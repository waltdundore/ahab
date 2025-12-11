#!/bin/bash
# ==============================================================================
# Nested Test Common Functions
# ==============================================================================
# Shared functions for nested test environment setup
# ==============================================================================

# ==============================================================================
# Prerequisite Checking
# ==============================================================================

check_prerequisites() {
    print_section "PREREQUISITE CHECKS"
    
    local errors=0
    
    # Check for required tools
    local required_tools=(
        "vagrant"
        "VBoxManage"
        "git"
    )
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "Found: $tool"
        else
            print_error "Missing required tool: $tool"
            ((errors++))
        fi
    done
    
    # Check VirtualBox version
    if command -v VBoxManage >/dev/null 2>&1; then
        local vbox_version
        vbox_version=$(VBoxManage --version 2>/dev/null | cut -d'r' -f1)
        print_info "VirtualBox version: $vbox_version"
    fi
    
    # Check Vagrant version
    if command -v vagrant >/dev/null 2>&1; then
        local vagrant_version
        vagrant_version=$(vagrant --version | cut -d' ' -f2)
        print_info "Vagrant version: $vagrant_version"
    fi
    
    # Check available memory
    local available_memory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_memory=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        available_memory=$(free -g | awk '/^Mem:/{print $2}')
    fi
    
    print_info "Available memory: ${available_memory}GB"
    
    if [ "$available_memory" -lt 8 ]; then
        print_warning "Less than 8GB RAM available - nested VMs may be slow"
    fi
    
    return $errors
}

# ==============================================================================
# Directory Structure Creation
# ==============================================================================

create_test_directory_structure() {
    local test_dir="$1"
    
    print_section "CREATING TEST DIRECTORY STRUCTURE"
    
    # Create main test directory
    if [ ! -d "$test_dir" ]; then
        mkdir -p "$test_dir"
        print_success "Created test directory: $test_dir"
    else
        print_info "Test directory already exists: $test_dir"
    fi
    
    # Create subdirectories
    local subdirs=(
        "fedora-test"
        "debian-test"
        "shared"
        "results"
    )
    
    for subdir in "${subdirs[@]}"; do
        local full_path="$test_dir/$subdir"
        if [ ! -d "$full_path" ]; then
            mkdir -p "$full_path"
            print_success "Created: $subdir/"
        else
            print_info "Already exists: $subdir/"
        fi
    done
}

# ==============================================================================
# Vagrantfile Generation
# ==============================================================================

# Generate Fedora provisioning script
generate_fedora_provision_script() {
    local test_dir="$1"
    local provision_script="$test_dir/fedora-test/provision.sh"
    
    cat > "$provision_script" << 'EOF'
#!/bin/bash
# Update system
dnf update -y

# Install required packages
dnf install -y git curl wget vim

# Install Docker
dnf install -y docker docker-compose
systemctl enable --now docker
usermod -aG docker vagrant

# Install Vagrant and VirtualBox for nested testing
dnf install -y vagrant VirtualBox

# Clone Ahab
if [ ! -d "/home/vagrant/ahab" ]; then
  cd /home/vagrant
  git clone https://github.com/waltdundore/ahab.git
  chown -R vagrant:vagrant ahab
fi

echo "Fedora test environment ready!"
EOF
    
    chmod +x "$provision_script"
}

generate_fedora_vagrantfile() {
    local test_dir="$1"
    local vagrantfile="$test_dir/fedora-test/Vagrantfile"
    
    print_info "Generating Fedora Vagrantfile..."
    
    # Generate provisioning script first
    generate_fedora_provision_script "$test_dir"
    
    cat > "$vagrantfile" << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/fedora-39"
  config.vm.hostname = "fedora-test"
  
  # Network configuration
  config.vm.network "private_network", type: "dhcp"
  
  # VM configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ahab-fedora-test"
    vb.memory = "2048"
    vb.cpus = 2
    
    # Enable nested virtualization
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ["modifyvm", :id, "--vtxux", "on"]
  end
  
  # Shared folder
  config.vm.synced_folder "../shared", "/vagrant_shared"
  
  # Provisioning
  config.vm.provision "shell", path: "provision.sh"
end
EOF
    
    print_success "Generated: fedora-test/Vagrantfile"
}

# Generate Debian provisioning script
generate_debian_provision_script() {
    local test_dir="$1"
    local provision_script="$test_dir/debian-test/provision.sh"
    
    cat > "$provision_script" << 'EOF'
#!/bin/bash
# Update system
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y git curl wget vim

# Install Docker
apt-get install -y docker.io docker-compose
systemctl enable --now docker
usermod -aG docker vagrant

# Install Vagrant and VirtualBox for nested testing
apt-get install -y vagrant virtualbox

# Clone Ahab
if [ ! -d "/home/vagrant/ahab" ]; then
  cd /home/vagrant
  git clone https://github.com/waltdundore/ahab.git
  chown -R vagrant:vagrant ahab
fi

echo "Debian test environment ready!"
EOF
    
    chmod +x "$provision_script"
}

generate_debian_vagrantfile() {
    local test_dir="$1"
    local vagrantfile="$test_dir/debian-test/Vagrantfile"
    
    print_info "Generating Debian Vagrantfile..."
    
    # Generate provisioning script first
    generate_debian_provision_script "$test_dir"
    
    cat > "$vagrantfile" << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"
  config.vm.hostname = "debian-test"
  
  # Network configuration
  config.vm.network "private_network", type: "dhcp"
  
  # VM configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ahab-debian-test"
    vb.memory = "2048"
    vb.cpus = 2
    
    # Enable nested virtualization
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ["modifyvm", :id, "--vtxux", "on"]
  end
  
  # Shared folder
  config.vm.synced_folder "../shared", "/vagrant_shared"
  
  # Provisioning
  config.vm.provision "shell", path: "provision.sh"
end
EOF
    
    print_success "Generated: debian-test/Vagrantfile"
}

# ==============================================================================
# Test Scripts Generation
# ==============================================================================

generate_test_scripts() {
    local test_dir="$1"
    
    print_section "GENERATING TEST SCRIPTS"
    
    # Generate run-tests.sh
    local run_tests_script="$test_dir/run-tests.sh"
    cat > "$run_tests_script" << 'EOF'
#!/bin/bash
# Automated test runner for Ahab nested testing

set -euo pipefail

echo "=========================================="
echo "Ahab Nested Test Runner"
echo "=========================================="

# Test Fedora
echo "Testing on Fedora..."
cd fedora-test
vagrant up
vagrant ssh -c "cd ahab && make test"
vagrant halt

# Test Debian
echo "Testing on Debian..."
cd ../debian-test
vagrant up
vagrant ssh -c "cd ahab && make test"
vagrant halt

echo "All tests completed!"
EOF
    
    chmod +x "$run_tests_script"
    print_success "Generated: run-tests.sh"
    
    # Generate cleanup script
    local cleanup_script="$test_dir/cleanup.sh"
    cat > "$cleanup_script" << 'EOF'
#!/bin/bash
# Cleanup script for Ahab nested testing

set -euo pipefail

echo "Cleaning up nested test environment..."

# Destroy VMs
cd fedora-test && vagrant destroy -f
cd ../debian-test && vagrant destroy -f

echo "Cleanup completed!"
EOF
    
    chmod +x "$cleanup_script"
    print_success "Generated: cleanup.sh"
}

# ==============================================================================
# Documentation Generation
# ==============================================================================

# Generate documentation header
generate_doc_header() {
    local readme="$1"
    
    cat > "$readme" << EOF
# Ahab Nested Testing Environment

This directory contains a nested testing environment for Ahab that allows you to test Ahab's VM creation capabilities on different operating systems.

## Structure

- \`fedora-test/\` - Fedora test environment
- \`debian-test/\` - Debian test environment  
- \`shared/\` - Shared files between test environments
- \`results/\` - Test results and logs
- \`run-tests.sh\` - Automated test runner
- \`cleanup.sh\` - Environment cleanup script

## Prerequisites

- VirtualBox with nested virtualization support
- Vagrant
- At least 8GB RAM (16GB recommended)
- 20GB free disk space
EOF
}

# Generate usage instructions
generate_usage_instructions() {
    local readme="$1"
    
    cat >> "$readme" << EOF

## Usage

### Manual Testing

1. Start a test environment:
   \`\`\`bash
   cd fedora-test
   vagrant up
   vagrant ssh
   \`\`\`

2. Inside the VM, test Ahab:
   \`\`\`bash
   cd ahab
   make test
   make install
   \`\`\`

3. Clean up:
   \`\`\`bash
   exit
   vagrant destroy -f
   \`\`\`

### Automated Testing

Run all tests automatically:
\`\`\`bash
./run-tests.sh
\`\`\`
EOF
}

# Generate troubleshooting section
generate_troubleshooting_section() {
    local readme="$1"
    
    cat >> "$readme" << EOF

## Troubleshooting

### Nested Virtualization Issues

If you encounter errors about nested virtualization:

1. Enable nested virtualization in your host BIOS/UEFI
2. For Intel CPUs: Enable VT-x and VT-d
3. For AMD CPUs: Enable AMD-V and IOMMU
4. Verify with: \`egrep -c '(vmx|svm)' /proc/cpuinfo\`

### Memory Issues

If VMs fail to start due to memory:

1. Reduce VM memory in Vagrantfiles (default: 2048MB)
2. Close other applications
3. Consider testing one OS at a time

### Disk Space Issues

If you run out of disk space:

1. Run \`./cleanup.sh\` to remove test VMs
2. Run \`vagrant box prune\` to remove old boxes
3. Clear Docker images: \`docker system prune -a\`

## Results

Test results are saved in the \`results/\` directory:

- \`fedora-results.log\` - Fedora test output
- \`debian-results.log\` - Debian test output
- \`test-summary.txt\` - Overall test summary

EOF
}

generate_test_documentation() {
    local test_dir="$1"
    
    print_info "Generating test documentation..."
    
    local readme="$test_dir/README.md"
    
    # Generate documentation sections
    generate_doc_header "$readme"
    generate_usage_instructions "$readme"
    generate_troubleshooting_section "$readme"

### Cleanup

Remove all test VMs:
\`\`\`bash
./cleanup.sh
\`\`\`

## Notes

- Each test VM has nested virtualization enabled
- Ahab is automatically cloned in each test environment
- Test results are saved to the \`results/\` directory
- VMs are configured with 2GB RAM and 2 CPUs each

## Troubleshooting

If you encounter issues:

1. Ensure nested virtualization is enabled in your BIOS
2. Check that VirtualBox supports nested virtualization
3. Verify you have sufficient RAM and disk space
4. Check the Vagrant logs for detailed error messages

Generated: $(date)
EOF
    
    print_success "Generated: README.md"
}

# ==============================================================================
# Summary and Instructions
# ==============================================================================

print_setup_summary() {
    local test_dir="$1"
    
    print_header "SETUP COMPLETE"
    
    echo "Nested test environment created at: $test_dir"
    echo ""
    echo "Next steps:"
    echo "  1. cd $test_dir"
    echo "  2. ./run-tests.sh    # Run automated tests"
    echo "  3. ./cleanup.sh      # Clean up when done"
    echo ""
    echo "Manual testing:"
    echo "  cd $test_dir/fedora-test && vagrant up && vagrant ssh"
    echo "  cd $test_dir/debian-test && vagrant up && vagrant ssh"
    echo ""
    echo "See README.md for detailed instructions."
}