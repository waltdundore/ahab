#!/usr/bin/env bash
# ==============================================================================
# Duplicate Documentation Detection Check
# ==============================================================================
# Identifies duplicate documentation content across files
# 
# Requirements: 4.2
# Property: 15 - Duplicate documentation detection
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

print_section "Duplicate Documentation Detection Check"
print_info "Checking for duplicate documentation content in: $CHECK_PATH"
echo ""

# Create temporary directory for analysis
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Find all markdown files
print_info "Analyzing markdown files..."
declare -A section_hashes
declare -A section_locations

while IFS= read -r -d '' mdfile; do
    increment_check
    
    # Extract sections (lines between headers)
    awk '/^#+ /{section=$0; next} {if (section) print section ": " $0}' "$mdfile" > "$TMP_DIR/$(basename "$mdfile").sections" 2>/dev/null || true
    
    # Check each section for duplicates
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # Calculate hash of section content
        hash=$(echo "$line" | md5sum | awk '{print $1}')
        
        if [ -n "${section_hashes[$hash]:-}" ]; then
            # Duplicate found
            original="${section_locations[$hash]}"
            duplicate="$mdfile"
            
            if [ "$original" != "$duplicate" ]; then
                print_warning "Potential duplicate documentation found"
                echo "  Original: $original"
                echo "  Duplicate: $duplicate"
                echo "  Content: $(echo "$line" | cut -c1-80)..."
                echo "  Consider: Create single source of truth and link to it"
                echo ""
                increment_warning
            fi
        else
            section_hashes[$hash]=1
            section_locations[$hash]="$mdfile"
        fi
    done < "$TMP_DIR/$(basename "$mdfile").sections"
done < <(find "$CHECK_PATH" -name "*.md" -type f -print0 2>/dev/null)

# Check for common documentation anti-patterns
print_info "Checking for common documentation duplication patterns..."

# Look for repeated installation instructions
install_count=$(grep -r "install\|Install" "$CHECK_PATH" --include="*.md" | grep -i "docker\|ansible\|vagrant" | wc -l)
if [ "$install_count" -gt 5 ]; then
    print_warning "Multiple installation instruction sections found ($install_count occurrences)"
    echo "  Consider: Create single INSTALLATION.md and link to it from other docs"
    echo ""
    increment_warning
fi

# Look for repeated troubleshooting sections
troubleshoot_count=$(grep -r "Troubleshooting\|Common Issues\|FAQ" "$CHECK_PATH" --include="*.md" | wc -l)
if [ "$troubleshoot_count" -gt 3 ]; then
    print_warning "Multiple troubleshooting sections found ($troubleshoot_count occurrences)"
    echo "  Consider: Create single TROUBLESHOOTING.md and link to it from other docs"
    echo ""
    increment_warning
fi

# Look for repeated command examples
command_count=$(grep -r '```bash' "$CHECK_PATH" --include="*.md" | wc -l)
if [ "$command_count" -gt 20 ]; then
    print_info "Found $command_count bash code blocks"
    echo "  Consider: Ensure command examples are not duplicated across docs"
    echo "  Use references like 'See INSTALLATION.md for setup commands'"
    echo ""
fi

# Print summary
print_summary "Duplicate Documentation Detection Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No significant documentation duplication detected"
fi

exit $exit_code
