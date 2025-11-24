# Contributing to RHEL DevOps Toolbox

Thank you for your interest in contributing to the RHEL DevOps Toolbox!

## 📋 Project Overview

This is a production-ready DevOps toolkit for RHEL 9.3 x86-64 with comprehensive tooling for container orchestration, GitOps, monitoring, and infrastructure management.

## 🏗️ Repository Structure

```
rhel-devops-toolbox/
├── tools/              # Tool installation scripts
│   ├── install-kubectl.sh
│   ├── install-helm.sh
│   ├── install-k9s.sh
│   ├── install-docker.sh
│   ├── install-argocd.sh
│   ├── install-kafka-cluster.sh
│   └── install-additional-tools.sh
│
├── scripts/            # Operational & management scripts
│   ├── setup.sh                  # Complete setup
│   ├── doctor.sh                 # Health checks
│   ├── test-all.sh               # Test suite
│   ├── verify-repo.sh            # Repository verification
│   ├── init-cluster.sh           # Initialize K8s cluster
│   ├── setup-3node-cluster.sh    # Deploy 3-node cluster
│   ├── helm-umbrella.sh          # Helm platform management
│   └── remote-ssh-setup.sh       # SSH configuration
│
├── docker/             # Container configuration
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
│
├── helm-umbrella/      # Helm chart for platform
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│
├── config/             # Configuration files
│   └── prometheus.yml
│
├── tests/              # Test directory
├── workspace/          # User workspace
└── README.md           # Main documentation (SINGLE SOURCE OF TRUTH)
```

## 📝 Documentation Standards

### Single Source of Truth

**README.md** is the **ONLY** comprehensive documentation file. All documentation should be:
- Maintained in README.md
- Well-organized with clear sections
- Up-to-date with code changes
- Include usage examples

### Additional Docs
- **CHANGELOG.md** - Version history and changes
- **CONTRIBUTING.md** - This file
- Inline comments in scripts for complex logic

## 🔧 Development Workflow

### 1. Setup Development Environment

```bash
# Clone repository
git clone <your-fork>
cd rhel-devops-toolbox

# Verify repository structure
./scripts/verify-repo.sh

# Run health checks
./scripts/doctor.sh
```

### 2. Making Changes

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# - Add new tools in tools/
# - Add operational scripts in scripts/
# - Update README.md with changes

# Test your changes
./scripts/test-all.sh
./scripts/verify-repo.sh
```

### 3. Testing Requirements

All contributions must pass:

```bash
# Repository structure validation
./scripts/verify-repo.sh    # Must pass all 57 checks

# Comprehensive test suite
./scripts/test-all.sh        # Must pass all tests

# Script syntax validation (automatic in verify-repo.sh)
bash -n script-name.sh       # Must have no syntax errors

# Health checks
./scripts/doctor.sh          # Should pass all tool checks
```

### 4. Commit Standards

Use conventional commit format:

```bash
feat: Add new feature
fix: Fix bug in script
docs: Update README
refactor: Restructure code
test: Add new tests
chore: Update dependencies
```

### 5. Pull Request Process

1. Update README.md with any new features or changes
2. Ensure all tests pass
3. Update CHANGELOG.md with your changes
4. Create PR with clear description

## 🎯 Contribution Guidelines

### Adding New Tools

When adding new tools to `tools/`:

1. **Create installation script**: `tools/install-newtool.sh`
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   
   # Tool installation logic
   # Include version variables
   # Add error handling
   # Include verification step
   ```

2. **Update setup.sh**: Add tool to main setup script
3. **Update doctor.sh**: Add health check for the tool
4. **Update test-all.sh**: Add tests for the tool
5. **Update README.md**: Document the new tool
6. **Update Dockerfile**: If needed for container image

### Adding New Scripts

When adding operational scripts to `scripts/`:

1. **Follow naming convention**: `action-target.sh`
2. **Use standard header**:
   ```bash
   #!/usr/bin/env bash
   ###############################################################################
   # Script Description
   # Purpose and functionality
   ###############################################################################
   
   set -euo pipefail
   ```

3. **Include logging functions**:
   ```bash
   log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
   log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
   ```

4. **Add to verify-repo.sh** for validation
5. **Document in README.md** with usage examples

### Code Style

- **Bash**: Follow Google Shell Style Guide
- **Indentation**: 4 spaces (no tabs)
- **Line length**: Max 100 characters
- **Comments**: Clear and concise
- **Error handling**: Always use `set -euo pipefail`
- **Variables**: Use `${VAR}` syntax

## 🧪 Testing

### Test Categories

1. **Installation Tests** - Verify tool installations
2. **Runtime Tests** - Test tool functionality
3. **Syntax Tests** - Validate script syntax
4. **Structure Tests** - Verify repository structure
5. **Integration Tests** - Test script interactions

### Running Tests

```bash
# Full test suite
./scripts/test-all.sh

# Repository verification
./scripts/verify-repo.sh

# Health checks
./scripts/doctor.sh

# Specific script testing
bash -n scripts/script-name.sh    # Syntax check
shellcheck scripts/script-name.sh  # Linting (if available)
```

## 📦 Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v1.x.x -m "Release version 1.x.x"`
4. Push changes and tags
5. Create GitHub release with notes

## 🐛 Bug Reports

Include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, versions)
- Relevant logs or error messages

## 💡 Feature Requests

Include:
- Clear description of the feature
- Use case and benefits
- Proposed implementation (optional)
- Impact on existing functionality

## 📞 Getting Help

- Check README.md for documentation
- Run `./scripts/doctor.sh` for health checks
- Run `./scripts/test-all.sh` for testing
- Open an issue for questions

## ✅ Checklist Before Submitting

- [ ] All tests pass (`./scripts/test-all.sh`)
- [ ] Repository verification passes (`./scripts/verify-repo.sh`)
- [ ] README.md updated (if applicable)
- [ ] CHANGELOG.md updated
- [ ] Scripts have proper permissions (755)
- [ ] No secrets or sensitive data committed
- [ ] Commit messages follow conventions
- [ ] Branch is up to date with main

## 🎉 Thank You!

Your contributions help make this DevOps toolkit better for everyone!
