#!/usr/bin/env bash

###############################################################################
# Install k9s - Kubernetes CLI UI for RHEL
# Supports: RHEL 9.3 x86-64
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if k9s is already installed
if command -v k9s &> /dev/null; then
    CURRENT_VERSION=$(k9s version --short 2>/dev/null | grep Version | awk '{print $2}' || echo "unknown")
    log_info "k9s is already installed (version: ${CURRENT_VERSION})"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping k9s installation"
        exit 0
    fi
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log_info "Detected Architecture: $ARCH"

# Get latest release version from GitHub
log_info "Fetching latest k9s release..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
log_info "Latest version: v$LATEST_VERSION"

# Construct download URL
FILENAME="k9s_Linux_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/v${LATEST_VERSION}/${FILENAME}"

log_info "Downloading k9s from: $DOWNLOAD_URL"

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

cd "$TMP_DIR"
curl -LO "$DOWNLOAD_URL"

# Extract archive
log_info "Extracting archive..."
tar -xzf "$FILENAME"

# Install k9s
log_info "Installing k9s..."
chmod +x k9s

INSTALL_DIR="/usr/local/bin"
if [[ -w "$INSTALL_DIR" ]]; then
    mv k9s "$INSTALL_DIR/"
else
    log_warn "Requires sudo to install to $INSTALL_DIR"
    sudo mv k9s "$INSTALL_DIR/"
fi

# Verify installation
if command -v k9s &> /dev/null; then
    INSTALLED_VERSION=$(k9s version --short 2>/dev/null | grep Version | awk '{print $2}')
    log_info "✅ k9s successfully installed!"
    log_info "Version: $INSTALLED_VERSION"
    log_info "Location: $(which k9s)"
    
    log_info ""
    log_info "Usage: Run 'k9s' to start the Kubernetes CLI"
else
    log_error "Installation failed. k9s not found in PATH"
    exit 1
fi

log_info ""
log_info "🎉 Installation complete!"
