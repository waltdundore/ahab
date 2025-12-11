#!/usr/bin/env bash
# ==============================================================================
# Apache Module End-to-End Test
# ==============================================================================
# Complete test of Apache module using Vagrant
#
# This script:
#   1. Runs on your Mac
#   2. Uses 'make install' to create Vagrant VM
#   3. Deploys Apache inside the VM using Ansible
#   4. Creates Hello World page
#   5. Opens browser to view the page
#
# Usage:
#   ./test-apache-e2e.sh
#
# Requirements:
#   - Vagrant installed
#   - VirtualBox installed
#   - Ansible installed
# ==============================================================================

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Cleanup on exit
cleanup_on_exit() { :; }
trap cleanup_on_exit EXIT

CONTROL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Apache Module End-to-End Test"
echo "=========================================="
echo ""

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking prerequisites...${NC}"
echo ""

MISSING_PREREQS=0

# Check Vagrant
if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}✗ Vagrant not found${NC}"
    echo "  Install: https://www.vagrantup.com/downloads"
    ((MISSING_PREREQS++))
else
    echo -e "${GREEN}✓ Vagrant installed${NC}"
fi

# Check VirtualBox
if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}✗ VirtualBox not found${NC}"
    echo "  Install: https://www.virtualbox.org/wiki/Downloads"
    ((MISSING_PREREQS++))
else
    echo -e "${GREEN}✓ VirtualBox installed${NC}"
fi

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}✗ Ansible not found${NC}"
    echo "  Install: brew install ansible"
    ((MISSING_PREREQS++))
else
    echo -e "${GREEN}✓ Ansible installed${NC}"
fi

if [ $MISSING_PREREQS -gt 0 ]; then
    echo ""
    echo -e "${RED}Please install missing prerequisites${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Clean Up Old VMs
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking for existing VMs...${NC}"

cd "$CONTROL_DIR"

if vagrant status 2>/dev/null | grep -q "running\|poweroff\|saved"; then
    echo -e "${YELLOW}Found existing VM, cleaning up...${NC}"
    vagrant destroy -f 2>/dev/null || true
    echo -e "${GREEN}✓ Old VM removed${NC}"
else
    echo -e "${GREEN}✓ No existing VMs${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Create Hello World Content
#------------------------------------------------------------------------------

echo -e "${BLUE}Creating Hello World content...${NC}"

# Create files directory for Apache role
mkdir -p "$CONTROL_DIR/roles/apache/files"

# Create Hello World HTML page
cat > "$CONTROL_DIR/roles/apache/files/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ahab Apache Test - Hello World</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 60px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 800px;
            animation: fadeIn 0.5s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .emoji {
            font-size: 5em;
            margin: 20px 0;
            animation: bounce 2s infinite;
        }
        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-20px); }
        }
        h1 {
            color: #667eea;
            font-size: 3.5em;
            margin: 20px 0;
            font-weight: 700;
        }
        .success {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 20px 40px;
            border-radius: 50px;
            display: inline-block;
            margin: 30px 0;
            font-weight: bold;
            font-size: 1.2em;
            box-shadow: 0 10px 30px rgba(16, 185, 129, 0.3);
        }
        p {
            color: #666;
            font-size: 1.3em;
            line-height: 1.8;
            margin: 20px 0;
        }
        .info {
            background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
            padding: 30px;
            border-radius: 15px;
            margin: 30px 0;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .info-item {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .label {
            font-weight: bold;
            color: #667eea;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            display: block;
            margin-bottom: 8px;
        }
        .value {
            color: #374151;
            font-size: 1.1em;
            font-weight: 600;
        }
        .badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            margin: 5px;
            font-weight: 600;
        }
        .footer {
            margin-top: 40px;
            padding-top: 30px;
            border-top: 2px solid #e5e7eb;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>Hello World!</h1>
        <div class="success">✓ Apache Module Working!</div>
        <p>Your Ahab Apache module successfully deployed and is serving this page from a Vagrant VM.</p>
        
        <div class="info">
            <div class="info-grid">
                <div class="info-item">
                    <span class="label">Server</span>
                    <div class="value">Apache HTTP</div>
                </div>
                <div class="info-item">
                    <span class="label">Module</span>
                    <div class="value">ahab-apache</div>
                </div>
                <div class="info-item">
                    <span class="label">Deployment</span>
                    <div class="value">Vagrant VM</div>
                </div>
                <div class="info-item">
                    <span class="label">Port</span>
                    <div class="value">8080</div>
                </div>
            </div>
        </div>

        <div>
            <span class="badge">Ansible Deployed</span>
            <span class="badge">Vagrant VM</span>
            <span class="badge">End-to-End Test</span>
        </div>
        
        <div class="footer">
            <p>
                <strong>Ahab Infrastructure Management System</strong><br>
                Making infrastructure simple for K-12 education
            </p>
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✓ Hello World page created${NC}"
echo ""

#------------------------------------------------------------------------------
# Create Apache Defaults
#------------------------------------------------------------------------------

echo -e "${BLUE}Setting up Apache defaults...${NC}"

# Create defaults file if it doesn't exist
mkdir -p "$CONTROL_DIR/roles/apache/defaults"

cat > "$CONTROL_DIR/roles/apache/defaults/main.yml" << 'EOF'
---
# Apache default variables

apache_server_name: "{{ ansible_fqdn }}"
apache_port: 80
apache_ssl_port: 443
EOF

echo -e "${GREEN}✓ Apache defaults configured${NC}"
echo ""

#------------------------------------------------------------------------------
# Create Inventory
#------------------------------------------------------------------------------

echo -e "${BLUE}Creating inventory...${NC}"

mkdir -p "$CONTROL_DIR/inventory"

cat > "$CONTROL_DIR/inventory/hosts" << 'EOF'
[webservers]
default ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/default/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo -e "${GREEN}✓ Inventory created${NC}"
echo ""

#------------------------------------------------------------------------------
# Start Vagrant VM
#------------------------------------------------------------------------------

echo -e "${BLUE}Starting Vagrant VM (this may take a few minutes)...${NC}"
echo ""

cd "$CONTROL_DIR"

# Use make install to create VM (with timeout - NASA Rule 2)
if ! vagrant_with_timeout 600 up; then
    echo ""
    echo -e "${RED}✗ Failed to create VM${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ VM created${NC}"
echo ""

#------------------------------------------------------------------------------
# Deploy Apache Using Ansible
#------------------------------------------------------------------------------

echo -e "${BLUE}Deploying Apache with Ansible...${NC}"
echo ""

# Run the webserver playbook
if ! ansible-playbook -i inventory/hosts playbooks/webserver.yml; then
    echo ""
    echo -e "${RED}✗ Ansible deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Apache deployed successfully${NC}"
echo ""

#------------------------------------------------------------------------------
# Get VM IP Address
#------------------------------------------------------------------------------

echo -e "${BLUE}Getting VM IP address...${NC}"

# Vagrant forwards port 80 to 8080 by default
# Check Vagrantfile for port forwarding
if grep -q "forwarded_port.*80.*8080" Vagrantfile 2>/dev/null; then
    VM_IP="localhost"
    PORT="8080"
    echo -e "${GREEN}✓ Using port forwarding: localhost:8080${NC}"
else
    # Try to get private network IP
    VM_IP=$(vagrant ssh -c "ip addr show eth1 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null | tr -d '\r')
    
    if [ -z "$VM_IP" ]; then
        # Fallback to localhost with port forwarding
        VM_IP="localhost"
        PORT="8080"
        echo -e "${YELLOW}⚠ Using localhost:8080 (add port forwarding to Vagrantfile if needed)${NC}"
    else
        PORT="80"
        echo -e "${GREEN}✓ VM IP: $VM_IP${NC}"
    fi
fi

echo ""

#------------------------------------------------------------------------------
# Wait for Apache to Start
#------------------------------------------------------------------------------

echo -e "${BLUE}Waiting for Apache to be accessible...${NC}"

MAX_ATTEMPTS=15
ATTEMPT=0

# Wait a moment for Apache to fully start
sleep 3

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if [ "$VM_IP" = "localhost" ]; then
        # Test via port forwarding
        if curl -s "http://localhost:$PORT/" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Apache is responding on localhost:$PORT${NC}"
            break
        fi
    else
        # Test via private network IP
        if curl -s "http://$VM_IP/" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Apache is responding on $VM_IP${NC}"
            break
        fi
    fi
    
    if [ $ATTEMPT -eq $((MAX_ATTEMPTS - 1)) ]; then
        echo -e "${RED}✗ Apache is not accessible${NC}"
        echo ""
        echo "Checking Apache status in VM..."
        vagrant ssh -c "sudo systemctl status httpd || sudo systemctl status apache2" || true
        echo ""
        echo "Checking if Apache is listening..."
        vagrant ssh -c "sudo ss -tlnp | grep :80" || true
        exit 1
    fi
    
    echo -n "."
    sleep 2
    ((ATTEMPT++))
done

echo ""

#------------------------------------------------------------------------------
# Display Access URL
#------------------------------------------------------------------------------

if [ "$VM_IP" = "localhost" ]; then
    URL="http://localhost:$PORT"
else
    URL="http://$VM_IP"
fi

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo ""
echo -e "${GREEN}=========================================="
echo "Apache Test Complete!"
echo -e "==========================================${NC}"
echo ""
echo "VM Status: Running"
echo "URL: $URL"
echo ""
echo "Useful commands:"
echo "  SSH into VM:      cd $CONTROL_DIR && vagrant ssh"
echo "  Check Apache:     vagrant ssh -c 'sudo systemctl status httpd'"
echo "  View logs:        vagrant ssh -c 'sudo tail -f /var/log/httpd/error_log'"
echo "  Restart Apache:   vagrant ssh -c 'sudo systemctl restart httpd'"
echo "  Stop VM:          cd $CONTROL_DIR && vagrant halt"
echo "  Destroy VM:       cd $CONTROL_DIR && vagrant destroy -f"
echo ""
echo -e "${BLUE}VM is running. Use 'vagrant halt' to stop it.${NC}"
echo ""
