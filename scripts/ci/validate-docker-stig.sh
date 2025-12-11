#!/usr/bin/env bash
# ==============================================================================
# Docker STIG Compliance Validation
# ==============================================================================
# Validates Docker containers and configurations against STIG requirements
#
# STIG Requirements Validated:
#   - STIG-DKER-EE-001010: Containers must not run as root
#   - STIG-DKER-EE-003010: Security options must be configured
#   - STIG-DKER-EE-003020: Resource limits must be set
#   - STIG-DKER-EE-003030: No privileged containers
#   - STIG-DKER-EE-004010: Network segmentation required
#
# Usage:
#   ./validate-docker-stig.sh [path]
#
# Exit Codes:
#   0 - All STIG requirements met
#   1 - One or more STIG violations found
# ==============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Path to check (default to project root)
CHECK_PATH="${1:-$PROJECT_ROOT}"

print_section "Docker STIG Compliance Validation"
print_info "Checking: $CHECK_PATH"
echo ""

# ==============================================================================
# STIG-DKER-EE-001010: Containers Must Not Run as Root
# ==============================================================================

print_subsection "STIG-DKER-EE-001010: Non-Root Container Check"

# Check Dockerfiles for USER directive
while IFS= read -r -d '' dockerfile; do
    increment_check
    
    if ! grep -q "^USER " "$dockerfile"; then
        print_error "Dockerfile missing USER directive: $dockerfile"
        echo "  STIG Violation: STIG-DKER-EE-001010"
        echo "  Requirement: Containers must run as non-root user"
        echo "  Fix: Add USER directive before CMD/ENTRYPOINT"
        echo "  Example:"
        echo "    RUN adduser -D -u 1000 appuser"
        echo "    USER appuser"
        echo ""
        increment_error
    else
        # Check if USER is set to root
        if grep -q "^USER root\|^USER 0" "$dockerfile"; then
            print_error "Dockerfile explicitly sets USER to root: $dockerfile"
            echo "  STIG Violation: STIG-DKER-EE-001010"
            echo "  Requirement: Containers must run as non-root user"
            echo "  Fix: Change USER to non-root user (UID >= 1000)"
            echo ""
            increment_error
        else
            print_success "$(basename "$dockerfile"): Non-root user configured"
        fi
    fi
done < <(find "$CHECK_PATH" -name "Dockerfile*" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-DKER-EE-003010: Security Options Must Be Configured
# ==============================================================================

print_subsection "STIG-DKER-EE-003010: Security Options Check"

# Check docker-compose files for security_opt
while IFS= read -r -d '' compose_file; do
    increment_check
    
    # Check for security_opt
    if ! grep -q "security_opt:" "$compose_file"; then
        print_error "Missing security_opt in: $compose_file"
        echo "  STIG Violation: STIG-DKER-EE-003010"
        echo "  Requirement: Containers must use security hardening options"
        echo "  Fix: Add security_opt to all services"
        echo "  Example:"
        echo "    security_opt:"
        echo "      - no-new-privileges:true"
        echo "      - seccomp:default"
        echo ""
        increment_error
    else
        # Check for required security options
        if ! grep -A2 "security_opt:" "$compose_file" | grep -q "no-new-privileges:true"; then
            print_error "Missing no-new-privileges in: $compose_file"
            echo "  STIG Violation: STIG-DKER-EE-003010"
            echo "  Requirement: Must prevent privilege escalation"
            echo ""
            increment_error
        else
            print_success "$(basename "$compose_file"): Security options configured"
        fi
    fi
    
    # Check for cap_drop
    if ! grep -q "cap_drop:" "$compose_file"; then
        print_warning "Missing cap_drop in: $compose_file"
        echo "  Recommendation: Drop all capabilities, add only needed ones"
        echo "  Example:"
        echo "    cap_drop:"
        echo "      - ALL"
        echo "    cap_add:"
        echo "      - NET_BIND_SERVICE"
        echo ""
        increment_warning
    fi
done < <(find "$CHECK_PATH" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-DKER-EE-003020: Resource Limits Must Be Set
# ==============================================================================

print_subsection "STIG-DKER-EE-003020: Resource Limits Check"

# Check docker-compose files for resource limits
while IFS= read -r -d '' compose_file; do
    increment_check
    
    if ! grep -q "resources:" "$compose_file"; then
        print_error "Missing resource limits in: $compose_file"
        echo "  STIG Violation: STIG-DKER-EE-003020"
        echo "  Requirement: Containers must have CPU and memory limits"
        echo "  Fix: Add deploy.resources section"
        echo "  Example:"
        echo "    deploy:"
        echo "      resources:"
        echo "        limits:"
        echo "          cpus: '0.5'"
        echo "          memory: 512M"
        echo ""
        increment_error
    else
        # Check for both CPU and memory limits
        if ! grep -A5 "resources:" "$compose_file" | grep -q "cpus:"; then
            print_error "Missing CPU limits in: $compose_file"
            echo "  STIG Violation: STIG-DKER-EE-003020"
            echo ""
            increment_error
        fi
        
        if ! grep -A5 "resources:" "$compose_file" | grep -q "memory:"; then
            print_error "Missing memory limits in: $compose_file"
            echo "  STIG Violation: STIG-DKER-EE-003020"
            echo ""
            increment_error
        fi
        
        if grep -A5 "resources:" "$compose_file" | grep -q "cpus:" && \
           grep -A5 "resources:" "$compose_file" | grep -q "memory:"; then
            print_success "$(basename "$compose_file"): Resource limits configured"
        fi
    fi
done < <(find "$CHECK_PATH" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-DKER-EE-003030: No Privileged Containers
# ==============================================================================

print_subsection "STIG-DKER-EE-003030: Privileged Container Check"

# Check for privileged: true
while IFS= read -r -d '' compose_file; do
    increment_check
    
    if grep -q "privileged:[[:space:]]*true" "$compose_file"; then
        print_error "Privileged container found in: $compose_file"
        echo "  STIG Violation: STIG-DKER-EE-003030"
        echo "  Requirement: Containers must not run in privileged mode"
        echo "  Fix: Remove 'privileged: true' or use specific capabilities"
        echo ""
        increment_error
    else
        print_success "$(basename "$compose_file"): No privileged containers"
    fi
done < <(find "$CHECK_PATH" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -type f -print0 2>/dev/null)

# ==============================================================================
# STIG-DKER-EE-004010: Network Segmentation
# ==============================================================================

print_subsection "STIG-DKER-EE-004010: Network Segmentation Check"

# Check for custom networks (not default bridge)
while IFS= read -r -d '' compose_file; do
    increment_check
    
    if grep -q "^networks:" "$compose_file"; then
        print_success "$(basename "$compose_file"): Custom networks defined"
    else
        print_warning "No custom networks in: $compose_file"
        echo "  Recommendation: Use custom networks for isolation"
        echo "  Example:"
        echo "    networks:"
        echo "      frontend:"
        echo "        driver: bridge"
        echo "      backend:"
        echo "        driver: bridge"
        echo "        internal: true"
        echo ""
        increment_warning
    fi
done < <(find "$CHECK_PATH" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -type f -print0 2>/dev/null)

# ==============================================================================
# Summary
# ==============================================================================

echo ""
print_section "Docker STIG Compliance Summary"

if [ "$ERRORS" -eq 0 ]; then
    print_success "All Docker STIG requirements met"
    echo ""
    echo "Validated:"
    echo "  ✓ STIG-DKER-EE-001010: Non-root containers"
    echo "  ✓ STIG-DKER-EE-003010: Security options configured"
    echo "  ✓ STIG-DKER-EE-003020: Resource limits set"
    echo "  ✓ STIG-DKER-EE-003030: No privileged containers"
    echo "  ✓ STIG-DKER-EE-004010: Network segmentation"
    echo ""
    exit 0
else
    print_error "$ERRORS STIG violation(s) found"
    echo ""
    echo "Failed Requirements:"
    [ "$ERRORS" -gt 0 ] && echo "  ✗ $ERRORS critical violation(s)"
    [ "$WARNINGS" -gt 0 ] && echo "  ⚠ $WARNINGS warning(s)"
    echo ""
    echo "See ahab/docs/DOCKER_STIG_COMPLIANCE.md for remediation guidance"
    echo ""
    exit 1
fi
