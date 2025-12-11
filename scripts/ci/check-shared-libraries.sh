#!/usr/bin/env bash
# ==============================================================================
# Shared Library Usage Check
# ==============================================================================
# Verifies that common functions use shared libraries instead of duplication
# 
# Requirements: 4.4
# Property: 17 - Shared library usage
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

print_section "Shared Library Usage Check"
print_info "Checking for proper shared library usage in: $CHECK_PATH"
echo ""

# Check if common library exists
if [ ! -f "$PROJECT_ROOT/scripts/lib/common.sh" ]; then
    print_error "Common library not found: $PROJECT_ROOT/scripts/lib/common.sh"
    echo "  Problem: Shared library is missing"
    echo "  Fix: Create scripts/lib/common.sh with common functions"
    echo ""
    increment_error
    print_summary "Shared Library Usage Check"
    exit 1
fi

# Find all shell scripts
print_info "Analyzing shell scripts for library usage..."
while IFS= read -r -d '' script; do
    increment_check
    
    # Skip library files themselves
    if [[ "$script" == */lib/* ]]; then
        continue
    fi
    
    # Skip this script itself
    if [ "$script" = "$0" ]; then
        continue
    fi
    
    # Check if script sources common library
    if ! grep -q "source.*common.sh\|source.*lib/common.sh\|\. .*common.sh" "$script"; then
        # Check if script defines functions that exist in common library
        has_local_functions=false
        
        # Check for local color definitions (should use common library)
        if grep -q "RED=\|GREEN=\|YELLOW=\|BLUE=" "$script"; then
            print_warning "Script defines colors locally: $script"
            echo "  Consider: Source colors from scripts/lib/common.sh"
            echo "  Add: source \"\$PROJECT_ROOT/scripts/lib/common.sh\""
            echo ""
            has_local_functions=true
            increment_warning
        fi
        
        # Check for local error handling functions (should use common library)
        if grep -q "^[[:space:]]*print_error\|^[[:space:]]*print_success\|^[[:space:]]*die" "$script"; then
            print_warning "Script defines error handling functions locally: $script"
            echo "  Consider: Source error handling from scripts/lib/common.sh"
            echo "  Functions available: print_error, print_success, print_warning, die"
            echo ""
            has_local_functions=true
            increment_warning
        fi
        
        # Check for local validation functions (should use common library)
        if grep -q "^[[:space:]]*validate_\|^[[:space:]]*check_\|^[[:space:]]*require_" "$script"; then
            print_warning "Script defines validation functions locally: $script"
            echo "  Consider: Source validation from scripts/lib/common.sh"
            echo "  Functions available: require_file, require_command, validate_version_format"
            echo ""
            has_local_functions=true
            increment_warning
        fi
        
        if ! $has_local_functions; then
            # Script doesn't source library but also doesn't define common functions
            # This is okay - not all scripts need the library
            print_info "Script doesn't use common library: $script (OK if no common functions needed)"
        fi
    else
        print_success "Script sources common library: $script"
    fi
done < <(find "$CHECK_PATH" -name "*.sh" -type f -print0 2>/dev/null)

# Check for Makefile includes
print_info "Checking Makefile includes..."
while IFS= read -r -d '' makefile; do
    increment_check
    
    # Check if Makefile uses includes for common targets
    if grep -q "^include " "$makefile"; then
        print_success "Makefile uses includes: $makefile"
        
        # Verify included files exist
        while IFS= read -r include_line; do
            included_file=$(echo "$include_line" | awk '{print $2}')
            makefile_dir=$(dirname "$makefile")
            
            if [ ! -f "$makefile_dir/$included_file" ] && [ ! -f "$PROJECT_ROOT/$included_file" ]; then
                print_error "Included Makefile not found: $included_file"
                echo "  Referenced in: $makefile"
                echo "  Fix: Create the included Makefile or fix the include path"
                echo ""
                increment_error
            fi
        done < <(grep "^include " "$makefile")
    else
        # Check if Makefile has common targets that should be in includes
        if grep -q "^help:\|^test:\|^clean:" "$makefile"; then
            print_warning "Makefile defines common targets without includes: $makefile"
            echo "  Consider: Extract common targets to Makefile.common"
            echo "  Add: include Makefile.common"
            echo ""
            increment_warning
        fi
    fi
done < <(find "$CHECK_PATH" -name "Makefile*" -type f -print0 2>/dev/null)

# Print summary
print_summary "Shared Library Usage Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "Shared libraries are properly used"
fi

exit $exit_code
