#!/usr/bin/env bash
# ==============================================================================
# Hardcoded Values Security Audit
# ==============================================================================
# Systematically identifies hardcoded values that violate security and DRY principles
#
# This script scans for:
# 1. Hardcoded usernames (waltdundore, specific users)
# 2. Hardcoded paths (/Users/username, /home/username)
# 3. Hardcoded secrets (passwords, API keys, tokens)
# 4. Hardcoded IP addresses and hostnames
# 5. Hardcoded URLs and repositories
# 6. Configuration values that should be variables
#
# Exit codes:
#   0 - No violations found
#   1 - Violations found
#   2 - Script error
# ==============================================================================

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
VIOLATIONS_FOUND=0
REPORT_FILE="hardcoded-values-audit-$(date +%Y%m%d-%H%M%S).txt"
TEMP_DIR=$(mktemp -d)

# Cleanup on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

# Colors for output (check if already defined)
if [ -z "${RED:-}" ]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
fi

print_header() {
    echo -e "${BLUE}=============================================="
    echo "Hardcoded Values Security Audit"
    echo "$(date)"
    echo -e "==============================================${NC}"
    echo ""
}

print_violation() {
    local category="$1"
    local file="$2"
    local line_num="$3"
    local content="$4"
    local severity="$5"
    local recommendation="$6"
    
    echo -e "${RED}[${severity}] ${category}${NC}"
    echo "  File: $file:$line_num"
    echo "  Content: $content"
    echo "  Fix: $recommendation"
    echo ""
    
    # Log to report file
    {
        echo "VIOLATION: $category [$severity]"
        echo "File: $file:$line_num"
        echo "Content: $content"
        echo "Recommendation: $recommendation"
        echo "---"
    } >> "$REPORT_FILE"
    
    ((VIOLATIONS_FOUND++))
}

print_summary() {
    echo -e "${BLUE}=============================================="
    echo "Audit Summary"
    echo -e "==============================================${NC}"
    
    if [ $VIOLATIONS_FOUND -eq 0 ]; then
        echo -e "${GREEN}✓ No hardcoded values found${NC}"
        echo ""
        echo "All code follows security and DRY principles."
    else
        echo -e "${RED}✗ Found $VIOLATIONS_FOUND violations${NC}"
        echo ""
        echo "Report saved to: $REPORT_FILE"
        echo ""
        echo -e "${YELLOW}Priority Actions:${NC}"
        echo "1. Replace hardcoded usernames with variables"
        echo "2. Replace hardcoded paths with relative paths"
        echo "3. Move secrets to environment variables"
        echo "4. Use configuration files for URLs and IPs"
        echo ""
        echo -e "${BLUE}See report for detailed recommendations.${NC}"
    fi
    
    echo ""
}

# Scan for hardcoded usernames
scan_hardcoded_usernames() {
    print_info "Scanning for hardcoded usernames..."
    
    local usernames=("waltdundore" "walt" "dundore")
    
    for username in "${usernames[@]}"; do
        scan_files_for_pattern "$username" "Hardcoded Username" "HIGH" \
            "Replace '$username' with \${GITHUB_USER} or similar variable"
    done
}

# Generic file scanning function
scan_files_for_pattern() {
    local pattern="$1"
    local violation_type="$2" 
    local severity="$3"
    local recommendation="$4"
    
    while IFS= read -r -d '' file; do
        scan_file_for_pattern "$file" "$pattern" "$violation_type" "$severity" "$recommendation"
    done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
}

# Scan individual file for pattern
scan_file_for_pattern() {
    local file="$1"
    local pattern="$2"
    local violation_type="$3"
    local severity="$4" 
    local recommendation="$5"
    
    # Skip binary files
    if ! file "$file" | grep -q "text\|ASCII\|UTF-8"; then
        return
    fi
    
    local line_num=1
    while IFS= read -r line; do
        if echo "$line" | grep -qi "$pattern"; then
            if should_report_line "$line" "$pattern"; then
                print_violation "$violation_type" "$file" "$line_num" \
                    "$(echo "$line" | sed 's/^[[:space:]]*//')" \
                    "$severity" "$recommendation"
            fi
        fi
        ((line_num++))
    done < "$file"
}

# Check if line should be reported (skip comments, etc.)
should_report_line() {
    local line="$1"
    local pattern="$2"
    
    # Skip comments and documentation
    if echo "$line" | grep -E "^[[:space:]]*#|^[[:space:]]*//|^[[:space:]]*\*|^[[:space:]]*-.*\[x\]" > /dev/null; then
        return 1
    fi
    
    return 0
}

# Scan for hardcoded paths
scan_hardcoded_paths() {
    print_info "Scanning for hardcoded paths..."
    
    local path_patterns=(
        "/Users/[^/]*/"
        "/home/[^/]*/"
        "/opt/[^/]*/[^/]*/"
    )
    
    for pattern in "${path_patterns[@]}"; do
        scan_files_for_regex_pattern "$pattern" "Hardcoded Path" "HIGH" \
            "Replace with relative path or environment variable"
    done
}

# Scan files for regex pattern
scan_files_for_regex_pattern() {
    local pattern="$1"
    local violation_type="$2"
    local severity="$3" 
    local recommendation="$4"
    
    while IFS= read -r -d '' file; do
        if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
            local line_num=1
            while IFS= read -r line; do
                if echo "$line" | grep -E "$pattern" > /dev/null; then
                    if should_report_line "$line" "$pattern"; then
                        print_violation "$violation_type" "$file" "$line_num" \
                            "$(echo "$line" | sed 's/^[[:space:]]*//')" \
                            "$severity" "$recommendation"
                    fi
                fi
                ((line_num++))
            done < "$file"
        fi
    done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
}

# Scan for hardcoded secrets
scan_hardcoded_secrets() {
    print_info "Scanning for hardcoded secrets..."
    
    # Patterns for secrets (excluding test files and examples)
    local secret_patterns=(
        'password[[:space:]]*=[[:space:]]*["\047][^"\047]{3,}["\047]'
        'api_key[[:space:]]*=[[:space:]]*["\047][^"\047]{10,}["\047]'
        'secret[[:space:]]*=[[:space:]]*["\047][^"\047]{8,}["\047]'
        'token[[:space:]]*=[[:space:]]*["\047][^"\047]{10,}["\047]'
        'key[[:space:]]*=[[:space:]]*["\047][a-zA-Z0-9]{16,}["\047]'
    )
    
    for pattern in "${secret_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            # Skip test files and examples
            if [[ "$file" =~ test|example|\.example|\.env\.example ]] || [[ "$file" =~ /tests/ ]]; then
                continue
            fi
            
            if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
                local line_num=1
                while IFS= read -r line; do
                    if echo "$line" | grep -iE "$pattern" > /dev/null; then
                        # Skip comments and clearly fake test values
                        if ! echo "$line" | grep -E "^[[:space:]]*#|^[[:space:]]*//|test|fake|example|dummy|placeholder" > /dev/null; then
                            print_violation \
                                "Hardcoded Secret" \
                                "$file" \
                                "$line_num" \
                                "$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/["\047][^"\047]*["\047]/***REDACTED***/')" \
                                "CRITICAL" \
                                "Move to environment variable or secure vault"
                        fi
                    fi
                    ((line_num++))
                done < "$file"
            fi
        done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
    done
}

# Scan for hardcoded IP addresses
scan_hardcoded_ips() {
    print_info "Scanning for hardcoded IP addresses..."
    
    # IP patterns (excluding localhost and common examples)
    local ip_patterns=(
        '192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
        '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        '172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}'
    )
    
    for pattern in "${ip_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
                local line_num=1
                while IFS= read -r line; do
                    if echo "$line" | grep -E "$pattern" > /dev/null; then
                        # Skip comments and documentation examples
                        if ! echo "$line" | grep -E "^[[:space:]]*#|^[[:space:]]*//|Example:|example:|NETWORK_BASE" > /dev/null; then
                            print_violation \
                                "Hardcoded IP Address" \
                                "$file" \
                                "$line_num" \
                                "$(echo "$line" | sed 's/^[[:space:]]*//')" \
                                "MEDIUM" \
                                "Replace with configuration variable or use DHCP"
                        fi
                    fi
                    ((line_num++))
                done < "$file"
            fi
        done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
    done
}

# Scan for hardcoded URLs and repositories
scan_hardcoded_urls() {
    print_info "Scanning for hardcoded URLs and repositories..."
    
    # URL patterns that should be configurable
    local url_patterns=(
        'https://github\.com/waltdundore/'
        'git@github\.com:waltdundore/'
        'https://waltdundore\.github\.io'
    )
    
    for pattern in "${url_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
                local line_num=1
                while IFS= read -r line; do
                    if echo "$line" | grep -E "$pattern" > /dev/null; then
                        # Skip comments in documentation
                        if ! echo "$line" | grep -E "^[[:space:]]*#.*URL:|^[[:space:]]*#.*Repository:" > /dev/null; then
                            print_violation \
                                "Hardcoded URL/Repository" \
                                "$file" \
                                "$line_num" \
                                "$(echo "$line" | sed 's/^[[:space:]]*//')" \
                                "MEDIUM" \
                                "Replace with \${GITHUB_USER} or \${MODULE_REPO_BASE} variable"
                        fi
                    fi
                    ((line_num++))
                done < "$file"
            fi
        done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
    done
}

# Scan for hardcoded configuration values
scan_hardcoded_config() {
    print_info "Scanning for hardcoded configuration values..."
    
    # Configuration patterns that should be variables
    local config_patterns=(
        'port[[:space:]]*=[[:space:]]*[0-9]{4,5}'
        'memory[[:space:]]*=[[:space:]]*[0-9]{4,}'
        'cpus[[:space:]]*=[[:space:]]*[0-9]+'
        'version[[:space:]]*=[[:space:]]*["\047][0-9]+\.[0-9]+["\047]'
    )
    
    for pattern in "${config_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            # Skip configuration files themselves
            if [[ "$file" =~ \.conf$|\.cfg$|\.ini$|ahab\.conf ]]; then
                continue
            fi
            
            if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
                local line_num=1
                while IFS= read -r line; do
                    if echo "$line" | grep -iE "$pattern" > /dev/null; then
                        # Skip comments and variable assignments
                        if ! echo "$line" | grep -E "^[[:space:]]*#|^[[:space:]]*//|\\\$|get_config" > /dev/null; then
                            print_violation \
                                "Hardcoded Configuration" \
                                "$file" \
                                "$line_num" \
                                "$(echo "$line" | sed 's/^[[:space:]]*//')" \
                                "LOW" \
                                "Move to ahab.conf or use get_config function"
                        fi
                    fi
                    ((line_num++))
                done < "$file"
            fi
        done < <(find . -type f -not -path "./.git/*" -not -path "./backups/*" -not -path "./.kiro/*" -print0)
    done
}

# Generate recommendations report
generate_recommendations() {
    print_info "Generating recommendations..."
    
    {
        echo "HARDCODED VALUES AUDIT RECOMMENDATIONS"
        echo "======================================"
        echo "Generated: $(date)"
        echo ""
        echo "SUMMARY"
        echo "-------"
        echo "Total violations found: $VIOLATIONS_FOUND"
        echo ""
        echo "PRIORITY FIXES"
        echo "-------------"
        echo ""
        echo "1. CRITICAL - Hardcoded Secrets"
        echo "   - Move all passwords, API keys, tokens to environment variables"
        echo "   - Use ahab-secrets repository for sensitive data"
        echo "   - Implement proper secret rotation"
        echo ""
        echo "2. HIGH - Hardcoded Usernames and Paths"
        echo "   - Replace 'waltdundore' with \${GITHUB_USER} variable"
        echo "   - Replace /Users/username paths with relative paths"
        echo "   - Use \${HOME} or \${BASE_DIR} variables"
        echo ""
        echo "3. MEDIUM - Hardcoded URLs and IPs"
        echo "   - Replace GitHub URLs with \${GITHUB_USER} variable"
        echo "   - Use \${MODULE_REPO_BASE} for repository URLs"
        echo "   - Replace hardcoded IPs with DHCP or config variables"
        echo ""
        echo "4. LOW - Hardcoded Configuration"
        echo "   - Move port numbers to ahab.conf"
        echo "   - Move resource limits to configuration"
        echo "   - Use get_config() function for all settings"
        echo ""
        echo "IMPLEMENTATION PLAN"
        echo "==================="
        echo ""
        echo "Phase 1: Security (CRITICAL/HIGH)"
        echo "- Audit all secrets and move to environment variables"
        echo "- Replace hardcoded usernames with variables"
        echo "- Fix hardcoded paths"
        echo ""
        echo "Phase 2: Configuration (MEDIUM/LOW)"
        echo "- Centralize all configuration in ahab.conf"
        echo "- Update all scripts to use get_config()"
        echo "- Replace hardcoded URLs and IPs"
        echo ""
        echo "Phase 3: Validation"
        echo "- Add pre-commit hooks to prevent new hardcoded values"
        echo "- Add CI/CD checks for hardcoded patterns"
        echo "- Regular audits with this script"
        echo ""
        echo "DETAILED VIOLATIONS"
        echo "==================="
        echo ""
    } >> "$REPORT_FILE"
}

# Main execution
main() {
    print_header
    
    # Initialize report
    echo "HARDCODED VALUES SECURITY AUDIT" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Run all scans
    scan_hardcoded_usernames
    scan_hardcoded_paths
    scan_hardcoded_secrets
    scan_hardcoded_ips
    scan_hardcoded_urls
    scan_hardcoded_config
    
    # Generate recommendations
    generate_recommendations
    
    # Print summary
    print_summary
    
    # Exit with appropriate code
    if [ $VIOLATIONS_FOUND -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"