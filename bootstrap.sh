#!/usr/bin/env bash
# ==============================================================================
# Ahab Bootstrap Script
# ==============================================================================
# Automated Host Administration & Build
# Sets up the four-repository structure with proper symlinks
#
# This script automates the initial setup of Ahab by:
#   1. Checking prerequisites (git, ansible, vagrant, virtualbox)
#   2. Cloning all four repositories (if not already cloned)
#   3. Initializing ahab-modules as a Git submodule
#   4. Creating symlinks for inventory and config
#   5. Creating Makefile symlinks for ansible-inventory and ansible-config
#   6. Checking out the dev branch on all repos
#   7. Creating example configuration files
#   8. Verifying the installation
#
# Prerequisites:
#   - Git (with SSH keys configured for GitHub)
#   - Ansible
#   - Vagrant (optional, for testing)
#   - VirtualBox (optional, for testing)
#
# Usage:
#   ./bootstrap.sh [options]
#
# Options:
#   --base-dir DIR    Base directory for repositories (default: ~/git)
#   --github-user USER GitHub username (default: ${GITHUB_USER})
#   --skip-checks     Skip prerequisite checks
#   --help            Show this help message
#
# Examples:
#   ./bootstrap.sh
#   ./bootstrap.sh --base-dir ~/projects --github-user myusername
#   ./bootstrap.sh --skip-checks

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

# Default Configuration (can be overridden with command-line arguments)
BASE_DIR="${HOME}/git"
GITHUB_USER="${GITHUB_USER}"
SKIP_CHECKS=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        --github-user)
            GITHUB_USER="$2"
            shift 2
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --help)
            grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            die "Unknown option: $1. Run '$0 --help' for usage information"
            ;;
    esac
done

print_section "Ahab Bootstrap"
print_info "Configuration:"
print_info "  Base Directory: ${BASE_DIR}"
print_info "  GitHub User:    ${GITHUB_USER}"
echo ""

#------------------------------------------------------------------------------
# Prerequisite Checks
#------------------------------------------------------------------------------
if [ "$SKIP_CHECKS" = false ]; then
    print_info "Checking prerequisites..."
    
    # Check for git (REQUIRED)
    if command -v git &> /dev/null; then
        print_success "Git found: $(git --version | head -1)"
    else
        die "Git is not installed. Install: https://git-scm.com/downloads"
    fi
    
    # Check for ansible (REQUIRED for deployments)
    if command -v ansible &> /dev/null; then
        print_success "Ansible found: $(ansible --version | head -1)"
    else
        print_warning "Ansible is not installed (required for deployments)"
        print_info "  Install: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    fi
    
    # Check for vagrant (OPTIONAL)
    if command -v vagrant &> /dev/null; then
        print_success "Vagrant found: $(vagrant --version)"
    else
        print_warning "Vagrant is not installed (optional, for testing)"
        print_info "  Install: https://www.vagrantup.com/downloads"
    fi
    
    # Check for VirtualBox (OPTIONAL)
    if command -v VBoxManage &> /dev/null; then
        print_success "VirtualBox found: $(VBoxManage --version)"
    else
        print_warning "VirtualBox is not installed (optional, for testing)"
        print_info "  Install: https://www.virtualbox.org/wiki/Downloads"
    fi
    
    # Check SSH keys (REQUIRED for GitHub)
    if [ ! -f "${HOME}/.ssh/id_rsa" ] && [ ! -f "${HOME}/.ssh/id_ed25519" ]; then
        print_warning "No SSH keys found"
        print_info "  Generate with: ssh-keygen -t ed25519 -C \"your_email@example.com\""
        print_info "  Add to GitHub: https://github.com/settings/keys"
        echo ""
        read -p "Continue anyway? [y/N] " continue_without_ssh
        if [ "$continue_without_ssh" != "y" ] && [ "$continue_without_ssh" != "Y" ]; then
            exit 1
        fi
    else
        print_success "SSH keys found"
    fi
    
    echo ""
fi

#------------------------------------------------------------------------------
# Create Base Directory
#------------------------------------------------------------------------------
ensure_dir "${BASE_DIR}"

#------------------------------------------------------------------------------
# Step 1: Clone Repositories
#------------------------------------------------------------------------------
# Clone all four Ahab repositories from GitHub if they don't already exist
# Repositories:
#   - ahab: Playbooks and automation logic
#   - ansible-inventory: Host definitions and groups
#   - ansible-config: Configuration variables and settings
#   - ahab-modules: Service definitions (configured as submodule)
echo "Step 1: Checking repositories..."
cd "${BASE_DIR}"

if [ ! -d "ahab" ]; then
    echo "  → Cloning ahab..."
    if ! git clone "git@github.com:${GITHUB_USER}/ahab.git"; then
        echo -e "${RED}✗ Failed to clone ahab${NC}"
        echo "  Check your GitHub SSH keys and network connection"
        exit 1
    fi
else
    echo "  ✓ ahab exists"
fi

if [ ! -d "ansible-inventory" ]; then
    echo "  → Cloning ansible-inventory..."
    if ! git clone "git@github.com:${GITHUB_USER}/ansible-inventory.git"; then
        echo -e "${RED}✗ Failed to clone ansible-inventory${NC}"
        echo "  Check your GitHub SSH keys and network connection"
        exit 1
    fi
else
    echo "  ✓ ansible-inventory exists"
fi

if [ ! -d "ansible-config" ]; then
    echo "  → Cloning ansible-config..."
    if ! git clone "git@github.com:${GITHUB_USER}/ansible-config.git"; then
        echo -e "${RED}✗ Failed to clone ansible-config${NC}"
        echo "  Check your GitHub SSH keys and network connection"
        exit 1
    fi
else
    echo "  ✓ ansible-config exists"
fi

echo ""

#------------------------------------------------------------------------------
# Step 2: Initialize ahab-modules Submodule
#------------------------------------------------------------------------------
# Initialize and update the ahab-modules submodule within ahab
# The ahab-modules repository contains all service definitions
# It's configured as a Git submodule at ahab/modules
echo "Step 2: Initializing ahab-modules submodule..."
cd "${BASE_DIR}/ahab"

if [ ! -f ".gitmodules" ]; then
    echo -e "${YELLOW}⚠ No .gitmodules file found${NC}"
    echo "  ahab-modules submodule may not be configured"
    echo "  Skipping submodule initialization"
else
    if [ ! -d "modules/.git" ]; then
        echo "  → Initializing submodule..."
        git submodule update --init --recursive
        echo "  ✓ ahab-modules submodule initialized"
    else
        echo "  ✓ ahab-modules submodule already initialized"
        echo "  → Updating submodule..."
        git submodule update --recursive
        echo "  ✓ ahab-modules submodule updated"
    fi
fi

echo ""

#------------------------------------------------------------------------------
# Step 3: Checkout Dev Branch
#------------------------------------------------------------------------------
# Switch all repositories to the dev branch for safe testing
# Dev branch is where all changes should be made and tested before production
echo "Step 3: Checking out dev branch..."
cd "${BASE_DIR}/ahab"
git checkout dev
echo "  ✓ ahab on dev"

cd "${BASE_DIR}/ansible-inventory"
git checkout dev
echo "  ✓ ansible-inventory on dev"

cd "${BASE_DIR}/ansible-config"
git checkout dev
echo "  ✓ ansible-config on dev"

# Checkout dev branch in ahab-modules submodule if it exists
if [ -d "${BASE_DIR}/ahab/modules/.git" ]; then
    cd "${BASE_DIR}/ahab/modules"
    git checkout dev 2>/dev/null || echo "  ⚠ ahab-modules: dev branch not available, staying on current branch"
    echo "  ✓ ahab-modules checked"
fi

echo ""

#------------------------------------------------------------------------------
# Step 4: Create Symlinks in ahab
#------------------------------------------------------------------------------
# Create symbolic links to tie the repositories together
# This allows ahab to access inventory seamlessly
# Symlinks:
#   - inventory -> ../ansible-inventory (host definitions)
# Note: modules directory is managed as a Git submodule, not a symlink
# Note: config.yml removed - ahab.conf is the single source of truth
echo "Step 4: Creating symlinks..."
cd "${BASE_DIR}/ahab"

if [ ! -L "inventory" ]; then
    ln -s ../ansible-inventory inventory
    echo "  ✓ Created inventory → ../ansible-inventory"
else
    echo "  ✓ inventory symlink exists"
fi

echo ""

#------------------------------------------------------------------------------
# Step 5: Create Makefile Symlinks
#------------------------------------------------------------------------------
# Link Makefiles from ahab to config and inventory repos
# This allows running make commands from any of the repositories
# All repos share the same Makefile targets for consistency
echo "Step 5: Creating Makefile symlinks..."

cd "${BASE_DIR}/ansible-inventory"
if [ ! -L "Makefile" ]; then
    ln -s ../ahab/Makefile Makefile
    echo "  ✓ Created ansible-inventory/Makefile → ../ahab/Makefile"
else
    echo "  ✓ ansible-inventory/Makefile symlink exists"
fi

cd "${BASE_DIR}/ansible-config"
if [ ! -L "Makefile" ]; then
    ln -s ../ahab/Makefile Makefile
    echo "  ✓ Created ansible-config/Makefile → ../ahab/Makefile"
else
    echo "  ✓ ansible-config/Makefile symlink exists"
fi

echo ""

#------------------------------------------------------------------------------
# Step 6: Create Example Configuration Files
#------------------------------------------------------------------------------
# Copy example inventory files to create working versions
# These files need to be edited with your actual host information
# Environments:
#   - dev: Development/testing hosts
#   - prod: Production hosts
#   - workstation: Personal workstation hosts
echo "Step 6: Creating example configuration files..."

# Dev inventory
if [ ! -f "${BASE_DIR}/ansible-inventory/dev/hosts.yml" ]; then
    if [ -f "${BASE_DIR}/ansible-inventory/dev/hosts.yml.example" ]; then
        cp "${BASE_DIR}/ansible-inventory/dev/hosts.yml.example" "${BASE_DIR}/ansible-inventory/dev/hosts.yml"
        echo "  ✓ Created dev/hosts.yml from example"
        echo -e "  ${YELLOW}⚠  Edit ansible-inventory/dev/hosts.yml with your hosts${NC}"
    fi
else
    echo "  ✓ dev/hosts.yml exists"
fi

# Prod inventory
if [ ! -f "${BASE_DIR}/ansible-inventory/prod/hosts.yml" ]; then
    if [ -f "${BASE_DIR}/ansible-inventory/prod/hosts.yml.example" ]; then
        cp "${BASE_DIR}/ansible-inventory/prod/hosts.yml.example" "${BASE_DIR}/ansible-inventory/prod/hosts.yml"
        echo "  ✓ Created prod/hosts.yml from example"
        echo -e "  ${YELLOW}⚠  Edit ansible-inventory/prod/hosts.yml with your hosts${NC}"
    fi
else
    echo "  ✓ prod/hosts.yml exists"
fi

# Workstation inventory
if [ ! -f "${BASE_DIR}/ansible-inventory/workstation/hosts.yml" ]; then
    if [ -f "${BASE_DIR}/ansible-inventory/workstation/hosts.yml.example" ]; then
        cp "${BASE_DIR}/ansible-inventory/workstation/hosts.yml.example" "${BASE_DIR}/ansible-inventory/workstation/hosts.yml"
        echo "  ✓ Created workstation/hosts.yml from example"
        echo -e "  ${YELLOW}⚠  Edit ansible-inventory/workstation/hosts.yml with your hosts${NC}"
    fi
else
    echo "  ✓ workstation/hosts.yml exists"
fi

echo ""

# Step 7: Verify installation
echo "Step 7: Verifying installation..."
cd "${BASE_DIR}/ahab"

# Check symlinks
if [ -L "inventory" ]; then
    echo "  ✓ Symlinks verified"
else
    echo -e "  ${RED}✗ Symlink verification failed${NC}"
    exit 1
fi

# Check Makefile
if [ -f "Makefile" ]; then
    echo "  ✓ Makefile found"
else
    echo -e "  ${RED}✗ Makefile not found${NC}"
    exit 1
fi

# Check ahab-modules submodule
if [ -d "modules/.git" ]; then
    echo "  ✓ ahab-modules submodule initialized"
else
    echo -e "  ${YELLOW}⚠ ahab-modules submodule not initialized${NC}"
fi

# Check git branches
CONTROL_BRANCH=$(cd "${BASE_DIR}/ahab" && git rev-parse --abbrev-ref HEAD)
INVENTORY_BRANCH=$(cd "${BASE_DIR}/ansible-inventory" && git rev-parse --abbrev-ref HEAD)
CONFIG_BRANCH=$(cd "${BASE_DIR}/ansible-config" && git rev-parse --abbrev-ref HEAD)

if [ "$CONTROL_BRANCH" = "dev" ] && [ "$INVENTORY_BRANCH" = "dev" ] && [ "$CONFIG_BRANCH" = "dev" ]; then
    echo "  ✓ All repos on dev branch"
else
    echo -e "  ${YELLOW}⚠ Branch mismatch: control=$CONTROL_BRANCH, inventory=$INVENTORY_BRANCH, config=$CONFIG_BRANCH${NC}"
fi

# Verify all four repositories exist
REPOS_FOUND=0
[ -d "${BASE_DIR}/ahab/.git" ] && ((REPOS_FOUND++))
[ -d "${BASE_DIR}/ansible-inventory/.git" ] && ((REPOS_FOUND++))
[ -d "${BASE_DIR}/ansible-config/.git" ] && ((REPOS_FOUND++))
[ -d "${BASE_DIR}/ahab/modules/.git" ] && ((REPOS_FOUND++))

if [ $REPOS_FOUND -eq 4 ]; then
    echo "  ✓ All four repositories verified"
else
    echo -e "  ${YELLOW}⚠ Found $REPOS_FOUND of 4 repositories${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Bootstrap Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}Installation Summary:${NC}"
echo "  • Four repositories cloned and configured"
echo "    - ahab (orchestration)"
echo "    - ansible-config (configuration)"
echo "    - ansible-inventory (environments)"
echo "    - ahab-modules (service definitions)"
echo "  • Symlinks created for seamless integration"
echo "  • ahab-modules configured as Git submodule"
echo "  • Dev branch checked out for safe testing"
echo "  • Example configuration files ready"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo -e "${YELLOW}1. Configure Your Inventory${NC}"
echo "   Edit the list of computers you want to manage:"
echo "   ${BASE_DIR}/ansible-inventory/dev/hosts.yml"
echo ""
echo -e "${YELLOW}2. Customize Configuration${NC}"
echo "   Set your preferences and variables:"
echo "   ${BASE_DIR}/ahab.conf"
echo ""
echo -e "${YELLOW}3. Test with Virtual Machine${NC}"
echo "   Try it out safely before touching real computers:"
echo "   cd ${BASE_DIR}/ahab"
echo "   make install"
echo ""
echo -e "${YELLOW}4. Explore Available Commands${NC}"
echo "   See everything you can do:"
echo "   make help"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  • Main README:     ${BASE_DIR}/README.md"
echo "  • Quick Start:     ${BASE_DIR}/docs/quick-start.md"
echo "  • Troubleshooting: ${BASE_DIR}/docs/troubleshooting.md"
echo ""
echo -e "${GREEN}Ready to automate!${NC}"
echo ""
