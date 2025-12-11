#!/usr/bin/env bash
# ==============================================================================
# Workstation Integration Test
# ==============================================================================
# Tests workstation VM creation, provisioning, and tool installation
#
# Usage:
#   make test-integration  # Runs this test
#   bash tests/integration/test-workstation.sh  # Direct execution
#
# Success criteria:
#   - VM starts successfully
#   - Prerequisites installed (Git, Ansible, Vagrant, VirtualBox)
#   - Repositories cloned
#   - Bootstrap completed
#
# NASA Power of 10 Compliance:
#   - Bounded loops with timeouts
#   - All returns checked
#   - Functions ≤60 lines
#   - Minimum 2 assertions per function
#   - Idempotent cleanup
# ==============================================================================

set -euo pipefail

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"
source "$SCRIPT_DIR/../lib/assertions.sh"
source "$SCRIPT_DIR/../lib/cleanup.sh"
source "$SCRIPT_DIR/../lib/test-config.sh"

# Test configuration
readonly TEST_NAME="test-workstation"

# Cleanup on exit (idempotent)
trap cleanup_on_exit EXIT

main() {
    print_info "=========================================="
    print_info "Workstation Integration Test"
    print_info "=========================================="
    echo ""
    
    check_prerequisites || exit 1
    cleanup_before_test || exit 1
    start_workstation || exit 1
    verify_installation || exit 1
    
    print_success "=========================================="
    print_success "Workstation Test PASSED"
    print_success "=========================================="
    exit 0
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # NASA Rule 5: Min 2 assertions
    if ! check_vagrant; then
        echo ""
        print_info "No worries - this is a one-time setup."
        print_info "Takes about 2 minutes to install."
        return 1
    fi
    
    if ! check_virtualbox; then
        echo ""
        print_info "One more thing - we need VirtualBox to run VMs."
        print_info "This is the last prerequisite, I promise."
        return 1
    fi
    
    print_success "All prerequisites installed"
    return 0
}

cleanup_before_test() {
    print_info "Cleaning up any existing test VMs..."
    
    # Idempotent cleanup
    if vagrant status 2>/dev/null | grep -q "running\|poweroff"; then
        print_info "Found existing VM, removing it..."
        vagrant destroy -f 2>/dev/null || true
    fi
    
    print_success "Clean state ready"
    return 0
}

start_workstation() {
    print_info "Starting workstation VM..."
    print_info "This usually takes 10-15 minutes for first-time setup."
    echo ""
    
    # NASA Rule 7: Check return
    # NASA Rule 2: Bounded operation with timeout
    if ! SKIP_MULTI_TEST=true VAGRANT_VAGRANTFILE=Vagrantfile.workstation vagrant_with_timeout 600 up; then
        print_error "VM failed to start"
        echo ""
        print_info "This is frustrating, I know. Let's figure this out together."
        print_info ""
        print_info "Common causes:"
        print_info "  • VirtualBox might not be running"
        print_info "  • Not enough disk space"
        print_info "  • Network connectivity issues"
        print_info ""
        print_info "Try these steps:"
        print_info "  1. Check VirtualBox: VBoxManage --version"
        print_info "  2. Check disk space: df -h"
        print_info "  3. Try again: vagrant destroy -f && vagrant up"
        print_info "  4. Debug mode: vagrant up --debug"
        print_info ""
        print_info "Still stuck? Ask for help - include the output above."
        return 1
    fi
    
    print_success "VM started successfully"
    return 0
}

verify_installation() {
    print_info "Verifying workstation setup..."
    echo ""
    
    # NASA Rule 5: Multiple assertions
    print_info "Checking installed tools..."
    
    if ! vagrant ssh -c "git --version" >/dev/null 2>&1; then
        print_error "Git not installed in VM"
        print_info "The bootstrap script may have failed."
        return 1
    fi
    print_success "Git installed"
    
    if ! vagrant ssh -c "ansible --version" >/dev/null 2>&1; then
        print_error "Ansible not installed in VM"
        print_info "The bootstrap script may have failed."
        return 1
    fi
    print_success "Ansible installed"
    
    if ! vagrant ssh -c "vagrant --version" >/dev/null 2>&1; then
        print_error "Vagrant not installed in VM"
        print_info "The bootstrap script may have failed."
        return 1
    fi
    print_success "Vagrant installed"
    
    if ! vagrant ssh -c "VBoxManage --version" >/dev/null 2>&1; then
        print_error "VirtualBox not installed in VM"
        print_info "The bootstrap script may have failed."
        return 1
    fi
    print_success "VirtualBox installed"
    
    echo ""
    print_info "Checking cloned repositories..."
    
    if ! vagrant ssh -c "test -d ~/git/ahab" 2>/dev/null; then
        print_error "ahab repository not cloned"
        return 1
    fi
    print_success "ahab cloned"
    
    if ! vagrant ssh -c "test -d ~/git/ansible-config" 2>/dev/null; then
        print_error "ansible-config repository not cloned"
        return 1
    fi
    print_success "ansible-config cloned"
    
    if ! vagrant ssh -c "test -d ~/git/ansible-inventory" 2>/dev/null; then
        print_error "ansible-inventory repository not cloned"
        return 1
    fi
    print_success "ansible-inventory cloned"
    
    echo ""
    print_success "All verifications passed"
    return 0
}

cleanup_on_exit() {
    print_info "Cleaning up test resources..."
    
    # Idempotent cleanup
    vagrant destroy -f 2>/dev/null || true
    rm -rf .vagrant 2>/dev/null || true
    
    print_success "Cleanup complete - test can be run again"
}

# Run main
main "$@"
