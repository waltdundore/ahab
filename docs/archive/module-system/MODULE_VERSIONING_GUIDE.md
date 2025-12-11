# Ahab Module Versioning Guide

## Overview

Ahab modules use **version-based branching** where each release gets its own branch matching the version number. This provides clear version history and easy rollback capabilities.

---

## Branch Strategy

### Branch Types

```
main              # Always points to latest stable release
dev               # Development branch (default for new work)
v1.0.0            # Release branch for version 1.0.0
v1.1.0            # Release branch for version 1.1.0
v1.1.1            # Release branch for version 1.1.1 (hotfix)
v2.0.0            # Release branch for version 2.0.0 (major)
```

### Branch Purposes

| Branch | Purpose | Protected | Lifetime |
|--------|---------|-----------|----------|
| `main` | Latest stable | Yes | Permanent |
| `dev` | Development | Yes | Permanent |
| `v*.*.*` | Specific release | Yes | Permanent |
| `feature/*` | Feature development | No | Temporary |
| `hotfix/*` | Emergency fixes | No | Temporary |

---

## Semantic Versioning

### Version Format

```
v1.2.3
 │ │ │
 │ │ └─ PATCH: Bug fixes, no breaking changes
 │ └─── MINOR: New features, backwards compatible
 └───── MAJOR: Breaking changes
```

### Version Increment Rules

**MAJOR (v1.0.0 → v2.0.0)**
- Breaking API changes
- Incompatible with previous version
- Requires user action to upgrade

**MINOR (v1.0.0 → v1.1.0)**
- New features added
- Backwards compatible
- No breaking changes

**PATCH (v1.0.0 → v1.0.1)**
- Bug fixes only
- No new features
- Backwards compatible

---

## Release Workflow

### Creating a New Release

#### Step 1: Prepare Development Branch

```bash
cd ahab-module-apache

# Ensure dev is up to date
git checkout dev
git pull origin dev

# Verify all changes are committed
git status

# Run tests
make test  # or your test command
```

#### Step 2: Create Release Branch

```bash
# Use the release script
cd ../ahab
./scripts/release-module.sh ../ahab-module-apache 1.0.0

# Or manually:
cd ../ahab-module-apache
git checkout -b v1.0.0

# Update MODULE.yml version
sed -i 's/version: .*/version: "1.0.0"/' MODULE.yml

# Commit
git add MODULE.yml
git commit -m "Release v1.0.0"

# Tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push
git push origin v1.0.0
git push origin v1.0.0  # tag
```

#### Step 3: Merge to Main

```bash
git checkout main
git merge v1.0.0 --no-edit
git push origin main
```

#### Step 4: Merge Back to Dev

```bash
git checkout dev
git merge v1.0.0 --no-edit
git push origin dev
```

#### Step 5: Create GitHub Release

```bash
gh release create v1.0.0 \
  --title "v1.0.0" \
  --notes "Release notes here"
```

---

## Hotfix Workflow

### Creating a Hotfix

When a critical bug is found in production:

```bash
cd ahab-module-apache

# Create hotfix branch from version branch
git checkout v1.0.0
git checkout -b hotfix/critical-bug

# Fix the bug
# ... make changes ...

# Commit
git add .
git commit -m "Fix critical bug"

# Create new patch version
git checkout -b v1.0.1
git merge hotfix/critical-bug --no-edit

# Update MODULE.yml
sed -i 's/version: .*/version: "1.0.1"/' MODULE.yml
git add MODULE.yml
git commit -m "Release v1.0.1"

# Tag
git tag -a v1.0.1 -m "Hotfix release 1.0.1"

# Push
git push origin v1.0.1
git push origin v1.0.1  # tag

# Merge to main
git checkout main
git merge v1.0.1 --no-edit
git push origin main

# Merge to dev
git checkout dev
git merge v1.0.1 --no-edit
git push origin dev

# Clean up
git branch -d hotfix/critical-bug
```

---

## Installing Specific Versions

### Install Latest Stable

```bash
# Installs from main branch (latest stable)
./scripts/install-module.sh apache
```

### Install Specific Version

```bash
# Install version 1.0.0
./scripts/install-module.sh apache v1.0.0

# Install version 1.1.0
./scripts/install-module.sh apache v1.1.0
```

### Install from Development

```bash
# Install from dev branch (bleeding edge)
./scripts/install-module.sh apache dev
```

### Manual Installation

```bash
# Clone specific version
git clone -b v1.0.0 https://github.com/waltdundore/ahab-module-apache.git

# Or checkout version in existing clone
cd ahab-module-apache
git fetch origin
git checkout v1.0.0
```

---

## Version Compatibility

### Checking Compatibility

Each module's `MODULE.yml` specifies compatible versions of dependencies:

```yaml
dependencies:
  modules:
    - name: apache
      version: ">=1.0.0,<2.0.0"  # Compatible with 1.x
      reason: "Requires Apache web server"
```

### Version Constraints

| Constraint | Meaning | Example |
|------------|---------|---------|
| `1.0.0` | Exact version | Only 1.0.0 |
| `>=1.0.0` | Greater or equal | 1.0.0, 1.1.0, 2.0.0 |
| `>=1.0.0,<2.0.0` | Range | 1.0.0, 1.1.0, 1.9.9 |
| `~1.0.0` | Patch updates | 1.0.0, 1.0.1, 1.0.2 |
| `^1.0.0` | Minor updates | 1.0.0, 1.1.0, 1.9.9 |
| `*` | Any version | Not recommended |

---

## Module Registry

### Registry Format

```yaml
# MODULE_REGISTRY.yml
registry:
  modules:
    apache:
      repository: "https://github.com/waltdundore/ahab-module-apache.git"
      version: "v1.0.0"  # Current stable version
      description: "Apache HTTP Server"
      status: stable
```

### Updating Registry

After releasing a new version:

```bash
cd ahab

# Update MODULE_REGISTRY.yml
# Change version: "v1.0.0" to version: "v1.1.0"

git add MODULE_REGISTRY.yml
git commit -m "Update apache module to v1.1.0"
git push origin dev
```

---

## Best Practices

### Version Numbering

✅ **DO:**
- Start at v1.0.0 for first stable release
- Use v0.x.x for pre-release versions
- Increment MAJOR for breaking changes
- Increment MINOR for new features
- Increment PATCH for bug fixes
- Keep version in MODULE.yml in sync with branch/tag

❌ **DON'T:**
- Skip version numbers
- Reuse version numbers
- Delete version branches
- Force push to version branches
- Use non-semantic versions

### Branch Management

✅ **DO:**
- Protect main and dev branches
- Protect all version branches
- Merge hotfixes to all affected branches
- Keep version branches indefinitely
- Tag every release

❌ **DON'T:**
- Commit directly to main
- Delete version branches
- Rebase version branches
- Force push to protected branches

### Release Process

✅ **DO:**
- Test thoroughly before release
- Update CHANGELOG.md
- Update MODULE.yml version
- Create GitHub release with notes
- Update registry
- Announce release

❌ **DON'T:**
- Release untested code
- Skip version in MODULE.yml
- Forget to tag
- Release without documentation

---

## Examples

### Example 1: First Release

```bash
# Module is ready for first release
cd ahab-module-apache
git checkout dev

# Create v1.0.0
./scripts/release-module.sh . 1.0.0

# Result:
# - Branch v1.0.0 created
# - Tag v1.0.0 created
# - main updated to v1.0.0
# - dev merged with v1.0.0
```

### Example 2: Feature Release

```bash
# New feature added to dev
cd ahab-module-apache
git checkout dev

# Create v1.1.0
./scripts/release-module.sh . 1.1.0

# Result:
# - Branch v1.1.0 created
# - Tag v1.1.0 created
# - main updated to v1.1.0
# - dev merged with v1.1.0
```

### Example 3: Hotfix Release

```bash
# Critical bug in v1.1.0
cd ahab-module-apache

# Create hotfix from v1.1.0
git checkout v1.1.0
git checkout -b hotfix/security-fix

# Fix bug
# ... make changes ...
git commit -am "Fix security vulnerability"

# Create v1.1.1
git checkout -b v1.1.1
git merge hotfix/security-fix
# Update MODULE.yml to 1.1.1
git commit -am "Release v1.1.1"
git tag v1.1.1

# Merge to main and dev
git checkout main && git merge v1.1.1
git checkout dev && git merge v1.1.1
```

### Example 4: Major Version

```bash
# Breaking changes ready
cd ahab-module-apache
git checkout dev

# Create v2.0.0
./scripts/release-module.sh . 2.0.0

# Result:
# - Branch v2.0.0 created
# - Tag v2.0.0 created
# - main updated to v2.0.0
# - dev merged with v2.0.0
# - v1.x.x branches still available for hotfixes
```

---

## Troubleshooting

### Version Already Exists

```bash
# Error: Tag v1.0.0 already exists

# Check existing tags
git tag -l

# Use next version
./scripts/release-module.sh . 1.0.1
```

### Uncommitted Changes

```bash
# Error: You have uncommitted changes

# Commit or stash changes
git status
git add .
git commit -m "Prepare for release"

# Then release
./scripts/release-module.sh . 1.0.0
```

### Merge Conflicts

```bash
# Conflict when merging to main

# Resolve conflicts
git status
# Edit conflicting files
git add .
git commit -m "Resolve merge conflicts"
git push origin main
```

---

## Tools

### Release Script

```bash
# Create release with version branch
./scripts/release-module.sh <module-path> <version>

# Example
./scripts/release-module.sh ../ahab-module-apache 1.0.0
```

### Install Script

```bash
# Install specific version
./scripts/install-module.sh apache v1.0.0

# Install latest
./scripts/install-module.sh apache
```

### List Modules

```bash
# List available modules and versions
./scripts/install-module.sh --list
```

---

## Summary

**Key Points:**
- ✅ Branches match version numbers (v1.0.0, v1.1.0, etc.)
- ✅ Each release gets its own permanent branch
- ✅ main always points to latest stable
- ✅ dev is for development
- ✅ Semantic versioning (MAJOR.MINOR.PATCH)
- ✅ Hotfixes create new patch versions
- ✅ Version branches are never deleted

**Benefits:**
- Clear version history
- Easy rollback to any version
- Multiple versions can coexist
- Hotfixes don't affect development
- Users can pin to specific versions

---

**Ready to version your modules!** 🚀
