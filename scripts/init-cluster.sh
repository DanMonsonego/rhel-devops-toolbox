#!/usr/bin/env bash

###############################################################################
# Initialize Kubernetes Cluster Configuration
# Sets up common cluster configurations and tools
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

# Check if connected to cluster
if ! kubectl cluster-info &> /dev/null; then
    log_error "Not connected to a Kubernetes cluster"
    log_info "Please configure kubeconfig first:"
    log_info "  export KUBECONFIG=/path/to/kubeconfig"
    exit 1
fi

CLUSTER_INFO=$(kubectl cluster-info 2>/dev/null | head -1)
log_info "Connected to: $CLUSTER_INFO"

###############################################################################
# Create common namespaces
###############################################################################
create_namespaces() {
    log_step "Creating common namespaces..."
    
    NAMESPACES=("development" "staging" "production" "monitoring" "logging")
    
    for ns in "${NAMESPACES[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            log_info "  Namespace '$ns' already exists"
        else
            kubectl create namespace "$ns"
            log_info "  ✅ Created namespace '$ns'"
        fi
    done
}

###############################################################################
# Install ArgoCD (optional)
###############################################################################
install_argocd_cluster() {
    log_step "Install ArgoCD in cluster? (y/N): "
    read -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installing ArgoCD..."
        
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        log_info "✅ ArgoCD installed"
        log_info ""
        log_info "Access ArgoCD:"
        log_info "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
        log_info ""
        log_info "Get admin password:"
        log_info "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    fi
}

###############################################################################
# Setup Helm repositories
###############################################################################
setup_helm_repos() {
    log_step "Setting up Helm repositories..."
    
    helm repo add stable https://charts.helm.sh/stable 2>/dev/null || log_info "  stable repo already added"
    helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || log_info "  bitnami repo already added"
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || log_info "  prometheus-community repo already added"
    helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || log_info "  grafana repo already added"
    helm repo add istio https://istio-release.storage.googleapis.com/charts 2>/dev/null || log_info "  istio repo already added"
    
    helm repo update
    log_info "✅ Helm repositories updated"
}

###############################################################################
# Install cert-manager (optional)
###############################################################################
install_cert_manager() {
    log_step "Install cert-manager? (y/N): "
    read -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installing cert-manager..."
        
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
        
        log_info "✅ cert-manager installed"
    fi
}

###############################################################################
# Main execution
###############################################################################
main() {
    log_info "Initializing Kubernetes cluster configuration..."
    echo ""
    
    create_namespaces
    echo ""
    
    setup_helm_repos
    echo ""
    
    install_argocd_cluster
    echo ""
    
    install_cert_manager
    echo ""
    
    log_info "🎉 Cluster initialization complete!"
}

main
