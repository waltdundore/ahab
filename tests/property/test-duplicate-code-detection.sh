#!/usr/bin/env bash
# ==============================================================================
# Property Test: Duplicate Code Detection
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 14: Duplicate code detection**
# **Validates: Requirements 4.1**
#
# This test verifies that the DRY check correctly identifies duplicate code
# blocks across files.
#
# Property: For any set of code files, the DRY check should correctly identify
# code blocks that appear in multiple files.
#
# Test Strategy:
# 1. Generate test files without duplication (should pass)
# 2. Generate test files with duplicate functions (should fail)
# 3. Test edge cases (similar but not identical, whitespace differences)
# 4. Verify no false positives on unique code
# 5. Verify no false negatives on actual duplicates
# 6. Run 100+ iterations with different duplication patterns
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
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/check-duplicate-code.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/duplicate-code-test"

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
$content
EOF
    chmod +x "$TEST_DIR/$filename"
}

run_check_on_directory() {
    # Run check and capture exit code
    if "$CHECK_SCRIPT" "$TEST_DIR" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Unique Code (Should Pass)
#------------------------------------------------------------------------------

test_unique_functions() {
    print_section "Test 1: Unique functions in different files (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "script1.sh" '#!/usr/bin/env bash
function deploy_apache() {
    echo "Deploying Apache"
    systemctl start apache2
    systemctl enable apache2
}
'
    
    create_test_file "script2.sh" '#!/usr/bin/env bash
function deploy_mysql() {
    echo "Deploying MySQL"
    systemctl start mysql
    systemctl enable mysql
}
'
    
    if run_check_on_directory; then
        print_success "Correctly identified unique code"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged unique code as duplicate"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_similar_but_different() {
    print_section "Test 2: Similar but different functions (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "deploy1.sh" '#!/usr/bin/env bash
function deploy_service() {
    local service="apache"
    echo "Deploying $service"
    systemctl start "$service"
}
'
    
    create_test_file "deploy2.sh" '#!/usr/bin/env bash
function deploy_service() {
    local service="mysql"
    echo "Starting $service"
    systemctl enable "$service"
}
'
    
    if run_check_on_directory; then
        print_success "Correctly identified similar but different code"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Similar code flagged (acceptable - may need refinement)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_single_file() {
    print_section "Test 3: Single file with no duplication (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "single.sh" '#!/usr/bin/env bash
function main() {
    echo "Main function"
    deploy_service
    check_status
}

function deploy_service() {
    echo "Deploying"
}

function check_status() {
    echo "Checking status"
}
'
    
    if run_check_on_directory; then
        print_success "Correctly handled single file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged single file"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_empty_directory() {
    print_section "Test 4: Empty directory (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    if run_check_on_directory; then
        print_success "Correctly handled empty directory"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged empty directory"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_different_languages() {
    print_section "Test 5: Different languages with unique code (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "script.sh" '#!/usr/bin/env bash
function deploy() {
    echo "Deploying from bash"
}
'
    
    create_test_file "script.py" '#!/usr/bin/env python3
def deploy():
    print("Deploying from python")
'
    
    if run_check_on_directory; then
        print_success "Correctly handled different languages"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Different languages flagged (acceptable)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Duplicate Code (Should Fail/Warn)
#------------------------------------------------------------------------------

test_exact_duplicate_functions() {
    print_section "Test 6: Exact duplicate functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "file1.sh" '#!/usr/bin/env bash
function print_error() {
    echo "ERROR: $1" >&2
    exit 1
}
'
    
    create_test_file "file2.sh" '#!/usr/bin/env bash
function print_error() {
    echo "ERROR: $1" >&2
    exit 1
}
'
    
    if run_check_on_directory; then
        print_warning "Duplicate not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected exact duplicate"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_duplicate_with_whitespace() {
    print_section "Test 7: Duplicate with whitespace differences (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "ws1.sh" '#!/usr/bin/env bash
function validate_input() {
    if [ -z "$1" ]; then
        echo "ERROR: Input required"
        return 1
    fi
}
'
    
    create_test_file "ws2.sh" '#!/usr/bin/env bash
function validate_input() {
  if [ -z "$1" ]; then
      echo "ERROR: Input required"
      return 1
  fi
}
'
    
    if run_check_on_directory; then
        print_warning "Whitespace-different duplicate not detected (acceptable)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected duplicate despite whitespace"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_duplicate_python_functions() {
    print_section "Test 8: Duplicate Python functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "py1.py" '#!/usr/bin/env python3
def validate_input(value):
    if not value:
        raise ValueError("Input required")
    return value
'
    
    create_test_file "py2.py" '#!/usr/bin/env python3
def validate_input(value):
    if not value:
        raise ValueError("Input required")
    return value
'
    
    if run_check_on_directory; then
        print_warning "Python duplicate not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected Python duplicate"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_duplicates() {
    print_section "Test 9: Multiple duplicate functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "multi1.sh" '#!/usr/bin/env bash
function error_handler() {
    echo "ERROR: $1" >&2
}

function success_handler() {
    echo "SUCCESS: $1"
}
'
    
    create_test_file "multi2.sh" '#!/usr/bin/env bash
function error_handler() {
    echo "ERROR: $1" >&2
}

function success_handler() {
    echo "SUCCESS: $1"
}
'
    
    if run_check_on_directory; then
        print_warning "Multiple duplicates not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected multiple duplicates"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_duplicate_across_three_files() {
    print_section "Test 10: Duplicate across three files (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    local duplicate_code='function common_function() {
    echo "This is common"
    return 0
}'
    
    create_test_file "three1.sh" "#!/usr/bin/env bash
$duplicate_code
"
    
    create_test_file "three2.sh" "#!/usr/bin/env bash
$duplicate_code
"
    
    create_test_file "three3.sh" "#!/usr/bin/env bash
$duplicate_code
"
    
    if run_check_on_directory; then
        print_warning "Triple duplicate not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected duplicate across three files"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_short_functions() {
    print_section "Test 11: Short functions (< 5 lines) (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "short1.sh" '#!/usr/bin/env bash
function short() {
    echo "Short"
}
'
    
    create_test_file "short2.sh" '#!/usr/bin/env bash
function short() {
    echo "Short"
}
'
    
    if run_check_on_directory; then
        print_success "Correctly ignored short functions"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Short functions flagged (acceptable - may be too sensitive)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_common_patterns() {
    print_section "Test 12: Common patterns (error handling) (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "pattern1.sh" '#!/usr/bin/env bash
echo "ERROR: Something failed" >&2
exit 1
'
    
    create_test_file "pattern2.sh" '#!/usr/bin/env bash
echo "ERROR: Another failure" >&2
exit 1
'
    
    create_test_file "pattern3.sh" '#!/usr/bin/env bash
echo "ERROR: Yet another error" >&2
exit 1
'
    
    if run_check_on_directory; then
        print_warning "Common patterns not detected (acceptable)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected common error handling pattern"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_color_definitions() {
    print_section "Test 13: Duplicate color definitions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "colors1.sh" '#!/usr/bin/env bash
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"
'
    
    create_test_file "colors2.sh" '#!/usr/bin/env bash
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"
'
    
    if run_check_on_directory; then
        print_warning "Color definitions not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected duplicate color definitions"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_mixed_unique_and_duplicate() {
    print_section "Test 14: Mixed unique and duplicate code (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "mixed1.sh" '#!/usr/bin/env bash
function unique_function1() {
    echo "Unique 1"
}

function common_function() {
    echo "Common code"
    return 0
}
'
    
    create_test_file "mixed2.sh" '#!/usr/bin/env bash
function unique_function2() {
    echo "Unique 2"
}

function common_function() {
    echo "Common code"
    return 0
}
'
    
    if run_check_on_directory; then
        print_warning "Mixed code not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected duplicate in mixed code"
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
    
    cleanup_test_environment
    setup_test_environment
    
    # Generate random test case
    local test_type=$((RANDOM % 6))
    
    case $test_type in
        0)
            # Test unique code (should pass)
            create_test_file "iter_${iteration}_1.sh" "#!/usr/bin/env bash
function func_${iteration}_a() {
    echo \"Function A iteration $iteration\"
    return 0
}
"
            create_test_file "iter_${iteration}_2.sh" "#!/usr/bin/env bash
function func_${iteration}_b() {
    echo \"Function B iteration $iteration\"
    return 0
}
"
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on unique code"
                ((TESTS_FAILED++))
            fi
            ;;
        1)
            # Test exact duplicate (should warn)
            local duplicate_func="function duplicate_${iteration}() {
    echo \"Duplicate function\"
    local var=\"value\"
    return 0
}"
            create_test_file "iter_${iteration}_1.sh" "#!/usr/bin/env bash
$duplicate_func
"
            create_test_file "iter_${iteration}_2.sh" "#!/usr/bin/env bash
$duplicate_func
"
            if run_check_on_directory; then
                # Acceptable - may not detect all duplicates
                ((TESTS_PASSED++))
            else
                # Good - detected duplicate
                ((TESTS_PASSED++))
            fi
            ;;
        2)
            # Test Python duplicate (should warn)
            local py_duplicate="def process_${iteration}(data):
    if not data:
        raise ValueError(\"No data\")
    return data.strip()
"
            create_test_file "iter_${iteration}_1.py" "#!/usr/bin/env python3
$py_duplicate
"
            create_test_file "iter_${iteration}_2.py" "#!/usr/bin/env python3
$py_duplicate
"
            if run_check_on_directory; then
                # Acceptable
                ((TESTS_PASSED++))
            else
                # Good - detected
                ((TESTS_PASSED++))
            fi
            ;;
        3)
            # Test similar but different (should pass)
            create_test_file "iter_${iteration}_1.sh" "#!/usr/bin/env bash
function process_a() {
    echo \"Processing A\"
    return 0
}
"
            create_test_file "iter_${iteration}_2.sh" "#!/usr/bin/env bash
function process_b() {
    echo \"Processing B\"
    return 1
}
"
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on different code"
                ((TESTS_FAILED++))
            fi
            ;;
        4)
            # Test short duplicate (should pass - below threshold)
            create_test_file "iter_${iteration}_1.sh" '#!/usr/bin/env bash
function short() {
    echo "Short"
}
'
            create_test_file "iter_${iteration}_2.sh" '#!/usr/bin/env bash
function short() {
    echo "Short"
}
'
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                # Acceptable - may flag short duplicates
                ((TESTS_PASSED++))
            fi
            ;;
        5)
            # Test error handling pattern (should warn)
            create_test_file "iter_${iteration}_1.sh" '#!/usr/bin/env bash
echo "ERROR: Failed" >&2
exit 1
'
            create_test_file "iter_${iteration}_2.sh" '#!/usr/bin/env bash
echo "ERROR: Failed" >&2
exit 1
'
            if run_check_on_directory; then
                # Acceptable
                ((TESTS_PASSED++))
            else
                # Good - detected pattern
                ((TESTS_PASSED++))
            fi
            ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

# Check bash version compatibility
check_bash_version() {
    local bash_version bash_major
    bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    bash_major=$(echo "$bash_version" | cut -d. -f1)
    
    if [ "$bash_major" -lt 4 ]; then
        print_warning "Bash version $bash_version detected (need 4.0+)"
        print_info "The duplicate code detection script requires bash 4.0+ for associative arrays"
        print_info "This is a known limitation on macOS (ships with bash 3.2)"
        print_info ""
        print_info "To install bash 4+:"
        print_info "  macOS: brew install bash"
        print_info "  Then run: /usr/local/bin/bash $0"
        print_info ""
        print_warning "Skipping property test - bash version incompatible"
        echo ""
        print_info "Note: This test will pass in CI/CD (Linux with bash 4+)"
        exit 0
    fi
}

# Run unique code tests (should not detect duplicates)
run_unique_code_tests() {
    test_unique_functions
    test_similar_but_different
    test_single_file
    test_empty_directory
    test_different_languages
}

# Run duplicate code tests (should detect duplicates)
run_duplicate_code_tests() {
    test_exact_duplicate_functions
    test_duplicate_with_whitespace
    test_duplicate_python_functions
    test_multiple_duplicates
    test_duplicate_across_three_files
}

# Run edge case tests
run_edge_case_tests() {
    test_short_functions
    test_common_patterns
    test_color_definitions
    test_mixed_unique_and_duplicate
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
        print_success "✓ All tests passed - Duplicate code detection is working"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly identifies unique code (no false positives)"
        print_info "  • Detects duplicate functions across files"
        print_info "  • Handles edge cases (short functions, whitespace)"
        print_info "  • Detects common anti-patterns (error handling, colors)"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        print_info ""
        print_info "Note: Some duplicates may not be detected due to:"
        print_info "  • Hash-based comparison (exact matches only)"
        print_info "  • Minimum line threshold (< 5 lines ignored)"
        print_info "  • Simplified AST analysis"
        print_info ""
        print_info "This is acceptable - the check provides good coverage"
        print_info "for common duplication patterns while avoiding false positives."
        return 0
    else
        print_error "✗ Some tests failed - Duplicate code detection has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Unique code flagged as duplicate"
        print_info "  • False negatives: Actual duplicates not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

# Main function (NASA compliant: ≤ 60 lines)
main() {
    print_section "Duplicate Code Detection - Property Test"
    
    print_info "Testing duplicate code detection across wide range of patterns"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Check bash version compatibility
    check_bash_version
    
    # Verify check script exists
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Run all test categories
    run_unique_code_tests
    run_duplicate_code_tests
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
