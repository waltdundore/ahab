#!/usr/bin/env bash
# Library file - sourced by tests, no cleanup needed
# ==============================================================================
# Test Assertion Functions
# ==============================================================================
# NASA Rule 5: Minimum 2 assertions per function
# All assertions provide empathetic error messages
# ==============================================================================

# Source test helpers for print functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Assert command exists
assert_command() {
    local cmd="$1"
    local error_msg="${2:-Command '$cmd' not found}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local error_msg="${2:-File '$file' does not exist}"
    
    if [ ! -f "$file" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local error_msg="${2:-Directory '$dir' does not exist}"
    
    if [ ! -d "$dir" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local error_msg="${3:-Expected '$expected' but got '$actual'}"
    
    if [ "$expected" != "$actual" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string not empty
assert_not_empty() {
    local value="$1"
    local error_msg="${2:-Value is empty}"
    
    if [ -z "$value" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string contains substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local error_msg="${3:-String does not contain '$needle'}"
    
    if [[ ! "$haystack" =~ $needle ]]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert VM is running
assert_vm_running() {
    local error_msg="${1:-VM is not running}"
    
    if ! vagrant status 2>/dev/null | grep -q "running"; then
        print_error "$error_msg"
        print_info "Check status with: vagrant status"
        return 1
    fi
    return 0
}

# Assert service is active
assert_service_active() {
    local service="$1"
    local error_msg="${2:-Service '$service' is not active}"
    
    if ! vagrant ssh -c "systemctl is-active $service" >/dev/null 2>&1; then
        print_error "$error_msg"
        print_info "Check service with: vagrant ssh -c 'systemctl status $service'"
        return 1
    fi
    return 0
}

# Assert HTTP response
assert_http_response() {
    local url="$1"
    local expected_code="${2:-200}"
    local error_msg="${3:-HTTP request to '$url' failed}"
    
    local actual_code
    actual_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$actual_code" != "$expected_code" ]; then
        print_error "$error_msg"
        print_info "Expected HTTP $expected_code, got $actual_code"
        return 1
    fi
    return 0
}
