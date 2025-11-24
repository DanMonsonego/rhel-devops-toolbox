#!/usr/bin/env bash

###############################################################################
# Install Additional Tools for RHEL DevOps Toolbox
# Installs: yq, jq, istioctl, promtool, chartmuseum, cmctl, harbor-cli
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

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

###############################################################################
# Install yq (YAML processor)
###############################################################################
install_yq() {
    log_step "Installing yq (YAML processor)..."
    
    if command -v yq &> /dev/null; then
        log_info "yq already installed: $(yq --version)"
        return 0
    fi
    
    YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /tmp/yq
    
    sudo mv /tmp/yq /usr/local/bin/yq
    sudo chmod 0755 /usr/local/bin/yq
    
    log_info "✅ yq installed: $(yq --version)"
}

###############################################################################
# Install jq (JSON processor)
###############################################################################
install_jq() {
    log_step "Installing jq (JSON processor)..."
    
    if command -v jq &> /dev/null; then
        log_info "jq already installed: $(jq --version)"
        return 0
    fi
    
    JQ_VERSION=$(curl -s https://api.github.com/repos/jqlang/jq/releases/latest | grep '"tag_name":' | sed -E 's/.*"jq-([^"]+)".*/\1/')
    if [[ "$OS" == "linux" ]]; then
        JQ_OS="linux64"
    elif [[ "$OS" == "darwin" ]]; then
        JQ_OS="osx-amd64"
    fi
    curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_OS}" -o /tmp/jq
    
    sudo mv /tmp/jq /usr/local/bin/jq
    sudo chmod 0755 /usr/local/bin/jq
    
    log_info "✅ jq installed: $(jq --version)"
}

###############################################################################
# Install Istio CLI (istioctl)
###############################################################################
install_istioctl() {
    log_step "Installing istioctl..."
    
    if command -v istioctl &> /dev/null; then
        log_info "istioctl already installed: $(istioctl version --remote=false 2>/dev/null | head -1)"
        return 0
    fi
    
    cd /tmp
    curl -L https://istio.io/downloadIstio | sh -
    
    ISTIO_DIR=$(ls -d istio-* | head -1)
    sudo mv "$ISTIO_DIR/bin/istioctl" /usr/local/bin/
    rm -rf "$ISTIO_DIR"
    
    log_info "✅ istioctl installed: $(istioctl version --remote=false)"
}

###############################################################################
# Install Prometheus CLI tools (promtool)
###############################################################################
install_promtool() {
    log_step "Installing promtool..."
    
    if command -v promtool &> /dev/null; then
        log_info "promtool already installed: $(promtool --version 2>/dev/null | head -1)"
        return 0
    fi
    
    PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    cd /tmp
    curl -fsSL "https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.${OS}-${ARCH}.tar.gz" -o prometheus.tar.gz
    tar -xzf prometheus.tar.gz
    
    sudo mv "prometheus-${PROM_VERSION}.${OS}-${ARCH}/promtool" /usr/local/bin/
    sudo chmod 0755 /usr/local/bin/promtool
    rm -rf "prometheus-${PROM_VERSION}.linux-${ARCH}" prometheus.tar.gz
    
    log_info "✅ promtool installed: $(promtool --version 2>/dev/null | head -1)"
}

###############################################################################
# Install ChartMuseum
###############################################################################
install_chartmuseum() {
    log_step "Installing ChartMuseum..."
    
    if command -v chartmuseum &> /dev/null; then
        log_info "ChartMuseum already installed: $(chartmuseum --version 2>/dev/null)"
        return 0
    fi
    
    CM_VERSION=$(curl -s https://api.github.com/repos/helm/chartmuseum/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    cd /tmp
    curl -fsSL "https://get.helm.sh/chartmuseum-${CM_VERSION}-${OS}-${ARCH}.tar.gz" -o chartmuseum.tar.gz
    tar -xzf chartmuseum.tar.gz
    
    sudo mv "${OS}-${ARCH}/chartmuseum" /usr/local/bin/
    sudo chmod 0755 /usr/local/bin/chartmuseum
    rm -rf "${OS}-${ARCH}" chartmuseum.tar.gz
    
    log_info "✅ ChartMuseum installed: $(chartmuseum --version)"
}

###############################################################################
# Install cert-manager CLI (cmctl)
###############################################################################
install_cmctl() {
    log_step "Installing cmctl (cert-manager CLI)..."
    
    if command -v cmctl &> /dev/null; then
        log_info "cmctl already installed: $(cmctl version --client 2>/dev/null | head -1)"
        return 0
    fi
    
    if [[ "$OS" == "darwin" ]]; then
        log_warn "cmctl is not available for macOS. Skipping."
        return 0
    fi
    
    cd /tmp
    curl -fsSL "https://github.com/cert-manager/cert-manager/releases/latest/download/cmctl-${OS}-${ARCH}.tar.gz" -o cmctl.tar.gz
    tar -xzf cmctl.tar.gz
    
    sudo mv cmctl /usr/local/bin/
    sudo chmod 0755 /usr/local/bin/cmctl
    rm -f cmctl.tar.gz
    
    log_info "✅ cmctl installed: $(cmctl version --client 2>/dev/null | head -1)"
}

###############################################################################
# Install RKE2 tools
###############################################################################
install_rke2() {
    log_step "Installing RKE2 tools..."
    
    if command -v rke2 &> /dev/null; then
        log_info "RKE2 already installed"
        return 0
    fi
    
    if [[ "$OS" == "darwin" ]]; then
        log_warn "RKE2 is not available for macOS. Skipping."
        return 0
    fi
    
    curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -
    
    log_info "✅ RKE2 tools installed"
}

###############################################################################
# Main installation
###############################################################################
main() {
    log_info "Installing additional DevOps tools for RHEL..."
    echo ""
    
    install_yq
    install_jq
    install_istioctl
    install_promtool
    install_chartmuseum
    install_cmctl
    install_rke2
    
    echo ""
    log_info "🎉 All additional tools installed successfully!"
    echo ""
    log_info "Installed tools:"
    log_info "  • yq:          $(yq --version 2>/dev/null || echo 'N/A')"
    log_info "  • jq:          $(jq --version 2>/dev/null || echo 'N/A')"
    log_info "  • istioctl:    $(istioctl version --remote=false 2>/dev/null | head -1 || echo 'N/A')"
    log_info "  • promtool:    $(promtool --version 2>/dev/null | head -1 || echo 'N/A')"
    log_info "  • chartmuseum: $(chartmuseum --version 2>/dev/null || echo 'N/A')"
    log_info "  • cmctl:       $(cmctl version --client 2>/dev/null | head -1 || echo 'N/A')"
    log_info "  • rke2:        $(rke2 --version 2>/dev/null | head -1 || echo 'Installed')"
}

main
