#!/usr/bin/env bash
# ==============================================================================
# NASA Power of 10 Rule #3: Return Value Checking
# ==============================================================================
# Validates that all function return values are checked
# 
# Requirements: 2.2
# Property: 5 - Return value checking detection
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

print_section "NASA Power of 10 Rule #3: Return Value Checking"
print_info "Checking for unchecked return values in: $CHECK_PATH"
echo ""

# Find all shell scripts
while IFS= read -r -d '' script; do
    increment_check
    
    # Skip this script itself
    if [ "$script" = "$0" ]; then
        continue
    fi
    
    # Check for command execution without checking return value
    # Look for commands that should have their return values checked
    
    # Check for make commands without checking return value
    if grep -n "^[[:space:]]*make " "$script" 2>/dev/null | grep -v "if.*make\|make.*&&\|make.*||\||| true" >/dev/null; then
        print_warning "Unchecked 'make' command in $script"
        grep -n "^[[:space:]]*make " "$script" | grep -v "if.*make\|make.*&&\|make.*||\||| true" | head -3
        echo "  Consider: Check return value with 'if make ...' or 'make ... || handle_error'"
        echo ""
        increment_warning
    fi
    
    # Check for git commands without checking return value
    if grep -n "^[[:space:]]*git " "$script" 2>/dev/null | grep -v "if.*git\|git.*&&\|git.*||\||| true" >/dev/null; then
        print_warning "Unchecked 'git' command in $script"
        grep -n "^[[:space:]]*git " "$script" | grep -v "if.*git\|git.*&&\|git.*||\||| true" | head -3
        echo "  Consider: Check return value with 'if git ...' or 'git ... || handle_error'"
        echo ""
        increment_warning
    fi
    
    # Check for function calls without checking return value
    # This is harder to detect reliably, so we focus on common patterns
    if grep -n "^[[:space:]]*[a-z_][a-z0-9_]*[[:space:]]*$" "$script" 2>/dev/null | grep -v "^[[:space:]]*#" >/dev/null; then
        # This might be a function call without checking return value
        # But it's hard to distinguish from variable assignments, so we just warn
        print_info "Potential unchecked function calls in $script (manual review recommended)"
    fi
    
done < <(find "$CHECK_PATH" -name "*.sh" -type f -print0)

# Print summary
print_summary "Return Value Checking"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "Return value checking looks good"
fi

exit $exit_code
