#!/usr/bin/env bash
# ==============================================================================
# Validation Common Library
# ==============================================================================
# Shared functions for validation and pre-release check scripts
# Used by pre-release-check.sh, validate-*.sh scripts
# ==============================================================================

#------------------------------------------------------------------------------
# Validator Management
#------------------------------------------------------------------------------

# Track validation results
VALIDATOR_RESULTS=()
VALIDATOR_STATUS=()
TOTAL_ERRORS=0
TOTAL_WARNINGS=0

# Add validator result
add_validator_result() {
    local validator="$1"
    local status="$2"
    
    VALIDATOR_RESULTS+=("$validator")
    VALIDATOR_STATUS+=("$status")
    
    case "$status" in
        "FAIL") ((TOTAL_ERRORS++)) ;;
        "WARN") ((TOTAL_WARNINGS++)) ;;
    esac
}

# Run a single validator
run_validator() {
    local validator="$1"
    local validator_script="$2"
    
    # Check if validator exists
    if [ ! -f "$validator_script" ]; then
        print_warning "Validator not found: $validator (skipping)"
        add_validator_result "$validator" "SKIP"
        return 0
    fi
    
    # Check if validator is executable
    if [ ! -x "$validator_script" ]; then
        chmod +x "$validator_script"
    fi
    
    print_info "Running validator: $validator"
    
    # Run validator and capture result
    local exit_code=0
    "$validator_script" || exit_code=$?
    
    # Store results
    case $exit_code in
        0)
            add_validator_result "$validator" "PASS"
            print_success "$validator validation passed"
            ;;
        1)
            add_validator_result "$validator" "FAIL"
            print_error "$validator validation failed"
            ;;
        2)
            add_validator_result "$validator" "WARN"
            print_warning "$validator validation has warnings"
            ;;
        *)
            add_validator_result "$validator" "ERROR"
            print_error "$validator validation error (exit code: $exit_code)"
            ;;
    esac
    
    return $exit_code
}

#------------------------------------------------------------------------------
# Report Generation
#------------------------------------------------------------------------------

generate_validation_summary() {
    local total_validators=${#VALIDATOR_RESULTS[@]}
    local passed=0
    local failed=0
    local warnings=0
    local skipped=0
    
    # Count results
    for status in "${VALIDATOR_STATUS[@]}"; do
        case "$status" in
            "PASS") ((passed++)) ;;
            "FAIL") ((failed++)) ;;
            "WARN") ((warnings++)) ;;
            "SKIP") ((skipped++)) ;;
        esac
    done
    
    echo ""
    print_header "VALIDATION SUMMARY"
    
    echo "Total validators: $total_validators"
    echo -e "Passed: ${GREEN}$passed${NC}"
    echo -e "Failed: ${RED}$failed${NC}"
    echo -e "Warnings: ${YELLOW}$warnings${NC}"
    echo -e "Skipped: ${BLUE}$skipped${NC}"
    echo ""
    
    # Detailed results
    if [ $total_validators -gt 0 ]; then
        echo "Detailed Results:"
        for i in "${!VALIDATOR_RESULTS[@]}"; do
            local validator="${VALIDATOR_RESULTS[$i]}"
            local status="${VALIDATOR_STATUS[$i]}"
            
            case "$status" in
                "PASS") echo -e "  ${GREEN}✓${NC} $validator" ;;
                "FAIL") echo -e "  ${RED}✗${NC} $validator" ;;
                "WARN") echo -e "  ${YELLOW}⚠${NC} $validator" ;;
                "SKIP") echo -e "  ${BLUE}○${NC} $validator (skipped)" ;;
                *) echo -e "  ${RED}?${NC} $validator (unknown status)" ;;
            esac
        done
        echo ""
    fi
    
    # Return appropriate exit code
    if [ $failed -gt 0 ]; then
        echo -e "${RED}❌ VALIDATION FAILED${NC}"
        echo "$failed validator(s) failed"
        return 1
    elif [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠ VALIDATION COMPLETED WITH WARNINGS${NC}"
        echo "$warnings validator(s) have warnings"
        return 2
    else
        echo -e "${GREEN}✅ ALL VALIDATIONS PASSED${NC}"
        return 0
    fi
}

#------------------------------------------------------------------------------
# Configuration Management
#------------------------------------------------------------------------------

load_validation_config() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        print_info "Loading configuration from: $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
    fi
}

#------------------------------------------------------------------------------
# Validator Discovery
#------------------------------------------------------------------------------

discover_validators() {
    local validators_dir="$1"
    local validators=()
    
    if [ -d "$validators_dir" ]; then
        while IFS= read -r -d '' validator_script; do
            local validator_name
            validator_name=$(basename "$validator_script" .sh)
            validator_name=${validator_name#validate-}
            validators+=("$validator_name")
        done < <(find "$validators_dir" -name "validate-*.sh" -type f -print0 2>/dev/null)
    fi
    
    printf '%s\n' "${validators[@]}"
}

#------------------------------------------------------------------------------
# Parallel Execution Support
#------------------------------------------------------------------------------

run_validators_parallel() {
    local validators_dir="$1"
    shift
    local validators=("$@")
    
    local pids=()
    local temp_dir="/tmp/validation-$$"
    mkdir -p "$temp_dir"
    
    print_info "Running ${#validators[@]} validators in parallel..."
    
    # Start all validators
    for validator in "${validators[@]}"; do
        local validator_script="$validators_dir/validate-${validator}.sh"
        local output_file="$temp_dir/$validator.out"
        
        if [ -f "$validator_script" ]; then
            (
                echo "=== $validator ===" > "$output_file"
                "$validator_script" >> "$output_file" 2>&1
                echo $? > "$temp_dir/$validator.exit"
            ) &
            pids+=($!)
        fi
    done
    
    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Collect results
    for validator in "${validators[@]}"; do
        local output_file="$temp_dir/$validator.out"
        local exit_file="$temp_dir/$validator.exit"
        
        if [ -f "$exit_file" ]; then
            local exit_code
            exit_code=$(cat "$exit_file")
            
            # Show output
            if [ -f "$output_file" ]; then
                cat "$output_file"
            fi
            
            # Record result
            case $exit_code in
                0) add_validator_result "$validator" "PASS" ;;
                1) add_validator_result "$validator" "FAIL" ;;
                2) add_validator_result "$validator" "WARN" ;;
                *) add_validator_result "$validator" "ERROR" ;;
            esac
        else
            add_validator_result "$validator" "SKIP"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
}

#------------------------------------------------------------------------------
# Report Formatting
#------------------------------------------------------------------------------

generate_text_report() {
    local output_file="$1"
    
    {
        echo "Pre-Release Validation Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        
        generate_validation_summary
    } > "$output_file"
    
    print_success "Text report saved to: $output_file"
}

generate_json_report() {
    local output_file="$1"
    
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"total_validators\": ${#VALIDATOR_RESULTS[@]},"
        echo "  \"total_errors\": $TOTAL_ERRORS,"
        echo "  \"total_warnings\": $TOTAL_WARNINGS,"
        echo "  \"results\": ["
        
        for i in "${!VALIDATOR_RESULTS[@]}"; do
            local validator="${VALIDATOR_RESULTS[$i]}"
            local status="${VALIDATOR_STATUS[$i]}"
            local comma=""
            
            if [ $i -lt $((${#VALIDATOR_RESULTS[@]} - 1)) ]; then
                comma=","
            fi
            
            echo "    {"
            echo "      \"validator\": \"$validator\","
            echo "      \"status\": \"$status\""
            echo "    }$comma"
        done
        
        echo "  ]"
        echo "}"
    } > "$output_file"
    
    print_success "JSON report saved to: $output_file"
}