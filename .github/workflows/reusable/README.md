# Reusable GitHub Actions Workflows

This directory contains reusable workflow components that enforce quality, safety, security, and compliance standards across all Ahab repositories.

## Overview

These workflows implement the CI/CD enforcement design specified in `.kiro/specs/ci-cd-enforcement/`. They are designed to be called by repository-specific workflows to provide consistent validation across the project.

## Available Workflows

### safety-checks.yml
**Purpose**: Validates NASA Power of 10 compliance  
**Requirements**: 2.1, 2.2, 2.3, 2.4, 2.5  
**Checks**:
- Bounded loops (no infinite loops)
- Return value checking
- Function length (max 60 lines)
- Shellcheck validation

**Usage**:
```yaml
jobs:
  safety:
    uses: ./.github/workflows/reusable/safety-checks.yml
    with:
      path: .
```

### security-checks.yml
**Purpose**: Validates security best practices  
**Requirements**: 3.1, 3.2, 3.3, 3.4, 3.5, 18.1, 18.2, 18.3  
**Checks**:
- Secret scanning (TruffleHog)
- Credential file naming (.template or .example suffix)
- Root container detection
- Dependency vulnerability scanning

**Usage**:
```yaml
jobs:
  security:
    uses: ./.github/workflows/reusable/security-checks.yml
```

### dry-checks.yml
**Purpose**: Validates DRY (Don't Repeat Yourself) principle  
**Requirements**: 4.1, 4.2, 4.3, 4.4, 4.5  
**Checks**:
- Duplicate code detection
- Duplicate documentation detection
- Duplicate configuration detection
- Shared library usage verification

**Usage**:
```yaml
jobs:
  dry:
    uses: ./.github/workflows/reusable/dry-checks.yml
```

### cleanup-checks.yml
**Purpose**: Validates repository cleanliness  
**Requirements**: 5.1, 5.2, 5.3, 5.4, 5.5  
**Checks**:
- Temporary files (*.tmp, *.bak, *~)
- Build artifacts (__pycache__, *.pyc, node_modules)
- Editor backups (.swp, .swo, .DS_Store)
- Log files (*.log)
- Database files (*.db, *.sqlite)

**Usage**:
```yaml
jobs:
  cleanup:
    uses: ./.github/workflows/reusable/cleanup-checks.yml
```

### gitignore-checks.yml
**Purpose**: Validates .gitignore configuration  
**Requirements**: 6.1, 6.2, 6.3, 6.4, 6.5  
**Checks**:
- .gitignore file exists
- Required patterns present (temp files, build artifacts, sensitive files)
- No tracked files match .gitignore patterns

**Usage**:
```yaml
jobs:
  gitignore:
    uses: ./.github/workflows/reusable/gitignore-checks.yml
```

## Complete Example

Here's how to use all reusable workflows in a repository-specific workflow:

```yaml
name: CI/CD

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]

jobs:
  # Common checks
  safety:
    uses: ./.github/workflows/reusable/safety-checks.yml
    with:
      path: .
  
  security:
    uses: ./.github/workflows/reusable/security-checks.yml
  
  dry:
    uses: ./.github/workflows/reusable/dry-checks.yml
  
  cleanup:
    uses: ./.github/workflows/reusable/cleanup-checks.yml
  
  gitignore:
    uses: ./.github/workflows/reusable/gitignore-checks.yml
  
  # Repository-specific checks
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: make test
```

## Cross-Repository Usage

These workflows can be used by other repositories in the organization:

```yaml
jobs:
  safety:
    uses: waltdundore/ahab/.github/workflows/reusable/safety-checks.yml@main
  
  security:
    uses: waltdundore/ahab/.github/workflows/reusable/security-checks.yml@main
```

## Check Scripts

All workflows call check scripts located in `scripts/ci/`:
- `check-bounded-loops.sh`
- `check-return-values.sh`
- `check-function-length.sh`
- `check-credential-templates.sh`
- `check-container-users.sh`
- `scan-dependencies.sh`
- `check-duplicate-code.sh`
- `check-duplicate-docs.sh`
- `check-duplicate-config.sh`
- `check-shared-libraries.sh`
- `check-gitignore-patterns.sh`

See `scripts/ci/README.md` for detailed documentation of each script.

## Error Handling

All workflows:
- Fail fast on critical errors
- Provide clear, actionable error messages
- Include fix suggestions and examples
- Link to relevant documentation

## Parallel Execution

Workflows are designed to run in parallel for fast feedback:
- Independent checks run simultaneously
- Total execution time typically < 5 minutes
- Caching used for dependencies

## Local Testing

Test workflows locally before pushing:

```bash
# Run individual checks
./scripts/ci/check-bounded-loops.sh .
./scripts/ci/check-credential-templates.sh .
./scripts/ci/check-duplicate-code.sh .

# Run all checks
make test-ci-cd  # (if make target exists)
```

## Maintenance

When updating workflows:
1. Test changes in feature branch
2. Verify all checks still pass
3. Update documentation
4. Roll out to one repository first
5. Monitor for issues
6. Roll out to remaining repositories

## Related Documentation

- Design: `.kiro/specs/ci-cd-enforcement/design.md`
- Requirements: `.kiro/specs/ci-cd-enforcement/requirements.md`
- Tasks: `.kiro/specs/ci-cd-enforcement/tasks.md`
- Check Scripts: `scripts/ci/README.md`

---

**Last Updated**: December 9, 2025  
**Status**: Active  
**Maintainer**: Ahab Development Team
