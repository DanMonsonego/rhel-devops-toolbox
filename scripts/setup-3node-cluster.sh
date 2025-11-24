#!/usr/bin/env bash

###############################################################################
# Setup 3-Node Kubernetes Cluster with RKE2
# Creates a complete 3-node cluster for development/testing
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

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-devops-cluster}"
NODE1_IP="${NODE1_IP:-192.168.1.101}"
NODE2_IP="${NODE2_IP:-192.168.1.102}"
NODE3_IP="${NODE3_IP:-192.168.1.103}"
SSH_USER="${SSH_USER:-root}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

log_section "Setting Up 3-Node Kubernetes Cluster"

cat << EOF
Cluster Configuration:
  Name:        $CLUSTER_NAME
  Node 1:      $NODE1_IP (master)
  Node 2:      $NODE2_IP (worker)
  Node 3:      $NODE3_IP (worker)
  SSH User:    $SSH_USER
  SSH Key:     $SSH_KEY
EOF

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found: $SSH_KEY"
    log_info "Generate SSH key with: ssh-keygen -t rsa -b 4096"
    exit 1
fi

###############################################################################
# Function: Setup RKE2 on node
###############################################################################
setup_rke2_node() {
    local node_ip=$1
    local node_type=$2  # server or agent
    local server_ip=$3
    
    log_step "Setting up RKE2 $node_type on $node_ip..."
    
    ssh -i "$SSH_KEY" "$SSH_USER@$node_ip" << 'ENDSSH'
        # Update system
        dnf update -y
        
        # Disable firewall (for testing - enable and configure for production)
        systemctl disable firewalld --now || true
        
        # Disable SELinux (for testing - configure properly for production)
        setenforce 0 || true
        sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
        
        # Install RKE2
        curl -sfL https://get.rke2.io | sh -
ENDSSH
    
    if [ "$node_type" = "server" ]; then
        log_info "Configuring as RKE2 server (master)..."
        ssh -i "$SSH_KEY" "$SSH_USER@$node_ip" << 'ENDSSH'
            # Create config directory
            mkdir -p /etc/rancher/rke2
            
            # Create config
            cat > /etc/rancher/rke2/config.yaml << 'EOF'
tls-san:
  - ${NODE_IP}
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
EOF
            
            # Enable and start RKE2 server
            systemctl enable rke2-server.service
            systemctl start rke2-server.service
            
            # Wait for RKE2 to start
            echo "Waiting for RKE2 server to start..."
            sleep 30
            
            # Create symlinks
            ln -sf /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
            ln -sf /var/lib/rancher/rke2/bin/crictl /usr/local/bin/crictl
            
            # Get node token
            cat /var/lib/rancher/rke2/server/node-token
ENDSSH
    else
        log_info "Configuring as RKE2 agent (worker)..."
        
        # Get token from server
        local token=$(ssh -i "$SSH_KEY" "$SSH_USER@$server_ip" "cat /var/lib/rancher/rke2/server/node-token")
        
        ssh -i "$SSH_KEY" "$SSH_USER@$node_ip" << ENDSSH
            # Create config directory
            mkdir -p /etc/rancher/rke2
            
            # Create config
            cat > /etc/rancher/rke2/config.yaml << EOF
server: https://$server_ip:9345
token: $token
EOF
            
            # Enable and start RKE2 agent
            systemctl enable rke2-agent.service
            systemctl start rke2-agent.service
ENDSSH
    fi
    
    log_info "✅ RKE2 $node_type setup complete on $node_ip"
}

###############################################################################
# Function: Copy kubeconfig
###############################################################################
copy_kubeconfig() {
    local master_ip=$1
    
    log_step "Copying kubeconfig from master..."
    
    ssh -i "$SSH_KEY" "$SSH_USER@$master_ip" "cat /etc/rancher/rke2/rke2.yaml" > /tmp/rke2-kubeconfig.yaml
    
    # Update server IP in kubeconfig
    sed -i.bak "s/127.0.0.1/$master_ip/g" /tmp/rke2-kubeconfig.yaml
    
    # Install kubeconfig
    mkdir -p ~/.kube
    cp /tmp/rke2-kubeconfig.yaml ~/.kube/config
    chmod 600 ~/.kube/config
    
    log_info "✅ Kubeconfig copied to ~/.kube/config"
}

###############################################################################
# Function: Verify cluster
###############################################################################
verify_cluster() {
    log_step "Verifying cluster..."
    
    # Wait for nodes to be ready
    log_info "Waiting for nodes to be ready (this may take a few minutes)..."
    sleep 60
    
    kubectl get nodes
    
    local ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || echo "0")
    
    if [ "$ready_nodes" -ge 3 ]; then
        log_info "✅ All 3 nodes are ready!"
        kubectl get nodes -o wide
    else
        log_warn "Only $ready_nodes nodes are ready. Waiting longer..."
        sleep 60
        kubectl get nodes -o wide
    fi
}

###############################################################################
# Function: Install cluster addons
###############################################################################
install_addons() {
    log_section "Installing Cluster Add-ons"
    
    # Install metrics-server
    log_step "Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics-server for self-signed certs (development)
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' || true
    
    # Install cert-manager (optional)
    read -p "Install cert-manager? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Installing cert-manager..."
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    fi
    
    # Install ArgoCD (optional)
    read -p "Install ArgoCD? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Installing ArgoCD..."
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        log_info "ArgoCD installed. Access it with:"
        log_info "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
        log_info "Get password:"
        log_info "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    fi
}

###############################################################################
# Main execution
###############################################################################
main() {
    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Install it first: ./tools/install-kubectl.sh"
        exit 1
    fi
    
    # Setup Node 1 (Master)
    setup_rke2_node "$NODE1_IP" "server" ""
    
    # Copy kubeconfig
    copy_kubeconfig "$NODE1_IP"
    
    # Setup Node 2 (Worker)
    setup_rke2_node "$NODE2_IP" "agent" "$NODE1_IP"
    
    # Setup Node 3 (Worker)
    setup_rke2_node "$NODE3_IP" "agent" "$NODE1_IP"
    
    # Verify cluster
    verify_cluster
    
    # Install addons
    install_addons
    
    log_section "🎉 Cluster Setup Complete!"
    
    cat << EOF

Cluster Information:
  Name:           $CLUSTER_NAME
  Master Node:    $NODE1_IP
  Worker Nodes:   $NODE2_IP, $NODE3_IP
  Kubeconfig:     ~/.kube/config

Useful Commands:
  kubectl get nodes
  kubectl get pods --all-namespaces
  kubectl cluster-info
  k9s  # Interactive terminal UI

Access Services:
  ArgoCD UI:      kubectl port-forward svc/argocd-server -n argocd 8080:443
  Kubernetes API: https://$NODE1_IP:6443

Next Steps:
  1. Deploy applications: kubectl apply -f your-app.yaml
  2. Use Helm: helm install my-app stable/nginx
  3. Monitor with k9s: k9s
  4. Setup ArgoCD apps: argocd app create ...

EOF
}

# Parse arguments
case "${1:-setup}" in
    setup)
        main
        ;;
    verify)
        verify_cluster
        ;;
    clean)
        log_warn "Cleaning up cluster..."
        ssh -i "$SSH_KEY" "$SSH_USER@$NODE1_IP" "systemctl stop rke2-server && rm -rf /var/lib/rancher/rke2" || true
        ssh -i "$SSH_KEY" "$SSH_USER@$NODE2_IP" "systemctl stop rke2-agent && rm -rf /var/lib/rancher/rke2" || true
        ssh -i "$SSH_KEY" "$SSH_USER@$NODE3_IP" "systemctl stop rke2-agent && rm -rf /var/lib/rancher/rke2" || true
        log_info "Cluster cleaned up"
        ;;
    *)
        echo "Usage: $0 [setup|verify|clean]"
        echo ""
        echo "Environment variables:"
        echo "  NODE1_IP=<ip>    Master node IP (default: 192.168.1.101)"
        echo "  NODE2_IP=<ip>    Worker node 1 IP (default: 192.168.1.102)"
        echo "  NODE3_IP=<ip>    Worker node 2 IP (default: 192.168.1.103)"
        echo "  SSH_USER=<user>  SSH user (default: root)"
        echo "  SSH_KEY=<path>   SSH key path (default: ~/.ssh/id_rsa)"
        exit 1
        ;;
esac
