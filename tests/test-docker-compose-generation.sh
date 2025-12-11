#!/bin/bash
# ==============================================================================
# Test: Docker Compose Generation
# ==============================================================================
# Tests that generate-docker-compose.py works correctly
#
# This test:
# 1. Verifies modules directory exists
# 2. Runs generation script
# 3. Validates output file
# 4. Checks file contents
# 5. Cleans up
#
# Expected to run on workstation VM, not host
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared test helpers (DRY - Don't Repeat Yourself)
# shellcheck source=tests/lib/test-helpers.sh
source "$SCRIPT_DIR/lib/test-helpers.sh"

# Source assertions library
# shellcheck source=tests/lib/assertions.sh
source "$SCRIPT_DIR/lib/assertions.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Timeout for script execution (30 seconds)
TIMEOUT=30

# Test output file
OUTPUT_FILE="docker-compose.yml"
TEST_MODULE="apache"

# ==============================================================================
# Helper Functions
# ==============================================================================

run_test() {
    ((TESTS_RUN++))
}

print_test() {
    print_info "TEST: $1"
}

print_pass() {
    print_success "PASS: $1"
    ((TESTS_PASSED++))
}

print_fail() {
    print_error "FAIL: $1"
    ((TESTS_FAILED++))
}

cleanup() {
    echo ""
    print_info "Cleaning up..."
    rm -f "$OUTPUT_FILE"
    print_success "Cleanup complete"
}

# ==============================================================================
# Tests
# ==============================================================================

print_section "Docker Compose Generation Test"

# Test 1: Verify modules directory exists
run_test
print_test "Modules directory exists"
if [ -d "modules" ]; then
    print_pass "modules/ directory found"
else
    print_fail "modules/ directory not found"
    echo "Hint: Run 'git submodule update --init --recursive'"
    exit 1
fi

# Test 2: Verify apache module exists
run_test
print_test "Apache module exists"
if [ -f "modules/apache/module.yml" ]; then
    print_pass "modules/apache/module.yml found"
else
    print_fail "modules/apache/module.yml not found"
    exit 1
fi

# Test 3: Verify script exists
run_test
print_test "Generation script exists"
if [ -f "scripts/generate-docker-compose.py" ]; then
    print_pass "scripts/generate-docker-compose.py found"
else
    print_fail "scripts/generate-docker-compose.py not found"
    exit 1
fi

# Test 4: Verify Python is available
run_test
print_test "Python is available"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_pass "Python found: $PYTHON_VERSION"
else
    print_fail "Python not found"
    exit 1
fi

# Test 5: Verify PyYAML is available
run_test
print_test "PyYAML is available"
if python3 -c "import yaml" 2>/dev/null; then
    print_pass "PyYAML is installed"
else
    print_fail "PyYAML not installed"
    echo "Installing PyYAML..."
    if pip3 install pyyaml --quiet; then
        print_pass "PyYAML installed successfully"
    else
        print_fail "Failed to install PyYAML"
        exit 1
    fi
fi

# Test 6: Run generation script with timeout
run_test
print_test "Generate docker-compose.yml (timeout: ${TIMEOUT}s)"
cleanup  # Remove any existing file first

# Run with timeout
if timeout "$TIMEOUT" python3 scripts/generate-docker-compose.py "$TEST_MODULE" > /tmp/generate-output.log 2>&1; then
    print_pass "Script executed successfully"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        print_fail "Script timed out after ${TIMEOUT} seconds"
        echo "Output:"
        cat /tmp/generate-output.log
        exit 1
    else
        print_fail "Script failed with exit code $EXIT_CODE"
        echo "Output:"
        cat /tmp/generate-output.log
        exit 1
    fi
fi

# Test 7: Verify output file was created
run_test
print_test "Output file created"
if [ -f "$OUTPUT_FILE" ]; then
    print_pass "$OUTPUT_FILE exists"
else
    print_fail "$OUTPUT_FILE not created"
    echo "Script output:"
    cat /tmp/generate-output.log
    exit 1
fi

# Test 8: Verify output file is not empty
run_test
print_test "Output file is not empty"
if [ -s "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(wc -c < "$OUTPUT_FILE")
    print_pass "$OUTPUT_FILE has content ($FILE_SIZE bytes)"
else
    print_fail "$OUTPUT_FILE is empty"
    exit 1
fi

# Test 9: Verify output is valid YAML
run_test
print_test "Output is valid YAML"
if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE'))" 2>/dev/null; then
    print_pass "Valid YAML syntax"
else
    print_fail "Invalid YAML syntax"
    echo "File contents:"
    cat "$OUTPUT_FILE"
    exit 1
fi

# Test 10: Verify docker-compose version is present
run_test
print_test "Docker Compose version specified"
if grep -q "^version:" "$OUTPUT_FILE"; then
    VERSION=$(grep "^version:" "$OUTPUT_FILE" | awk '{print $2}')
    print_pass "Version found: $VERSION"
else
    print_fail "No version specified"
fi

# Test 11: Verify services section exists
run_test
print_test "Services section exists"
if grep -q "^services:" "$OUTPUT_FILE"; then
    print_pass "Services section found"
else
    print_fail "Services section not found"
fi

# Test 12: Verify apache service exists
run_test
print_test "Apache service defined"
if grep -q "  apache:" "$OUTPUT_FILE"; then
    print_pass "Apache service found"
else
    print_fail "Apache service not found"
fi

# Test 13: Verify image is specified
run_test
print_test "Docker image specified"
if grep -q "    image:" "$OUTPUT_FILE"; then
    IMAGE=$(grep "    image:" "$OUTPUT_FILE" | head -1 | awk '{print $2}')
    print_pass "Image found: $IMAGE"
else
    print_fail "No image specified"
fi

# Test 14: Verify ports are mapped
run_test
print_test "Ports are mapped"
if grep -q "    ports:" "$OUTPUT_FILE"; then
    print_pass "Port mappings found"
else
    print_fail "No port mappings found"
fi

# Test 15: Verify networks section exists
run_test
print_test "Networks section exists"
if grep -q "^networks:" "$OUTPUT_FILE"; then
    print_pass "Networks section found"
else
    print_fail "Networks section not found"
fi

# ==============================================================================
# Summary
# ==============================================================================

cleanup

print_section "Test Summary"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed!"
    exit 0
else
    print_error "Some tests failed"
    exit 1
fi
