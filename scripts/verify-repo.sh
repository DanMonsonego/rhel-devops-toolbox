#!/usr/bin/env bash

###############################################################################
# Verify RHEL DevOps Toolbox Repository
# Ensures all files are in place and scripts are valid
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_section() { echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"; }
log_pass() { echo -e "${GREEN}✅ $1${NC}"; }
log_fail() { echo -e "${RED}❌ $1${NC}"; }
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ISSUES=0
CHECKS=0

check_file() {
    local file=$1
    local desc=$2
    
    CHECKS=$((CHECKS + 1))
    
    if [ -f "$file" ]; then
        log_pass "$desc exists: $file"
        return 0
    else
        log_fail "$desc missing: $file"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local desc=$2
    
    CHECKS=$((CHECKS + 1))
    
    if [ -d "$dir" ]; then
        log_pass "$desc exists: $dir"
        return 0
    else
        log_fail "$desc missing: $dir"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

check_executable() {
    local file=$1
    local desc=$2
    
    CHECKS=$((CHECKS + 1))
    
    if [ -x "$file" ]; then
        log_pass "$desc is executable: $file"
        return 0
    else
        log_fail "$desc not executable: $file"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

check_syntax() {
    local file=$1
    local desc=$2
    
    CHECKS=$((CHECKS + 1))
    
    if bash -n "$file" 2>/dev/null; then
        log_pass "$desc has valid syntax: $file"
        return 0
    else
        log_fail "$desc has syntax errors: $file"
        ISSUES=$((ISSUES + 1))
        return 1
    fi
}

log_section "RHEL DevOps Toolbox - Repository Verification"

###############################################################################
# Check directory structure
###############################################################################
log_section "Directory Structure"

check_dir "docker" "Docker directory"
check_dir "scripts" "Scripts directory"
check_dir "tools" "Tools directory"
check_dir "config" "Config directory"
check_dir "tests" "Tests directory"
check_dir "workspace" "Workspace directory"

###############################################################################
# Check Docker files
###############################################################################
log_section "Docker Files"

check_file "docker/Dockerfile" "Dockerfile"
check_file "docker/docker-compose.yml" "Docker Compose configuration"
check_file "docker/entrypoint.sh" "Entrypoint script"
check_executable "docker/entrypoint.sh" "Entrypoint script"

###############################################################################
# Check installation scripts
###############################################################################
log_section "Installation Scripts"

INSTALL_SCRIPTS=(
    "install-kubectl.sh"
    "install-helm.sh"
    "install-k9s.sh"
    "install-docker.sh"
    "install-argocd.sh"
    "install-additional-tools.sh"
)

for script in "${INSTALL_SCRIPTS[@]}"; do
    check_file "tools/$script" "Install script: $script"
    check_executable "tools/$script" "Install script: $script"
    check_syntax "tools/$script" "Install script: $script"
done

###############################################################################
# Check main scripts
###############################################################################
log_section "Main Scripts"

MAIN_SCRIPTS=(
    "setup.sh"
    "doctor.sh"
    "test-all.sh"
    "init-cluster.sh"
    "healthcheck.sh"
    "verify-repo.sh"
)

for script in "${MAIN_SCRIPTS[@]}"; do
    check_file "scripts/$script" "Main script: $script"
    check_executable "scripts/$script" "Main script: $script"
    check_syntax "scripts/$script" "Main script: $script"
done

###############################################################################
# Check documentation
###############################################################################
log_section "Documentation"

check_file "README.md" "README"
check_file "CHANGELOG.md" "Changelog"
check_file "LICENSE" "License"
check_file ".gitignore" "Gitignore"

###############################################################################
# Check configuration files
###############################################################################
log_section "Configuration Files"

check_file "config/prometheus.yml" "Prometheus configuration"
check_file "Makefile" "Makefile"

###############################################################################
# Verify Dockerfile content
###############################################################################
log_section "Dockerfile Content"

CHECKS=$((CHECKS + 1))
if grep -q "FROM registry.access.redhat.com/ubi9/ubi:9.3" docker/Dockerfile; then
    log_pass "Dockerfile uses RHEL UBI 9.3"
else
    log_fail "Dockerfile missing RHEL UBI 9.3 base"
    ISSUES=$((ISSUES + 1))
fi

CHECKS=$((CHECKS + 1))
if grep -q "kubectl" docker/Dockerfile; then
    log_pass "Dockerfile includes kubectl"
else
    log_fail "Dockerfile missing kubectl"
    ISSUES=$((ISSUES + 1))
fi

CHECKS=$((CHECKS + 1))
if grep -q "helm" docker/Dockerfile; then
    log_pass "Dockerfile includes helm"
else
    log_fail "Dockerfile missing helm"
    ISSUES=$((ISSUES + 1))
fi

###############################################################################
# Check Makefile targets
###############################################################################
log_section "Makefile Targets"

CHECKS=$((CHECKS + 1))
if grep -q "^build:" Makefile; then
    log_pass "Makefile has build target"
else
    log_fail "Makefile missing build target"
    ISSUES=$((ISSUES + 1))
fi

CHECKS=$((CHECKS + 1))
if grep -q "^test:" Makefile; then
    log_pass "Makefile has test target"
else
    log_fail "Makefile missing test target"
    ISSUES=$((ISSUES + 1))
fi

###############################################################################
# Summary
###############################################################################
log_section "Verification Summary"

echo -e "${BLUE}Total Checks:${NC}  $CHECKS"
echo -e "${GREEN}Passed:${NC}        $((CHECKS - ISSUES))"
echo -e "${RED}Failed:${NC}        $ISSUES"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 ALL VERIFICATION CHECKS PASSED!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✅ Repository is complete and ready to use!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Build the container:    make build"
    echo "  2. Run tests:              make test"
    echo "  3. Start the toolbox:      make run"
    echo "  4. Or use docker-compose:  make up"
    echo ""
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ VERIFICATION FAILED - $ISSUES ISSUES FOUND${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}Please fix the issues above and run verification again.${NC}"
    echo ""
    exit 1
fi
