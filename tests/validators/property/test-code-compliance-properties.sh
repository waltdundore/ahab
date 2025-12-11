#!/bin/bash
# Property-Based Tests for Code Compliance Validator
# Feature: pre-release-checklist, Property 1: Code follows Core Principles
# Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$TEST_ROOT/.." && pwd)"

# Test configuration
ITERATIONS=${ITERATIONS:-100}  # Run 100 iterations as specified in design
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
    
    # Create directory structure
    mkdir -p "$TEST_DIR/ahab/scripts"
    mkdir -p "$TEST_DIR/ahab-gui"
    mkdir -p "$TEST_DIR/scripts/validators/lib"
    
    # Copy validator and dependencies
    cp "$PROJECT_ROOT/scripts/validators/validate-code-compliance.sh" "$TEST_DIR/scripts/validators/"
    cp "$PROJECT_ROOT/scripts/validators/lib/common.sh" "$TEST_DIR/scripts/validators/lib/"
    
    # Copy colors.sh if it exists
    if [ -f "$PROJECT_ROOT/lib/colors.sh" ]; then
        mkdir -p "$TEST_DIR/lib"
        cp "$PROJECT_ROOT/lib/colors.sh" "$TEST_DIR/lib/"
    fi
}

cleanup_test_env() {
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# Code Generators - Violations
# ============================================================================

# Generate Python file with direct vagrant command
generate_python_with_vagrant() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/usr/bin/env python3
import subprocess

def deploy():
    # Direct vagrant command - VIOLATION
    subprocess.run(['vagrant', 'up'])
    subprocess.call(['vagrant', 'ssh', '-c', 'docker ps'])
    
if __name__ == '__main__':
    deploy()
EOF
}

# Generate Python file with direct ansible command
generate_python_with_ansible() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/usr/bin/env python3
import subprocess

def provision():
    # Direct ansible command - VIOLATION
    subprocess.run(['ansible-playbook', 'playbook.yml'])
    
if __name__ == '__main__':
    provision()
EOF
}

# Generate shell script with direct vagrant command
generate_shell_with_vagrant() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Deploy script

# Direct vagrant command - VIOLATION
vagrant up
vagrant ssh -c "docker ps"
EOF
    chmod +x "$file"
}

# Generate shell script with Python not in Docker
generate_shell_with_python_not_docker() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Generate script

# Python not in Docker - VIOLATION
python3 scripts/generate-compose.py apache
python3 -m pytest tests/
EOF
    chmod +x "$file"
}

# Generate shell script with cd command
generate_shell_with_cd() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Deploy script

# cd command - VIOLATION
cd ahab
make install

cd ../ahab-gui
python3 app.py
EOF
    chmod +x "$file"
}

# ============================================================================
# Code Generators - Valid Code
# ============================================================================

# Generate valid Python file using make commands
generate_valid_python() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/usr/bin/env python3
import subprocess

def deploy():
    # Valid: using make commands
    subprocess.run(['make', 'install'], cwd='ahab')
    subprocess.run(['make', 'test'], cwd='ahab')
    
if __name__ == '__main__':
    deploy()
EOF
}

# Generate valid shell script using make commands with proper path setup
generate_valid_shell() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Deploy script

# Valid: proper path setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Valid: using make commands with explicit path
cd "$PROJECT_ROOT/ahab"
make install
make test
EOF
    chmod +x "$file"
}

# Generate valid shell script with Python in Docker
generate_valid_shell_docker() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Generate script

# Valid: Python in Docker
docker run --rm -v $(pwd):/workspace -w /workspace \
    python:3.11-slim \
    sh -c "pip install pyyaml && python scripts/generate-compose.py apache"
EOF
    chmod +x "$file"
}

# Generate valid shell script with proper path setup
generate_valid_shell_paths() {
    local file="$1"
    cat > "$file" << 'EOF'
#!/bin/bash
# Setup script

# Valid: cd for SCRIPT_DIR calculation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Valid: cd to PROJECT_ROOT
cd "$PROJECT_ROOT"

# Run commands
make test
EOF
    chmod +x "$file"
}

# ============================================================================
# Property Tests
# ============================================================================

# Property 1: Code with direct vagrant commands should fail validation
test_property_direct_vagrant_fails() {
    report_test_info "Testing Property 1a: Direct vagrant commands should fail"
    report_test_info "Running $ITERATIONS iterations..."
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        setup_test_env
        
        # Generate random violation type
        local violation_type=$((RANDOM % 3))
        local test_file=""
        
        case $violation_type in
            0)
                # Python with vagrant
                test_file="$TEST_DIR/ahab-gui/deploy.py"
                generate_python_with_vagrant "$test_file"
                ;;
            1)
                # Shell with vagrant
                test_file="$TEST_DIR/ahab/scripts/deploy.sh"
                generate_shell_with_vagrant "$test_file"
                ;;
            2)
                # Python with ansible
                test_file="$TEST_DIR/ahab-gui/provision.py"
                generate_python_with_ansible "$test_file"
                ;;
        esac
        
        # Run validator (should fail)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/validators/validate-code-compliance.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify validator failed
        if [ $exit_code -eq 0 ]; then
            report_test_error "Iteration $i: Validator should have failed for direct vagrant/ansible command"
            ((iteration_failures++))
        fi
        
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1a passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1a failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 2: Code with Python not in Docker should fail validation
test_property_python_not_docker_fails() {
    report_test_info "Testing Property 1b: Python not in Docker should fail"
    report_test_info "Running $ITERATIONS iterations..."
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        setup_test_env
        
        # Generate shell script with Python not in Docker
        local test_file="$TEST_DIR/ahab/scripts/generate-$i.sh"
        generate_shell_with_python_not_docker "$test_file"
        
        # Run validator (should fail)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/validators/validate-code-compliance.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify validator failed
        if [ $exit_code -eq 0 ]; then
            report_test_error "Iteration $i: Validator should have failed for Python not in Docker"
            ((iteration_failures++))
        fi
        
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1b passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1b failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 3: Code with cd commands should fail validation
test_property_cd_commands_fail() {
    report_test_info "Testing Property 1c: cd commands should fail"
    report_test_info "Running $ITERATIONS iterations..."
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        setup_test_env
        
        # Generate shell script with cd commands
        local test_file="$TEST_DIR/ahab/scripts/deploy-$i.sh"
        generate_shell_with_cd "$test_file"
        
        # Run validator (should fail)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/validators/validate-code-compliance.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify validator failed
        if [ $exit_code -eq 0 ]; then
            report_test_error "Iteration $i: Validator should have failed for cd commands"
            ((iteration_failures++))
        fi
        
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1c passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1c failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 4: Valid code should pass validation
test_property_valid_code_passes() {
    report_test_info "Testing Property 1d: Valid code should pass"
    report_test_info "Running $ITERATIONS iterations..."
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        setup_test_env
        
        # Generate random valid code type
        local code_type=$((RANDOM % 4))
        
        case $code_type in
            0)
                # Valid Python with make commands
                generate_valid_python "$TEST_DIR/ahab-gui/deploy.py"
                ;;
            1)
                # Valid shell with make commands
                generate_valid_shell "$TEST_DIR/ahab/scripts/deploy.sh"
                ;;
            2)
                # Valid shell with Python in Docker
                generate_valid_shell_docker "$TEST_DIR/ahab/scripts/generate.sh"
                ;;
            3)
                # Valid shell with proper path setup
                generate_valid_shell_paths "$TEST_DIR/ahab/scripts/setup.sh"
                ;;
        esac
        
        # Run validator (should pass)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/validators/validate-code-compliance.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify validator passed
        if [ $exit_code -ne 0 ]; then
            report_test_error "Iteration $i: Validator should have passed for valid code (type: $code_type)"
            ((iteration_failures++))
        fi
        
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1d passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1d failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# Property 5: Mixed code (valid + violations) should fail validation
test_property_mixed_code_fails() {
    report_test_info "Testing Property 1e: Mixed code (valid + violations) should fail"
    report_test_info "Running $ITERATIONS iterations..."
    
    local iteration_failures=0
    
    for i in $(seq 1 $ITERATIONS); do
        setup_test_env
        
        # Generate mix of valid and invalid code
        generate_valid_python "$TEST_DIR/ahab-gui/valid.py"
        generate_valid_shell "$TEST_DIR/ahab/scripts/valid.sh"
        
        # Add one violation
        local violation_type=$((RANDOM % 3))
        case $violation_type in
            0)
                generate_python_with_vagrant "$TEST_DIR/ahab-gui/invalid.py"
                ;;
            1)
                generate_shell_with_python_not_docker "$TEST_DIR/ahab/scripts/invalid.sh"
                ;;
            2)
                generate_shell_with_cd "$TEST_DIR/ahab/scripts/bad.sh"
                ;;
        esac
        
        # Run validator (should fail due to violation)
        cd "$TEST_DIR"
        local exit_code=0
        ./scripts/validators/validate-code-compliance.sh >/dev/null 2>&1 || exit_code=$?
        
        # Verify validator failed
        if [ $exit_code -eq 0 ]; then
            report_test_error "Iteration $i: Validator should have failed for mixed code with violations"
            ((iteration_failures++))
        fi
        
        cleanup_test_env
        
        # Progress indicator every 10 iterations
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    
    if [ $iteration_failures -eq 0 ]; then
        report_test_success "Property 1e passed: All $ITERATIONS iterations successful"
    else
        report_test_error "Property 1e failed: $iteration_failures failures in $ITERATIONS iterations"
        FAILURES=$((FAILURES + iteration_failures))
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "=========================================="
    echo "Code Compliance Validator Property Tests"
    echo "=========================================="
    echo ""
    echo "Feature: pre-release-checklist"
    echo "Property 1: Code follows Core Principles"
    echo "Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5"
    echo ""
    echo "Iterations per property: $ITERATIONS"
    echo ""
    
    # Run property tests
    test_property_direct_vagrant_fails
    echo ""
    test_property_python_not_docker_fails
    echo ""
    test_property_cd_commands_fail
    echo ""
    test_property_valid_code_passes
    echo ""
    test_property_mixed_code_fails
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
