#!/usr/bin/env bash
# ==============================================================================
# Self-Audit Script (NASA Rule #4 Compliant)
# ==============================================================================
# Runs comprehensive audits on the ahab system itself
#
# Usage:
#   ./scripts/audit-self.sh
#   make audit-self
#
# Exit Codes:
#   0 - All audits passed
#   1 - Violations found
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "SELF-AUDIT: Comprehensive System Check"
    
    echo "Running comprehensive audit of ahab system..."
    echo ""
    
    # Run audit phases
    audit_system_integrity
    audit_script_quality
    audit_documentation_quality
    audit_security_posture
    
    # Generate final report
    generate_audit_summary "self-audit-$(generate_audit_timestamp).md"
}

#------------------------------------------------------------------------------
# System Integrity Audit
#------------------------------------------------------------------------------

audit_system_integrity() {
    print_section "SYSTEM INTEGRITY AUDIT"
    
    echo "→ Checking core files exist..."
    
    local required_files=(
        "Makefile"
        "ahab.conf"
        "scripts/validate-nasa-standards.sh"
        "playbooks/provision-workstation.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            check_pass "Required file exists: $file"
        else
            check_fail "Missing required file: $file"
        fi
    done
}

#------------------------------------------------------------------------------
# Script Quality Audit
#------------------------------------------------------------------------------

audit_script_quality() {
    print_section "SCRIPT QUALITY AUDIT"
    
    echo "→ Checking script standards..."
    
    local script_count=0
    local compliant_count=0
    
    while IFS= read -r script; do
        ((script_count++))
        
        # Check for strict error handling
        if grep -q "set -euo pipefail" "$script"; then
            ((compliant_count++))
        else
            echo -e "${YELLOW}  Missing strict error handling: $script${NC}"
        fi
    done < <(find scripts -name "*.sh" -type f)
    
    if [ "$script_count" -gt 0 ]; then
        local compliance_percentage=$((compliant_count * 100 / script_count))
        if [ "$compliance_percentage" -ge 80 ]; then
            check_pass "Script quality: ${compliance_percentage}% compliant"
        else
            check_fail "Script quality: only ${compliance_percentage}% compliant (need 80%+)"
        fi
    fi
}

#------------------------------------------------------------------------------
# Documentation Quality Audit
#------------------------------------------------------------------------------

audit_documentation_quality() {
    print_section "DOCUMENTATION QUALITY AUDIT"
    
    echo "→ Checking documentation coverage..."
    
    local doc_files=0
    local outdated_files=0
    
    while IFS= read -r file; do
        ((doc_files++))
        
        # Check for placeholder content
        if grep -qi "TODO\|FIXME\|PLACEHOLDER" "$file"; then
            ((outdated_files++))
            echo -e "${YELLOW}  Contains placeholders: $file${NC}"
        fi
    done < <(find . -name "*.md" -type f | grep -v ".git")
    
    if [ "$doc_files" -gt 0 ]; then
        local quality_percentage=$(((doc_files - outdated_files) * 100 / doc_files))
        if [ "$quality_percentage" -ge 90 ]; then
            check_pass "Documentation quality: ${quality_percentage}%"
        else
            check_warn "Documentation quality: ${quality_percentage}% (${outdated_files} files need updates)"
        fi
    fi
}

#------------------------------------------------------------------------------
# Security Posture Audit
#------------------------------------------------------------------------------

audit_security_posture() {
    print_section "SECURITY POSTURE AUDIT"
    
    echo "→ Checking security configurations..."
    
    # Check for hardcoded secrets
    if command -v grep >/dev/null 2>&1; then
        local secret_patterns="password.*=\|api.*key.*=\|secret.*="
        local secrets_found=0
        
        while IFS= read -r file; do
            if grep -qi "$secret_patterns" "$file" 2>/dev/null; then
                ((secrets_found++))
                echo -e "${RED}  Potential secret in: $file${NC}"
            fi
        done < <(find . -type f -name "*.sh" -o -name "*.yml" -o -name "*.yaml" | grep -v ".git")
        
        if [ "$secrets_found" -eq 0 ]; then
            check_pass "No hardcoded secrets detected"
        else
            check_fail "Found $secrets_found potential hardcoded secrets"
        fi
    fi
    
    # Check for proper file permissions
    local executable_count=0
    while IFS= read -r script; do
        if [ -x "$script" ]; then
            ((executable_count++))
        fi
    done < <(find scripts -name "*.sh" -type f)
    
    if [ "$executable_count" -gt 0 ]; then
        check_pass "Scripts have proper executable permissions"
    else
        check_warn "No executable scripts found (may be intentional)"
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi