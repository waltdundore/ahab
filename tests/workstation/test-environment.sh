#!/usr/bin/env bash
# ==============================================================================
# Workstation Environment Test
# ==============================================================================
# Tests the Fedora 43 workstation environment is properly configured
# This runs INSIDE the workstation VM, not on the host
#
# Usage:
#   ./test-environment.sh
#
# Tests:
#   - Operating system version
#   - Required packages installed
#   - Services running
#   - User permissions
#   - Network connectivity
#   - Disk space
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Workstation Environment Validation"
echo "=========================================="
echo ""

#------------------------------------------------------------------------------
# Test 1: Operating System
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing operating system...${NC}"

# Check OS release
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "  OS: $PRETTY_NAME"
    
    # Verify it's Fedora 43 (or configured OS)
    if [[ "$ID" == "fedora" && "$VERSION_ID" == "43" ]]; then
        echo -e "${GREEN}✓ Fedora 43 confirmed${NC}"
    elif [[ "$ID" == "debian" && "$VERSION_ID" == "13" ]]; then
        echo -e "${GREEN}✓ Debian 13 confirmed${NC}"
    elif [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
        echo -e "${GREEN}✓ Ubuntu 24.04 confirmed${NC}"
    else
        echo -e "${YELLOW}⚠ Unexpected OS: $ID $VERSION_ID${NC}"
    fi
else
    echo -e "${RED}✗ Cannot determine OS version${NC}"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
echo "  Architecture: $ARCH"
if [[ "$ARCH" == "aarch64" || "$ARCH" == "x86_64" ]]; then
    echo -e "${GREEN}✓ Supported architecture${NC}"
else
    echo -e "${YELLOW}⚠ Unusual architecture: $ARCH${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Test 2: Required Packages
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing required packages...${NC}"

# Test Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo -e "${GREEN}✓ Docker $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Docker not found${NC}"
    exit 1
fi

# Test Ansible
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ Ansible $ANSIBLE_VERSION${NC}"
else
    echo -e "${RED}✗ Ansible not found${NC}"
    exit 1
fi

# Test Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓ Python $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python 3 not found${NC}"
    exit 1
fi

# Test Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo -e "${GREEN}✓ Git $GIT_VERSION${NC}"
else
    echo -e "${RED}✗ Git not found${NC}"
    exit 1
fi

# Test Make
if command -v make &> /dev/null; then
    echo -e "${GREEN}✓ Make available${NC}"
else
    echo -e "${RED}✗ Make not found${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 3: Services
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing services...${NC}"

# Test Docker service
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker service running${NC}"
else
    echo -e "${RED}✗ Docker service not running${NC}"
    exit 1
fi

# Test Docker socket
if [ -S /var/run/docker.sock ]; then
    echo -e "${GREEN}✓ Docker socket available${NC}"
else
    echo -e "${RED}✗ Docker socket not found${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 4: User Permissions
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing user permissions...${NC}"

# Test current user
CURRENT_USER=$(whoami)
echo "  Current user: $CURRENT_USER"

# Test Docker group membership
if groups | grep -q docker; then
    echo -e "${GREEN}✓ User in docker group${NC}"
else
    echo -e "${RED}✗ User not in docker group${NC}"
    exit 1
fi

# Test Docker access
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Docker access working${NC}"
else
    echo -e "${RED}✗ Cannot access Docker${NC}"
    exit 1
fi

# Test ahab directory permissions
if [ -d "/home/vagrant/ahab" ]; then
    if [ -w "/home/vagrant/ahab" ]; then
        echo -e "${GREEN}✓ Ahab directory writable${NC}"
    else
        echo -e "${RED}✗ Ahab directory not writable${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Ahab directory not found${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 5: Network Connectivity
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing network connectivity...${NC}"

# Test localhost
if ping -c 1 localhost &> /dev/null; then
    echo -e "${GREEN}✓ Localhost reachable${NC}"
else
    echo -e "${RED}✗ Localhost not reachable${NC}"
    exit 1
fi

# Test external connectivity (if available)
if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}✓ External connectivity${NC}"
else
    echo -e "${YELLOW}⚠ No external connectivity (may be expected)${NC}"
fi

# Test Docker Hub (if external connectivity works)
if docker pull hello-world:latest &> /dev/null; then
    echo -e "${GREEN}✓ Docker Hub accessible${NC}"
    docker rmi hello-world:latest &> /dev/null || true
else
    echo -e "${YELLOW}⚠ Docker Hub not accessible (may be expected)${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Test 6: Disk Space
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing disk space...${NC}"

# Check available space
AVAILABLE_GB=$(df -BG /home | tail -1 | awk '{print $4}' | sed 's/G//')
echo "  Available space: ${AVAILABLE_GB}GB"

if [ "$AVAILABLE_GB" -gt 5 ]; then
    echo -e "${GREEN}✓ Sufficient disk space${NC}"
elif [ "$AVAILABLE_GB" -gt 2 ]; then
    echo -e "${YELLOW}⚠ Low disk space (${AVAILABLE_GB}GB)${NC}"
else
    echo -e "${RED}✗ Insufficient disk space (${AVAILABLE_GB}GB)${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 7: Security Configuration
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing security configuration...${NC}"

# Check SELinux (Fedora) or AppArmor (Debian/Ubuntu)
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    echo "  SELinux: $SELINUX_STATUS"
    if [[ "$SELINUX_STATUS" == "Enforcing" ]]; then
        echo -e "${GREEN}✓ SELinux enforcing${NC}"
    else
        echo -e "${YELLOW}⚠ SELinux not enforcing${NC}"
    fi
elif command -v aa-status &> /dev/null; then
    if aa-status --enabled &> /dev/null; then
        echo -e "${GREEN}✓ AppArmor enabled${NC}"
    else
        echo -e "${YELLOW}⚠ AppArmor not enabled${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No MAC system detected${NC}"
fi

# Check firewall
if systemctl is-active --quiet firewalld; then
    echo -e "${GREEN}✓ Firewall active (firewalld)${NC}"
elif systemctl is-active --quiet ufw; then
    echo -e "${GREEN}✓ Firewall active (ufw)${NC}"
else
    echo -e "${YELLOW}⚠ No active firewall detected${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo -e "${GREEN}=========================================="
echo "✓ Workstation Environment Validated"
echo -e "==========================================${NC}"
echo ""
echo "Environment Summary:"
echo "  OS: $PRETTY_NAME ($ARCH)"
echo "  Docker: $DOCKER_VERSION"
echo "  Ansible: $ANSIBLE_VERSION"
echo "  Python: $PYTHON_VERSION"
echo "  User: $CURRENT_USER (docker group)"
echo "  Disk: ${AVAILABLE_GB}GB available"
echo ""
echo "✅ Ready for service deployment"
echo ""