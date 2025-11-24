#!/usr/bin/env bash

###############################################################################
# Install Docker for RHEL
# Supports: RHEL 9.3 x86-64
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

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    CURRENT_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    log_info "Docker is already installed (version: ${CURRENT_VERSION})"
    read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Docker installation"
        exit 0
    fi
fi

log_step "Installing Docker on RHEL..."

# Install prerequisites
log_step "Installing prerequisites..."
sudo dnf install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repository
log_step "Adding Docker repository..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Install Docker Engine
log_step "Installing Docker Engine..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
log_step "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
log_step "Adding user to docker group..."
sudo usermod -aG docker $USER

log_info "✅ Docker Engine installed successfully!"
log_warn ""
log_warn "⚠️  IMPORTANT: Please log out and log back in for group changes to take effect"
log_warn "    Or run: newgrp docker"
log_warn ""

# Verify installation
if docker --version &> /dev/null; then
    INSTALLED_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    log_info "Version: $INSTALLED_VERSION"
    log_info "Location: $(which docker)"
    
    # Test Docker (may require newgrp docker first)
    log_step "Testing Docker installation..."
    if sudo docker run --rm hello-world &> /dev/null; then
        log_info "✅ Docker test successful!"
    else
        log_warn "Docker is installed but test requires group permissions (run: newgrp docker)"
    fi
    
    # Show Docker Compose version
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        log_info "Docker Compose version: $COMPOSE_VERSION"
    fi
else
    log_error "Installation verification failed. Docker not found in PATH"
    exit 1
fi

log_info ""
log_info "🎉 Installation complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Log out and log back in (or run: newgrp docker)"
log_info "  2. Test Docker: docker run hello-world"
log_info "  3. Build an image: docker build -t myapp ."
log_info "  4. Use Docker Compose: docker compose up"
