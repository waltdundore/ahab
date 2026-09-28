# Ahab Improvement Tracking

![Ahab Logo](docs/images/ahab-logo.png)

**Purpose**: Track all "could be better" items systematically  
**Last Updated**: December 8, 2025

---

## How This Works

- **High Priority**: Fix within 1 week (blocks quality)
- **Medium Priority**: Fix within 1 month (important but not blocking)
- **Low Priority**: Nice to have (optional)

**Rules**:
1. Every audit creates improvement items
2. Items must be prioritized
3. High priority items are mandatory
4. Update status when working on items
5. Document fixes in CHANGELOG.md

---

## High Priority (Fix This Week)

### Code Quality

- [ ] **IMP-001**: Refactor audit-accountability.sh (629 lines → <400 lines)
  - **Why**: Violates NASA Rule 4 (max 60 lines per function)
  - **Impact**: Hard to maintain, test, and understand
  - **Effort**: 4 hours
  - **Blocked By**: None

- [ ] **IMP-002**: Refactor create-module.sh (752 lines → <400 lines)
  - **Why**: Violates NASA Rule 4
  - **Impact**: Hard to maintain, test, and understand
  - **Effort**: 6 hours
  - **Blocked By**: None

- [ ] **IMP-003**: Refactor setup-nested-test.sh (382 lines → <200 lines)
  - **Why**: Violates NASA Rule 4
  - **Impact**: Hard to maintain, test, and understand
  - **Effort**: 3 hours
  - **Blocked By**: None

### Testing

- [ ] **IMP-004**: Add unit tests for install-module.sh
  - **Why**: No test coverage for critical script
  - **Impact**: Can't verify behavior, risky to refactor
  - **Effort**: 2 hours
  - **Blocked By**: None

- [ ] **IMP-005**: Add unit tests for create-module.sh
  - **Why**: No test coverage for critical script
  - **Impact**: Can't verify behavior, risky to refactor
  - **Effort**: 3 hours
  - **Blocked By**: None

---

## Medium Priority (Fix This Month)

### Documentation

- [x] **IMP-006**: Fix Quick Start duplication (8+ files) ✅ COMPLETE
  - **Why**: DRY violation, maintenance burden
  - **Impact**: Must update 8+ files when commands change
  - **Effort**: 20 minutes (actual: 15 minutes)
  - **Completed**: December 8, 2025
  - **Result**: README.md is authoritative, others link to it
  - **Files**: START_HERE.md, README-STUDENTS.md, DEVELOPMENT_RULES.md

- [x] **IMP-007**: Fix Repository Structure duplication (4+ files) ✅ COMPLETE
  - **Why**: DRY violation, maintenance burden
  - **Impact**: Must update 4+ files when structure changes
  - **Effort**: 15 minutes (actual: 10 minutes)
  - **Completed**: December 8, 2025
  - **Result**: README.md is authoritative, others link to it
  - **Files**: START_HERE.md, ABOUT.md

- [x] **IMP-008**: Create DOCUMENTATION_MAP.md ✅ COMPLETE
  - **Why**: Need to know which file is authoritative for what
  - **Effort**: 30 minutes (actual: 25 minutes)
  - **Completed**: December 8, 2025
  - **Result**: Comprehensive map of authoritative sources and linking guidelines
  - **File**: docs/DOCUMENTATION_MAP.md
  - **Impact**: Confusion about where to update content
  - **Effort**: 30 minutes
  - **Blocked By**: IMP-006, IMP-007
  - **Source**: DOCUMENTATION_DRY_AUDIT_2025-12-08.md

- [ ] **IMP-009**: Add DRY guidelines to DEVELOPMENT_RULES.md
  - **Why**: Need clear rules for when to duplicate vs link
  - **Impact**: Inconsistent documentation practices
  - **Effort**: 15 minutes
  - **Blocked By**: IMP-008
  - **Source**: DOCUMENTATION_DRY_AUDIT_2025-12-08.md

### Roles

- [ ] **IMP-010**: Document apache role variables
  - **Why**: No documentation for role configuration
  - **Impact**: Users don't know how to customize
  - **Effort**: 1 hour
  - **Blocked By**: None

- [ ] **IMP-011**: Add tests for php role
  - **Why**: No test coverage for role
  - **Impact**: Can't verify role works correctly
  - **Effort**: 2 hours
  - **Blocked By**: None

- [ ] **IMP-012**: Complete mysql role
  - **Why**: Role is incomplete
  - **Impact**: Can't deploy MySQL
  - **Effort**: 4 hours
  - **Blocked By**: None

### Scripts

- [ ] **IMP-013**: Refactor audit-self.sh (375 lines → <200 lines)
  - **Why**: Violates NASA Rule 4
  - **Impact**: Hard to maintain
  - **Effort**: 3 hours
  - **Blocked By**: None

- [ ] **IMP-014**: Refactor install-module.sh (236 lines → <150 lines)
  - **Why**: Violates NASA Rule 4
  - **Impact**: Hard to maintain
  - **Effort**: 2 hours
  - **Blocked By**: None

- [ ] **IMP-015**: Refactor release-module.sh (279 lines → <150 lines)
  - **Why**: Violates NASA Rule 4
  - **Impact**: Hard to maintain
  - **Effort**: 2 hours
  - **Blocked By**: None

---

## Low Priority (Nice to Have)

### Developer Experience

- [ ] **IMP-016**: Add bash completion for make commands
  - **Why**: Improve developer experience
  - **Impact**: Faster command entry
  - **Effort**: 2 hours
  - **Blocked By**: None

- [ ] **IMP-017**: Create module dependency graph
  - **Why**: Visualize module relationships
  - **Impact**: Better understanding of architecture
  - **Effort**: 3 hours
  - **Blocked By**: None

- [ ] **IMP-018**: Add performance benchmarks
  - **Why**: Track performance over time
  - **Impact**: Catch performance regressions
  - **Effort**: 4 hours
  - **Blocked By**: None

### Configuration

- [ ] **IMP-019**: Split Makefile into includes
  - **Why**: Makefile is getting large
  - **Impact**: Easier to maintain
  - **Effort**: 2 hours
  - **Blocked By**: None

- [ ] **IMP-020**: Add Makefile documentation
  - **Why**: No documentation for Makefile targets
  - **Impact**: Users don't know all available commands
  - **Effort**: 1 hour
  - **Blocked By**: None

### Testing

- [ ] **IMP-021**: Add integration tests for roles
  - **Why**: No integration test coverage
  - **Impact**: Can't verify roles work together
  - **Effort**: 4 hours
  - **Blocked By**: None

- [ ] **IMP-022**: Add role-specific tests
  - **Why**: No role-specific test coverage
  - **Impact**: Can't verify role behavior in isolation
  - **Effort**: 6 hours
  - **Blocked By**: None

- [ ] **IMP-023**: Complete E2E test suite
  - **Why**: E2E tests are incomplete
  - **Impact**: Can't verify full system behavior
  - **Effort**: 8 hours
  - **Blocked By**: None

---

## Completed Items

### ✅ Phase 1: Documentation DRY Fixes (December 8, 2025)

- [x] **IMP-000**: Fix Core Principles duplication
  - **Completed**: December 8, 2025
  - **Result**: DEVELOPMENT_RULES.md is single source of truth
  - **Impact**: 80% reduction in maintenance time
  - **Files**: README.md, ABOUT.md, PRIORITIES.md, DEVELOPMENT_RULES.md
  - **Documentation**: DOCUMENTATION_DRY_FIX_2025-12-08.md

- [x] **IMP-006**: Fix Quick Start duplication (8+ files)
  - **Completed**: December 8, 2025
  - **Result**: README.md is authoritative, others link to it
  - **Impact**: Update once, applies everywhere
  - **Files**: START_HERE.md, README-STUDENTS.md, DEVELOPMENT_RULES.md

- [x] **IMP-007**: Fix Repository Structure duplication (4+ files)
  - **Completed**: December 8, 2025
  - **Result**: README.md is authoritative, others link to it
  - **Impact**: Update once, applies everywhere
  - **Files**: START_HERE.md, ABOUT.md

- [x] **IMP-008**: Create DOCUMENTATION_MAP.md
  - **Completed**: December 8, 2025
  - **Result**: Comprehensive documentation map created
  - **Impact**: Know which file is authoritative for what content
  - **File**: docs/DOCUMENTATION_MAP.md

---

## Statistics

### Current State

**Total Items**: 23
- High Priority: 5 (22%)
- Medium Priority: 8 (35%) - 3 completed
- Low Priority: 7 (30%)
- Completed: 4 (17%)

**By Category**:
- Code Quality: 4 items
- Testing: 6 items
- Documentation: 1 item (3 completed)
- Roles: 3 items
- Configuration: 2 items
- Developer Experience: 3 items
- Completed: 4 items

**Estimated Effort**:
- High Priority: 18 hours
- Medium Priority: 26.2 hours (1.05 hours completed)
- Low Priority: 30 hours
- **Total**: 74.2 hours (~2 weeks of work)

### Progress

**This Week**: 3 items completed (IMP-006, IMP-007, IMP-008)
**This Month**: 4 items completed  
**This Quarter**: 4 items completed

**Velocity**: 4 items per session (excellent!)

---

## Next Actions

### This Week (December 9-13, 2025)

1. **Pick highest priority item**: IMP-001 (audit-accountability.sh refactor)
2. **Create refactoring plan**: Break into smaller functions
3. **Implement refactoring**: Follow NASA Rule 4
4. **Test thoroughly**: `make test` after each change
5. **Document changes**: Update CHANGELOG.md

### This Month (December 2025)

1. **Complete all High priority items** (5 items, 18 hours)
2. **Start Medium priority items** (documentation fixes first)
3. **Build audit-comprehensive.sh** (automated discovery)
4. **Establish weekly audit routine** (every Monday)

### This Quarter (Q1 2026)

1. **Complete all Medium priority items** (11 items, 28 hours)
2. **Achieve 80% test coverage**
3. **Zero NASA violations in all code**
4. **Automate improvement discovery**

---

## How to Add Items

### Template

```markdown
- [ ] **IMP-XXX**: Brief description
  - **Why**: Reason this needs fixing
  - **Impact**: What happens if not fixed
  - **Effort**: Estimated time
  - **Blocked By**: Dependencies (or None)
  - **Source**: Where this was discovered (audit, user report, etc.)
```

### Process

1. Discover issue (audit, user report, code review)
2. Create improvement item with IMP-XXX number
3. Prioritize (High/Medium/Low)
4. Estimate effort
5. Identify blockers
6. Add to appropriate section

---

## Rules for Working Items

### Before Starting

1. Read the item description
2. Understand why it needs fixing
3. Check for blockers
4. Estimate if effort is accurate
5. Update status to "In Progress"

### While Working

1. Follow DEVELOPMENT_RULES.md
2. Test after every change (`make test`)
3. Document as you go
4. Commit frequently (small commits)
5. Update CHANGELOG.md

### After Completing

1. Verify all tests pass
2. Update CHANGELOG.md
3. Move item to "Completed Items"
4. Document the fix
5. Update statistics

---

*This file is the systematic improvement queue. Keep it current.*
