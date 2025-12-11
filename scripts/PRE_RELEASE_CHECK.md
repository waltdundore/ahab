# Pre-Release Checklist System

**Date**: 2025-12-09  
**Status**: Active  
**Audience**: Developers

---

## Purpose

The pre-release checklist system validates all code, documentation, and configuration against project principles and standards before any release. It ensures releases meet quality, security, architectural, and documentation standards.

---

## Quick Start

### Run Pre-Release Check

```bash
cd ahab
./scripts/pre-release-check.sh
```

### Run in Strict Mode

```bash
./scripts/pre-release-check.sh --strict
```

### Run with Auto-Fix

```bash
./scripts/pre-release-check.sh --fix
```

### Run in Docker (for bash 4+ compatibility)

```bash
./scripts/pre-release-check-docker.sh
```

---

## Project Structure

```
ahab/
├── scripts/
│   ├── pre-release-check.sh           # Main orchestrator
│   ├── pre-release-check-docker.sh    # Docker wrapper
│   └── validators/
│       ├── lib/
│       │   └── common.sh              # Shared utilities
│       ├── Dockerfile                 # Docker image for validators
│       ├── README.md                  # Validator documentation
│       ├── validate-code-compliance.sh
│       ├── validate-documentation.sh
│       ├── validate-file-organization.sh
│       ├── validate-gitignore.sh
│       ├── validate-tests.sh
│       ├── validate-branding.sh
│       ├── validate-architecture.sh
│       ├── validate-code-quality.sh
│       ├── validate-dependencies.sh
│       ├── validate-changelog.sh
│       ├── validate-consolidation.sh
│       └── validate-security.sh
├── tests/
│   └── validators/
│       ├── unit/                      # Unit tests
│       ├── property/                  # Property-based tests
│       ├── integration/               # Integration tests
│       └── README.md                  # Test documentation
└── .pre-release-check.conf.template   # Configuration template
```

---

## Configuration

### Create Configuration File

```bash
cd ahab
cp .pre-release-check.conf.template .pre-release-check.conf
# Edit .pre-release-check.conf as needed
```

### Configuration Options

See `.pre-release-check.conf.template` for all available options:

- **STRICT_MODE**: Treat warnings as errors
- **AUTO_FIX**: Attempt automatic fixes
- **PARALLEL**: Run validators in parallel
- **REPORT_FORMAT**: text, json, or html
- **REPORT_FILE**: Output file path
- Validator-specific settings

---

## Validators

The system includes 12 validators:

1. **code-compliance**: Verify code follows Core Principles
2. **documentation**: Verify documentation accuracy and completeness
3. **file-organization**: Verify proper file organization and cleanup
4. **gitignore**: Verify .gitignore configuration
5. **tests**: Verify all tests pass
6. **branding**: Verify GUI follows brand guidelines
7. **architecture**: Verify architectural compliance
8. **code-quality**: Verify code quality standards
9. **dependencies**: Verify dependency management
10. **changelog**: Verify changelog and versioning
11. **consolidation**: Identify duplicate content (DRY violations)
12. **security**: Verify security compliance

### Validator Status

- ✓ **PASS**: Validation passed
- ✗ **FAIL**: Validation failed
- ○ **SKIP**: Validator not implemented yet

---

## Usage Examples

### Basic Usage

```bash
# Run all checks
./scripts/pre-release-check.sh

# Check specific format
./scripts/pre-release-check.sh --format json --output report.json

# Strict mode (warnings = errors)
./scripts/pre-release-check.sh --strict

# Auto-fix mode
./scripts/pre-release-check.sh --fix

# Combine options
./scripts/pre-release-check.sh --strict --fix
```

### Via Make Commands

```bash
# Run pre-release check
make pre-release-check

# Run in strict mode
make pre-release-check-strict

# Run with auto-fix
make pre-release-check-fix

# Test validators
make test-validators
make test-validators-unit
make test-validators-property
make test-validators-integration
```

---

## Development

### Adding a New Validator

1. Create validator script:
   ```bash
   cd ahab/scripts/validators
   cp validate-test-dummy.sh validate-my-validator.sh
   chmod +x validate-my-validator.sh
   ```

2. Implement validator logic following the interface pattern

3. Add tests:
   ```bash
   cd ahab/tests/validators/unit
   # Create test-validate-my-validator.sh
   ```

4. Update orchestrator if needed (validators are auto-discovered)

5. Document in design document

### Validator Interface

Each validator must:
- Exit with 0 on success, 1 on failure
- Use common utility functions from `lib/common.sh`
- Follow the standard structure (see `validators/README.md`)

### Testing

```bash
# Test individual validator
./scripts/validators/validate-code-compliance.sh

# Test all validators
make test-validators

# Test specific type
make test-validators-unit
make test-validators-property
make test-validators-integration
```

---

## Reports

### Text Report (Default)

```
==========================================
Pre-Release Checklist Report
==========================================

Date: 2025-12-09 14:21:04
Mode: Normal

==========================================
Validator Results
==========================================

code-compliance                ✓ PASS
documentation                  ✓ PASS
...

==========================================
Summary
==========================================

Total Errors:   0
Total Warnings: 0

Status: ✓ PASSED

All validations passed. Safe to release.
==========================================
```

### JSON Report

```bash
./scripts/pre-release-check.sh --format json --output report.json
```

### HTML Report

```bash
./scripts/pre-release-check.sh --format html --output report.html
```

---

## Exit Codes

- **0**: All checks passed
- **1**: One or more checks failed
- **2**: Invalid arguments

---

## Troubleshooting

### Validator Not Found

**Problem**: `WARNING: Validator not found: <name> (skipping)`

**Solution**: The validator hasn't been implemented yet. This is expected during development.

### Bash Version Issues

**Problem**: `declare: -A: invalid option`

**Solution**: Use the Docker wrapper:
```bash
./scripts/pre-release-check-docker.sh
```

### Permission Denied

**Problem**: `Permission denied` when running validators

**Solution**: Make scripts executable:
```bash
chmod +x scripts/pre-release-check.sh
chmod +x scripts/validators/*.sh
```

### Tests Fail

**Problem**: Validator tests fail

**Solution**: 
1. Check test output for specific failures
2. Run individual validator to debug
3. Check validator logic and test expectations

---

## Integration with CI/CD

### Git Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

cd ahab
if ! ./scripts/pre-release-check.sh --strict; then
    echo "Pre-release check failed. Fix issues before committing."
    exit 1
fi
```

### GitHub Actions

```yaml
name: Pre-Release Check

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run pre-release check
        run: |
          cd ahab
          ./scripts/pre-release-check-docker.sh --strict
```

---

## Related Documents

- **Design**: `.kiro/specs/pre-release-checklist/design.md`
- **Requirements**: `.kiro/specs/pre-release-checklist/requirements.md`
- **Tasks**: `.kiro/specs/pre-release-checklist/tasks.md`
- **Validators**: `scripts/validators/README.md`
- **Tests**: `tests/validators/README.md`
- **Development Rules**: `DEVELOPMENT_RULES.md`

---

## Support

For issues or questions:
1. Check this documentation
2. Check validator-specific README files
3. Review design and requirements documents
4. Check test output for specific failures

---

**Last Updated**: 2025-12-09
