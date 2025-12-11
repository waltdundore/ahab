#!/usr/bin/env bash
# ==============================================================================
# Secret Scanning Check
# ==============================================================================
# Scans for hardcoded credentials, API keys, and passwords in code
# 
# Requirements: 3.1
# Property: 9 - Secret detection
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

print_section "Secret Scanning Check"
print_info "Scanning for hardcoded secrets in: $CHECK_PATH"
echo ""

# Secret patterns to detect (name|pattern pairs)
# These patterns match common secret formats
SECRET_PATTERNS=(
    "AWS_Access_Key|AKIA[0-9A-Z]{16}"
    "AWS_Secret_Key|[Aa][Ww][Ss]_[Ss][Ee][Cc][Rr][Ee][Tt]_[Aa][Cc][Cc][Ee][Ss][Ss]_[Kk][Ee][Yy][[:space:]]*=[[:space:]]*[\"'][A-Za-z0-9/+=]{40}[\"']"
    "Generic_API_Key|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][[:space:]]*[=:][[:space:]]*[\"'][A-Za-z0-9_\-]{20,}[\"']"
    "Generic_Secret|[Ss][Ee][Cc][Rr][Ee][Tt][[:space:]]*[=:][[:space:]]*[\"'][A-Za-z0-9_\-]{20,}[\"']"
    "Auth_Credential|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][[:space:]]*[=:][[:space:]]*[\"'][^\"']{8,}[\"']"
    "Private_Key_Header|BEGIN (RSA |DSA |EC )?PRIVATE KEY"
    "GitHub_Token|gh[pousr]_[A-Za-z0-9_]{36,}"
    "Generic_Token|[Tt][Oo][Kk][Ee][Nn][[:space:]]*[=:][[:space:]]*[\"'][A-Za-z0-9_\-]{20,}[\"']"
    "Slack_Token|xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[A-Za-z0-9]{24,}"
    "Stripe_Key|sk_live_[0-9a-zA-Z]{20,}"
    "Google_API_Key|AIza[0-9A-Za-z\-_]{35}"
    "Heroku_API_Key|[Hh][Ee][Rr][Oo][Kk][Uu].*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
    "MailChimp_API_Key|[0-9a-f]{32}-us[0-9]{1,2}"
    "Twilio_API_Key|SK[0-9a-fA-F]{32}"
)

# Files to exclude from scanning
EXCLUDE_PATTERNS=(
    "*.md"
    "*.txt"
    "*.log"
    "*.json.example"
    "*.yml.template"
    "*.yaml.template"
    "*.env.example"
    "*.template"
    "*.example"
    ".git/*"
    "node_modules/*"
    "__pycache__/*"
    "*.pyc"
    "vendor/*"
    "dist/*"
    "build/*"
    "tests/*"
    "test-*"
    "*test*.sh"
    "scripts/audit-self.sh"
    "scripts/ci/*"
    "docs/*"
    "*.rst"
    "CHANGELOG*"
    "*.backup"
    "*.bak"
    "*backup*"
    "*/backup/*"
    "*/backups/*"
    "config-roles/*.yml"
    "README*"
    "*SUMMARY*"
    "*COMPLETE*"
    "*PROGRESS*"
    "*ANALYSIS*"
    "*PLAN*"
    "*STATUS*"
)

# Build find exclude arguments
FIND_EXCLUDES=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    FIND_EXCLUDES+=(-not -path "*/$pattern" -not -name "$pattern")
done

# Scan for secrets
print_info "Scanning for secret patterns..."
echo ""

# Find all text files (excluding binaries and excluded patterns)
while IFS= read -r -d '' file; do
    increment_check
    
    # Skip binary files (but include PEM files which are text-based)
    if file "$file" | grep -qE "text|PEM|ASCII"; then
        # Check each secret pattern
        for pattern_entry in "${SECRET_PATTERNS[@]}"; do
            pattern_name="${pattern_entry%%|*}"
            pattern="${pattern_entry#*|}"
            
            # Search for pattern in file
            while IFS=: read -r line_num match; do
                if [ -n "$line_num" ] && [ -n "$match" ]; then
                    print_error "Secret detected: $pattern_name"
                    echo "  Location: $file:$line_num"
                    echo "  Rule Violated: Security Best Practice (No Hardcoded Secrets)"
                    echo "  Problem: Hardcoded secret found in code"
                    echo ""
                    echo "  Match preview:"
                    # Mask the actual secret value for security
                    masked_match=$(echo "$match" | sed 's/[=:][[:space:]]*["\047][^"\047]*["\047]/=***REDACTED***/g')
                    echo "    $masked_match"
                    echo ""
                    echo "  Fix:"
                    echo "    1. Remove the hardcoded secret from the file"
                    echo "    2. Store secrets in environment variables or secret management system"
                    echo "    3. Use configuration templates with .template or .example suffix"
                    echo ""
                    echo "  Example:"
                    echo "    # Bad (hardcoded)"
                    echo "    API_KEY=\"sk_live_EXAMPLE_NOT_REAL\""
                    echo ""
                    echo "    # Good (environment variable)"
                    echo "    API_KEY=\"\${API_KEY}\""
                    echo ""
                    echo "    # Good (from secret manager)"
                    echo "    API_KEY=\$(aws secretsmanager get-secret-value --secret-id my-api-key --query SecretString --output text)"
                    echo ""
                    increment_error
                fi
            done < <(grep -nE "$pattern" "$file" 2>/dev/null | grep -v "REPLACE_WITH\|EXAMPLE\|TODO\|PLACEHOLDER\|your-.*-here\|<.*>\|secret_patterns\|pattern.*=" || true)
        done
    fi
done < <(find "$CHECK_PATH" -type f "${FIND_EXCLUDES[@]}" -print0 2>/dev/null)

# Additional check for common secret file names
print_info "Checking for common secret file names..."
echo ""

COMMON_SECRET_FILES=(
    ".env"
    "secrets.yml"
    "secrets.yaml"
    "credentials.yml"
    "credentials.yaml"
    "api-keys.yml"
    "api-keys.yaml"
    ".aws/credentials"
    ".ssh/id_rsa"
    ".ssh/id_dsa"
    ".ssh/id_ecdsa"
    ".ssh/id_ed25519"
)

for secret_file in "${COMMON_SECRET_FILES[@]}"; do
    if [ -f "$CHECK_PATH/$secret_file" ]; then
        # Check if it's a template or example
        if [[ ! "$secret_file" =~ \.(template|example)$ ]]; then
            increment_check
            print_error "Secret file found: $CHECK_PATH/$secret_file"
            echo "  Rule Violated: Security Best Practice (No Secret Files in Repository)"
            echo "  Problem: Common secret file name detected"
            echo "  Fix: Remove file and add to .gitignore"
            echo ""
            echo "  Steps:"
            echo "    1. git rm --cached $secret_file"
            echo "    2. echo '$secret_file' >> .gitignore"
            echo "    3. Create ${secret_file}.template with placeholder values"
            echo ""
            increment_error
        fi
    fi
done

# Print summary
print_summary "Secret Scanning Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No hardcoded secrets detected"
fi

exit $exit_code
