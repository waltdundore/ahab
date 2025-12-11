#!/bin/bash
# Pre-Release Checklist - Docker Wrapper
# Runs pre-release-check.sh in Docker container for bash 4+ compatibility
#
# Usage: ./scripts/pre-release-check-docker.sh [OPTIONS]
#
# All options are passed through to pre-release-check.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Docker image name
IMAGE_NAME="ahab-pre-release-checker"
IMAGE_TAG="latest"

# Build Docker image if it doesn't exist
build_image() {
    echo "Building pre-release checker Docker image..."
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -f "$SCRIPT_DIR/validators/Dockerfile" \
        "$SCRIPT_DIR/validators/"
    echo "Image built successfully"
}

# Check if image exists
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    build_image
fi

# Run pre-release check in Docker
echo "Running pre-release check in Docker container..."
echo ""

docker run --rm \
    -v "$PROJECT_ROOT:/workspace" \
    -w /workspace \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    bash /workspace/scripts/pre-release-check.sh "$@"

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo "Pre-release check completed successfully"
else
    echo "Pre-release check failed"
fi

exit $exit_code
