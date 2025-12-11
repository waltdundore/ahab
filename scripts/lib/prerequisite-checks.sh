#!/bin/bash
# ==============================================================================
# Prerequisite Checking Library
# ==============================================================================
# Shared functions for checking Ahab prerequisites
#
# Usage:
#   source scripts/lib/prerequisite-checks.sh
#
# Functions provided:
#   - check_command_version()
#   - check_docker_running()
#   - check_vagrant_plugins()
#   - check_virtualbox()
#   - check_vbox_modules()
#   - print_installation_help()
#
# Security: Zero Trust - validates each tool independently
# ==============================================================================

# ==============================================================================
# Individual Tool Checks
# ==============================================================================

check_command_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$($cmd $version_flag 2>/dev/null | head -1 || echo "Unknown version")
        print_success "$cmd: $version"
        return 0
    else
        print_error "$cmd: Not installed"
        return 1
    fi
}

check_docker_running() {
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker: Running"
            return 0
        else
            print_warning "Docker: Installed but not running"
            echo "  → Start with: sudo systemctl start docker"
            return 1
        fi
    else
        print_error "Docker: Not installed"
        return 1
    fi
}

check_vagrant_plugins() {
    if command -v vagrant >/dev/null 2>&1; then
        local plugins
        plugins=$(vagrant plugin list 2>/dev/null || echo "")
        if [[ -n "$plugins" ]]; then
            print_info "Vagrant plugins:"
            echo "$plugins" | sed 's/^/    /'
        else
            print_info "Vagrant: No plugins installed (this is normal)"
        fi
    fi
}

check_virtualbox() {
    if command -v VBoxManage >/dev/null 2>&1; then
        local version
        version=$(VBoxManage --version 2>/dev/null | head -1 || echo "Unknown")
        print_success "VirtualBox: $version"
        
        check_vbox_modules
        return 0
    else
        print_error "VirtualBox: Not installed"
        return 1
    fi
}

check_vbox_modules() {
    # Check if VirtualBox kernel modules are loaded (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if lsmod | grep -q vboxdrv; then
            print_success "VirtualBox kernel modules: Loaded"
        else
            print_warning "VirtualBox kernel modules: Not loaded"
            echo "  → Load with: sudo modprobe vboxdrv"
        fi
    fi
}

# ==============================================================================
# Installation Help Functions
# ==============================================================================

print_fedora_help() {
    echo "    Fedora/RHEL:"
    echo "      sudo dnf install git ansible vagrant docker make python3"
    echo "      sudo dnf install VirtualBox"
}

print_debian_help() {
    echo "    Debian/Ubuntu:"
    echo "      sudo apt update"
    echo "      sudo apt install git ansible vagrant virtualbox docker.io make python3"
}

print_macos_help() {
    echo "    macOS (with Homebrew):"
    echo "      brew install git ansible vagrant docker make python3"
    echo "      brew install --cask virtualbox"
}

print_installation_help() {
    echo ""
    print_section "INSTALLATION HELP"
    echo ""
    echo "To install missing prerequisites:"
    echo ""
    echo "  Automated installation:"
    echo "    make install-prerequisites"
    echo ""
    echo "  Manual installation:"
    echo ""
    
    case "$OSTYPE" in
        linux-gnu*)
            if command -v dnf >/dev/null 2>&1; then
                print_fedora_help
            elif command -v apt >/dev/null 2>&1; then
                print_debian_help
            fi
            ;;
        darwin*)
            print_macos_help
            ;;
        *)
            echo "    See: https://docs.ansible.com/ansible/latest/installation_guide/"
            echo "    See: https://www.vagrantup.com/downloads"
            echo "    See: https://www.virtualbox.org/wiki/Downloads"
            ;;
    esac
    
    echo ""
    echo "  After installation:"
    echo "    1. Log out and back in (for Docker group membership)"
    echo "    2. Start Docker: sudo systemctl start docker"
    echo "    3. Re-run: make check-prerequisites"
    echo ""
}

# ==============================================================================
# Bulk Checking Functions
# ==============================================================================

check_required_tools() {
    local missing=0
    
    print_section "REQUIRED TOOLS"
    
    # Check required commands
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        case "$cmd" in
            "docker")
                if ! check_docker_running; then
                    ((missing++))
                fi
                ;;
            "VBoxManage")
                if ! check_virtualbox; then
                    ((missing++))
                fi
                ;;
            *)
                if ! check_command_version "$cmd"; then
                    ((missing++))
                fi
                ;;
        esac
    done
    
    return $missing
}

check_optional_tools() {
    local warnings=0
    
    print_section "OPTIONAL TOOLS"
    
    # Check optional commands
    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        case "$cmd" in
            "VBoxManage")
                if ! check_virtualbox; then
                    ((warnings++))
                fi
                ;;
            *)
                if ! check_command_version "$cmd"; then
                    ((warnings++))
                fi
                ;;
        esac
    done
    
    return $warnings
}

check_additional_requirements() {
    local warnings=0
    
    print_section "ADDITIONAL CHECKS"
    
    check_vagrant_plugins
    
    # Check if user is in docker group (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v docker >/dev/null 2>&1; then
        if groups | grep -q docker; then
            print_success "User in docker group: Yes"
        else
            print_warning "User in docker group: No"
            echo "  → Add with: sudo usermod -aG docker \$USER"
            echo "  → Then log out and back in"
            ((warnings++))
        fi
    fi
    
    return $warnings
}

print_final_summary() {
    local missing=$1
    local warnings=$2
    
    print_section "SUMMARY"
    
    if [ $missing -eq 0 ]; then
        print_success "✅ All required prerequisites are installed"
        
        if [ $warnings -gt 0 ]; then
            print_warning "⚠️  $warnings optional tools missing or need configuration"
            echo ""
            echo "Ahab will work, but some features may be limited."
        fi
        
        echo ""
        echo "Ready to run:"
        echo "  make install"
        echo ""
        
        return 0
    else
        print_error "❌ $missing required prerequisites missing"
        
        if [ $warnings -gt 0 ]; then
            print_warning "⚠️  $warnings additional issues found"
        fi
        
        print_installation_help
        return 1
    fi
}