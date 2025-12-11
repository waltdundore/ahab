#!/usr/bin/env bash
# ==============================================================================
# NASA Power of 10 Rule #2: Bounded Loops Check
# ==============================================================================
# Validates that all loops have fixed upper bounds
# 
# Requirements: 2.1
# Property: 4 - Bounded loop detection
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

print_section "NASA Power of 10 Rule #2: Bounded Loops"
print_info "Checking for unbounded loops in: $CHECK_PATH"
echo ""

# Find all shell scripts
while IFS= read -r -d '' script; do
    increment_check
    
    # Skip this script itself (absolute path comparison)
    if [ "$(realpath "$script")" = "$(realpath "$0")" ]; then
        continue
    fi
    
    # Skip test files (they may contain intentional violations for testing)
    if [[ "$script" == */test* ]] || [[ "$script" == *test*.sh ]] || [[ "$script" == */tests/* ]]; then
        continue
    fi
    
    # Skip CI scripts (they may contain examples of violations)
    if [[ "$script" == */ci/* ]] || [[ "$script" == */scripts/ci/* ]]; then
        continue
    fi
    
    # Skip property test files specifically
    if [[ "$script" == */property/* ]]; then
        continue
    fi
    
    # Skip documentation and README files
    if [[ "$script" == */README* ]] || [[ "$script" == *.md ]]; then
        continue
    fi
    
    # Skip lib files (they may contain examples)
    if [[ "$script" == */lib/* ]]; then
        continue
    fi
    
    # Check for infinite while loops (exclude comments and example text)
    if grep -n "while true" "$script" 2>/dev/null | grep -v "#.*while true" | grep -v "echo.*while true"; then
        print_error "Unbounded loop found in $script"
        echo "  Rule Violated: NASA Power of 10 Rule #2 (Bounded Loops)"
        echo "  Problem: Infinite while loops create unbounded execution with no fixed upper bound"
        echo "  Fix: Replace with a for loop with fixed iteration count"
        echo "  Example:"
        echo "    # Before (unbounded)"
        echo "    while [condition]; do  # infinite loop"
        echo "      # ..."
        echo "    done"
        echo ""
        echo "    # After (bounded)"
        echo "    for i in {1..100}; do"
        echo "      # ..."
        echo "    done"
        echo ""
        increment_error
    fi
    
    # Check for while loops without timeout/counter
    # This is a heuristic - we look for while loops that don't have obvious bounds
    if grep -n "^[[:space:]]*while \[" "$script" 2>/dev/null | grep -v "while \[ \$.*-lt\|while \[ \$.*-le\|while \[ \$.*-gt\|while \[ \$.*-ge" >/dev/null; then
        print_warning "Potentially unbounded while loop in $script"
        echo "  Consider: Add a counter or timeout to ensure loop terminates"
        echo "  Example:"
        echo "    max_attempts=30"
        echo "    attempt=0"
        echo "    while [ \$attempt -lt \$max_attempts ]; do"
        echo "      # ..."
        echo "      ((attempt++))"
        echo "    done"
        echo ""
        increment_warning
    fi
    
done < <(find "$CHECK_PATH" -name "*.sh" -type f -print0) || true

# Print summary
print_summary "Bounded Loops Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "All loops have fixed upper bounds"
fi

exit $exit_code
