#!/usr/bin/env bash
# ==============================================================================
# Clean Unused Vagrant Boxes
# ==============================================================================
# Removes Vagrant boxes that are not defined in ahab.conf
#
# Usage:
#   ./scripts/clean-unused-boxes.sh           # Interactive (prompts)
#   ./scripts/clean-unused-boxes.sh --force   # Non-interactive (removes all)
#
# Exit Codes:
#   0 - Success
#   1 - Error
# ==============================================================================

set -euo pipefail

# Source shared color definitions (DRY)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"

# Configuration
AHAB_CONF="../ahab.conf"
FORCE=false

# Parse arguments
if [ "${1:-}" = "--force" ]; then
    FORCE=true
fi

echo "=========================================="
echo "Clean Unused Vagrant Boxes"
echo "=========================================="
echo ""

# Read versions from ahab.conf
if [ -f "$AHAB_CONF" ]; then
    FEDORA_VERSION=$(grep '^FEDORA_VERSION=' "$AHAB_CONF" | cut -d'=' -f2 || echo "43")
    DEBIAN_VERSION=$(grep '^DEBIAN_VERSION=' "$AHAB_CONF" | cut -d'=' -f2 || echo "13")
    UBUNTU_VERSION=$(grep '^UBUNTU_VERSION=' "$AHAB_CONF" | cut -d'=' -f2 || echo "24.04")
else
    echo -e "${YELLOW}Warning: ahab.conf not found, using defaults${NC}"
    FEDORA_VERSION="43"
    DEBIAN_VERSION="13"
    UBUNTU_VERSION="24.04"
fi

echo "Boxes in use (from ahab.conf):"
echo "  ✓ bento/fedora-${FEDORA_VERSION}"
echo "  ✓ bento/debian-${DEBIAN_VERSION}"
echo "  ✓ bento/ubuntu-${UBUNTU_VERSION}"
echo ""

# Get list of all boxes
BOXES=$(vagrant box list | awk '{print $1 " " $2 " " $3}')

# Boxes to keep (from ahab.conf)
KEEP_BOXES=(
    "bento/fedora-${FEDORA_VERSION}"
    "bento/debian-${DEBIAN_VERSION}"
    "bento/ubuntu-${UBUNTU_VERSION}"
)

# Boxes to remove
TO_REMOVE=()

while IFS= read -r line; do
    BOX_NAME=$(echo "$line" | awk '{print $1}')
    PROVIDER=$(echo "$line" | awk '{print $2}' | tr -d '(),')
    
    # Check if this box is in the keep list
    KEEP=false
    for keep_box in "${KEEP_BOXES[@]}"; do
        if [[ "$BOX_NAME" == "$keep_box" ]]; then
            KEEP=true
            break
        fi
    done
    
    if [ "$KEEP" = false ]; then
        TO_REMOVE+=("$BOX_NAME --provider $PROVIDER")
    fi
done <<< "$BOXES"

if [ ${#TO_REMOVE[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No unused boxes found${NC}"
    echo ""
    exit 0
fi

echo "=========================================="
echo "Boxes to Remove:"
echo "=========================================="
for box in "${TO_REMOVE[@]}"; do
    echo "  • $box"
done
echo ""

# Calculate approximate disk space
TOTAL_SIZE=$(du -sh ~/.vagrant.d 2>/dev/null | awk '{print $1}' || echo "unknown")
echo "Current Vagrant disk usage: $TOTAL_SIZE"
echo ""

if [ "$FORCE" = false ]; then
    read -p "Remove these boxes? [y/N] " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo ""
        echo "Cancelled - no boxes removed"
        echo ""
        exit 0
    fi
fi

echo ""
echo "→ Removing unused boxes..."
echo ""

REMOVED=0
FAILED=0

for box in "${TO_REMOVE[@]}"; do
    echo -n "  Removing $box... "
    # Try with --all flag first (handles multi-version boxes)
    if vagrant box remove $box --all --force >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((REMOVED++))
    # If that fails, try without --all (single version)
    elif vagrant box remove $box --force >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((REMOVED++))
    else
        echo -e "${RED}✗${NC}"
        ((FAILED++))
    fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "  Removed: $REMOVED boxes"
if [ $FAILED -gt 0 ]; then
    echo "  Failed:  $FAILED boxes"
fi
echo ""

# Show new disk usage
NEW_SIZE=$(du -sh ~/.vagrant.d 2>/dev/null | awk '{print $1}' || echo "unknown")
echo "Vagrant disk usage: $TOTAL_SIZE → $NEW_SIZE"
echo ""
echo -e "${GREEN}✅ Cleanup complete${NC}"
echo ""

