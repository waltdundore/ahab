# Pre-Release Checklist Validators

This directory contains validation scripts for the pre-release checklist system.

## Structure

```
validators/
├── lib/
│   └── common.sh              # Shared utility functions
├── validate-code-compliance.sh
├── validate-documentation.sh
├── validate-file-organization.sh
├── validate-gitignore.sh
├── validate-tests.sh
├── validate-branding.sh
├── validate-architecture.sh
├── validate-code-quality.sh
├── validate-dependencies.sh
├── validate-changelog.sh
├── validate-consolidation.sh
└── validate-security.sh
```

## Validator Interface

Each validator script must follow this interface:

### Exit Codes
- `0` - Validation passed
- `1` - Validation failed

### Output Format
- Use `report_error()` for errors
- Use `report_warning()` for warnings
- Use `report_success()` for successes
- Use `report_info()` for informational messages

### Example Validator

```bash
#!/bin/bash
# Validator: Example
# Purpose: Demonstrate validator structure

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Validator logic
validate_example() {
    local errors=0
    
    print_section "Checking example requirement"
    
    # Perform checks
    if [ some_condition ]; then
        report_error "Error message"
        ((errors++))
    else
        report_success "Check passed"
    fi
    
    return $errors
}

# Main
main() {
    print_header "Example Validator"
    
    local exit_code=0
    validate_example || exit_code=$?
    
    print_summary "Example Validator"
    
    return $exit_code
}

main "$@"
```

## Available Utility Functions

See `lib/common.sh` for complete documentation. Key functions:

### Error Reporting
- `report_error "message"` - Report an error
- `report_warning "message"` - Report a warning
- `report_success "message"` - Report success
- `report_info "message"` - Report info

### File Scanning
- `find_files "*.sh"` - Find files matching pattern
- `find_shell_scripts` - Find all shell scripts
- `find_python_files` - Find all Python files
- `find_markdown_files` - Find all Markdown files
- `find_makefiles` - Find all Makefiles

### Pattern Matching
- `file_contains "pattern" "file"` - Check if file contains pattern
- `count_pattern "pattern" "file"` - Count pattern occurrences
- `find_files_with_pattern "pattern" "*.sh"` - Find files with pattern

### Validation Helpers
- `command_exists "cmd"` - Check if command exists
- `is_tracked_by_git "file"` - Check if file is tracked
- `is_gitignored "file"` - Check if file is gitignored
- `is_temp_file "file"` - Check if file is temporary
- `is_build_artifact "file"` - Check if file is build artifact

### Output Formatting
- `print_header "text"` - Print colored header
- `print_section "text"` - Print colored section
- `print_summary "validator"` - Print validation summary

## Adding a New Validator

1. Create new script: `validate-<name>.sh`
2. Follow the validator interface pattern
3. Make script executable: `chmod +x validate-<name>.sh`
4. Add to orchestrator's validator list in `../pre-release-check.sh`
5. Add tests in `../../tests/validators/`
6. Document in design document

## Testing Validators

```bash
# Test individual validator
./validate-code-compliance.sh

# Test all validators via orchestrator
cd ../..
./scripts/pre-release-check.sh

# Test with strict mode
./scripts/pre-release-check.sh --strict

# Test with auto-fix
./scripts/pre-release-check.sh --fix
```

## Configuration

Validators respect configuration from `.pre-release-check.conf`:
- `STRICT_MODE` - Treat warnings as errors
- `FIX_MODE` - Attempt auto-fixes
- Validator-specific settings

## Best Practices

1. **Use common utilities** - Don't reinvent file scanning, error reporting
2. **Follow exit code convention** - 0 = pass, 1 = fail
3. **Provide clear messages** - Explain what failed and how to fix
4. **Be idempotent** - Running twice should give same result
5. **Handle edge cases** - Empty files, missing directories, etc.
6. **Document checks** - Comment what each check does
7. **Test thoroughly** - Unit, property, and integration tests

## Related Documents

- Design: `.kiro/specs/pre-release-checklist/design.md`
- Requirements: `.kiro/specs/pre-release-checklist/requirements.md`
- Tasks: `.kiro/specs/pre-release-checklist/tasks.md`
