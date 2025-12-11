#!/usr/bin/env bash
# ==============================================================================
# Setup Production Credentials for Ahab (Refactored)
# ==============================================================================
# This script configures Ansible credentials for production deployments
# (non-Vagrant environments where you need to specify an admin user)
#
# Usage: ./setup-production-credentials.sh
#        make setup-production
#
# What it does:
# 1. Validates admin user has sudo access
# 2. Generates ansible.cfg from template
# 3. Generates inventory/production from template
# 4. Optionally configures passwordless sudo
# 5. Tests the configuration
# ==============================================================================

set -euo pipefail

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common library functions
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/setup-common.sh
source "$SCRIPT_DIR/lib/setup-common.sh"
# shellcheck source=lib/production-setup-common.sh
source "$SCRIPT_DIR/lib/production-setup-common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

CONFIG_DIR="$PROJECT_ROOT/config"
INVENTORY_DIR="$PROJECT_ROOT/inventory"
ANSIBLE_CFG="$PROJECT_ROOT/ansible.cfg"
INVENTORY_FILE="$INVENTORY_DIR/production"
GROUP_VARS_DIR="$INVENTORY_DIR/group_vars"
GROUP_VARS_FILE="$GROUP_VARS_DIR/all.yml"

#------------------------------------------------------------------------------
# Input Functions
#------------------------------------------------------------------------------

prompt_for_user() {
    echo ""
    echo "Enter the admin username for your production servers:"
    echo "(This user must have sudo access on the target machines)"
    echo ""
    read -r -p "Admin username: " admin_user
    
    if [ -z "$admin_user" ]; then
        print_error "Username cannot be empty"
        exit 1
    fi
    
    echo "$admin_user"
}

confirm_setup() {
    local admin_user="$1"
    
    echo ""
    echo "Configuration Summary:"
    echo "  Admin user: $admin_user"
    echo "  Files to create:"
    echo "    - ansible.cfg"
    echo "    - inventory/production"
    echo "    - inventory/group_vars/all.yml"
    echo ""
    
    confirm_action "Proceed with setup?"
}

#------------------------------------------------------------------------------
# Main Setup Function
#------------------------------------------------------------------------------

setup_configuration() {
    local admin_user="$1"
    
    print_section "GENERATING CONFIGURATION FILES"
    
    # Generate configuration files
    generate_ansible_cfg "$admin_user" "$CONFIG_DIR" "$ANSIBLE_CFG"
    generate_production_inventory "$admin_user" "$INVENTORY_DIR" "$INVENTORY_FILE"
    generate_group_vars "$admin_user" "$GROUP_VARS_DIR" "$GROUP_VARS_FILE"
    
    # Setup passwordless sudo if requested
    setup_passwordless_sudo "$admin_user"
    
    print_success "Configuration files generated successfully"
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "SETUP PRODUCTION CREDENTIALS"
    
    echo "This script configures Ansible for production deployments"
    echo "It will create ansible.cfg and inventory/production files"
    echo ""
    
    # Get user input
    local admin_user
    admin_user=$(prompt_for_user)
    
    # Validate user
    if ! validate_admin_user "$admin_user"; then
        exit 1
    fi
    
    # Confirm setup
    if ! confirm_setup "$admin_user"; then
        print_info "Setup cancelled by user"
        exit 0
    fi
    
    # Perform setup
    setup_configuration "$admin_user"
    
    # Test configuration
    test_ansible_configuration "$INVENTORY_FILE"
    
    # Print summary
    print_configuration_summary "$admin_user" "$ANSIBLE_CFG" "$INVENTORY_FILE"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi