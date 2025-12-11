#!/usr/bin/env bash
# ==============================================================================
# Release Module Script (NASA Rule #4 Compliant)
# ==============================================================================
# Packages and releases an Ahab module
#
# Usage:
#   ./scripts/release-module.sh <module-name> [version]
#   make release-module MODULE=<module-name> VERSION=<version>
#
# Exit Codes:
#   0 - Module released successfully
#   1 - Release failed
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
    local version="${2:-1.0.0}"
    
    if [ -z "$module_name" ]; then
        print_error "Module name is required"
        show_usage
        exit 1
    fi
    
    print_header "RELEASE MODULE: $module_name v$version"
    
    # Validate module name
    if ! validate_module_name "$module_name"; then
        exit 1
    fi
    
    # Check if module exists
    if ! check_module_exists "$module_name"; then
        print_error "Module '$module_name' not found"
        exit 1
    fi
    
    # Validate module for release
    if ! validate_module_for_release "$module_name"; then
        print_error "Module validation failed"
        exit 1
    fi
    
    # Create release
    mkdir -p dist
    create_module_package "$module_name" "$version"
    register_module "$module_name" "$version"
    
    print_success "Module '$module_name' v$version released successfully"
    print_info "Package: dist/${module_name}-${version}.tar.gz"
    print_info "Registry updated: MODULE_REGISTRY.yml"
}

show_usage() {
    cat << EOF
Usage: $0 <module-name> [version]

Packages and releases an Ahab module.

Arguments:
  module-name    Name of the module to release
  version        Version number (default: 1.0.0)

Examples:
  $0 apache 1.2.0    # Release Apache module v1.2.0
  $0 mysql           # Release MySQL module v1.0.0

The module must pass validation before it can be released.
EOF
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi