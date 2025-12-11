#!/usr/bin/env bash
# Library file - sourced by tests, no cleanup needed
# ==============================================================================
# Test Helper Functions
# ==============================================================================
# Shared utilities for all test scripts
# NASA Power of 10 compliant: bounded loops, checked returns, ≤60 lines/function
# DRY: Single source of truth for all common test operations
# ==============================================================================

# Source shared color definitions (DRY)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

#------------------------------------------------------------------------------
# Output Functions
#------------------------------------------------------------------------------

print_success() {
    local message="$1"
    echo -e "${GREEN}✓ ${message}${NC}"
}

print_error() {
    local message="$1"
    echo -e "${RED}✗ ${message}${NC}" >&2
}

print_info() {
    local message="$1"
    echo -e "${BLUE}${message}${NC}"
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ ${message}${NC}"
}

print_section() {
    local title="$1"
    echo ""
    echo "=========================================="
    echo "$title"
    echo "=========================================="
    echo ""
}

#------------------------------------------------------------------------------
# Command Checking Functions
#------------------------------------------------------------------------------

check_command() {
    local cmd="$1"
    local help_msg="${2:-}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$cmd is not installed"
        if [ -n "$help_msg" ]; then
            echo ""
            print_info "$help_msg"
        fi
        return 1
    fi
    return 0
}

check_vagrant() {
    check_command vagrant "Install with: brew install vagrant"
}

check_virtualbox() {
    check_command VBoxManage "Install with: brew install --cask virtualbox"
}

check_ansible() {
    check_command ansible "Install with: brew install ansible"
}

check_python3() {
    check_command python3 "Install with: brew install python3"
}

check_docker() {
    check_command docker "Install with: brew install --cask docker"
}

# Check all standard prerequisites (Vagrant + VirtualBox)
check_standard_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing=0
    
    if ! check_vagrant; then
        ((missing++))
    else
        print_success "Vagrant installed"
    fi
    
    if ! check_virtualbox; then
        ((missing++))
    else
        print_success "VirtualBox installed"
    fi
    
    if [ $missing -gt 0 ]; then
        echo ""
        print_error "Please install missing prerequisites"
        return 1
    fi
    
    echo ""
    return 0
}

# Check prerequisites with Ansible
check_prerequisites_with_ansible() {
    print_info "Checking prerequisites..."
    
    local missing=0
    
    if ! check_vagrant; then
        ((missing++))
    else
        print_success "Vagrant installed"
    fi
    
    if ! check_virtualbox; then
        ((missing++))
    else
        print_success "VirtualBox installed"
    fi
    
    if ! check_ansible; then
        ((missing++))
    else
        print_success "Ansible installed"
    fi
    
    if [ $missing -gt 0 ]; then
        echo ""
        print_error "Please install missing prerequisites"
        return 1
    fi
    
    echo ""
    return 0
}

#------------------------------------------------------------------------------
# VM Management Functions
#------------------------------------------------------------------------------

cleanup_existing_vm() {
    local vagrantfile="${1:-}"
    
    print_info "Checking for existing VMs..."
    
    local vagrant_cmd="vagrant"
    if [ -n "$vagrantfile" ]; then
        vagrant_cmd="VAGRANT_VAGRANTFILE=$vagrantfile vagrant"
    fi
    
    if eval "$vagrant_cmd status 2>/dev/null" | grep -q "running\|poweroff\|saved"; then
        print_warning "Found existing VM, cleaning up..."
        eval "$vagrant_cmd destroy -f 2>/dev/null" || true
        print_success "Old VM removed"
    else
        print_success "No existing VMs"
    fi
    
    echo ""
}

cleanup_vm() {
    local vm_name="${1:-}"
    
    if [ -n "$vm_name" ]; then
        vagrant destroy -f "$vm_name" 2>/dev/null || true
    else
        vagrant destroy -f 2>/dev/null || true
    fi
}

verify_vm_running() {
    local vm_name="${1:-default}"
    
    if ! vagrant status "$vm_name" 2>/dev/null | grep -q "running"; then
        print_error "VM '$vm_name' is not running"
        print_info "Start it with: make install"
        return 1
    fi
    print_success "VM is running"
    return 0
}

wait_for_vm() {
    local max_wait="${1:-60}"
    local vm_name="${2:-default}"
    
    print_info "Waiting for VM '$vm_name' (max ${max_wait}s)..."
    
    for i in $(seq 1 "$max_wait"); do
        if vagrant status "$vm_name" 2>/dev/null | grep -q "running"; then
            print_success "VM is ready"
            return 0
        fi
        sleep 1
    done
    
    print_error "Timeout waiting for VM (waited ${max_wait}s)"
    return 1
}

vagrant_with_timeout() {
    local timeout_seconds="$1"
    shift
    local cmd="$*"
    
    print_info "Running: vagrant $cmd (timeout: ${timeout_seconds}s)"
    
    if timeout "$timeout_seconds" vagrant "$@"; then
        return 0
    else
        local exit_code=$?
        
        if [ $exit_code -eq 124 ]; then
            echo ""
            print_error "Vagrant command timed out after ${timeout_seconds}s"
            echo ""
            print_info "Command: vagrant $cmd"
            echo ""
            print_info "Common causes:"
            print_info "  • VirtualBox not running - Check: VBoxManage --version"
            print_info "  • Insufficient resources - Check: Activity Monitor"
            print_info "  • Network issues - Check: ping 8.8.8.8"
            print_info "  • Box download stuck - Check: ~/.vagrant.d/boxes/"
            echo ""
            print_info "Try:"
            print_info "  make clean"
            print_info "  make install"
            echo ""
        else
            echo ""
            print_error "Vagrant command failed (exit code: $exit_code)"
            echo ""
        fi
        
        return $exit_code
    fi
}

#------------------------------------------------------------------------------
# Docker Functions
#------------------------------------------------------------------------------

check_docker_in_vm() {
    print_info "Checking Docker in VM..."
    
    if ! vagrant ssh -c "docker info" >/dev/null 2>&1; then
        print_warning "Docker not running in VM, starting..."
        if ! vagrant ssh -c "sudo systemctl start docker" 2>/dev/null; then
            print_error "Failed to start Docker"
            return 1
        fi
        sleep 2
    fi
    print_success "Docker is running in VM"
    return 0
}

cleanup_docker_container() {
    local container_name="$1"
    
    vagrant ssh -c "docker stop ${container_name} 2>/dev/null || true" 2>/dev/null || true
    vagrant ssh -c "docker rm ${container_name} 2>/dev/null || true" 2>/dev/null || true
    vagrant ssh -c "docker rmi ${container_name}:latest 2>/dev/null || true" 2>/dev/null || true
}

#------------------------------------------------------------------------------
# HTTP Testing Functions
#------------------------------------------------------------------------------

wait_for_http() {
    local url="$1"
    local max_attempts="${2:-15}"
    local search_pattern="${3:-}"
    
    print_info "Waiting for HTTP response at $url (max ${max_attempts} attempts)..."
    
    for attempt in $(seq 1 "$max_attempts"); do
        if [ -n "$search_pattern" ]; then
            if curl -s "$url" 2>/dev/null | grep -q "$search_pattern"; then
                print_success "HTTP service is responding"
                return 0
            fi
        else
            if curl -s "$url" > /dev/null 2>&1; then
                print_success "HTTP service is responding"
                return 0
            fi
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "HTTP service not accessible after $max_attempts attempts"
            return 1
        fi
        
        echo -n "."
        sleep 2
    done
    
    return 1
}

find_available_port() {
    local start_port="${1:-8080}"
    local max_ports="${2:-10}"
    
    for p in $(seq "$start_port" $((start_port + max_ports - 1))); do
        if ! lsof -Pi ":$p" -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "$p"
            return 0
        fi
    done
    
    return 1
}

#------------------------------------------------------------------------------
# File Creation Functions
#------------------------------------------------------------------------------

create_hello_world_html() {
    local output_file="$1"
    local title="${2:-Hello World}"
    
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ahab - It Works!</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 60px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 800px;
        }
        .emoji { font-size: 5em; margin: 20px 0; }
        h1 { color: #667eea; font-size: 3.5em; margin: 20px 0; }
        .success {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 20px 40px;
            border-radius: 50px;
            display: inline-block;
            margin: 30px 0;
            font-weight: bold;
            font-size: 1.2em;
        }
        p { color: #666; font-size: 1.3em; line-height: 1.8; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>Hello World!</h1>
        <div class="success">✓ Apache Module Working!</div>
        <p>Your Ahab Apache module successfully deployed and is serving this page.</p>
    </div>
</body>
</html>
EOF
}

create_apache_role_files() {
    local control_dir="$1"
    
    print_info "Creating Apache role files..."
    
    # Create files directory
    mkdir -p "$control_dir/roles/apache/files"
    
    # Create Hello World HTML
    create_hello_world_html "$control_dir/roles/apache/files/index.html"
    
    print_success "Apache role files created"
}

create_apache_defaults() {
    local control_dir="$1"
    
    print_info "Setting up Apache defaults..."
    
    mkdir -p "$control_dir/roles/apache/defaults"
    
    cat > "$control_dir/roles/apache/defaults/main.yml" << 'EOF'
---
# Apache default variables

apache_server_name: "{{ ansible_fqdn }}"
apache_port: 80
apache_ssl_port: 443
EOF
    
    print_success "Apache defaults configured"
}

create_test_inventory() {
    local control_dir="$1"
    local vm_name="${2:-default}"
    
    print_info "Creating inventory..."
    
    mkdir -p "$control_dir/inventory"
    
    cat > "$control_dir/inventory/hosts" << EOF
[webservers]
$vm_name ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/$vm_name/virtualbox/private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    
    print_success "Inventory created"
}

#------------------------------------------------------------------------------
# Ansible Functions
#------------------------------------------------------------------------------

deploy_with_ansible() {
    local playbook="$1"
    local inventory="${2:-inventory/hosts}"
    
    print_info "Deploying with Ansible..."
    echo ""
    
    if ! ansible-playbook -i "$inventory" "$playbook"; then
        echo ""
        print_error "Ansible deployment failed"
        return 1
    fi
    
    echo ""
    print_success "Ansible deployment complete"
    return 0
}

#------------------------------------------------------------------------------
# VM IP Functions
#------------------------------------------------------------------------------

get_vm_ip() {
    local vm_name="${1:-default}"
    local interface="${2:-eth1}"
    
    # Try to get private network IP
    local vm_ip
    vm_ip=$(vagrant ssh "$vm_name" -c "ip addr show $interface 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null | tr -d '\r')
    
    if [ -z "$vm_ip" ]; then
        # Fallback to localhost with port forwarding
        echo "localhost"
    else
        echo "$vm_ip"
    fi
}

check_port_forwarding() {
    local vagrantfile="${1:-Vagrantfile}"
    local guest_port="${2:-80}"
    local host_port="${3:-8080}"
    
    if grep -q "forwarded_port.*$guest_port.*$host_port" "$vagrantfile" 2>/dev/null; then
        return 0
    fi
    return 1
}
