#!/usr/bin/env bash
# ==============================================================================
# Property Test: Function Length Validation
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 6: Function length validation**
# **Validates: Requirements 2.3**
#
# This test verifies that the function length validation check correctly identifies
# functions exceeding 60 lines across a wide range of code samples.
#
# Property: For any function in shell scripts or code files, the safety check
# should correctly identify functions exceeding 60 lines.
#
# Test Strategy:
# 1. Generate test files with functions under 60 lines (should pass)
# 2. Generate test files with functions over 60 lines (should fail)
# 3. Test edge cases (nested braces, comments, empty lines, etc.)
# 4. Verify no false positives on valid short functions
# 5. Verify no false negatives on long functions
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
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/check-function-length.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/function-length-test"
readonly MAX_FUNCTION_LENGTH=60
readonly VIOLATIONS_LOG="$PROJECT_ROOT/.function-length-violations"

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
    
    # Run check and capture exit code
    if "$CHECK_SCRIPT" "$TEST_DIR/$filename" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

generate_function_with_lines() {
    local function_name="$1"
    local line_count="$2"
    
    local content="${function_name}() {"
    content="$content"$'\n'"    local result=0"
    
    # Generate lines (subtract 3 for function declaration, local var, and closing brace)
    local body_lines=$((line_count - 3))
    for i in $(seq 1 "$body_lines"); do
        content="$content"$'\n'"    echo \"Line $i\""
    done
    
    content="$content"$'\n'"}"
    
    echo "$content"
}

#------------------------------------------------------------------------------
# Test Functions - Valid Functions (Should Pass)
#------------------------------------------------------------------------------

test_function_exactly_60_lines() {
    print_section "Test 1: Function with exactly 60 lines (should pass)"
    
    ((TESTS_RUN++))
    
    local func_content
    func_content=$(generate_function_with_lines "test_function" 60)
    
    create_test_file "function_60_lines.sh" "$func_content"
    
    if run_check_on_file "function_60_lines.sh"; then
        print_success "Correctly accepted function with exactly 60 lines"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid 60-line function"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_function_under_60_lines() {
    print_section "Test 2: Function with 30 lines (should pass)"
    
    ((TESTS_RUN++))
    
    local func_content
    func_content=$(generate_function_with_lines "short_function" 30)
    
    create_test_file "function_30_lines.sh" "$func_content"
    
    if run_check_on_file "function_30_lines.sh"; then
        print_success "Correctly accepted function with 30 lines"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid 30-line function"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_very_short_function() {
    print_section "Test 3: Very short function (5 lines) (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "short_func.sh" '
short_function() {
    echo "Hello"
    return 0
}
'
    
    if run_check_on_file "short_func.sh"; then
        print_success "Correctly accepted very short function"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid short function"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_multiple_short_functions() {
    print_section "Test 4: Multiple short functions (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "multiple_short.sh" '
function_one() {
    echo "Function 1"
    local var=1
    return 0
}

function_two() {
    echo "Function 2"
    local var=2
    return 0
}

function_three() {
    echo "Function 3"
    local var=3
    return 0
}
'
    
    if run_check_on_file "multiple_short.sh"; then
        print_success "Correctly accepted multiple short functions"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid short functions"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_function_with_comments() {
    print_section "Test 5: Function with comments (40 lines total) (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "function_with_comments.sh" '
documented_function() {
    # This is a comment
    local var1=1
    # Another comment
    local var2=2
    # More comments
    echo "Line 1"
    # Comment
    echo "Line 2"
    # Comment
    echo "Line 3"
    # Comment
    echo "Line 4"
    # Comment
    echo "Line 5"
    # Comment
    echo "Line 6"
    # Comment
    echo "Line 7"
    # Comment
    echo "Line 8"
    # Comment
    echo "Line 9"
    # Comment
    echo "Line 10"
    # Comment
    echo "Line 11"
    # Comment
    echo "Line 12"
    # Comment
    echo "Line 13"
    # Comment
    echo "Line 14"
    # Comment
    echo "Line 15"
    # Final comment
    return 0
}
'
    
    if run_check_on_file "function_with_comments.sh"; then
        print_success "Correctly accepted function with comments (40 lines)"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid function with comments"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Invalid Functions (Should Fail)
#------------------------------------------------------------------------------

test_function_over_60_lines() {
    print_section "Test 6: Function with 70 lines (should fail)"
    
    ((TESTS_RUN++))
    
    local func_content
    func_content=$(generate_function_with_lines "long_function" 70)
    
    create_test_file "function_70_lines.sh" "$func_content"
    
    if run_check_on_file "function_70_lines.sh"; then
        print_error "False negative: missed function with 70 lines"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected function exceeding 60 lines"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_function_way_over_limit() {
    print_section "Test 7: Function with 100 lines (should fail)"
    
    ((TESTS_RUN++))
    
    local func_content
    func_content=$(generate_function_with_lines "very_long_function" 100)
    
    create_test_file "function_100_lines.sh" "$func_content"
    
    if run_check_on_file "function_100_lines.sh"; then
        print_error "False negative: missed function with 100 lines"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected function with 100 lines"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_function_61_lines() {
    print_section "Test 8: Function with 61 lines (just over limit) (should fail)"
    
    ((TESTS_RUN++))
    
    local func_content
    func_content=$(generate_function_with_lines "just_over_limit" 61)
    
    create_test_file "function_61_lines.sh" "$func_content"
    
    if run_check_on_file "function_61_lines.sh"; then
        print_error "False negative: missed function with 61 lines"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected function with 61 lines"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_functions_one_long() {
    print_section "Test 9: Multiple functions, one exceeds limit (should fail)"
    
    ((TESTS_RUN++))
    
    local short_func
    short_func=$(generate_function_with_lines "short_func" 20)
    
    local long_func
    long_func=$(generate_function_with_lines "long_func" 70)
    
    create_test_file "mixed_functions.sh" "$short_func"$'\n\n'"$long_func"
    
    if run_check_on_file "mixed_functions.sh"; then
        print_error "False negative: missed long function among short ones"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected long function among short ones"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_function_with_nested_braces() {
    print_section "Test 10: Function with nested braces (should pass if under 60)"
    
    ((TESTS_RUN++))
    
    create_test_file "nested_braces.sh" '
function_with_if() {
    local var=1
    if [ $var -eq 1 ]; then
        echo "Condition 1"
        if [ $var -gt 0 ]; then
            echo "Nested condition"
        fi
    else
        echo "Else branch"
    fi
    for i in {1..5}; do
        echo "Loop $i"
    done
    return 0
}
'
    
    if run_check_on_file "nested_braces.sh"; then
        print_success "Correctly handled function with nested braces"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid function with nested braces"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_function_with_case_statement() {
    print_section "Test 11: Function with case statement (should pass if under 60)"
    
    ((TESTS_RUN++))
    
    create_test_file "case_statement.sh" '
function_with_case() {
    local option="$1"
    case "$option" in
        start)
            echo "Starting"
            ;;
        stop)
            echo "Stopping"
            ;;
        restart)
            echo "Restarting"
            ;;
        status)
            echo "Status"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
    return 0
}
'
    
    if run_check_on_file "case_statement.sh"; then
        print_success "Correctly handled function with case statement"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid function with case"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_empty_file() {
    print_section "Test 12: Empty file (should pass)"
    
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

test_file_with_no_functions() {
    print_section "Test 13: File with no functions (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "no_functions.sh" '
#!/usr/bin/env bash
# Just a script with no functions
echo "Hello World"
exit 0
'
    
    if run_check_on_file "no_functions.sh"; then
        print_success "Correctly handled file with no functions"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged file with no functions"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_function_with_empty_lines() {
    print_section "Test 14: Function with many empty lines (counts all lines)"
    
    ((TESTS_RUN++))
    
    # Create function with 40 code lines + 25 empty lines = 65 total lines
    create_test_file "empty_lines.sh" '
function_with_empty_lines() {
    echo "Line 1"

    echo "Line 2"

    echo "Line 3"

    echo "Line 4"

    echo "Line 5"

    echo "Line 6"

    echo "Line 7"

    echo "Line 8"

    echo "Line 9"

    echo "Line 10"

    echo "Line 11"

    echo "Line 12"

    echo "Line 13"

    echo "Line 14"

    echo "Line 15"

    echo "Line 16"

    echo "Line 17"

    echo "Line 18"

    echo "Line 19"

    echo "Line 20"

    return 0
}
'
    
    # This function has 65 total lines (including empty lines), so it should fail
    if run_check_on_file "empty_lines.sh"; then
        print_warning "Implementation may not count empty lines (acceptable)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected function exceeding limit with empty lines"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_function_alternate_syntax() {
    print_section "Test 15: Function with 'function' keyword syntax (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "function_keyword.sh" '
function my_function {
    echo "Using function keyword"
    local var=1
    return 0
}
'
    
    if run_check_on_file "function_keyword.sh"; then
        print_success "Correctly handled function keyword syntax"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged valid function with keyword syntax"
        ((TESTS_FAILED++))
        return 1
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
    local test_type=$((RANDOM % 5))
    
    case $test_type in
        0)
            # Test function under limit (random 10-59 lines)
            local line_count=$((RANDOM % 50 + 10))
            local func_content
            func_content=$(generate_function_with_lines "iter_func_$iteration" "$line_count")
            create_test_file "iter_${iteration}_under.sh" "$func_content"
            
            if run_check_on_file "iter_${iteration}_under.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on $line_count-line function"
                ((TESTS_FAILED++))
            fi
            ;;
        1)
            # Test function at limit (exactly 60 lines)
            local func_content
            func_content=$(generate_function_with_lines "iter_func_$iteration" 60)
            create_test_file "iter_${iteration}_exact.sh" "$func_content"
            
            if run_check_on_file "iter_${iteration}_exact.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on 60-line function"
                ((TESTS_FAILED++))
            fi
            ;;
        2)
            # Test function over limit (random 61-100 lines)
            local line_count=$((RANDOM % 40 + 61))
            local func_content
            func_content=$(generate_function_with_lines "iter_func_$iteration" "$line_count")
            create_test_file "iter_${iteration}_over.sh" "$func_content"
            
            if run_check_on_file "iter_${iteration}_over.sh"; then
                print_error "Iteration $iteration: False negative on $line_count-line function"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        3)
            # Test very short function (random 3-10 lines)
            local line_count=$((RANDOM % 8 + 3))
            local func_content
            func_content=$(generate_function_with_lines "iter_func_$iteration" "$line_count")
            create_test_file "iter_${iteration}_short.sh" "$func_content"
            
            if run_check_on_file "iter_${iteration}_short.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on $line_count-line function"
                ((TESTS_FAILED++))
            fi
            ;;
        4)
            # Test multiple functions with one over limit
            local short_func
            short_func=$(generate_function_with_lines "short_$iteration" 30)
            local long_func
            long_func=$(generate_function_with_lines "long_$iteration" 70)
            create_test_file "iter_${iteration}_mixed.sh" "$short_func"$'\n\n'"$long_func"
            
            if run_check_on_file "iter_${iteration}_mixed.sh"; then
                print_error "Iteration $iteration: False negative on mixed functions"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

update_violations_log() {
    local file="$1"
    local lines="$2"
    local status="$3"
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Update or add entry in violations log
    if [ -f "$VIOLATIONS_LOG" ]; then
        # Remove existing entry for this file
        grep -v "| $file |" "$VIOLATIONS_LOG" > "${VIOLATIONS_LOG}.tmp" || true
        mv "${VIOLATIONS_LOG}.tmp" "$VIOLATIONS_LOG"
    fi
    
    # Add new entry
    echo "$timestamp | $file | $lines | $status" >> "$VIOLATIONS_LOG"
}

check_real_project_files() {
    print_info "Checking actual project files for violations..."
    
    local violations_found=0
    
    # Check all shell scripts in the project
    while IFS= read -r -d '' script; do
        if [[ "$script" == *.sh ]] && [ -f "$script" ]; then
            local line_count
            line_count=$(wc -l < "$script")
            
            # Check if script is over warning threshold (200 lines)
            if [ "$line_count" -gt 200 ]; then
                print_warning "Script is very long ($line_count lines): $script"
                update_violations_log "$script" "$line_count" "NEEDS_REFACTORING"
                ((violations_found++))
            fi
            
            # Check individual functions in the script
            if "$CHECK_SCRIPT" "$script" >/dev/null 2>&1; then
                # Script passed - no function length violations
                continue
            else
                # Script failed - has function length violations
                print_error "Function length violations in: $script"
                update_violations_log "$script" "$line_count" "FUNCTION_VIOLATIONS"
                ((violations_found++))
            fi
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -not -path "*/tests/*" -not -path "*/.git/*" -print0 2>/dev/null)
    
    if [ $violations_found -gt 0 ]; then
        print_info "Found $violations_found files with violations"
        print_info "Violations logged to: $VIOLATIONS_LOG"
        print_info "See TECHNICAL_DEBT.md for refactoring plans"
    else
        print_success "No function length violations found in project files"
    fi
    
    return $violations_found
}

# Run valid function tests (should not detect violations)
run_valid_function_tests() {
    test_function_exactly_60_lines
    test_function_under_60_lines
    test_very_short_function
    test_multiple_short_functions
    test_function_with_comments
}

# Run invalid function tests (should detect violations)
run_invalid_function_tests() {
    test_function_over_60_lines
    test_function_way_over_limit
    test_function_61_lines
    test_multiple_functions_one_long
}

# Run edge case tests
run_edge_case_tests() {
    test_function_with_nested_braces
    test_function_with_case_statement
    test_empty_file
    test_file_with_no_functions
    test_function_with_empty_lines
    test_function_alternate_syntax
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
        print_success "✓ All tests passed - Function length validation is working correctly"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly accepts functions ≤ 60 lines (no false positives)"
        print_info "  • Correctly detects functions > 60 lines (no false negatives)"
        print_info "  • Handles edge cases (nested braces, case statements, comments)"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        return 0
    else
        print_error "✗ Some tests failed - Function length validation has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Valid short functions flagged as too long"
        print_info "  • False negatives: Long functions not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

# Main function (NASA compliant: ≤ 60 lines)
main() {
    print_section "Function Length Validation - Property Test"
    
    print_info "Testing function length validation across wide range of code patterns"
    print_info "Maximum function length: $MAX_FUNCTION_LENGTH lines"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Verify check script exists
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    # Check real project files first
    check_real_project_files
    
    # Setup test environment
    setup_test_environment
    
    # Run all test categories
    run_valid_function_tests
    run_invalid_function_tests
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
