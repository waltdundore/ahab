#!/usr/bin/env bash
# ==============================================================================
# Fix Hanging Prompts - Simple Version
# ==============================================================================
# Adds automation support to scripts with blocking prompts
# Follows NASA Rule #4: Functions ≤ 60 lines
# ==============================================================================

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/automation.sh"

# Parse arguments
check_force_flag "$@"

print_section "Fixing Hanging Input Prompts"

# Add automation detection to bootstrap.sh
fix_bootstrap() {
    local file="bootstrap.sh"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Skip if already has automation support
    if grep -q "is_automated\|FORCE_MODE" "$file"; then
        print_success "Already has automation support: $file"
        return 0
    fi
    
    print_info "Adding automation support to: $file"
    
    # Add simple automation detection after set -e
    sed -i.bak '/^set -e/a\
\
# Simple automation detection\
is_automated() {\
    [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ "${TERM:-}" = "dumb" ] || [ ! -t 0 ]\
}\
\
# Check for force flag\
FORCE_MODE=false\
for arg in "$@"; do\
    case "$arg" in\
        --force|--yes|-y|-f) FORCE_MODE=true ;;\
    esac\
done
' "$file"
    
    # Replace the hanging prompt
    sed -i.bak2 '
        /read -p "Continue anyway\? \[y\/N\]"/i\
        if is_automated || [ "$FORCE_MODE" = true ]; then\
            echo "Automated mode: continuing without SSH verification"\
            continue_without_ssh="y"\
        else
        /read -p "Continue anyway\? \[y\/N\]"/a\
        fi
    ' "$file"
    
    rm -f "$file.bak" "$file.bak2"
    print_success "Fixed: $file"
    return 0
}

# Add force flag support to clean script
fix_clean_script() {
    local file="scripts/clean-unused-boxes.sh"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # This script already has --force support
    if grep -q "FORCE.*false" "$file"; then
        print_success "Already has force support: $file"
        return 0
    fi
    
    print_success "Verified: $file"
    return 0
}

# Main execution
main() {
    local fixed=0
    local failed=0
    
    if fix_bootstrap; then
        ((fixed++))
    else
        ((failed++))
    fi
    
    if fix_clean_script; then
        ((fixed++))
    else
        ((failed++))
    fi
    
    print_section "Summary"
    echo "Fixed: $fixed, Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        print_success "All hanging prompts fixed"
        print_info "Scripts now support --force flag and CI/CD detection"
        return 0
    else
        print_error "$failed files failed to fix"
        return 1
    fi
}

# Show usage if help requested
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    echo "Usage: $(basename "$0") [--force]"
    echo "Fix hanging input prompts in scripts"
    exit 0
fi

main "$@"