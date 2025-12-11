#!/usr/bin/env bash
# ==============================================================================
# Dependency Audit Test Suite
# ==============================================================================
# Tests for the dependency minimization audit system
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test libraries
if [ -f "$SCRIPT_DIR/../lib/test-helpers.sh" ]; then
    source "$SCRIPT_DIR/../lib/test-helpers.sh"
else
    echo "Error: Cannot find test-helpers.sh"
    exit 1
fi

if [ -f "$SCRIPT_DIR/../lib/assertions.sh" ]; then
    source "$SCRIPT_DIR/../lib/assertions.sh"
else
    echo "Error: Cannot find assertions.sh"
    exit 1
fi

# Test configuration
readonly TEST_DIR="$PROJECT_ROOT/tests/fixtures/audit-test"
readonly AUDIT_SCRIPT="$PROJECT_ROOT/scripts/audit-dependencies.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#------------------------------------------------------------------------------
# Test Helper Functions
#------------------------------------------------------------------------------

# Create a temporary test directory
setup_test_dir() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

# Clean up test directory
cleanup_test_dir() {
    rm -rf "$TEST_DIR"
}

# Generate a test markdown file with violations
generate_test_markdown() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
$content
EOF
}

# Generate a test shell script with violations
generate_test_script() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
#!/usr/bin/env bash
$content
EOF
    chmod +x "$TEST_DIR/$filename"
}

# Generate a test Ansible playbook
generate_test_playbook() {
    local filename="$1"
    local content="$2"
    
    mkdir -p "$TEST_DIR/playbooks"
    cat > "$TEST_DIR/playbooks/$filename" << EOF
$content
EOF
}

# Run audit and capture output
run_audit() {
    local args="${1:-}"
    local output
    
    cd "$TEST_DIR"
    output=$("$AUDIT_SCRIPT" $args 2>&1 || true)
    cd "$PROJECT_ROOT"
    
    echo "$output"
}

# Run audit and capture exit code
run_audit_exit_code() {
    local args="${1:-}"
    
    cd "$TEST_DIR"
    "$AUDIT_SCRIPT" $args >/dev/null 2>&1
    local exit_code=$?
    cd "$PROJECT_ROOT"
    
    echo "$exit_code"
}

# Count violations in output
count_violations() {
    local output="$1"
    echo "$output" | grep -c "File:" || echo "0"
}

#------------------------------------------------------------------------------
# Test Execution Framework
#------------------------------------------------------------------------------

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    
    print_info "Running: $test_name"
    
    # Setup
    setup_test_dir
    
    # Run test
    if $test_function; then
        ((TESTS_PASSED++))
        print_success "$test_name"
    else
        ((TESTS_FAILED++))
        print_error "$test_name"
    fi
    
    # Cleanup
    cleanup_test_dir
    
    echo ""
}

#------------------------------------------------------------------------------
# Test Suite
#------------------------------------------------------------------------------

# Test: Synthetic file generation
test_synthetic_markdown_generation() {
    generate_test_markdown "test.md" "# Test Document"
    
    if [ ! -f "$TEST_DIR/test.md" ]; then
        print_error "Failed to create test markdown file"
        return 1
    fi
    
    if ! grep -q "# Test Document" "$TEST_DIR/test.md"; then
        print_error "Test markdown content incorrect"
        return 1
    fi
    
    return 0
}

# Test: Synthetic script generation
test_synthetic_script_generation() {
    generate_test_script "test.sh" "echo 'test'"
    
    if [ ! -f "$TEST_DIR/test.sh" ]; then
        print_error "Failed to create test script"
        return 1
    fi
    
    if [ ! -x "$TEST_DIR/test.sh" ]; then
        print_error "Test script not executable"
        return 1
    fi
    
    if ! grep -q "echo 'test'" "$TEST_DIR/test.sh"; then
        print_error "Test script content incorrect"
        return 1
    fi
    
    return 0
}

# Test: Synthetic playbook generation
test_synthetic_playbook_generation() {
    generate_test_playbook "test.yml" "---\n- hosts: all"
    
    if [ ! -f "$TEST_DIR/playbooks/test.yml" ]; then
        print_error "Failed to create test playbook"
        return 1
    fi
    
    if ! grep -q "hosts: all" "$TEST_DIR/playbooks/test.yml"; then
        print_error "Test playbook content incorrect"
        return 1
    fi
    
    return 0
}

# Test: Audit execution with clean codebase
test_audit_clean_codebase() {
    # Create a clean markdown file
    generate_test_markdown "clean.md" "# Clean Document\n\nUse \`make install\` to set up."
    
    local exit_code
    exit_code=$(run_audit_exit_code "--quick")
    
    if [ "$exit_code" -ne 0 ]; then
        print_error "Audit should pass on clean codebase (exit code: $exit_code)"
        return 1
    fi
    
    return 0
}

# Test: Violation counting
test_violation_counting() {
    # Create a file with violations
    generate_test_markdown "violations.md" "Run \`vagrant up\` to start."
    
    local output
    output=$(run_audit "--quick")
    
    local count
    count=$(count_violations "$output")
    
    if [ "$count" -lt 1 ]; then
        print_error "Should detect at least 1 violation (found: $count)"
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "Dependency Audit Test Suite"
    
    # Verify audit script exists
    if [ ! -f "$AUDIT_SCRIPT" ]; then
        print_error "Audit script not found: $AUDIT_SCRIPT"
        exit 1
    fi
    print_success "Audit script found"
    echo ""
    
    # Run tests
    run_test "Synthetic markdown generation" test_synthetic_markdown_generation
    run_test "Synthetic script generation" test_synthetic_script_generation
    run_test "Synthetic playbook generation" test_synthetic_playbook_generation
    run_test "Audit clean codebase" test_audit_clean_codebase
    run_test "Violation counting" test_violation_counting
    
    # Print summary
    print_section "Test Summary"
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed!"
        exit 0
    else
        print_error "$TESTS_FAILED test(s) failed"
        exit 1
    fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
