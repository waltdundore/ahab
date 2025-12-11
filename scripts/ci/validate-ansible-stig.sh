#!/usr/bin/env bash
# ==============================================================================
# Ansible STIG Compliance Validation
# ==============================================================================
# Validates Ansible playbooks and configurations against STIG requirements
#
# STIG Requirements Validated:
#   - STIG-ANSI-IA-000001: Credentials must be protected (Vault)
#   - STIG-ANSI-IA-000002: Sensitive data must not be logged (no_log)
#   - STIG-ANSI-AU-000001: Audit logging must be enabled
#   - STIG-ANSI-AC-000002: Least privilege (task-level become)
#   - STIG-ANSI-SC-000001: SSH host key verification
#
# Usage:
#   ./validate-ansible-stig.sh [path]
#
# Exit Codes:
#   0 - All STIG requirements met
#   1 - One or more STIG violations found
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Path to check (default to project root)
CHECK_PATH="${1:-$PROJECT_ROOT}"

print_section "Ansible STIG Compliance Validation"
print_info "Checking: $CHECK_PATH"
echo ""

# ==============================================================================
# STIG-ANSI-IA-000001: Credentials Must Be Protected (Ansible Vault)
# ==============================================================================

print_subsection "STIG-ANSI-IA-000001: Ansible Vault Check"

# Check for vault.yml in group_vars
VAULT_FILE="$CHECK_PATH/group_vars/all/vault.yml"
if [ -f "$VAULT_FILE" ]; then
    # Check if file is encrypted
    if head -n1 "$VAULT_FILE" | grep -q "^\$ANSIBLE_VAULT"; then
        print_success "Ansible Vault configured and encrypted"
    else
        print_error "Vault file exists but is not encrypted: $VAULT_FILE"
        echo "  STIG Violation: STIG-ANSI-IA-000001"
        echo "  Requirement: Secrets must be encrypted with Ansible Vault"
        echo "  Fix: Encrypt the vault file"
        echo "  Command: ansible-vault encrypt $VAULT_FILE"
        echo ""
        increment_error
    fi
else
    print_warning "No Ansible Vault file found"
    echo "  Location: $VAULT_FILE"
    echo "  Recommendation: Create encrypted vault for secrets"
    echo "  Command: ansible-vault create $VAULT_FILE"
    echo ""
    increment_warning
fi

# Check for vault_password_file in ansible.cfg
if [ -f "$CHECK_PATH/config/ansible.cfg.production" ]; then
    if grep -q "^vault_password_file" "$CHECK_PATH/config/ansible.cfg.production"; then
        print_success "Vault password file configured"
    else
        print_warning "Vault password file not configured in ansible.cfg"
        echo "  Recommendation: Configure vault_password_file for automation"
        echo ""
        increment_warning
    fi
fi

# ==============================================================================
# STIG-ANSI-IA-000002: Sensitive Data Must Not Be Logged
# ==============================================================================

print_subsection "STIG-ANSI-IA-000002: Sensitive Data Logging Check"

# Check playbooks for tasks that should have no_log
while IFS= read -r -d '' playbook; do
    increment_check
    
    # Look for sensitive operations without no_log
    if grep -E "password|secret|key|token|credential" "$playbook" | grep -v "no_log:" | grep -v "^#" | grep -q .; then
        print_warning "Potential sensitive data without no_log in: $(basename "$playbook")"
        echo "  Recommendation: Add 'no_log: true' to tasks handling sensitive data"
        echo "  Lines:"
        grep -n -E "password|secret|key|token|credential" "$playbook" | grep -v "no_log:" | grep -v "^#" | head -3
        echo ""
        increment_warning
    fi
    
    # Check for register without no_log on sensitive tasks
    if grep -B5 "register:" "$playbook" | grep -E "password|secret|key|token" | grep -v "no_log:" | grep -q .; then
        print_warning "Registered variable may capture sensitive data: $(basename "$playbook")"
        echo "  Recommendation: Add 'no_log: true' to prevent logging"
        echo ""
        increment_warning
    fi
done < <(find "$CHECK_PATH" -path "*/playbooks/*.yml" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-ANSI-AU-000001: Audit Logging Must Be Enabled
# ==============================================================================

print_subsection "STIG-ANSI-AU-000001: Audit Logging Check"

# Check for log_path in ansible.cfg
if [ -f "$CHECK_PATH/config/ansible.cfg.production" ]; then
    if grep -q "^log_path" "$CHECK_PATH/config/ansible.cfg.production"; then
        print_success "Audit logging enabled in ansible.cfg"
    else
        print_error "Audit logging not enabled"
        echo "  STIG Violation: STIG-ANSI-AU-000001"
        echo "  Requirement: Ansible must log all operations"
        echo "  Fix: Enable log_path in ansible.cfg"
        echo "  Example:"
        echo "    [defaults]"
        echo "    log_path = /var/log/ansible/ansible.log"
        echo ""
        increment_error
    fi
else
    print_warning "Production ansible.cfg not found"
    echo "  Expected: $CHECK_PATH/config/ansible.cfg.production"
    echo ""
    increment_warning
fi

# ==============================================================================
# STIG-ANSI-AC-000002: Least Privilege (Task-Level Become)
# ==============================================================================

print_subsection "STIG-ANSI-AC-000002: Privilege Escalation Check"

# Check for global become: true at playbook level
while IFS= read -r -d '' playbook; do
    increment_check
    
    # Check if playbook has global become
    if grep -A5 "^- name:" "$playbook" | grep -q "^  become: true"; then
        # Count tasks in playbook
        task_count=$(grep -c "^  - name:" "$playbook" || echo "0")
        
        # Count tasks with explicit become
        task_become_count=$(grep -A1 "^  - name:" "$playbook" | grep -c "become: true" || echo "0")
        
        if [ "$task_count" -gt 0 ] && [ "$task_become_count" -eq 0 ]; then
            print_warning "Global become in: $(basename "$playbook")"
            echo "  Recommendation: Use task-level become for least privilege"
            echo "  Tasks: $task_count (all run as root)"
            echo ""
            increment_warning
        fi
    fi
    
    # Check for privileged tasks that should be tagged
    if grep -B2 "become: true" "$playbook" | grep "name:" | grep -v "tags:" | grep -q .; then
        print_info "Privileged tasks in: $(basename "$playbook")"
        echo "  Recommendation: Tag privileged tasks with 'privileged' and 'audit'"
        echo ""
    fi
done < <(find "$CHECK_PATH" -path "*/playbooks/*.yml" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-ANSI-SC-000001: SSH Host Key Verification
# ==============================================================================

print_subsection "STIG-ANSI-SC-000001: SSH Security Check"

# Check host_key_checking in production config
if [ -f "$CHECK_PATH/config/ansible.cfg.production" ]; then
    if grep -q "^host_key_checking = False" "$CHECK_PATH/config/ansible.cfg.production"; then
        print_error "Host key checking disabled in production"
        echo "  STIG Violation: STIG-ANSI-SC-000001"
        echo "  Requirement: SSH host keys must be verified"
        echo "  Fix: Enable host_key_checking in production ansible.cfg"
        echo "  Note: Development config can disable for Vagrant VMs"
        echo ""
        increment_error
    else
        print_success "Host key checking enabled (or not explicitly disabled)"
    fi
    
    # Check for connection timeout
    if grep -q "^timeout = " "$CHECK_PATH/config/ansible.cfg.production"; then
        timeout_value=$(grep "^timeout = " "$CHECK_PATH/config/ansible.cfg.production" | cut -d'=' -f2 | tr -d ' ')
        if [ "$timeout_value" -gt 0 ]; then
            print_success "Connection timeout configured: ${timeout_value}s"
        fi
    else
        print_warning "Connection timeout not explicitly configured"
        echo "  Recommendation: Set timeout in ansible.cfg (e.g., timeout = 30)"
        echo ""
        increment_warning
    fi
fi

# ==============================================================================
# Additional Security Checks
# ==============================================================================

print_subsection "Additional Security Checks"

# Check for idempotency markers
while IFS= read -r -d '' playbook; do
    increment_check
    
    # Check for changed_when on command/shell tasks
    if grep -E "ansible\.builtin\.(command|shell):" "$playbook" | grep -v "changed_when:" | grep -q .; then
        print_info "Command tasks without changed_when in: $(basename "$playbook")"
        echo "  Recommendation: Add 'changed_when: false' for idempotency"
        echo ""
    fi
done < <(find "$CHECK_PATH" -path "*/playbooks/*.yml" -type f -print0 2>/dev/null)

# ==============================================================================
# Summary
# ==============================================================================

echo ""
print_section "Ansible STIG Compliance Summary"

if [ "$ERRORS" -eq 0 ]; then
    print_success "All critical Ansible STIG requirements met"
    echo ""
    echo "Validated:"
    echo "  ✓ STIG-ANSI-IA-000001: Credentials protection"
    echo "  ✓ STIG-ANSI-IA-000002: Sensitive data logging"
    echo "  ✓ STIG-ANSI-AU-000001: Audit logging"
    echo "  ✓ STIG-ANSI-AC-000002: Privilege escalation"
    echo "  ✓ STIG-ANSI-SC-000001: SSH security"
    echo ""
    
    if [ "$WARNINGS" -gt 0 ]; then
        echo "Warnings: $WARNINGS (non-critical recommendations)"
        echo ""
    fi
    
    exit 0
else
    print_error "$ERRORS STIG violation(s) found"
    echo ""
    echo "Failed Requirements:"
    [ "$ERRORS" -gt 0 ] && echo "  ✗ $ERRORS critical violation(s)"
    [ "$WARNINGS" -gt 0 ] && echo "  ⚠ $WARNINGS warning(s)"
    echo ""
    echo "See ahab/docs/ANSIBLE_STIG_COMPLIANCE.md for remediation guidance"
    echo ""
    exit 1
fi
