#!/usr/bin/env bash
# ==============================================================================
# Validate Feature-to-Standards Mapping (Refactored)
# ==============================================================================
# Validates feature-standards-map.yml file
# Exit codes: 0=pass, 1=fail
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/validation-common.sh
source "$SCRIPT_DIR/lib/validation-common.sh"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "FEATURE MAPPING VALIDATION"
    
    # Find files
    local mapping_file registry_file
    mapping_file=$(find_mapping_file)
    registry_file=$(find_registry_file)
    
    # Run validations
    validate_file_exists "$mapping_file"
    validate_file_exists "$registry_file"
    validate_mapping_structure "$mapping_file"
    validate_standard_references "$mapping_file" "$registry_file"
    
    # Generate summary
    generate_validation_summary
}

#------------------------------------------------------------------------------
# File Discovery
#------------------------------------------------------------------------------

find_mapping_file() {
    local candidates=("feature-standards-map.yml" "docs/feature-standards-map.yml")
    
    for file in "${candidates[@]}"; do
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    
    print_error "feature-standards-map.yml not found"
    exit 1
}

find_registry_file() {
    local candidates=("standards-registry.yml" "docs/standards-registry.yml")
    
    for file in "${candidates[@]}"; do
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    
    print_error "standards-registry.yml not found"
    exit 1
}

#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------

validate_file_exists() {
    local file="$1"
    
    if [ -f "$file" ] && [ -r "$file" ]; then
        check_pass "File exists and is readable: $file"
    else
        check_fail "File not found or not readable: $file"
    fi
}

validate_mapping_structure() {
    local file="$1"
    
    print_info "Validating mapping structure..."
    
    # Check for PLACEHOLDER values
    if grep -q "PLACEHOLDER" "$file" 2>/dev/null; then
        check_fail "PLACEHOLDER values found in $file"
    else
        check_pass "No PLACEHOLDER values found"
    fi
    
    # Check YAML syntax
    if command -v python3 &>/dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            check_pass "Valid YAML syntax"
        else
            check_fail "Invalid YAML syntax in $file"
        fi
    else
        check_warn "Python3 not available - skipping YAML syntax check"
    fi
}

validate_standard_references() {
    local mapping_file="$1"
    local registry_file="$2"
    
    print_info "Validating standard references..."
    
    if ! command -v python3 &>/dev/null; then
        check_warn "Python3 not available - skipping reference validation"
        return 0
    fi
    
    # Use Python to validate references
    python3 << EOF
import yaml
import sys

try:
    with open('$mapping_file') as f:
        mapping = yaml.safe_load(f)
    with open('$registry_file') as f:
        registry = yaml.safe_load(f)
    
    # Extract standard IDs from registry
    registry_ids = set()
    if isinstance(registry, dict) and 'standards' in registry:
        for standard in registry['standards']:
            if 'id' in standard:
                registry_ids.add(standard['id'])
    
    # Check mapping references
    errors = 0
    if isinstance(mapping, dict) and 'features' in mapping:
        for feature in mapping['features']:
            if 'standards' in feature:
                for std_ref in feature['standards']:
                    if isinstance(std_ref, dict) and 'id' in std_ref:
                        if std_ref['id'] not in registry_ids:
                            print(f"ERROR: Unknown standard ID: {std_ref['id']}")
                            errors += 1
    
    sys.exit(errors)
    
except Exception as e:
    print(f"ERROR: Validation failed: {e}")
    sys.exit(1)
EOF
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        check_pass "All standard references are valid"
    else
        check_fail "Invalid standard references found"
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi