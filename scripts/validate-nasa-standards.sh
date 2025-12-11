#!/usr/bin/env bash
# ==============================================================================
# NASA Power of 10 Standards Validation
# ==============================================================================
# Validates code compliance with NASA Power of 10 rules for safety-critical systems
# Used by: GitHub Actions, make test-nasa, CI/CD pipeline
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/nasa-validation.sh"

# ==============================================================================
# Configuration
# ==============================================================================

# NASA Power of 10 Rules
readonly NASA_RULES=(
    "Rule #1: Simple control flow (no goto, setjmp, longjmp)"
    "Rule #2: Bounded loops (all loops have fixed upper bounds)"
    "Rule #3: No dynamic memory allocation after initialization"
    "Rule #4: Functions ≤ 60 lines (printable on single page)"
    "Rule #5: Assertion density ≥ 2 per function"
    "Rule #6: Restricted scope (data objects at smallest scope)"
    "Rule #7: Return value checking (all function returns checked)"
    "Rule #8: Preprocessor use limited (no macros with side effects)"
    "Rule #9: Pointer use restricted (no function pointers)"
    "Rule #10: Compiler warnings enabled (all warnings treated as errors)"
)

# File patterns to check
readonly SHELL_PATTERNS="*.sh"
readonly PYTHON_PATTERNS="*.py"

# Violation counters
TOTAL_VIOLATIONS=0
TOTAL_FILES_CHECKED=0

# ==============================================================================
# Main Validation Logic
# ==============================================================================

validate_all_files() {
    # Find and validate shell scripts
    print_info "Validating shell scripts..."
    while IFS= read -r -d '' file; do
        validate_nasa_file "$file"
        local file_violations=$?
        TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + file_violations))
        TOTAL_FILES_CHECKED=$((TOTAL_FILES_CHECKED + 1))
    done < <(find . -name "$SHELL_PATTERNS" -type f -print0 2>/dev/null)
    
    # Find and validate Python scripts
    print_info "Validating Python scripts..."
    while IFS= read -r -d '' file; do
        validate_nasa_file "$file"
        local file_violations=$?
        TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + file_violations))
        TOTAL_FILES_CHECKED=$((TOTAL_FILES_CHECKED + 1))
    done < <(find . -name "$PYTHON_PATTERNS" -type f -print0 2>/dev/null)
}

show_summary() {
    echo ""
    print_section "NASA Validation Summary"
    print_info "Files checked: $TOTAL_FILES_CHECKED"
    
    if [ $TOTAL_VIOLATIONS -eq 0 ]; then
        print_success "✅ All files pass NASA Power of 10 standards"
        print_success "Ready for safety-critical deployment"
        return 0
    else
        print_error "❌ $TOTAL_VIOLATIONS NASA rule violations found"
        print_error "Fix violations before deployment"
        echo ""
        print_info "Most common fixes:"
        echo "  - Break long functions into smaller ones (≤ 60 lines)"
        echo "  - Add timeout protection to loops"
        echo "  - Check return values of all function calls"
        echo "  - Use 'set -euo pipefail' for error handling"
        return 1
    fi
}

main() {
    print_section "NASA Power of 10 Standards Validation"
    
    echo "Validating compliance with NASA Power of 10 rules for safety-critical systems"
    echo ""
    
    # Print rules being checked
    print_info "Rules being validated:"
    for rule in "${NASA_RULES[@]}"; do
        echo "  - $rule"
    done
    echo ""
    
    validate_all_files
    show_summary
}

# ==============================================================================
# Script Execution
# ==============================================================================

# Validate we're in the right directory
if [ ! -f "Makefile" ]; then
    print_error "Must be run from ahab directory (where Makefile exists)"
    exit 1
fi

# Run main validation
main "$@"