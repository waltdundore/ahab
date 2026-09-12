# Color Code Consolidation

**Date**: December 9, 2025  
**Status**: Complete  
**Principle**: DRY (Don't Repeat Yourself)

---

## Problem

Color codes were duplicated across multiple scripts:
- `ahab/tests/property/*.sh` - Each defined RED, GREEN, YELLOW, etc.
- `ahab/scripts/*.sh` - Each defined their own colors
- `tests/property/*.sh` - Root-level tests duplicated colors
- `ahab/tests/lib/test-helpers.sh` - Had its own color definitions

**Total duplication**: 8+ files defining the same ANSI color codes.

---

## Solution

Created single source of truth: `ahab/lib/colors.sh`

### What It Provides

```bash
# Standard colors
RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE

# Text formatting
BOLD, DIM, UNDERLINE

# Reset
NC (No Color)

# Semantic colors (for consistent meaning)
COLOR_SUCCESS, COLOR_ERROR, COLOR_WARNING, COLOR_INFO, COLOR_DEBUG
```

### Usage Pattern

```bash
#!/usr/bin/env bash

# Source shared colors (DRY)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"

# Use colors
echo -e "${GREEN}✓ Success${NC}"
echo -e "${RED}✗ Error${NC}"
echo -e "${YELLOW}⚠ Warning${NC}"
```

---

## Files Updated

### Core Library
- ✅ `ahab/lib/colors.sh` - Created (single source of truth)

### Test Infrastructure
- ✅ `ahab/tests/lib/test-helpers.sh` - Now sources colors.sh
- ✅ `ahab/tests/property/test-inventory-make-commands.sh`
- ✅ `ahab/tests/property/test-make-command-detection.sh`

### Scripts
- ✅ `ahab/scripts/audit-dependencies.sh`
- ✅ `ahab/scripts/clean-unused-boxes.sh`

### Root-Level Tests
- ✅ `tests/property/test-config-loading.sh`
- ✅ `tests/property/test-input-validation.sh`

### GUI Scripts
- ⚠️ `ahab-gui/scripts/validate.sh` - Kept local colors (separate repo)

---

## Benefits

### Before (Duplicated)
```bash
# In 8+ files:
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
```

**Problems**:
- Duplication across files
- Inconsistent color definitions
- Hard to maintain
- Easy to forget colors in new scripts

### After (DRY)
```bash
# In 1 file (ahab/lib/colors.sh):
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
# ... etc

# In all other files:
source "$SCRIPT_DIR/../lib/colors.sh"
```

**Benefits**:
- ✅ Single source of truth
- ✅ Consistent colors everywhere
- ✅ Easy to maintain
- ✅ Easy to extend (add new colors once)
- ✅ Prevents typos/inconsistencies

---

## Adding New Scripts

When creating new scripts in `ahab/`:

```bash
#!/usr/bin/env bash

# Source shared colors (DRY)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"

# Now use colors
echo -e "${GREEN}✓ Ready${NC}"
```

**Path adjustments**:
- From `ahab/scripts/`: `source "$SCRIPT_DIR/../lib/colors.sh"`
- From `ahab/tests/`: `source "$SCRIPT_DIR/../lib/colors.sh"`
- From `ahab/tests/property/`: `source "$SCRIPT_DIR/../../lib/colors.sh"`
- From root `tests/`: `source "$SCRIPT_DIR/../ahab/lib/colors.sh"`

---

## Semantic Colors

For consistent meaning across all scripts:

```bash
# Use semantic names for clarity
echo -e "${COLOR_SUCCESS}Operation complete${NC}"
echo -e "${COLOR_ERROR}Operation failed${NC}"
echo -e "${COLOR_WARNING}Potential issue${NC}"
echo -e "${COLOR_INFO}Information${NC}"
echo -e "${COLOR_DEBUG}Debug output${NC}"
```

This makes intent clearer than raw color names.

---

## Testing

Verify colors work:

```bash
cd ahab
bash -c 'source lib/colors.sh && echo -e "${GREEN}✓ Success${NC}"'
bash -c 'source lib/colors.sh && echo -e "${RED}✗ Error${NC}"'
bash -c 'source lib/colors.sh && echo -e "${YELLOW}⚠ Warning${NC}"'
```

All scripts should continue working with no behavior changes.

---

## Future Improvements

### Potential Enhancements
1. Add more semantic colors (COLOR_HEADER, COLOR_PROMPT, etc.)
2. Add color disable flag for CI/non-TTY environments
3. Add color theme support (light/dark mode)
4. Add 256-color support for terminals that support it

### Example: CI-Friendly Colors
```bash
# In colors.sh, detect if output is to terminal
if [ -t 1 ]; then
    # Terminal - use colors
    readonly RED='\033[0;31m'
else
    # Non-terminal (CI) - no colors
    readonly RED=''
fi
```

---

## Related Standards

- **DRY Principle**: Don't Repeat Yourself
- **Single Source of Truth**: One place to define colors
- **Maintainability**: Easy to update all scripts at once
- **Consistency**: Same colors mean same things everywhere

---

## Verification

Run tests to ensure nothing broke:

```bash
cd ahab
make test
```

All tests should pass with colored output working correctly.

---

**Status**: ✅ Complete  
**Impact**: 8+ files consolidated to 1 shared library  
**Breaking Changes**: None (all scripts work as before)
