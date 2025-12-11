#!/bin/bash
# Pre-Release Checklist Validator: Code Compliance
# Purpose: Verify all code follows Core Principles from DEVELOPMENT_RULES.md
#
# Checks:
# - No direct vagrant/ansible commands (must use make)
# - Python execution in Docker containers
# - No cd commands in bash scripts
# - Proper use of path parameters
# - Tests run on workstation VM
#
# Requirements: 1.1, 1.2, 1.3, 1.4, 1.5

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Project root
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ============================================================================
# Validation Functions
# ============================================================================

# Check for direct vagrant/ansible commands
# Requirement 1.1: No direct vagrant/ansible commands (use make)
validate_no_direct_vagrant_ansible() {
    print_section "Checking for direct vagrant/ansible commands"
    
    local errors=0
    local checked=0
    
    # Check Python files for direct vagrant usage
    while IFS= read -r file; do
        ((checked++))
        
        # Skip test files and example files
        if [[ "$file" =~ /tests/ ]] || [[ "$file" =~ \.example ]]; then
            continue
        fi
        
        # Check for subprocess calls to vagrant
        if grep -n "subprocess\.\(run\|call\|Popen\).*['\"]vagrant" "$file" 2>/dev/null | grep -v "make "; then
            report_error "Direct vagrant command in $file"
            echo "  Use make commands instead (e.g., 'make install' not 'vagrant up')"
            ((errors++))
        fi
        
        # Check for subprocess calls to ansible
        if grep -n "subprocess\.\(run\|call\|Popen\).*['\"]ansible" "$file" 2>/dev/null | grep -v "make "; then
            report_error "Direct ansible command in $file"
            echo "  Use make commands instead"
            ((errors++))
        fi
    done < <(find_python_files)
    
    # Check shell scripts for direct vagrant usage
    while IFS= read -r file; do
        ((checked++))
        
        # Skip test files, example files, and the validators themselves
        if [[ "$file" =~ /tests/ ]] || [[ "$file" =~ \.example ]] || [[ "$file" =~ /validators/ ]]; then
            continue
        fi
        
        # Check for direct vagrant commands (not in comments)
        if grep -n "^\s*vagrant\s\+\(up\|ssh\|halt\|destroy\|reload\)" "$file" 2>/dev/null | grep -v "^[[:space:]]*#"; then
            report_error "Direct vagrant command in $file"
            echo "  Use make commands instead (e.g., 'make install' not 'vagrant up')"
            ((errors++))
        fi
        
        # Check for direct ansible-playbook commands
        if grep -n "^\s*ansible-playbook" "$file" 2>/dev/null | grep -v "^[[:space:]]*#"; then
            report_error "Direct ansible-playbook command in $file"
            echo "  Use make commands instead"
            ((errors++))
        fi
    done < <(find_shell_scripts)
    
    if [ $errors -eq 0 ]; then
        report_success "No direct vagrant/ansible commands found ($checked files checked)"
    fi
    
    return $errors
}

# Check for Python execution in Docker
# Requirement 1.2: All Python execution occurs in Docker containers
validate_python_in_docker() {
    print_section "Checking Python execution in Docker"
    
    local errors=0
    local checked=0
    
    # Check shell scripts for Python execution
    while IFS= read -r file; do
        ((checked++))
        
        # Skip test files and validators
        if [[ "$file" =~ /tests/ ]] || [[ "$file" =~ /validators/ ]]; then
            continue
        fi
        
        # Look for python3 commands not in docker context
        # This is a heuristic check - we look for python3 without docker nearby
        local line_num=0
        while IFS= read -r line; do
            ((line_num++))
            
            # Skip comments
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Check for python3 execution
            if echo "$line" | grep -q "python3\s"; then
                # Check if this line or nearby lines mention docker
                local context_start=$((line_num - 2))
                local context_end=$((line_num + 2))
                [ $context_start -lt 1 ] && context_start=1
                
                local context
                context=$(sed -n "${context_start},${context_end}p" "$file")
                
                if ! echo "$context" | grep -q "docker"; then
                    report_error "Python execution not in Docker: $file:$line_num"
                    echo "  Line: $line"
                    echo "  Use: docker run --rm -v \$(pwd):/workspace python:3.11-slim python script.py"
                    ((errors++))
                fi
            fi
        done < "$file"
    done < <(find_shell_scripts)
    
    if [ $errors -eq 0 ]; then
        report_success "Python execution properly containerized ($checked files checked)"
    fi
    
    return $errors
}

# Check for cd commands in bash scripts
# Requirement 1.3: No cd commands (use path parameters)
validate_no_cd_commands() {
    print_section "Checking for cd commands in bash scripts"
    
    local errors=0
    local checked=0
    
    while IFS= read -r file; do
        ((checked++))
        
        # Skip test files and validators
        if [[ "$file" =~ /tests/ ]] || [[ "$file" =~ /validators/ ]]; then
            continue
        fi
        
        # Look for cd commands (not in comments)
        local line_num=0
        while IFS= read -r line; do
            ((line_num++))
            
            # Skip comments
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Check for cd commands
            # Allow: cd "$(dirname ...)" for SCRIPT_DIR calculation
            # Allow: cd "$SCRIPT_DIR" or cd "$PROJECT_ROOT" for path setup
            # Disallow: cd to change working directory for commands
            if echo "$line" | grep -q "^\s*cd\s" && \
               ! echo "$line" | grep -q 'cd.*dirname.*BASH_SOURCE' && \
               ! echo "$line" | grep -q 'cd.*SCRIPT_DIR' && \
               ! echo "$line" | grep -q 'cd.*PROJECT_ROOT'; then
                report_error "cd command found: $file:$line_num"
                echo "  Line: $line"
                echo "  Use path parameter in executeBash or controlBashProcess instead"
                ((errors++))
            fi
        done < "$file"
    done < <(find_shell_scripts)
    
    if [ $errors -eq 0 ]; then
        report_success "No problematic cd commands found ($checked files checked)"
    fi
    
    return $errors
}

# Check for proper path parameters
# Requirement 1.4: Proper use of path parameters
validate_path_parameters() {
    print_section "Checking for proper path parameter usage"
    
    local errors=0
    local checked=0
    
    # Check Python files for subprocess calls with path parameter
    while IFS= read -r file; do
        ((checked++))
        
        # Skip test files
        if [[ "$file" =~ /tests/ ]]; then
            continue
        fi
        
        # Look for subprocess calls that might need cwd parameter
        local line_num=0
        local in_subprocess=false
        local has_cwd=false
        local subprocess_start=0
        
        while IFS= read -r line; do
            ((line_num++))
            
            # Check if we're starting a subprocess call
            if echo "$line" | grep -q "subprocess\.\(run\|call\|Popen\)"; then
                in_subprocess=true
                subprocess_start=$line_num
                has_cwd=false
            fi
            
            # Check if this subprocess call has cwd parameter
            if [ "$in_subprocess" = true ] && echo "$line" | grep -q "cwd="; then
                has_cwd=true
            fi
            
            # Check if subprocess call is complete
            if [ "$in_subprocess" = true ] && echo "$line" | grep -q ")"; then
                # If subprocess calls make or other commands, it should have cwd
                local context
                context=$(sed -n "${subprocess_start},${line_num}p" "$file")
                
                if echo "$context" | grep -q "'make'" && [ "$has_cwd" = false ]; then
                    report_warning "subprocess call without cwd parameter: $file:$subprocess_start"
                    echo "  Consider adding cwd parameter for make commands"
                fi
                
                in_subprocess=false
            fi
        done < "$file"
    done < <(find_python_files)
    
    if [ $errors -eq 0 ]; then
        report_success "Path parameter usage looks good ($checked files checked)"
    fi
    
    return $errors
}

# Check for tests on workstation VM
# Requirement 1.5: Tests execute on workstation VM
validate_tests_on_workstation() {
    print_section "Checking tests run on workstation VM"
    
    local errors=0
    local checked=0
    
    # Check test scripts for proper execution context
    while IFS= read -r file; do
        # Only check files in tests directory
        if [[ ! "$file" =~ /tests/ ]]; then
            continue
        fi
        
        ((checked++))
        
        # Skip property tests and unit tests (these can run on host)
        if [[ "$file" =~ /property/ ]] || [[ "$file" =~ /unit/ ]]; then
            continue
        fi
        
        # Integration tests should use vagrant ssh or make ssh
        if [[ "$file" =~ /integration/ ]] || [[ "$file" =~ test-.*\.sh ]]; then
            # Check if test uses vagrant ssh or make ssh
            if ! grep -q "vagrant ssh\|make ssh" "$file" 2>/dev/null; then
                report_warning "Integration test may not run on workstation: $file"
                echo "  Integration tests should execute via 'vagrant ssh' or 'make ssh'"
            fi
        fi
    done < <(find_shell_scripts)
    
    if [ $errors -eq 0 ]; then
        report_success "Test execution context looks good ($checked files checked)"
    fi
    
    return $errors
}

# ============================================================================
# Main Validation
# ============================================================================

main() {
    print_header "Code Compliance Validator"
    
    cd "$PROJECT_ROOT" || exit 1
    
    local total_errors=0
    
    # Run all validation checks
    validate_no_direct_vagrant_ansible || ((total_errors+=$?))
    validate_python_in_docker || ((total_errors+=$?))
    validate_no_cd_commands || ((total_errors+=$?))
    validate_path_parameters || ((total_errors+=$?))
    validate_tests_on_workstation || ((total_errors+=$?))
    
    # Print summary
    print_summary "Code Compliance"
    
    # Return appropriate exit code
    if [ $total_errors -gt 0 ]; then
        return 1
    else
        report_success "All code compliance checks passed"
        return 0
    fi
}

# Run main function
main "$@"
