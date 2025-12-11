#!/usr/bin/env bash
# ==============================================================================
# Dependency Vulnerability Scan
# ==============================================================================
# Scans dependencies for known vulnerabilities
# 
# Requirements: 3.4, 18.1, 18.2, 18.3
# Property: 40 - Dependency vulnerability detection
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

print_section "Dependency Vulnerability Scan"
print_info "Scanning dependencies for vulnerabilities in: $CHECK_PATH"
echo ""

# Check for Python dependencies
if [ -f "$CHECK_PATH/requirements.txt" ]; then
    print_info "Scanning Python dependencies..."
    increment_check
    
    # Install pip-audit if not available
    if ! command -v pip-audit >/dev/null 2>&1; then
        print_info "Installing pip-audit..."
        pip3 install pip-audit --break-system-packages 2>/dev/null || pip3 install pip-audit
    fi
    
    # Run pip-audit
    if pip-audit -r "$CHECK_PATH/requirements.txt" --desc --format json > /tmp/pip-audit.json 2>&1; then
        print_success "No vulnerabilities found in Python dependencies"
    else
        # Parse results
        if [ -f /tmp/pip-audit.json ]; then
            print_error "Vulnerabilities found in Python dependencies"
            cat /tmp/pip-audit.json
            increment_error
        else
            print_warning "pip-audit scan completed with warnings"
            increment_warning
        fi
    fi
fi

# Check for Node.js dependencies
if [ -f "$CHECK_PATH/package.json" ]; then
    print_info "Scanning Node.js dependencies..."
    increment_check
    
    if command -v npm >/dev/null 2>&1; then
        cd "$CHECK_PATH" || exit 1
        if npm audit --json > /tmp/npm-audit.json 2>&1; then
            print_success "No vulnerabilities found in Node.js dependencies"
        else
            print_error "Vulnerabilities found in Node.js dependencies"
            cat /tmp/npm-audit.json
            increment_error
        fi
        cd - >/dev/null || exit 1
    else
        print_warning "npm not installed, skipping Node.js dependency scan"
        increment_warning
    fi
fi

# Check for Docker images
while IFS= read -r -d '' dockerfile; do
    print_info "Scanning Docker image: $dockerfile"
    increment_check
    
    # Install trivy if not available
    if ! command -v trivy >/dev/null 2>&1; then
        print_info "Installing trivy..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y wget apt-transport-https gnupg lsb-release
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install -y trivy
        else
            print_warning "Cannot install trivy automatically, skipping Docker image scan"
            increment_warning
            continue
        fi
    fi
    
    # Extract base image from Dockerfile
    base_image=$(grep "^FROM " "$dockerfile" | head -1 | awk '{print $2}')
    
    if [ -n "$base_image" ]; then
        print_info "Scanning base image: $base_image"
        if trivy image --severity HIGH,CRITICAL "$base_image" > /tmp/trivy-scan.txt 2>&1; then
            print_success "No critical vulnerabilities in $base_image"
        else
            print_error "Vulnerabilities found in $base_image"
            cat /tmp/trivy-scan.txt
            increment_error
        fi
    fi
done < <(find "$CHECK_PATH" -name "Dockerfile*" -type f -print0 2>/dev/null)

# Print summary
print_summary "Dependency Vulnerability Scan"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No vulnerabilities found in dependencies"
fi

exit $exit_code
