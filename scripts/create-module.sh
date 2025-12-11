#!/usr/bin/env bash
# ==============================================================================
# Create Module Script (NASA Rule #4 Compliant)
# ==============================================================================
# Creates a new Ahab module with standard structure
#
# Usage:
#   ./scripts/create-module.sh <module-name>
#   make create-module MODULE=<module-name>
#
# Exit Codes:
#   0 - Module created successfully
#   1 - Creation failed
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
    
    if [ -z "$module_name" ]; then
        print_error "Module name is required"
        show_usage
        exit 1
    fi
    
    print_header "CREATE MODULE: $module_name"
    
    # Validate module name
    if ! validate_module_name "$module_name"; then
        exit 1
    fi
    
    # Check if module already exists
    if check_module_exists "$module_name"; then
        print_error "Module '$module_name' already exists"
        exit 1
    fi
    
    # Create module
    create_module_structure "$module_name"
    create_module_metadata "$module_name"
    
    print_success "Module '$module_name' created successfully"
    print_info "Module location: modules/$module_name"
    print_info "Next steps:"
    print_info "  1. Edit modules/$module_name/roles/$module_name/tasks/main.yml"
    print_info "  2. Test with: make test-module MODULE=$module_name"
    print_info "  3. Install with: make install $module_name"
}

show_usage() {
    cat << EOF
Usage: $0 <module-name>

Creates a new Ahab module with standard structure.

Arguments:
  module-name    Name of the module to create

Examples:
  $0 apache      # Create Apache module
  $0 mysql       # Create MySQL module

The module name must contain only letters, numbers, hyphens, and underscores.
EOF
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi