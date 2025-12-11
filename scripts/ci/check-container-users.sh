#!/usr/bin/env bash
# ==============================================================================
# Root Container Detection Check
# ==============================================================================
# Validates that no containers run as root user
# 
# Requirements: 3.5
# Property: 13 - Root container detection
# ==============================================================================

set -euo pipefail

# Get script directory for sourcing common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Path to check (default to current directory)
CHECK_PATH="${1:-.}"

print_section "Root Container Detection Check"
print_info "Checking for containers running as root in: $CHECK_PATH"
echo ""

# Find all Dockerfiles
while IFS= read -r -d '' dockerfile; do
    increment_check
    
    # Check if Dockerfile has USER directive
    if ! grep -q "^USER " "$dockerfile"; then
        print_error "Dockerfile missing USER directive: $dockerfile"
        echo "  Rule Violated: Security Best Practice (No Root Containers)"
        echo "  Problem: Dockerfile doesn't specify a non-root user"
        echo "  Fix: Add USER directive to run container as non-root"
        echo "  Example:"
        echo "    # Add before CMD/ENTRYPOINT"
        echo "    RUN useradd -m -u 1000 appuser"
        echo "    USER appuser"
        echo ""
        increment_error
    else
        # Check if USER is set to root (by name or UID 0)
        if grep -q "^USER root\|^USER 0\|^USER 0:" "$dockerfile"; then
            print_error "Dockerfile explicitly sets USER to root: $dockerfile"
            echo "  Rule Violated: Security Best Practice (No Root Containers)"
            echo "  Problem: Container explicitly runs as root user"
            echo "  Fix: Change USER to non-root user"
            echo "  Example:"
            echo "    # Before"
            echo "    USER root  (or USER 0)"
            echo ""
            echo "    # After"
            echo "    RUN useradd -m -u 1000 appuser"
            echo "    USER appuser"
            echo ""
            increment_error
        fi
    fi
done < <(find "$CHECK_PATH" -name "Dockerfile*" -type f -print0 2>/dev/null)

# Find all docker-compose files
while IFS= read -r -d '' compose_file; do
    increment_check
    
    # Check for user: root in docker-compose
    if grep -q "user:[[:space:]]*root\|user:[[:space:]]*0" "$compose_file"; then
        print_error "Docker Compose file specifies root user: $compose_file"
        echo "  Rule Violated: Security Best Practice (No Root Containers)"
        echo "  Problem: Service configured to run as root"
        echo "  Fix: Remove 'user: root' or change to non-root user"
        echo "  Example:"
        echo "    # Before"
        echo "    services:"
        echo "      app:"
        echo "        user: root"
        echo ""
        echo "    # After"
        echo "    services:"
        echo "      app:"
        echo "        user: \"1000:1000\""
        echo ""
        increment_error
    fi
    
    # Check for privileged: true
    if grep -q "privileged:[[:space:]]*true" "$compose_file"; then
        print_warning "Docker Compose file uses privileged mode: $compose_file"
        echo "  Consider: Privileged mode gives container root access to host"
        echo "  Only use if absolutely necessary for specific hardware access"
        echo ""
        increment_warning
    fi
done < <(find "$CHECK_PATH" -type f \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) -print0 2>/dev/null)

# Print summary
print_summary "Root Container Detection Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No containers configured to run as root"
fi

exit $exit_code
