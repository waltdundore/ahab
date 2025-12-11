#!/usr/bin/env bash
# ==============================================================================
# Hardcoded Values Security Audit (Simplified)
# ==============================================================================
# Scans for critical hardcoded values that violate security and DRY principles
# ==============================================================================

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
VIOLATIONS_FOUND=0

print_violation() {
    local category="$1"
    local file="$2"
    local line_num="$3"
    local content="$4"
    
    echo -e "${RED}[HIGH] ${category}${NC}"
    echo "  File: $file:$line_num"
    echo "  Content: $content"
    echo "  Fix: Use configuration variables instead"
    echo ""
    
    ((VIOLATIONS_FOUND++))
}

scan_for_hardcoded_username() {
    print_info "Scanning for hardcoded username 'waltdundore'..."
    
    while IFS= read -r -d '' file; do
        if file "$file" | grep -q "text" && [[ ! "$file" =~ \.(md|txt)$ ]]; then
            local line_num=1
            while IFS= read -r line; do
                if echo "$line" | grep -q "waltdundore" && ! echo "$line" | grep -E "^[[:space:]]*#" > /dev/null; then
                    print_violation "Hardcoded Username" "$file" "$line_num" \
                        "$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)"
                fi
                ((line_num++))
            done < "$file"
        fi
    done < <(find . -name "*.sh" -o -name "*.conf" -o -name "*.yml" | head -20 | tr '\n' '\0')
}

scan_for_hardcoded_paths() {
    print_info "Scanning for hardcoded paths..."
    
    while IFS= read -r -d '' file; do
        if file "$file" | grep -q "text" && [[ ! "$file" =~ \.(md|txt)$ ]]; then
            local line_num=1
            while IFS= read -r line; do
                if echo "$line" | grep -E "/Users/[^/]+/" > /dev/null && ! echo "$line" | grep -E "^[[:space:]]*#" > /dev/null; then
                    print_violation "Hardcoded Path" "$file" "$line_num" \
                        "$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)"
                fi
                ((line_num++))
            done < "$file"
        fi
    done < <(find . -name "*.sh" -o -name "*.conf" -o -name "*.yml" | head -20 | tr '\n' '\0')
}

main() {
    echo "=============================================="
    echo "Hardcoded Values Security Audit"
    echo "=============================================="
    echo ""
    
    scan_for_hardcoded_username
    scan_for_hardcoded_paths
    
    echo "=============================================="
    if [ $VIOLATIONS_FOUND -eq 0 ]; then
        echo -e "${GREEN}✓ No critical violations found${NC}"
        exit 0
    else
        echo -e "${RED}✗ Found $VIOLATIONS_FOUND violations${NC}"
        echo ""
        echo "Run 'make fix-hardcoded' to fix automatically"
        exit 1
    fi
}

main "$@"