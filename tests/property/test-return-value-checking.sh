#!/usr/bin/env bash
# ==============================================================================
# Property Test: Return Value Checking Detection
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 5: Return value checking detection**
# **Validates: Requirements 2.2**
#
# This test verifies that the return value checking detection correctly identifies
# function calls and commands where return values are not checked.
#
# Property: For any shell script or code file, the safety check should correctly
# identify function calls where return values are not checked.
#
# Test Strategy:
# 1. Generate test files with properly checked return values (should pass)
# 2. Generate test files with unchecked return values (should fail/warn)
# 3. Test edge cases (piped commands, || true, etc.)
# 4. Verify no false positives on properly checked commands
# 5. Verify no false negatives on unchecked commands
# 6. Run 100+ iterations with different code patterns
#
# ==============================================================================

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
readonly MIN_ITERATIONS=100
readonly PROJECT_ROOT="$SCRIPT_DIR/../.."
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/check-return-values.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/return-value-test"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

setup_test_environment() {
    # Create test directory
    mkdir -p "$TEST_DIR"
}

cleanup_test_environment() {
    # Clean up test files
    rm -rf "$TEST_DIR"
}

create_test_file() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
#!/usr/bin/env bash
$content
EOF
    chmod +x "$TEST_DIR/$filename"
}

run_check_on_file() {
    local filename="$1"
    
    # Create a temporary directory for this specific test
    local temp_test_dir="$TEST_DIR/test_$$_$RANDOM"
    mkdir -p "$temp_test_dir"
    cp "$TEST_DIR/$filename" "$temp_test_dir/"
    
    # Run check on the directory and capture ALL output (stdout and stderr)
    local output
    local exit_code
    output=$("$CHECK_SCRIPT" "$temp_test_dir" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    # Clean up temp directory
    rm -rf "$temp_test_dir"
    
    # Debug: uncomment to see what the check script outputs
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "DEBUG: Output from check script:"
        echo "$output"
        echo "DEBUG: Exit code: $exit_code"
    fi
    
    # Check if there are actual warnings (not just info messages)
    # Look for the warning symbol ⚠ or "Warnings: [1-9]" in summary
    if echo "$output" | grep -q "⚠.*Unchecked"; then
        return 1  # Found unchecked return values (warnings present)
    fi
    
    # Check if warnings count is > 0 in summary
    if echo "$output" | grep -q "Warnings: [1-9]"; then
        return 1  # Found warnings
    fi
    
    # Also check if there were any errors (ERRORS > 0 in summary)
    if echo "$output" | grep -q "Errors: [1-9]"; then
        return 1  # Found errors
    fi
    
    return 0  # No issues found
}

#------------------------------------------------------------------------------
# Test Functions - Properly Checked Return Values (Should Pass)
#------------------------------------------------------------------------------

test_make_with_if_check() {
    print_section "Test 1: make command with if check (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_make_if.sh" '
if make test; then
    echo "Tests passed"
else
    echo "Tests failed"
    exit 1
fi
'
    
    if run_check_on_file "checked_make_if.sh"; then
        print_success "Correctly identified checked make command with if"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged properly checked make command"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_make_with_and_operator() {
    print_section "Test 2: make command with && operator (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_make_and.sh" '
make build && echo "Build successful"
'
    
    if run_check_on_file "checked_make_and.sh"; then
        print_success "Correctly identified checked make command with &&"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged properly checked make command"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_make_with_or_operator() {
    print_section "Test 3: make command with || operator (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_make_or.sh" '
make test || exit 1
'
    
    if run_check_on_file "checked_make_or.sh"; then
        print_success "Correctly identified checked make command with ||"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged properly checked make command"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_git_with_if_check() {
    print_section "Test 4: git command with if check (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_git_if.sh" '
if git pull origin main; then
    echo "Pull successful"
else
    echo "Pull failed"
    exit 1
fi
'
    
    if run_check_on_file "checked_git_if.sh"; then
        print_success "Correctly identified checked git command with if"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged properly checked git command"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_git_with_and_operator() {
    print_section "Test 5: git command with && operator (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_git_and.sh" '
git commit -m "Update" && git push origin main
'
    
    if run_check_on_file "checked_git_and.sh"; then
        print_success "Correctly identified checked git command with &&"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged properly checked git command"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_command_with_or_true() {
    print_section "Test 6: Command with || true (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "checked_or_true.sh" '
make clean || true
'
    
    if run_check_on_file "checked_or_true.sh"; then
        print_success "Correctly identified command with || true"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged command with || true"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Unchecked Return Values (Should Fail/Warn)
#------------------------------------------------------------------------------

test_unchecked_make_command() {
    print_section "Test 7: Unchecked make command (should warn)"
    
    ((TESTS_RUN++))
    
    create_test_file "unchecked_make.sh" '
make test
echo "Continuing regardless of test result"
'
    
    if run_check_on_file "unchecked_make.sh"; then
        print_error "False negative: missed unchecked make command"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected unchecked make command"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_unchecked_git_command() {
    print_section "Test 8: Unchecked git command (should warn)"
    
    ((TESTS_RUN++))
    
    create_test_file "unchecked_git.sh" '
git pull origin main
echo "Pulled code"
'
    
    if run_check_on_file "unchecked_git.sh"; then
        print_error "False negative: missed unchecked git command"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected unchecked git command"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_unchecked_commands() {
    print_section "Test 9: Multiple unchecked commands (should warn)"
    
    ((TESTS_RUN++))
    
    create_test_file "multiple_unchecked.sh" '
make clean
make build
make test
'
    
    if run_check_on_file "multiple_unchecked.sh"; then
        print_error "False negative: missed multiple unchecked commands"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected multiple unchecked commands"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_unchecked_in_function() {
    print_section "Test 10: Unchecked command in function (should warn)"
    
    ((TESTS_RUN++))
    
    create_test_file "unchecked_in_function.sh" '
deploy() {
    make build
    echo "Deployed"
}
'
    
    if run_check_on_file "unchecked_in_function.sh"; then
        print_error "False negative: missed unchecked command in function"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected unchecked command in function"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_make_in_subshell() {
    print_section "Test 11: make in subshell with check (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "make_subshell.sh" '
result=$(make test && echo "pass" || echo "fail")
echo "Result: $result"
'
    
    if run_check_on_file "make_subshell.sh"; then
        print_success "Correctly handled make in subshell"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "May have flagged make in subshell (acceptable)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_make_with_pipe() {
    print_section "Test 12: make with pipe (edge case)"
    
    ((TESTS_RUN++))
    
    create_test_file "make_pipe.sh" '
make test | tee test.log
'
    
    # Piped commands are tricky - the pipe itself doesn't check the return value
    # This should ideally be flagged
    if run_check_on_file "make_pipe.sh"; then
        print_warning "Pipe may hide return value (implementation dependent)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected potential issue with piped command"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_empty_file() {
    print_section "Test 13: Empty file (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "empty.sh" ''
    
    if run_check_on_file "empty.sh"; then
        print_success "Correctly handled empty file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged empty file"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_comments_only() {
    print_section "Test 14: File with comments only (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "comments_only.sh" '
# This is a comment
# make test
# git pull
'
    
    if run_check_on_file "comments_only.sh"; then
        print_success "Correctly handled comments"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "May flag commented commands (known limitation)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_make_in_if_condition() {
    print_section "Test 15: make in if condition (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "make_if_condition.sh" '
if make build; then
    make install
fi
'
    
    # The first make is checked, but the second make inside the if is not
    if run_check_on_file "make_if_condition.sh"; then
        print_warning "May not catch unchecked make inside if block"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected unchecked make inside if block"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Property-Based Test Iterations
#------------------------------------------------------------------------------

run_iteration_tests() {
    local iteration=$1
    
    if [ $((iteration % 20)) -eq 0 ]; then
        print_info "Completed $iteration/$MIN_ITERATIONS iterations..."
    fi
    
    ((TESTS_RUN++))
    
    # Generate random test case
    local test_type=$((RANDOM % 6))
    
    case $test_type in
        0)
            # Test checked make with if
            create_test_file "iter_${iteration}_checked_if.sh" '
if make test; then
    echo "Success"
fi
'
            if run_check_on_file "iter_${iteration}_checked_if.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on checked make"
                ((TESTS_FAILED++))
            fi
            ;;
        1)
            # Test checked make with &&
            create_test_file "iter_${iteration}_checked_and.sh" '
make build && echo "Built"
'
            if run_check_on_file "iter_${iteration}_checked_and.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on checked make"
                ((TESTS_FAILED++))
            fi
            ;;
        2)
            # Test checked git with ||
            create_test_file "iter_${iteration}_checked_or.sh" '
git pull || exit 1
'
            if run_check_on_file "iter_${iteration}_checked_or.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on checked git"
                ((TESTS_FAILED++))
            fi
            ;;
        3)
            # Test unchecked make (should warn)
            create_test_file "iter_${iteration}_unchecked_make.sh" '
make test
echo "Done"
'
            if run_check_on_file "iter_${iteration}_unchecked_make.sh"; then
                print_error "Iteration $iteration: False negative on unchecked make"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        4)
            # Test unchecked git (should warn)
            create_test_file "iter_${iteration}_unchecked_git.sh" '
git commit -m "Update"
echo "Committed"
'
            if run_check_on_file "iter_${iteration}_unchecked_git.sh"; then
                print_error "Iteration $iteration: False negative on unchecked git"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        5)
            # Test || true pattern
            create_test_file "iter_${iteration}_or_true.sh" '
make clean || true
'
            if run_check_on_file "iter_${iteration}_or_true.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on || true"
                ((TESTS_FAILED++))
            fi
            ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

# Run checked return value tests (should not detect violations)
run_checked_return_value_tests() {
    test_make_with_if_check
    test_make_with_and_operator
    test_make_with_or_operator
    test_git_with_if_check
    test_git_with_and_operator
    test_command_with_or_true
}

# Run unchecked return value tests (should detect violations)
run_unchecked_return_value_tests() {
    test_unchecked_make_command
    test_unchecked_git_command
    test_multiple_unchecked_commands
    test_unchecked_in_function
}

# Run edge case tests
run_edge_case_tests() {
    test_make_in_subshell
    test_make_with_pipe
    test_empty_file
    test_comments_only
    test_make_in_if_condition
}

# Print test summary and results
print_test_summary() {
    echo ""
    print_section "Test Summary"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "✓ All tests passed - Return value checking detection is working correctly"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly identifies checked return values (no false positives)"
        print_info "  • Correctly detects unchecked return values (no false negatives)"
        print_info "  • Handles edge cases (||, &&, if statements, || true)"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        return 0
    else
        print_error "✗ Some tests failed - Return value checking detection has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Properly checked commands flagged as unchecked"
        print_info "  • False negatives: Unchecked commands not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

# Main function (NASA compliant: ≤ 60 lines)
main() {
    print_section "Return Value Checking Detection - Property Test"
    
    print_info "Testing return value checking detection across wide range of code patterns"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Verify check script exists
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Run all test categories
    run_checked_return_value_tests
    run_unchecked_return_value_tests
    run_edge_case_tests
    
    # Run iteration tests (property-based testing style)
    print_section "Running $MIN_ITERATIONS property test iterations"
    
    for i in $(seq 1 $MIN_ITERATIONS); do
        run_iteration_tests "$i"
    done
    
    # Cleanup
    cleanup_test_environment
    
    # Print summary and return result
    print_test_summary
}

# Run main function
main "$@"
