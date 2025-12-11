#!/usr/bin/env bash
# ==============================================================================
# Dependency Minimization Audit Script (NASA Rule #4 Compliant)
# ==============================================================================
# Verifies adherence to the "Make-only, minimal dependencies" principle
#
# Usage:
#   ./scripts/audit-dependencies.sh [--quick]
#   make audit-deps
#
# Exit codes: 0=pass, 1=violations, 2=error
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"

# Global variables
QUICK_MODE=false

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    parse_arguments "$@"
    
    print_header "DEPENDENCY MINIMIZATION AUDIT"
    
    echo "Auditing adherence to 'Make-only, minimal dependencies' principle..."
    echo ""
    
    # Run audit phases
    if [ "$QUICK_MODE" = true ]; then
        audit_documentation_only
    else
        audit_all_dependencies
    fi
    
    # Generate report
    generate_audit_summary "dependency-audit-$(generate_audit_timestamp).md"
}

#------------------------------------------------------------------------------
# Argument Parsing
#------------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --quick         Run quick scan (documentation only)
    --help, -h      Show this help message

Exit codes:
    0   No violations found
    1   Violations detected
    2   Error during audit

Examples:
    $0                    # Full audit
    $0 --quick            # Quick documentation scan
EOF
}

#------------------------------------------------------------------------------
# Audit Functions
#------------------------------------------------------------------------------

audit_documentation_only() {
    print_section "DOCUMENTATION AUDIT"
    scan_for_direct_commands
}

audit_all_dependencies() {
    print_section "COMPREHENSIVE DEPENDENCY AUDIT"
    
    scan_for_direct_commands
    scan_makefiles_integration
    scan_docker_dependencies
}

#------------------------------------------------------------------------------
# Scanner Functions
#------------------------------------------------------------------------------

scan_for_direct_commands() {
    echo "→ Scanning for direct tool usage (should use make)..."
    
    local violations=0
    
    # Check documentation files
    while IFS= read -r file; do
        if grep -q "vagrant up\|docker run\|ansible-playbook" "$file" 2>/dev/null; then
            echo -e "${YELLOW}  Direct command in: $file${NC}"
            ((violations++))
        fi
    done < <(find . -name "*.md" -type f | grep -v ".git")
    
    if [ "$violations" -eq 0 ]; then
        check_pass "No direct tool usage found in documentation"
    else
        check_warn "$violations files contain direct tool usage (should suggest make commands)"
    fi
}

scan_makefiles_integration() {
    echo ""
    echo "→ Checking Makefile integration..."
    
    if [ -f "Makefile" ]; then
        check_pass "Primary Makefile exists"
        
        # Check for key targets
        local required_targets=("install" "test" "clean")
        for target in "${required_targets[@]}"; do
            if grep -q "^${target}:" Makefile; then
                check_pass "Target '$target' exists in Makefile"
            else
                check_fail "Target '$target' missing from Makefile"
            fi
        done
    else
        check_fail "Primary Makefile missing"
    fi
}

scan_docker_dependencies() {
    echo ""
    echo "→ Checking Docker dependency management..."
    
    local docker_files=0
    
    while IFS= read -r file; do
        ((docker_files++))
        
        # Check for minimal base images
        if grep -q "FROM.*:latest" "$file"; then
            check_warn "Using :latest tag in $file (prefer specific versions)"
        fi
        
        # Check for non-root users
        if ! grep -q "USER " "$file"; then
            check_warn "No USER directive in $file (should run as non-root)"
        fi
    done < <(find . -name "Dockerfile*" -type f | grep -v ".git")
    
    if [ "$docker_files" -eq 0 ]; then
        check_pass "No Dockerfiles found to audit"
    else
        check_pass "Audited $docker_files Docker files"
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
