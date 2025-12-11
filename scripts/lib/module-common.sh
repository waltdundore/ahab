#!/usr/bin/env bash
# ==============================================================================
# Module Common Library
# ==============================================================================
# Shared functions for module management scripts (NASA Rule #4 compliant)
# Used by create-module.sh, install-module.sh, release-module.sh, etc.
# ==============================================================================

# ==============================================================================
# Module Creation Functions
# ==============================================================================

create_module_structure() {
    local module_name="$1"
    local module_dir="modules/$module_name"
    
    echo "→ Creating module structure for: $module_name"
    
    mkdir -p "$module_dir"/{playbooks,roles,templates,tests,docs}
    
    # Create basic playbook
    cat > "$module_dir/playbooks/main.yml" << EOF
---
- name: Deploy $module_name
  hosts: all
  become: true
  
  tasks:
    - name: Include $module_name role
      include_role:
        name: $module_name
EOF
    
    # Create basic role structure
    mkdir -p "$module_dir/roles/$module_name"/{tasks,handlers,templates,files,vars,defaults,meta}
    
    cat > "$module_dir/roles/$module_name/tasks/main.yml" << EOF
---
- name: Install $module_name
  package:
    name: $module_name
    state: present
EOF
    
    check_pass "Created module structure for $module_name"
}

create_module_metadata() {
    local module_name="$1"
    local module_dir="modules/$module_name"
    
    echo "→ Creating module metadata"
    
    cat > "$module_dir/module.yml" << EOF
---
name: $module_name
version: "1.0.0"
description: "Ahab module for $module_name"
author: "Ahab Team"
license: "MIT"
min_ansible_version: "2.9"

dependencies: []

tags:
  - $module_name
  - automation
  - infrastructure
EOF
    
    cat > "$module_dir/README.md" << EOF
# $module_name Module

Ahab module for deploying and managing $module_name.

## Quick Start

\`\`\`bash
make install $module_name
\`\`\`

## Requirements

- Ansible 2.9+
- Target system with package manager

## Variables

See \`defaults/main.yml\` for available variables.

## License

MIT
EOF
    
    check_pass "Created module metadata"
}

# ==============================================================================
# Module Installation Functions
# ==============================================================================

install_module_dependencies() {
    local module_name="$1"
    
    echo "→ Installing dependencies for: $module_name"
    
    # Check if module exists
    if [ ! -d "modules/$module_name" ]; then
        check_fail "Module $module_name not found"
        return 1
    fi
    
    # Install Ansible dependencies
    if [ -f "modules/$module_name/requirements.yml" ]; then
        ansible-galaxy install -r "modules/$module_name/requirements.yml"
        check_pass "Installed Ansible dependencies"
    else
        check_pass "No Ansible dependencies to install"
    fi
}

deploy_module() {
    local module_name="$1"
    local target="${2:-workstation}"
    
    echo "→ Deploying module: $module_name to $target"
    
    local playbook="modules/$module_name/playbooks/main.yml"
    
    if [ ! -f "$playbook" ]; then
        check_fail "Playbook not found: $playbook"
        return 1
    fi
    
    # Run the playbook
    if ansible-playbook -i "inventory/$target" "$playbook"; then
        check_pass "Successfully deployed $module_name"
    else
        check_fail "Failed to deploy $module_name"
        return 1
    fi
}

# ==============================================================================
# Module Testing Functions
# ==============================================================================

test_module() {
    local module_name="$1"
    
    echo "→ Testing module: $module_name"
    
    # Run syntax check
    local playbook="modules/$module_name/playbooks/main.yml"
    if ansible-playbook --syntax-check "$playbook"; then
        check_pass "Syntax check passed"
    else
        check_fail "Syntax check failed"
        return 1
    fi
    
    # Run module tests if they exist
    local test_script="modules/$module_name/tests/test.sh"
    if [ -f "$test_script" ]; then
        if bash "$test_script"; then
            check_pass "Module tests passed"
        else
            check_fail "Module tests failed"
            return 1
        fi
    else
        check_pass "No module tests to run"
    fi
}

# ==============================================================================
# Module Release Functions
# ==============================================================================

validate_module_for_release() {
    local module_name="$1"
    
    echo "→ Validating module for release: $module_name"
    
    local module_dir="modules/$module_name"
    local errors=0
    
    # Check required files
    local required_files=(
        "$module_dir/module.yml"
        "$module_dir/README.md"
        "$module_dir/playbooks/main.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            check_pass "Required file exists: $file"
        else
            check_fail "Missing required file: $file"
            ((errors++))
        fi
    done
    
    # Check for placeholder content
    if grep -r "PLACEHOLDER\|TODO\|FIXME" "$module_dir" >/dev/null 2>&1; then
        check_fail "Module contains placeholder content"
        ((errors++))
    else
        check_pass "No placeholder content found"
    fi
    
    return $errors
}

create_module_package() {
    local module_name="$1"
    local version="${2:-1.0.0}"
    
    echo "→ Creating package for module: $module_name"
    
    local package_name="${module_name}-${version}.tar.gz"
    local module_dir="modules/$module_name"
    
    if [ ! -d "$module_dir" ]; then
        check_fail "Module directory not found: $module_dir"
        return 1
    fi
    
    # Create package
    tar -czf "dist/$package_name" -C modules "$module_name"
    
    if [ -f "dist/$package_name" ]; then
        check_pass "Created package: dist/$package_name"
    else
        check_fail "Failed to create package"
        return 1
    fi
}

# ==============================================================================
# Module Registry Functions
# ==============================================================================

register_module() {
    local module_name="$1"
    local version="${2:-1.0.0}"
    
    echo "→ Registering module in registry: $module_name"
    
    # Update module registry
    if [ ! -f "MODULE_REGISTRY.yml" ]; then
        cat > "MODULE_REGISTRY.yml" << 'EOF'
---
modules: []
EOF
    fi
    
    # Add module to registry (simplified - would use yq in production)
    echo "  - name: $module_name" >> "MODULE_REGISTRY.yml"
    echo "    version: $version" >> "MODULE_REGISTRY.yml"
    echo "    path: modules/$module_name" >> "MODULE_REGISTRY.yml"
    
    check_pass "Registered module in registry"
}

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_module_name() {
    local module_name="$1"
    
    if [[ ! $module_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid module name: $module_name"
        print_info "Module names must contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    return 0
}

check_module_exists() {
    local module_name="$1"
    
    if [ -d "modules/$module_name" ]; then
        return 0
    else
        return 1
    fi
}