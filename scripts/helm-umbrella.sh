#!/usr/bin/env bash

###############################################################################
# Helm Umbrella Chart Deployment Script
# Manages multiple related Helm charts as a single unit
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
UMBRELLA_NAME="${UMBRELLA_NAME:-devops-platform}"
NAMESPACE="${NAMESPACE:-devops}"
CHART_DIR="${CHART_DIR:-./helm-umbrella}"
ACTION="${1:-install}"

log_section "Helm Umbrella Chart Manager"

###############################################################################
# Create Umbrella Chart Structure
###############################################################################
create_umbrella_chart() {
    log_step "Creating umbrella chart structure..."
    
    mkdir -p "$CHART_DIR"
    cd "$CHART_DIR"
    
    # Create Chart.yaml
    cat > Chart.yaml << 'EOF'
apiVersion: v2
name: devops-platform
description: Umbrella chart for complete DevOps platform
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - devops
  - kubernetes
  - platform
  - umbrella
maintainers:
  - name: DevOps Team
dependencies:
  # Monitoring Stack
  - name: prometheus
    version: "25.8.0"
    repository: "https://prometheus-community.github.io/helm-charts"
    condition: prometheus.enabled
    tags:
      - monitoring
  
  - name: grafana
    version: "7.0.8"
    repository: "https://grafana.github.io/helm-charts"
    condition: grafana.enabled
    tags:
      - monitoring
  
  # GitOps
  - name: argo-cd
    version: "5.51.4"
    repository: "https://argoproj.github.io/argo-helm"
    condition: argocd.enabled
    tags:
      - gitops
  
  # Service Mesh
  - name: istio-base
    version: "1.20.1"
    repository: "https://istio-release.storage.googleapis.com/charts"
    condition: istio.enabled
    tags:
      - servicemesh
  
  - name: istiod
    version: "1.20.1"
    repository: "https://istio-release.storage.googleapis.com/charts"
    condition: istio.enabled
    tags:
      - servicemesh
  
  # Ingress
  - name: nginx-ingress
    version: "4.9.0"
    repository: "https://kubernetes.github.io/ingress-nginx"
    condition: nginx.enabled
    tags:
      - ingress
  
  # Certificate Management
  - name: cert-manager
    version: "v1.13.3"
    repository: "https://charts.jetstack.io"
    condition: certManager.enabled
    tags:
      - security
  
  # Secrets Management
  - name: sealed-secrets
    version: "2.14.1"
    repository: "https://bitnami-labs.github.io/sealed-secrets"
    condition: sealedSecrets.enabled
    tags:
      - security
  
  # Container Registry
  - name: harbor
    version: "1.14.0"
    repository: "https://helm.goharbor.io"
    condition: harbor.enabled
    tags:
      - registry
  
  # Helm Repository
  - name: chartmuseum
    version: "3.10.1"
    repository: "https://chartmuseum.github.io/charts"
    condition: chartmuseum.enabled
    tags:
      - helm
EOF

    # Create values.yaml
    cat > values.yaml << 'EOF'
# Global configuration
global:
  domain: example.com
  storageClass: standard

# Enable/Disable components
prometheus:
  enabled: true
  alertmanager:
    enabled: true
  server:
    persistentVolume:
      enabled: true
      size: 10Gi

grafana:
  enabled: true
  adminPassword: admin
  persistence:
    enabled: true
    size: 5Gi
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server
          isDefault: true

argocd:
  enabled: true
  server:
    ingress:
      enabled: true
      hosts:
        - argocd.example.com

istio:
  enabled: false

nginx:
  enabled: true
  controller:
    service:
      type: LoadBalancer

certManager:
  enabled: true
  installCRDs: true

sealedSecrets:
  enabled: false

harbor:
  enabled: false
  expose:
    type: ingress
    ingress:
      hosts:
        core: harbor.example.com

chartmuseum:
  enabled: false
  env:
    open:
      DISABLE_API: false
      ALLOW_OVERWRITE: true
  persistence:
    enabled: true
    size: 10Gi

# Tags to enable/disable groups
tags:
  monitoring: true
  gitops: true
  servicemesh: false
  ingress: true
  security: true
  registry: false
  helm: false
EOF

    # Create templates directory
    mkdir -p templates
    
    # Create NOTES.txt
    cat > templates/NOTES.txt << 'EOF'
DevOps Platform Umbrella Chart deployed successfully!

Components installed:
{{- if .Values.prometheus.enabled }}
  ✅ Prometheus - Monitoring
{{- end }}
{{- if .Values.grafana.enabled }}
  ✅ Grafana - Visualization
{{- end }}
{{- if .Values.argocd.enabled }}
  ✅ ArgoCD - GitOps
{{- end }}
{{- if .Values.istio.enabled }}
  ✅ Istio - Service Mesh
{{- end }}
{{- if .Values.nginx.enabled }}
  ✅ NGINX - Ingress Controller
{{- end }}
{{- if .Values.certManager.enabled }}
  ✅ cert-manager - Certificate Management
{{- end }}
{{- if .Values.harbor.enabled }}
  ✅ Harbor - Container Registry
{{- end }}
{{- if .Values.chartmuseum.enabled }}
  ✅ ChartMuseum - Helm Repository
{{- end }}

Access your services:
  Grafana:    http://grafana.{{ .Values.global.domain }}
  ArgoCD:     http://argocd.{{ .Values.global.domain }}
  Prometheus: http://prometheus.{{ .Values.global.domain }}

Get credentials:
  kubectl get secret -n {{ .Release.Namespace }}
EOF

    # Create .helmignore
    cat > .helmignore << 'EOF'
.git/
.gitignore
*.swp
*.bak
*.tmp
.DS_Store
EOF

    log_info "✅ Umbrella chart structure created"
}

###############################################################################
# Update dependencies
###############################################################################
update_dependencies() {
    log_step "Updating Helm dependencies..."
    
    cd "$CHART_DIR"
    
    # Add required repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo add istio https://istio-release.storage.googleapis.com/charts
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add jetstack https://charts.jetstack.io
    helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets
    helm repo add harbor https://helm.goharbor.io
    helm repo add chartmuseum https://chartmuseum.github.io/charts
    
    # Update repositories
    helm repo update
    
    # Build dependencies
    helm dependency build
    
    log_info "✅ Dependencies updated"
}

###############################################################################
# Install umbrella chart
###############################################################################
install_umbrella() {
    log_step "Installing umbrella chart..."
    
    # Create namespace
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    cd "$CHART_DIR"
    
    # Install chart
    helm install "$UMBRELLA_NAME" . \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --wait \
        --timeout 15m
    
    log_info "✅ Umbrella chart installed"
}

###############################################################################
# Upgrade umbrella chart
###############################################################################
upgrade_umbrella() {
    log_step "Upgrading umbrella chart..."
    
    cd "$CHART_DIR"
    
    # Upgrade chart
    helm upgrade "$UMBRELLA_NAME" . \
        --namespace "$NAMESPACE" \
        --wait \
        --timeout 15m
    
    log_info "✅ Umbrella chart upgraded"
}

###############################################################################
# Uninstall umbrella chart
###############################################################################
uninstall_umbrella() {
    log_step "Uninstalling umbrella chart..."
    
    helm uninstall "$UMBRELLA_NAME" \
        --namespace "$NAMESPACE"
    
    log_info "✅ Umbrella chart uninstalled"
}

###############################################################################
# Show status
###############################################################################
show_status() {
    log_step "Umbrella chart status..."
    
    helm list -n "$NAMESPACE"
    echo ""
    helm status "$UMBRELLA_NAME" -n "$NAMESPACE"
    echo ""
    kubectl get pods -n "$NAMESPACE"
}

###############################################################################
# Custom values deployment
###############################################################################
deploy_with_custom_values() {
    local values_file=$1
    
    log_step "Deploying with custom values: $values_file"
    
    if [ ! -f "$values_file" ]; then
        log_error "Values file not found: $values_file"
        exit 1
    fi
    
    cd "$CHART_DIR"
    
    helm upgrade --install "$UMBRELLA_NAME" . \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --values "$values_file" \
        --wait \
        --timeout 15m
    
    log_info "✅ Deployed with custom values"
}

###############################################################################
# Generate example custom values
###############################################################################
generate_custom_values() {
    log_step "Generating example custom values..."
    
    cat > custom-values-example.yaml << 'EOF'
# Example custom values for specific deployment

global:
  domain: mycompany.com
  storageClass: fast-ssd

# Enable only monitoring stack
tags:
  monitoring: true
  gitops: false
  servicemesh: false
  ingress: true
  security: true
  registry: false
  helm: false

prometheus:
  enabled: true
  server:
    persistentVolume:
      size: 50Gi
    retention: "30d"

grafana:
  enabled: true
  adminPassword: MySecurePassword123!
  persistence:
    size: 20Gi
  ingress:
    enabled: true
    hosts:
      - grafana.mycompany.com
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.mycompany.com

nginx:
  enabled: true
  controller:
    service:
      type: LoadBalancer
      loadBalancerIP: "10.0.0.100"

certManager:
  enabled: true
  installCRDs: true
EOF

    log_info "✅ Example custom values generated: custom-values-example.yaml"
}

###############################################################################
# Main execution
###############################################################################
main() {
    case "$ACTION" in
        create)
            create_umbrella_chart
            update_dependencies
            log_info "Umbrella chart created. Review $CHART_DIR/values.yaml"
            ;;
        install)
            if [ ! -d "$CHART_DIR" ]; then
                create_umbrella_chart
            fi
            update_dependencies
            install_umbrella
            show_status
            ;;
        upgrade)
            update_dependencies
            upgrade_umbrella
            show_status
            ;;
        uninstall)
            uninstall_umbrella
            ;;
        status)
            show_status
            ;;
        custom)
            if [ -z "${2:-}" ]; then
                log_error "Please provide values file: $0 custom <values-file>"
                exit 1
            fi
            deploy_with_custom_values "$2"
            ;;
        example)
            generate_custom_values
            ;;
        *)
            cat << EOF
Usage: $0 <action> [options]

Actions:
  create              Create umbrella chart structure
  install             Install umbrella chart
  upgrade             Upgrade existing installation
  uninstall           Uninstall umbrella chart
  status              Show installation status
  custom <file>       Deploy with custom values file
  example             Generate example custom values file

Environment Variables:
  UMBRELLA_NAME       Chart release name (default: devops-platform)
  NAMESPACE           Kubernetes namespace (default: devops)
  CHART_DIR           Chart directory (default: ./helm-umbrella)

Examples:
  # Create and install
  $0 create
  $0 install

  # Deploy with custom values
  $0 example
  $0 custom custom-values-example.yaml

  # Upgrade
  $0 upgrade

  # Check status
  $0 status

EOF
            exit 1
            ;;
    esac
    
    if [ "$ACTION" != "create" ] && [ "$ACTION" != "example" ]; then
        log_section "🎉 Operation Complete!"
        
        cat << EOF

Umbrella Chart: $UMBRELLA_NAME
Namespace: $NAMESPACE

Useful Commands:
  helm list -n $NAMESPACE
  helm status $UMBRELLA_NAME -n $NAMESPACE
  kubectl get pods -n $NAMESPACE
  kubectl get svc -n $NAMESPACE
  kubectl get ingress -n $NAMESPACE

Logs:
  kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$UMBRELLA_NAME

EOF
    fi
}

main "$@"
