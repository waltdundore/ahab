#!/usr/bin/env bash
# ==============================================================================
# Duplicate Code Detection Check
# ==============================================================================
# Identifies duplicate code blocks across files
# 
# Requirements: 4.1
# Property: 14 - Duplicate code detection
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

# Minimum lines to consider as duplicate (avoid flagging trivial duplicates)
MIN_DUPLICATE_LINES=5

print_section "Duplicate Code Detection Check"
print_info "Checking for duplicate code blocks in: $CHECK_PATH"
print_info "Minimum duplicate size: $MIN_DUPLICATE_LINES lines"
echo ""

# Create temporary directory for analysis
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Find all shell scripts and extract function definitions
print_info "Analyzing shell scripts..."
while IFS= read -r -d '' script; do
    increment_check
    
    # Extract functions from script
    awk '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/,/^}/' "$script" > "$TMP_DIR/$(basename "$script").functions" 2>/dev/null || true
done < <(find "$CHECK_PATH" -name "*.sh" -type f -print0 2>/dev/null)

# Find all Python files and extract function definitions
print_info "Analyzing Python files..."
while IFS= read -r -d '' pyfile; do
    increment_check
    
    # Extract functions from Python file
    awk '/^def [a-zA-Z_][a-zA-Z0-9_]*\(/,/^[^ \t]/' "$pyfile" > "$TMP_DIR/$(basename "$pyfile").functions" 2>/dev/null || true
done < <(find "$CHECK_PATH" -name "*.py" -type f -print0 2>/dev/null)

# Compare extracted functions for duplicates
# This is a simplified check - a full solution would use AST comparison
print_info "Comparing code blocks for duplicates..."

# Use a simple hash-based approach
declare -A code_hashes
declare -A code_locations

for func_file in "$TMP_DIR"/*.functions; do
    if [ ! -s "$func_file" ]; then
        continue
    fi
    
    # Calculate hash of function content
    hash=$(md5sum "$func_file" | awk '{print $1}')
    
    if [ -n "${code_hashes[$hash]:-}" ]; then
        # Duplicate found
        original="${code_locations[$hash]}"
        duplicate="$(basename "$func_file" .functions)"
        
        print_warning "Potential duplicate code found"
        echo "  Original: $original"
        echo "  Duplicate: $duplicate"
        echo "  Consider: Extract common code into shared library"
        echo "  Location: scripts/lib/common.sh"
        echo ""
        increment_warning
    else
        code_hashes[$hash]=1
        code_locations[$hash]="$(basename "$func_file" .functions)"
    fi
done

# Check for common anti-patterns that indicate duplication
print_info "Checking for common duplication patterns..."

# Look for repeated error handling patterns
if grep -r "echo.*ERROR\|print.*error" "$CHECK_PATH" --include="*.sh" --include="*.py" | wc -l | awk '{if ($1 > 10) exit 0; else exit 1}'; then
    print_warning "Multiple error handling implementations found"
    echo "  Consider: Use common error handling functions from scripts/lib/common.sh"
    echo "  Functions available: print_error, die, require_file, require_command"
    echo ""
    increment_warning
fi

# Look for repeated color definitions
if grep -r "RED=\|GREEN=\|YELLOW=" "$CHECK_PATH" --include="*.sh" | wc -l | awk '{if ($1 > 1) exit 0; else exit 1}'; then
    print_warning "Multiple color definitions found"
    echo "  Consider: Source colors from scripts/lib/common.sh"
    echo "  Colors available: RED, GREEN, YELLOW, BLUE, NC"
    echo ""
    increment_warning
fi

# Print summary
print_summary "Duplicate Code Detection Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No significant code duplication detected"
fi

exit $exit_code
