# Unit Tests

![Ahab Logo](../docs/images/ahab-logo.png)

This directory contains unit tests for the Ahab Control system.

## Available Tests

### test-audit-compliance.sh

Tests that the dependency minimization audit returns 100% compliance on a clean codebase.

**Validates:** Requirements 9.1

**What it tests:**
1. Creates a clean test repository that follows all dependency minimization principles
2. Verifies the audit script returns exit code 0 (no violations)
3. Verifies the compliance score is 100%
4. Verifies zero violations are reported
5. Tests that violations are correctly detected in a dirty repository

**Usage:**
```bash
# Run this specific test
bash tests/unit/test-audit-compliance.sh

# Run all unit tests
make test-unit
```

**Test Structure:**
- Creates a fixture repository with proper Make targets
- Documentation uses only Make commands
- Scripts use only system tools
- External tools are containerized in docker-compose.yml

**Expected Behavior:**
- When audit script is not yet implemented: Test passes with warnings
- When audit script exists: Test validates 100% compliance on clean repo
- Test also validates that violations are detected in dirty repositories

## Adding New Unit Tests

1. Create a new test file: `tests/unit/test-<feature>.sh`
2. Make it executable: `chmod +x tests/unit/test-<feature>.sh`
3. Use the test helper libraries:
   - `source ../lib/test-helpers.sh` - Helper functions
   - `source ../lib/assertions.sh` - Assertion functions
4. Follow the existing test structure:
   - Setup function
   - Test functions
   - Cleanup function
   - Main execution function
5. Run with `make test-unit`

## Test Helpers

See `tests/lib/` for available helper functions:
- `test-helpers.sh` - Common utilities (print functions, VM management, etc.)
- `assertions.sh` - Assertion functions for testing
- `test-config.sh` - Shared configuration and constants
