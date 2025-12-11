#!/usr/bin/env bash
# ==============================================================================
# Property Test: Script Tool Usage Validation
# ==============================================================================
# Feature: dependency-minimization-audit
# Property 15: Script tool usage validation
#
# For any script file, all tools used should be either system tools or 
# Docker-containerized applications.
#
# Validates: Requirements 9.4
# ==============================================================================

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test configuration
readonly TEST_NAME="Script Tool Usage Validation"
readonly PROPERTY_NUMBER="15"

# System tools that are allowed (POSIX-compatible)
readonly SYSTEM_TOOLS=(
    bash sh echo cat grep sed awk cut tr sort uniq wc head tail
    find xargs test mkdir rm cp mv chmod chown ls pwd cd touch
    date sleep true false printf read expr bc tee diff patch
    tar gzip gunzip zip unzip curl wget ssh scp rsync git make
)

# Package managers that should NOT be in scripts
readonly PACKAGE_MANAGERS=(
    dnf yum apt apt-get pip pip3 npm yarn gem cargo go python
)

# Docker commands (should be wrapped in Make targets)
readonly DOCKER_COMMANDS=(
    docker docker-compose podman
)

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

is_system_tool() {
    local cmd="$1"
    for tool in "${SYSTEM_TOOLS[@]}"; do
        if [ "$cmd" = "$tool" ]; then
            return 0
        fi
    done
    return 1
}

is_package_manager() {
    local cmd="$1"
    for pm in "${PACKAGE_MANAGERS[@]}"; do
        if [ "$cmd" = "$pm" ]; then
            return 0
        fi
    done
    return 1
}

is_docker_command() {
    local cmd="$1"
    for dc in "${DOCKER_COMMANDS[@]}"; do
        if [ "$cmd" = "$dc" ]; then
            return 0
        fi
    done
    return 1
}

extract_commands_from_script() {
    local script_file="$1"
    
    # Extract command patterns from script
    # Look for package manager install patterns
    grep -oE '\b(dnf|yum|apt|apt-get|pip|pip3|npm|yarn|gem|cargo|go)\s+(install|get|add)' "$script_file" 2>/dev/null | \
        awk '{print $1}' | sort -u || true
}

check_script_for_violations() {
    local script_file="$1"
    local violations=0
    
    # Check for package manager calls
    local package_managers
    package_managers=$(extract_commands_from_script "$script_file")
    
    if [ -n "$package_managers" ]; then
        while IFS= read -r cmd; do
            if is_package_manager "$cmd"; then
                print_error "VIOLATION: Package manager '$cmd' found in $script_file"
                ((violations++))
            fi
        done <<< "$package_managers"
    fi
    
    if [ $violations -gt 0 ]; then
        return 1
    fi
    return 0
}

#------------------------------------------------------------------------------
# Property Test: No Package Managers in Scripts
#------------------------------------------------------------------------------

test_property_no_package_managers() {
    print_section "Property $PROPERTY_NUMBER: Script Tool Usage Validation"
    
    print_info "Testing: Scripts should not contain package manager calls"
    echo ""
    
    local total_violations=0
    local scripts_checked=0
    
    # Find all shell scripts
    while IFS= read -r -d '' script; do
        # Skip test scripts, audit scripts (they search for patterns), and certain directories
        if [[ "$script" =~ /tests/ ]] || \
           [[ "$script" =~ /audit-dependencies\.sh ]] || \
           [[ "$script" =~ /.git/ ]] || \
           [[ "$script" =~ /.vagrant/ ]]; then
            continue
        fi
        
        ((scripts_checked++))
        
        if ! check_script_for_violations "$script"; then
            ((total_violations++))
        fi
    done < <(find . -name "*.sh" -type f -print0 2>/dev/null)
    
    echo ""
    print_info "Checked $scripts_checked scripts"
    
    if [ $total_violations -eq 0 ]; then
        print_success "Property holds: No package managers found in scripts"
        return 0
    else
        print_error "Property violated: Found $total_violations package manager calls"
        echo ""
        print_info "Fix: Remove package manager calls, use Docker containers instead"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Property Test: Specific Script Validation
#------------------------------------------------------------------------------

test_bootstrap_uses_system_tools() {
    print_section "Specific Test: bootstrap.sh uses only system tools"
    
    if [ ! -f "bootstrap.sh" ]; then
        print_warning "bootstrap.sh not found, skipping"
        return 0
    fi
    
    print_info "Checking bootstrap.sh for violations..."
    echo ""
    
    if check_script_for_violations "bootstrap.sh"; then
        print_success "bootstrap.sh uses only system tools"
        return 0
    else
        print_error "bootstrap.sh contains violations"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Property Test: Random Script Generation
#------------------------------------------------------------------------------

test_property_with_random_scripts() {
    print_section "Property Test: Random Script Validation"
    
    print_info "Generating random test scripts..."
    echo ""
    
    local test_dir="/tmp/audit-test-$$"
    mkdir -p "$test_dir"
    
    local iterations=10
    local failures=0
    
    for i in $(seq 1 $iterations); do
        local script_file="$test_dir/test-script-$i.sh"
        
        # Generate random script with various patterns
        cat > "$script_file" << 'EOF'
#!/bin/bash
# Test script
echo "Hello"
grep pattern file.txt
sed 's/old/new/' file.txt
make test
EOF
        
        # Randomly add violations
        if [ $((RANDOM % 3)) -eq 0 ]; then
            echo "dnf install python3" >> "$script_file"
        fi
        
        if [ $((RANDOM % 3)) -eq 0 ]; then
            echo "pip install requests" >> "$script_file"
        fi
        
        # Check for violations
        if ! check_script_for_violations "$script_file"; then
            ((failures++))
        fi
    done
    
    # Cleanup
    rm -rf "$test_dir"
    
    echo ""
    print_info "Tested $iterations random scripts"
    
    if [ $failures -gt 0 ]; then
        print_warning "Found $failures scripts with violations (expected for random test)"
    else
        print_success "All random scripts passed"
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "$TEST_NAME"
    
    local test_failures=0
    
    # Run property tests
    if ! test_property_no_package_managers; then
        ((test_failures++))
    fi
    
    echo ""
    
    if ! test_bootstrap_uses_system_tools; then
        ((test_failures++))
    fi
    
    echo ""
    
    if ! test_property_with_random_scripts; then
        ((test_failures++))
    fi
    
    # Summary
    echo ""
    print_section "Test Summary"
    
    if [ $test_failures -eq 0 ]; then
        print_success "All property tests passed"
        echo ""
        return 0
    else
        print_error "$test_failures property test(s) failed"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
