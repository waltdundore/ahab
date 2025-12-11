#!/usr/bin/env bash
# ==============================================================================
# Quick OS Test
# ==============================================================================
# Quick test of a single OS installation (for learning/debugging)
#
# Usage:
#   ./scripts/quick-test-os.sh [fedora|debian|ubuntu]
#
# Example:
#   ./scripts/quick-test-os.sh fedora
#
# ==============================================================================

set -euo pipefail

OS="${1:-fedora}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Quick OS Test: $OS"
echo "=========================================="
echo ""

# Update ahab.conf
echo -e "${BLUE}→${NC} Configuring ahab.conf for $OS..."
sed -i.bak "s/^DEFAULT_OS=.*/DEFAULT_OS=$OS/" ../ahab.conf
echo -e "${GREEN}✓${NC} Configured"
echo ""

# Clean existing VM
echo -e "${BLUE}→${NC} Cleaning existing VMs..."
make clean >/dev/null 2>&1 || true
echo -e "${GREEN}✓${NC} Clean"
echo ""

# Install
echo -e "${BLUE}→${NC} Installing workstation..."
if ! make install; then
    echo ""
    echo -e "${YELLOW}❌ Installation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Installed"
echo ""

# Verify
echo -e "${BLUE}→${NC} Verifying installation..."
if ! make verify-install; then
    echo ""
    echo -e "${YELLOW}❌ Verification failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Verified"
echo ""

# Deploy hello world
echo -e "${BLUE}→${NC} Deploying hello world..."
if ! ./scripts/deploy-hello-world.sh "$OS"; then
    echo ""
    echo -e "${YELLOW}❌ Hello world deployment failed${NC}"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ $OS Test Complete${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  • View hello world: vagrant ssh -c 'curl http://localhost:8080'"
echo "  • SSH into VM: vagrant ssh"
echo "  • Clean up: make clean"
echo ""
