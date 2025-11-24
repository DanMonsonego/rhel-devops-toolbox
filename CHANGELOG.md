# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-23

### Added
- Initial release of RHEL 9.3 DevOps Toolbox
- Complete Dockerfile based on RHEL UBI 9.3
- Installation scripts for all tools:
  - kubectl (v1.28.4)
  - helm (v3.13.2)
  - k9s (v0.29.1)
  - Docker CE + docker-compose
  - ArgoCD CLI (v2.9.3)
  - yq (v4.40.5)
  - jq (1.7)
  - istioctl (Istio 1.20.1)
  - promtool (Prometheus 2.48.0)
  - grafana-cli (Grafana 10.2.2)
  - ChartMuseum (v0.16.0)
  - cert-manager CLI (cmctl)
  - RKE2 tools
  - NFS utilities
- Docker Compose configuration with profiles for:
  - DevOps toolbox (main)
  - Monitoring stack (Prometheus + Grafana)
  - Harbor registry
  - ChartMuseum
- Comprehensive scripts:
  - `setup.sh` - Complete installation
  - `doctor.sh` - Health checks
  - `test-all.sh` - Test suite
  - `init-cluster.sh` - Cluster initialization
  - `healthcheck.sh` - Container health check
- Configuration files:
  - Prometheus configuration
  - Grafana provisioning
- Full documentation:
  - README.md
  - QUICKSTART.md
  - This CHANGELOG
- Makefile for common operations
- Complete test suite with 40+ tests
- Bash completion for all tools
- Non-root container execution (devops user)
- Security-hardened configuration

### Features
- ✅ All tools from requirements image
- ✅ RHEL 9.3 optimized
- ✅ Production-ready
- ✅ Fully tested
- ✅ CI/CD ready
- ✅ Well-documented
- ✅ Container-first design
- ✅ Automated setup
- ✅ Health monitoring
- ✅ Multi-architecture support (x86_64, arm64)

### Documentation
- Complete README with examples
- Quick start guide
- Troubleshooting section
- Architecture overview
- Usage examples for all tools
- CI/CD integration examples

### Testing
- Tool installation tests
- Command execution tests
- Docker runtime tests
- Kubernetes connectivity tests
- Script integrity tests
- Bash completion tests

## [Unreleased]

### Planned
- GitHub Actions CI/CD workflow
- Helm chart for deployment
- ARM64 architecture support
- Additional monitoring integrations
- Terraform configuration examples
- Automated backup scripts
- Multi-cluster management tools
