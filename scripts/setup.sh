#!/usr/bin/env bash

###############################################################################
# RHEL DevOps Toolbox - Setup Script
# Installs all required tools for DevOps workflows
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_section() { echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

log_section "RHEL 9.3 DevOps Toolbox - Complete Setup"

# Check if running on RHEL or macOS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "rhel" && "$ID" != "centos" && "$ID" != "rocky" && "$ID" != "almalinux" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "Detected macOS. Using Homebrew for package management."
            OS="macos"
        else
            log_warn "This script is optimized for RHEL-based systems or macOS"
            log_warn "Detected: $PRETTY_NAME"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            OS="unknown"
        fi
    else
        OS="rhel"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    log_info "Detected macOS. Using Homebrew for package management."
    OS="macos"
else
    log_warn "Unable to detect OS. Assuming RHEL-like system."
    OS="rhel"
fi

###############################################################################
# Update system
###############################################################################
update_system() {
    log_section "Updating System Packages"
    
    if [[ "$OS" == "macos" ]]; then
        log_step "Checking Homebrew installation..."
        if ! command -v brew &> /dev/null; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        log_step "Updating Homebrew..."
        brew update
        
        log_step "Installing base dependencies..."
        brew install \
            git vim nano \
            bash-completion \
            ca-certificates \
            openssl openssh \
            python3
        
        log_info "✅ Homebrew updated and base packages installed"
    else
        log_step "Running system update..."
        sudo dnf update -y
        
        log_step "Installing base dependencies..."
        sudo dnf install -y \
            curl wget git vim nano \
            bash-completion \
            ca-certificates \
            openssl openssh-clients \
            tar gzip unzip \
            bind-utils net-tools \
            python3 python3-pip
        
        log_info "✅ System updated and base packages installed"
    fi
}

###############################################################################
# Install core Kubernetes tools
###############################################################################
install_k8s_tools() {
    log_section "Installing Kubernetes Tools"
    
    log_step "Checking kubectl..."
    if command -v kubectl &> /dev/null; then
        CURRENT_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
        log_info "kubectl is already installed (version: ${CURRENT_VERSION})"
        read -p "Do you want to reinstall/upgrade kubectl? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Installing kubectl..."
            "$SCRIPT_DIR/../tools/install-kubectl.sh"
        else
            log_warn "Skipping kubectl installation"
        fi
    else
        log_step "Installing kubectl..."
        "$SCRIPT_DIR/../tools/install-kubectl.sh"
    fi
    
    log_step "Checking helm..."
    if command -v helm &> /dev/null; then
        CURRENT_VERSION=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_info "Helm is already installed (version: ${CURRENT_VERSION})"
        read -p "Do you want to reinstall/upgrade Helm? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Installing helm..."
            "$SCRIPT_DIR/../tools/install-helm.sh"
        else
            log_warn "Skipping Helm installation"
        fi
    else
        log_step "Installing helm..."
        "$SCRIPT_DIR/../tools/install-helm.sh"
    fi
    
    log_step "Checking k9s..."
    if command -v k9s &> /dev/null; then
        CURRENT_VERSION=$(k9s version --short 2>/dev/null | grep Version | awk '{print $2}' || echo "unknown")
        log_info "k9s is already installed (version: ${CURRENT_VERSION})"
        read -p "Do you want to reinstall/upgrade k9s? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Installing k9s..."
            "$SCRIPT_DIR/../tools/install-k9s.sh"
        else
            log_warn "Skipping k9s installation"
        fi
    else
        log_step "Installing k9s..."
        "$SCRIPT_DIR/../tools/install-k9s.sh"
    fi
    
    log_info "✅ Kubernetes tools checked/installed"
}

###############################################################################
# Install container tools
###############################################################################
install_container_tools() {
    log_section "Installing Container Tools"
    
    read -p "Install Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Installing Docker..."
        "$SCRIPT_DIR/../tools/install-docker.sh"
    else
        log_warn "Skipping Docker installation"
    fi
}

###############################################################################
# Install GitOps tools
###############################################################################
install_gitops_tools() {
    log_section "Installing GitOps Tools"
    
    if command -v argocd &> /dev/null; then
        CURRENT_VERSION=$(argocd version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_info "ArgoCD CLI is already installed (version: ${CURRENT_VERSION})"
        read -p "Do you want to reinstall/upgrade ArgoCD CLI? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Installing ArgoCD CLI..."
            "$SCRIPT_DIR/../tools/install-argocd.sh"
        else
            log_warn "Skipping ArgoCD CLI installation"
        fi
    else
        read -p "Install ArgoCD CLI? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_step "Installing ArgoCD CLI..."
            "$SCRIPT_DIR/../tools/install-argocd.sh"
        else
            log_warn "Skipping ArgoCD CLI installation"
        fi
    fi
}

###############################################################################
# Install additional tools
###############################################################################
install_additional_tools() {
    log_section "Installing Additional Tools"
    
    read -p "Install additional tools (yq, jq, istioctl, promtool, etc.)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Installing additional tools..."
        "$SCRIPT_DIR/../tools/install-additional-tools.sh"
    else
        log_warn "Skipping additional tools installation"
    fi
}

###############################################################################
# Configure environment
###############################################################################
configure_environment() {
    log_section "Configuring Environment"
    
    # Setup bash completion
    log_step "Setting up bash completion..."
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        if ! grep -q "bash_completion" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# Enable bash completion" >> ~/.bashrc
            echo "if [ -f /usr/share/bash-completion/bash_completion ]; then" >> ~/.bashrc
            echo "    . /usr/share/bash-completion/bash_completion" >> ~/.bashrc
            echo "fi" >> ~/.bashrc
        fi
    fi
    
    # Add kubectl alias
    if ! grep -q "alias k=" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Kubectl alias" >> ~/.bashrc
        echo "alias k=kubectl" >> ~/.bashrc
    fi
    
    # Source completion files
    if ! grep -q "kubectl completion" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Kubectl completion" >> ~/.bashrc
        echo "source <(kubectl completion bash)" >> ~/.bashrc
        echo "complete -F __start_kubectl k" >> ~/.bashrc
    fi
    
    log_info "✅ Environment configured"
}

###############################################################################
# Run verification
###############################################################################
run_verification() {
    log_section "Running Verification"
    
    if [ -f "$SCRIPT_DIR/doctor.sh" ]; then
        "$SCRIPT_DIR/doctor.sh"
    else
        log_warn "doctor.sh not found. Skipping verification."
    fi
}

###############################################################################
# Main execution
###############################################################################
main() {
    update_system
    install_k8s_tools
    install_container_tools
    install_gitops_tools
    install_additional_tools
    configure_environment
    run_verification
    
    log_section "🎉 Setup Complete!"
    
    cat << EOF

${GREEN}Your RHEL DevOps Toolbox is ready!${NC}

${YELLOW}Next Steps:${NC}

1. ${BLUE}Reload your shell to apply changes:${NC}
   source ~/.bashrc

2. ${BLUE}Verify installation:${NC}
   ./scripts/doctor.sh

3. ${BLUE}Test tools:${NC}
   kubectl version --client
   helm version
   k9s version
   docker --version
   argocd version --client

4. ${BLUE}Configure Kubernetes access:${NC}
   export KUBECONFIG=~/.kube/config
   # Or copy your cluster config to ~/.kube/config

5. ${BLUE}Run comprehensive tests:${NC}
   ./scripts/test-all.sh

${YELLOW}Documentation:${NC}
  • README.md          - Complete documentation
  • QUICKSTART.md      - Quick start guide
  • scripts/           - All installation and utility scripts

${YELLOW}Support:${NC}
  • Run doctor: ./scripts/doctor.sh
  • Check logs: journalctl -xe

EOF
}

# Run main function
main
