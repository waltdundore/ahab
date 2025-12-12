#!/usr/bin/env bash
# ==============================================================================
# Setup Secrets Repository Integration - Wrapper
# ==============================================================================
# Simple wrapper for the full setup-secrets-repo.sh script
# The full implementation is in needs-refactoring/ until it can be properly
# refactored to meet the 200-line limit while maintaining functionality
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to the full implementation
exec "$SCRIPT_DIR/needs-refactoring/setup-secrets-repo.sh" "$@"