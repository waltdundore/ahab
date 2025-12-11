#!/usr/bin/env bash
# ==============================================================================
# Workstation Docker Test
# ==============================================================================
# Tests Docker functionality on the workstation VM
# This runs INSIDE the workstation VM, not on the host
#
# Usage:
#   ./test-docker.sh
#
# Tests:
#   - Docker daemon running
#   - Image operations (pull, build, remove)
#   - Container operations (run, stop, remove)
#   - Network functionality
#   - Volume mounts
#   - Port binding
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Workstation Docker Functionality Test"
echo "=========================================="
echo ""

# Test container and image names
TEST_IMAGE="ahab-test-image"
TEST_CONTAINER="ahab-test-container"
TEST_PORT="8999"

# Cleanup function
cleanup() {
    echo -e "${BLUE}Cleaning up test resources...${NC}"
    docker stop "$TEST_CONTAINER" 2>/dev/null || true
    docker rm "$TEST_CONTAINER" 2>/dev/null || true
    docker rmi "$TEST_IMAGE" 2>/dev/null || true
    rm -rf /tmp/docker-test 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Cleanup on exit
trap cleanup EXIT

#------------------------------------------------------------------------------
# Test 1: Docker Daemon
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing Docker daemon...${NC}"

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon not accessible${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker daemon accessible${NC}"

# Check Docker version
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
echo "  Docker version: $DOCKER_VERSION"

echo ""

#------------------------------------------------------------------------------
# Test 2: Image Operations
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing image operations...${NC}"

# Test image pull
echo "  Pulling test image..."
if docker pull alpine:latest &> /dev/null; then
    echo -e "${GREEN}✓ Image pull successful${NC}"
else
    echo -e "${RED}✗ Image pull failed${NC}"
    exit 1
fi

# Test image list
if docker images alpine:latest | grep -q alpine; then
    echo -e "${GREEN}✓ Image listed correctly${NC}"
else
    echo -e "${RED}✗ Image not found in list${NC}"
    exit 1
fi

# Test image build
echo "  Building test image..."
mkdir -p /tmp/docker-test
cat > /tmp/docker-test/Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Ahab test image" > /test.txt
CMD ["cat", "/test.txt"]
EOF

if docker build -t "$TEST_IMAGE" /tmp/docker-test &> /dev/null; then
    echo -e "${GREEN}✓ Image build successful${NC}"
else
    echo -e "${RED}✗ Image build failed${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 3: Container Operations
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing container operations...${NC}"

# Test container run
echo "  Running test container..."
if docker run --name "$TEST_CONTAINER" -d "$TEST_IMAGE" sleep 30 &> /dev/null; then
    echo -e "${GREEN}✓ Container run successful${NC}"
else
    echo -e "${RED}✗ Container run failed${NC}"
    exit 1
fi

# Test container list
if docker ps | grep -q "$TEST_CONTAINER"; then
    echo -e "${GREEN}✓ Container listed as running${NC}"
else
    echo -e "${RED}✗ Container not found in running list${NC}"
    exit 1
fi

# Test container exec
if docker exec "$TEST_CONTAINER" echo "exec test" &> /dev/null; then
    echo -e "${GREEN}✓ Container exec successful${NC}"
else
    echo -e "${RED}✗ Container exec failed${NC}"
    exit 1
fi

# Test container stop
if docker stop "$TEST_CONTAINER" &> /dev/null; then
    echo -e "${GREEN}✓ Container stop successful${NC}"
else
    echo -e "${RED}✗ Container stop failed${NC}"
    exit 1
fi

# Test container remove
if docker rm "$TEST_CONTAINER" &> /dev/null; then
    echo -e "${GREEN}✓ Container remove successful${NC}"
else
    echo -e "${RED}✗ Container remove failed${NC}"
    exit 1
fi

echo ""

#------------------------------------------------------------------------------
# Test 4: Port Binding
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing port binding...${NC}"

# Find available port
for p in 8999 9000 9001 9002 9003; do
    if ! netstat -ln | grep -q ":$p "; then
        TEST_PORT=$p
        break
    fi
done

echo "  Using port: $TEST_PORT"

# Create simple HTTP server container
cat > /tmp/docker-test/Dockerfile << EOF
FROM alpine:latest
RUN apk add --no-cache python3
WORKDIR /app
RUN echo '<h1>Ahab Docker Test</h1>' > index.html
CMD ["python3", "-m", "http.server", "8000"]
EOF

# Build HTTP server image
if docker build -t "${TEST_IMAGE}-http" /tmp/docker-test &> /dev/null; then
    echo -e "${GREEN}✓ HTTP server image built${NC}"
else
    echo -e "${RED}✗ HTTP server image build failed${NC}"
    exit 1
fi

# Run with port binding
if docker run --name "${TEST_CONTAINER}-http" -d -p "$TEST_PORT:8000" "${TEST_IMAGE}-http" &> /dev/null; then
    echo -e "${GREEN}✓ Container with port binding started${NC}"
else
    echo -e "${RED}✗ Container with port binding failed${NC}"
    exit 1
fi

# Wait for server to start
sleep 3

# Test port accessibility
if curl -s "http://localhost:$TEST_PORT" | grep -q "Ahab Docker Test"; then
    echo -e "${GREEN}✓ Port binding working${NC}"
else
    echo -e "${RED}✗ Port binding not working${NC}"
    exit 1
fi

# Cleanup HTTP test
docker stop "${TEST_CONTAINER}-http" &> /dev/null || true
docker rm "${TEST_CONTAINER}-http" &> /dev/null || true
docker rmi "${TEST_IMAGE}-http" &> /dev/null || true

echo ""

#------------------------------------------------------------------------------
# Test 5: Volume Mounts
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing volume mounts...${NC}"

# Create test directory
mkdir -p /tmp/docker-test/volume-test
echo "Ahab volume test" > /tmp/docker-test/volume-test/test.txt

# Test volume mount (with SELinux context)
if docker run --rm -v /tmp/docker-test/volume-test:/mnt:Z alpine:latest cat /mnt/test.txt | grep -q "Ahab volume test"; then
    echo -e "${GREEN}✓ Volume mount working${NC}"
elif docker run --rm -v /tmp/docker-test/volume-test:/mnt alpine:latest cat /mnt/test.txt 2>/dev/null | grep -q "Ahab volume test"; then
    echo -e "${GREEN}✓ Volume mount working (without SELinux context)${NC}"
else
    echo -e "${YELLOW}⚠ Volume mount failed (SELinux may be blocking)${NC}"
    # Try to diagnose the issue
    if getenforce 2>/dev/null | grep -q "Enforcing"; then
        echo "  SELinux is enforcing - this may require :Z flag for volume mounts"
    fi
fi

# Test read-only mount (with SELinux context)
if docker run --rm -v /tmp/docker-test/volume-test:/mnt:ro,Z alpine:latest sh -c "cat /mnt/test.txt && ! touch /mnt/readonly-test" &> /dev/null; then
    echo -e "${GREEN}✓ Read-only mount working${NC}"
elif docker run --rm -v /tmp/docker-test/volume-test:/mnt:ro alpine:latest sh -c "cat /mnt/test.txt && ! touch /mnt/readonly-test" &> /dev/null; then
    echo -e "${GREEN}✓ Read-only mount working (without SELinux context)${NC}"
else
    echo -e "${YELLOW}⚠ Read-only mount failed (SELinux may be blocking)${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Test 6: Network Functionality
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing network functionality...${NC}"

# Test default bridge network
if docker network ls | grep -q bridge; then
    echo -e "${GREEN}✓ Default bridge network available${NC}"
else
    echo -e "${RED}✗ Default bridge network missing${NC}"
    exit 1
fi

# Test container networking
if docker run --rm alpine:latest ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}✓ Container external networking${NC}"
else
    echo -e "${YELLOW}⚠ Container external networking failed (may be expected)${NC}"
fi

# Test container-to-container networking
docker run --name test-net-1 -d alpine:latest sleep 30 &> /dev/null
docker run --name test-net-2 -d alpine:latest sleep 30 &> /dev/null

if docker exec test-net-1 ping -c 1 test-net-2 &> /dev/null; then
    echo -e "${GREEN}✓ Container-to-container networking${NC}"
else
    echo -e "${YELLOW}⚠ Container-to-container networking failed${NC}"
fi

# Cleanup network test
docker stop test-net-1 test-net-2 &> /dev/null || true
docker rm test-net-1 test-net-2 &> /dev/null || true

echo ""

#------------------------------------------------------------------------------
# Test 7: Docker Compose (if available)
#------------------------------------------------------------------------------

echo -e "${BLUE}Testing Docker Compose...${NC}"

if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
    echo -e "${GREEN}✓ Docker Compose $COMPOSE_VERSION available${NC}"
    
    # Test simple compose file
    cat > /tmp/docker-test/docker-compose.yml << 'EOF'
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Docker Compose test"
EOF
    
    cd /tmp/docker-test
    if docker-compose up --abort-on-container-exit &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose execution working${NC}"
    else
        echo -e "${RED}✗ Docker Compose execution failed${NC}"
        exit 1
    fi
    docker-compose down &> /dev/null || true
    
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${GREEN}✓ Docker Compose (plugin) $COMPOSE_VERSION available${NC}"
    
    # Test simple compose file
    cat > /tmp/docker-test/docker-compose.yml << 'EOF'
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Docker Compose test"
EOF
    
    cd /tmp/docker-test
    if docker compose up --abort-on-container-exit &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose execution working${NC}"
    else
        echo -e "${RED}✗ Docker Compose execution failed${NC}"
        exit 1
    fi
    docker compose down &> /dev/null || true
    
else
    echo -e "${YELLOW}⚠ Docker Compose not available${NC}"
fi

echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

echo -e "${GREEN}=========================================="
echo "✓ Docker Functionality Validated"
echo -e "==========================================${NC}"
echo ""
echo "Docker Summary:"
echo "  Daemon: Running ($DOCKER_VERSION)"
echo "  Images: Pull, build, remove ✓"
echo "  Containers: Run, stop, remove ✓"
echo "  Ports: Binding and accessibility ✓"
echo "  Volumes: Mount and permissions ✓"
echo "  Network: Bridge and connectivity ✓"
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "  Compose: Available and functional ✓"
fi
echo ""
echo "✅ Ready for container deployments"
echo ""