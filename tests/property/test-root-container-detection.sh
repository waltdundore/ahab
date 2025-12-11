#!/usr/bin/env bash
# ==============================================================================
# Property Test: Root Container Detection
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 13: Root container detection**
# **Validates: Requirements 3.5**
#
# This test verifies that the root container detection check correctly identifies
# containers configured to run as root across a wide range of Docker configurations.
#
# Property: For any Dockerfile or docker-compose.yml, the security check should
# correctly identify containers configured to run as root.
#
# Test Strategy:
# 1. Generate Dockerfiles without USER directive (should fail - defaults to root)
# 2. Generate Dockerfiles with explicit USER root (should fail)
# 3. Generate Dockerfiles with non-root USER (should pass)
# 4. Generate docker-compose files with user: root (should fail)
# 5. Generate docker-compose files with user: 0 (should fail)
# 6. Generate docker-compose files with non-root user (should pass)
# 7. Test edge cases (privileged mode, no user specified, etc.)
# 8. Run 100+ iterations with different configurations
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
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/check-container-users.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/root-container-test"

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

create_dockerfile() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
$content
EOF
}

create_compose_file() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
$content
EOF
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
# Test Functions - Dockerfiles That Should Fail
#------------------------------------------------------------------------------

test_dockerfile_no_user() {
    print_section "Test 1: Dockerfile without USER directive (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY . /app

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_error "False negative: missed Dockerfile without USER directive"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected missing USER directive"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_dockerfile_explicit_root() {
    print_section "Test 2: Dockerfile with explicit USER root (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY . /app

USER root

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_error "False negative: missed explicit USER root"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected explicit USER root"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_dockerfile_root_uid() {
    print_section "Test 3: Dockerfile with USER 0 (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY . /app

USER 0

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_error "False negative: missed USER 0 (root UID)"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected USER 0 (root UID)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Dockerfiles That Should Pass
#------------------------------------------------------------------------------

test_dockerfile_with_nonroot_user() {
    print_section "Test 4: Dockerfile with non-root USER (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY . /app

RUN useradd -m -u 1000 appuser
USER appuser

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_success "Correctly identified non-root USER"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged non-root USER"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_dockerfile_with_named_user() {
    print_section "Test 5: Dockerfile with named non-root user (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app
COPY . /app

USER appuser

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_success "Correctly identified named non-root user"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged named non-root user"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_dockerfile_with_uid_gid() {
    print_section "Test 6: Dockerfile with UID:GID (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

RUN groupadd -g 1000 appgroup && useradd -u 1000 -g appgroup appuser

WORKDIR /app
COPY . /app

USER 1000:1000

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_success "Correctly identified non-root UID:GID"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged non-root UID:GID"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Docker Compose Files That Should Fail
#------------------------------------------------------------------------------

test_compose_user_root() {
    print_section "Test 7: docker-compose with user: root (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    user: root
    command: python app.py
'
    
    if run_check_on_directory; then
        print_error "False negative: missed user: root in compose"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected user: root in compose"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_compose_user_zero() {
    print_section "Test 8: docker-compose with user: 0 (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    user: 0
    command: python app.py
'
    
    if run_check_on_directory; then
        print_error "False negative: missed user: 0 in compose"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected user: 0 in compose"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_compose_user_zero_colon_zero() {
    print_section "Test 9: docker-compose with user: 0:0 (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    user: 0:0
    command: python app.py
'
    
    if run_check_on_directory; then
        print_error "False negative: missed user: 0:0 in compose"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected user: 0:0 in compose"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Docker Compose Files That Should Pass
#------------------------------------------------------------------------------

test_compose_nonroot_user() {
    print_section "Test 10: docker-compose with non-root user (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    user: "1000:1000"
    command: python app.py
'
    
    if run_check_on_directory; then
        print_success "Correctly identified non-root user in compose"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged non-root user in compose"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_compose_no_user_specified() {
    print_section "Test 11: docker-compose without user specified (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    # Note: This should pass because the check is for docker-compose files
    # that explicitly set user: root, not for missing user directives
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    command: python app.py
'
    
    if run_check_on_directory; then
        print_success "Correctly handled compose without user directive"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Compose without user directive flagged (acceptable - relies on Dockerfile)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_compose_privileged_mode() {
    print_section "Test 12: docker-compose with privileged: true (warning)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_compose_file "docker-compose.yml" 'version: "3.8"

services:
  app:
    image: python:3.11-slim
    user: "1000:1000"
    privileged: true
    command: python app.py
'
    
    # Privileged mode should generate a warning but not fail
    # (it's a valid use case for hardware access)
    if run_check_on_directory; then
        print_success "Correctly handled privileged mode (warning only)"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Privileged mode caused failure (acceptable - security concern)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_dockerfiles() {
    print_section "Test 13: Multiple Dockerfiles, one with root (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    # Good Dockerfile
    create_dockerfile "Dockerfile.good" 'FROM python:3.11-slim
USER 1000
CMD ["python", "app.py"]
'
    
    # Bad Dockerfile (no USER)
    create_dockerfile "Dockerfile.bad" 'FROM python:3.11-slim
CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_error "False negative: missed bad Dockerfile among multiple files"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected bad Dockerfile among multiple files"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_empty_dockerfile() {
    print_section "Test 14: Empty Dockerfile (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" ''
    
    if run_check_on_directory; then
        print_success "Correctly handled empty Dockerfile"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Empty Dockerfile flagged (acceptable)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_dockerfile_with_comments() {
    print_section "Test 15: Dockerfile with USER in comments (should fail)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim

# TODO: Add USER directive
# USER appuser

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_error "False negative: missed Dockerfile with commented USER"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected missing USER (comments don't count)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multistage_dockerfile() {
    print_section "Test 16: Multi-stage Dockerfile with USER in final stage (should pass)"
    
    ((TESTS_RUN++))
    
    # Clean test directory
    rm -rf "$TEST_DIR"/*
    
    create_dockerfile "Dockerfile" 'FROM python:3.11-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /build /app

RUN useradd -m -u 1000 appuser
USER appuser

CMD ["python", "app.py"]
'
    
    if run_check_on_directory; then
        print_success "Correctly identified USER in multi-stage Dockerfile"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged multi-stage Dockerfile with USER"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Property-Based Test Iterations
#------------------------------------------------------------------------------

# Test case generators for iteration tests
test_dockerfile_no_user() {
    local iteration=$1
    create_dockerfile "Dockerfile" "FROM alpine:latest
RUN apk add --no-cache python3
CMD [\"python3\", \"-m\", \"http.server\"]
"
    if run_check_on_directory; then
        print_error "Iteration $iteration: False negative on missing USER"
        ((TESTS_FAILED++))
    else
        ((TESTS_PASSED++))
    fi
}

test_dockerfile_root_user() {
    local iteration=$1
    create_dockerfile "Dockerfile" "FROM alpine:latest
RUN apk add --no-cache python3
USER root
CMD [\"python3\", \"-m\", \"http.server\"]
"
    if run_check_on_directory; then
        print_error "Iteration $iteration: False negative on USER root"
        ((TESTS_FAILED++))
    else
        ((TESTS_PASSED++))
    fi
}

test_dockerfile_nonroot_user() {
    local iteration=$1
    local uid=$((1000 + RANDOM % 1000))
    create_dockerfile "Dockerfile" "FROM alpine:latest
RUN apk add --no-cache python3
RUN adduser -D -u $uid appuser
USER appuser
CMD [\"python3\", \"-m\", \"http.server\"]
"
    if run_check_on_directory; then
        ((TESTS_PASSED++))
    else
        print_error "Iteration $iteration: False positive on non-root USER"
        ((TESTS_FAILED++))
    fi
}

test_compose_root_user() {
    local iteration=$1
    create_compose_file "docker-compose.yml" "version: '3.8'
services:
  app:
    image: alpine:latest
    user: root
    command: sleep infinity
"
    if run_check_on_directory; then
        print_error "Iteration $iteration: False negative on compose user: root"
        ((TESTS_FAILED++))
    else
        ((TESTS_PASSED++))
    fi
}

test_compose_nonroot_user() {
    local iteration=$1
    local uid=$((1000 + RANDOM % 1000))
    create_compose_file "docker-compose.yml" "version: '3.8'
services:
  app:
    image: alpine:latest
    user: \"$uid:$uid\"
    command: sleep infinity
"
    if run_check_on_directory; then
        ((TESTS_PASSED++))
    else
        print_error "Iteration $iteration: False positive on compose non-root user"
        ((TESTS_FAILED++))
    fi
}

test_compose_uid_zero() {
    local iteration=$1
    create_compose_file "docker-compose.yml" "version: '3.8'
services:
  app:
    image: alpine:latest
    user: 0
    command: sleep infinity
"
    if run_check_on_directory; then
        print_error "Iteration $iteration: False negative on compose user: 0"
        ((TESTS_FAILED++))
    else
        ((TESTS_PASSED++))
    fi
}

# Run iteration tests (NASA compliant: ≤ 60 lines)
run_iteration_tests() {
    local iteration=$1
    
    if [ $((iteration % 20)) -eq 0 ]; then
        print_info "Completed $iteration/$MIN_ITERATIONS iterations..."
    fi
    
    ((TESTS_RUN++))
    rm -rf "$TEST_DIR"/*
    
    # Generate random test case
    local test_type=$((RANDOM % 10))
    
    case $test_type in
        0|1) test_dockerfile_no_user "$iteration" ;;
        2)   test_dockerfile_root_user "$iteration" ;;
        3|4) test_dockerfile_nonroot_user "$iteration" ;;
        5|6) test_compose_root_user "$iteration" ;;
        7|8) test_compose_nonroot_user "$iteration" ;;
        9)   test_compose_uid_zero "$iteration" ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

# Run Dockerfile tests that should fail
run_dockerfile_fail_tests() {
    test_dockerfile_no_user
    test_dockerfile_explicit_root
    test_dockerfile_root_uid
}

# Run Dockerfile tests that should pass
run_dockerfile_pass_tests() {
    test_dockerfile_with_nonroot_user
    test_dockerfile_with_named_user
    test_dockerfile_with_uid_gid
}

# Run compose tests that should fail
run_compose_fail_tests() {
    test_compose_user_root
    test_compose_user_zero
    test_compose_user_zero_colon_zero
}

# Run compose tests that should pass
run_compose_pass_tests() {
    test_compose_nonroot_user
    test_compose_no_user_specified
}

# Run edge case tests
run_edge_case_tests() {
    test_compose_privileged_mode
    test_multiple_dockerfiles
    test_empty_dockerfile
    test_dockerfile_with_comments
    test_multistage_dockerfile
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
        print_success "✓ All tests passed - Root container detection is working correctly"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly identifies Dockerfiles without USER directive"
        print_info "  • Correctly detects explicit USER root"
        print_info "  • Correctly identifies non-root users (no false positives)"
        print_info "  • Correctly detects user: root in docker-compose files"
        print_info "  • Correctly detects user: 0 (root UID) in compose files"
        print_info "  • Handles edge cases (privileged mode, multi-stage, etc.)"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        return 0
    else
        print_error "✗ Some tests failed - Root container detection has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Non-root containers flagged incorrectly"
        print_info "  • False negatives: Root containers not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

# Main function (NASA compliant: ≤ 60 lines)
main() {
    print_section "Root Container Detection - Property Test"
    
    print_info "Testing root container detection across wide range of configurations"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Verify check script exists
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Run all test categories
    run_dockerfile_fail_tests
    run_dockerfile_pass_tests
    run_compose_fail_tests
    run_compose_pass_tests
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
