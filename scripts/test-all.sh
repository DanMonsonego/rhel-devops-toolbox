#!/usr/bin/env bash

###############################################################################
# Test All Components
# Comprehensive test suite for RHEL DevOps Toolbox
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() { echo -e "${CYAN}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}  ✅ PASS${NC} $1"; }
log_fail() { echo -e "${RED}  ❌ FAIL${NC} $1"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_section() { echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"; }

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name=$1
    shift
    local test_cmd="$@"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_test "$test_name"
    
    if eval "$test_cmd" &> /dev/null; then
        log_pass "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_fail "$test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

log_section "RHEL DevOps Toolbox - Comprehensive Test Suite"

###############################################################################
# Test kubectl
###############################################################################
log_section "Testing kubectl"
run_test "kubectl is installed" "command -v kubectl"
run_test "kubectl version works" "kubectl version --client"
run_test "kubectl can read kubeconfig" "kubectl config view"

###############################################################################
# Test helm
###############################################################################
log_section "Testing helm"
run_test "helm is installed" "command -v helm"
run_test "helm version works" "helm version"
run_test "helm can list repos" "helm repo list"

###############################################################################
# Test k9s
###############################################################################
log_section "Testing k9s"
run_test "k9s is installed" "command -v k9s"
run_test "k9s version works" "k9s version"

###############################################################################
# Test Docker
###############################################################################
log_section "Testing Docker"
run_test "docker is installed" "command -v docker"
run_test "docker version works" "docker --version"

if docker ps &> /dev/null; then
    run_test "docker daemon is running" "docker ps"
    run_test "docker can pull images" "docker pull hello-world:latest"
    run_test "docker can run containers" "docker run --rm hello-world"
    run_test "docker can list images" "docker images"
    
    # Cleanup
    docker rmi hello-world:latest &> /dev/null || true
else
    log_info "Docker daemon not running - skipping runtime tests"
fi

###############################################################################
# Test ArgoCD CLI
###############################################################################
log_section "Testing ArgoCD CLI"
if command -v argocd &> /dev/null; then
    run_test "argocd is installed" "command -v argocd"
    run_test "argocd version works" "argocd version --client"
else
    log_info "ArgoCD CLI not installed - skipping tests"
fi

###############################################################################
# Test Utilities
###############################################################################
log_section "Testing Utilities"

if command -v yq &> /dev/null; then
    run_test "yq is installed" "command -v yq"
    run_test "yq can process YAML" "echo 'test: value' | yq '.test'"
fi

run_test "jq is installed" "command -v jq"
if command -v jq &> /dev/null; then
    run_test "jq can process JSON" "echo '{\"test\":\"value\"}' | jq '.test'"
fi

###############################################################################
# Test Service Mesh Tools
###############################################################################
log_section "Testing Service Mesh Tools"

if command -v istioctl &> /dev/null; then
    run_test "istioctl is installed" "command -v istioctl"
    run_test "istioctl version works" "istioctl version --remote=false"
else
    log_info "istioctl not installed - skipping tests"
fi

###############################################################################
# Test Monitoring Tools
###############################################################################
log_section "Testing Monitoring Tools"

if command -v promtool &> /dev/null; then
    run_test "promtool is installed" "command -v promtool"
    run_test "promtool version works" "promtool --version"
else
    log_info "promtool not installed - skipping tests"
fi

###############################################################################
# Test Package Management
###############################################################################
log_section "Testing Package Management"

if command -v chartmuseum &> /dev/null; then
    run_test "chartmuseum is installed" "command -v chartmuseum"
    run_test "chartmuseum version works" "chartmuseum --version"
else
    log_info "chartmuseum not installed - skipping tests"
fi

if command -v cmctl &> /dev/null; then
    run_test "cmctl is installed" "command -v cmctl"
    run_test "cmctl version works" "cmctl version --client"
else
    log_info "cmctl not installed - skipping tests"
fi

###############################################################################
# Test Kubernetes Connectivity (if available)
###############################################################################
log_section "Testing Kubernetes Connectivity"

if [ -f "$HOME/.kube/config" ]; then
    run_test "kubeconfig exists" "test -f $HOME/.kube/config"
    
    if kubectl cluster-info &> /dev/null; then
        run_test "can connect to cluster" "kubectl cluster-info"
        run_test "can list nodes" "kubectl get nodes"
        run_test "can list namespaces" "kubectl get namespaces"
        run_test "can list pods" "kubectl get pods --all-namespaces"
    else
        log_info "Cannot connect to Kubernetes cluster - skipping connectivity tests"
    fi
else
    log_info "No kubeconfig found - skipping Kubernetes connectivity tests"
fi

###############################################################################
# Test Scripts
###############################################################################
log_section "Testing Scripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_test "setup.sh exists" "test -f $SCRIPT_DIR/setup.sh"
run_test "setup.sh is executable" "test -x $SCRIPT_DIR/setup.sh"
run_test "doctor.sh exists" "test -f $SCRIPT_DIR/doctor.sh"
run_test "doctor.sh is executable" "test -x $SCRIPT_DIR/doctor.sh"
run_test "install-kubectl.sh exists" "test -f $SCRIPT_DIR/../tools/install-kubectl.sh"
run_test "install-helm.sh exists" "test -f $SCRIPT_DIR/../tools/install-helm.sh"
run_test "install-k9s.sh exists" "test -f $SCRIPT_DIR/../tools/install-k9s.sh"
run_test "install-docker.sh exists" "test -f $SCRIPT_DIR/../tools/install-docker.sh"

###############################################################################
# Test Bash Completion
###############################################################################
log_section "Testing Bash Completion"

if [ -d /etc/bash_completion.d ]; then
    run_test "bash completion directory exists" "test -d /etc/bash_completion.d"
    
    if [ -f /etc/bash_completion.d/kubectl ]; then
        run_test "kubectl completion installed" "test -f /etc/bash_completion.d/kubectl"
    fi
    
    if [ -f /etc/bash_completion.d/helm ]; then
        run_test "helm completion installed" "test -f /etc/bash_completion.d/helm"
    fi
fi

###############################################################################
# Summary
###############################################################################
log_section "Test Summary"

echo -e "${BLUE}Total Tests:${NC}   $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC}        $PASSED_TESTS"
echo -e "${RED}Failed:${NC}        $FAILED_TESTS"
echo ""

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 ALL TESTS PASSED! (100%)${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Your RHEL DevOps Toolbox is fully functional!${NC}"
    exit 0
elif [ "$PASS_RATE" -ge 90 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  MOSTLY PASSED ($PASS_RATE%)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Minor issues detected. Review failed tests above.${NC}"
    exit 1
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ SIGNIFICANT ISSUES FOUND ($PASS_RATE%)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}Multiple tests failed. Please review the output above.${NC}"
    exit 1
fi
