# Ahab Test Infrastructure

![Ahab Logo](docs/images/ahab-logo.png)

## Overview

This directory contains all tests for the Ahab infrastructure management system. Tests are organized by type and follow NASA Power of 10 standards for safety-critical systems.

## Test Philosophy

### 1. Empathy First (Above All Else)

Tests exist to help developers, not punish them. Every error message:
- Acknowledges frustration
- Provides clear next steps
- Assumes good intent
- Offers help and resources

**Example:**
```
❌ BAD: "Error: VM failed to start"
✅ GOOD: "VM failed to start. This is frustrating, I know. 
         Let's figure this out together. Common causes:
         • VirtualBox might not be running
         • Port 2222 might be in use
         Try: vagrant destroy -f && vagrant up"
```

### 2. Idempotency

All tests can be run multiple times without side effects:
- `make test` twice = same result
- Tests clean up after themselves (VMs, containers, files)
- Failed test halfway through? Run again without manual cleanup

### 3. Self-Healing

Tests must work after the creator is gone:
- Detect regressions automatically
- Provide clear guidance for fixes
- Account for human mistakes

## Test Categories

### Unit Tests (`tests/unit/`)

Fast tests that validate individual components:
- Configuration parsing
- Path resolution
- Error handling
- Input validation

**Characteristics:**
- Execute in <5 seconds per test
- No external dependencies
- Test single functions/modules

**Run with:**
```bash
make test-unit
```

### Integration Tests (`tests/integration/`)

Tests that validate complete workflows:
- Workstation VM creation and provisioning
- Apache deployment validation
- Docker Compose generation
- Module system functionality

**Characteristics:**
- Execute in minutes
- May require VMs or containers
- Test multiple components working together

**Run with:**
```bash
make test-integration
```

**Available tests:**
- `test-workstation.sh` - Validates workstation VM setup
- `test-apache-docker.sh` - Tests Apache in Docker
- `test-apache-simple.sh` - Simple Apache test (no Docker)
- `test-os-versions.sh` - Verifies Debian, Fedora, Ubuntu versions

### End-to-End Tests (`tests/e2e/`)

Complete workflow validation from start to finish:
- Nested virtualization tests
- Full Apache deployment from workstation
- Multi-stage deployment validation

**Characteristics:**
- Longest running (10-15 minutes)
- Test entire user workflows
- Most comprehensive validation

**Run with:**
```bash
make test-e2e
```

**Available tests:**
- `test-workstation-apache.sh` - Full workstation + Apache deployment
- `test-apache-e2e.sh` - Complete Apache deployment workflow

## Shared Test Library (`tests/lib/`)

All tests use shared utilities to avoid code duplication:

### test-helpers.sh
- `print_success()` - Green success message
- `print_error()` - Red error message with empathy
- `print_info()` - Blue informational message
- `print_warning()` - Yellow warning message
- `check_command()` - Verify command exists
- `check_vagrant()` - Verify Vagrant installed
- `check_virtualbox()` - Verify VirtualBox installed
- `wait_for_vm()` - Wait for VM with bounded timeout
- `cleanup_vm()` - Idempotent VM cleanup
- `verify_vm_running()` - Check VM status

### assertions.sh
- `assert_command()` - Assert command exists
- `assert_file_exists()` - Assert file exists
- `assert_dir_exists()` - Assert directory exists
- `assert_equals()` - Assert string equality
- `assert_not_empty()` - Assert string not empty
- `assert_contains()` - Assert string contains substring
- `assert_vm_running()` - Assert VM is running
- `assert_service_active()` - Assert service is active
- `assert_http_response()` - Assert HTTP response code

### cleanup.sh
- `cleanup_test_vms()` - Remove all test VMs
- `cleanup_docker_containers()` - Remove test containers
- `cleanup_temp_files()` - Remove temp files
- `cleanup_all()` - Complete cleanup

### test-config.sh
- Shared configuration constants
- Timeout values (NASA Rule 2: bounded loops)
- Path definitions
- VM naming conventions

## Running Tests

### Quick Start

```bash
# Run all tests
make test

# Run specific test category
make test-unit
make test-integration
make test-e2e

# Run OS version verification (Debian, Fedora, Ubuntu)
make test-os-versions

# Run NASA standards validation
make test-nasa

# Validate test scripts themselves
make validate-tests
```

### Prerequisites

Tests require:
- Vagrant (for VM tests)
- VirtualBox (for VM provider)
- Docker (for container tests)
- shellcheck (for static analysis)
- ansible-lint (for playbook validation)

Install on macOS:
```bash
brew install vagrant virtualbox docker shellcheck ansible-lint
```

## Writing New Tests

### Test Script Template

```bash
#!/usr/bin/env bash
# ==============================================================================
# Test Name
# ==============================================================================
# Description of what this test validates
#
# Usage:
#   make test-integration  # Runs this test
#
# Success criteria:
#   - Criterion 1
#   - Criterion 2
#
# NASA Power of 10 Compliance:
#   - Bounded loops with timeouts
#   - All returns checked
#   - Functions ≤60 lines
# ==============================================================================

set -euo pipefail  # Fail fast

# Source shared libraries (internal use only - users run via make test)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"
# shellcheck source=../lib/assertions.sh
source "$SCRIPT_DIR/../lib/assertions.sh"
# shellcheck source=../lib/cleanup.sh
source "$SCRIPT_DIR/../lib/cleanup.sh"
# shellcheck source=../lib/test-config.sh
source "$SCRIPT_DIR/../lib/test-config.sh"

# Test configuration
readonly TEST_NAME="test-name"
readonly MAX_TIMEOUT=300

# Cleanup on exit (idempotent)
trap cleanup_on_exit EXIT

main() {
    print_info "Starting $TEST_NAME..."
    
    check_prerequisites || exit 1
    run_test || exit 1
    verify_results || exit 1
    
    print_success "$TEST_NAME PASSED"
    exit 0
}

check_prerequisites() {
    # NASA Rule 5: Min 2 assertions per function
    check_vagrant || return 1
    check_virtualbox || return 1
    
    print_success "All prerequisites installed"
    return 0
}

run_test() {
    # NASA Rule 7: Check all returns
    if ! vagrant up; then
        print_error "VM failed to start"
        echo ""
        print_info "This is frustrating, I know. Let's figure this out together."
        print_info "Common causes: VirtualBox not running, port in use"
        print_info "Try: vagrant destroy -f && vagrant up"
        return 1
    fi
    
    # NASA Rule 2: Bounded loops
    wait_for_vm 60 || return 1
    
    return 0
}

verify_results() {
    # NASA Rule 5: Min 2 assertions
    assert_vm_running || return 1
    assert_service_active "sshd" || return 1
    
    return 0
}

cleanup_on_exit() {
    # IDEMPOTENCY: Clean up so test can be run again
    print_info "Cleaning up test resources..."
    vagrant destroy -f 2>/dev/null || true
    rm -rf .vagrant 2>/dev/null || true
    print_success "Cleanup complete"
}

# Run main
main "$@"
```

## NASA Power of 10 Compliance

All test scripts must comply with NASA Power of 10 rules for safety-critical systems:

### Rule 1: Simple Control Flow
- No goto statements
- No recursion
- Clear, linear flow

### Rule 2: Bounded Loops
- All loops have fixed upper bounds
- Use timeouts for waiting operations
- Example: `for i in $(seq 1 $MAX_WAIT); do ... done`

### Rule 3: No Dynamic Memory After Init
- No unbounded array growth
- Fixed-size data structures

### Rule 4: Short Functions
- Maximum 60 lines per function
- Break large functions into smaller ones
- Each function does one thing

### Rule 5: High Assertion Density
- Minimum 2 assertions per function
- Validate all assumptions
- Check all critical conditions

### Rule 6: Minimal Scope
- Use `local` for function variables
- Declare variables at smallest scope
- Avoid global state

### Rule 7: Check All Returns
- Validate all command exit codes
- Use `set -e` or explicit checks
- Never ignore errors

### Rule 8: Limited Preprocessor
- Avoid complex variable substitution
- Keep shell expansions simple

### Rule 9: Restricted Pointers
- Avoid complex indirection
- Keep references simple

### Rule 10: Zero Warnings
- Pass shellcheck with zero warnings
- Fix all linting issues
- No exceptions

## Test Naming Conventions

- Test files: `test-<component>.sh`
- Test functions: `test_<feature>()`
- Helper functions: `<verb>_<noun>()`
- Constants: `UPPER_CASE`
- Variables: `lower_case`

## Expected Test Duration

- Unit tests: <5 seconds each
- Integration tests: 5-15 minutes each
- End-to-end tests: 10-20 minutes each
- Full test suite: ~30 minutes

## Troubleshooting Common Failures

### VM Won't Start

**Symptoms:** `vagrant up` fails or times out

**Common Causes:**
- VirtualBox not running
- Port 2222 already in use
- Insufficient disk space
- Insufficient memory

**Solutions:**
```bash
# Check VirtualBox
VBoxManage --version

# Check port usage
lsof -i :2222

# Clean start
vagrant destroy -f && vagrant up

# Debug mode
vagrant up --debug
```

### Docker Container Won't Start

**Symptoms:** `docker run` fails

**Common Causes:**
- Docker daemon not running
- Port already in use
- Image not built

**Solutions:**
```bash
# Check Docker
docker info

# Check port
lsof -i :8080

# Rebuild image
docker build -t <image> .

# Check logs
docker logs <container>
```

### Test Hangs

**Symptoms:** Test runs forever

**Common Causes:**
- Unbounded loop (violates NASA Rule 2)
- Waiting for condition that never occurs
- Network timeout

**Solutions:**
- Check for `while true` loops
- Verify timeout values
- Add debug output
- Use `timeout` command

### Cleanup Fails

**Symptoms:** Test leaves resources behind

**Common Causes:**
- Missing cleanup function
- Cleanup not idempotent
- Trap not set

**Solutions:**
- Add `trap cleanup EXIT`
- Make cleanup idempotent (safe to run multiple times)
- Test cleanup independently

## Continuous Integration

Tests run automatically on:
- Every commit (pre-commit hook)
- Every push (GitHub Actions)
- Every pull request (GitHub Actions)

**Pre-commit Hook:**
- Validates NASA standards
- Runs shellcheck
- Blocks commit if violations found

**GitHub Actions:**
- Runs full test suite
- Uploads test artifacts
- Blocks merge if tests fail

## Test Artifacts

When tests fail, artifacts are preserved:
- Test logs
- VM logs
- Container logs
- Screenshots (if applicable)

Artifacts are uploaded to GitHub Actions and retained for 7 days.

## Getting Help

If tests fail and you're stuck:

1. **Read the error message** - It's designed to help you
2. **Check this README** - Common issues documented above
3. **Run with debug** - Add `-x` to bash for verbose output
4. **Ask for help** - Open an issue with:
   - Full error output
   - Steps to reproduce
   - Your environment (OS, versions)

Remember: Test failures are not your fault. They're opportunities to improve the system.

## Contributing

When adding new tests:

1. Follow the test template above
2. Use shared library functions
3. Follow NASA Power of 10 standards
4. Include empathetic error messages
5. Make tests idempotent
6. Document in this README
7. Run `make validate-tests` before committing

## Resources

- [NASA Power of 10 Rules](http://spinroot.com/gerard/pdf/P10.pdf)
- [Shellcheck Documentation](https://www.shellcheck.net/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
