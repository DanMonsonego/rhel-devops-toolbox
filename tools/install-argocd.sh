#!/usr/bin/env bash

###############################################################################
# Install ArgoCD CLI for RHEL
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

# Check if ArgoCD CLI is already installed
if command -v argocd &> /dev/null; then
    CURRENT_VERSION=$(argocd version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    log_info "ArgoCD CLI is already installed (version: ${CURRENT_VERSION})"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping ArgoCD CLI installation"
        exit 0
    fi
fi

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case $OS in
    linux)
        OS="linux"
        ;;
    darwin)
        OS="darwin"
        ;;
    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        log_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log_info "Detected OS: $OS, Architecture: $ARCH"

# Get latest stable version
log_info "Fetching latest stable ArgoCD version..."
ARGOCD_VERSION=$(curl -L -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
log_info "Latest stable version: $ARGOCD_VERSION"

# Download ArgoCD CLI
DOWNLOAD_URL="https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-${OS}-${ARCH}"
log_info "Downloading ArgoCD CLI from: $DOWNLOAD_URL"

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/argocd"

# Install ArgoCD CLI
log_info "Installing ArgoCD CLI..."
chmod +x "$TMP_DIR/argocd"

INSTALL_DIR="/usr/local/bin"
if [[ -w "$INSTALL_DIR" ]]; then
    mv "$TMP_DIR/argocd" "$INSTALL_DIR/"
else
    log_warn "Requires sudo to install to $INSTALL_DIR"
    sudo mv "$TMP_DIR/argocd" "$INSTALL_DIR/"
    sudo chmod 0755 "$INSTALL_DIR/argocd"
fi

# Verify installation
if command -v argocd &> /dev/null; then
    INSTALLED_VERSION=$(argocd version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "installed")
    log_info "✅ ArgoCD CLI successfully installed!"
    log_info "Version: $INSTALLED_VERSION"
    log_info "Location: $(which argocd)"
    
    # Setup ArgoCD CLI completion
    log_info ""
    log_info "Setting up ArgoCD CLI autocompletion..."
    argocd completion bash > /etc/bash_completion.d/argocd 2>/dev/null || \
        sudo argocd completion bash > /etc/bash_completion.d/argocd
else
    log_error "Installation failed. ArgoCD CLI not found in PATH"
    exit 1
fi

log_info ""
log_info "🎉 Installation complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Install ArgoCD in your cluster:"
log_info "     kubectl create namespace argocd"
log_info "     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
log_info ""
log_info "  2. Access ArgoCD UI:"
log_info "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
log_info ""
log_info "  3. Get admin password:"
log_info "     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
