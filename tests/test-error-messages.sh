#!/usr/bin/env bash
# ==============================================================================
# Test Enhanced Error Message Functions
# ==============================================================================
# Tests the new error message functions in scripts/lib/common.sh
# Core Principles: #4 (Never Assume Success)
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common library
# shellcheck source=../scripts/lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#------------------------------------------------------------------------------
# Test Helper Functions
#------------------------------------------------------------------------------

test_function() {
    local test_name="$1"
    local test_func="$2"
    
    ((TESTS_RUN++))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if $test_func; then
        ((TESTS_PASSED++))
        print_success "Test passed: $test_name"
    else
        ((TESTS_FAILED++))
        print_error "Test failed: $test_name"
    fi
}

#------------------------------------------------------------------------------
# Test Cases
#------------------------------------------------------------------------------

test_print_error_detailed() {
    echo "Testing print_error_detailed..."
    
    # Capture output (strip color codes for testing)
    local output
    output=$(print_error_detailed \
        "VM name required" \
        "This script connects to a virtual machine via SSH" \
        "Run: ./script.sh workstation" \
        "https://github.com/waltdundore/ahab" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    
    # Verify output contains expected elements
    if [[ "$output" =~ "ERROR: VM name required" ]] && \
       [[ "$output" =~ "Context:" ]] && \
       [[ "$output" =~ "What to try:" ]] && \
       [[ "$output" =~ "More help:" ]]; then
        return 0
    else
        echo "Output did not contain expected elements"
        echo "Expected: ERROR, Context, What to try, More help"
        echo "Got: $output"
        return 1
    fi
}

test_print_error_with_command() {
    echo "Testing print_error_with_command..."
    
    local output
    output=$(print_error_with_command \
        "Configuration file not found" \
        "cp ahab.conf.example ahab.conf" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ "$output" =~ "ERROR: Configuration file not found" ]] && \
       [[ "$output" =~ "Try running:" ]] && \
       [[ "$output" =~ "cp ahab.conf.example ahab.conf" ]]; then
        return 0
    else
        echo "Output did not contain expected elements"
        return 1
    fi
}

test_print_error_with_options() {
    echo "Testing print_error_with_options..."
    
    local output
    output=$(print_error_with_options \
        "No terminal emulator found" \
        "Install iTerm2: brew install --cask iterm2" \
        "Install Alacritty: brew install --cask alacritty" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ "$output" =~ "ERROR: No terminal emulator found" ]] && \
       [[ "$output" =~ "Try one of these:" ]] && \
       [[ "$output" =~ "iTerm2" ]] && \
       [[ "$output" =~ "Alacritty" ]]; then
        return 0
    else
        echo "Output did not contain expected elements"
        return 1
    fi
}

test_print_error_missing_prereq() {
    echo "Testing print_error_missing_prereq..."
    
    local output
    output=$(print_error_missing_prereq \
        "docker" \
        "brew install --cask docker" \
        "https://docs.docker.com/get-docker/" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ "$output" =~ "ERROR: docker is not installed" ]] && \
       [[ "$output" =~ "Context:" ]] && \
       [[ "$output" =~ "To install:" ]] && \
       [[ "$output" =~ "Installation guide:" ]]; then
        return 0
    else
        echo "Output did not contain expected elements"
        return 1
    fi
}

test_print_error_invalid_input() {
    echo "Testing print_error_invalid_input..."
    
    local output
    output=$(print_error_invalid_input \
        "v1.0" \
        "version number" \
        "1.0.0" \
        "2.5.3" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ "$output" =~ "ERROR: Invalid version number: v1.0" ]] && \
       [[ "$output" =~ "Valid examples:" ]] && \
       [[ "$output" =~ "1.0.0" ]] && \
       [[ "$output" =~ "2.5.3" ]]; then
        return 0
    else
        echo "Output did not contain expected elements"
        return 1
    fi
}

test_colors_work() {
    echo "Testing that color codes are defined..."
    
    if [ -n "${RED:-}" ] && \
       [ -n "${GREEN:-}" ] && \
       [ -n "${YELLOW:-}" ] && \
       [ -n "${BLUE:-}" ] && \
       [ -n "${NC:-}" ]; then
        return 0
    else
        echo "Color codes not defined"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Run Tests
#------------------------------------------------------------------------------

print_header "TESTING ENHANCED ERROR MESSAGE FUNCTIONS"

test_function "Color codes are defined" test_colors_work
test_function "print_error_detailed" test_print_error_detailed
test_function "print_error_with_command" test_print_error_with_command
test_function "print_error_with_options" test_print_error_with_options
test_function "print_error_missing_prereq" test_print_error_missing_prereq
test_function "print_error_invalid_input" test_print_error_invalid_input

#------------------------------------------------------------------------------
# Print Summary
#------------------------------------------------------------------------------

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed!"
    exit 0
else
    print_error "$TESTS_FAILED test(s) failed"
    exit 1
fi
