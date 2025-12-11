#!/usr/bin/env bash
# ==============================================================================
# Setup Ansible Vault (NASA Rule #4 Compliant)
# ==============================================================================
# Sets up Ansible Vault for secure credential management
#
# Usage:
#   ./scripts/setup-ansible-vault.sh
#   make setup-vault
#
# Exit Codes:
#   0 - Setup completed successfully
#   1 - Setup failed
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"
# shellcheck source=./lib/setup-common.sh
source "$SCRIPT_DIR/lib/setup-common.sh"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "ANSIBLE VAULT SETUP"
    
    echo "Setting up Ansible Vault for secure credential management..."
    echo ""
    
    # Validate prerequisites
    if ! validate_setup_prerequisites; then
        print_error "Prerequisites not met"
        exit 1
    fi
    
    # Setup vault structure
    setup_vault_structure
    create_vault_documentation
    
    print_success "Ansible Vault setup completed successfully"
    print_info "Next steps:"
    print_info "  1. Set ANSIBLE_VAULT_PASSWORD_FILE environment variable"
    print_info "  2. Create vault password file (keep it secure!)"
    print_info "  3. Start encrypting sensitive files"
}

#------------------------------------------------------------------------------
# Setup Functions
#------------------------------------------------------------------------------

setup_vault_structure() {
    print_section "Setting up Vault Structure"
    
    # Create vault directories
    setup_secrets_directory "vault"
    setup_secrets_directory "vault/group_vars"
    setup_secrets_directory "vault/host_vars"
    
    # Setup vault files
    setup_ansible_vault "vault/secrets.yml"
    
    # Create vault password file template
    create_vault_password_template
}

create_vault_password_template() {
    echo "→ Creating vault password file template"
    
    cat > "vault/vault-password-file.template" << 'EOF'
# Ansible Vault Password File Template
# 
# 1. Copy this file to a secure location outside the repository
# 2. Replace this content with your actual vault password
# 3. Set ANSIBLE_VAULT_PASSWORD_FILE to point to the file
# 4. Ensure file permissions are 600 (readable only by owner)
#
# Example:
#   cp vault/vault-password-file.template ~/.ansible-vault-password
#   echo "your-secure-password-here" > ~/.ansible-vault-password
#   chmod 600 ~/.ansible-vault-password
#   export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-password

YOUR_SECURE_VAULT_PASSWORD_HERE
EOF
    
    check_pass "Created vault password file template"
}

create_vault_documentation() {
    print_section "Creating Vault Documentation"
    
    cat > "vault/README.md" << 'EOF'
# Ansible Vault Configuration

This directory contains Ansible Vault encrypted files for secure credential management.

## Quick Start

1. **Set up vault password file:**
   ```bash
   cp vault-password-file.template ~/.ansible-vault-password
   echo "your-secure-password" > ~/.ansible-vault-password
   chmod 600 ~/.ansible-vault-password
   export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-password
   ```

2. **Create encrypted files:**
   ```bash
   ansible-vault create vault/secrets.yml
   ansible-vault create vault/group_vars/production.yml
   ```

3. **Edit encrypted files:**
   ```bash
   ansible-vault edit vault/secrets.yml
   ```

4. **View encrypted files:**
   ```bash
   ansible-vault view vault/secrets.yml
   ```

## Best Practices

- Use strong, unique passwords for vault
- Store vault password file outside repository
- Rotate vault passwords regularly
- Use separate vaults for different environments
- Never commit unencrypted secrets

## File Structure

- `secrets.yml` - Main secrets file
- `group_vars/` - Group-specific encrypted variables
- `host_vars/` - Host-specific encrypted variables
EOF
    
    check_pass "Created vault documentation"
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi