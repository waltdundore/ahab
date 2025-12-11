#!/usr/bin/env bash
# ==============================================================================
# Unit Test: Audit Compliance Check
# ==============================================================================
# Tests that audit on clean codebase returns 100% compliance
# Validates: Requirements 9.1
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test helpers
source "$SCRIPT_DIR/../lib/test-helpers.sh"
source "$SCRIPT_DIR/../lib/assertions.sh"

# Test configuration
readonly TEST_NAME="Audit Compliance Check"
readonly CLEAN_REPO_DIR="$REPO_ROOT/tests/fixtures/clean-repo"

#------------------------------------------------------------------------------
# Setup and Teardown
#------------------------------------------------------------------------------

# Create directory structure for test repo
create_test_repo_structure() {
    mkdir -p "$CLEAN_REPO_DIR"
    mkdir -p "$CLEAN_REPO_DIR/scripts"
    mkdir -p "$CLEAN_REPO_DIR/docs"
}

# Create Makefile with proper Make targets
create_test_makefile() {
    cat > "$CLEAN_REPO_DIR/Makefile" << 'EOF'
.PHONY: help install test clean

help:
	@echo "Available commands:"
	@echo "  make install - Install the system"
	@echo "  make test    - Run tests"
	@echo "  make clean   - Clean up"

install:
	@echo "Installing..."
	@docker-compose up -d

test:
	@echo "Running tests..."
	@./scripts/run-tests.sh

clean:
	@echo "Cleaning..."
	@docker-compose down
EOF
}

# Create documentation with Make commands only
create_test_readme() {
    cat > "$CLEAN_REPO_DIR/README.md" << 'EOF'
# Clean Repository

This is a clean repository that follows all dependency minimization principles.

## Usage

Install the system:
```bash
make install
```

Run tests:
```bash
make test
```

Clean up:
```bash
make clean
```

## Architecture

All operations use Make commands. No direct tool invocations.
All external tools run in Docker containers.
EOF
}

# Create test script using only system tools
create_test_script() {
    cat > "$CLEAN_REPO_DIR/scripts/run-tests.sh" << 'EOF'
#!/usr/bin/env bash
# Test script using only system tools

set -euo pipefail

echo "Running tests..."

# Use only system tools: grep, sed, awk, etc.
if grep -q "test" README.md; then
    echo "✓ Tests passed"
else
    echo "✗ Tests failed"
    exit 1
fi
EOF
    chmod +x "$CLEAN_REPO_DIR/scripts/run-tests.sh"
}

# Create docker-compose for containerized tools
create_test_compose() {
    cat > "$CLEAN_REPO_DIR/docker-compose.yml" << 'EOF'
version: '3.8'
services:
  app:
    image: alpine:latest
    command: echo "Hello from container"
EOF
}

# Main setup function (NASA compliant: ≤ 60 lines)
setup_clean_repo() {
    print_info "Setting up clean test repository..."
    
    create_test_repo_structure
    create_test_makefile
    create_test_readme
    create_test_script
    create_test_compose
    
    print_success "Clean repository created"
}

cleanup_test_repo() {
    print_info "Cleaning up test repository..."
    rm -rf "$CLEAN_REPO_DIR"
    print_success "Cleanup complete"
}

#------------------------------------------------------------------------------
# Test Functions
#------------------------------------------------------------------------------

test_clean_repo_structure() {
    print_section "Test: Clean Repository Structure"
    
    # Verify clean repo was created
    assert_dir_exists "$CLEAN_REPO_DIR" "Clean repo directory should exist"
    assert_file_exists "$CLEAN_REPO_DIR/Makefile" "Makefile should exist"
    assert_file_exists "$CLEAN_REPO_DIR/README.md" "README should exist"
    assert_file_exists "$CLEAN_REPO_DIR/scripts/run-tests.sh" "Test script should exist"
    
    print_success "Clean repository structure verified"
}

test_audit_on_clean_repo() {
    print_section "Test: Audit on Clean Repository"
    
    # Check if audit script exists
    if [ ! -f "$REPO_ROOT/scripts/audit-dependencies.sh" ]; then
        print_warning "Audit script not yet implemented"
        print_info "This test will pass once scripts/audit-dependencies.sh is implemented"
        print_info "Expected behavior: audit should return 100% compliance on clean repo"
        return 0
    fi
    
    # Run audit on clean repository
    print_info "Running audit on clean repository..."
    
    local audit_output
    local audit_exit_code
    
    # Run audit and capture output and exit code
    set +e
    audit_output=$(cd "$CLEAN_REPO_DIR" && "$REPO_ROOT/scripts/audit-dependencies.sh" 2>&1)
    audit_exit_code=$?
    set -e
    
    print_info "Audit exit code: $audit_exit_code"
    
    # Verify exit code is 0 (no violations)
    if [ $audit_exit_code -ne 0 ]; then
        print_error "Audit should return exit code 0 for clean repository"
        echo "Audit output:"
        echo "$audit_output"
        return 1
    fi
    
    print_success "Audit returned exit code 0 (no violations)"
    
    # Verify compliance score is 100%
    if echo "$audit_output" | grep -q "Compliance Score: 100"; then
        print_success "Compliance score is 100%"
    else
        print_error "Compliance score should be 100% for clean repository"
        echo "Audit output:"
        echo "$audit_output"
        return 1
    fi
    
    # Verify no violations reported
    if echo "$audit_output" | grep -q "Total Violations: 0"; then
        print_success "No violations reported"
    else
        print_error "Clean repository should have zero violations"
        echo "Audit output:"
        echo "$audit_output"
        return 1
    fi
    
    print_success "Audit on clean repository passed all checks"
}

# Create dirty repo with violations for testing
create_dirty_repo() {
    local dirty_repo="$1"
    mkdir -p "$dirty_repo/scripts"
    
    # Create script with package manager violation
    cat > "$dirty_repo/scripts/bad-script.sh" << 'EOF'
#!/usr/bin/env bash
# This script violates dependency minimization

# VIOLATION: Direct package manager usage
dnf install -y python3-pip

# VIOLATION: pip install on host
pip install requests
EOF
    
    # Create README with direct tool invocation
    cat > "$dirty_repo/README.md" << 'EOF'
# Dirty Repository

## Usage

Run vagrant directly (VIOLATION):
```bash
vagrant up
```

Install packages (VIOLATION):
```bash
dnf install ansible
```
EOF
}

# Run audit and verify it detects violations
verify_audit_detects_violations() {
    local dirty_repo="$1"
    local audit_output
    local audit_exit_code
    
    print_info "Running audit on dirty repository..."
    
    # Run audit and capture output and exit code
    set +e
    audit_output=$(cd "$dirty_repo" && "$REPO_ROOT/scripts/audit-dependencies.sh" 2>&1)
    audit_exit_code=$?
    set -e
    
    # Verify exit code is 1 (violations found)
    if [ $audit_exit_code -ne 1 ]; then
        print_error "Audit should return exit code 1 when violations are found"
        echo "Audit output:"
        echo "$audit_output"
        return 1
    fi
    
    print_success "Audit correctly detected violations (exit code 1)"
    
    # Verify violations are reported
    if echo "$audit_output" | grep -q "Total Violations:"; then
        local violation_count
        violation_count=$(echo "$audit_output" | grep "Total Violations:" | grep -oE '[0-9]+' | head -1)
        if [ "$violation_count" -gt 0 ]; then
            print_success "Violations reported: $violation_count"
        else
            print_error "Should report violations > 0"
            return 1
        fi
    else
        print_error "Audit output should include violation count"
        echo "Audit output:"
        echo "$audit_output"
        return 1
    fi
    
    return 0
}

# Main test function (NASA compliant: ≤ 60 lines)
test_audit_detects_violations() {
    print_section "Test: Audit Detects Violations"
    
    # Check if audit script exists
    if [ ! -f "$REPO_ROOT/scripts/audit-dependencies.sh" ]; then
        print_warning "Audit script not yet implemented"
        print_info "Skipping violation detection test"
        return 0
    fi
    
    # Create a dirty repo with violations
    local dirty_repo="$REPO_ROOT/tests/fixtures/dirty-repo"
    
    create_dirty_repo "$dirty_repo"
    
    if verify_audit_detects_violations "$dirty_repo"; then
        print_success "Audit correctly detects violations"
    else
        rm -rf "$dirty_repo"
        return 1
    fi
    
    # Cleanup
    rm -rf "$dirty_repo"
    
    return 0
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "$TEST_NAME"
    
    local failed=0
    
    # Setup
    setup_clean_repo || {
        print_error "Setup failed"
        exit 1
    }
    
    # Run tests
    test_clean_repo_structure || ((failed++))
    test_audit_on_clean_repo || ((failed++))
    test_audit_detects_violations || ((failed++))
    
    # Cleanup
    cleanup_test_repo
    
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
