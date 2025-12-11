# Technical Debt Tracking

| Script | Lines | Priority | Refactoring Plan | Target Date |
|--------|-------|----------|------------------|-------------|
| Script | Lines | Priority | Refactoring Plan | Target Date |
|--------|-------|----------|------------------|-------------|
| `scripts/audit-hardcoded-values.sh` | 415 | HIGH | Extract functions to lib/ directory | 2025-12-15 |
### Current Violations

| Script | Lines | Priority | Refactoring Plan | Target Date |
|--------|-------|----------|------------------|-------------|
| `scripts/audit-hardcoded-values.sh` | 415 | HIGH | Extract functions to lib/ directory | 2025-12-15 |
| `scripts/fix-hardcoded-values.sh` | 304 | HIGH | Extract functions to lib/ directory | 2025-12-15 |

### Refactoring Strategy
### Refactoring Strategy

#### 1. audit-hardcoded-values.sh (415 lines)

**Current Structure**:
- Main function (50+ lines)
- 6 scan functions (40-60 lines each)
- Utility functions (20-30 lines each)

**Refactoring Plan**:
```bash
# Extract to lib/security-audit.sh
- scan_hardcoded_usernames()
- scan_hardcoded_paths()
- scan_hardcoded_secrets()
- scan_hardcoded_ips()
- scan_hardcoded_urls()
- scan_hardcoded_config()

# Keep in main script (≤ 60 lines)
- main()
- print_header()
- print_summary()
- Configuration and setup
```

**Benefits**:
- Reusable security scanning functions
- Easier to test individual scanners
- Cleaner main script
- Follows single responsibility principle

#### 2. fix-hardcoded-values.sh (304 lines)

**Current Structure**:
- Main function (30+ lines)
- 4 fix functions (40-50 lines each)
- Utility functions (20-30 lines each)

**Refactoring Plan**:
```bash
# Extract to lib/hardcoded-fixes.sh
- fix_usernames()
- fix_paths()
- fix_urls()
- update_scripts_to_use_config()
- validate_fixes()

# Keep in main script (≤ 60 lines)
- main()
- print_header()
- print_summary()
- Argument parsing
- Configuration
```

**Benefits**:
- Reusable fix functions
- Easier to test individual fixes
- Modular approach to different fix types
- Better error handling per category

---

## Implementation Tasks

### Phase 1: Create Library Functions (Week of 2025-12-15)

- [ ] Create `ahab/scripts/lib/security-audit.sh`
  - [ ] Extract scan functions from audit-hardcoded-values.sh
  - [ ] Add proper error handling
  - [ ] Add unit tests for each function
  - [ ] Ensure functions are ≤ 60 lines each

- [ ] Create `ahab/scripts/lib/hardcoded-fixes.sh`
  - [ ] Extract fix functions from fix-hardcoded-values.sh
  - [ ] Add proper error handling
  - [ ] Add unit tests for each function
  - [ ] Ensure functions are ≤ 60 lines each

### Phase 2: Refactor Main Scripts (Week of 2025-12-22)

- [ ] Refactor `scripts/audit-hardcoded-values.sh`
  - [ ] Source lib/security-audit.sh
  - [ ] Reduce main script to ≤ 200 lines
  - [ ] Ensure all functions ≤ 60 lines
  - [ ] Maintain same CLI interface
  - [ ] Verify tests still pass

- [ ] Refactor `scripts/fix-hardcoded-values.sh`
  - [ ] Source lib/hardcoded-fixes.sh
  - [ ] Reduce main script to ≤ 200 lines
  - [ ] Ensure all functions ≤ 60 lines
  - [ ] Maintain same CLI interface
  - [ ] Verify tests still pass

### Phase 3: Validation (Week of 2025-12-29)

- [ ] Run function length validation
  - [ ] `make test-property` should pass
  - [ ] No functions > 60 lines
  - [ ] No scripts > 200 lines (warning threshold)

- [ ] Integration testing
  - [ ] `make audit-hardcoded` works same as before
  - [ ] `make fix-hardcoded` works same as before
  - [ ] All existing tests pass
  - [ ] Performance is same or better

---

## Prevention Measures

### Pre-Commit Hooks

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Check function length before commit
if ! ./tests/property/test-function-length-validation.sh; then
    echo "ERROR: Function length violations found"
    echo "See TECHNICAL_DEBT.md for refactoring guidance"
    exit 1
fi
```

### CI/CD Integration

Add to CI pipeline:
```bash
# Fail build on new function length violations
./tests/property/test-function-length-validation.sh || exit 1
```

### Code Review Checklist

- [ ] All new functions ≤ 60 lines
- [ ] No new scripts > 200 lines without refactoring plan
- [ ] Complex functions broken into smaller pieces
- [ ] Library functions used where appropriate

---

## Tracking Progress

### Completion Criteria

**audit-hardcoded-values.sh**:
- [ ] Main script ≤ 200 lines
- [ ] All functions ≤ 60 lines
- [ ] Library functions extracted
- [ ] Tests pass
- [ ] Same functionality

**fix-hardcoded-values.sh**:
- [ ] Main script ≤ 200 lines
- [ ] All functions ≤ 60 lines
- [ ] Library functions extracted
- [ ] Tests pass
- [ ] Same functionality

### Success Metrics

- Function length validation passes: `make test-property`
- No regressions: All existing tests pass
- Maintainability improved: Code easier to understand and modify
- Reusability increased: Library functions can be used elsewhere

---

## Related Documentation

- [Function Length Refactoring Rules](.kiro/steering/function-length-refactoring.md)
- [NASA Power of 10 Rules](docs/NASA_STANDARDS.md)
- [Code Quality Standards](docs/CODE_QUALITY.md)

---

## Notes

**Why track this separately?**
- Function length violations don't break functionality
- They make code harder to maintain over time
- NASA Rule #4 is about long-term code quality
- Better to fix systematically than ignore

**Why not fix immediately?**
- These scripts work correctly
- Refactoring requires careful testing
- Better to plan the refactoring properly
- Tracking ensures it doesn't get forgotten

**Priority rationale**:
- Both scripts are security-related (HIGH priority)
- They're used frequently in audits
- They're good candidates for library extraction
- Refactoring will benefit other security scripts

---

**Status**: ACTIVE  
**Owner**: Development Team  
**Review Date**: 2025-12-15
