#!/usr/bin/env bash

###############################################################################
# Health Check Script for Container
# Used by Docker HEALTHCHECK instruction
###############################################################################

set -e

# Check if essential commands are available
command -v kubectl &> /dev/null || exit 1
command -v helm &> /dev/null || exit 1
command -v k9s &> /dev/null || exit 1

# All checks passed
exit 0
