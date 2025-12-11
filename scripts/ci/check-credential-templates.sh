#!/usr/bin/env bash
# ==============================================================================
# Credential File Naming Check
# ==============================================================================
# Validates that credential files use .template or .example suffix
# 
# Requirements: 3.3
# Property: 11 - Credential file naming
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

print_section "Credential File Naming Check"
print_info "Checking for improperly named credential files in: $CHECK_PATH"
echo ""

# Patterns that indicate credential files
CREDENTIAL_PATTERNS=(
    "*password*"
    "*passwd*"
    "*secret*"
    "*credential*"
    "*cred*"
    "*key*"
    "*token*"
    "*api*"
    "*.env"
    "*config*.yml"
    "*config*.yaml"
)

# Find files matching credential patterns
for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        increment_check
        
        # Skip if file is already a template or example
        if [[ "$file" == *.template ]] || [[ "$file" == *.example ]]; then
            continue
        fi
        
        # Skip if in .git directory
        if [[ "$file" == */.git/* ]]; then
            continue
        fi
        
        # Check if file contains credential-like content
        if [ -f "$file" ]; then
            # Look for patterns that suggest credentials
            if grep -qi "password\|secret\|api_key\|token\|credential" "$file" 2>/dev/null; then
                # Check if it's actually a credential file (not documentation)
                if ! grep -qi "example\|sample\|template\|placeholder" "$file" 2>/dev/null; then
                    print_error "Credential file without proper suffix: $file"
                    echo "  Rule Violated: Security Best Practice (Credential File Naming)"
                    echo "  Problem: File appears to contain credentials but doesn't use .template or .example suffix"
                    echo "  Fix: Rename file to include .template or .example suffix"
                    echo "  Example:"
                    echo "    # Before"
                    echo "    config.yml"
                    echo ""
                    echo "    # After"
                    echo "    config.yml.template"
                    echo ""
                    echo "  Then add the actual config file to .gitignore:"
                    echo "    echo 'config.yml' >> .gitignore"
                    echo ""
                    increment_error
                fi
            fi
        fi
    done < <(find "$CHECK_PATH" -name "$pattern" -type f -print0 2>/dev/null)
done

# Check for common credential file names without proper suffix
COMMON_CRED_FILES=(
    ".env"
    "secrets.yml"
    "secrets.yaml"
    "credentials.yml"
    "credentials.yaml"
    "api-keys.yml"
    "api-keys.yaml"
)

for cred_file in "${COMMON_CRED_FILES[@]}"; do
    if [ -f "$CHECK_PATH/$cred_file" ]; then
        increment_check
        print_error "Credential file found: $CHECK_PATH/$cred_file"
        echo "  Rule Violated: Security Best Practice (Credential File Naming)"
        echo "  Problem: Common credential file name without .template or .example suffix"
        echo "  Fix: Rename to $cred_file.template or $cred_file.example"
        echo ""
        increment_error
    fi
done

# Print summary
print_summary "Credential File Naming Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "All credential files use proper naming conventions"
fi

exit $exit_code
