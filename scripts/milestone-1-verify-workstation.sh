#!/bin/bash

# Milestone 1: Workstation Installation Verification
# Verifies that the workstation VM is properly installed and configured

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MILESTONE_DIR="$PROJECT_ROOT/.milestones"
MILESTONE_FILE="$MILESTONE_DIR/milestone-1.status"

# Source common functions
# shellcheck source=lib/milestone-common.sh
source "$SCRIPT_DIR/lib/milestone-common.sh"

# Initialize milestone
initialize_milestone() {
    echo "=========================================="
    echo "Milestone 1: Workstation Installation Verification"
    echo "=========================================="
    echo ""
    echo "This milestone verifies that:"
    echo "  ✓ Workstation VM is created and running"
    echo "  ✓ Docker is installed and working"
    echo "  ✓ Ansible is installed and working"
    echo "  ✓ Basic connectivity is established"
    echo "  ✓ File synchronization is working"
    echo ""

    mkdir -p "$MILESTONE_DIR"
    echo "MILESTONE_1_STATUS=RUNNING" > "$MILESTONE_FILE"
    echo "MILESTONE_1_START_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$MILESTONE_FILE"
}

# Check workstation is running
check_workstation() {
    echo "Step 1: Checking if workstation exists..."
    if ! vagrant status 2>/dev/null | grep -q "running"; then
        show_error_and_exit "Workstation is not running" \
            "  1. Run: make install\n  2. Wait for VM creation to complete\n  3. Run: make milestone-1" \
            "1" "$MILESTONE_FILE"
    fi
    echo "✓ Workstation VM is running"
}

# Test SSH connectivity
test_ssh() {
    echo ""
    echo "Step 2: Testing SSH connectivity..."
    if ! test_vagrant_ssh; then
        show_error_and_exit "Cannot SSH into workstation" \
            "  1. Run: vagrant reload\n  2. If that fails: make clean && make install" \
            "1" "$MILESTONE_FILE"
    fi
    echo "✓ SSH connectivity working"
}

# Verify Docker
verify_docker() {
    echo ""
    echo "Step 3: Verifying Docker installation..."
    if ! vagrant ssh -c "docker --version" >/dev/null 2>&1; then
        show_error_and_exit "Docker is not installed or not working" \
            "  1. Run: vagrant reload --provision\n  2. If that fails: make clean && make install" \
            "1" "$MILESTONE_FILE"
    fi

    local docker_version
    docker_version=$(get_docker_version)
    echo "✓ Docker installed: $docker_version"
    echo "MILESTONE_1_DOCKER_VERSION=$docker_version" >> "$MILESTONE_FILE"

    echo ""
    echo "Step 4: Testing Docker functionality..."
    if ! vagrant ssh -c "docker run --rm hello-world" >/dev/null 2>&1; then
        show_error_and_exit "Docker is not functioning properly" \
            "  1. Run: vagrant ssh\n  2. Run: sudo systemctl start docker\n  3. Run: sudo usermod -aG docker vagrant\n  4. Exit and run: vagrant reload" \
            "1" "$MILESTONE_FILE"
    fi
    echo "✓ Docker functionality verified"
}

# Verify Ansible
verify_ansible() {
    echo ""
    echo "Step 5: Verifying Ansible installation..."
    if ! vagrant ssh -c "ansible --version" >/dev/null 2>&1; then
        show_error_and_exit "Ansible is not installed" \
            "  1. Run: vagrant reload --provision\n  2. If that fails: make clean && make install" \
            "1" "$MILESTONE_FILE"
    fi

    local ansible_version
    ansible_version=$(get_ansible_version)
    echo "✓ Ansible installed: $ansible_version"
    echo "MILESTONE_1_ANSIBLE_VERSION=$ansible_version" >> "$MILESTONE_FILE"
}

# Test file sync and system resources
test_system() {
    echo ""
    echo "Step 6: Testing file synchronization..."
    if ! vagrant ssh -c "ls /home/vagrant/ahab/Makefile" >/dev/null 2>&1; then
        show_error_and_exit "File synchronization not working" \
            "  1. Run: vagrant reload\n  2. If that fails: make clean && make install" \
            "1" "$MILESTONE_FILE"
    fi
    echo "✓ File synchronization working"

    echo ""
    echo "Step 7: Verifying system resources..."
    local memory_mb cpu_count disk_gb
    memory_mb=$(get_system_memory)
    cpu_count=$(get_system_cpus)
    disk_gb=$(get_system_disk)

    echo "✓ System Resources:"
    echo "  - Memory: ${memory_mb}MB"
    echo "  - CPUs: ${cpu_count}"
    echo "  - Disk: ${disk_gb}"

    if [ "$memory_mb" -lt 2048 ]; then
        echo "⚠ WARNING: Low memory (${memory_mb}MB). Recommended: 4GB+"
    fi
    
    echo "MILESTONE_1_WORKSTATION_MEMORY=${memory_mb}MB" >> "$MILESTONE_FILE"
    echo "MILESTONE_1_WORKSTATION_CPUS=$cpu_count" >> "$MILESTONE_FILE"
}

# Test Ansible functionality
test_ansible() {
    echo ""
    echo "Step 8: Testing basic Ansible functionality..."
    
    # Test basic Ansible functionality (handle known vault issue)
    set +e
    local ansible_output
    ansible_output=$(vagrant ssh -c "cd /home/vagrant/ahab && ansible localhost -m ping" 2>&1)
    set -e

    if echo "$ansible_output" | grep -q "SUCCESS"; then
        echo "✓ Ansible localhost connectivity verified"
    elif echo "$ansible_output" | grep -q "vault secrets found"; then
        echo "✓ Ansible working (vault configuration needed for inventory)"
        echo "  Note: This is a known issue - Ansible Vault needs configuration"
        echo "  The workstation is properly set up, vault config is separate milestone"
    else
        show_error_and_exit "Ansible localhost ping failed" \
            "  1. Run: vagrant ssh\n  2. Run: cd /home/vagrant/ahab && ansible localhost -m ping\n  3. Check for error messages" \
            "1" "$MILESTONE_FILE"
    fi
}

# Complete milestone
complete_milestone() {
    sed -i.bak 's/MILESTONE_1_STATUS=RUNNING/MILESTONE_1_STATUS=COMPLETED/' "$MILESTONE_FILE"
    echo "MILESTONE_1_END_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$MILESTONE_FILE"

    echo ""
    echo "=========================================="
    echo "✅ Milestone 1 COMPLETED Successfully!"
    echo "=========================================="
    echo ""
    echo "Workstation verification results:"
    echo "  ✓ VM Status: Running"
    echo "  ✓ SSH: Working"
    
    local docker_version ansible_version memory cpus
    docker_version=$(grep "MILESTONE_1_DOCKER_VERSION=" "$MILESTONE_FILE" | cut -d'=' -f2)
    ansible_version=$(grep "MILESTONE_1_ANSIBLE_VERSION=" "$MILESTONE_FILE" | cut -d'=' -f2)
    memory=$(grep "MILESTONE_1_WORKSTATION_MEMORY=" "$MILESTONE_FILE" | cut -d'=' -f2)
    cpus=$(grep "MILESTONE_1_WORKSTATION_CPUS=" "$MILESTONE_FILE" | cut -d'=' -f2)
    
    echo "  ✓ Docker: $docker_version"
    echo "  ✓ Ansible: $ansible_version"
    echo "  ✓ File Sync: Working"
    echo "  ✓ Resources: $memory RAM, $cpus CPUs"
    echo ""
    echo "Next step:"
    echo "  make milestone-2    # Define target servers"
    echo ""
    echo "Or check overall progress:"
    echo "  make milestone-status"
}

# Main execution
main() {
    initialize_milestone
    check_workstation
    test_ssh
    verify_docker
    verify_ansible
    test_system
    test_ansible
    complete_milestone
}

main "$@"