#!/usr/bin/env bash
# ==============================================================================
# NASA Validation Library
# ==============================================================================
# Shared functions for NASA Power of 10 standards validation
# Used by: validate-nasa-standards.sh, CI/CD pipeline
# ==============================================================================

# ==============================================================================
# NASA Rule Validation Functions
# ==============================================================================

# Rule #1: Simple control flow (no goto, setjmp, longjmp)
validate_nasa_rule_1() {
    local file="$1"
    local violations=0
    
    # Skip the NASA validation script itself (contains these keywords in comments)
    if [[ "$file" == *"validate-nasa-standards.sh" ]]; then
        return 0
    fi
    
    # Check for goto statements (exclude comments and strings)
    if grep -n "goto\|setjmp\|longjmp" "$file" 2>/dev/null | grep -v "#.*goto\|#.*setjmp\|#.*longjmp" | grep -v "echo.*goto\|echo.*setjmp\|echo.*longjmp" >/dev/null; then
        print_error "Rule #1 violation in $file: goto/setjmp/longjmp found"
        violations=$((violations + 1))
    fi
    
    return $violations
}

# Rule #2: Bounded loops (all loops have fixed upper bounds)
validate_nasa_rule_2() {
    local file="$1"
    local violations=0
    
    # Skip validation for test files that intentionally create bad code
    if [[ "$file" == *"test-bounded-loop-detection.sh" ]]; then
        return 0
    fi
    
    # Check for unbounded while loops (exclude test strings and comments)
    if grep -n "while true\|while \[\[ true \]\]\|while \[ true \]" "$file" | grep -v "create_test_file\|#.*while true" >/dev/null 2>&1; then
        print_error "Rule #2 violation in $file: unbounded while loop found"
        grep -n "while true\|while \[\[ true \]\]\|while \[ true \]" "$file" | grep -v "create_test_file\|#.*while true" | head -3
        violations=$((violations + 1))
    fi
    
    # Check for loops without timeout protection
    if grep -n "while.*;" "$file" | grep -v "timeout\|sleep.*[0-9]\|create_test_file" >/dev/null 2>&1; then
        local loop_count
        loop_count=$(grep -c "while.*;" "$file" | grep -v "timeout\|sleep.*[0-9]\|create_test_file" || echo "0")
        if [ "$loop_count" -gt 0 ]; then
            print_warning "Rule #2 advisory in $file: $loop_count loops without timeout protection"
        fi
    fi
    
    return $violations
}

# Rule #4: Functions ≤ 60 lines (most critical for our codebase)
validate_nasa_rule_4() {
    local file="$1"
    local violations=0
    
    if [[ "$file" == *.sh ]]; then
        # Shell function validation
        while IFS= read -r line; do
            local func_name line_num func_length
            func_name=$(echo "$line" | cut -d: -f3)
            line_num=$(echo "$line" | cut -d: -f1)
            func_length=$(echo "$line" | cut -d: -f2)
            
            if [ "$func_length" -gt 60 ]; then
                print_error "Rule #4 violation in $file:$line_num: function '$func_name' is $func_length lines (max: 60)"
                violations=$((violations + 1))
            fi
        done < <(get_shell_function_lengths "$file")
    fi
    
    return $violations
}

# Rule #7: Return value checking (all function returns checked)
validate_nasa_rule_7() {
    local file="$1"
    local violations=0
    
    # Check for unchecked command executions
    if grep -n "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(" "$file" | grep -v "if\|&&\|\|\|;" >/dev/null 2>&1; then
        local unchecked_count
        unchecked_count=$(grep -c "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*(" "$file" | grep -v "if\|&&\|\|\|;" || echo "0")
        if [ "$unchecked_count" -gt 0 ]; then
            print_warning "Rule #7 advisory in $file: $unchecked_count potentially unchecked function calls"
        fi
    fi
    
    return $violations
}

# Get function lengths for shell scripts
get_shell_function_lengths() {
    local file="$1"
    
    # Extract function definitions and calculate lengths
    awk '
    /^[[:space:]]*function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)|^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)/ {
        if (in_function) {
            print line_start ":" (NR - line_start) ":" func_name
        }
        func_name = $0
        gsub(/^[[:space:]]*function[[:space:]]+/, "", func_name)
        gsub(/^[[:space:]]*/, "", func_name)
        gsub(/[[:space:]]*\(\).*$/, "", func_name)
        line_start = NR
        in_function = 1
        brace_count = 0
        next
    }
    in_function && /\{/ {
        brace_count += gsub(/\{/, "&")
    }
    in_function && /\}/ {
        brace_count -= gsub(/\}/, "&")
        if (brace_count <= 0) {
            print line_start ":" (NR - line_start + 1) ":" func_name
            in_function = 0
        }
    }
    END {
        if (in_function) {
            print line_start ":" (NR - line_start + 1) ":" func_name
        }
    }
    ' "$file"
}

# Validate single file against all applicable NASA rules
validate_nasa_file() {
    local file="$1"
    local file_violations=0
    
    print_info "Checking: $file"
    
    # Rule #1: Simple control flow
    validate_nasa_rule_1 "$file"
    file_violations=$((file_violations + $?))
    
    # Rule #2: Bounded loops
    validate_nasa_rule_2 "$file"
    file_violations=$((file_violations + $?))
    
    # Rule #4: Function length (most important)
    validate_nasa_rule_4 "$file"
    file_violations=$((file_violations + $?))
    
    # Rule #7: Return value checking
    validate_nasa_rule_7 "$file"
    file_violations=$((file_violations + $?))
    
    if [ $file_violations -eq 0 ]; then
        print_success "✓ $file: NASA compliant"
    else
        print_error "✗ $file: $file_violations violations"
    fi
    
    return $file_violations
}