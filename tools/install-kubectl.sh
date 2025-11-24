#!/usr/bin/env bash

###############################################################################
# Install kubectl - Kubernetes command-line tool for RHEL
# Supports: RHEL 9.3 x86-64
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if kubectl is already installed
if command -v kubectl &> /dev/null; then
    CURRENT_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
    log_info "kubectl is already installed (version: ${CURRENT_VERSION})"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping kubectl installation"
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

# Get latest stable version
log_info "Fetching latest stable kubectl version..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
log_info "Latest stable version: $KUBECTL_VERSION"

# Download kubectl
DOWNLOAD_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
log_info "Downloading kubectl from: $DOWNLOAD_URL"

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/kubectl"

# Download checksum
log_info "Downloading checksum..."
curl -L "${DOWNLOAD_URL}.sha256" -o "$TMP_DIR/kubectl.sha256"

# Verify checksum
log_info "Verifying checksum..."
cd "$TMP_DIR"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install kubectl
log_info "Installing kubectl..."
chmod +x kubectl

INSTALL_DIR="/usr/local/bin"
if [[ -w "$INSTALL_DIR" ]]; then
    mv kubectl "$INSTALL_DIR/"
else
    log_warn "Requires sudo to install to $INSTALL_DIR"
    sudo mv kubectl "$INSTALL_DIR/"
fi

# Verify installation
if command -v kubectl &> /dev/null; then
    INSTALLED_VERSION=$(kubectl version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || kubectl version --client -o json | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_info "✅ kubectl successfully installed!"
    log_info "Version: $INSTALLED_VERSION"
    log_info "Location: $(which kubectl)"
    
    # Setup kubectl completion
    log_info ""
    log_info "Setting up kubectl autocompletion..."
    kubectl completion bash > /etc/bash_completion.d/kubectl 2>/dev/null || \
        sudo kubectl completion bash > /etc/bash_completion.d/kubectl
    log_info "To enable: source /etc/bash_completion.d/kubectl"
else
    log_error "Installation failed. kubectl not found in PATH"
    exit 1
fi

log_info ""
log_info "🎉 Installation complete!"
