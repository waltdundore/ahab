# Testing Guide

![Ahab Logo](docs/images/ahab-logo.png)

## Quick Test

```bash
make test
```

## Test Status Tracking

Every test run records status in `.test-status`:
- **PASS**: Version becomes promotable
- **FAIL**: Previous passing version remains promotable

## View Test Status

```bash
cat .test-status
```

## Promotion Rules

**CRITICAL**: Only promote versions that pass ALL tests.

1. Run `make test`
2. If PASS → commit is promotable
3. If FAIL → fix issues, previous passing commit remains promotable

## GitHub Actions

Tests run automatically on:
- Push to `main` or `dev`
- Pull requests

Status posted as PR comment with promotable version.

## Manual Testing

```bash
# NASA standards only
make test-nasa

# Integration tests only  
make test-integration

# Property tests only
make test-property

# Parnas principle test only
./tests/property/test-parnas-principle.sh

# Full suite
make test
```

## Test Phases

1. **NASA Power of 10** - Code quality, security, standards
2. **Property Tests** - Verify architectural principles (Parnas, DRY)
3. **Integration** - Docker, Apache, actual deployment

## Property Tests

Property tests verify that architectural principles are maintained:

### Parnas's Information Hiding Principle

**What it tests:** Verifies that alternatives (modules, OS versions) are managed in exactly one place.

**Why it matters:** Ensures maintainability - when you add a new module or OS version, you only update one file.

**Single sources of truth:**
- `MODULE_REGISTRY.yml` - all available modules
- `ahab.conf` - all configuration (OS versions, VM settings)

**How to run:**
```bash
./tests/property/test-parnas-principle.sh
```

**If it fails:** See the comprehensive guide at `docs/development/PARNAS_PRINCIPLE_GUIDE.md` for:
- What Parnas's principle is and why it matters
- Detailed explanation of each test
- How to interpret test results
- Step-by-step instructions to fix violations
- Examples and anti-patterns

**Quick fix checklist:**
1. Don't hardcode module lists - read from MODULE_REGISTRY.yml
2. Don't hardcode OS versions - source ahab.conf
3. Scripts using config variables must source ahab.conf first
4. All referenced modules must exist in MODULE_REGISTRY.yml

## Troubleshooting

**Tests fail?**
1. Check `.test-status` for last passing version
2. Fix issues
3. Run `make test` again
4. Only promote when PASS

**Need to rollback?**
```bash
# Check last passing commit
grep PROMOTABLE_VERSION .test-status

# Checkout that commit
git checkout <commit>
```
