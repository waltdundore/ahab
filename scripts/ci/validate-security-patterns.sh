#!/bin/bash
# ==============================================================================
# Security Pattern Validation for CI/CD
# ==============================================================================
# Validates security patterns without false positives from documentation
# 
# Usage:
#   ./scripts/ci/validate-security-patterns.sh [directory]
#
# Exit Codes:
#   0 - All checks passed
#   1 - Security violations found
# ==============================================================================

set -euo pipefail

# Default to current directory if no argument provided
SCAN_DIR="${1:-.}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
VIOLATIONS=0

echo "=========================================="
echo "Security Pattern Validation"
echo "=========================================="
echo "Scanning directory: $SCAN_DIR"
echo ""

# ==============================================================================
# Check for shell=True in Python code (not documentation)
# ==============================================================================
check_shell_true() {
    echo "→ Checking for shell=True usage..."
    
    local found_violations=0
    
    # Find Python files and check for shell=True
    while IFS= read -r -d '' file; do
        # Skip if no Python files found
        [ -f "$file" ] || continue
        
        # Check for shell=True that's not in comments or documentation examples
        if grep -n "shell=True" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ Found shell=True in: $file${NC}"
            grep -n "shell=True" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" | head -3
            found_violations=1
        fi
    done < <(find "$SCAN_DIR" -name "*.py" -type f -print0 2>/dev/null)
    
    if [ $found_violations -eq 0 ]; then
        echo -e "  ${GREEN}✓ No shell=True violations found${NC}"
    else
        ((VIOLATIONS++))
    fi
    echo ""
}

# ==============================================================================
# Check for os.system usage in Python code
# ==============================================================================
check_os_system() {
    echo "→ Checking for os.system usage..."
    
    local found_violations=0
    
    while IFS= read -r -d '' file; do
        [ -f "$file" ] || continue
        
        if grep -n "os\.system" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ Found os.system in: $file${NC}"
            grep -n "os\.system" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" | head -3
            found_violations=1
        fi
    done < <(find "$SCAN_DIR" -name "*.py" -type f -print0 2>/dev/null)
    
    if [ $found_violations -eq 0 ]; then
        echo -e "  ${GREEN}✓ No os.system violations found${NC}"
    else
        ((VIOLATIONS++))
    fi
    echo ""
}

# ==============================================================================
# Check for eval() usage in Python code
# ==============================================================================
check_eval_usage() {
    echo "→ Checking for eval() usage..."
    
    local found_violations=0
    
    while IFS= read -r -d '' file; do
        [ -f "$file" ] || continue
        
        if grep -n "[^a-zA-Z_]eval(" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ Found eval() in: $file${NC}"
            grep -n "[^a-zA-Z_]eval(" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" | head -3
            found_violations=1
        fi
    done < <(find "$SCAN_DIR" -name "*.py" -type f -print0 2>/dev/null)
    
    if [ $found_violations -eq 0 ]; then
        echo -e "  ${GREEN}✓ No eval() violations found${NC}"
    else
        ((VIOLATIONS++))
    fi
    echo ""
}

# ==============================================================================
# Check for privileged Docker containers
# ==============================================================================
check_privileged_containers() {
    echo "→ Checking for privileged Docker containers..."
    
    local found_violations=0
    
    # Check Docker Compose files
    while IFS= read -r -d '' file; do
        [ -f "$file" ] || continue
        
        if grep -n "privileged:\s*true" "$file" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ Found privileged container in: $file${NC}"
            grep -n "privileged:\s*true" "$file"
            found_violations=1
        fi
    done < <(find "$SCAN_DIR" -name "docker-compose*.yml" -o -name "compose*.yml" -type f -print0 2>/dev/null)
    
    # Check shell scripts for --privileged flag (actual usage)
    while IFS= read -r -d '' file; do
        [ -f "$file" ] || continue
        
        if grep -n "docker run.*--privileged" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ Found --privileged flag in: $file${NC}"
            grep -n "docker run.*--privileged" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example"
            found_violations=1
        fi
    done < <(find "$SCAN_DIR" -name "*.sh" -type f -print0 2>/dev/null)
    
    if [ $found_violations -eq 0 ]; then
        echo -e "  ${GREEN}✓ No privileged containers found${NC}"
    else
        ((VIOLATIONS++))
    fi
    echo ""
}

# ==============================================================================
# Check for hardcoded secrets (basic patterns)
# ==============================================================================
check_hardcoded_secrets() {
    echo "→ Checking for hardcoded secrets..."
    
    local found_violations=0
    
    # Common secret patterns (excluding documentation examples)
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]{8,}['\"]"
        "api_key\s*=\s*['\"][^'\"]{20,}['\"]"
        "secret\s*=\s*['\"][^'\"]{16,}['\"]"
        "token\s*=\s*['\"][^'\"]{20,}['\"]"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            [ -f "$file" ] || continue
            
            if grep -i -n "$pattern" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" | grep -v "FAKE" | grep -v "DOCS" >/dev/null 2>&1; then
                echo -e "  ${RED}✗ Potential hardcoded secret in: $file${NC}"
                grep -i -n "$pattern" "$file" | grep -v "^\s*#" | grep -v "echo" | grep -v "print" | grep -v "BAD:" | grep -v "WRONG:" | grep -v "❌" | grep -v "example" | grep -v "FAKE" | grep -v "DOCS" | head -1
                found_violations=1
            fi
        done < <(find "$SCAN_DIR" -name "*.py" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -type f -print0 2>/dev/null)
    done
    
    if [ $found_violations -eq 0 ]; then
        echo -e "  ${GREEN}✓ No hardcoded secrets found${NC}"
    else
        ((VIOLATIONS++))
    fi
    echo ""
}

# ==============================================================================
# Main execution
# ==============================================================================
main() {
    check_shell_true
    check_os_system
    check_eval_usage
    check_privileged_containers
    check_hardcoded_secrets
    
    echo "=========================================="
    if [ $VIOLATIONS -eq 0 ]; then
        echo -e "${GREEN}✅ All security pattern checks passed${NC}"
        echo "=========================================="
        exit 0
    else
        echo -e "${RED}❌ Found $VIOLATIONS security violation(s)${NC}"
        echo "=========================================="
        echo ""
        echo "Fix these violations before committing:"
        echo "1. Replace shell=True with shell=False and argument lists"
        echo "2. Replace os.system() with subprocess.run()"
        echo "3. Avoid eval() on untrusted input"
        echo "4. Remove privileged container configurations"
        echo "5. Move secrets to environment variables"
        echo ""
        echo "See .kiro/steering/python-secure-coding.md for guidance"
        exit 1
    fi
}

# Run main function
main "$@"