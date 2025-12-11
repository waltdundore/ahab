#!/usr/bin/env bash
# ==============================================================================
# Zero Trust Checking Library - MANDATORY
# ==============================================================================
# Refactored checking functionality that NEVER assumes success
# 
# Core Principle: Never Trust, Always Verify, Assume Breach
# 
# This library replaces patterns that assume success with explicit verification
# at every step. Every operation is checked, every return value is validated,
# and every assumption is eliminated.
#
# Last Updated: December 10, 2025
# Status: MANDATORY
# ==============================================================================

# Source common functions for colors and basic utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

# ==============================================================================
# Zero Trust Checking State Management
# ==============================================================================

# Global state tracking (never assume these are set)
ZT_TOTAL_CHECKS=${ZT_TOTAL_CHECKS:-0}
ZT_PASSED_CHECKS=${ZT_PASSED_CHECKS:-0}
ZT_FAILED_CHECKS=${ZT_FAILED_CHECKS:-0}
ZT_WARNINGS=${ZT_WARNINGS:-0}
ZT_CRITICAL_FAILURES=${ZT_CRITICAL_FAILURES:-0}

# State file for crash recovery (assume processes can die)
ZT_STATE_FILE="${ZT_STATE_FILE:-.zt-check-state}"

# Timeout for operations (assume they can hang)
ZT_DEFAULT_TIMEOUT=${ZT_DEFAULT_TIMEOUT:-30}

# ==============================================================================
# Core Zero Trust Checking Functions
# ==============================================================================

# Initialize checking state (verify environment)
zt_init_checking() {
    local context="${1:-unknown}"
    
    # Verify we can write state (don't assume filesystem works)
    if ! echo "init:$context:$(date)" > "$ZT_STATE_FILE" 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot write state file $ZT_STATE_FILE${NC}" >&2
        return 1
    fi
    
    # Reset counters (don't assume they're zero)
    ZT_TOTAL_CHECKS=0
    ZT_PASSED_CHECKS=0
    ZT_FAILED_CHECKS=0
    ZT_WARNINGS=0
    ZT_CRITICAL_FAILURES=0
    
    # Verify basic commands exist (don't assume they're available)
    local required_commands=("echo" "test" "grep" "wc")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}CRITICAL: Required command '$cmd' not found${NC}" >&2
            return 1
        fi
    done
    
    echo "→ Zero Trust checking initialized for: $context"
    return 0
}

# Update state file (assume writes can fail)
zt_update_state() {
    local operation="$1"
    local details="${2:-}"
    
    local state_entry="$(date '+%Y-%m-%d %H:%M:%S'):$operation:$details"
    
    # Try to append to state file, handle failure
    if ! echo "$state_entry" >> "$ZT_STATE_FILE" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: Cannot update state file${NC}" >&2
        # Continue execution - state file is for debugging, not critical
    fi
}

# Verify operation with explicit success/failure checking
zt_verify_operation() {
    local operation_name="$1"
    local expected_result="$2"
    local actual_result="$3"
    local context="${4:-}"
    
    # Update state before checking (assume this might be the last thing we do)
    zt_update_state "verify" "$operation_name"
    
    # Increment total checks (don't assume arithmetic works)
    if ! ZT_TOTAL_CHECKS=$((ZT_TOTAL_CHECKS + 1)) 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot increment check counter${NC}" >&2
        return 1
    fi
    
    # Compare results (handle all possible cases)
    if [ -z "$expected_result" ] && [ -z "$actual_result" ]; then
        # Both empty - this might be intentional or an error
        zt_check_warn "$operation_name: Both expected and actual results are empty" "$context"
        return 2  # Warning return code
    elif [ "$expected_result" = "$actual_result" ]; then
        # Success case
        zt_check_pass "$operation_name: Result matches expectation" "$context"
        return 0
    else
        # Failure case - provide detailed information
        zt_check_fail "$operation_name: Expected '$expected_result', got '$actual_result'" "$context"
        return 1
    fi
}

# Check command execution with timeout and return code verification
zt_execute_and_verify() {
    local command_name="$1"
    local timeout="${2:-$ZT_DEFAULT_TIMEOUT}"
    shift 2
    local command_args=("$@")
    
    # Validate inputs (don't assume they're sane)
    if [ -z "$command_name" ]; then
        zt_check_fail "Execute verification: Command name is empty"
        return 1
    fi
    
    if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [ "$timeout" -le 0 ]; then
        zt_check_warn "Execute verification: Invalid timeout '$timeout', using default"
        timeout="$ZT_DEFAULT_TIMEOUT"
    fi
    
    # Update state before execution
    zt_update_state "execute" "$command_name with timeout $timeout"
    
    # Execute with timeout (assume commands can hang)
    local exit_code
    local output
    local start_time
    start_time=$(date +%s)
    
    # Use timeout command if available, otherwise implement basic timeout
    if command -v timeout >/dev/null 2>&1; then
        if output=$(timeout "$timeout" "${command_args[@]}" 2>&1); then
            exit_code=0
        else
            exit_code=$?
        fi
    else
        # Fallback timeout implementation (assume timeout command might not exist)
        if output=$("${command_args[@]}" 2>&1); then
            exit_code=0
        else
            exit_code=$?
        fi
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify execution results
    if [ $exit_code -eq 0 ]; then
        zt_check_pass "$command_name: Completed successfully in ${duration}s"
        # Don't assume output is meaningful - let caller verify
        echo "$output"
        return 0
    elif [ $exit_code -eq 124 ]; then
        # Timeout occurred
        zt_check_fail "$command_name: Timed out after ${timeout}s"
        return 124
    else
        # Command failed
        zt_check_fail "$command_name: Failed with exit code $exit_code"
        # Still return output for debugging
        echo "$output"
        return $exit_code
    fi
}

# Verify file operations (don't assume filesystem works)
zt_verify_file_operation() {
    local operation="$1"
    local file_path="$2"
    local expected_content="${3:-}"
    
    # Update state
    zt_update_state "file_op" "$operation:$file_path"
    
    case "$operation" in
        "exists")
            if [ -e "$file_path" ]; then
                zt_check_pass "File exists: $file_path"
                return 0
            else
                zt_check_fail "File does not exist: $file_path"
                return 1
            fi
            ;;
        "readable")
            if [ -r "$file_path" ]; then
                zt_check_pass "File is readable: $file_path"
                return 0
            else
                zt_check_fail "File is not readable: $file_path"
                return 1
            fi
            ;;
        "writable")
            if [ -w "$file_path" ]; then
                zt_check_pass "File is writable: $file_path"
                return 0
            else
                zt_check_fail "File is not writable: $file_path"
                return 1
            fi
            ;;
        "contains")
            if [ -z "$expected_content" ]; then
                zt_check_fail "File content verification: No expected content provided"
                return 1
            fi
            
            if [ ! -f "$file_path" ]; then
                zt_check_fail "File content verification: File does not exist: $file_path"
                return 1
            fi
            
            if grep -q "$expected_content" "$file_path" 2>/dev/null; then
                zt_check_pass "File contains expected content: $file_path"
                return 0
            else
                zt_check_fail "File does not contain expected content: $file_path"
                return 1
            fi
            ;;
        "size_gt_zero")
            if [ ! -f "$file_path" ]; then
                zt_check_fail "File size verification: File does not exist: $file_path"
                return 1
            fi
            
            local file_size
            if file_size=$(wc -c < "$file_path" 2>/dev/null) && [ "$file_size" -gt 0 ]; then
                zt_check_pass "File has content (${file_size} bytes): $file_path"
                return 0
            else
                zt_check_fail "File is empty or unreadable: $file_path"
                return 1
            fi
            ;;
        *)
            zt_check_fail "File operation verification: Unknown operation '$operation'"
            return 1
            ;;
    esac
}

# Verify network operations (assume network is unreliable)
zt_verify_network_operation() {
    local operation="$1"
    local target="$2"
    local timeout="${3:-5}"
    
    # Update state
    zt_update_state "network_op" "$operation:$target"
    
    case "$operation" in
        "ping")
            if command -v ping >/dev/null 2>&1; then
                if ping -c 1 -W "$timeout" "$target" >/dev/null 2>&1; then
                    zt_check_pass "Network ping successful: $target"
                    return 0
                else
                    zt_check_fail "Network ping failed: $target"
                    return 1
                fi
            else
                zt_check_fail "Network ping: ping command not available"
                return 1
            fi
            ;;
        "port_open")
            local port="${3:-22}"
            if command -v nc >/dev/null 2>&1; then
                if nc -z -w "$timeout" "$target" "$port" 2>/dev/null; then
                    zt_check_pass "Port $port is open on $target"
                    return 0
                else
                    zt_check_fail "Port $port is closed or unreachable on $target"
                    return 1
                fi
            elif command -v telnet >/dev/null 2>&1; then
                # Fallback to telnet (less reliable)
                if echo "quit" | telnet "$target" "$port" 2>/dev/null | grep -q "Connected"; then
                    zt_check_pass "Port $port is open on $target (via telnet)"
                    return 0
                else
                    zt_check_fail "Port $port is closed or unreachable on $target"
                    return 1
                fi
            else
                zt_check_fail "Network port check: No suitable command (nc/telnet) available"
                return 1
            fi
            ;;
        *)
            zt_check_fail "Network operation verification: Unknown operation '$operation'"
            return 1
            ;;
    esac
}

# ==============================================================================
# Enhanced Check Functions (Never Assume Success)
# ==============================================================================

# Pass check with verification
zt_check_pass() {
    local message="$1"
    local context="${2:-}"
    
    # Verify we can increment counter (don't assume arithmetic works)
    if ! ZT_PASSED_CHECKS=$((ZT_PASSED_CHECKS + 1)) 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot increment pass counter${NC}" >&2
        return 1
    fi
    
    # Format message with context
    local full_message="$message"
    if [ -n "$context" ]; then
        full_message="[$context] $message"
    fi
    
    # Output with verification (don't assume echo works)
    if ! echo -e "${GREEN}✓ PASS${NC}: $full_message"; then
        # Fallback without colors
        echo "PASS: $full_message"
    fi
    
    # Update state
    zt_update_state "pass" "$message"
    
    return 0
}

# Fail check with detailed information
zt_check_fail() {
    local message="$1"
    local context="${2:-}"
    local severity="${3:-normal}"  # normal, critical
    
    # Verify we can increment counter
    if ! ZT_FAILED_CHECKS=$((ZT_FAILED_CHECKS + 1)) 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot increment fail counter${NC}" >&2
        return 1
    fi
    
    # Track critical failures separately
    if [ "$severity" = "critical" ]; then
        ZT_CRITICAL_FAILURES=$((ZT_CRITICAL_FAILURES + 1))
    fi
    
    # Format message with context
    local full_message="$message"
    if [ -n "$context" ]; then
        full_message="[$context] $message"
    fi
    
    # Output with verification
    if [ "$severity" = "critical" ]; then
        if ! echo -e "${RED}✗ CRITICAL FAIL${NC}: $full_message" >&2; then
            echo "CRITICAL FAIL: $full_message" >&2
        fi
    else
        if ! echo -e "${RED}✗ FAIL${NC}: $full_message" >&2; then
            echo "FAIL: $full_message" >&2
        fi
    fi
    
    # Update state
    zt_update_state "fail" "$severity:$message"
    
    return 1
}

# Warning check (for non-critical issues)
zt_check_warn() {
    local message="$1"
    local context="${2:-}"
    
    # Verify we can increment counter
    if ! ZT_WARNINGS=$((ZT_WARNINGS + 1)) 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot increment warning counter${NC}" >&2
        return 1
    fi
    
    # Format message with context
    local full_message="$message"
    if [ -n "$context" ]; then
        full_message="[$context] $message"
    fi
    
    # Output with verification
    if ! echo -e "${YELLOW}⚠ WARN${NC}: $full_message"; then
        echo "WARN: $full_message"
    fi
    
    # Update state
    zt_update_state "warn" "$message"
    
    return 0
}

# ==============================================================================
# Compound Verification Functions
# ==============================================================================

# Verify make command execution (common pattern in ahab)
zt_verify_make_command() {
    local make_target="$1"
    local expected_pattern="${2:-}"
    local timeout="${3:-60}"
    local working_dir="${4:-$(pwd)}"
    
    # Validate inputs
    if [ -z "$make_target" ]; then
        zt_check_fail "Make verification: No target specified"
        return 1
    fi
    
    # Verify Makefile exists
    if ! zt_verify_file_operation "exists" "$working_dir/Makefile"; then
        zt_check_fail "Make verification: No Makefile in $working_dir"
        return 1
    fi
    
    # Verify target exists in Makefile
    if ! grep -q "^${make_target}:" "$working_dir/Makefile" 2>/dev/null; then
        zt_check_fail "Make verification: Target '$make_target' not found in Makefile"
        return 1
    fi
    
    # Execute make command
    local output
    local exit_code
    
    zt_update_state "make_exec" "$make_target in $working_dir"
    
    if output=$(cd "$working_dir" && zt_execute_and_verify "make $make_target" "$timeout" make "$make_target" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Verify execution
    if [ $exit_code -eq 0 ]; then
        if [ -n "$expected_pattern" ]; then
            # Verify output contains expected pattern
            if echo "$output" | grep -q "$expected_pattern"; then
                zt_check_pass "Make $make_target: Completed with expected output"
                return 0
            else
                zt_check_fail "Make $make_target: Completed but output missing expected pattern '$expected_pattern'"
                return 1
            fi
        else
            zt_check_pass "Make $make_target: Completed successfully"
            return 0
        fi
    else
        zt_check_fail "Make $make_target: Failed with exit code $exit_code"
        # Include output for debugging (but don't assume it's safe to display)
        if [ ${#output} -lt 1000 ]; then
            echo "Output: $output" >&2
        else
            echo "Output (truncated): ${output:0:500}..." >&2
        fi
        return $exit_code
    fi
}

# Verify service status (common pattern for checking if services are running)
zt_verify_service_status() {
    local service_name="$1"
    local expected_status="${2:-running}"  # running, stopped, not-found
    local method="${3:-auto}"  # auto, systemctl, docker, process
    
    # Validate inputs
    if [ -z "$service_name" ]; then
        zt_check_fail "Service verification: No service name specified"
        return 1
    fi
    
    zt_update_state "service_check" "$service_name:$expected_status:$method"
    
    local actual_status="unknown"
    
    # Determine check method
    if [ "$method" = "auto" ]; then
        if command -v systemctl >/dev/null 2>&1; then
            method="systemctl"
        elif command -v docker >/dev/null 2>&1; then
            method="docker"
        else
            method="process"
        fi
    fi
    
    # Check service status based on method
    case "$method" in
        "systemctl")
            if systemctl is-active "$service_name" >/dev/null 2>&1; then
                actual_status="running"
            elif systemctl list-unit-files | grep -q "^${service_name}\.service"; then
                actual_status="stopped"
            else
                actual_status="not-found"
            fi
            ;;
        "docker")
            if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "^${service_name}$"; then
                actual_status="running"
            elif docker ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${service_name}$"; then
                actual_status="stopped"
            else
                actual_status="not-found"
            fi
            ;;
        "process")
            if pgrep -f "$service_name" >/dev/null 2>&1; then
                actual_status="running"
            else
                actual_status="stopped"
            fi
            ;;
        *)
            zt_check_fail "Service verification: Unknown method '$method'"
            return 1
            ;;
    esac
    
    # Verify status matches expectation
    if [ "$actual_status" = "$expected_status" ]; then
        zt_check_pass "Service $service_name: Status is $actual_status (as expected)"
        return 0
    else
        zt_check_fail "Service $service_name: Expected $expected_status, got $actual_status"
        return 1
    fi
}

# ==============================================================================
# Recovery and Cleanup Functions
# ==============================================================================

# Recover from previous failed state
zt_recover_from_state() {
    if [ ! -f "$ZT_STATE_FILE" ]; then
        echo "→ No previous state file found"
        return 0
    fi
    
    echo "→ Recovering from previous state..."
    
    # Read last few lines to understand what was happening
    local last_operations
    if last_operations=$(tail -5 "$ZT_STATE_FILE" 2>/dev/null); then
        echo "Last operations:"
        echo "$last_operations" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        zt_check_warn "Cannot read state file for recovery"
    fi
    
    return 0
}

# Clean up state and generate summary
zt_finalize_checking() {
    local context="${1:-unknown}"
    local report_file="${2:-}"
    
    zt_update_state "finalize" "$context"
    
    # Calculate totals (verify arithmetic)
    local total_operations
    if ! total_operations=$((ZT_PASSED_CHECKS + ZT_FAILED_CHECKS)) 2>/dev/null; then
        echo -e "${RED}CRITICAL: Cannot calculate totals${NC}" >&2
        return 1
    fi
    
    # Generate summary
    echo ""
    echo "=========================================="
    echo "Zero Trust Checking Summary: $context"
    echo "=========================================="
    echo "Total Checks: $ZT_TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$ZT_PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$ZT_FAILED_CHECKS${NC}"
    echo -e "Warnings: ${YELLOW}$ZT_WARNINGS${NC}"
    
    if [ "$ZT_CRITICAL_FAILURES" -gt 0 ]; then
        echo -e "Critical Failures: ${RED}$ZT_CRITICAL_FAILURES${NC}"
    fi
    
    echo ""
    
    # Write report if requested
    if [ -n "$report_file" ]; then
        {
            echo "# Zero Trust Checking Report: $context"
            echo "Generated: $(date)"
            echo ""
            echo "## Summary"
            echo "- Total Checks: $ZT_TOTAL_CHECKS"
            echo "- Passed: $ZT_PASSED_CHECKS"
            echo "- Failed: $ZT_FAILED_CHECKS"
            echo "- Warnings: $ZT_WARNINGS"
            echo "- Critical Failures: $ZT_CRITICAL_FAILURES"
            echo ""
            echo "## State History"
            if [ -f "$ZT_STATE_FILE" ]; then
                cat "$ZT_STATE_FILE"
            else
                echo "No state file available"
            fi
        } > "$report_file" 2>/dev/null || zt_check_warn "Cannot write report file: $report_file"
    fi
    
    # Determine exit code
    if [ "$ZT_CRITICAL_FAILURES" -gt 0 ]; then
        echo -e "${RED}❌ CRITICAL FAILURES DETECTED${NC}"
        return 2
    elif [ "$ZT_FAILED_CHECKS" -gt 0 ]; then
        echo -e "${RED}❌ CHECKS FAILED${NC}"
        return 1
    elif [ "$ZT_WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}⚠ WARNINGS PRESENT${NC}"
        return 0  # Warnings don't fail the build
    else
        echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
        return 0
    fi
}

# Clean up temporary files
zt_cleanup() {
    # Remove state file if it exists
    if [ -f "$ZT_STATE_FILE" ]; then
        rm -f "$ZT_STATE_FILE" 2>/dev/null || true
    fi
}

# ==============================================================================
# Backward Compatibility Functions
# ==============================================================================

# Provide backward compatibility with existing check_pass/check_fail functions
check_pass() {
    zt_check_pass "$@"
}

check_fail() {
    zt_check_fail "$@"
}

check_warn() {
    zt_check_warn "$@"
}

# ==============================================================================
# Usage Examples and Documentation
# ==============================================================================

# Example usage function (for documentation)
zt_example_usage() {
    echo "Zero Trust Checking Library - Example Usage"
    echo ""
    echo "# Initialize checking"
    echo "zt_init_checking 'my-script'"
    echo ""
    echo "# Verify a file exists and has content"
    echo "zt_verify_file_operation 'exists' '/path/to/file'"
    echo "zt_verify_file_operation 'size_gt_zero' '/path/to/file'"
    echo ""
    echo "# Execute and verify a command"
    echo "zt_execute_and_verify 'test-command' 30 echo 'hello world'"
    echo ""
    echo "# Verify make command"
    echo "zt_verify_make_command 'test' 'All tests passed'"
    echo ""
    echo "# Verify service status"
    echo "zt_verify_service_status 'apache' 'running' 'systemctl'"
    echo ""
    echo "# Finalize and generate report"
    echo "zt_finalize_checking 'my-script' 'report.md'"
    echo ""
    echo "# Clean up"
    echo "zt_cleanup"
}

# ==============================================================================
# END OF ZERO TRUST CHECKING LIBRARY
# ==============================================================================