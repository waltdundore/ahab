# Pre-Release Checklist Validator Tests

This directory contains tests for the pre-release checklist validators.

## Structure

```
tests/validators/
├── unit/                      # Unit tests for individual validators
│   ├── test-validate-code-compliance.sh
│   ├── test-validate-documentation.sh
│   └── ...
├── property/                  # Property-based tests
│   ├── test-validator-properties.sh
│   └── ...
├── integration/               # Integration tests
│   ├── test-full-workflow.sh
│   └── ...
└── README.md                  # This file
```

## Test Types

### Unit Tests

Test individual validator functions in isolation.

**Location**: `unit/test-validate-<name>.sh`

**Example**:
```bash
#!/bin/bash
# Unit tests for code compliance validator

test_detects_direct_vagrant_usage() {
    # Create temp file with violation
    echo 'vagrant up' > /tmp/test.sh
    
    # Run validator
    if validate_code_compliance /tmp/test.sh; then
        fail "Should have detected vagrant usage"
    fi
    
    # Verify error message
    assert_contains "Direct vagrant commands found"
}

test_allows_make_commands() {
    # Create temp file without violation
    echo 'make install' > /tmp/test.sh
    
    # Run validator
    if ! validate_code_compliance /tmp/test.sh; then
        fail "Should have passed for make commands"
    fi
}
```

### Property-Based Tests

Test universal properties that should hold across all inputs.

**Location**: `property/test-validator-properties.sh`

**Example**:
```bash
#!/bin/bash
# Property-based tests for validators

# Property: For any code file, if it contains 'vagrant up', validator should fail
test_property_vagrant_detection() {
    for i in {1..100}; do
        # Generate random code file with vagrant command
        generate_random_code_with_vagrant > /tmp/test_$i.sh
        
        # Validator should fail
        if validate_code_compliance /tmp/test_$i.sh; then
            fail "Iteration $i: Failed to detect vagrant usage"
        fi
    done
}

# Property: For any code file without violations, validator should pass
test_property_clean_code_passes() {
    for i in {1..100}; do
        # Generate random clean code
        generate_random_clean_code > /tmp/test_$i.sh
        
        # Validator should pass
        if ! validate_code_compliance /tmp/test_$i.sh; then
            fail "Iteration $i: False positive on clean code"
        fi
    done
}
```

### Integration Tests

Test the full pre-release check workflow.

**Location**: `integration/test-full-workflow.sh`

**Example**:
```bash
#!/bin/bash
# Integration tests for pre-release check

test_full_workflow_on_clean_repo() {
    # Setup clean test repo
    setup_clean_test_repo
    
    # Run full check
    if ! ../../scripts/pre-release-check.sh; then
        fail "Clean repo should pass all checks"
    fi
    
    # Verify report generated
    assert_file_exists "pre-release-report.txt"
}

test_full_workflow_with_violations() {
    # Setup repo with known violations
    setup_repo_with_violations
    
    # Run full check
    if ../../scripts/pre-release-check.sh; then
        fail "Repo with violations should fail"
    fi
    
    # Verify specific errors reported
    assert_contains "Direct vagrant commands found"
}
```

## Running Tests

### All Tests
```bash
cd ahab
make test-validators
```

### Unit Tests Only
```bash
cd ahab
make test-validators-unit
```

### Property Tests Only
```bash
cd ahab
make test-validators-property
```

### Integration Tests Only
```bash
cd ahab
make test-validators-integration
```

### Individual Test
```bash
cd ahab/tests/validators/unit
./test-validate-code-compliance.sh
```

## Test Helpers

Common test utilities are available in `../lib/test-helpers.sh`:

```bash
# Source test helpers
source "$(dirname "$0")/../../lib/test-helpers.sh"

# Available functions:
assert_equals "expected" "actual"
assert_contains "substring" "string"
assert_file_exists "path"
assert_file_contains "pattern" "file"
fail "message"
setup_test_env
cleanup_test_env
```

## Writing Tests

### Test Naming Convention
- Test files: `test-<component>.sh`
- Test functions: `test_<description>`
- Use descriptive names that explain what is being tested

### Test Structure
```bash
#!/bin/bash
# Test: Component Name
# Purpose: Test description

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/test-helpers.sh"

# Setup
setup() {
    setup_test_env
}

# Teardown
teardown() {
    cleanup_test_env
}

# Test functions
test_something() {
    # Arrange
    local input="test"
    
    # Act
    local result=$(function_under_test "$input")
    
    # Assert
    assert_equals "expected" "$result"
}

# Run tests
main() {
    setup
    
    test_something
    # Add more tests...
    
    teardown
    
    echo "All tests passed"
}

main "$@"
```

### Best Practices

1. **Test one thing per test** - Each test should verify one behavior
2. **Use descriptive names** - Test name should explain what is tested
3. **Arrange-Act-Assert** - Structure tests clearly
4. **Clean up after tests** - Remove temp files, restore state
5. **Test edge cases** - Empty inputs, large inputs, special characters
6. **Test error conditions** - Verify failures are detected
7. **Make tests independent** - Tests should not depend on each other
8. **Use test helpers** - Don't duplicate assertion logic

## Test Coverage Goals

- **Unit tests**: 100% coverage of validator functions
- **Property tests**: 100+ iterations per property
- **Integration tests**: Cover all validator combinations
- **Edge cases**: Empty files, large files, binary files, symlinks

## Continuous Integration

Tests run automatically on:
- Every commit (via git hooks)
- Every pull request (via CI/CD)
- Before release (via pre-release check)

## Troubleshooting

### Tests Fail Locally But Pass in CI
- Check for hardcoded paths
- Verify environment variables
- Check for timing issues

### Tests Pass But Validator Fails in Production
- Add integration test for the scenario
- Check for environment differences
- Verify test coverage is complete

### Property Tests Find Issues
- This is good! Property tests catch edge cases
- Fix the validator or adjust the property
- Add unit test for the specific case

## Related Documents

- Design: `.kiro/specs/pre-release-checklist/design.md`
- Requirements: `.kiro/specs/pre-release-checklist/requirements.md`
- Validators: `../../scripts/validators/README.md`
