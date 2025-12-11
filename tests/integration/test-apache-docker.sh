#!/usr/bin/env bash
# ==============================================================================
# Apache Docker Integration Test
# ==============================================================================
# Tests Apache deployment using Docker inside the Fedora workstation VM
#
# Architecture:
#   Mac (host) → Vagrant → Fedora VM → Docker → Apache container
#
# Usage:
#   make test-integration  # Runs this test
#
# Prerequisites:
#   - Workstation VM running (make install)
#   - Docker installed in VM (automatic via provisioning)
#
# What this test does:
#   1. Verifies VM is running
#   2. Verifies Docker is running in VM
#   3. Creates test files in VM
#   4. Builds Docker image in VM
#   5. Runs Apache container in VM
#   6. Validates Apache is serving content
#
# NASA Power of 10 Compliance:
#   - Bounded loops with timeouts (max 30s for Apache start)
#   - All returns checked
#   - Functions ≤60 lines
#   - Idempotent cleanup
# ==============================================================================

set -euo pipefail

# Colors (only define if not already defined)
if [ -z "${RED:-}" ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
fi

# Test configuration
readonly TEST_NAME="apache-docker"
readonly CONTAINER_NAME="ahab-apache-test"
readonly TEST_PORT="8080"
readonly MAX_WAIT=30  # NASA Rule 2: bounded loop

# Cleanup on exit (idempotent)
cleanup_on_exit() {
    echo -e "${BLUE}Cleaning up test resources...${NC}"
    
    # Stop and remove container in VM (idempotent)
    vagrant ssh -c "docker stop ${CONTAINER_NAME} 2>/dev/null || true" 2>/dev/null || true
    vagrant ssh -c "docker rm ${CONTAINER_NAME} 2>/dev/null || true" 2>/dev/null || true
    vagrant ssh -c "docker rmi ${CONTAINER_NAME}:latest 2>/dev/null || true" 2>/dev/null || true
    
    # Remove test directory in VM (idempotent)
    vagrant ssh -c "rm -rf /tmp/test-apache 2>/dev/null || true" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Cleanup complete - test can be run again${NC}"
}

trap cleanup_on_exit EXIT

echo "=========================================="
echo "Apache Docker Integration Test"
echo "=========================================="
echo ""
echo "Architecture: Mac → Vagrant → Fedora VM → Docker → Apache"
echo ""

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------

check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check if workstation VM is running
    if ! vagrant status 2>/dev/null | grep -q "running"; then
        echo -e "${RED}✗ Workstation VM not running${NC}"
        echo ""
        echo "The test needs the Fedora workstation VM."
        echo "Start it with: make install"
        echo ""
        return 1
    fi
    echo -e "${GREEN}✓ VM is running${NC}"
    
    # Check Docker inside the VM
    if ! vagrant ssh -c "docker info" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Docker not running in VM, starting...${NC}"
        if ! vagrant ssh -c "sudo systemctl start docker" 2>/dev/null; then
            echo -e "${RED}✗ Failed to start Docker${NC}"
            return 1
        fi
        sleep 2
    fi
    echo -e "${GREEN}✓ Docker is running in VM${NC}"
    
    return 0
}

#------------------------------------------------------------------------------
# Create Test Files in VM
#------------------------------------------------------------------------------

create_test_files() {
    echo ""
    echo -e "${BLUE}Creating test files in VM...${NC}"
    
    # Create test directory in VM
    vagrant ssh -c "rm -rf /tmp/test-apache && mkdir -p /tmp/test-apache/html" || return 1
    
    # Create simple HTML file
    vagrant ssh -c "echo '<h1>Apache Test - It Works!</h1>' > /tmp/test-apache/html/index.html" || return 1
    
    # Create Dockerfile
    vagrant ssh -c 'cat > /tmp/test-apache/Dockerfile << "DOCKEREOF"
FROM httpd:2.4-alpine
COPY html/ /usr/local/apache2/htdocs/
EXPOSE 80
CMD ["httpd-foreground"]
DOCKEREOF' || return 1
    
    echo -e "${GREEN}✓ Test files created in VM${NC}"
    return 0
}

create_test_files_old() {
    echo ""
    echo -e "${BLUE}Creating test files in VM...${NC}"
    
    # Create test directory in VM
    vagrant ssh -c "mkdir -p /tmp/test-apache/html" || return 1
    
    # Create HTML file
    vagrant ssh -c 'cat > /tmp/test-apache/html/index.html << '\''EOF'\''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ahab - It Works!</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 40px;
        }
        .success-badge {
            text-align: center;
            font-size: 4em;
            color: #10b981;
            margin-bottom: 20px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }
        h1 {
            color: #667eea;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        .info-box {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .info-box h2 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 1.3em;
        }
        .architecture {
            background: #1f2937;
            color: #10b981;
            padding: 20px;
            border-radius: 8px;
            font-family: "Courier New", monospace;
            margin: 20px 0;
            overflow-x: auto;
        }
        .architecture pre {
            color: #10b981;
            font-size: 0.9em;
        }
        .details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .detail-item {
            background: #f0f4ff;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #667eea;
        }
        .detail-item strong {
            color: #667eea;
            display: block;
            margin-bottom: 5px;
        }
        .next-steps {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .next-steps h2 {
            color: #856404;
            margin-bottom: 10px;
        }
        .next-steps ul {
            margin-left: 20px;
        }
        .next-steps li {
            margin: 8px 0;
        }
        code {
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: "Courier New", monospace;
            color: #e83e8c;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #e9ecef;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-badge">✓</div>
        <h1>🎉 Success! Apache is Running</h1>
        
        <div class="info-box">
            <h2>What Happened?</h2>
            <p>You successfully deployed an Apache web server using Docker containers! This page proves that your entire infrastructure stack is working correctly.</p>
        </div>

        <div class="architecture">
            <pre>
Your Computer (Mac/Linux)
    ↓
Vagrant (Virtual Machine Manager)
    ↓
Fedora Linux VM (Virtual Computer)
    ↓
Docker (Container Engine)
    ↓
Apache Container (This Web Server!)
    ↓
You are here! 👋
            </pre>
        </div>

        <div class="details">
            <div class="detail-item">
                <strong>Web Server</strong>
                Apache HTTP Server 2.4
            </div>
            <div class="detail-item">
                <strong>Container</strong>
                Docker (Alpine Linux)
            </div>
            <div class="detail-item">
                <strong>VM OS</strong>
                Fedora Linux
            </div>
            <div class="detail-item">
                <strong>Status</strong>
                ✓ Running
            </div>
        </div>

        <div class="info-box">
            <h2>Why This Matters</h2>
            <p><strong>For Students:</strong> You learned how professional developers deploy applications. This is the same technology used by Netflix, Spotify, and thousands of companies.</p>
            <p style="margin-top: 10px;"><strong>For Schools:</strong> You can now host your own websites, databases, and applications without paying monthly cloud fees.</p>
        </div>

        <div class="next-steps">
            <h2>🚀 What to Do Next</h2>
            <ul>
                <li><strong>Customize This Page:</strong> Edit <code>/tmp/test-apache/html/index.html</code> in the VM</li>
                <li><strong>Deploy More Services:</strong> Try <code>make install mysql</code> to add a database</li>
                <li><strong>Learn the Commands:</strong> Run <code>make help</code> to see all available commands</li>
                <li><strong>Check the Logs:</strong> Run <code>vagrant ssh -c "docker logs ahab-apache-test"</code></li>
                <li><strong>Read the Docs:</strong> Open <code>README-STUDENTS.md</code> for tutorials and project ideas</li>
            </ul>
        </div>

        <div class="info-box">
            <h2>🎓 Learning Resources</h2>
            <p><strong>Beginner:</strong> Start with README-STUDENTS.md for step-by-step tutorials</p>
            <p><strong>Intermediate:</strong> Read DEVELOPMENT_RULES.md to learn our coding standards</p>
            <p><strong>Advanced:</strong> Check ABOUT.md to understand the architecture and philosophy</p>
        </div>

        <div class="footer">
            <p><strong>Ahab</strong> - Infrastructure Automation for Schools and Non-Profits</p>
            <p style="margin-top: 10px;">Made with ❤️ for students learning real DevOps skills</p>
            <p style="margin-top: 10px;"><a href="https://github.com/waltdundore/ahab" style="color: #667eea;">View on GitHub</a></p>
        </div>
    </div>
</body>
</html>
EOF' || return 1
    
    # Create Dockerfile
    vagrant ssh -c 'cat > /tmp/test-apache/Dockerfile << '\''EOF'\''
FROM httpd:2.4-alpine
COPY html/ /usr/local/apache2/htdocs/
EXPOSE 80
CMD ["httpd-foreground"]
EOF' || return 1
    
    echo -e "${GREEN}✓ Test files created in VM${NC}"
    return 0
}

#------------------------------------------------------------------------------
# Build and Run Container in VM
#------------------------------------------------------------------------------

build_and_run_container() {
    echo ""
    echo -e "${BLUE}Building Docker image in VM...${NC}"
    
    # Build image in VM
    if ! vagrant ssh -c "cd /tmp/test-apache && docker build -t ${CONTAINER_NAME}:latest . 2>&1"; then
        echo -e "${RED}✗ Docker build failed${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Docker image built${NC}"
    
    echo ""
    echo -e "${BLUE}Starting Apache container in VM...${NC}"
    
    # Stop existing container if any (idempotent)
    vagrant ssh -c "docker stop ${CONTAINER_NAME} 2>/dev/null || true" 2>/dev/null || true
    vagrant ssh -c "docker rm ${CONTAINER_NAME} 2>/dev/null || true" 2>/dev/null || true
    
    # Run container in VM
    if ! vagrant ssh -c "docker run -d --name ${CONTAINER_NAME} -p ${TEST_PORT}:80 ${CONTAINER_NAME}:latest" >/dev/null 2>&1; then
        echo -e "${RED}✗ Failed to start container${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Container started${NC}"
    
    return 0
}

#------------------------------------------------------------------------------
# Verify Apache is Running
#------------------------------------------------------------------------------

verify_apache() {
    echo ""
    echo -e "${BLUE}Waiting for Apache to start (max ${MAX_WAIT}s)...${NC}"
    
    # NASA Rule 2: Bounded loop with timeout
    for i in $(seq 1 $MAX_WAIT); do
        if vagrant ssh -c "curl -s http://localhost:${TEST_PORT}" 2>/dev/null | grep -q "Apache"; then
            echo -e "${GREEN}✓ Apache is serving content${NC}"
            return 0
        fi
        
        if [ $i -eq $MAX_WAIT ]; then
            echo -e "${RED}✗ Apache failed to start within ${MAX_WAIT}s${NC}"
            echo ""
            echo "Container logs:"
            vagrant ssh -c "docker logs ${CONTAINER_NAME}" 2>/dev/null || true
            return 1
        fi
        
        sleep 1
    done
    
    return 1
}

#------------------------------------------------------------------------------
# Main Test Flow
#------------------------------------------------------------------------------

main() {
    # NASA Rule 7: Check all returns
    check_prerequisites || exit 1
    create_test_files || exit 1
    build_and_run_container || exit 1
    verify_apache || exit 1
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "✓ Apache Docker Test PASSED"
    echo -e "==========================================${NC}"
    echo ""
    echo "Apache is running in:"
    echo "  Container: ${CONTAINER_NAME}"
    echo "  VM Port: ${TEST_PORT}"
    echo "  Architecture: Mac → Vagrant → Fedora VM → Docker → Apache"
    echo ""
    echo "To access from VM:"
    echo "  vagrant ssh -c 'curl http://localhost:${TEST_PORT}'"
    echo ""
    
    exit 0
}

# Run main
main "$@"
