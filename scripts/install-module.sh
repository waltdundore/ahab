#!/usr/bin/env bash
# ==============================================================================
# Install Module Script (NASA Rule #4 Compliant)
# ==============================================================================
# Installs and deploys an Ahab module
#
# Usage:
#   ./scripts/install-module.sh <module-name> [target]
#   make install <module-name>
#
# Exit Codes:
#   0 - Module installed successfully
#   1 - Installation failed
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"
# shellcheck source=./lib/module-common.sh
source "$SCRIPT_DIR/lib/module-common.sh"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local module_name="${1:-}"
    local target="${2:-workstation}"
    
    if [ -z "$module_name" ]; then
        print_error "Module name is required"
        show_usage
        exit 1
    fi
    
    print_header "INSTALL MODULE: $module_name"
    
    # Validate module name
    if ! validate_module_name "$module_name"; then
        exit 1
    fi
    
    # Check if module exists
    if ! check_module_exists "$module_name"; then
        print_error "Module '$module_name' not found"
        print_info "Available modules:"
        list_available_modules
        exit 1
    fi
    
    # Install module
    install_module_dependencies "$module_name"
    test_module "$module_name"
    deploy_module "$module_name" "$target"
    
    print_success "Module '$module_name' installed successfully on $target"
}

show_usage() {
    cat << EOF
Usage: $0 <module-name> [target]

Installs and deploys an Ahab module.

Arguments:
  module-name    Name of the module to install
  target         Target environment (default: workstation)

Examples:
  $0 apache              # Install Apache on workstation
  $0 mysql production    # Install MySQL on production

Available targets: workstation, production, development
EOF
}

list_available_modules() {
    if [ -d "modules" ]; then
        find modules -maxdepth 1 -type d -not -name "modules" | sed 's|modules/||' | sort
    else
        echo "  No modules found"
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi