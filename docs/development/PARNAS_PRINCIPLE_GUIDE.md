# Parnas's Information Hiding Principle - Complete Guide

![Ahab Logo](../docs/images/ahab-logo.png)

## Table of Contents

1. [What is Parnas's Principle?](#what-is-parnass-principle)
2. [Why Does This Matter?](#why-does-this-matter)
3. [How Ahab Implements This Principle](#how-ahab-implements-this-principle)
4. [The Property Test Explained](#the-property-test-explained)
5. [Understanding Test Results](#understanding-test-results)
6. [How to Fix Violations](#how-to-fix-violations)
7. [Examples and Anti-Patterns](#examples-and-anti-patterns)

---

## What is Parnas's Principle?

**Parnas's Information Hiding Principle** states:

> *"For any set of alternatives in a system, exactly one module should know the exhaustive list of those alternatives."*

This principle was articulated by computer scientist David Parnas in his seminal 1972 paper "On the Criteria To Be Used in Decomposing Systems into Modules."

### The Core Idea

When your system supports multiple alternatives (different operating systems, different modules, different deployment methods), **exactly one place** in your codebase should contain the complete list of those alternatives. All other code should query that single source.

### Simple Example

**❌ BAD - Violates Parnas's Principle:**
```bash
# In install-apache.sh
case $OS in
    fedora|centos|rhel) install_rpm ;;
    debian|ubuntu) install_deb ;;
esac

# In install-mysql.sh
case $OS in
    fedora|centos|rhel) install_rpm ;;
    debian|ubuntu) install_deb ;;
esac

# In install-php.sh
case $OS in
    fedora|centos|rhel) install_rpm ;;
    debian|ubuntu) install_deb ;;
esac
```

**Problem:** The list of supported operating systems is duplicated in three places. When you add support for a new OS (like Alpine Linux), you must remember to update all three files.

**✅ GOOD - Follows Parnas's Principle:**
```bash
# In ahab.conf (SINGLE SOURCE OF TRUTH)
SUPPORTED_OS="fedora centos rhel debian ubuntu"
RPM_BASED="fedora centos rhel"
DEB_BASED="debian ubuntu"

# In install-apache.sh
source ahab.conf
if [[ " $RPM_BASED " =~ " $OS " ]]; then
    install_rpm
elif [[ " $DEB_BASED " =~ " $OS " ]]; then
    install_deb
fi

# In install-mysql.sh
source ahab.conf
if [[ " $RPM_BASED " =~ " $OS " ]]; then
    install_rpm
elif [[ " $DEB_BASED " =~ " $OS " ]]; then
    install_deb
fi
```

**Benefit:** Now when you add Alpine Linux support, you only update `ahab.conf` once. All scripts automatically know about the new OS.

---

## Why Does This Matter?

### 1. **Maintainability**

When alternatives are scattered across your codebase:
- Adding a new alternative requires changes in multiple files
- You might forget to update some locations
- The system becomes inconsistent

With Parnas's principle:
- Add the alternative in ONE place
- All code automatically knows about it
- Consistency is guaranteed

### 2. **Correctness**

**Real-world scenario:** Ahab supports Apache, MySQL, and PHP modules.

**Without Parnas's principle:**
```bash
# In Makefile
MODULES = apache mysql php

# In generate-compose.py
supported_modules = ["apache", "mysql", "php"]

# In validate-module.sh
case $MODULE in
    apache|mysql|php) echo "valid" ;;
    *) echo "invalid" ;;
esac
```

**What happens when you add Redis?**
- You update the Makefile ✓
- You forget to update generate-compose.py ✗
- You forget to update validate-module.sh ✗
- Result: `make install redis` appears to work, but Docker Compose generation fails silently

**With Parnas's principle:**
```yaml
# MODULE_REGISTRY.yml (SINGLE SOURCE)
registry:
  modules:
    apache: {...}
    mysql: {...}
    php: {...}
    redis: {...}  # Add here ONCE
```

All code reads from this registry. Add Redis once, everything works.

### 3. **Testability**

With Parnas's principle, you can write a property test that verifies:
- Only ONE file contains the exhaustive list
- All other code references that single source
- No hardcoded alternatives exist elsewhere

This is exactly what `test-parnas-principle.sh` does.

---

## How Ahab Implements This Principle

Ahab has **two primary single sources of truth**:

### 1. MODULE_REGISTRY.yml - The Single Source for Modules

**Location:** `ahab/MODULE_REGISTRY.yml`

**What it contains:**
- Complete list of all available modules (Apache, MySQL, PHP, etc.)
- Module metadata (repository URL, version, dependencies, status)
- Deployment methods for each module
- Documentation links

**Example:**
```yaml
registry:
  version: "1.0"
  modules:
    apache:
      repository: "https://github.com/waltdundore/ahab-module-apache.git"
      version: "v1.0.0"
      description: "Apache HTTP Server"
      deployment_methods: [ansible, docker]
      dependencies: []
      status: stable
    
    mysql:
      repository: "https://github.com/waltdundore/ahab-module-mysql.git"
      version: "v1.2.0"
      description: "MySQL Database Server"
      deployment_methods: [docker]
      dependencies: []
      status: stable
```

**Who reads from it:**
- `make install <module>` - validates module exists
- `scripts/fetch-modules.sh` - downloads module repositories
- `scripts/generate-docker-compose.py` - generates compose files
- `make help` - lists available modules

**The rule:** No script should hardcode module names. All must read from MODULE_REGISTRY.yml.

### 2. ahab.conf - The Single Source for Configuration

**Location:** `ahab/ahab.conf` (or `ahab.conf` in root)

**What it contains:**
- Operating system versions (Fedora, Debian, Ubuntu)
- VM resource allocations (memory, CPUs)
- Network configuration
- Package lists
- System-wide settings

**Example:**
```ini
[system]
FEDORA_VERSION=43
DEBIAN_VERSION=13
UBUNTU_VERSION=24.04

[vm]
MEMORY=2048
CPUS=2

[packages]
WORKSTATION_PACKAGES=git,ansible,docker,make
```

**Who reads from it:**
- `Vagrantfile` - VM configuration
- `scripts/install-packages.sh` - package installation
- `playbooks/*.yml` - Ansible playbooks
- All shell scripts that need OS-specific behavior

**The rule:** No script should hardcode OS versions or configuration values. All must source ahab.conf.

---

## The Property Test Explained

The test file `ahab/tests/property/test-parnas-principle.sh` verifies that Ahab follows Parnas's principle.

### What the Test Does

The test runs **7 core checks** plus **100+ iterations** to verify the property holds:

#### Test 1: MODULE_REGISTRY.yml is Single Source for Modules

**What it checks:**
- Searches all shell scripts, Python files, and Makefiles
- Looks for hardcoded module lists like:
  - `modules=(apache mysql php)`
  - `case apache|mysql|php)`
- Excludes documentation and test files (they can mention modules)

**Why it matters:**
If this test fails, it means some code has a hardcoded list of modules. When you add a new module to the registry, that code won't know about it.

**Example violation:**
```bash
# In some-script.sh
AVAILABLE_MODULES="apache mysql php"  # ❌ VIOLATION!
```

**Correct approach:**
```bash
# In some-script.sh
AVAILABLE_MODULES=$(yq eval '.registry.modules | keys | .[]' MODULE_REGISTRY.yml)
```

#### Test 2: ahab.conf is Single Source for OS Versions

**What it checks:**
- Searches all code files
- Looks for hardcoded OS version assignments like:
  - `FEDORA_VERSION=43`
  - `DEBIAN_VERSION=13`
- Excludes ahab.conf itself (that's where they should be)

**Why it matters:**
If this test fails, some code has hardcoded OS versions. When Fedora 44 is released, you'll need to update multiple files instead of just ahab.conf.

**Example violation:**
```bash
# In install-vm.sh
FEDORA_VERSION=43  # ❌ VIOLATION!
vagrant box add fedora/$FEDORA_VERSION
```

**Correct approach:**
```bash
# In install-vm.sh
source ahab.conf  # ✓ CORRECT
vagrant box add fedora/$FEDORA_VERSION
```

#### Test 3: Scripts Source ahab.conf When Using Config Variables

**What it checks:**
- Finds all shell scripts
- For each script that uses variables like `$FEDORA_VERSION`
- Verifies the script sources ahab.conf first

**Why it matters:**
If a script uses `$FEDORA_VERSION` without sourcing ahab.conf, the variable will be empty or undefined, causing silent failures.

**Example violation:**
```bash
#!/bin/bash
# install-fedora.sh

# ❌ VIOLATION - uses $FEDORA_VERSION without sourcing config
echo "Installing Fedora $FEDORA_VERSION"
vagrant box add fedora/$FEDORA_VERSION
```

**Correct approach:**
```bash
#!/bin/bash
# install-fedora.sh

# ✓ CORRECT - sources config first
source "$(dirname "$0")/../ahab.conf"
echo "Installing Fedora $FEDORA_VERSION"
vagrant box add fedora/$FEDORA_VERSION
```

#### Test 4: No Hardcoded Module Lists in Code

**What it checks:**
- Searches for patterns suggesting hardcoded module lists
- Looks for case statements with multiple module names
- Looks for arrays containing module names

**Why it matters:**
Catches subtle violations where modules are listed together in code.

**Example violation:**
```bash
# In validate-modules.sh
case $MODULE in
    apache|mysql|php|redis)  # ❌ VIOLATION!
        echo "Valid module"
        ;;
    *)
        echo "Invalid module"
        ;;
esac
```

**Correct approach:**
```bash
# In validate-modules.sh
VALID_MODULES=$(yq eval '.registry.modules | keys | .[]' MODULE_REGISTRY.yml)
if echo "$VALID_MODULES" | grep -q "^$MODULE$"; then
    echo "Valid module"
else
    echo "Invalid module"
fi
```

#### Test 5: No Hardcoded OS Version Numbers in Code

**What it checks:**
- Searches for patterns like `fedora:43`, `debian/13`, `ubuntu:24.04`
- These are hardcoded version numbers in Docker images or URLs

**Why it matters:**
Catches violations where OS versions are embedded in strings.

**Example violation:**
```dockerfile
# In Dockerfile
FROM fedora:43  # ❌ VIOLATION!
```

**Correct approach:**
```dockerfile
# In Dockerfile
ARG FEDORA_VERSION
FROM fedora:${FEDORA_VERSION}
```

Then pass the version from ahab.conf when building.

#### Test 6: MODULE_REGISTRY.yml Contains All Referenced Modules

**What it checks:**
- Scans documentation and code for module references
- Extracts module names (apache, mysql, php, etc.)
- Verifies each referenced module exists in MODULE_REGISTRY.yml

**Why it matters:**
Catches the opposite problem: documentation mentions a module that doesn't exist in the registry.

**Example violation:**
```markdown
# In README.md
You can install Redis with `make install redis`
```

But MODULE_REGISTRY.yml doesn't have a `redis:` entry.

**Fix:** Either add Redis to the registry, or remove the documentation reference.

#### Test 7: ahab.conf Contains All OS Alternatives

**What it checks:**
- Verifies ahab.conf has entries for all major OS families
- Checks for `FEDORA_VERSION`, `DEBIAN_VERSION`, `UBUNTU_VERSION`

**Why it matters:**
Ensures the single source of truth is actually complete.

**Example violation:**
ahab.conf is missing `UBUNTU_VERSION=24.04`

**Fix:** Add the missing OS version to ahab.conf.

#### Iteration Tests (100+ runs)

**What they do:**
- Run 100+ iterations of randomized checks
- Each iteration verifies:
  - MODULE_REGISTRY.yml is readable
  - ahab.conf is readable
  - Files exist and are accessible

**Why it matters:**
Property-based testing principle: run the same checks many times with slight variations to catch edge cases and race conditions.

---

## Understanding Test Results

### Successful Test Run

```
==================================================
Parnas's Information Hiding Principle - Property Test
==================================================

Testing that alternatives are managed in exactly one place
Running 100 iterations...

==================================================
Test 1: MODULE_REGISTRY.yml is single source for modules
==================================================
✓ No hardcoded module lists found - registry is single source

==================================================
Test 2: ahab.conf is single source for OS versions
==================================================
✓ No hardcoded OS versions found - ahab.conf is single source

==================================================
Test 3: Scripts source ahab.conf when using config variables
==================================================
✓ install-packages.sh properly sources config
✓ create-vm.sh properly sources config
✓ deploy-services.sh properly sources config

==================================================
Test 4: No hardcoded module lists in code
==================================================
✓ No hardcoded module lists found

==================================================
Test 5: No hardcoded OS version numbers in code
==================================================
✓ No hardcoded OS versions found

==================================================
Test 6: MODULE_REGISTRY.yml contains all referenced modules
==================================================
✓ All referenced modules are in registry

==================================================
Test 7: ahab.conf contains all OS alternatives
==================================================
✓ All OS version variables present in ahab.conf

==================================================
Running 100 property test iterations
==================================================
Completed 20/100 iterations...
Completed 40/100 iterations...
Completed 60/100 iterations...
Completed 80/100 iterations...
Completed 100/100 iterations...

==================================================
Test Summary
==================================================
Tests run:    107
Tests passed: 107
Tests failed: 0

✓ All tests passed - Parnas's principle is upheld

Property verified:
  • MODULE_REGISTRY.yml is the single source for modules
  • ahab.conf is the single source for OS versions
  • No hardcoded alternatives found in code
  • All code references the single sources of truth
```

**What this means:**
- ✅ Your codebase follows Parnas's principle
- ✅ All alternatives are managed in exactly one place
- ✅ Adding new modules or OS versions only requires updating one file
- ✅ The system is maintainable and consistent

### Failed Test Run

```
==================================================
Test 1: MODULE_REGISTRY.yml is single source for modules
==================================================
⚠ Hardcoded module list in: install-services.sh
⚠ Hardcoded module case statement in: validate-module.sh
✗ Found 2 hardcoded module lists

==================================================
Test 2: ahab.conf is single source for OS versions
==================================================
⚠ Hardcoded OS version assignment in: Dockerfile
✗ Found 1 hardcoded OS version assignments

==================================================
Test 3: Scripts source ahab.conf when using config variables
==================================================
✓ install-packages.sh properly sources config
✗ create-vm.sh uses config variables without sourcing ahab.conf
✓ deploy-services.sh properly sources config

==================================================
Test Summary
==================================================
Tests run:    107
Tests passed: 104
Tests failed: 3

✗ Some tests failed - Parnas's principle violations found

Violations indicate:
  • Hardcoded module lists or OS versions in code
  • Scripts not sourcing ahab.conf properly
  • Missing entries in registry or config
```

**What this means:**
- ❌ Your codebase violates Parnas's principle
- ❌ Some code has hardcoded alternatives
- ❌ Adding new alternatives will require changes in multiple places
- ⚠️ The system is at risk of inconsistency

**Next steps:** See "How to Fix Violations" below.

---

## How to Fix Violations

### Violation Type 1: Hardcoded Module List

**Error message:**
```
⚠ Hardcoded module list in: install-services.sh
```

**How to find it:**
```bash
grep -n "apache.*mysql\|mysql.*apache" install-services.sh
```

**Example violation:**
```bash
# Line 42 in install-services.sh
MODULES="apache mysql php"
```

**How to fix:**
```bash
# Read from MODULE_REGISTRY.yml instead
MODULES=$(yq eval '.registry.modules | keys | .[]' MODULE_REGISTRY.yml | tr '\n' ' ')
```

Or if you need to check if a specific module exists:
```bash
# Instead of hardcoding
if [[ "$MODULE" == "apache" ]] || [[ "$MODULE" == "mysql" ]]; then
    # ...
fi

# Read from registry
if yq eval ".registry.modules | has(\"$MODULE\")" MODULE_REGISTRY.yml | grep -q "true"; then
    # ...
fi
```

### Violation Type 2: Hardcoded OS Version

**Error message:**
```
⚠ Hardcoded OS version assignment in: Dockerfile
```

**How to find it:**
```bash
grep -n "FEDORA_VERSION=\|DEBIAN_VERSION=" Dockerfile
```

**Example violation:**
```dockerfile
# Line 1 in Dockerfile
FROM fedora:43
```

**How to fix:**
```dockerfile
# Use build argument
ARG FEDORA_VERSION=43
FROM fedora:${FEDORA_VERSION}
```

Then when building:
```bash
source ahab.conf
docker build --build-arg FEDORA_VERSION=$FEDORA_VERSION -t myimage .
```

### Violation Type 3: Script Doesn't Source Config

**Error message:**
```
✗ create-vm.sh uses config variables without sourcing ahab.conf
```

**How to find it:**
```bash
# Check if script uses config variables
grep -n '\$FEDORA_VERSION\|\$DEBIAN_VERSION' create-vm.sh

# Check if script sources config
grep -n 'source.*ahab\.conf' create-vm.sh
```

**Example violation:**
```bash
#!/bin/bash
# create-vm.sh

# Uses $FEDORA_VERSION but doesn't source ahab.conf
vagrant box add fedora/$FEDORA_VERSION
```

**How to fix:**
```bash
#!/bin/bash
# create-vm.sh

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source ahab.conf (adjust path as needed)
source "$SCRIPT_DIR/../ahab.conf"

# Now $FEDORA_VERSION is defined
vagrant box add fedora/$FEDORA_VERSION
```

### Violation Type 4: Module Referenced But Not in Registry

**Error message:**
```
⚠ Module 'redis' referenced but not in registry
```

**How to find it:**
```bash
grep -rn "redis" docs/ README.md
```

**Example violation:**
```markdown
# In README.md line 42
You can install Redis with `make install redis`
```

But MODULE_REGISTRY.yml doesn't have Redis.

**How to fix - Option 1: Add to registry**
```yaml
# In MODULE_REGISTRY.yml
registry:
  modules:
    redis:
      repository: "https://github.com/waltdundore/ahab-module-redis.git"
      version: "v1.0.0"
      description: "Redis Cache Server"
      deployment_methods: [docker]
      dependencies: []
      status: beta
```

**How to fix - Option 2: Remove from documentation**
```markdown
# In README.md
You can install Apache, MySQL, or PHP with `make install <module>`
```

### Violation Type 5: Missing OS Version in Config

**Error message:**
```
✗ Missing UBUNTU_VERSION in ahab.conf
```

**How to fix:**
```ini
# Add to ahab.conf
[system]
FEDORA_VERSION=43
DEBIAN_VERSION=13
UBUNTU_VERSION=24.04  # Add this line
```

---

## Examples and Anti-Patterns

### Example 1: Adding a New Module

**❌ WRONG WAY (Violates Parnas's Principle):**

1. Add module to Makefile:
```makefile
AVAILABLE_MODULES = apache mysql php nginx  # Added nginx
```

2. Add module to validation script:
```bash
case $MODULE in
    apache|mysql|php|nginx)  # Added nginx
        echo "valid"
        ;;
esac
```

3. Add module to Docker Compose generator:
```python
supported_modules = ["apache", "mysql", "php", "nginx"]  # Added nginx
```

4. Update documentation:
```markdown
Available modules: apache, mysql, php, nginx
```

**Problems:**
- Changed 4 files
- Easy to forget one
- Inconsistency risk
- Test will fail

**✅ RIGHT WAY (Follows Parnas's Principle):**

1. Add module to MODULE_REGISTRY.yml ONLY:
```yaml
registry:
  modules:
    nginx:
      repository: "https://github.com/waltdundore/ahab-module-nginx.git"
      version: "v1.0.0"
      description: "Nginx Web Server"
      deployment_methods: [docker]
      dependencies: []
      status: stable
```

2. Done! All code automatically knows about nginx:
- Makefile reads from registry
- Validation script reads from registry
- Docker Compose generator reads from registry
- Documentation can use `make help` which reads from registry

**Benefits:**
- Changed 1 file
- Impossible to forget
- Guaranteed consistency
- Test will pass

### Example 2: Updating OS Version

**❌ WRONG WAY:**

Fedora 44 is released. You need to update:

1. ahab.conf:
```ini
FEDORA_VERSION=44
```

2. Vagrantfile:
```ruby
config.vm.box = "fedora/44"
```

3. Dockerfile:
```dockerfile
FROM fedora:44
```

4. Documentation:
```markdown
Ahab supports Fedora 44
```

**Problems:**
- Changed 4 files
- Vagrantfile and Dockerfile shouldn't hardcode versions
- Test will fail

**✅ RIGHT WAY:**

1. Update ahab.conf ONLY:
```ini
FEDORA_VERSION=44
```

2. Vagrantfile reads from config:
```ruby
require 'inifile'
config_file = IniFile.load('../ahab.conf')
fedora_version = config_file['system']['FEDORA_VERSION']
config.vm.box = "fedora/#{fedora_version}"
```

3. Dockerfile uses build arg:
```dockerfile
ARG FEDORA_VERSION
FROM fedora:${FEDORA_VERSION}
```

4. Documentation references config:
```markdown
Ahab supports Fedora (version configured in ahab.conf)
```

**Benefits:**
- Changed 1 file
- All code automatically uses new version
- Test will pass

### Example 3: Checking if Module is Valid

**❌ WRONG WAY:**
```bash
#!/bin/bash
# validate-module.sh

MODULE=$1

# Hardcoded list - violates Parnas's principle
case $MODULE in
    apache|mysql|php)
        echo "Valid module"
        exit 0
        ;;
    *)
        echo "Invalid module"
        exit 1
        ;;
esac
```

**✅ RIGHT WAY:**
```bash
#!/bin/bash
# validate-module.sh

MODULE=$1
REGISTRY="$(dirname "$0")/../MODULE_REGISTRY.yml"

# Check if module exists in registry
if yq eval ".registry.modules | has(\"$MODULE\")" "$REGISTRY" | grep -q "true"; then
    echo "Valid module"
    exit 0
else
    echo "Invalid module"
    echo "Available modules:"
    yq eval '.registry.modules | keys | .[]' "$REGISTRY"
    exit 1
fi
```

**Benefits:**
- No hardcoded module list
- Automatically knows about new modules
- Can show available modules from registry
- Test will pass

### Example 4: Generating Docker Compose

**❌ WRONG WAY:**
```python
# generate-compose.py

def generate_compose(modules):
    # Hardcoded module configurations - violates Parnas's principle
    configs = {
        'apache': {'image': 'httpd:2.4', 'ports': ['80:80']},
        'mysql': {'image': 'mysql:8.0', 'ports': ['3306:3306']},
        'php': {'image': 'php:8.2-fpm', 'ports': ['9000:9000']},
    }
    
    for module in modules:
        if module in configs:
            # Generate service...
            pass
```

**✅ RIGHT WAY:**
```python
# generate-compose.py
import yaml

def load_registry():
    with open('MODULE_REGISTRY.yml', 'r') as f:
        return yaml.safe_load(f)

def generate_compose(modules):
    registry = load_registry()
    
    for module in modules:
        if module in registry['registry']['modules']:
            module_info = registry['registry']['modules'][module]
            # Use module_info to generate service...
            # All configuration comes from registry
            pass
```

**Benefits:**
- No hardcoded module configurations
- Module metadata lives in registry
- Adding new module only requires updating registry
- Test will pass

---

## Summary

**Parnas's Principle in One Sentence:**
> For any set of alternatives, exactly one file should contain the complete list, and all other code should read from that file.

**In Ahab:**
- **MODULE_REGISTRY.yml** = single source for modules
- **ahab.conf** = single source for configuration

**The Test:**
- Verifies only these files contain exhaustive lists
- Verifies all other code reads from these files
- Runs 100+ iterations to ensure property holds

**When You Add Something New:**
1. Update the single source (registry or config)
2. Run the test: `make test-parnas` or `./ahab/tests/property/test-parnas-principle.sh`
3. If it passes, you're done!
4. If it fails, fix the violations using this guide

**Why This Matters:**
- **Maintainability:** Change one file, not many
- **Correctness:** Impossible to have inconsistent alternatives
- **Testability:** Property test verifies the principle holds

---

## Further Reading

- David Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (1972)
- [Wikipedia: Information Hiding](https://en.wikipedia.org/wiki/Information_hiding)
- [Parnas's Principles in Modern Software](https://www.cs.umd.edu/class/spring2003/cmsc838p/Design/criteria.pdf)

---

**Questions or Issues?**

If you encounter violations you don't know how to fix, or if you think the test is reporting a false positive:

1. Check this guide for examples
2. Look at the test output for specific file names and line numbers
3. Use `grep` to find the violation in your code
4. Ask for help in the project discussions

Remember: The test is your friend. It's catching problems before they cause bugs!
