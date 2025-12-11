#!/usr/bin/env bash
# ==============================================================================
# Update Technical Debt Tracking
# ==============================================================================
# Updates TECHNICAL_DEBT.md with current function length violations
#
# Usage:
#   ./update-technical-debt.sh
#
# This script:
# 1. Reads current violations from .function-length-violations
# 2. Updates TECHNICAL_DEBT.md with current status
# 3. Provides refactoring recommendations
# ==============================================================================

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VIOLATIONS_LOG="$PROJECT_ROOT/.function-length-violations"
TECHNICAL_DEBT_FILE="$PROJECT_ROOT/TECHNICAL_DEBT.md"

print_header() {
    echo "=============================================="
    echo "Technical Debt Tracking Update"
    echo "=============================================="
    echo ""
}

# Count violations in log file
count_violations() {
    if [ ! -f "$VIOLATIONS_LOG" ]; then
        echo "0"
        return
    fi
    
    grep -c "NEEDS_REFACTORING\|FUNCTION_VIOLATIONS" "$VIOLATIONS_LOG" 2>/dev/null || echo "0"
}

# Determine priority based on file characteristics
get_refactoring_priority() {
    local file="$1"
    local lines="$2"
    
    if [[ "$file" == *"audit"* || "$file" == *"security"* ]]; then
        echo "HIGH"
    elif [ "$lines" -gt 400 ]; then
        echo "HIGH"
    elif [ "$lines" -gt 300 ]; then
        echo "MEDIUM"
    else
        echo "LOW"
    fi
}

# Get target date for refactoring
get_target_date() {
    if command -v gdate >/dev/null 2>&1; then
        gdate -d "+5 days" '+%Y-%m-%d'
    else
        date -v+5d '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d'
    fi
}

# Generate violations table
generate_violations_table() {
    local temp_file="$1"
    
    {
        echo "| Script | Lines | Priority | Refactoring Plan | Target Date |"
        echo "|--------|-------|----------|------------------|-------------|"
        
        while IFS='|' read -r timestamp file lines status; do
            # Skip comment lines and empty lines
            [[ "$timestamp" =~ ^#.*$ ]] && continue
            [[ -z "$timestamp" ]] && continue
            
            # Clean up whitespace
            file=$(echo "$file" | xargs)
            lines=$(echo "$lines" | xargs)
            status=$(echo "$status" | xargs)
            
            # Skip if any field is empty
            [[ -z "$file" || -z "$lines" || -z "$status" ]] && continue
            
            if [[ "$status" == "NEEDS_REFACTORING" || "$status" == "FUNCTION_VIOLATIONS" ]]; then
                local priority
                priority=$(get_refactoring_priority "$file" "$lines")
                local plan="Extract functions to lib/ directory"
                local target_date
                target_date=$(get_target_date)
                
                echo "| \`$file\` | $lines | $priority | $plan | $target_date |"
            fi
        done < "$VIOLATIONS_LOG"
    } > "$temp_file"
}

update_technical_debt_file() {
    print_info "Updating TECHNICAL_DEBT.md with current violations..."
    
    if [ ! -f "$VIOLATIONS_LOG" ]; then
        print_info "No violations log found - no updates needed"
        return 0
    fi
    
    local violations_count
    violations_count=$(count_violations)
    
    if [ "$violations_count" -eq 0 ]; then
        print_success "No function length violations found"
        return 0
    fi
    
    print_info "Found $violations_count files needing refactoring"
    
    # Create updated violations table
    local temp_file
    temp_file=$(mktemp)
    
    generate_violations_table "$temp_file"
    
    # Update the technical debt file
    if [ -f "$TECHNICAL_DEBT_FILE" ]; then
        # Simple approach: replace everything between the table header and next section
        {
            # Print everything up to and including the table header
            sed -n '1,/^| Script | Lines | Priority/p' "$TECHNICAL_DEBT_FILE"
            
            # Print the separator line
            echo "|--------|-------|----------|------------------|-------------|"
            
            # Print the new table content
            cat "$temp_file"
            
            # Print everything after the table (skip existing table rows)
            sed -n '/^| Script | Lines | Priority/,/^### /{ /^### /p; }; /^### /,$p' "$TECHNICAL_DEBT_FILE" | sed '1d'
        } > "${TECHNICAL_DEBT_FILE}.tmp" && mv "${TECHNICAL_DEBT_FILE}.tmp" "$TECHNICAL_DEBT_FILE"
    else
        print_warning "TECHNICAL_DEBT.md not found - creating new file"
        cat > "$TECHNICAL_DEBT_FILE" << EOF
# Technical Debt Tracking

**Last Updated**: $(date '+%Y-%m-%d')

## Function Length Violations (NASA Rule #4)

$(cat "$temp_file")

## Notes

- Files over 200 lines should be refactored into smaller functions
- Functions over 60 lines violate NASA Power of 10 Rule #4
- Priority based on file importance and size
- Target dates are suggestions for completion

EOF
    fi
    
    rm -f "$temp_file"
    
    print_success "Updated TECHNICAL_DEBT.md with $violations_count violations"
}

generate_refactoring_recommendations() {
    print_info "Generating refactoring recommendations..."
    
    if [ ! -f "$VIOLATIONS_LOG" ]; then
        return 0
    fi
    
    echo ""
    echo "REFACTORING RECOMMENDATIONS"
    echo "=========================="
    echo ""
    
    while IFS='|' read -r timestamp file lines status; do
        file=$(echo "$file" | xargs)
        lines=$(echo "$lines" | xargs)
        status=$(echo "$status" | xargs)
        
        if [[ "$status" == "NEEDS_REFACTORING" || "$status" == "FUNCTION_VIOLATIONS" ]]; then
            echo "File: $file ($lines lines)"
            echo "  Recommendation: Extract functions to scripts/lib/"
            echo "  Benefits: Reusable functions, easier testing, better maintainability"
            echo "  Steps:"
            echo "    1. Identify logical function groups"
            echo "    2. Create lib/$(basename "$file" .sh)-lib.sh"
            echo "    3. Extract functions (keep each ≤ 60 lines)"
            echo "    4. Update main script to source library"
            echo "    5. Test that functionality is preserved"
            echo ""
        fi
    done < "$VIOLATIONS_LOG"
}

print_summary() {
    echo "=============================================="
    echo "Summary"
    echo "=============================================="
    echo ""
    
    if [ -f "$VIOLATIONS_LOG" ]; then
        local total_violations
        total_violations=$(grep -c "NEEDS_REFACTORING\|FUNCTION_VIOLATIONS" "$VIOLATIONS_LOG" 2>/dev/null || echo "0")
        
        if [ "$total_violations" -gt 0 ]; then
            echo "Technical debt items tracked: $total_violations"
            echo "Updated: $TECHNICAL_DEBT_FILE"
            echo ""
            echo "Next steps:"
            echo "1. Review TECHNICAL_DEBT.md for refactoring plans"
            echo "2. Prioritize HIGH priority items first"
            echo "3. Create library functions for reusable code"
            echo "4. Test thoroughly after refactoring"
        else
            echo "No technical debt items found - all functions within limits"
        fi
    else
        echo "No violations log found - run function length validation first"
    fi
    
    echo ""
}

main() {
    print_header
    
    update_technical_debt_file
    generate_refactoring_recommendations
    print_summary
}

# Run main function
main "$@"