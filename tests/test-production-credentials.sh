#!/usr/bin/env bash
# ==============================================================================
# Unit Test: Production Credential Configuration
# ==============================================================================
# Tests production credential setup for non-Vagrant deployments
# Validates: M0.5 Production Deployment requirements
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test helpers (DRY: reuse existing functions)
source "$SCRIPT_DIR/lib/test-helpers.sh"
source "$SCRIPT_DIR/lib/assertions.sh"

# Test configuration
readonly TEST_NAME="Production Credential Configuration"

#------------------------------------------------------------------------------
# Test Functions
#------------------------------------------------------------------------------

test_ansible_cfg_exists() {
    print_section "Test: ansible.cfg exists"
    
    if [ -f "$REPO_ROOT/ansible.cfg" ]; then
        print_success "ansible.cfg found"
        return 0
    else
        print_warning "ansible.cfg not found"
        print_info "Run 'make setup-production' to create it"
        print_info "This is expected if production mode hasn't been configured yet"
        return 0  # Not a failure - just not configured yet
    fi
}

test_ansible_cfg_valid() {
    print_section "Test: ansible.cfg is valid"
    
    if [ ! -f "$REPO_ROOT/ansible.cfg" ]; then
        print_info "ansible.cfg not found - skipping validation"
        return 0
    fi
    
    # Check required sections exist
    local has_defaults=0
    local has_privilege=0
    
    if grep -q "^\[defaults\]" "$REPO_ROOT/ansible.cfg"; then
        has_defaults=1
        print_success "ansible.cfg has [defaults] section"
    fi
    
    if grep -q "^\[privilege_escalation\]" "$REPO_ROOT/ansible.cfg"; then
        has_privilege=1
        print_success "ansible.cfg has [privilege_escalation] section"
    fi
    
    if [ $has_defaults -eq 1 ] && [ $has_privilege -eq 1 ]; then
        print_success "ansible.cfg has required sections"
        return 0
    else
        print_error "ansible.cfg missing required sections"
        print_info "Expected: [defaults] and [privilege_escalation]"
        return 1
    fi
}

test_inventory_exists() {
    print_section "Test: Production inventory exists"
    
    if [ -f "$REPO_ROOT/inventory/production" ]; then
        print_success "inventory/production found"
        return 0
    else
        print_warning "inventory/production not found"
        print_info "Run 'make setup-production' to create it"
        print_info "This is expected if production mode hasn't been configured yet"
        return 0  # Not a failure - just not configured yet
    fi
}

test_ansible_connection() {
    print_section "Test: Ansible can connect to localhost"
    
    if [ ! -f "$REPO_ROOT/ansible.cfg" ]; then
        print_info "ansible.cfg not found - skipping connection test"
        return 0
    fi
    
    # Check if ansible command exists
    if ! command -v ansible >/dev/null 2>&1; then
        print_warning "Ansible not installed"
        print_info "Install with: brew install ansible (macOS) or dnf install ansible (Fedora)"
        return 0  # Not a failure - just not installed
    fi
    
    print_info "Testing Ansible connection to localhost..."
    
    # Try to ping localhost
    if ansible localhost -m ping >/dev/null 2>&1; then
        print_success "Ansible connection successful"
        return 0
    else
        print_error "Ansible connection failed"
        print_info "Check ansible.cfg and inventory configuration"
        print_info "Run: ansible localhost -m ping -vvv (for debug output)"
        return 1
    fi
}

test_ansible_become() {
    print_section "Test: Ansible can escalate privileges"
    
    if [ ! -f "$REPO_ROOT/ansible.cfg" ]; then
        print_info "ansible.cfg not found - skipping privilege escalation test"
        return 0
    fi
    
    # Check if ansible command exists
    if ! command -v ansible >/dev/null 2>&1; then
        print_warning "Ansible not installed - skipping privilege escalation test"
        return 0
    fi
    
    print_info "Testing Ansible privilege escalation..."
    
    # Try to become root and check whoami
    local result
    result=$(ansible localhost -b -m command -a "whoami" 2>/dev/null | grep -o "root" || echo "")
    
    if [ "$result" = "root" ]; then
        print_success "Ansible privilege escalation successful"
        return 0
    else
        print_error "Ansible privilege escalation failed"
        print_info "Check sudo configuration and become settings"
        print_info "Run: ansible localhost -b -m command -a 'whoami' -vvv"
        return 1
    fi
}

test_sudo_configuration() {
    print_section "Test: Sudo configuration (if applicable)"
    
    if [ -f "/etc/sudoers.d/ahab" ]; then
        print_info "Found /etc/sudoers.d/ahab - validating..."
        
        # Validate sudoers syntax
        if sudo visudo -c -f /etc/sudoers.d/ahab >/dev/null 2>&1; then
            print_success "Sudo configuration valid"
            return 0
        else
            print_error "Sudo configuration has syntax errors"
            print_info "Fix with: sudo visudo /etc/sudoers.d/ahab"
            return 1
        fi
    else
        print_info "No /etc/sudoers.d/ahab file"
        print_info "This is expected if using password prompt or Ansible Vault"
        return 0
    fi
}

test_vault_configuration() {
    print_section "Test: Vault configuration (if applicable)"
    
    if [ ! -f "$REPO_ROOT/ansible.cfg" ]; then
        print_info "ansible.cfg not found - skipping vault test"
        return 0
    fi
    
    # Check if vault is configured
    if grep -q "vault_password_file" "$REPO_ROOT/ansible.cfg" 2>/dev/null; then
        print_info "Vault password file configured in ansible.cfg"
        
        # Check if vault password file exists
        if [ -f "$REPO_ROOT/.vault_pass" ]; then
            print_success "Vault password file exists"
            
            # Check permissions
            local perms
            perms=$(stat -f "%OLp" "$REPO_ROOT/.vault_pass" 2>/dev/null || stat -c "%a" "$REPO_ROOT/.vault_pass" 2>/dev/null || echo "unknown")
            
            if [ "$perms" = "600" ]; then
                print_success "Vault password file has correct permissions (600)"
            else
                print_warning "Vault password file permissions: $perms (should be 600)"
                print_info "Fix with: chmod 600 .vault_pass"
            fi
            
            return 0
        else
            print_error "Vault password file missing"
            print_info "Create .vault_pass or update ansible.cfg"
            return 1
        fi
    else
        print_info "Not using Ansible Vault"
        return 0
    fi
}

test_production_templates_exist() {
    print_section "Test: Production templates exist"
    
    local missing=0
    
    # Check for production templates
    if [ -f "$REPO_ROOT/config/ansible.cfg.production" ]; then
        print_success "ansible.cfg.production template found"
    else
        print_error "ansible.cfg.production template missing"
        ((missing++))
    fi
    
    if [ -f "$REPO_ROOT/inventory/production.template" ]; then
        print_success "production.template inventory found"
    else
        print_error "production.template inventory missing"
        ((missing++))
    fi
    
    if [ $missing -eq 0 ]; then
        print_success "All production templates exist"
        return 0
    else
        print_error "$missing production template(s) missing"
        return 1
    fi
}

test_gitignore_configured() {
    print_section "Test: .gitignore configured for production files"
    
    if [ ! -f "$REPO_ROOT/.gitignore" ]; then
        print_warning ".gitignore not found"
        return 0
    fi
    
    local missing=0
    
    # Check that sensitive files are ignored
    if grep -q "^ansible\.cfg$" "$REPO_ROOT/.gitignore" 2>/dev/null || \
       grep -q "^/ansible\.cfg$" "$REPO_ROOT/.gitignore" 2>/dev/null; then
        print_success "ansible.cfg is in .gitignore"
    else
        print_warning "ansible.cfg should be in .gitignore"
        ((missing++))
    fi
    
    if grep -q "^\.vault_pass$" "$REPO_ROOT/.gitignore" 2>/dev/null || \
       grep -q "^/\.vault_pass$" "$REPO_ROOT/.gitignore" 2>/dev/null; then
        print_success ".vault_pass is in .gitignore"
    else
        print_warning ".vault_pass should be in .gitignore"
        ((missing++))
    fi
    
    if grep -q "^inventory/production$" "$REPO_ROOT/.gitignore" 2>/dev/null || \
       grep -q "^/inventory/production$" "$REPO_ROOT/.gitignore" 2>/dev/null; then
        print_success "inventory/production is in .gitignore"
    else
        print_warning "inventory/production should be in .gitignore"
        ((missing++))
    fi
    
    if [ $missing -eq 0 ]; then
        print_success ".gitignore properly configured"
        return 0
    else
        print_warning "$missing sensitive file(s) not in .gitignore"
        print_info "Add to .gitignore: ansible.cfg, .vault_pass, inventory/production"
        return 0  # Warning, not error
    fi
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "$TEST_NAME"
    
    print_info "Testing production credential configuration..."
    print_info "Note: Some tests may be skipped if production mode not configured"
    echo ""
    
    local failed=0
    
    # Run tests
    test_production_templates_exist || ((failed++))
    test_gitignore_configured || true  # Warnings only
    test_ansible_cfg_exists || true  # Not a failure if not configured
    test_ansible_cfg_valid || ((failed++))
    test_inventory_exists || true  # Not a failure if not configured
    test_ansible_connection || ((failed++))
    test_ansible_become || ((failed++))
    test_sudo_configuration || ((failed++))
    test_vault_configuration || ((failed++))
    
    # Report results
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "All production credential tests passed"
        echo ""
        print_info "Production configuration status:"
        if [ -f "$REPO_ROOT/ansible.cfg" ]; then
            print_info "  ✓ Production mode configured"
        else
            print_info "  ○ Production mode not configured (run 'make setup-production')"
        fi
        return 0
    else
        print_error "$failed test(s) failed"
        echo ""
        print_info "To configure production mode:"
        print_info "  1. Run: make setup-production"
        print_info "  2. Follow the prompts to configure credentials"
        print_info "  3. Run: make test-production (to verify)"
        return 1
    fi
}

# Run tests
main "$@"
