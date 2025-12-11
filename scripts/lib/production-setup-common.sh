#!/bin/bash
# ==============================================================================
# Production Setup Common Functions
# ==============================================================================
# Shared functions for production credential setup
# ==============================================================================

# ==============================================================================
# User Validation Functions
# ==============================================================================

validate_admin_user() {
    local admin_user="$1"
    
    print_info "Validating admin user: $admin_user"
    
    # Check if user exists
    if ! id "$admin_user" &>/dev/null; then
        print_error "User '$admin_user' does not exist on this system"
        echo "Available users:"
        getent passwd | cut -d: -f1 | grep -v "^_" | sort
        return 1
    fi
    
    # Check if user has sudo access
    if ! sudo -l -U "$admin_user" &>/dev/null; then
        print_error "User '$admin_user' does not have sudo access"
        echo "To grant sudo access:"
        echo "  sudo usermod -aG sudo $admin_user  # Debian/Ubuntu"
        echo "  sudo usermod -aG wheel $admin_user # RHEL/Fedora"
        return 1
    fi
    
    print_success "User '$admin_user' validated successfully"
    return 0
}

setup_passwordless_sudo() {
    local admin_user="$1"
    
    print_info "Setting up passwordless sudo for $admin_user"
    
    if confirm_action "Configure passwordless sudo for $admin_user?"; then
        configure_passwordless_sudo "$admin_user" "$CONFIG_DIR"
    else
        print_info "Skipping passwordless sudo configuration"
        print_warning "You may need to enter passwords during playbook runs"
    fi
}

configure_passwordless_sudo() {
    local admin_user="$1"
    local config_dir="$2"
    
    local sudoers_file="/etc/sudoers.d/99-$admin_user-nopasswd"
    
    print_info "Creating sudoers file: $sudoers_file"
    
    # Create sudoers entry
    echo "$admin_user ALL=(ALL) NOPASSWD:ALL" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 440 "$sudoers_file"
    
    # Validate sudoers file
    if sudo visudo -c; then
        print_success "Passwordless sudo configured successfully"
        echo "You can now run playbooks without password prompts"
    else
        print_error "Sudoers file validation failed"
        sudo rm -f "$sudoers_file"
        echo "You will be prompted for passwords during playbook runs"
        return 1
    fi
}

# ==============================================================================
# Configuration File Generation
# ==============================================================================

generate_ansible_cfg() {
    local admin_user="$1"
    local config_dir="$2"
    local ansible_cfg="$3"
    
    print_info "Generating ansible.cfg for user: $admin_user"
    
    cat > "$ansible_cfg" << EOF
[defaults]
inventory = inventory/production
remote_user = $admin_user
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory
stdout_callback = yaml
bin_ansible_callbacks = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
EOF
    
    print_success "Generated: $ansible_cfg"
}

generate_production_inventory() {
    local admin_user="$1"
    local inventory_dir="$2"
    local inventory_file="$3"
    
    print_info "Generating production inventory"
    
    # Create inventory directory
    mkdir -p "$inventory_dir"
    
    # Generate inventory file
    cat > "$inventory_file" << EOF
# Production Inventory
# Replace 'your-server.example.com' with your actual server hostname/IP

[workstations]
# Example: production-server ansible_host=192.168.1.100
your-server.example.com ansible_user=$admin_user

[workstations:vars]
# Common variables for all workstations
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3

[all:vars]
# Global variables
admin_user=$admin_user
EOF
    
    print_success "Generated: $inventory_file"
}

generate_group_vars() {
    local admin_user="$1"
    local group_vars_dir="$2"
    local group_vars_file="$3"
    
    print_info "Generating group variables"
    
    # Create group_vars directory
    mkdir -p "$group_vars_dir"
    
    # Generate all.yml
    cat > "$group_vars_file" << EOF
---
# Global variables for all hosts

# Admin user configuration
admin_user: $admin_user

# Security settings
security_hardening: true
firewall_enabled: true

# Docker configuration
docker_users:
  - "{{ admin_user }}"

# Ansible configuration
ansible_ssh_pipelining: true
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    
    print_success "Generated: $group_vars_file"
}

# ==============================================================================
# Configuration Testing
# ==============================================================================

test_ansible_configuration() {
    local inventory_file="$1"
    
    print_info "Testing Ansible configuration"
    
    # Test inventory parsing
    if ansible-inventory --list -i "$inventory_file" &>/dev/null; then
        print_success "Inventory file syntax is valid"
    else
        print_error "Inventory file has syntax errors"
        return 1
    fi
    
    # Test connection (if hosts are reachable)
    print_info "Testing connection to hosts (this may take a moment)..."
    if ansible all -i "$inventory_file" -m ping --timeout=10 2>/dev/null; then
        print_success "Successfully connected to all hosts"
    else
        print_warning "Could not connect to hosts (this is normal if servers aren't running)"
        echo "To test connection later:"
        echo "  ansible all -i inventory/production -m ping"
    fi
}

# ==============================================================================
# Summary and Next Steps
# ==============================================================================

print_configuration_summary() {
    local admin_user="$1"
    local ansible_cfg="$2"
    local inventory_file="$3"
    
    print_header "CONFIGURATION COMPLETE"
    
    echo "Files created:"
    echo "  ✓ $ansible_cfg"
    echo "  ✓ $inventory_file"
    echo "  ✓ inventory/group_vars/all.yml"
    echo ""
    
    echo "Admin user: $admin_user"
    echo ""
    
    echo "Next steps:"
    echo "  1. Edit inventory/production with your actual server details"
    echo "  2. Test connection: ansible all -m ping"
    echo "  3. Run a playbook: ansible-playbook playbooks/workstation.yml"
    echo ""
    
    if [ -f "/etc/sudoers.d/99-$admin_user-nopasswd" ]; then
        echo "Passwordless sudo: ✓ Configured"
        echo "You can now run playbooks without password prompts"
    else
        echo "Passwordless sudo: ✗ Not configured"
        echo "Configure vault passwords before running playbooks"
    fi
}