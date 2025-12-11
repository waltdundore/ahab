#!/usr/bin/env bash
# ==============================================================================
# Fix Duplicate Colors - Simple Version
# ==============================================================================
# Replaces duplicate color definitions with shared library imports
# Follows NASA Rule #4: Functions ≤ 60 lines
# ==============================================================================

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/automation.sh"

# Parse arguments
check_force_flag "$@"

print_section "Fixing Duplicate Color Definitions"

# Simple approach: just update the most problematic files
fix_test_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Skip if already fixed
    if grep -q "source.*colors\.sh" "$file"; then
        print_success "Already fixed: $file"
        return 0
    fi
    
    print_info "Fixing: $file"
    
    # Simple sed replacement
    sed -i.bak '
        /^RED=.*033.*31m/d
        /^GREEN=.*033.*32m/d
        /^YELLOW=.*033.*33m/d
        /^BLUE=.*033.*34m/d
        /^NC=.*033.*0m/d
        /^# Colors$/a\
# Source shared colors\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
source "$SCRIPT_DIR/../lib/colors.sh"
    ' "$file"
    
    # Verify fix worked
    if grep -q "source.*colors\.sh" "$file"; then
        rm "$file.bak"
        print_success "Fixed: $file"
        return 0
    else
        mv "$file.bak" "$file"
        print_error "Fix failed: $file"
        return 1
    fi
}

# Main execution
main() {
    local files=(
        "tests/workstation/test-environment.sh"
        "tests/workstation/test-docker.sh"
        "tests/integration/test-apache-simple.sh"
    )
    
    local fixed=0
    local failed=0
    
    for file in "${files[@]}"; do
        if fix_test_file "$file"; then
            ((fixed++))
        else
            ((failed++))
        fi
    done
    
    print_section "Summary"
    echo "Fixed: $fixed, Failed: $failed"
    
    if [ $failed -eq 0 ]; then
        print_success "All color duplications fixed"
        return 0
    else
        print_error "$failed files failed to fix"
        return 1
    fi
}

# Show usage if help requested
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    echo "Usage: $(basename "$0") [--force]"
    echo "Fix duplicate color definitions in test scripts"
    exit 0
fi

main "$@"