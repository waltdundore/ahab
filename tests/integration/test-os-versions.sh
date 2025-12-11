#!/usr/bin/env bash
# ==============================================================================
# OS Version Verification Test
# ==============================================================================
# Tests that VMs are created with correct OS versions from ahab.conf
# ==============================================================================

set -euo pipefail


# Source common functions (includes colors)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

echo "=========================================="
echo "OS Version Verification Test"
echo "=========================================="
echo ""

# Find config file (relative to ahab directory)
CONFIG_FILE="../ahab.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo "Using config: $CONFIG_FILE"

# Parse config values
DEBIAN_VERSION=$(grep "^DEBIAN_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)
FEDORA_VERSION=$(grep "^FEDORA_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)
UBUNTU_VERSION=$(grep "^UBUNTU_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)

echo "Expected versions from ahab.conf:"
echo "  Debian: $DEBIAN_VERSION"
echo "  Fedora: $FEDORA_VERSION"
echo "  Ubuntu: $UBUNTU_VERSION"
echo ""

# Test each OS
test_os() {
    local os_name=$1
    local expected_version=$2
    
    echo "----------------------------------------"
    echo "Testing: $os_name $expected_version"
    echo "----------------------------------------"
    
    # Update config to use this OS
    sed -i.bak "s/^DEFAULT_OS=.*/DEFAULT_OS=$os_name/" "$CONFIG_FILE"
    
    # Clean any existing VM
    echo "→ Cleaning existing VM..."
    make clean >/dev/null 2>&1 || true
    sleep 2
    
    # Create VM
    echo "→ Creating $os_name VM..."
    if ! make install 2>&1 | tee /tmp/install-$os_name.log; then
        echo -e "${RED}❌ Failed to create $os_name VM${NC}"
        return 1
    fi
    
    # Verify OS version
    echo "→ Verifying OS version..."
    
    case $os_name in
        debian)
            actual_version=$(vagrant ssh -c "cat /etc/debian_version" 2>/dev/null | tr -d '\r' | cut -d'.' -f1)
            ;;
        fedora)
            actual_version=$(vagrant ssh -c "cat /etc/fedora-release" 2>/dev/null | grep -oP 'release \K[0-9]+')
            ;;
        ubuntu)
            actual_version=$(vagrant ssh -c "lsb_release -rs" 2>/dev/null | tr -d '\r')
            ;;
    esac
    
    echo "  Expected: $expected_version"
    echo "  Actual: $actual_version"
    
    if [[ "$actual_version" == "$expected_version"* ]] || [[ "$expected_version" == "$actual_version"* ]]; then
        echo -e "${GREEN}✓ $os_name version verified${NC}"
        return 0
    else
        echo -e "${RED}❌ Version mismatch for $os_name${NC}"
        return 1
    fi
}

# Track results
PASSED=0
FAILED=0

# Test Debian
if test_os "debian" "$DEBIAN_VERSION"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test Fedora
if test_os "fedora" "$FEDORA_VERSION"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Test Ubuntu
if test_os "ubuntu" "$UBUNTU_VERSION"; then
    ((PASSED++))
else
    ((FAILED++))
fi
echo ""

# Restore original config
if [[ -f "$CONFIG_FILE.bak" ]]; then
    mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
fi

# Clean up
make clean >/dev/null 2>&1 || true

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All OS versions verified${NC}"
    exit 0
else
    echo -e "${RED}❌ Some OS versions failed verification${NC}"
    exit 1
fi
