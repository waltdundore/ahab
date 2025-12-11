#!/usr/bin/env bash
# ==============================================================================
# Zero Trust Demo Script - MANDATORY
# ==============================================================================
# Concise demonstration of refactored checking functionality that never assumes success
#
# Usage:
#   ./scripts/zero-trust-demo.sh
#   make zero-trust-demo
#
# Exit Codes:
#   0 - All checks passed
#   1 - Some checks failed
#   2 - Critical failures detected
# ==============================================================================

set -euo pipefail

# Source the zero trust checking library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/zero-trust-checking.sh
source "$SCRIPT_DIR/lib/zero-trust-checking.sh"

#------------------------------------------------------------------------------
# Core Zero Trust Demonstration Functions
#------------------------------------------------------------------------------

demo_file_verification() {
    echo "→ Demo: File Verification (Never Assume Files Exist)"
    
    # Use current working directory (we're running from ahab/)
    local test_file="Makefile"
    
    # ✅ Zero Trust: Verify each property explicitly
    zt_verify_file_operation "exists" "$test_file" || return 1
    zt_verify_file_operation "readable" "$test_file" || return 1
    zt_verify_file_operation "contains" "$test_file" "help:" || return 1
}

demo_command_execution() {
    echo "→ Demo: Command Execution (Never Assume Commands Succeed)"
    
    local test_file="/tmp/zt-demo-$$"
    
    # ✅ Zero Trust: Verify creation, execution, and cleanup
    if echo "test" > "$test_file" 2>/dev/null; then
        zt_verify_file_operation "exists" "$test_file" || return 1
        
        local output
        if output=$(zt_execute_and_verify "wc-demo" 5 wc -l "$test_file"); then
            if echo "$output" | grep -q "1.*$test_file"; then
                zt_check_pass "Command output verified"
            else
                zt_check_fail "Unexpected command output: $output"
                return 1
            fi
        fi
        
        rm -f "$test_file" 2>/dev/null || zt_check_warn "Cleanup failed"
    else
        zt_check_fail "Cannot create test file"
        return 1
    fi
}

demo_make_verification() {
    echo "→ Demo: Make Command Verification (Never Assume Targets Work)"
    
    # Use current working directory (we're running from ahab/)
    local makefile="Makefile"
    
    # ✅ Zero Trust: Verify Makefile exists and target is valid
    if zt_verify_file_operation "exists" "$makefile"; then
        if grep -q "^help:" "$makefile" 2>/dev/null; then
            zt_check_pass "Make target 'help' verified in Makefile"
        else
            zt_check_fail "Make target 'help' not found"
            return 1
        fi
    else
        zt_check_fail "Makefile not found"
        return 1
    fi
}

demo_network_verification() {
    echo "→ Demo: Network Verification (Never Assume Network Works)"
    
    # ✅ Zero Trust: Test local first, then external
    if zt_verify_network_operation "ping" "127.0.0.1" 2; then
        zt_check_pass "Local network verified"
    else
        zt_check_warn "Local network not functional"
    fi
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "Zero Trust Checking Demo"
    echo "=========================================="
    echo ""
    
    # Initialize zero trust checking
    if ! zt_init_checking "zero-trust-demo"; then
        echo "CRITICAL: Cannot initialize zero trust checking"
        exit 2
    fi
    
    # Run demonstrations
    local demos=(
        "demo_file_verification"
        "demo_command_execution"
        "demo_make_verification"
        "demo_network_verification"
    )
    
    local failed_demos=0
    
    for demo in "${demos[@]}"; do
        echo ""
        if ! "$demo"; then
            ((failed_demos++))
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "Demo Summary"
    echo "=========================================="
    echo "Failed demos: $failed_demos"
    echo ""
    
    # Generate final report
    local exit_code
    if zt_finalize_checking "zero-trust-demo"; then
        exit_code=$?
    else
        exit_code=$?
    fi
    
    # Clean up
    zt_cleanup
    
    return $exit_code
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi