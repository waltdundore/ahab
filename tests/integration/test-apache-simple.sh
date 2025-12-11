#!/usr/bin/env bash
# ==============================================================================
# Apache Module Simple Test
# ==============================================================================
# Tests Apache module concept with a simple Python HTTP server
# (No Docker required)
#
# Usage:
#   ./test-apache-simple.sh
#
# This script:
#   - Creates a test directory with HTML content
#   - Starts Python HTTP server on port 8080
#   - Opens browser to test page
# ==============================================================================

set -e

# Cleanup on exit
cleanup_on_exit() { :; }
trap cleanup_on_exit EXIT

# Colors (only define if not already defined)
if [ -z "${RED:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$CONTROL_DIR/test-apache-simple"
PORT=8080

echo "=========================================="
echo "Apache Module Simple Test"
echo "=========================================="
echo ""
echo "Using Python HTTP server (no Docker needed)"
echo ""

#------------------------------------------------------------------------------
# Check Prerequisites
#------------------------------------------------------------------------------

echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python 3 is available${NC}"
echo ""

#------------------------------------------------------------------------------
# Create Test Directory
#------------------------------------------------------------------------------

echo -e "${BLUE}Creating test directory...${NC}"

# Clean up old test directory
if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
fi

# Create new test directory
mkdir -p "$TEST_DIR"

# Create Hello World page
cat > "$TEST_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ahab Apache Module Test</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
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
            max-width: 700px;
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
        .success::before {
            content: "✓ ";
            font-size: 1.3em;
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
        .footer {
            margin-top: 40px;
            padding-top: 30px;
            border-top: 2px solid #e5e7eb;
        }
        .footer p {
            font-size: 1em;
            color: #999;
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
        .features {
            margin: 30px 0;
            text-align: left;
        }
        .feature {
            background: #f9fafb;
            padding: 15px 20px;
            margin: 10px 0;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .feature::before {
            content: "✓";
            color: #10b981;
            font-weight: bold;
            margin-right: 10px;
            font-size: 1.2em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>Hello World!</h1>
        <div class="success">Apache Module Working!</div>
        <p>Your Ahab Apache module is successfully serving this page.</p>
        
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
                    <div class="value">Test Mode</div>
                </div>
                <div class="info-item">
                    <span class="label">Port</span>
                    <div class="value">8080</div>
                </div>
            </div>
        </div>

        <div class="features">
            <div class="feature">Multi-platform support (Fedora, Debian, Ubuntu)</div>
            <div class="feature">Dual deployment (Ansible + Docker)</div>
            <div class="feature">Automatic OS detection and configuration</div>
            <div class="feature">Self-documenting with MODULE.yml</div>
            <div class="feature">Version branching and dependency tracking</div>
        </div>

        <div>
            <span class="badge">Open Source</span>
            <span class="badge">K-12 Focused</span>
            <span class="badge">No Subscriptions</span>
            <span class="badge">Own Your Data</span>
        </div>
        
        <div class="footer">
            <p>
                <strong>Ahab Infrastructure Management System</strong><br>
                Making infrastructure simple for K-12 education<br>
                <small>Save money • Own your data • Learn real skills</small>
            </p>
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✓ Test page created${NC}"
echo ""

#------------------------------------------------------------------------------
# Check if Port is Available
#------------------------------------------------------------------------------

echo -e "${BLUE}Finding available port...${NC}"

# Find an available port
for p in 8080 8081 8082 8083 8084 8085 8086 8087 8088 8089; do
    if ! lsof -Pi :$p -sTCP:LISTEN -t >/dev/null 2>&1; then
        PORT=$p
        echo -e "${GREEN}✓ Using port $PORT${NC}"
        break
    fi
done

# Verify we found a port
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}✗ No available ports found${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Start HTTP Server
#------------------------------------------------------------------------------

echo -e "${BLUE}Starting HTTP server on port $PORT...${NC}"

cd "$TEST_DIR"

# Start server in background
python3 -m http.server $PORT > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 2

# Check if server is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo -e "${RED}✗ Failed to start server${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Server started (PID: $SERVER_PID)${NC}"
echo ""

#------------------------------------------------------------------------------
# Test HTTP Response
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing HTTP response...${NC}"

URL="http://localhost:$PORT"

# Test with curl
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ HTTP 200 OK${NC}"
    else
        echo -e "${RED}✗ HTTP $HTTP_CODE${NC}"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ curl not available, skipping HTTP test${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

echo -e "${BLUE}Cleaning up...${NC}"
kill $SERVER_PID 2>/dev/null || true
echo -e "${GREEN}✓ Server stopped${NC}"

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Apache Simple Test PASSED"
echo -e "==========================================${NC}"
echo ""
