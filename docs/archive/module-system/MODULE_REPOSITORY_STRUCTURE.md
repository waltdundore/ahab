# Ahab Module Repository Structure

## Overview

For true modularity, each Ahab module should be its own Git repository. This allows:
- ✅ Independent versioning
- ✅ Separate development cycles
- ✅ Easy sharing and reuse
- ✅ Clear dependency management
- ✅ Community contributions

---

## Repository Structure

### Core Repositories (Already Exist)

```
github.com/waltdundore/
├── ahab/      # Main control repository
├── ansible-config/       # Configuration repository
└── ansible-inventory/    # Inventory repository
```

### Module Repositories (New)

```
github.com/waltdundore/
├── ahab-module-apache/   # Apache HTTP Server module
├── ahab-module-php/      # PHP module
├── ahab-module-mysql/    # MySQL module (future)
├── ahab-module-docker/   # Docker module (existing, needs restructure)
└── ahab-module-*/        # Additional modules
```

---

## Module Repository Template

Each module repository should contain:

```
ahab-module-apache/
├── README.md                 # Module documentation
├── MODULE.yml                # Module metadata
├── Dockerfile                # Docker image (if applicable)
├── ansible/                  # Ansible role
│   ├── tasks/
│   │   └── main.yml
│   ├── handlers/
│   │   └── main.yml
│   ├── templates/
│   ├── files/
│   ├── vars/
│   │   ├── RedHat.yml
│   │   └── Debian.yml
│   ├── defaults/
│   │   └── main.yml
│   └── meta/
│       └── main.yml
├── docker/                   # Docker-specific files
│   ├── config/
│   ├── scripts/
│   └── docker-compose.example.yml
├── tests/                    # Test files
│   ├── ansible-test.yml
│   ├── docker-test.yml
│   └── integration-test.sh
├── examples/                 # Usage examples
│   ├── basic.yml
│   └── advanced.yml
├── .github/                  # GitHub Actions
│   └── workflows/
│       └── test.yml
├── LICENSE
└── CHANGELOG.md
```

---

## Creating Module Repositories

### Step 1: Create Repository on GitHub

```bash
# For each module, create a new repository:
# - ahab-module-apache
# - ahab-module-php
# etc.
```

### Step 2: Initialize Module Repository

```bash
# Clone the new repository
git clone git@github.com:waltdundore/ahab-module-apache.git
cd ahab-module-apache

# Create structure
mkdir -p ansible/{tasks,handlers,templates,files,vars,defaults,meta}
mkdir -p docker/{config,scripts}
mkdir -p tests
mkdir -p examples
mkdir -p .github/workflows

# Initialize
git add .
git commit -m "Initial module structure"
git push origin main
```

### Step 3: Move Existing Code

```bash
# Move Apache role files to module repository
cp -r ahab/roles/apache/* ahab-module-apache/ansible/
cp ahab/roles/apache/MODULE.yml ahab-module-apache/
cp ahab/roles/apache/Dockerfile ahab-module-apache/
cp ahab/roles/apache/README.md ahab-module-apache/

# Commit
cd ahab-module-apache
git add .
git commit -m "Add Apache module files"
git push origin main
```

---

## Using Modules in ahab

### Option 1: Git Submodules

```bash
cd ahab

# Add module as submodule
git submodule add git@github.com:waltdundore/ahab-module-apache.git modules/apache
git submodule add git@github.com:waltdundore/ahab-module-php.git modules/php

# Create symlinks to roles directory
ln -s ../modules/apache/ansible roles/apache
ln -s ../modules/php/ansible roles/php

# Commit
git add .gitmodules modules/ roles/
git commit -m "Add Apache and PHP modules as submodules"
git push
```

### Option 2: Ansible Galaxy / requirements.yml

```yaml
# ahab/requirements.yml
---
roles:
  - name: apache
    src: https://github.com/waltdundore/ahab-module-apache.git
    version: v1.0.0
    scm: git
  
  - name: php
    src: https://github.com/waltdundore/ahab-module-php.git
    version: v1.0.0
    scm: git
```

Install modules:
```bash
cd ahab
ansible-galaxy install -r requirements.yml -p roles/
```

### Option 3: Module Manager Script

```bash
# ahab/scripts/install-modules.sh
#!/bin/bash
# Installs Ahab modules from GitHub

MODULES_DIR="modules"
ROLES_DIR="roles"

install_module() {
    local module_name=$1
    local version=${2:-main}
    
    echo "Installing module: $module_name ($version)"
    
    # Clone or update module
    if [ -d "$MODULES_DIR/$module_name" ]; then
        cd "$MODULES_DIR/$module_name"
        git pull origin $version
        cd ../..
    else
        git clone -b $version \
            "https://github.com/waltdundore/ahab-module-$module_name.git" \
            "$MODULES_DIR/$module_name"
    fi
    
    # Create symlink to roles
    ln -sf "../$MODULES_DIR/$module_name/ansible" "$ROLES_DIR/$module_name"
}

# Install modules
install_module apache v1.0.0
install_module php v1.0.0
```

---

## Module Versioning

### Semantic Versioning

```
v1.0.0 - Major.Minor.Patch
```

- **Major**: Breaking changes
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes

### Branch Strategy

**Branches match version numbers:**

```
main              # Latest stable (always points to latest release)
dev               # Development branch
v1.0.0            # Release branch for version 1.0.0
v1.1.0            # Release branch for version 1.1.0
v2.0.0            # Release branch for version 2.0.0
```

**Workflow:**

1. **Development** happens on `dev` branch
2. **Release** creates a version branch (e.g., `v1.0.0`)
3. **Hotfixes** go to version branch, then merge to `dev` and `main`
4. **Main** always points to latest stable release

### Creating a Release

```bash
cd ahab-module-apache

# Ensure you're on dev with latest changes
git checkout dev
git pull origin dev

# Create version branch
git checkout -b v1.0.0

# Update MODULE.yml with version
sed -i 's/version: .*/version: "1.0.0"/' MODULE.yml

# Commit version bump
git add MODULE.yml
git commit -m "Release v1.0.0"

# Push version branch
git push origin v1.0.0

# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Merge to main
git checkout main
git merge v1.0.0
git push origin main

# Merge back to dev
git checkout dev
git merge v1.0.0
git push origin dev

# Create GitHub release
gh release create v1.0.0 --title "v1.0.0" --notes "Initial release"
```

### Installing Specific Versions

```bash
# Install from version branch
git clone -b v1.0.0 https://github.com/waltdundore/ahab-module-apache.git

# Or checkout specific version
cd ahab-module-apache
git checkout v1.0.0

# Or use tag
git checkout tags/v1.0.0
```

---

## Module Registry

### Central Registry File

```yaml
# ahab/MODULE_REGISTRY.yml
---
registry:
  version: "1.0"
  modules:
    apache:
      repository: "https://github.com/waltdundore/ahab-module-apache.git"
      version: "v1.0.0"
      description: "Apache HTTP Server"
      deployment: [ansible, docker]
      dependencies: []
      status: stable
    
    php:
      repository: "https://github.com/waltdundore/ahab-module-php.git"
      version: "v1.0.0"
      description: "PHP scripting language"
      deployment: [ansible, docker]
      dependencies: [apache]
      status: stable
    
    docker:
      repository: "https://github.com/waltdundore/ahab-module-docker.git"
      version: "v1.0.0"
      description: "Docker container runtime"
      deployment: [ansible]
      dependencies: []
      status: stable
```

---

## Module Discovery

### List Available Modules

```bash
# ahab/scripts/list-modules.sh
#!/bin/bash
# Lists available Ahab modules from registry

cat MODULE_REGISTRY.yml | yq '.registry.modules | to_entries | .[] | .key + " - " + .value.description'
```

### Install Module from Registry

```bash
# ahab/scripts/install-module.sh
#!/bin/bash
# Installs a module from the registry

MODULE_NAME=$1

if [ -z "$MODULE_NAME" ]; then
    echo "Usage: $0 <module-name>"
    exit 1
fi

# Get module info from registry
REPO=$(yq ".registry.modules.$MODULE_NAME.repository" MODULE_REGISTRY.yml)
VERSION=$(yq ".registry.modules.$MODULE_NAME.version" MODULE_REGISTRY.yml)

if [ "$REPO" = "null" ]; then
    echo "Error: Module '$MODULE_NAME' not found in registry"
    exit 1
fi

echo "Installing $MODULE_NAME from $REPO ($VERSION)"

# Clone module
git clone -b $VERSION $REPO modules/$MODULE_NAME

# Create symlink
ln -sf ../modules/$MODULE_NAME/ansible roles/$MODULE_NAME

echo "✓ Module $MODULE_NAME installed"
```

---

## Updated ahab Structure

```
ahab/
├── playbooks/              # Playbooks using modules
├── inventory/              # Symlink to ansible-inventory
├── config.yml              # Symlink to ansible-config
├── modules/                # Module repositories (git submodules or clones)
│   ├── apache/            # ahab-module-apache repository
│   ├── php/               # ahab-module-php repository
│   └── docker/            # ahab-module-docker repository
├── roles/                  # Symlinks to module ansible directories
│   ├── apache -> ../modules/apache/ansible
│   ├── php -> ../modules/php/ansible
│   └── docker -> ../modules/docker/ansible
├── scripts/
│   ├── install-module.sh
│   ├── list-modules.sh
│   └── generate-docker-compose.py
├── MODULE_REGISTRY.yml     # Central module registry
├── requirements.yml        # Ansible Galaxy requirements
└── README.md
```

---

## Benefits of Separate Repositories

### For Module Developers

✅ **Independent Development** - Work on modules without affecting core
✅ **Version Control** - Tag and release modules independently
✅ **Testing** - CI/CD per module
✅ **Documentation** - Module-specific docs
✅ **Collaboration** - Easy to contribute to specific modules

### For Module Users

✅ **Selective Installation** - Install only needed modules
✅ **Version Pinning** - Use specific module versions
✅ **Easy Updates** - Update modules independently
✅ **Clear Dependencies** - See what each module needs
✅ **Community Modules** - Use modules from any source

### For the Project

✅ **Scalability** - Add modules without bloating core
✅ **Maintainability** - Easier to maintain separate codebases
✅ **Flexibility** - Mix official and community modules
✅ **Distribution** - Share modules via Ansible Galaxy
✅ **Quality** - Each module can have its own quality standards

---

## Migration Plan

### Phase 1: Create Module Repositories

1. Create `ahab-module-apache` repository
2. Create `ahab-module-php` repository
3. Move existing code to new repositories
4. Tag initial releases (v1.0.0)

### Phase 2: Update ahab

1. Add `modules/` directory
2. Add `MODULE_REGISTRY.yml`
3. Create module management scripts
4. Update documentation
5. Add `requirements.yml`

### Phase 3: Test Integration

1. Test submodule approach
2. Test Ansible Galaxy approach
3. Test module manager script
4. Verify playbooks still work
5. Test Docker Compose generation

### Phase 4: Documentation

1. Update main README
2. Create module development guide
3. Document module installation
4. Create contribution guidelines
5. Add examples

---

## Next Steps

1. **Create GitHub Repositories**
   ```bash
   # Create these repositories on GitHub:
   - ahab-module-apache
   - ahab-module-php
   - ahab-module-docker (restructure existing)
   ```

2. **Move Code to Module Repos**
   ```bash
   # Move existing role code to new repositories
   # Tag initial releases
   ```

3. **Update ahab**
   ```bash
   # Add module management
   # Update documentation
   # Test integration
   ```

4. **Publish Modules**
   ```bash
   # Optionally publish to Ansible Galaxy
   # Create releases on GitHub
   # Update registry
   ```

---

## Example: Installing Apache Module

### Using Submodules

```bash
cd ahab
git submodule add git@github.com:waltdundore/ahab-module-apache.git modules/apache
ln -s ../modules/apache/ansible roles/apache
```

### Using Module Manager

```bash
cd ahab
./scripts/install-module.sh apache
```

### Using Ansible Galaxy

```bash
cd ahab
ansible-galaxy install -r requirements.yml
```

---

**This structure provides true modularity with independent, reusable, versionable modules!**
