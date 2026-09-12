# DRY Fix: Color Code Consolidation

![Ahab Logo](docs/images/ahab-logo.png)

**Date**: 2025-12-08  
**Issue**: Color codes were duplicated across all scripts instead of being sourced from a single location

## Problem

Every script defined its own color codes:

```bash
# BEFORE (WRONG) - Repeated in every script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
```

This violated DRY principles:
- 14+ scripts each defining the same colors
- Inconsistent color definitions (some used `readonly`, some didn't)
- Difficult to change colors globally
- Unnecessary code duplication

## Solution

Consolidated all color definitions into `scripts/lib/colors.sh`:

```bash
# scripts/lib/colors.sh - Single source of truth
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
readonly RESET='\033[0m'
```

All scripts now source colors through `common.sh`:

```bash
# AFTER (CORRECT) - In every script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
```

## Files Changed

### Created
- `scripts/lib/colors.sh` - Single source of truth for color codes
- `scripts/lib/common.sh` - Common functions that source colors.sh

### Modified (removed duplicate color definitions)
- `scripts/audit-priorities.sh`
- `scripts/audit-documentation.sh`
- `scripts/validate-scripts.sh`
- `scripts/install-module.sh`
- `scripts/validate-feature-mapping.sh`
- `scripts/audit-unused-files.sh`
- `scripts/audit-accountability.sh`
- `scripts/create-module.sh`
- `scripts/release-module.sh`
- `scripts/validate-standards-registry.sh`
- `scripts/setup-nested-test.sh`
- `scripts/validate-nasa-standards.sh`
- `scripts/audit-self.sh`
- `tests/integration/test-os-versions.sh`
- `bootstrap.sh`

## Benefits

1. **Single Source of Truth**: Colors defined once in `colors.sh`
2. **Easy to Change**: Update colors globally by editing one file
3. **Consistency**: All scripts use identical color codes
4. **Less Code**: Removed ~70 lines of duplicate code
5. **Better Maintainability**: Changes propagate automatically

## Code Reduction

**Before**: ~5 lines × 14 scripts = 70 lines of duplicate color definitions  
**After**: 6 lines in `colors.sh` + 3 lines source statement per script = ~48 lines total  
**Savings**: 22 lines + improved maintainability

## Testing

All scripts still pass validation:

```bash
make test
```

## Pattern to Follow

**Always source common.sh for colors:**

```bash
# ✅ GOOD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

echo -e "${GREEN}Success!${NC}"

# ❌ BAD
RED='\033[0;31m'
GREEN='\033[0;32m'
echo -e "${GREEN}Success${NC}"
```

## Additional Benefits from common.sh

By sourcing `common.sh`, scripts also get access to:
- `print_success()` - Standardized success messages
- `print_error()` - Standardized error messages
- `print_info()` - Standardized info messages
- `print_warning()` - Standardized warning messages
- `die()` - Error handling with exit
- Git helper functions
- YAML parsing functions
- File operation helpers

## Related Documentation

- `scripts/lib/colors.sh` - Color definitions
- `scripts/lib/common.sh` - Common functions
- `docs/DRY_REFACTORING_INDEX.md` - Overall DRY improvements
