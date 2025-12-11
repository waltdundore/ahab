# Shell Library Migration Checklist

![Ahab Logo](../docs/images/ahab-logo.png)

## Overview

This checklist tracks the migration from duplicate library files to the consolidated `shell-common.sh`.

**Goal:** All scripts and tests should source `ahab/scripts/lib/shell-common.sh` instead of duplicate libraries.

---

## Phase 1: Create New Library ✅

- [x] Create `ahab/scripts/lib/shell-common.sh` with all common functions
- [x] Document all functions with clear comments
- [x] Organize into logical sections
- [x] Create comprehensive documentation (SHELL_LIBRARY_CONSOLIDATION.md)

---

## Phase 2: Update Ahab Scripts

### Audit Scripts
- [ ] `ahab/scripts/audit-accountability.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh
  
- [ ] `ahab/scripts/audit-dependencies.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh
  
- [ ] `ahab/scripts/audit-self.sh`
  - Currently: Sources common.sh
  - Action: Update to source shell-common.sh
  
- [ ] `ahab/scripts/audit-unused-files.sh`
  - Currently: Sources common.sh
  - Action: Update to source shell-common.sh

### Validation Scripts
- [ ] `ahab/scripts/validate-feature-mapping.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh
  
- [ ] `ahab/scripts/validate-standards-registry.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh

### Other Scripts
- [ ] Check for any other scripts in `ahab/scripts/`
- [ ] Update each to source shell-common.sh

---

## Phase 3: Update Ahab Tests

### Unit Tests
- [ ] `ahab/tests/unit/test-audit-arg-parsing.sh`
  - Currently: Sources test-helpers.sh and assertions.sh
  - Action: Update to source shell-common.sh
  
- [ ] `ahab/tests/unit/test-audit-compliance.sh`
  - Currently: Sources test-helpers.sh and assertions.sh
  - Action: Update to source shell-common.sh
  
- [ ] `ahab/tests/unit/test-audit-dependencies.sh`
  - Currently: Sources test-helpers.sh and assertions.sh
  - Action: Update to source shell-common.sh
  
- [ ] `ahab/tests/unit/test-script-tool-usage.sh`
  - Currently: Sources test-helpers.sh
  - Action: Update to source shell-common.sh

### Property Tests
- [ ] Check for property tests in `ahab/tests/property/`
- [ ] Update each to source shell-common.sh

### Integration Tests
- [ ] Check for integration tests
- [ ] Update each to source shell-common.sh
- [ ] Keep VM/Docker-specific functions in test-helpers.sh

---

## Phase 4: Update Root Scripts

### Audit Scripts
- [ ] `scripts/audit-documentation.sh`
  - Currently: Sources common.sh
  - Action: Update to source ../ahab/scripts/lib/shell-common.sh
  
- [ ] `scripts/audit-priorities.sh`
  - Currently: Sources common.sh
  - Action: Update to source ../ahab/scripts/lib/shell-common.sh
  
- [ ] `scripts/audit-unused-files.sh`
  - Currently: Empty
  - Action: If implemented, use shell-common.sh

---

## Phase 5: Update Root Tests

### Property Tests
- [ ] `tests/property/test-config-loading.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh
  
- [ ] `tests/property/test-input-validation.sh`
  - Currently: Defines own print functions
  - Action: Remove duplicates, source shell-common.sh

### Unit Tests
- [ ] `tests/unit/test-common-lib.sh`
  - Currently: Sources test-helpers.sh and assertions.sh
  - Action: Update to source shell-common.sh
  - Note: This tests the OLD common.sh - may need to update to test shell-common.sh

---

## Phase 6: Update Library Files for Backward Compatibility

### Root Libraries
- [ ] `scripts/lib/common.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper
  
- [ ] `scripts/lib/colors.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper

### Root Test Libraries
- [ ] `tests/lib/test-helpers.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper
  
- [ ] `tests/lib/assertions.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper

### Ahab Libraries
- [ ] `ahab/scripts/lib/common.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper
  
- [ ] `ahab/scripts/lib/colors.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper

### Ahab Test Libraries
- [ ] `ahab/tests/lib/test-helpers.sh`
  - Action: Keep VM/Docker functions, source shell-common.sh for common functions
  - This file has unique functions worth keeping
  
- [ ] `ahab/tests/lib/assertions.sh`
  - Action: Update to source shell-common.sh for backward compatibility
  - Keep file but make it a thin wrapper

---

## Phase 7: Testing

### Test Each Updated Script
- [ ] Run each updated script manually
- [ ] Verify no errors
- [ ] Verify output looks correct

### Run Test Suite
- [ ] Run `make test` in ahab/
- [ ] Run `make test` in root (if exists)
- [ ] Verify all tests pass

### Test Backward Compatibility
- [ ] Verify old scripts that haven't been updated still work
- [ ] Verify wrapper files work correctly

---

## Phase 8: Documentation

- [x] Create SHELL_LIBRARY_CONSOLIDATION.md
- [x] Create SHELL_LIBRARY_MIGRATION_CHECKLIST.md (this file)
- [ ] Update DEVELOPMENT_RULES.md to mention shell-common.sh
- [ ] Update README.md if it mentions library files
- [ ] Add entry to CHANGELOG.md

---

## Phase 9: Cleanup (Optional - After Full Migration)

### Consider Removing Old Files
Once ALL scripts are migrated and tested:

- [ ] Remove `scripts/lib/common.sh` (or keep as thin wrapper)
- [ ] Remove `scripts/lib/colors.sh` (or keep as thin wrapper)
- [ ] Remove `tests/lib/test-helpers.sh` (or keep as thin wrapper)
- [ ] Remove `tests/lib/assertions.sh` (or keep as thin wrapper)
- [ ] Remove `ahab/scripts/lib/common.sh` (or keep as thin wrapper)
- [ ] Remove `ahab/scripts/lib/colors.sh` (or keep as thin wrapper)
- [ ] Remove `ahab/tests/lib/assertions.sh` (or keep as thin wrapper)
- [ ] Keep `ahab/tests/lib/test-helpers.sh` (has unique VM/Docker functions)

**Note:** Recommend keeping as thin wrappers for at least one release cycle to ensure nothing breaks.

---

## Phase 10: Announcement

- [ ] Announce migration in team communication
- [ ] Update any external documentation
- [ ] Add deprecation warnings to old library files
- [ ] Update any CI/CD scripts if needed

---

## Migration Script Template

For each script/test file, follow this pattern:

### Before:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/colors.sh"

# Duplicate function definitions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Script logic...
```

### After:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/shell-common.sh"

# No duplicate functions needed - provided by shell-common.sh

# Script logic...
```

---

## Verification Commands

### Check for Duplicate Function Definitions
```bash
# Find scripts that define print_success
grep -r "^print_success()" ahab/scripts/ ahab/tests/ scripts/ tests/

# Find scripts that define print_error
grep -r "^print_error()" ahab/scripts/ ahab/tests/ scripts/ tests/
```

### Check for Old Library Sources
```bash
# Find scripts sourcing old libraries
grep -r "source.*lib/common.sh" ahab/scripts/ ahab/tests/ scripts/ tests/
grep -r "source.*lib/colors.sh" ahab/scripts/ ahab/tests/ scripts/ tests/
grep -r "source.*lib/test-helpers.sh" ahab/tests/ tests/
```

### Check for New Library Sources
```bash
# Find scripts sourcing new library
grep -r "source.*shell-common.sh" ahab/scripts/ ahab/tests/ scripts/ tests/
```

---

## Success Criteria

Migration is complete when:

1. ✅ shell-common.sh exists and is well-documented
2. ⏳ All scripts source shell-common.sh (directly or via wrapper)
3. ⏳ No duplicate function definitions in scripts
4. ⏳ All tests pass
5. ⏳ Old library files are wrappers or removed
6. ⏳ Documentation is updated
7. ⏳ CHANGELOG.md has entry

---

## Rollback Plan

If migration causes issues:

1. Keep old library files as-is
2. Revert scripts to source old libraries
3. Investigate issues
4. Fix shell-common.sh
5. Retry migration

The old files should NOT be deleted until we're confident the migration is successful.

---

## Notes

- **Priority:** High - This eliminates significant technical debt
- **Risk:** Medium - Could break scripts if not careful
- **Effort:** Medium - Systematic but straightforward
- **Impact:** High - Major improvement in maintainability

---

## Questions?

If you encounter issues during migration:

1. Check SHELL_LIBRARY_CONSOLIDATION.md for usage examples
2. Check shell-common.sh for function definitions
3. Test your changes before committing
4. Ask for help if stuck

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-08  
**Status:** Active - Migration In Progress
