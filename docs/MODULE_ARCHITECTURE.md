# Module Architecture

![Ahab Logo](docs/images/ahab-logo.png)

## Overview

Ahab uses a distributed module system where modules live in separate repositories, not in the `ahab` project. This document explains the architecture and prevents confusion about where modules should live.

## Repository Structure

### Three Types of Repositories

1. **ahab** (This Repository)
   - The control plane and orchestration layer
   - Contains playbooks, scripts, and the module registry
   - **DOES NOT contain module code**
   - Pulls modules from external repositories

2. **ahab-modules** (Collection Repository)
   - https://github.com/waltdundore/ahab-modules
   - Collection of all available modules
   - Each module is a separate subdirectory
   - Used for browsing and discovery

3. **ahab-module-common** (Shared Files)
   - https://github.com/waltdundore/ahab-module-common
   - Common files, prerequisites, bridge/linking files
   - Shared across multiple modules

### Individual Module Repositories

Each module has its own repository:
- `ahab-module-apache` - Apache HTTP Server
- `ahab-module-php` - PHP runtime
- `ahab-module-docker` - Docker engine
- `ahab-module-mysql` - MySQL database (planned)
- etc.

## Critical Rule: No Local Modules

**❌ WRONG: Storing modules locally in ahab**

```
ahab/
├── modules/
│   ├── apache/          ← WRONG! Don't do this!
│   │   └── module.yml
│   └── mysql/           ← WRONG! Don't do this!
│       └── module.yml
```

**✅ CORRECT: Modules in separate repositories**

```
ahab/
├── MODULE_REGISTRY.yml  ← Points to external repos
├── playbooks/
├── scripts/
└── roles/               ← Symlinks to cloned modules (if needed)

External repositories:
- github.com/waltdundore/ahab-module-apache
- github.com/waltdundore/ahab-module-php
- github.com/waltdundore/ahab-module-docker
```

## Why This Architecture?

### 1. Separation of Concerns
- Control plane (ahab) separate from modules
- Each module can be versioned independently
- Modules can be reused across different projects

### 2. Version Management
- Each module has its own version branches (v1.0.0, v1.1.0, etc.)
- MODULE_REGISTRY.yml tracks which version to use
- Easy to pin to specific versions or update independently

### 3. Collaboration
- Different teams can maintain different modules
- Module updates don't require ahab changes
- Clear ownership and responsibility

### 4. Distribution
- Users can install only the modules they need
- Modules can be shared across organizations
- Easy to contribute new modules

## Module Registry

The `MODULE_REGISTRY.yml` file is the single source of truth for available modules:

```yaml
registry:
  modules:
    apache:
      repository: "https://github.com/waltdundore/ahab-module-apache.git"
      version: "v1.0.0"
      description: "Apache HTTP Server"
      deployment: [ansible, docker]
      dependencies: []
      status: stable
```

## How Modules Are Used

### 1. User Requests Module

```bash
make install apache
```

### 2. System Checks Registry

- Reads `MODULE_REGISTRY.yml`
- Finds Apache module repository URL
- Checks version to use

### 3. System Fetches Module

- Clones from external repository (if not cached)
- Checks out specified version
- Reads module configuration

### 4. System Deploys Module

- Generates Docker Compose configuration
- Deploys using Ansible playbooks
- Verifies deployment

## Module Development Workflow

### Creating a New Module

1. **Create separate repository**
   ```bash
   # Create new repo on GitHub
   # Example: ahab-module-nginx
   ```

2. **Add module structure**
   ```
   ahab-module-nginx/
   ├── README.md
   ├── module.yml          ← Docker Compose definition
   ├── ansible/            ← Ansible role (if needed)
   │   ├── tasks/
   │   ├── templates/
   │   └── defaults/
   └── docs/
   ```

3. **Register in MODULE_REGISTRY.yml**
   ```yaml
   nginx:
     repository: "https://github.com/waltdundore/ahab-module-nginx.git"
     version: "v1.0.0"
     description: "Nginx web server"
     deployment: [ansible, docker]
     dependencies: []
     status: stable
   ```

4. **Test module**
   ```bash
   make install nginx
   make test
   ```

### Updating a Module

1. **Make changes in module repository**
   - Update module.yml or Ansible role
   - Test changes
   - Commit and tag new version

2. **Update MODULE_REGISTRY.yml**
   ```yaml
   apache:
     version: "v1.1.0"  # Update version
   ```

3. **Test updated module**
   ```bash
   make clean
   make install apache
   make test
   ```

## Common Mistakes to Avoid

### ❌ Mistake 1: Creating modules/ directory in ahab

**Don't do this:**
```bash
mkdir ahab/modules/apache
```

**Do this instead:**
```bash
# Create separate repository
# Add to MODULE_REGISTRY.yml
```

### ❌ Mistake 2: Copying module code into ahab

**Don't do this:**
```bash
cp -r ~/ahab-module-apache ahab/modules/
```

**Do this instead:**
```bash
# Module stays in its own repository
# ahab references it via MODULE_REGISTRY.yml
```

### ❌ Mistake 3: Editing modules locally

**Don't do this:**
```bash
vim ahab/modules/apache/module.yml
```

**Do this instead:**
```bash
# Clone the module repository
git clone https://github.com/waltdundore/ahab-module-apache.git
cd ahab-module-apache
vim module.yml
git commit -m "Update Apache configuration"
git push
```

## Directory Structure Reference

### ahab (This Repository)

```
ahab/
├── MODULE_REGISTRY.yml      ← Module registry (ONLY place modules are referenced)
├── Makefile                 ← Commands
├── Vagrantfile              ← VM configuration
├── playbooks/               ← Ansible playbooks
├── scripts/                 ← Helper scripts
├── tests/                   ← Test suite
├── inventory/               ← Environment definitions
└── docs/                    ← Documentation
    └── MODULE_ARCHITECTURE.md  ← This file
```

**Note:** No `modules/` directory should exist here!

### ahab-modules (Collection Repository)

```
ahab-modules/
├── README.md
├── apache/                  ← Apache module
├── php/                     ← PHP module
├── docker/                  ← Docker module
└── mysql/                   ← MySQL module (planned)
```

### ahab-module-common (Shared Files)

```
ahab-module-common/
├── README.md
├── templates/               ← Common templates
├── scripts/                 ← Shared scripts
└── docs/                    ← Shared documentation
```

### Individual Module Repository

```
ahab-module-apache/
├── README.md
├── module.yml               ← Docker Compose definition
├── ansible/                 ← Ansible role (optional)
│   ├── tasks/
│   │   └── main.yml
│   ├── templates/
│   ├── defaults/
│   │   └── main.yml
│   └── meta/
│       └── main.yml
├── docs/
│   └── USAGE.md
└── tests/
    └── test.yml
```

## Troubleshooting

### "I see a modules/ directory in ahab"

**This is wrong.** Remove it:

```bash
cd ahab
rm -rf modules/
git add -A
git commit -m "Remove local modules directory - modules live in separate repos"
```

### "How do I edit a module?"

1. Clone the module's repository
2. Make changes there
3. Commit and push
4. Update MODULE_REGISTRY.yml if version changed

### "Where do I find module code?"

- Check MODULE_REGISTRY.yml for repository URL
- Clone that repository
- Module code lives there, not in ahab

## Summary

**Key Points:**

1. ✅ Modules live in separate repositories
2. ✅ MODULE_REGISTRY.yml is the single source of truth
3. ✅ ahab orchestrates, doesn't contain modules
4. ❌ Never create modules/ directory in ahab
5. ❌ Never copy module code into ahab
6. ✅ Use ahab-module-common for shared files
7. ✅ Use ahab-modules for browsing available modules

**When in doubt:** If you're creating or editing a module, you should be in a separate repository, not in ahab.
