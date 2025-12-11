#!/bin/bash
# ==============================================================================
# Security Standards Validation Script
# ==============================================================================
# Validates that all code follows security and code quality standards for
# safety-critical systems.
#
# Usage:
#   ./scripts/validate-security-standards.sh
#
# Exit Codes:
#   0 - All checks passed
#   1 - Violations found
#
# MANDATORY: This must pass before ANY commit.
# ==============================================================================

set -euo pipefail

# Source common functions (includes colors)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/security-validation-common.sh
source "$SCRIPT_DIR/lib/security-validation-common.sh"

ERRORS=0

# All validation functions moved to security-validation-common.sh for reusability

# ==============================================================================
# Security Checks
# ==============================================================================
check_security() {
    echo "Checking Security..."
    echo ""
    
    # Use the improved security validation script
    if [ -f "scripts/ci/validate-security-patterns.sh" ]; then
        echo "→ Running improved security pattern validation..."
        if ./scripts/ci/validate-security-patterns.sh >/dev/null 2>&1; then
            echo "✓ PASS: Security pattern validation complete"
        else
            echo "✗ FAIL: Security pattern violations found"
            echo "  Run 'make test-security' for details"
            ((ERRORS++))
        fi
    else
        echo "⚠ WARNING: Improved security validation script not found"
        echo "  Falling back to basic checks..."
        
        if ! check_hardcoded_secrets; then
            ((ERRORS++))
        fi
        
        echo ""
        if ! check_command_injection; then
            ((ERRORS++))
        fi
        
        echo ""
        if ! check_privileged_containers; then
            ((ERRORS++))
        fi
    fi
    echo ""
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    echo "=========================================="
    echo "Security Standards Validation"
    echo "=========================================="
    echo ""
    
    # Run all checks and count errors
    check_rule_s10_zero_warnings || ((ERRORS++))
    echo ""
    check_rule_s2_bounded_loops || ((ERRORS++))
    echo ""
    check_rule_s7_return_values || ((ERRORS++))
    echo ""
    check_rule_s4_function_length || ((ERRORS++))
    echo ""
    check_ansible_playbooks || ((ERRORS++))
    echo ""
    check_makefile || ((ERRORS++))
    echo ""
    check_security
    
    # Final result
    if [ $ERRORS -eq 0 ]; then
        echo "=========================================="
        echo "✅ ALL CHECKS PASSED"
        echo "=========================================="
        echo ""
        echo "Code meets security standards."
        exit 0
    else
        echo "=========================================="
        echo "❌ $ERRORS CHECKS FAILED"
        echo "=========================================="
        echo ""
        echo "Code does NOT meet security standards."
        echo "Fix violations before committing."
        echo ""
        echo "See DEVELOPMENT_RULES.md for details on each rule."
        exit 1
    fi
}

# Run main function
main "$@"