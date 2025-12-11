#!/bin/bash
# Test modular configuration switching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/ahab-config"

echo "Testing modular configuration switching..."

# Test 1: Check ahab-config directory exists
test_config_directory() {
    echo "→ Testing ahab-config directory exists"
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "ERROR: ahab-config directory not found at $CONFIG_DIR"
        exit 1
    fi
    echo "  ✓ ahab-config directory found"
}

# Test 2: Test branch switching
test_branch_switching() {
    echo "→ Testing branch switching"
    
    cd "$CONFIG_DIR"
    
    # Test switching to each role branch
    for branch in apache mysql php; do
        echo "  Testing $branch branch..."
        
        if ! git checkout "$branch" &>/dev/null; then
            echo "ERROR: Failed to switch to $branch branch"
            exit 1
        fi
        
        # Check that role-specific config exists
        if [ ! -f "$branch-vars.yml" ]; then
            echo "ERROR: $branch-vars.yml not found in $branch branch"
            exit 1
        fi
        
        echo "    ✓ $branch branch working"
    done
    
    # Return to main branch
    git checkout main &>/dev/null
    echo "  ✓ Branch switching working"
}

# Test 3: Test configuration file inheritance
test_config_inheritance() {
    echo "→ Testing configuration inheritance"
    
    cd "$CONFIG_DIR"
    
    for branch in apache mysql php; do
        git checkout "$branch" &>/dev/null
        
        # Check that common files exist
        if [ ! -f "common-vars.yml" ]; then
            echo "ERROR: common-vars.yml not found in $branch branch"
            exit 1
        fi
        
        if [ ! -f "ansible.cfg.base" ]; then
            echo "ERROR: ansible.cfg.base not found in $branch branch"
            exit 1
        fi
        
        echo "    ✓ $branch inherits common configuration"
    done
    
    git checkout main &>/dev/null
    echo "  ✓ Configuration inheritance working"
}

# Run tests
test_config_directory
test_branch_switching
test_config_inheritance

echo "✓ All modular configuration tests passed"
