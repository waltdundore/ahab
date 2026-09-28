# Workflow Improvement System

![Ahab Logo](docs/images/ahab-logo.png)

**Date**: December 8, 2025  
**Purpose**: Make our development workflow more efficient and comprehensive  
**Problem**: Large parts of codebase get ignored when they could be improved

---

## The Problem

### What Gets Ignored

1. **Scripts** - 12 shell scripts, many long and complex
2. **Roles** - Ansible roles with tasks, handlers, templates
3. **Tests** - Test scripts that could be more comprehensive
4. **Modules** - Module definitions and metadata
5. **Configuration** - ahab.conf, Makefile, Vagrantfile
6. **Documentation** - Many .md files, some outdated

### Why It Gets Ignored

- **No systematic review process** - We fix what breaks, not what could be better
- **No regular audits** - Only audit when asked
- **No improvement queue** - No tracking of "could be better" items
- **Focus on features** - New features get attention, existing code doesn't
- **Manual discovery** - Rely on humans to notice issues

---

## The Solution: Systematic Improvement Workflow

### Phase 1: Automated Discovery (Weekly)

**Create automated audit system that runs weekly:**

```bash
make audit-all
```

**What it audits:**

1. **Code Quality**
   - NASA Power of 10 compliance
   - Shellcheck warnings
   - Function length
   - Complexity metrics

2. **Documentation Quality**
   - DRY violations
   - Outdated content
   - Missing documentation
   - Broken links

3. **Test Coverage**
   - Untested code paths
   - Missing test cases
   - Flaky tests

4. **Configuration Quality**
   - Hardcoded values
   - Duplicate configuration
   - Unused settings

5. **Security**
   - Hardcoded secrets
   - Command injection risks
   - Privilege escalation

**Output**: Weekly audit report in `docs/audits/WEEKLY_AUDIT_YYYY-MM-DD.md`

---

### Phase 2: Prioritized Improvement Queue

**Create improvement tracking system:**

```markdown
# IMPROVEMENTS.md

## High Priority (Fix This Week)
- [ ] IMP-001: Refactor audit-accountability.sh (629 lines → 300 lines)
- [ ] IMP-002: Add tests for install-module.sh
- [ ] IMP-003: Document apache role variables

## Medium Priority (Fix This Month)
- [ ] IMP-004: Consolidate Quick Start documentation
- [ ] IMP-005: Add error handling to create-module.sh
- [ ] IMP-006: Update ABOUT.md mission statement

## Low Priority (Nice to Have)
- [ ] IMP-007: Add bash completion for make commands
- [ ] IMP-008: Create module dependency graph
- [ ] IMP-009: Add performance benchmarks
```

**Rules:**
- Every audit creates improvement items
- Items are prioritized (High/Medium/Low)
- High priority items must be fixed within 1 week
- Medium priority items must be fixed within 1 month
- Low priority items are optional

---

### Phase 3: Continuous Improvement Cycle

**Weekly Cycle:**

```
Monday:
  1. Run `make audit-all`
  2. Review audit report
  3. Create improvement items in IMPROVEMENTS.md
  4. Prioritize items (High/Medium/Low)

Tuesday-Thursday:
  5. Work on High priority items
  6. Test each fix with `make test`
  7. Document each fix
  8. Update IMPROVEMENTS.md

Friday:
  9. Review week's improvements
  10. Update CHANGELOG.md
  11. Commit and push
```

**Monthly Cycle:**

```
Week 1: Focus on Code Quality
Week 2: Focus on Documentation
Week 3: Focus on Tests
Week 4: Focus on Security
```

---

## Specific Improvements Needed

### Scripts (High Priority)

**Problem**: Many scripts are too long (NASA Rule 4: max 60 lines per function)

**Current State**:
- audit-accountability.sh: 629 lines
- create-module.sh: 752 lines
- setup-nested-test.sh: 382 lines
- audit-self.sh: 375 lines

**Solution**: Break into smaller functions

**Example**:
```bash
# Before: One giant function
validate_everything() {
    # 200 lines of code
}

# After: Many small functions
validate_prerequisites() { }  # 20 lines
validate_configuration() { }  # 20 lines
validate_permissions() { }    # 20 lines
validate_network() { }        # 20 lines
```

**Tracking**:
- [ ] IMP-010: Refactor audit-accountability.sh (629 → 300 lines)
- [ ] IMP-011: Refactor create-module.sh (752 → 400 lines)
- [ ] IMP-012: Refactor setup-nested-test.sh (382 → 200 lines)
- [ ] IMP-013: Refactor audit-self.sh (375 → 200 lines)

---

### Roles (Medium Priority)

**Problem**: Roles lack comprehensive documentation and tests

**Current State**:
- apache role: Works but no variable documentation
- php role: Works but no tests
- mysql role: Incomplete

**Solution**: Standardize role structure

**Template**:
```
roles/apache/
├── README.md           # What it does, how to use it
├── defaults/main.yml   # Default variables (documented)
├── tasks/main.yml      # Tasks (commented)
├── handlers/main.yml   # Handlers
├── templates/          # Templates
├── tests/              # Role-specific tests
└── meta/main.yml       # Dependencies
```

**Tracking**:
- [ ] IMP-014: Document apache role variables
- [ ] IMP-015: Add tests for php role
- [ ] IMP-016: Complete mysql role
- [ ] IMP-017: Create role template/generator

---

### Tests (High Priority)

**Problem**: Test coverage is incomplete

**Current State**:
- Simple integration tests: ✅ Working
- E2E tests: ⚠️ Incomplete
- Unit tests: ❌ Missing
- Role tests: ❌ Missing

**Solution**: Comprehensive test matrix

**Test Matrix**:
```
                 Unit  Integration  E2E  Role
Scripts          [ ]   [✓]         [✓]  N/A
Roles            N/A   [ ]         [✓]  [ ]
Playbooks        N/A   [✓]         [✓]  N/A
Modules          [ ]   [ ]         [✓]  N/A
```

**Tracking**:
- [ ] IMP-018: Add unit tests for scripts
- [ ] IMP-019: Add integration tests for roles
- [ ] IMP-020: Add role-specific tests
- [ ] IMP-021: Complete E2E test suite

---

### Documentation (Medium Priority)

**Problem**: Documentation has DRY violations and gaps

**Current State**:
- Core Principles: ✅ Fixed (Phase 1)
- Quick Start: ⚠️ Duplicated in 8+ files
- Repository Structure: ⚠️ Duplicated in 4+ files
- Role documentation: ❌ Missing

**Solution**: Complete DRY fixes + fill gaps

**Tracking**:
- [ ] IMP-022: Fix Quick Start duplication (20 min)
- [ ] IMP-023: Fix Repository Structure duplication (15 min)
- [ ] IMP-024: Create DOCUMENTATION_MAP.md (30 min)
- [ ] IMP-025: Add DRY guidelines to DEVELOPMENT_RULES.md (15 min)
- [ ] IMP-026: Document all role variables
- [ ] IMP-027: Create troubleshooting guide for each module

---

### Configuration (Low Priority)

**Problem**: Configuration could be more maintainable

**Current State**:
- ahab.conf: ✅ Single source of truth
- Makefile: ⚠️ Could be more modular
- Vagrantfile: ✅ Reads from ahab.conf

**Solution**: Modular Makefile structure

**Tracking**:
- [ ] IMP-028: Split Makefile into includes (Makefile.test, Makefile.deploy)
- [ ] IMP-029: Add Makefile documentation
- [ ] IMP-030: Create Makefile template for new projects

---

## Implementation Plan

### Week 1: Setup Infrastructure

**Day 1-2: Create Audit System**
- [ ] Create `make audit-all` target
- [ ] Create weekly audit script
- [ ] Create audit report template
- [ ] Test audit system

**Day 3-4: Create Tracking System**
- [ ] Create IMPROVEMENTS.md
- [ ] Populate with current issues
- [ ] Prioritize all items
- [ ] Document workflow

**Day 5: First Audit**
- [ ] Run first weekly audit
- [ ] Review results
- [ ] Create improvement items
- [ ] Plan next week

### Week 2-4: High Priority Fixes

**Week 2: Scripts**
- [ ] Refactor audit-accountability.sh
- [ ] Refactor create-module.sh
- [ ] Test all changes
- [ ] Document improvements

**Week 3: Tests**
- [ ] Add unit tests for scripts
- [ ] Add integration tests for roles
- [ ] Complete E2E test suite
- [ ] Document test coverage

**Week 4: Documentation**
- [ ] Fix Quick Start duplication
- [ ] Fix Repository Structure duplication
- [ ] Create DOCUMENTATION_MAP.md
- [ ] Add DRY guidelines

---

## Automation Opportunities

### 1. Automated Code Review

**Create pre-commit hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run quick checks
make test-nasa
make test-unit

# Check for common issues
./scripts/check-dry-violations.sh
./scripts/check-documentation-links.sh
./scripts/check-test-coverage.sh

# If any fail, prevent commit
```

### 2. Automated Documentation Updates

**Create post-commit hook:**
```bash
#!/bin/bash
# .git/hooks/post-commit

# Update CHANGELOG.md automatically
./scripts/update-changelog.sh

# Update documentation if code changed
./scripts/sync-documentation.sh

# Update test coverage report
./scripts/update-coverage.sh
```

### 3. Automated Improvement Discovery

**Create weekly cron job:**
```bash
# Run every Monday at 9am
0 9 * * 1 cd /path/to/ahab && make audit-all
```

---

## Metrics to Track

### Code Quality Metrics

- **Lines of code per function** (target: <60)
- **Shellcheck warnings** (target: 0)
- **NASA compliance violations** (target: 0)
- **Cyclomatic complexity** (target: <10)

### Documentation Metrics

- **DRY violations** (target: 0)
- **Outdated documentation** (target: 0)
- **Missing documentation** (target: 0)
- **Broken links** (target: 0)

### Test Metrics

- **Test coverage** (target: >80%)
- **Passing tests** (target: 100%)
- **Flaky tests** (target: 0)
- **Test execution time** (target: <5 min)

### Improvement Metrics

- **Open improvement items** (track trend)
- **Items fixed per week** (track velocity)
- **Time to fix high priority** (target: <1 week)
- **Time to fix medium priority** (target: <1 month)

---

## Tools to Build

### 1. Comprehensive Audit Tool

**File**: `scripts/audit-comprehensive.sh`

**What it does**:
- Runs all existing audits (NASA, DRY, documentation, security)
- Adds new audits (test coverage, complexity, outdated docs)
- Generates unified report
- Creates improvement items automatically

**Usage**:
```bash
make audit-all
# Output: docs/audits/WEEKLY_AUDIT_2025-12-08.md
```

### 2. Improvement Tracker

**File**: `scripts/track-improvements.sh`

**What it does**:
- Parses IMPROVEMENTS.md
- Tracks status of each item
- Generates progress report
- Sends alerts for overdue items

**Usage**:
```bash
make improvements-status
# Output: Current status of all improvement items
```

### 3. Automated Refactoring Helper

**File**: `scripts/refactor-helper.sh`

**What it does**:
- Identifies long functions
- Suggests split points
- Generates skeleton for new functions
- Updates tests automatically

**Usage**:
```bash
./scripts/refactor-helper.sh scripts/audit-accountability.sh
# Output: Suggested refactoring plan
```

---

## Success Criteria

### Short Term (1 Month)

- [ ] Weekly audit system running
- [ ] IMPROVEMENTS.md tracking all issues
- [ ] All High priority items fixed
- [ ] Test coverage >60%
- [ ] Zero NASA violations in new code

### Medium Term (3 Months)

- [ ] All scripts <400 lines
- [ ] Test coverage >80%
- [ ] All roles documented
- [ ] Zero DRY violations
- [ ] Automated improvement discovery

### Long Term (6 Months)

- [ ] All scripts <200 lines
- [ ] Test coverage >90%
- [ ] Comprehensive role tests
- [ ] Automated refactoring
- [ ] Zero technical debt

---

## Next Steps

### Immediate (This Week)

1. **Create IMPROVEMENTS.md** - Track all improvement items
2. **Populate with current issues** - From all audits
3. **Prioritize items** - High/Medium/Low
4. **Pick first item** - Start with highest priority
5. **Fix, test, document** - Follow workflow

### This Month

1. **Build audit-comprehensive.sh** - Unified audit system
2. **Fix all High priority items** - Clear the backlog
3. **Add unit tests** - Improve test coverage
4. **Refactor longest scripts** - Start with audit-accountability.sh

### This Quarter

1. **Automate everything** - Pre-commit hooks, weekly audits
2. **Achieve 80% test coverage** - Comprehensive testing
3. **Zero technical debt** - All improvements complete
4. **Document the process** - So others can replicate

---

## Conclusion

**The Problem**: Large parts of codebase ignored, improvements ad-hoc

**The Solution**: Systematic workflow with automated discovery, prioritized tracking, and continuous improvement

**The Result**: Higher quality code, better documentation, comprehensive tests, zero technical debt

**The Key**: Make improvement systematic, not reactive

---

*Created: December 8, 2025*  
*Status: Proposal - Ready for Implementation*
