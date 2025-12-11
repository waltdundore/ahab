#!/usr/bin/env bash
# ==============================================================================
# Property Test: Make command usage for inventory operations
# ==============================================================================
# **Feature: inventory-management-gui, Property 18: Make command usage for operations**
# **Validates: Requirements 10.1, 10.2**
#
# This test verifies that inventory operations (connectivity testing and
# validation) are executed via make commands rather than direct tool invocations.
#
# Property: For any inventory operation (test or validate), the executed
# command should start with "make" and use the appropriate inventory target
# ==============================================================================

set -euo pipefail

# Source shared color definitions (DRY)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
print_test_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

assert_true() {
    local condition="$1"
    local message="$2"
    
    ((TESTS_RUN++))
    
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    ((TESTS_RUN++))
    
    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected to find: $needle"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    ((TESTS_RUN++))
    
    if ! echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo -e "  Should not contain: $needle"
        ((TESTS_FAILED++))
        return 1
    fi
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# ==============================================================================
# Property Test: Make Command Usage for Inventory Operations
# ==============================================================================

print_test_header "Property 18: Make command usage for operations"

# Test 1: Makefile has inventory-test target
print_test_header "Test 1: Makefile defines inventory-test target"

assert_true "grep -q '^inventory-test:' Makefile" \
    "Makefile contains inventory-test target"

# Test 2: Makefile has inventory-validate target
print_test_header "Test 2: Makefile defines inventory-validate target"

assert_true "grep -q '^inventory-validate:' Makefile" \
    "Makefile contains inventory-validate target"

# Test 3: Makefile has inventory-list target
print_test_header "Test 3: Makefile defines inventory-list target"

assert_true "grep -q '^inventory-list:' Makefile" \
    "Makefile contains inventory-list target"

# Test 4: inventory-test uses ansible command
print_test_header "Test 4: inventory-test executes ansible ping"

INVENTORY_TEST_CONTENT=$(grep -A 50 "^inventory-test:" Makefile)

assert_contains "$INVENTORY_TEST_CONTENT" "ansible.*-m ping" \
    "inventory-test uses ansible ping command"

# Test 5: inventory-validate uses ansible-inventory command
print_test_header "Test 5: inventory-validate executes ansible-inventory"

INVENTORY_VALIDATE_CONTENT=$(grep -A 50 "^inventory-validate:" Makefile)

assert_contains "$INVENTORY_VALIDATE_CONTENT" "ansible-inventory" \
    "inventory-validate uses ansible-inventory command"

# Test 6: inventory-test accepts ENV parameter
print_test_header "Test 6: inventory-test requires ENV parameter"

assert_contains "$INVENTORY_TEST_CONTENT" '$(ENV)' \
    "inventory-test uses ENV parameter"

# Test 7: inventory-test accepts optional HOST parameter
print_test_header "Test 7: inventory-test accepts HOST parameter"

assert_contains "$INVENTORY_TEST_CONTENT" '$(HOST)' \
    "inventory-test uses HOST parameter"

# Test 8: inventory-validate accepts ENV parameter
print_test_header "Test 8: inventory-validate requires ENV parameter"

assert_contains "$INVENTORY_VALIDATE_CONTENT" '$(ENV)' \
    "inventory-validate uses ENV parameter"

# Test 9: Targets are documented in help
print_test_header "Test 9: Inventory targets appear in help"

HELP_OUTPUT=$(make help 2>/dev/null || true)

assert_contains "$HELP_OUTPUT" "inventory-list" \
    "Help includes inventory-list"

assert_contains "$HELP_OUTPUT" "inventory-test" \
    "Help includes inventory-test"

assert_contains "$HELP_OUTPUT" "inventory-validate" \
    "Help includes inventory-validate"

# Test 10: Targets are in .PHONY
print_test_header "Test 10: Inventory targets are marked as .PHONY"

PHONY_LINE=$(grep '^\.PHONY:' Makefile)

assert_contains "$PHONY_LINE" "inventory-list" \
    ".PHONY includes inventory-list"

assert_contains "$PHONY_LINE" "inventory-test" \
    ".PHONY includes inventory-test"

assert_contains "$PHONY_LINE" "inventory-validate" \
    ".PHONY includes inventory-validate"

# Test 11: inventory-test does NOT use direct vagrant ssh
print_test_header "Test 11: inventory-test avoids direct vagrant ssh"

assert_not_contains "$INVENTORY_TEST_CONTENT" "vagrant ssh.*ansible" \
    "inventory-test does not wrap ansible in vagrant ssh"

# Test 12: inventory-validate does NOT use direct vagrant ssh
print_test_header "Test 12: inventory-validate avoids direct vagrant ssh"

assert_not_contains "$INVENTORY_VALIDATE_CONTENT" "vagrant ssh.*ansible" \
    "inventory-validate does not wrap ansible in vagrant ssh"

# Test 13: Targets provide helpful error messages
print_test_header "Test 13: Targets provide error messages for missing ENV"

assert_contains "$INVENTORY_TEST_CONTENT" "ENV parameter required" \
    "inventory-test has error message for missing ENV"

assert_contains "$INVENTORY_VALIDATE_CONTENT" "ENV parameter required" \
    "inventory-validate has error message for missing ENV"

# Test 14: Targets check for inventory file existence
print_test_header "Test 14: Targets validate inventory file exists"

assert_contains "$INVENTORY_TEST_CONTENT" "Inventory file not found" \
    "inventory-test checks for file existence"

assert_contains "$INVENTORY_VALIDATE_CONTENT" "Inventory file not found" \
    "inventory-validate checks for file existence"

# Test 15: inventory-list shows environment status
print_test_header "Test 15: inventory-list displays environment status"

INVENTORY_LIST_CONTENT=$(grep -A 30 "^inventory-list:" Makefile)

assert_contains "$INVENTORY_LIST_CONTENT" "for env in" \
    "inventory-list iterates over environments"

assert_contains "$INVENTORY_LIST_CONTENT" "dev prod workstation" \
    "inventory-list checks dev, prod, and workstation"

# Test 16: Make commands can be executed (smoke test)
print_test_header "Test 16: Make commands execute without syntax errors"

# Test inventory-list (should always work)
assert_true "make inventory-list >/dev/null 2>&1" \
    "make inventory-list executes successfully"

# Test inventory-test without ENV (should fail with helpful message)
OUTPUT=$(make inventory-test 2>&1 || true)
assert_contains "$OUTPUT" "ENV parameter required" \
    "make inventory-test shows helpful error without ENV"

# Test inventory-validate without ENV (should fail with helpful message)
OUTPUT=$(make inventory-validate 2>&1 || true)
assert_contains "$OUTPUT" "ENV parameter required" \
    "make inventory-validate shows helpful error without ENV"

# Print final summary
print_summary
