# CI/CD Check Scripts

This directory contains automated check scripts used by GitHub Actions workflows to enforce quality, safety, security, and compliance standards.

## Overview

These scripts are called by reusable GitHub Actions workflows located in `.github/workflows/reusable/`. They implement the CI/CD enforcement design specified in `.kiro/specs/ci-cd-enforcement/`.

## Safety Checks (NASA Power of 10)

### check-bounded-loops.sh
**Purpose**: Validates that all loops have fixed upper bounds  
**Requirements**: 2.1  
**Property**: 4 - Bounded loop detection  
**Usage**: `./check-bounded-loops.sh [path]`

Detects:
- `while true` loops (infinite loops)
- While loops without obvious bounds or counters

### check-return-values.sh
**Purpose**: Validates that function return values are checked  
**Requirements**: 2.2  
**Property**: 5 - Return value checking detection  
**Usage**: `./check-return-values.sh [path]`

Detects:
- Unchecked `make` commands
- Unchecked `git` commands
- Potential unchecked function calls

### check-function-length.sh
**Purpose**: Validates that no function exceeds 60 lines  
**Requirements**: 2.3  
**Property**: 6 - Function length validation  
**Usage**: `./check-function-length.sh [path]`

Detects:
- Functions exceeding 60 lines (NASA Power of 10 Rule #4)
- Provides refactoring suggestions

## Security Checks

### check-credential-templates.sh
**Purpose**: Validates that credential files use .template or .example suffix  
**Requirements**: 3.3  
**Property**: 11 - Credential file naming  
**Usage**: `./check-credential-templates.sh [path]`

Detects:
- Credential files without proper suffix
- Common credential file names (.env, secrets.yml, etc.)

### check-container-users.sh
**Purpose**: Validates that no containers run as root  
**Requirements**: 3.5  
**Property**: 13 - Root container detection  
**Usage**: `./check-container-users.sh [path]`

Detects:
- Dockerfiles without USER directive
- Dockerfiles with USER root
- Docker Compose files with user: root
- Privileged containers

### scan-dependencies.sh
**Purpose**: Scans dependencies for known vulnerabilities  
**Requirements**: 3.4, 18.1, 18.2, 18.3  
**Property**: 40 - Dependency vulnerability detection  
**Usage**: `./scan-dependencies.sh [path]`

Scans:
- Python dependencies (pip-audit)
- Node.js dependencies (npm audit)
- Docker images (trivy)

## DRY Checks

### check-duplicate-code.sh
**Purpose**: Identifies duplicate code blocks across files  
**Requirements**: 4.1  
**Property**: 14 - Duplicate code detection  
**Usage**: `./check-duplicate-code.sh [path]`

Detects:
- Duplicate function definitions
- Repeated error handling patterns
- Repeated color definitions

### check-duplicate-docs.sh
**Purpose**: Identifies duplicate documentation content  
**Requirements**: 4.2  
**Property**: 15 - Duplicate documentation detection  
**Usage**: `./check-duplicate-docs.sh [path]`

Detects:
- Duplicate documentation sections
- Repeated installation instructions
- Repeated troubleshooting sections

### check-duplicate-config.sh
**Purpose**: Identifies duplicate configuration values  
**Requirements**: 4.3  
**Property**: 16 - Duplicate configuration detection  
**Usage**: `./check-duplicate-config.sh [path]`

Detects:
- Duplicate YAML configuration values
- Hardcoded ports, paths, and URLs

### check-shared-libraries.sh
**Purpose**: Verifies proper shared library usage  
**Requirements**: 4.4  
**Property**: 17 - Shared library usage  
**Usage**: `./check-shared-libraries.sh [path]`

Detects:
- Scripts not sourcing common library
- Local definitions of functions available in common library
- Makefiles not using includes

## Gitignore Checks

### check-gitignore-patterns.sh
**Purpose**: Validates .gitignore contains required patterns  
**Requirements**: 6.2, 6.3, 6.5  
**Property**: 20 - Required gitignore patterns  
**Usage**: `./check-gitignore-patterns.sh [category]`

Categories:
- `temp` - Temporary file patterns (*.tmp, *.bak, *~)
- `build` - Build artifact patterns (__pycache__, *.pyc, node_modules)
- `secrets` - Sensitive file patterns (*.key, *.pem, .env)
- `all` - All categories (default)

## Common Library

All scripts source `scripts/lib/common.sh` which provides:
- Color definitions (RED, GREEN, YELLOW, BLUE, NC)
- Output functions (print_success, print_error, print_warning, print_info)
- Error handling (die, require_file, require_command)
- Counter functions (init_counters, increment_error, increment_warning, print_summary)

## Exit Codes

- `0` - All checks passed
- `1` - One or more checks failed

## Integration with GitHub Actions

These scripts are called by reusable workflows:
- `.github/workflows/reusable/safety-checks.yml`
- `.github/workflows/reusable/security-checks.yml`
- `.github/workflows/reusable/dry-checks.yml`
- `.github/workflows/reusable/cleanup-checks.yml`
- `.github/workflows/reusable/gitignore-checks.yml`

## Local Testing

Run checks locally before pushing:

```bash
# Safety checks
./scripts/ci/check-bounded-loops.sh .
./scripts/ci/check-return-values.sh .
./scripts/ci/check-function-length.sh .

# Security checks
./scripts/ci/check-credential-templates.sh .
./scripts/ci/check-container-users.sh .
./scripts/ci/scan-dependencies.sh .

# DRY checks
./scripts/ci/check-duplicate-code.sh .
./scripts/ci/check-duplicate-docs.sh .
./scripts/ci/check-duplicate-config.sh .
./scripts/ci/check-shared-libraries.sh .

# Gitignore checks
./scripts/ci/check-gitignore-patterns.sh all
```

## Error Message Format

All scripts follow a consistent error message format:

```
❌ ERROR: [Brief description]

Rule Violated: [Specific rule or standard]
Location: [File path and line number]

Problem:
[Clear description of what went wrong]

Fix:
[Specific steps to resolve the issue]

Example:
[Code example showing correct implementation]
```

## Development

When adding new checks:

1. Create script in `scripts/ci/`
2. Make executable: `chmod +x scripts/ci/new-check.sh`
3. Source common library: `source "$PROJECT_ROOT/scripts/lib/common.sh"`
4. Use counter functions: `init_counters`, `increment_error`, `print_summary`
5. Follow error message format
6. Add to appropriate reusable workflow
7. Document in this README

## Related Documentation

- Design: `.kiro/specs/ci-cd-enforcement/design.md`
- Requirements: `.kiro/specs/ci-cd-enforcement/requirements.md`
- Tasks: `.kiro/specs/ci-cd-enforcement/tasks.md`
- Common Library: `scripts/lib/common.sh`

---

**Last Updated**: December 9, 2025  
**Status**: Active  
**Maintainer**: Ahab Development Team
