#!/usr/bin/env bash
# ==============================================================================
# Duplicate Configuration Detection Check
# ==============================================================================
# Identifies duplicate configuration values across files
# 
# Requirements: 4.3
# Property: 16 - Duplicate configuration detection
# ==============================================================================

set -euo pipefail

# Get script directory for sourcing common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Path to check (default to current directory)
CHECK_PATH="${1:-.}"

print_section "Duplicate Configuration Detection Check"
print_info "Checking for duplicate configuration values in: $CHECK_PATH"
echo ""

# Track configuration values
declare -A config_values
declare -A config_locations

# Check YAML configuration files
print_info "Analyzing YAML configuration files..."
while IFS= read -r -d '' yamlfile; do
    increment_check
    
    # Extract key-value pairs from YAML
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [ -z "$line" ]; then
            continue
        fi
        
        # Extract key: value pairs
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*):(.+)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            # Normalize value (trim whitespace)
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Skip common values that are expected to be duplicated
            if [[ "$value" =~ ^(true|false|yes|no|null|0|1)$ ]]; then
                continue
            fi
            
            # Create a key for this config value
            config_key="$key=$value"
            
            if [ -n "${config_values[$config_key]:-}" ]; then
                # Duplicate found
                original="${config_locations[$config_key]}"
                duplicate="$yamlfile"
                
                if [ "$original" != "$duplicate" ]; then
                    print_warning "Duplicate configuration value found"
                    echo "  Key: $key"
                    echo "  Value: $value"
                    echo "  Original: $original"
                    echo "  Duplicate: $duplicate"
                    echo "  Consider: Extract to shared configuration file"
                    echo ""
                    increment_warning
                fi
            else
                config_values[$config_key]=1
                config_locations[$config_key]="$yamlfile"
            fi
        fi
    done < "$yamlfile"
done < <(find "$CHECK_PATH" -name "*.yml" -o -name "*.yaml" -type f -print0 2>/dev/null)

# Check for hardcoded values that should be in configuration
print_info "Checking for hardcoded values in scripts..."

# Look for hardcoded ports
port_count=$(grep -r ":[0-9]\{4,5\}" "$CHECK_PATH" --include="*.sh" --include="*.py" | grep -v "localhost\|127.0.0.1" | wc -l)
if [ "$port_count" -gt 5 ]; then
    print_warning "Multiple hardcoded port numbers found ($port_count occurrences)"
    echo "  Consider: Move port numbers to configuration file"
    echo "  Example: Use ahab.conf or config.yml for port configuration"
    echo ""
    increment_warning
fi

# Look for hardcoded paths
path_count=$(grep -r "/var/\|/opt/\|/usr/local/" "$CHECK_PATH" --include="*.sh" --include="*.py" | wc -l)
if [ "$path_count" -gt 10 ]; then
    print_warning "Multiple hardcoded paths found ($path_count occurrences)"
    echo "  Consider: Move paths to configuration file"
    echo "  Example: Use ahab.conf for path configuration"
    echo ""
    increment_warning
fi

# Look for hardcoded URLs
url_count=$(grep -r "http://\|https://" "$CHECK_PATH" --include="*.sh" --include="*.py" | grep -v "example.com\|localhost" | wc -l)
if [ "$url_count" -gt 5 ]; then
    print_info "Found $url_count hardcoded URLs"
    echo "  Consider: Move URLs to configuration file if they're environment-specific"
    echo ""
fi

# Print summary
print_summary "Duplicate Configuration Detection Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "No significant configuration duplication detected"
fi

exit $exit_code
