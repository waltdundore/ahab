#!/usr/bin/env bash
# ==============================================================================
# NASA Power of 10 Rule #4: Function Length Limit
# ==============================================================================
# Validates that no function exceeds 60 lines of code
# 
# Requirements: 2.3
# Property: 6 - Function length validation
# ==============================================================================

set -euo pipefail

# Get script directory for sourcing common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Path to check (default to current directory)
CHECK_PATH="${1:-.}"

# Maximum function length (NASA Power of 10 Rule #4)
MAX_FUNCTION_LENGTH=60

print_section "NASA Power of 10 Rule #4: Function Length Limit"
print_info "Checking for functions exceeding $MAX_FUNCTION_LENGTH lines in: $CHECK_PATH"
echo ""

# Find all shell scripts
while IFS= read -r -d '' script; do
    increment_check
    
    # Skip this script itself
    if [ "$script" = "$0" ]; then
        continue
    fi
    
    # Extract functions and count their lines
    # This is a simplified check - it looks for function definitions and counts lines until the closing brace
    
    in_function=false
    function_name=""
    function_start_line=0
    function_line_count=0
    brace_count=0
    
    line_num=0
    while IFS= read -r line; do
        ((line_num++))
        
        # Check for function definition
        if [[ $line =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]] || \
           [[ $line =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\{ ]]; then
            # Start of function
            if [ "$in_function" = true ]; then
                # Nested function? This shouldn't happen in bash, but handle it
                print_warning "Nested function detected in $script at line $line_num"
            fi
            in_function=true
            function_name="${BASH_REMATCH[1]}"
            function_start_line=$line_num
            function_line_count=1
            brace_count=1
        elif [ "$in_function" = true ]; then
            # Count lines in function
            ((function_line_count++))
            
            # Count braces to find end of function
            open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_count=$((brace_count + open_braces - close_braces))
            
            # Check if function ended
            if [ $brace_count -eq 0 ]; then
                # Function ended
                if [ $function_line_count -gt $MAX_FUNCTION_LENGTH ]; then
                    print_error "Function '$function_name' in $script exceeds $MAX_FUNCTION_LENGTH lines"
                    echo "  Location: $script:$function_start_line"
                    echo "  Length: $function_line_count lines"
                    echo "  Rule Violated: NASA Power of 10 Rule #4 (Function Length)"
                    echo "  Problem: Function is too long and complex"
                    echo "  Fix: Break function into smaller, focused functions"
                    echo "  Example:"
                    echo "    # Before (too long)"
                    echo "    deploy_service() {"
                    echo "      # 100 lines of code..."
                    echo "    }"
                    echo ""
                    echo "    # After (refactored)"
                    echo "    deploy_service() {"
                    echo "      validate_config"
                    echo "      prepare_environment"
                    echo "      start_service"
                    echo "      verify_deployment"
                    echo "    }"
                    echo ""
                    increment_error
                fi
                
                # Reset for next function
                in_function=false
                function_name=""
                function_start_line=0
                function_line_count=0
                brace_count=0
            fi
        fi
    done < "$script"
    
done < <(find "$CHECK_PATH" -name "*.sh" -type f -print0)

# Print summary
print_summary "Function Length Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "All functions are within $MAX_FUNCTION_LENGTH line limit"
fi

exit $exit_code
