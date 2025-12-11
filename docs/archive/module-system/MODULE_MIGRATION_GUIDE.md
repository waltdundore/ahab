# Ahab Module Migration Guide

## Overview

This guide walks through migrating existing modules from `ahab/roles/` to separate GitHub repositories.

**Current State:**
```
ahab/
└── roles/
    ├── apache/
    └── php/
```

**Target State:**
```
github.com/waltdundore/
├── ahab-module-apache/     # Separate repository
└── ahab-module-php/        # Separate repository

ahab/
├── modules/                # Git submodules or clones
│   ├── apache/
│   └── php/
└── roles/                  # Symlinks to modules
    ├── apache -> ../modules/apache/ansible
    └── php -> ../modules/php/ansible
```

---

## Prerequisites

- Git installed
- GitHub CLI (`gh`) installed (optional but recommended)
- GitHub account with repository creation permissions
- Existing modules in `ahab/roles/`

---

## Migration Steps

### Step 1: Create Module Repositories on GitHub

#### Option A: Using GitHub CLI (Recommended)

```bash
# Create Apache module repository
gh repo create waltdundore/ahab-module-apache \
  --public \
  --description "Apache HTTP Server module for Ahab" \
  --clone

# Create PHP module repository
gh repo create waltdundore/ahab-module-php \
  --public \
  --description "PHP module for Ahab" \
  --clone
```

#### Option B: Using GitHub Web Interface

1. Go to https://github.com/new
2. Repository name: `ahab-module-apache`
3. Description: "Apache HTTP Server module for Ahab"
4. Public repository
5. Do NOT initialize with README, .gitignore, or license
6. Click "Create repository"
7. Repeat for `ahab-module-php`

---

### Step 2: Prepare Module Structure

For each module (apache, php), create the proper structure:

```bash
cd /path/to/workspace

# Create Apache module
./ahab/scripts/create-module.sh apache .

# Create PHP module
./ahab/scripts/create-module.sh php .
```

This creates:
- `ahab-module-apache/` with complete structure
- `ahab-module-php/` with complete structure

---

### Step 3: Copy Existing Module Files

#### Apache Module

```bash
cd ahab-module-apache

# Copy Ansible role files
cp -r ../ahab/roles/apache/tasks/* ansible/tasks/
cp -r ../ahab/roles/apache/handlers/* ansible/handlers/ 2>/dev/null || true
cp -r ../ahab/roles/apache/templates/* ansible/templates/ 2>/dev/null || true
cp -r ../ahab/roles/apache/files/* ansible/files/ 2>/dev/null || true
cp -r ../ahab/roles/apache/vars/* ansible/vars/
cp -r ../ahab/roles/apache/defaults/* ansible/defaults/ 2>/dev/null || true

# Copy module metadata
cp ../ahab/roles/apache/MODULE.yml MODULE.yml

# Copy Dockerfile if exists
cp ../ahab/roles/apache/Dockerfile Dockerfile 2>/dev/null || true

# Copy README if exists
cp ../ahab/roles/apache/README.md README.md 2>/dev/null || true

# Commit
git add .
git commit -m "Add Apache module files from ahab"
```

#### PHP Module

```bash
cd ../ahab-module-php

# Copy Ansible role files
cp -r ../ahab/roles/php/tasks/* ansible/tasks/
cp -r ../ahab/roles/php/handlers/* ansible/handlers/ 2>/dev/null || true
cp -r ../ahab/roles/php/templates/* ansible/templates/ 2>/dev/null || true
cp -r ../ahab/roles/php/files/* ansible/files/ 2>/dev/null || true
cp -r ../ahab/roles/php/vars/* ansible/vars/
cp -r ../ahab/roles/php/defaults/* ansible/defaults/ 2>/dev/null || true

# Copy module metadata
cp ../ahab/roles/php/MODULE.yml MODULE.yml

# Copy Dockerfile if exists
cp ../ahab/roles/php/Dockerfile Dockerfile 2>/dev/null || true

# Copy README if exists
cp ../ahab/roles/php/README.md README.md 2>/dev/null || true

# Commit
git add .
git commit -m "Add PHP module files from ahab"
```

---

### Step 4: Push to GitHub

#### Apache Module

```bash
cd ahab-module-apache

# Add remote (if not already added)
git remote add origin git@github.com:waltdundore/ahab-module-apache.git

# Push main branch
git branch -M main
git push -u origin main

# Create and push dev branch
git checkout -b dev
git push -u origin dev

# Return to main
git checkout main
```

#### PHP Module

```bash
cd ../ahab-module-php

# Add remote (if not already added)
git remote add origin git@github.com:waltdundore/ahab-module-php.git

# Push main branch
git branch -M main
git push -u origin main

# Create and push dev branch
git checkout -b dev
git push -u origin dev

# Return to main
git checkout main
```

---

### Step 5: Create Initial Releases

#### Apache Module

```bash
cd ../ahab

# Create v1.0.0 release for Apache
./scripts/release-module.sh ../ahab-module-apache 1.0.0
```

This will:
- Create `v1.0.0` branch
- Update MODULE.yml version
- Create `v1.0.0` tag
- Merge to main
- Merge back to dev
- Push everything

#### PHP Module

```bash
# Create v1.0.0 release for PHP
./scripts/release-module.sh ../ahab-module-php 1.0.0
```

---

### Step 6: Update ahab

Now update `ahab` to use the new module repositories:

```bash
cd ahab

# Create modules directory
mkdir -p modules

# Install modules using the install script
./scripts/install-module.sh apache v1.0.0
./scripts/install-module.sh php v1.0.0
```

This will:
- Clone modules to `modules/apache` and `modules/php`
- Create symlinks in `roles/` directory
- Resolve dependencies automatically

---

### Step 7: Test Integration

Test that playbooks still work with the new module structure:

```bash
cd ahab

# Test webserver playbook (Apache only)
ansible-playbook -i inventory/dev/hosts.yml playbooks/webserver.yml --check

# Test LAMP playbook (Apache + PHP)
ansible-playbook -i inventory/dev/hosts.yml playbooks/lamp.yml --check

# If checks pass, run for real
ansible-playbook -i inventory/dev/hosts.yml playbooks/webserver.yml
ansible-playbook -i inventory/dev/hosts.yml playbooks/lamp.yml
```

---

### Step 8: Clean Up Old Roles (Optional)

Once you've verified everything works, you can remove the old role directories:

```bash
cd ahab

# Backup first
tar -czf roles-backup-$(date +%Y%m%d).tar.gz roles/

# Remove old role directories (keep symlinks)
rm -rf roles/apache/tasks roles/apache/handlers roles/apache/vars
rm -rf roles/php/tasks roles/php/handlers roles/php/vars

# Or remove entirely and rely on symlinks
# rm -rf roles/apache roles/php
# (symlinks will be recreated by install-module.sh)
```

---

### Step 9: Update Documentation

Update `ahab/README.md` to reflect the new module system:

```bash
cd ahab

# Edit README.md to add module installation instructions
# Update playbook examples
# Add links to module repositories
```

---

### Step 10: Commit Changes to ahab

```bash
cd ahab

# Add new files
git add modules/ scripts/ MODULE_REGISTRY.yml

# Commit
git commit -m "Migrate to modular repository structure

- Add module management scripts
- Add MODULE_REGISTRY.yml
- Install apache and php modules from separate repositories
- Update documentation"

# Push
git push origin dev
```

---

## Verification Checklist

After migration, verify:

- [ ] Apache module repository exists on GitHub
- [ ] PHP module repository exists on GitHub
- [ ] Both modules have `main` and `dev` branches
- [ ] Both modules have `v1.0.0` tag and branch
- [ ] `ahab/modules/apache` exists
- [ ] `ahab/modules/php` exists
- [ ] `ahab/roles/apache` symlink points to `../modules/apache/ansible`
- [ ] `ahab/roles/php` symlink points to `../modules/php/ansible`
- [ ] Webserver playbook works
- [ ] LAMP playbook works
- [ ] Dependencies are resolved (PHP depends on Apache)
- [ ] Docker Compose generation works
- [ ] Documentation is updated

---

## Troubleshooting

### Module Not Found

```bash
# Error: Module 'apache' not found in registry

# Solution: Update MODULE_REGISTRY.yml
cd ahab
# Edit MODULE_REGISTRY.yml to add module entry
```

### Symlink Broken

```bash
# Error: roles/apache not found

# Solution: Recreate symlink
cd ahab
rm roles/apache
ln -s ../modules/apache/ansible roles/apache
```

### Git Push Rejected

```bash
# Error: Updates were rejected

# Solution: Pull first
cd ahab-module-apache
git pull origin main
git push origin main
```

### Version Already Exists

```bash
# Error: Tag v1.0.0 already exists

# Solution: Use next version
./scripts/release-module.sh ../ahab-module-apache 1.0.1
```

---

## Alternative: Git Submodules

Instead of using the install script, you can use git submodules:

```bash
cd ahab

# Add modules as submodules
git submodule add git@github.com:waltdundore/ahab-module-apache.git modules/apache
git submodule add git@github.com:waltdundore/ahab-module-php.git modules/php

# Create symlinks
ln -s ../modules/apache/ansible roles/apache
ln -s ../modules/php/ansible roles/php

# Commit
git add .gitmodules modules/ roles/
git commit -m "Add Apache and PHP modules as submodules"
git push origin dev
```

**Pros:**
- Git tracks exact module versions
- Easy to update all modules: `git submodule update --remote`
- Version pinning built-in

**Cons:**
- More complex git workflow
- Requires submodule knowledge
- Can be confusing for contributors

---

## Next Steps

After successful migration:

1. **Create More Modules**
   ```bash
   ./scripts/create-module.sh mysql
   ./scripts/create-module.sh nginx
   ./scripts/create-module.sh wordpress
   ```

2. **Publish to Ansible Galaxy** (Optional)
   ```bash
   cd ahab-module-apache
   ansible-galaxy role import waltdundore ahab-module-apache
   ```

3. **Set Up CI/CD**
   - GitHub Actions already configured in `.github/workflows/test.yml`
   - Add secrets for automated testing
   - Enable branch protection

4. **Create Documentation Site**
   - Use GitHub Pages
   - Document all modules
   - Add usage examples

5. **Community Contributions**
   - Add CONTRIBUTING.md
   - Set up issue templates
   - Create pull request template

---

## Summary

**What We Did:**
1. ✅ Created separate repositories for each module
2. ✅ Moved existing code to new repositories
3. ✅ Created version branches and tags
4. ✅ Updated ahab to use new structure
5. ✅ Tested integration
6. ✅ Updated documentation

**Benefits:**
- ✅ True modularity
- ✅ Independent versioning
- ✅ Easy to share and reuse
- ✅ Clear dependency management
- ✅ Community contributions possible
- ✅ Scalable architecture

**Result:**
- Modules are now separate, versionable, reusable components
- ahab is cleaner and more maintainable
- Easy to add new modules
- Ready for community contributions

---

**Migration complete! Your modules are now truly modular!** 🚀
