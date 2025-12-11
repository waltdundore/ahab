#!/bin/bash
# Test role-specific variable definitions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/ahab-config"

echo "Testing role-specific variables..."

# Function to test YAML syntax using Docker
test_yaml_syntax() {
    local file="$1"
    if ! docker run --rm -v "$(pwd):/workspace" -w /workspace python:3.11-slim \
        sh -c "pip install pyyaml && python -c \"import yaml; yaml.safe_load(open('$file'))\"" 2>/dev/null; then
        echo "ERROR: Invalid YAML syntax in $file"
        exit 1
    fi
}

# Test each role's variables
test_role_variables() {
    cd "$CONFIG_DIR"
    
    for role in apache mysql php; do
        echo "→ Testing $role variables"
        
        git checkout "$role" &>/dev/null
        
        # Test YAML syntax
        test_yaml_syntax "common-vars.yml"
        test_yaml_syntax "$role-vars.yml"
        
        # Test required variables exist
        case "$role" in
            "apache")
                if ! grep -q "apache_port:" "$role-vars.yml"; then
                    echo "ERROR: apache_port not defined in apache-vars.yml"
                    exit 1
                fi
                ;;
            "mysql")
                if ! grep -q "mysql_port:" "$role-vars.yml"; then
                    echo "ERROR: mysql_port not defined in mysql-vars.yml"
                    exit 1
                fi
                ;;
            "php")
                if ! grep -q "php_version:" "$role-vars.yml"; then
                    echo "ERROR: php_version not defined in php-vars.yml"
                    exit 1
                fi
                ;;
        esac
        
        echo "    ✓ $role variables valid"
    done
    
    git checkout main &>/dev/null
}

test_role_variables

echo "✓ All role variable tests passed"
