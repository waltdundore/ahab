#!/bin/bash
# Property-Based Tests for Pre-Release Orchestrator
# Feature: pre-release-checklist, Property 1: Orchestrator executes all validators
# Validates: Requirements 1.1

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$TEST_ROOT/.." && pwd)"

# Test configuration
ITERATIONS=${ITERATIONS:-10}  # Default to 10 for faster testing, can be overridden
FAILURES=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# Test Utilities
# ============================================================================

report_test_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILURES++))
}

report_test_success() {
    echo -e "${GREEN}✓${NC} $1"
}

report_test_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# ============================================================================
# Test Setup
# ============================================================================

setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
    
    # Create minimal validator structure
    mkdir -p "$TEST_DIR/scripts/validators/lib"
    
    # Copy common.sh
    cp "$PROJECT_ROOT/scripts/validators/lib/common.sh" "$TEST_DIR/scripts/validators/lib/"
    
    # Copy orchestrator
    cp "$PROJECT_ROOT/scripts/pre-release-check.sh" "$TEST_DIR/scripts/"
}

cleanup_test_env() {
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# Validator Generators
# ============================================================================

# Generate a validator that always passes
generate_passing_validator() {
    local name="$1"
    local script="$TEST_DIR/scripts/validators/validate-${name}.sh"
    
    cat > "$script" << 'EOF'
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
report_success "Validator passed"
exit 0
EOF
    
    chmod +x "$script"
}

# Generate a validator that always fails
generate_failing_validator() {
    local name="$1"
    local script="$TEST_DIR/scripts/validators/validate-${name}.sh"
    
    cat > "$script" << 'EOF'
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
report_error "Validator failed"
exit 1
EOF
    
    chmod +x "$script"
}

# Generate a random validator (pass or fail)
generate_random_validator() {
    local name="$1"
    local random=$((RANDOM % 2))
    
    if [ $random -eq 0 ]; then
        generate_passing_validator "$name"
    else
        generate_failing_validator "$name"
    fi
}

# ============================================================================
# Property Tests
# ============================================================================

# Property 1: Orchestrator executes all validators
# For any list of validators, the orchestrator should execute each one and collect results
test_property_orchestrator_executes_all_validators() {
    report_test_info "Testing Property 1: Orchestrator executes all validators"
    report_test_info "Running $ITERATIONS iterations..."
    
    # Known validator names from orchestrator
    local known_validators=("code-compliance" "documentation" "file-organization" "gitignore" "tests")
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        # Setup test environment
        setup_test_env
        
        # Generate random subset of validators (1-3)
        local num_validators=$((RANDOM % 3 + 1))
        local validator_names=()
        
        # Shuffle and select validators
        local shuffled=("${known_validators[@]}")
        for j in $(seq 1 $num_validators); do
            local idx=$((RANDOM % ${#shuffled[@]}))
            validator_names+=("${shuffled[$idx]}")
            # Remove selected validator
            unset 'shuffled[idx]'
            shuffled=("${shuffled[@]}")
        done
        
        # Generate validators
        for validator_name in "${validator_names[@]}"; do
            generate_passing_validator "$validator_name"
        done
        
        # Run orchestrator
        cd "$TEST_DIR"
        local output
        output=$(./scripts/pre-release-check.sh 2>&1 || true)
        
        # Verify each validator was executed
        local all_executed=true
        for validator_name in "${validator_names[@]}"; do
            if ! echo "$output" | grep -q "Running: $validator_name"; then
                report_test_error "Iteration $i: Validator $validator_name was not executed"
                ((iteration_failures++))
                all_executed=false
                break
            fi
        done
        
        if [ "$all_executed" = true ]; then
            # Verify report was generated
            if [ ! -f "pre-release-report.txt" ]; then
                report_test_error "Iteration $i: Report was not generated"
                ((iteration_failures++))
            fi
        fi
        
        # Cleanup
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1 passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1 failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 2: Orchestrator fails when any validator fails
# For any list of validators with at least one failure, orchestrator should exit with code 1
test_property_orchestrator_fails_on_validator_failure() {
    report_test_info "Testing Property 2: Orchestrator fails when any validator fails"
    report_test_info "Running $ITERATIONS iterations..."
    
    # Known validator names
    local known_validators=("code-compliance" "documentation" "file-organization")
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        # Setup test environment
        setup_test_env
        
        # Generate 2-3 validators with at least one failure
        local num_validators=$((RANDOM % 2 + 2))
        
        for j in $(seq 0 $((num_validators - 1))); do
            local validator_name="${known_validators[$j]}"
            if [ $j -eq 0 ]; then
                # First validator always fails
                generate_failing_validator "$validator_name"
            else
                # Others pass
                generate_passing_validator "$validator_name"
            fi
        done
        
        # Run orchestrator (should fail)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/pre-release-check.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify orchestrator failed
        if [ $exit_code -eq 0 ]; then
            report_test_error "Iteration $i: Orchestrator should have failed but passed"
            ((iteration_failures++))
        fi
        
        # Cleanup
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 2 passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 2 failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 3: Orchestrator passes when all validators pass
# For any list of validators that all pass, orchestrator should exit with code 0
test_property_orchestrator_passes_on_all_success() {
    report_test_info "Testing Property 3: Orchestrator passes when all validators pass"
    report_test_info "Running $ITERATIONS iterations..."
    
    # Known validator names
    local known_validators=("code-compliance" "documentation" "file-organization" "gitignore")
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        # Setup test environment
        setup_test_env
        
        # Generate random number of validators (1-4)
        local num_validators=$((RANDOM % 4 + 1))
        
        # Generate all passing validators
        for j in $(seq 0 $((num_validators - 1))); do
            local validator_name="${known_validators[$j]}"
            generate_passing_validator "$validator_name"
        done
        
        # Run orchestrator (should pass)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/pre-release-check.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify orchestrator passed
        if [ $exit_code -ne 0 ]; then
            report_test_error "Iteration $i: Orchestrator should have passed but failed (exit code: $exit_code)"
            ((iteration_failures++))
        fi
        
        # Cleanup
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 3 passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 3 failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "=========================================="
    echo "Pre-Release Orchestrator Property Tests"
    echo "=========================================="
    echo ""
    echo "Iterations per property: $ITERATIONS"
    echo ""
    
    # Run property tests
    test_property_orchestrator_executes_all_validators
    echo ""
    test_property_orchestrator_fails_on_validator_failure
    echo ""
    test_property_orchestrator_passes_on_all_success
    echo ""
    
    # Summary
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo "Total Failures: $FAILURES"
    echo ""
    
    if [ $FAILURES -eq 0 ]; then
        echo -e "${GREEN}✓ ALL PROPERTY TESTS PASSED${NC}"
        exit 0
    else
        echo -e "${RED}✗ PROPERTY TESTS FAILED${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
