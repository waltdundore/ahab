# Module Migration Testing Checklist

**Purpose:** Verify the module migration from `ahab/roles/` to separate repositories is successful.

**Date:** _______________  
**Tester:** _______________  
**Version:** 1.0.0

---

## Prerequisites

### Tools Installed
- [ ] Git 2.x+
- [ ] GitHub CLI (`gh`) or GitHub account access
- [ ] Ansible 2.9+
- [ ] Python 3.8+
- [ ] PyYAML (`pip install pyyaml`)
- [ ] Vagrant 2.x+ (optional, for VM testing)
- [ ] Docker 20.10+ (optional, for container testing)

### Access
- [ ] GitHub account: waltdundore
- [ ] SSH keys configured for GitHub
- [ ] Can create repositories on GitHub
- [ ] Can push to repositories

---

## Phase 1: Pre-Migration Verification

### Current State Check
- [ ] `ahab/roles/apache/` exists with files
- [ ] `ahab/roles/php/` exists with files
- [ ] Apache MODULE.yml is complete and valid
- [ ] PHP MODULE.yml is complete and valid
- [ ] Apache Dockerfile exists
- [ ] PHP Dockerfile exists
- [ ] Apache tasks/main.yml exists
- [ ] PHP tasks/main.yml exists

### Scripts Ready
- [ ] `create-module.sh` exists and is executable
- [ ] `install-module.sh` exists and is executable
- [ ] `release-module.sh` exists and is executable
- [ ] `generate-docker-compose.py` exists and is executable
- [ ] All scripts have proper permissions (755)

### Documentation Ready
- [ ] MODULE_MIGRATION_GUIDE.md exists
- [ ] MODULE_REPOSITORY_STRUCTURE.md exists
- [ ] MODULE_VERSIONING_GUIDE.md exists
- [ ] FINAL_SUMMARY.md exists
- [ ] PROJECT_STATUS.md exists

---

## Phase 2: Create Module Repositories

### Apache Repository
- [ ] Created repository: `ahab-module-apache`
- [ ] Repository is public
- [ ] Description: "Apache HTTP Server module for Ahab"
- [ ] No README, .gitignore, or license initialized
- [ ] Repository URL: `git@github.com:waltdundore/ahab-module-apache.git`

### PHP Repository
- [ ] Created repository: `ahab-module-php`
- [ ] Repository is public
- [ ] Description: "PHP module for Ahab"
- [ ] No README, .gitignore, or license initialized
- [ ] Repository URL: `git@github.com:waltdundore/ahab-module-php.git`

**Commands Used:**
```bash
gh repo create waltdundore/ahab-module-apache --public --description "Apache HTTP Server module for Ahab"
gh repo create waltdundore/ahab-module-php --public --description "PHP module for Ahab"
```

---

## Phase 3: Generate Module Structure

### Apache Module
- [ ] Ran: `./ahab/scripts/create-module.sh apache .`
- [ ] Directory created: `ahab-module-apache/`
- [ ] Structure verified:
  - [ ] `MODULE.yml` exists
  - [ ] `Dockerfile` exists
  - [ ] `README.md` exists
  - [ ] `LICENSE` exists
  - [ ] `CHANGELOG.md` exists
  - [ ] `.gitignore` exists
  - [ ] `ansible/` directory exists
  - [ ] `ansible/tasks/` exists
  - [ ] `ansible/handlers/` exists
  - [ ] `ansible/vars/` exists
  - [ ] `ansible/defaults/` exists
  - [ ] `ansible/meta/` exists
  - [ ] `docker/` directory exists
  - [ ] `tests/` directory exists
  - [ ] `.github/workflows/` exists
- [ ] Git repository initialized
- [ ] Initial commit created

### PHP Module
- [ ] Ran: `./ahab/scripts/create-module.sh php .`
- [ ] Directory created: `ahab-module-php/`
- [ ] Structure verified (same as Apache)
- [ ] Git repository initialized
- [ ] Initial commit created

---

## Phase 4: Copy Existing Files

### Apache Module Files
- [ ] Copied `tasks/main.yml` to `ahab-module-apache/ansible/tasks/`
- [ ] Copied `handlers/main.yml` (if exists)
- [ ] Copied `vars/RedHat.yml` to `ahab-module-apache/ansible/vars/`
- [ ] Copied `vars/Debian.yml` to `ahab-module-apache/ansible/vars/`
- [ ] Copied `defaults/main.yml` (if exists)
- [ ] Copied `templates/` directory (if exists)
- [ ] Copied `files/` directory (if exists)
- [ ] Replaced `MODULE.yml` with actual version
- [ ] Replaced `Dockerfile` with actual version
- [ ] Replaced `README.md` with actual version
- [ ] Committed changes: "Add Apache module files from ahab"

### PHP Module Files
- [ ] Copied `tasks/main.yml` to `ahab-module-php/ansible/tasks/`
- [ ] Copied `handlers/main.yml` (if exists)
- [ ] Copied `vars/RedHat.yml` to `ahab-module-php/ansible/vars/`
- [ ] Copied `vars/Debian.yml` to `ahab-module-php/ansible/vars/`
- [ ] Copied `defaults/main.yml` (if exists)
- [ ] Copied `templates/` directory (if exists)
- [ ] Copied `files/` directory (if exists)
- [ ] Replaced `MODULE.yml` with actual version
- [ ] Replaced `Dockerfile` with actual version
- [ ] Replaced `README.md` with actual version
- [ ] Committed changes: "Add PHP module files from ahab"

**Commands Used:**
```bash
cd ahab-module-apache
cp -r ../ahab/roles/apache/tasks/* ansible/tasks/
cp -r ../ahab/roles/apache/vars/* ansible/vars/
cp ../ahab/roles/apache/MODULE.yml MODULE.yml
cp ../ahab/roles/apache/Dockerfile Dockerfile
cp ../ahab/roles/apache/README.md README.md
git add .
git commit -m "Add Apache module files from ahab"

cd ../ahab-module-php
# Similar commands for PHP
```

---

## Phase 5: Push to GitHub

### Apache Module
- [ ] Added remote: `git remote add origin git@github.com:waltdundore/ahab-module-apache.git`
- [ ] Renamed branch to main: `git branch -M main`
- [ ] Pushed main: `git push -u origin main`
- [ ] Created dev branch: `git checkout -b dev`
- [ ] Pushed dev: `git push -u origin dev`
- [ ] Returned to main: `git checkout main`
- [ ] Verified on GitHub: branches exist

### PHP Module
- [ ] Added remote: `git remote add origin git@github.com:waltdundore/ahab-module-php.git`
- [ ] Renamed branch to main: `git branch -M main`
- [ ] Pushed main: `git push -u origin main`
- [ ] Created dev branch: `git checkout -b dev`
- [ ] Pushed dev: `git push -u origin dev`
- [ ] Returned to main: `git checkout main`
- [ ] Verified on GitHub: branches exist

---

## Phase 6: Create Releases

### Apache Release
- [ ] Ran: `cd ahab && ./scripts/release-module.sh ../ahab-module-apache 1.0.0`
- [ ] Script completed without errors
- [ ] Branch `v1.0.0` created
- [ ] Tag `v1.0.0` created
- [ ] MODULE.yml version updated to "1.0.0"
- [ ] Changes merged to main
- [ ] Changes merged back to dev
- [ ] All pushed to GitHub
- [ ] Verified on GitHub:
  - [ ] Branch `v1.0.0` exists
  - [ ] Tag `v1.0.0` exists
  - [ ] main is at v1.0.0
  - [ ] dev includes v1.0.0

### PHP Release
- [ ] Ran: `./scripts/release-module.sh ../ahab-module-php 1.0.0`
- [ ] Script completed without errors
- [ ] Branch `v1.0.0` created
- [ ] Tag `v1.0.0` created
- [ ] MODULE.yml version updated to "1.0.0"
- [ ] Changes merged to main
- [ ] Changes merged back to dev
- [ ] All pushed to GitHub
- [ ] Verified on GitHub (same checks as Apache)

### GitHub Releases (Optional)
- [ ] Created GitHub release for Apache v1.0.0
- [ ] Created GitHub release for PHP v1.0.0
- [ ] Releases have descriptions
- [ ] Releases are published

**Commands Used:**
```bash
gh release create v1.0.0 --repo waltdundore/ahab-module-apache --title "v1.0.0" --notes "Initial release"
gh release create v1.0.0 --repo waltdundore/ahab-module-php --title "v1.0.0" --notes "Initial release"
```

---

## Phase 7: Install Modules

### Apache Installation
- [ ] Ran: `cd ahab && ./scripts/install-module.sh apache v1.0.0`
- [ ] Script completed without errors
- [ ] Directory created: `ahab/modules/apache/`
- [ ] Repository cloned to modules/apache/
- [ ] Checked out v1.0.0
- [ ] Symlink created: `ahab/roles/apache -> ../modules/apache/ansible`
- [ ] Symlink is valid: `ls -la ahab/roles/apache`
- [ ] Can access files through symlink

### PHP Installation
- [ ] Ran: `./scripts/install-module.sh php v1.0.0`
- [ ] Script completed without errors
- [ ] Directory created: `ahab/modules/php/`
- [ ] Repository cloned to modules/php/
- [ ] Checked out v1.0.0
- [ ] Symlink created: `ahab/roles/php -> ../modules/php/ansible`
- [ ] Symlink is valid: `ls -la ahab/roles/php`
- [ ] Can access files through symlink
- [ ] Dependencies checked (Apache)
- [ ] Apache already installed (no re-install)

### Module List
- [ ] Ran: `./scripts/install-module.sh --list`
- [ ] Shows Apache module
- [ ] Shows PHP module
- [ ] Shows correct versions
- [ ] Shows descriptions

---

## Phase 8: Test Ansible Playbooks

### Webserver Playbook (Apache Only)
- [ ] Ran: `ansible-playbook -i inventory/dev/hosts.yml playbooks/webserver.yml --check`
- [ ] Check mode passed
- [ ] No errors
- [ ] Ran: `ansible-playbook -i inventory/dev/hosts.yml playbooks/webserver.yml`
- [ ] Playbook executed successfully
- [ ] Apache installed on target
- [ ] Apache service running
- [ ] Port 80 accessible
- [ ] Can curl default page

### LAMP Playbook (Apache + PHP)
- [ ] Ran: `ansible-playbook -i inventory/dev/hosts.yml playbooks/lamp.yml --check`
- [ ] Check mode passed
- [ ] No errors
- [ ] Ran: `ansible-playbook -i inventory/dev/hosts.yml playbooks/lamp.yml`
- [ ] Playbook executed successfully
- [ ] Apache installed
- [ ] PHP installed
- [ ] PHP module loaded in Apache
- [ ] Can execute PHP scripts
- [ ] Dependencies resolved correctly

---

## Phase 9: Test Docker

### Build Images
- [ ] Built Apache: `cd ahab-module-apache && docker build -t ahab/apache:1.0.0 .`
- [ ] Build succeeded
- [ ] Image tagged correctly
- [ ] Built PHP: `cd ahab-module-php && docker build -t ahab/php:1.0.0 .`
- [ ] Build succeeded
- [ ] Image tagged correctly
- [ ] Verified: `docker images | grep ahab`

### Run Containers
- [ ] Started Apache: `docker run -d -p 8080:80 --name test-apache ahab/apache:1.0.0`
- [ ] Container running: `docker ps | grep test-apache`
- [ ] Accessible: `curl http://localhost:8080`
- [ ] Stopped: `docker stop test-apache && docker rm test-apache`
- [ ] Started PHP: `docker run -d -p 9000:9000 --name test-php ahab/php:1.0.0`
- [ ] Container running: `docker ps | grep test-php`
- [ ] Stopped: `docker stop test-php && docker rm test-php`

### Docker Compose Generation
- [ ] Ran: `cd ahab && ./scripts/generate-docker-compose.py`
- [ ] Script completed without errors
- [ ] File created: `docker-compose.yml`
- [ ] File contains Apache service
- [ ] File contains PHP service
- [ ] PHP depends_on Apache
- [ ] Networks configured
- [ ] Volumes configured
- [ ] Ports configured
- [ ] Environment variables set

### Docker Compose Execution
- [ ] Ran: `docker-compose up -d`
- [ ] All services started
- [ ] Verified: `docker-compose ps`
- [ ] Apache accessible: `curl http://localhost`
- [ ] PHP accessible through Apache
- [ ] Services can communicate
- [ ] Stopped: `docker-compose down`
- [ ] All containers removed

---

## Phase 10: Update Documentation

### ahab README
- [ ] Updated with module installation instructions
- [ ] Added links to module repositories
- [ ] Updated playbook examples
- [ ] Added module management section
- [ ] Committed changes

### Module Registry
- [ ] `MODULE_REGISTRY.yml` is accurate
- [ ] Apache entry correct
- [ ] PHP entry correct
- [ ] Versions match releases
- [ ] Repository URLs correct

---

## Phase 11: Cleanup

### Backup Old Files
- [ ] Created backup: `tar -czf roles-backup-$(date +%Y%m%d).tar.gz ahab/roles/`
- [ ] Backup saved safely

### Remove Old Role Directories (Optional)
- [ ] Decided whether to remove old directories
- [ ] If removing: backed up first
- [ ] If removing: removed old files
- [ ] If keeping: documented reason

### Git Commit
- [ ] Staged changes: `git add modules/ scripts/ MODULE_REGISTRY.yml`
- [ ] Committed: `git commit -m "Migrate to modular repository structure"`
- [ ] Pushed: `git push origin dev`

---

## Phase 12: Final Verification

### Repository Structure
- [ ] `ahab-module-apache` repository complete
- [ ] `ahab-module-php` repository complete
- [ ] Both have proper structure
- [ ] Both have documentation
- [ ] Both have tests
- [ ] Both have CI/CD workflows

### ahab Structure
- [ ] `modules/` directory exists
- [ ] `modules/apache/` is a git repository
- [ ] `modules/php/` is a git repository
- [ ] `roles/apache` is a symlink
- [ ] `roles/php` is a symlink
- [ ] Symlinks are valid

### Functionality
- [ ] Can install modules
- [ ] Can list modules
- [ ] Can run playbooks
- [ ] Can generate Docker Compose
- [ ] Can build Docker images
- [ ] Can run Docker containers
- [ ] Dependencies resolve correctly

### Documentation
- [ ] All documentation accurate
- [ ] All links work
- [ ] Examples are correct
- [ ] Instructions are clear

---

## Issues Found

| Issue | Severity | Status | Resolution |
|-------|----------|--------|------------|
|       |          |        |            |

---

## Performance Metrics

| Task | Expected Time | Actual Time | Notes |
|------|---------------|-------------|-------|
| Create repositories | 2 min | | |
| Generate structure | 1 min | | |
| Copy files | 2 min | | |
| Push to GitHub | 2 min | | |
| Create releases | 2 min | | |
| Install modules | 1 min | | |
| Test playbooks | 5 min | | |
| Test Docker | 5 min | | |
| **Total** | **20 min** | | |

---

## Sign-Off

### Pre-Migration
- [ ] All prerequisites met
- [ ] Current state verified
- [ ] Scripts ready
- [ ] Documentation ready

### Migration Complete
- [ ] All repositories created
- [ ] All files migrated
- [ ] All releases tagged
- [ ] All modules installed

### Testing Complete
- [ ] Ansible playbooks work
- [ ] Docker images work
- [ ] Docker Compose works
- [ ] Documentation accurate

### Ready for Production
- [ ] All critical tests passed
- [ ] All documentation reviewed
- [ ] All platforms verified
- [ ] No blocking issues

**Tested by:** _______________  
**Date:** _______________  
**Approved by:** _______________  
**Date:** _______________  

---

## Next Steps

After successful migration:

1. [ ] Create additional modules (MySQL, Nginx, etc.)
2. [ ] Publish to Ansible Galaxy
3. [ ] Set up CI/CD pipelines
4. [ ] Create documentation site
5. [ ] Enable community contributions

---

**Migration Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete
