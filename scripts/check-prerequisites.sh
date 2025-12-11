#!/bin/bash
# ==============================================================================
# Check Ahab Prerequisites
# ==============================================================================
# Checks if all required tools are installed before running Ahab
#
# Usage:
#   ./scripts/check-prerequisites.sh
#   make check-prerequisites
#
# Exit codes:
#   0 - All prerequisites met
#   1 - Missing prerequisites
#
# Security: Zero Trust - validates each tool independently
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/prerequisite-checks.sh
source "$SCRIPT_DIR/lib/prerequisite-checks.sh"

# ==============================================================================
# Configuration
# ==============================================================================

# Required commands for Ahab operation
export REQUIRED_COMMANDS=(
    "git"
    "ansible"
    "vagrant"
    "docker"
    "make"
    "python3"
)

# Optional but recommended commands
export OPTIONAL_COMMANDS=(
    "curl"
    "wget"
    "VBoxManage"
)

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    print_header "Ahab Prerequisites Check"
    
    local missing warnings additional_warnings
    
    check_required_tools
    missing=$?
    
    check_optional_tools
    warnings=$?
    
    check_additional_requirements
    additional_warnings=$?
    
    warnings=$((warnings + additional_warnings))
    
    print_final_summary $missing $warnings
    return $?
}

# Run main function
main "$@"