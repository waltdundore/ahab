# Shell Library Documentation

![Ahab Logo](../docs/images/ahab-logo.png)

**Single Source of Truth for Common Shell Functions**

## Overview

This directory contains the shared shell library used by all scripts in the Ahab project. Following the DRY (Don't Repeat Yourself) principle, all common functionality is consolidated here.

## Files

### `common.sh` - The Universal Shell Library

**This is the ONLY common library.** All scripts must source this file for shared functionality.

**Usage in scripts:**
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
```

**Usage in tests:**
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "$SCRIPT_DIR/../../scripts/lib/common.sh"
```

## Available Functions

### Color Definitions
- `RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`, `RESET` - ANSI color codes

### Output Functions
- `print_success(message)` - Print success message with green checkmark
- `print_error(message)` - Print error message with red X to stderr
- `print_info(message)` - Print info message with blue arrow
- `print_warning(message)` - Print warning message with yellow symbol
- `print_section(title)` - Print section header with separator lines
- `print_header(message)` - Print large header (bigger than section)
- `print_summary()` - Print summary of checks/errors/warnings

### Error Handling
- `die(message, [exit_code])` - Exit with error message
- `require_file(file, [error_msg])` - Require file exists or exit
- `require_dir(dir, [error_msg])` - Require directory exists or exit
- `require_command(cmd, [install_msg])` - Require command exists or exit
- `require_arg(arg, name)` - Require argument is not empty or exit

### Command Checking (Non-Fatal)
- `check_command(cmd, [help_msg])` - Check if command exists (returns 0/1)
- `check_file(file, [error_msg])` - Check if file exists (returns 0/1)
- `check_prerequisites()` - Check for required commands

### Test Assertions
- `assert_command(cmd, [error_msg])` - Assert command exists
- `assert_file_exists(file, [error_msg])` - Assert file exists
- `assert_dir_exists(dir, [error_msg])` - Assert directory exists
- `assert_equals(expected, actual, [error_msg])` - Assert strings equal
- `assert_not_empty(value, [error_msg])` - Assert string not empty
- `assert_contains(haystack, needle, [error_msg])` - Assert string contains substring
- `assert_exit_code(expected, actual, [error_msg])` - Assert exit code matches

### Configuration Management
- `load_config()` - Load ahab.conf (searches up directory tree)
- `get_config(key, [default])` - Get config value with optional default
- `require_config(key, [error_msg])` - Get config value or exit

### Input Validation
- `validate_version_format(version)` - Validate MAJOR.MINOR.PATCH format
- `validate_identifier(identifier, [name])` - Validate alphanumeric + hyphens/underscores
- `validate_input(input, [pattern], [name])` - Validate against regex pattern
- `validate_not_empty(value, [name])` - Validate not empty or exit

### Cross-Platform Helpers
- `detect_os()` - Returns: linux, darwin, or unknown
- `sed_inplace(expression, file)` - Cross-platform sed in-place editing
- `get_cpu_count()` - Get number of CPU cores

### Git Operations
- `check_git_repo()` - Check if in git repository
- `check_git_clean()` - Check if git working directory is clean
- `check_git_branch_exists(branch)` - Check if branch exists
- `check_git_tag_exists(tag)` - Check if tag exists
- `get_current_branch()` - Get current git branch name
- `get_current_commit()` - Get current git commit hash

### YAML Operations
- `get_yaml_value(file, key)` - Get value from YAML file
- `check_yaml_field(file, field)` - Check if YAML field exists
- `check_yaml_placeholders(file)` - Check for placeholder values

### Module Operations
- `check_module_exists(module)` - Check if module exists in registry
- `get_module_info(module, field)` - Get module info from registry

### Progress Feedback
- `write_state(state, [state_file])` - Write diagnostic state for troubleshooting
- `clear_state([state_file])` - Clear diagnostic state file
- `show_progress(current, total, [message])` - Show progress indicator
- `start_spinner([message])` - Start spinner for long operations
- `stop_spinner()` - Stop spinner
- `show_usage(usage_text)` - Show usage information

### File Operations
- `create_backup(file)` - Create backup of file
- `safe_remove(path)` - Safely remove file or directory
- `ensure_dir(dir)` - Ensure directory exists (create if needed)

### Counter Functions
- `init_counters()` - Initialize check/error/warning counters
- `increment_check()` - Increment check counter
- `increment_error()` - Increment error counter
- `increment_warning()` - Increment warning counter

## Consolidation History

**2025-12-08:** Consolidated all shell libraries into single `common.sh`
- Merged `shell-common.sh` (deleted)
- Inlined `colors.sh` (deleted)
- Added assertion functions for testing
- Added `print_header()` function

**Previous state:**
- `scripts/lib/common.sh` - Used by 24 scripts
- `scripts/lib/shell-common.sh` - Claimed to be "universal", used by 0 scripts
- `scripts/lib/colors.sh` - Color definitions

**Current state:**
- `scripts/lib/common.sh` - SINGLE SOURCE OF TRUTH, used by all scripts

## Design Principles

### DRY (Don't Repeat Yourself)
- **One definition, many uses** - Functions defined once, used everywhere
- **No duplication** - If you need a function, add it here, don't copy it
- **Single source of truth** - Bug fixes happen in one place

### Consistency
- All scripts use identical functions
- Consistent error messages and formatting
- Predictable behavior across the codebase

### Maintainability
- Fix bugs in one place, benefit everywhere
- Easy to add new common functionality
- Clear documentation of available functions

### Testability
- Test once, trust everywhere
- Assertion functions for writing tests
- Diagnostic state tracking for debugging

## Adding New Functions

**Before adding a new function:**
1. Check if similar functionality already exists
2. Consider if it's truly common (used by multiple scripts)
3. Document it clearly with usage examples
4. Add it to this README

**Function naming conventions:**
- `check_*` - Non-fatal checks that return 0/1
- `require_*` - Fatal checks that exit on failure
- `assert_*` - Test assertions that return 0/1
- `print_*` - Output formatting functions
- `get_*` - Getter functions that return values
- `validate_*` - Input validation functions

## Migration Guide

**If you have a script with duplicate functions:**

1. Remove the duplicate function definitions
2. Source `common.sh` at the top of your script
3. Use the common functions instead
4. Test your script to ensure it still works

**Example:**

Before:
```bash
#!/usr/bin/env bash

# Duplicate function
die() {
    echo "ERROR: $1" >&2
    exit 1
}

# Your script code
die "Something went wrong"
```

After:
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Your script code
die "Something went wrong"
```

## Testing

All functions in `common.sh` should be tested. Tests are located in `tests/lib/`.

Run tests with:
```bash
make test
```

## Questions?

See the main project documentation or ask in the development channel.

---

**Remember:** This is the SINGLE SOURCE OF TRUTH for common shell functions. Always source this file, never duplicate functions.
