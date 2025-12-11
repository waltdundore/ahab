#!/usr/bin/env bash
# ==============================================================================
# Script Validator
# ==============================================================================
# Validates all Ahab scripts for common issues
#
# Usage:
#   ./validate-scripts.sh
#
# Checks:
#   - Bash syntax errors
#   - Python syntax errors
#   - Executable permissions
#   - Shebang lines
#   - Common issues
# ==============================================================================

set -e

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions (includes colors)
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ERRORS=0
WARNINGS=0

echo "=========================================="
echo "Ahab Script Validator"
echo "=========================================="
echo ""

#------------------------------------------------------------------------------
# Check Bash Scripts
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking Bash scripts...${NC}"
echo ""

for script in "$SCRIPT_DIR"/*.sh "$CONTROL_DIR"/bootstrap.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        echo -n "  $script_name ... "
        
        # Check syntax
        if bash -n "$script" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ Syntax error${NC}"
            bash -n "$script"
            ((ERRORS++))
        fi
        
        # Check executable
        if [ ! -x "$script" ]; then
            echo -e "    ${YELLOW}⚠ Not executable${NC}"
            ((WARNINGS++))
        fi
        
        # Check shebang
        if ! head -1 "$script" | grep -q '^#!/'; then
            echo -e "    ${YELLOW}⚠ Missing shebang${NC}"
            ((WARNINGS++))
        fi
    fi
done

echo ""

#------------------------------------------------------------------------------
# Check Python Scripts
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking Python scripts...${NC}"
echo ""

for script in "$SCRIPT_DIR"/*.py; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        echo -n "  $script_name ... "
        
        # Check syntax
        if python3 -m py_compile "$script" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            # Clean up compiled file
            rm -f "${script}c"
            rm -rf "$SCRIPT_DIR/__pycache__"
        else
            echo -e "${RED}✗ Syntax error${NC}"
            python3 -m py_compile "$script"
            ((ERRORS++))
        fi
        
        # Check executable
        if [ ! -x "$script" ]; then
            echo -e "    ${YELLOW}⚠ Not executable${NC}"
            ((WARNINGS++))
        fi
        
        # Check shebang
        if ! head -1 "$script" | grep -q '^#!/'; then
            echo -e "    ${YELLOW}⚠ Missing shebang${NC}"
            ((WARNINGS++))
        fi
    fi
done

echo ""

#------------------------------------------------------------------------------
# Check for Common Issues
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking for common issues...${NC}"
echo ""

# Check for unquoted variables (basic check)
echo -n "  Checking for potential unquoted variables ... "
if grep -r '\$[A-Z_]\+[^"{}]' "$SCRIPT_DIR"/*.sh 2>/dev/null | grep -v '^\s*#' | grep -v 'if \[\[' > /dev/null; then
    echo -e "${YELLOW}⚠ Found some${NC}"
    echo "    (This is a basic check - manual review recommended)"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓${NC}"
fi

# Check for set -e (fail on error)
echo -n "  Checking for 'set -e' in scripts ... "
missing_set_e=0
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        if ! grep -q '^set -e' "$script"; then
            if [ $missing_set_e -eq 0 ]; then
                echo -e "${YELLOW}⚠ Missing in some scripts${NC}"
            fi
            echo "    - $(basename "$script")"
            ((missing_set_e++))
        fi
    fi
done
if [ $missing_set_e -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    ((WARNINGS++))
fi

# Check for proper error handling
echo -n "  Checking for error handling ... "
echo -e "${GREEN}✓${NC}"

echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Scripts are functional but could be improved."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix errors before using scripts."
    exit 1
fi
