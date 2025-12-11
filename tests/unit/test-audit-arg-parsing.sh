#!/usr/bin/env bash
# ==============================================================================
# Property Test: Argument Parsing Consistency
# ==============================================================================
# Feature: dependency-minimization-audit, Property 1: Argument parsing consistency
# Validates: Requirements 10.3
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test helpers
source "$SCRIPT_DIR/../lib/test-helpers.sh"
source "$SCRIPT_DIR/../lib/assertions.sh"

# Test configuration
readonly TEST_NAME="Argument Parsing Consistency"
readonly AUDIT_SCRIPT="$REPO_ROOT/scripts/audit-dependencies.sh"

#------------------------------------------------------------------------------
# Test Functions
#------------------------------------------------------------------------------

test_help_flag() {
    print_section "Test: Help Flag"
    
    # Test --help
    local output
    output=$(bash "$AUDIT_SCRIPT" --help 2>&1 || true)
    
    assert_contains "$output" "Usage:" "Help should show usage"
    assert_contains "$output" "OPTIONS:" "Help should show options"
    assert_contains "$output" "--quick" "Help should document --quick"
    assert_contains "$output" "--fix" "Help should document --fix"
    assert_contains "$output" "--output" "Help should document --output"
    
    # Test -h
    output=$(bash "$AUDIT_SCRIPT" -h 2>&1 || true)
    assert_contains "$output" "Usage:" "Short help flag should work"
    
    print_success "Help flags work correctly"
}

test_quick_mode() {
    print_section "Test: Quick Mode Flag"
    
    # Create minimal test directory
    local test_dir="$REPO_ROOT/tests/fixtures/arg-test"
    mkdir -p "$test_dir"
    
    # Test --quick flag
    local output
    output=$(cd "$test_dir" && bash "$AUDIT_SCRIPT" --quick 2>&1 || true)
    
    assert_contains "$output" "Mode: Quick" "Quick mode should be indicated"
    assert_contains "$output" "Documentation scan" "Quick mode should scan documentation"
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_success "Quick mode flag works correctly"
}

test_output_format() {
    print_section "Test: Output Format Flag"
    
    # Create minimal test directory
    local test_dir="$REPO_ROOT/tests/fixtures/arg-test"
    mkdir -p "$test_dir"
    
    # Test JSON output
    local output
    output=$(cd "$test_dir" && bash "$AUDIT_SCRIPT" --output=json 2>&1 || true)
    
    assert_contains "$output" '"timestamp"' "JSON output should have timestamp"
    assert_contains "$output" '"version"' "JSON output should have version"
    assert_contains "$output" '"summary"' "JSON output should have summary"
    
    # Test markdown output
    output=$(cd "$test_dir" && bash "$AUDIT_SCRIPT" --output=markdown 2>&1 || true)
    
    assert_contains "$output" "# Dependency Minimization Audit Report" "Markdown output should have header"
    assert_contains "$output" "## Summary" "Markdown output should have summary section"
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_success "Output format flag works correctly"
}

test_invalid_argument() {
    print_section "Test: Invalid Argument Handling"
    
    # Test invalid flag
    local output
    local exit_code
    
    set +e
    output=$(bash "$AUDIT_SCRIPT" --invalid-flag 2>&1)
    exit_code=$?
    set -e
    
    assert_equals "$exit_code" "2" "Invalid argument should exit with code 2"
    assert_contains "$output" "Unknown option" "Should report unknown option"
    
    print_success "Invalid arguments handled correctly"
}

test_argument_combinations() {
    print_section "Test: Argument Combinations"
    
    # Create minimal test directory
    local test_dir="$REPO_ROOT/tests/fixtures/arg-test"
    mkdir -p "$test_dir"
    
    # Test --quick with --output=json
    local output
    output=$(cd "$test_dir" && bash "$AUDIT_SCRIPT" --quick --output=json 2>&1 || true)
    
    assert_contains "$output" '"timestamp"' "Combined flags should work"
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_success "Argument combinations work correctly"
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "$TEST_NAME"
    
    local failed=0
    
    # Run tests
    test_help_flag || ((failed++))
    test_quick_mode || ((failed++))
    test_output_format || ((failed++))
    test_invalid_argument || ((failed++))
    test_argument_combinations || ((failed++))
    
    # Report results
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "All tests passed"
        return 0
    else
        print_error "$failed test(s) failed"
        return 1
    fi
}

# Run tests
main "$@"
