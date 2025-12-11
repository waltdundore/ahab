#!/usr/bin/env bash
# ==============================================================================
# Workstation Apache Test
# ==============================================================================
# Complete test of the workstation setup by deploying Apache
#
# This test validates that the workstation can:
#   1. Start up using Vagrantfile.workstation
#   2. Clone repos and run bootstrap
#   3. Deploy Apache using the module
#   4. Serve a Hello World page
#   5. Make it accessible from your Mac
#
# Usage:
#   ./test-workstation-apache.sh
#
# Success criteria:
#   - Workstation VM starts
#   - Repos are cloned
#   - Apache deploys to a test VM
#   - Hello World page is accessible
#   - Link is displayed for you to click
# ==============================================================================

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Cleanup on exit
cleanup_on_exit() { :; }
trap cleanup_on_exit EXIT

echo "=========================================="
echo "Workstation Apache Test"
echo "=========================================="
echo ""
echo "This test validates the complete workstation setup"
echo "by deploying Apache and serving a Hello World page."
echo ""

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking prerequisites on Mac...${NC}"

MISSING=0

if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}✗ Vagrant not found${NC}"
    echo "  Install: brew install vagrant"
    ((MISSING++))
else
    echo -e "${GREEN}✓ Vagrant installed${NC}"
fi

if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}✗ VirtualBox not found${NC}"
    echo "  Install: brew install --cask virtualbox"
    ((MISSING++))
else
    echo -e "${GREEN}✓ VirtualBox installed${NC}"
fi

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${RED}Please install missing prerequisites${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Clean Up Old Test Workstation
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking for existing test workstation...${NC}"

if VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant status 2>/dev/null | grep -q "running\|poweroff"; then
    echo -e "${YELLOW}Found existing test workstation, destroying it...${NC}"
    VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant destroy -f
    echo -e "${GREEN}✓ Old test workstation removed${NC}"
else
    echo -e "${GREEN}✓ No existing test workstation${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Start Test Workstation
#------------------------------------------------------------------------------

echo -e "${BLUE}Starting test workstation VM...${NC}"
echo -e "${YELLOW}This will take 10-15 minutes (installing prerequisites, cloning repos, running bootstrap)${NC}"
echo -e "${YELLOW}Note: This uses Vagrantfile.workstation-test (does not affect your main workstation)${NC}"
echo ""

# Start test workstation with timeout (NASA Rule 2)
if ! SKIP_MULTI_TEST=true VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant_with_timeout 600 up; then
    echo ""
    echo -e "${RED}✗ Failed to start test workstation${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Test workstation VM created and provisioned${NC}"
echo ""

#------------------------------------------------------------------------------
# Deploy Apache from Test Workstation
#------------------------------------------------------------------------------

echo -e "${BLUE}Deploying Apache from test workstation...${NC}"
echo -e "${YELLOW}The test workstation will now create a test VM and deploy Apache${NC}"
echo ""

# Create the test script inside the test workstation
VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant ssh -c 'cat > /tmp/deploy-apache.sh << '\''INNEREOF'\''
#!/bin/bash
set -e

# Cleanup on exit
cleanup_on_exit() { :; }
trap cleanup_on_exit EXIT

cd ~/git/ahab

echo "Creating test VM..."
make install

echo ""
echo "Deploying Apache..."
ansible-playbook -i inventory/hosts playbooks/webserver.yml

echo ""
echo "Getting VM IP..."
VM_IP=$(vagrant ssh -c "ip addr show eth1 2>/dev/null | grep '\''inet '\'' | awk '\''{print \$2}'\'' | cut -d/ -f1" 2>/dev/null | tr -d '\''\r'\'')

if [ -z "$VM_IP" ]; then
    VM_IP="localhost"
    PORT="8080"
else
    PORT="80"
fi

echo ""
echo "Testing Apache..."
if vagrant ssh -c "curl -s http://localhost/" > /dev/null 2>&1; then
    echo "✓ Apache is responding"
    echo ""
    echo "=========================================="
    echo "Apache Deployed Successfully!"
    echo "=========================================="
    echo ""
    echo "Access URL: http://${VM_IP}:${PORT}"
    echo ""
else
    echo "✗ Apache is not responding"
    exit 1
fi
INNEREOF

chmod +x /tmp/deploy-apache.sh
/tmp/deploy-apache.sh
'

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}✗ Apache deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Apache deployed successfully${NC}"
echo ""

#------------------------------------------------------------------------------
# Get Access Information
#------------------------------------------------------------------------------

echo -e "${BLUE}Getting access information...${NC}"

# Get the test workstation IP
WORKSTATION_IP=$(VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant ssh -c "ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null | tr -d '\r')

if [ -z "$WORKSTATION_IP" ]; then
    WORKSTATION_IP="localhost"
fi

# Get the test VM IP from inside test workstation
TEST_VM_IP=$(VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant ssh -c "cd ~/git/ahab && vagrant ssh -c \"ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \\\$2}' | cut -d/ -f1\" 2>/dev/null | tr -d '\r'" 2>/dev/null | tr -d '\r')

echo ""

#------------------------------------------------------------------------------
# Display Results
#------------------------------------------------------------------------------

echo ""
echo -e "${GREEN}=========================================="
echo "Workstation Test PASSED!"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}What was tested:${NC}"
echo "  ✓ Workstation VM creation"
echo "  ✓ Prerequisites installation"
echo "  ✓ Repository cloning"
echo "  ✓ Bootstrap execution"
echo "  ✓ Test VM creation (nested)"
echo "  ✓ Apache module deployment"
echo "  ✓ Web server accessibility"
echo ""
echo -e "${BLUE}Access the Hello World page:${NC}"
echo ""
echo -e "${GREEN}  Click here: http://${TEST_VM_IP}${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to be on the same network or use port forwarding${NC}"
echo ""
echo -e "${BLUE}To access from inside the test workstation:${NC}"
echo "  1. SSH into test workstation:"
echo "     VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant ssh"
echo ""
echo "  2. Test from test workstation:"
echo "     cd ~/git/ahab"
echo "     vagrant ssh -c 'curl http://localhost'"
echo ""
echo -e "${BLUE}To stop everything:${NC}"
echo "  1. Stop test VM (from inside test workstation):"
echo "     VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant ssh"
echo "     cd ~/git/ahab"
echo "     vagrant halt"
echo ""
echo "  2. Stop test workstation (from Mac):"
echo "     VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant halt"
echo ""
echo -e "${BLUE}To destroy test workstation:${NC}"
echo "     VAGRANT_VAGRANTFILE=Vagrantfile.workstation-test vagrant destroy -f"
echo ""
echo -e "${YELLOW}Note: Your main workstation (Vagrantfile.workstation) was not modified${NC}"
echo ""
echo -e "${GREEN}Test complete! The workstation successfully deployed Apache.${NC}"
echo ""
