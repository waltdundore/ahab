# shell-common.sh Quick Reference Card

![Ahab Logo](../docs/images/ahab-logo.png)

## How to Source

```bash
# In ahab/scripts/*.sh
source "$SCRIPT_DIR/lib/shell-common.sh"

# In ahab/tests/**/*.sh
source "$SCRIPT_DIR/../../scripts/lib/shell-common.sh"

# In root scripts/*.sh
source "$SCRIPT_DIR/../ahab/scripts/lib/shell-common.sh"
```

---

## Most Common Functions

### Output
```bash
print_success "Operation completed"     # ✓ Green
print_error "Something failed"          # ✗ Red (stderr)
print_info "Processing..."              # → Blue
print_warning "Deprecated feature"      # ⚠ Yellow
print_section "Configuration"           # Header with lines
```

### Error Handling
```bash
die "Fatal error" [exit_code]           # Print error and exit
require_file "config.yml"               # Exit if missing
require_command "docker"                # Exit if missing
```

### Checking (Non-Fatal)
```bash
if check_command "docker"; then         # Returns 0/1
if check_file "config.yml"; then        # Returns 0/1
```

### Test Assertions
```bash
assert_file_exists "test.txt"           # Fail if missing
assert_equals "expected" "$actual"      # Fail if different
assert_not_empty "$value"               # Fail if empty
assert_contains "$output" "success"     # Fail if not found
```

### Configuration
```bash
load_config                             # Load ahab.conf
value=$(get_config "KEY" "default")     # Get with default
value=$(require_config "KEY")           # Get or exit
```

### Validation
```bash
validate_identifier "$name"             # Alphanumeric only
validate_version_format "1.2.3"         # Semver format
validate_input "$input" "^[a-z]+$"      # Regex pattern
```

---

## Full Function List

| Category | Functions |
|----------|-----------|
| **Output** | print_success, print_error, print_info, print_warning, print_section, print_header |
| **Error Handling** | die, require_file, require_dir, require_command |
| **Checking** | check_command, check_file |
| **Assertions** | assert_command, assert_file_exists, assert_dir_exists, assert_equals, assert_not_empty, assert_contains, assert_exit_code |
| **Config** | load_config, get_config, require_config |
| **Validation** | validate_version_format, validate_identifier, validate_input, validate_not_empty |
| **Cross-Platform** | detect_os, sed_inplace, get_cpu_count |
| **Progress** | write_state, clear_state, show_progress |
| **Files** | create_backup, safe_remove, ensure_dir |

---

## Color Constants

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'        # No Color
RESET='\033[0m'     # Alias for NC
```

---

## Common Patterns

### Script with Config
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/shell-common.sh"

load_config
VERSION=$(get_config "VERSION" "1.0.0")
print_info "Version: $VERSION"
```

### Test Script
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/lib/shell-common.sh"

print_section "Test: File Operations"
assert_file_exists "README.md"
print_success "Test passed"
```

### Audit Script
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/shell-common.sh"

check_command "docker" || die "Docker required"
print_success "Audit complete"
```

---

## See Also

- **Full Documentation:** `ahab/docs/development/SHELL_LIBRARY_CONSOLIDATION.md`
- **Migration Guide:** `ahab/docs/development/SHELL_LIBRARY_MIGRATION_CHECKLIST.md`
- **Source Code:** `ahab/scripts/lib/shell-common.sh`
