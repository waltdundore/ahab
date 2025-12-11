# Shared Libraries Quick Reference

![Ahab Logo](docs/images/ahab-logo.png)

## Overview

Use these shared libraries instead of duplicating code. All functions are tested and follow NASA Power of 10 standards.

## For Test Scripts

### Source the Library
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"
```

### Common Functions

**Prerequisites**:
```bash
check_standard_prerequisites          # Vagrant + VirtualBox
check_prerequisites_with_ansible      # Vagrant + VirtualBox + Ansible
```

**VM Management**:
```bash
cleanup_existing_vm                   # Remove old VMs
verify_vm_running                     # Check VM is running
vagrant_with_timeout 600 up          # Start VM with timeout
```

**Docker**:
```bash
check_docker_in_vm                    # Check/start Docker in VM
cleanup_docker_container "name"       # Remove container
```

**HTTP Testing**:
```bash
wait_for_http "http://localhost:8080" 15 "pattern"  # Wait for response
find_available_port 8080 10           # Find unused port
```

**File Creation**:
```bash
create_hello_world_html "index.html"  # Create test HTML
create_apache_role_files "$DIR"       # Create Apache role structure
create_apache_defaults "$DIR"         # Create Apache defaults
create_test_inventory "$DIR" "vm"     # Create Ansible inventory
```

**Output**:
```bash
print_success "Message"               # Green checkmark
print_error "Message"                 # Red X
print_info "Message"                  # Blue arrow
print_warning "Message"               # Yellow warning
print_section "Title"                 # Section header
```

## For Scripts

### Source the Library
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
```

### Common Functions

**Error Handling**:
```bash
die "Error message" 1                 # Print error and exit
require_file "config.yml"             # Check file exists or die
require_dir "modules"                 # Check directory exists or die
require_command "git"                 # Check command exists or die
```

**Validation**:
```bash
validate_version_format "1.0.0"       # Check semantic version
validate_identifier "my-module"       # Check alphanumeric + -_
validate_not_empty "$VAR" "name"      # Check non-empty
```

**Git Operations**:
```bash
check_git_repo                        # Verify in git repo
check_git_clean                       # Verify no uncommitted changes
check_git_tag_exists "v1.0.0"        # Check if tag exists
get_current_commit                    # Get commit hash
get_current_branch                    # Get branch name
```

**YAML Operations**:
```bash
check_yaml_field "file.yml" "name"    # Verify field exists
get_yaml_value "file.yml" "version"   # Extract field value
check_yaml_placeholders "file.yml"    # Find PLACEHOLDER text
```

**File Operations**:
```bash
create_backup "config.yml"            # Create .bak file
safe_remove "temp/"                   # Remove if exists
ensure_dir "output/"                  # Create if needed
```

**Prerequisites**:
```bash
check_prerequisites vagrant git       # Check multiple commands
```

**Validation Scripts**:
```bash
init_counters                         # Initialize ERRORS, WARNINGS
increment_error                       # Increment error count
increment_warning                     # Increment warning count
print_summary "Script Name"           # Print validation summary
```

**Argument Parsing**:
```bash
show_usage "script.sh" "<arg>"        # Display usage
require_arg "$1" "module" "usage"     # Require argument
```

**Module Registry**:
```bash
get_module_info "apache" "repo"       # Get module field
check_module_exists "apache"          # Verify module in registry
```

**Output**:
```bash
print_success "Message"               # Green checkmark
print_error "Message"                 # Red X
print_info "Message"                  # Blue arrow
print_warning "Message"               # Yellow warning
print_section "Title"                 # Section header
```

## Migration Example

### Before (Duplicated Code)
```bash
#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: Module name required${NC}"
    exit 1
fi

if [ ! -f "MODULE_REGISTRY.yml" ]; then
    echo -e "${RED}Error: Registry not found${NC}"
    exit 1
fi

if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Validation passed${NC}"
```

### After (Using Shared Library)
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arg "$1" "module name" "<module> <version>"
require_file "MODULE_REGISTRY.yml"
validate_version_format "$VERSION"

print_success "Validation passed"
```

**Result**: 18 lines → 9 lines (50% reduction)

## Benefits

✅ **Less code** - 50-70% reduction  
✅ **More readable** - Focus on business logic  
✅ **More reliable** - Tested functions  
✅ **More consistent** - Uniform behavior  
✅ **More maintainable** - Fix once, fixed everywhere  

## Rules

1. **Always use shared libraries** - Never duplicate
2. **Test after changes** - Run `make test`
3. **Add new patterns** - Extend libraries when needed
4. **Document usage** - Help future developers

## See Also

- `DRY_VIOLATIONS_AUDIT.md` - Test suite analysis
- `SCRIPT_DRY_ANALYSIS.md` - Script analysis
- `REFACTORING_SUMMARY.md` - Implementation details
- `DRY_REFACTORING_COMPLETE.md` - Complete summary
