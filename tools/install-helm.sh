#!/usr/bin/env bash

###############################################################################
# Install Helm - Kubernetes package manager for RHEL
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

# Check if Helm is already installed
if command -v helm &> /dev/null; then
    CURRENT_VERSION=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    log_info "Helm is already installed (version: ${CURRENT_VERSION})"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Helm installation"
        exit 0
    fi
fi

log_info "Installing Helm for RHEL..."

# Use official installation script
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

cd "$TMP_DIR"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh
chmod 700 get_helm.sh

# Run installation script
./get_helm.sh

# Verify installation
if command -v helm &> /dev/null; then
    INSTALLED_VERSION=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    log_info "✅ Helm successfully installed!"
    log_info "Version: $INSTALLED_VERSION"
    log_info "Location: $(which helm)"
    
    # Setup helm completion
    log_info ""
    log_info "Setting up Helm autocompletion..."
    helm completion bash > /etc/bash_completion.d/helm 2>/dev/null || \
        sudo helm completion bash > /etc/bash_completion.d/helm
    
    # Add common repositories
    log_info ""
    log_info "Adding common Helm repositories..."
    helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true
    helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
    helm repo update
    log_info "✅ Repositories added and updated!"
else
    log_error "Installation failed. Helm not found in PATH"
    exit 1
fi

log_info ""
log_info "🎉 Installation complete!"
