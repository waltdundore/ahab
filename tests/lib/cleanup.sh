#!/usr/bin/env bash
# Library file - sourced by tests, no cleanup needed
# ==============================================================================
# Test Cleanup Functions
# ==============================================================================
# Idempotent cleanup - safe to run multiple times
# ==============================================================================

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Cleanup test VMs (idempotent)
cleanup_test_vms() {
    print_info "Cleaning up test VMs..."
    
    # Destroy any running VMs (safe if none exist)
    vagrant destroy -f 2>/dev/null || true
    
    # Remove .vagrant directory (safe if doesn't exist)
    rm -rf .vagrant 2>/dev/null || true
    
    print_success "VM cleanup complete"
}

# Cleanup Docker containers (idempotent)
cleanup_docker_containers() {
    local prefix="${1:-ahab-test}"
    
    print_info "Cleaning up Docker containers with prefix '$prefix'..."
    
    # Stop and remove containers (safe if none exist)
    docker ps -a --filter "name=$prefix" -q | xargs -r docker stop 2>/dev/null || true
    docker ps -a --filter "name=$prefix" -q | xargs -r docker rm 2>/dev/null || true
    
    print_success "Docker cleanup complete"
}

# Cleanup temp files (idempotent)
cleanup_temp_files() {
    local pattern="${1:-/tmp/ahab-test-*}"
    
    print_info "Cleaning up temp files..."
    
    # Remove temp files (safe if none exist)
    rm -rf $pattern 2>/dev/null || true
    
    print_success "Temp file cleanup complete"
}

# Complete cleanup (idempotent)
cleanup_all() {
    print_info "Running complete cleanup..."
    
    cleanup_test_vms
    cleanup_docker_containers
    cleanup_temp_files
    
    print_success "All cleanup complete - tests can be run again"
}
