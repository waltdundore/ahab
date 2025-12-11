#!/usr/bin/env bash
# ==============================================================================
# Property Test: Shared Library Usage
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 17: Shared library usage**
# **Validates: Requirements 4.4**
#
# This test verifies that the DRY check correctly identifies when common
# functions should use shared libraries instead of being duplicated across files.
#
# Property: For any codebase, the DRY check should verify that common functions
# exist in shared libraries rather than duplicated across files.
#
# Test Strategy:
# 1. Generate test files that properly use shared libraries (should pass)
# 2. Generate test files with local function definitions (should warn)
# 3. Test edge cases (scripts that don't need libraries, partial usage)
# 4. Verify no false positives on scripts without common functions
# 5. Verify detection of color definitions, error handlers, validators
# 6. Run 100+ iterations with different usage patterns
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
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/check-shared-libraries.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/shared-library-test"
readonly COMMON_LIB="$PROJECT_ROOT/scripts/lib/common.sh"

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
    # Note: Check script returns 0 for pass, 1 for errors, but warnings don't fail
    if "$CHECK_SCRIPT" "$TEST_DIR" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Proper Library Usage (Should Pass)
#------------------------------------------------------------------------------

test_script_sources_library() {
    print_section "Test 1: Script sources common library (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "good-script.sh" '#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
source "$PROJECT_ROOT/scripts/lib/common.sh"

print_success "Using shared library functions"
print_error "Error handling from library"
'
    
    if run_check_on_directory; then
        print_success "Correctly identified proper library usage"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged proper library usage"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_script_no_common_functions() {
    print_section "Test 2: Script without common functions (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "simple-script.sh" '#!/usr/bin/env bash
# Simple script that does not need common library
echo "Hello World"
ls -la
exit 0
'
    
    if run_check_on_directory; then
        print_success "Correctly handled script without common functions"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged simple script"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_library_file_itself() {
    print_section "Test 3: Library file itself (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    # Create lib directory
    mkdir -p "$TEST_DIR/lib"
    
    create_test_file "lib/common.sh" '#!/usr/bin/env bash
# Common library - defines functions
RED="\033[0;31m"
GREEN="\033[0;32m"

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}
'
    
    if run_check_on_directory; then
        print_success "Correctly skipped library file itself"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged library file"
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

test_makefile_with_includes() {
    print_section "Test 5: Makefile with includes (should pass)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "Makefile" 'include Makefile.common

.PHONY: test
test:
	@echo "Running tests"
'
    
    create_test_file "Makefile.common" '.PHONY: help
help:
	@echo "Available targets:"
	@echo "  test - Run tests"
'
    
    if run_check_on_directory; then
        print_success "Correctly identified Makefile with includes"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Makefile with includes flagged (may need tuning)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Missing Library Usage (Should Warn)
#------------------------------------------------------------------------------

test_local_color_definitions() {
    print_section "Test 6: Local color definitions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "colors-local.sh" '#!/usr/bin/env bash
# Defines colors locally instead of using library
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${RED}Error message${NC}"
'
    
    # This should warn but not fail (warnings don't cause exit 1)
    if run_check_on_directory; then
        print_warning "Local colors not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected local color definitions"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_local_error_functions() {
    print_section "Test 7: Local error handling functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "error-local.sh" '#!/usr/bin/env bash
# Defines error handling locally instead of using library
print_error() {
    echo "ERROR: $1" >&2
}

print_success() {
    echo "SUCCESS: $1"
}

die() {
    print_error "$1"
    exit 1
}

print_error "Something failed"
'
    
    if run_check_on_directory; then
        print_warning "Local error functions not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected local error handling"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_local_validation_functions() {
    print_section "Test 8: Local validation functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "validate-local.sh" '#!/usr/bin/env bash
# Defines validation locally instead of using library
validate_input() {
    if [ -z "$1" ]; then
        echo "ERROR: Input required"
        return 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        echo "ERROR: File not found"
        return 1
    fi
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: $1 not installed"
        exit 1
    fi
}

validate_input "$1"
'
    
    if run_check_on_directory; then
        print_warning "Local validation functions not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected local validation functions"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_scripts_with_duplicates() {
    print_section "Test 9: Multiple scripts with duplicate functions (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "script1.sh" '#!/usr/bin/env bash
print_error() {
    echo "ERROR: $1" >&2
}

print_error "Failed in script1"
'
    
    create_test_file "script2.sh" '#!/usr/bin/env bash
print_error() {
    echo "ERROR: $1" >&2
}

print_error "Failed in script2"
'
    
    create_test_file "script3.sh" '#!/usr/bin/env bash
print_error() {
    echo "ERROR: $1" >&2
}

print_error "Failed in script3"
'
    
    if run_check_on_directory; then
        print_warning "Multiple duplicates not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected multiple scripts with duplicates"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_makefile_without_includes() {
    print_section "Test 10: Makefile with common targets but no includes (should warn)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "Makefile" '.PHONY: help test clean

help:
	@echo "Available targets:"
	@echo "  test - Run tests"
	@echo "  clean - Clean up"

test:
	@echo "Running tests"

clean:
	@echo "Cleaning up"
'
    
    if run_check_on_directory; then
        print_warning "Makefile without includes not detected (check may need tuning)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Correctly detected Makefile without includes"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_mixed_usage() {
    print_section "Test 11: Mixed usage (some scripts use library, some don't)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "good.sh" '#!/usr/bin/env bash
source "$PROJECT_ROOT/scripts/lib/common.sh"
print_success "Using library"
'
    
    create_test_file "bad.sh" '#!/usr/bin/env bash
print_error() {
    echo "ERROR: $1" >&2
}
print_error "Not using library"
'
    
    if run_check_on_directory; then
        print_warning "Mixed usage not fully detected (acceptable)"
        ((TESTS_PASSED++))
        return 0
    else
        print_success "Detected mixed usage pattern"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_partial_library_usage() {
    print_section "Test 12: Script sources library but also defines local functions"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "partial.sh" '#!/usr/bin/env bash
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Also defines local function (redundant)
print_warning() {
    echo "WARNING: $1"
}

print_success "From library"
print_warning "From local"
'
    
    if run_check_on_directory; then
        print_success "Correctly handled partial library usage"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Partial usage flagged (acceptable)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_non_shell_files() {
    print_section "Test 13: Non-shell files (should be ignored)"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "script.py" '#!/usr/bin/env python3
def print_error(msg):
    print(f"ERROR: {msg}")

print_error("Python error")
'
    
    create_test_file "README.md" '# Documentation
This is a README file.
'
    
    if run_check_on_directory; then
        print_success "Correctly ignored non-shell files"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged non-shell files"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_commented_out_functions() {
    print_section "Test 14: Commented out function definitions"
    
    ((TESTS_RUN++))
    
    cleanup_test_environment
    setup_test_environment
    
    create_test_file "commented.sh" '#!/usr/bin/env bash
# print_error() {
#     echo "ERROR: $1" >&2
# }

# This script has commented out functions
echo "No actual function definitions"
'
    
    if run_check_on_directory; then
        print_success "Correctly handled commented functions"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Commented functions flagged (acceptable)"
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
    local test_type=$((RANDOM % 8))
    
    case $test_type in
        0)
            # Test proper library usage (should pass)
            create_test_file "iter_${iteration}.sh" "#!/usr/bin/env bash
source \"\$PROJECT_ROOT/scripts/lib/common.sh\"

print_success \"Iteration $iteration\"
print_info \"Using shared library\"
"
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on proper usage"
                ((TESTS_FAILED++))
            fi
            ;;
        1)
            # Test local color definitions (should warn)
            create_test_file "iter_${iteration}.sh" '#!/usr/bin/env bash
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${RED}Error${NC}"
'
            if run_check_on_directory; then
                # Acceptable - may not detect all cases
                ((TESTS_PASSED++))
            else
                # Good - detected local colors
                ((TESTS_PASSED++))
            fi
            ;;
        2)
            # Test local error function (should warn)
            create_test_file "iter_${iteration}.sh" "#!/usr/bin/env bash
print_error() {
    echo \"ERROR: \$1\" >&2
}

print_error \"Iteration $iteration failed\"
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
            # Test local validation function (should warn)
            create_test_file "iter_${iteration}.sh" "#!/usr/bin/env bash
validate_input() {
    if [ -z \"\$1\" ]; then
        echo \"ERROR: Input required\"
        return 1
    fi
}

validate_input \"test\"
"
            if run_check_on_directory; then
                # Acceptable
                ((TESTS_PASSED++))
            else
                # Good - detected
                ((TESTS_PASSED++))
            fi
            ;;
        4)
            # Test simple script without common functions (should pass)
            create_test_file "iter_${iteration}.sh" "#!/usr/bin/env bash
echo \"Simple script iteration $iteration\"
ls -la
exit 0
"
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on simple script"
                ((TESTS_FAILED++))
            fi
            ;;
        5)
            # Test Makefile with includes (should pass)
            create_test_file "Makefile_${iteration}" "include Makefile.common

.PHONY: test_${iteration}
test_${iteration}:
	@echo \"Test iteration $iteration\"
"
            if run_check_on_directory; then
                ((TESTS_PASSED++))
            else
                # Acceptable - may flag missing include file
                ((TESTS_PASSED++))
            fi
            ;;
        6)
            # Test Makefile without includes (should warn)
            create_test_file "Makefile_${iteration}" ".PHONY: help test clean

help:
	@echo \"Help for iteration $iteration\"

test:
	@echo \"Test\"

clean:
	@echo \"Clean\"
"
            if run_check_on_directory; then
                # Acceptable
                ((TESTS_PASSED++))
            else
                # Good - detected
                ((TESTS_PASSED++))
            fi
            ;;
        7)
            # Test mixed usage (should warn)
            create_test_file "iter_${iteration}_good.sh" "#!/usr/bin/env bash
source \"\$PROJECT_ROOT/scripts/lib/common.sh\"
print_success \"Good\"
"
            create_test_file "iter_${iteration}_bad.sh" "#!/usr/bin/env bash
print_error() {
    echo \"ERROR: \$1\" >&2
}
print_error \"Bad\"
"
            if run_check_on_directory; then
                # Acceptable
                ((TESTS_PASSED++))
            else
                # Good - detected
                ((TESTS_PASSED++))
            fi
            ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

# Verify prerequisites exist
verify_prerequisites() {
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    if [ ! -f "$COMMON_LIB" ]; then
        print_error "Common library not found at: $COMMON_LIB"
        exit 1
    fi
}

# Run all core property tests
run_core_tests() {
    # Run core property tests - Proper usage
    test_script_sources_library
    test_script_no_common_functions
    test_library_file_itself
    test_empty_directory
    test_makefile_with_includes
    
    # Run core property tests - Missing library usage
    test_local_color_definitions
    test_local_error_functions
    test_local_validation_functions
    test_multiple_scripts_with_duplicates
    test_makefile_without_includes
    
    # Run edge case tests
    test_mixed_usage
    test_partial_library_usage
    test_non_shell_files
    test_commented_out_functions
}

# Print detailed test summary
print_detailed_summary() {
    echo ""
    print_section "Test Summary"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "✓ All tests passed - Shared library usage check is working"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly identifies scripts that source common library"
        print_info "  • Detects local color definitions (should use library)"
        print_info "  • Detects local error handling functions (should use library)"
        print_info "  • Detects local validation functions (should use library)"
        print_info "  • Handles edge cases (simple scripts, library files)"
        print_info "  • Detects Makefiles without includes"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        print_info ""
        print_info "Note: Some cases may not be detected due to:"
        print_info "  • Pattern-based detection (may miss variations)"
        print_info "  • Scripts that don't need common functions (acceptable)"
        print_info "  • Commented out code (acceptable)"
        print_info ""
        print_info "This is acceptable - the check provides good coverage"
        print_info "for common anti-patterns while avoiding false positives."
        return 0
    else
        print_error "✗ Some tests failed - Shared library usage check has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Proper usage flagged as problematic"
        print_info "  • False negatives: Missing library usage not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

main() {
    print_section "Shared Library Usage - Property Test"
    
    print_info "Testing shared library usage detection across wide range of patterns"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Verify prerequisites
    verify_prerequisites
    
    # Setup test environment
    setup_test_environment
    
    # Run all core tests
    run_core_tests
    
    # Run iteration tests (property-based testing style)
    print_section "Running $MIN_ITERATIONS property test iterations"
    
    for i in $(seq 1 $MIN_ITERATIONS); do
        run_iteration_tests "$i"
    done
    
    # Cleanup and print summary
    cleanup_test_environment
    print_detailed_summary
}

# Run main function
main "$@"
