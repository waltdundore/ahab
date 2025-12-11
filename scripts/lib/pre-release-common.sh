#!/bin/bash
# ==============================================================================
# Pre-Release Common Functions
# ==============================================================================
# Shared functions for pre-release validation
# ==============================================================================

# ==============================================================================
# Validator Functions
# ==============================================================================

run_nasa_standards_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "NASA STANDARDS VALIDATION"
    
    if ./scripts/validate-nasa-standards.sh; then
        print_success "NASA standards validation passed"
        return 0
    else
        print_error "NASA standards validation failed"
        return 1
    fi
}

run_documentation_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "DOCUMENTATION VALIDATION"
    
    local errors=0
    
    # Check for required documentation files
    local required_docs=(
        "README.md"
        "DEVELOPMENT_RULES.md"
        "TROUBLESHOOTING.md"
    )
    
    for doc in "${required_docs[@]}"; do
        if [ ! -f "$doc" ]; then
            print_error "Missing required documentation: $doc"
            ((errors++))
        else
            print_success "Found: $doc"
        fi
    done
    
    return $errors
}

run_code_compliance_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "CODE COMPLIANCE VALIDATION"
    
    local errors=0
    
    # Run shellcheck on all scripts
    print_info "Running shellcheck validation..."
    if ! find scripts/ -name "*.sh" -exec shellcheck {} \;; then
        print_error "Shellcheck validation failed"
        ((errors++))
    else
        print_success "Shellcheck validation passed"
    fi
    
    # Check for proper shebang lines
    print_info "Checking shebang lines..."
    local bad_shebangs=0
    while IFS= read -r -d '' script; do
        if ! head -1 "$script" | grep -q "^#!/"; then
            print_error "Missing shebang in: $script"
            ((bad_shebangs++))
        fi
    done < <(find scripts/ -name "*.sh" -print0)
    
    if [ $bad_shebangs -eq 0 ]; then
        print_success "All scripts have proper shebangs"
    else
        print_error "$bad_shebangs scripts missing shebangs"
        ((errors++))
    fi
    
    return $errors
}

run_security_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "SECURITY VALIDATION"
    
    local errors=0
    
    # Check for hardcoded secrets
    print_info "Scanning for hardcoded secrets..."
    if ./scripts/ci/scan-secrets.sh >/dev/null 2>&1; then
        print_success "No hardcoded secrets found"
    else
        print_error "Hardcoded secrets detected"
        ((errors++))
    fi
    
    # Check for root containers
    print_info "Checking for root containers..."
    if ./scripts/ci/check-container-users.sh >/dev/null 2>&1; then
        print_success "No root containers found"
    else
        print_error "Root containers detected"
        ((errors++))
    fi
    
    return $errors
}

run_dependencies_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "DEPENDENCIES VALIDATION"
    
    local errors=0
    
    # Check for required tools
    local required_tools=(
        "ansible"
        "vagrant"
        "docker"
        "shellcheck"
        "yq"
    )
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "Found: $tool"
        else
            print_warning "Missing optional tool: $tool"
            if [ "$strict_mode" = "true" ]; then
                ((errors++))
            fi
        fi
    done
    
    return $errors
}

run_integration_validator() {
    local strict_mode="$1"
    local fix_mode="$2"
    
    print_section "INTEGRATION VALIDATION"
    
    local errors=0
    
    # Test make targets
    print_info "Testing make targets..."
    local make_targets=("help" "test" "clean")
    
    for target in "${make_targets[@]}"; do
        if make -n "$target" >/dev/null 2>&1; then
            print_success "Make target '$target' is valid"
        else
            print_error "Make target '$target' is invalid"
            ((errors++))
        fi
    done
    
    return $errors
}

# ==============================================================================
# Report Generation
# ==============================================================================

generate_text_report() {
    local results_file="$1"
    local output_file="$2"
    
    {
        echo "=========================================="
        echo "PRE-RELEASE VALIDATION REPORT"
        echo "=========================================="
        echo "Generated: $(date)"
        echo ""
        
        # Read results and format
        while IFS=: read -r validator status message; do
            case "$status" in
                "PASS")
                    echo "✓ $validator: PASSED"
                    ;;
                "FAIL")
                    echo "✗ $validator: FAILED - $message"
                    ;;
                "WARN")
                    echo "⚠ $validator: WARNING - $message"
                    ;;
            esac
        done < "$results_file"
        
        echo ""
        echo "=========================================="
    } > "$output_file"
}

generate_json_report() {
    local results_file="$1"
    local output_file="$2"
    
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"results\": ["
        
        local first=true
        while IFS=: read -r validator status message; do
            if [ "$first" = "true" ]; then
                first=false
            else
                echo ","
            fi
            
            echo -n "    {"
            echo -n "\"validator\": \"$validator\", "
            echo -n "\"status\": \"$status\""
            if [ -n "$message" ]; then
                echo -n ", \"message\": \"$message\""
            fi
            echo -n "}"
        done < "$results_file"
        
        echo ""
        echo "  ]"
        echo "}"
    } > "$output_file"
}

# ==============================================================================
# Parallel Execution
# ==============================================================================

run_validators_parallel() {
    local validators=("$@")
    local strict_mode="$1"
    local fix_mode="$2"
    shift 2
    
    local pids=()
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Start all validators in background
    for validator in "${validators[@]}"; do
        {
            case "$validator" in
                "nasa-standards")
                    run_nasa_standards_validator "$strict_mode" "$fix_mode"
                    ;;
                "documentation")
                    run_documentation_validator "$strict_mode" "$fix_mode"
                    ;;
                "code-compliance")
                    run_code_compliance_validator "$strict_mode" "$fix_mode"
                    ;;
                "security")
                    run_security_validator "$strict_mode" "$fix_mode"
                    ;;
                "dependencies")
                    run_dependencies_validator "$strict_mode" "$fix_mode"
                    ;;
                "integration")
                    run_integration_validator "$strict_mode" "$fix_mode"
                    ;;
            esac
            echo $? > "$temp_dir/$validator.result"
        } &
        pids+=($!)
    done
    
    # Wait for all to complete
    local overall_result=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            overall_result=1
        fi
    done
    
    # Collect results
    for validator in "${validators[@]}"; do
        local result
        result=$(cat "$temp_dir/$validator.result")
        if [ "$result" -eq 0 ]; then
            echo "$validator:PASS:" >> "$temp_dir/results"
        else
            echo "$validator:FAIL:Validation failed" >> "$temp_dir/results"
            overall_result=1
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    return $overall_result
}

# ==============================================================================
# Summary Functions
# ==============================================================================

print_validation_summary() {
    local total_validators="$1"
    local passed_validators="$2"
    local failed_validators="$3"
    
    print_header "VALIDATION SUMMARY"
    
    echo "Total validators: $total_validators"
    echo "Passed: $passed_validators"
    echo "Failed: $failed_validators"
    echo ""
    
    if [ "$failed_validators" -eq 0 ]; then
        print_success "All validations passed - ready for release!"
        return 0
    else
        print_error "$failed_validators validation(s) failed - not ready for release"
        return 1
    fi
}