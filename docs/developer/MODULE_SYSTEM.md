# Ahab Module System

## Overview

The Ahab module system provides a standardized way to create, document, and manage Ansible roles with automatic dependency tracking and testing.

---

## Module Structure

Each module is a self-contained Ansible role with metadata:

```
ahab/roles/
├── apache/
│   ├── meta/
│   │   └── main.yml          # Dependencies and metadata
│   ├── tasks/
│   │   └── main.yml          # Installation tasks
│   ├── handlers/
│   │   └── main.yml          # Service handlers
│   ├── templates/
│   │   └── *.conf.j2         # Configuration templates
│   ├── defaults/
│   │   └── main.yml          # Default variables
│   ├── vars/
│   │   └── main.yml          # OS-specific variables
│   ├── tests/
│   │   ├── test.yml          # Test playbook
│   │   └── inventory         # Test inventory
│   ├── README.md             # Module documentation
│   └── MODULE.yml            # Module metadata (Ahab-specific)
```

---

## MODULE.yml Format

Each module has a `MODULE.yml` file that defines:

```yaml
---
# Module metadata
module:
  name: apache
  version: "1.0.0"
  description: "Apache HTTP Server installation and configuration"
  author: "Your Name"
  license: "MIT"
  
  # Supported platforms
  platforms:
    - name: Fedora
      versions: ["38", "39"]
    - name: Debian
      versions: ["11", "12"]
    - name: Ubuntu
      versions: ["20.04", "22.04"]
  
  # Module dependencies (other Ahab modules)
  dependencies: []
  
  # System prerequisites
  prerequisites:
    packages:
      fedora:
        - httpd
        - mod_ssl
      debian:
        - apache2
        - apache2-utils
    services:
      - httpd  # Fedora
      - apache2  # Debian
    ports:
      - 80
      - 443
    
  # Configuration
  configuration:
    required_vars:
      - apache_server_name
    optional_vars:
      - apache_port: 80
      - apache_ssl_port: 443
      - apache_document_root: /var/www/html
  
  # Testing
  testing:
    test_playbook: tests/test.yml
    test_commands:
      - "curl -I http://localhost"
      - "systemctl status httpd || systemctl status apache2"
    expected_results:
      - "HTTP/1.1 200 OK"
      - "active (running)"
```

---

## Creating a New Module

### Step 1: Generate Module Structure

```bash
cd ahab
make create-module MODULE=apache
```

This creates the complete directory structure.

### Step 2: Define Module Metadata

Edit `roles/apache/MODULE.yml` with your module details.

### Step 3: Write Tasks

Edit `roles/apache/tasks/main.yml`:

```yaml
---
# Apache installation tasks
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Install Apache
  package:
    name: "{{ apache_packages }}"
    state: present

- name: Start and enable Apache
  service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes
```

### Step 4: Create Tests

Edit `roles/apache/tests/test.yml`:

```yaml
---
- hosts: localhost
  roles:
    - apache
  
  post_tasks:
    - name: Test Apache is running
      uri:
        url: http://localhost
        status_code: 200
```

### Step 5: Document Module

Edit `roles/apache/README.md` with usage instructions.

---

## Module Dependencies

### Declaring Dependencies

In `MODULE.yml`:

```yaml
dependencies:
  - name: apache
    version: ">=1.0.0"
  - name: common
    version: "*"
```

### Dependency Resolution

The module system automatically:
1. Checks if dependencies are installed
2. Validates version compatibility
3. Installs dependencies in correct order
4. Prevents circular dependencies

---

## Testing Modules

### Test Individual Module

```bash
# Test Apache module alone
make test-module MODULE=apache

# Test PHP module alone
make test-module MODULE=php
```

### Test Module with Dependencies

```bash
# Test PHP (which depends on Apache)
make test-module MODULE=php

# Automatically tests:
# 1. Apache installation
# 2. PHP installation
# 3. Apache + PHP integration
```

### Test All Modules

```bash
# Test all modules
make test-modules

# Runs tests for each module in dependency order
```

---

## Module Registry

The module registry tracks all available modules:

`ahab/MODULE_REGISTRY.yml`:

```yaml
---
modules:
  apache:
    path: roles/apache
    version: "1.0.0"
    status: stable
    dependencies: []
  
  php:
    path: roles/php
    version: "1.0.0"
    status: stable
    dependencies:
      - apache
  
  docker:
    path: roles/docker
    version: "1.0.0"
    status: stable
    dependencies: []
```

---

## Module Lifecycle

### Development

1. Create module structure
2. Write tasks and tests
3. Document module
4. Test individually
5. Test with dependencies

### Stable

1. All tests pass
2. Documentation complete
3. Version tagged
4. Added to registry

### Deprecated

1. Mark as deprecated in MODULE.yml
2. Provide migration path
3. Remove after grace period

---

## Best Practices

### Module Design

- ✅ Keep modules focused (single responsibility)
- ✅ Make modules idempotent
- ✅ Support multiple OS families
- ✅ Provide sensible defaults
- ✅ Document all variables
- ✅ Include comprehensive tests

### Dependencies

- ✅ Minimize dependencies
- ✅ Use version constraints
- ✅ Document why dependencies exist
- ✅ Test with and without optional dependencies

### Testing

- ✅ Test on all supported platforms
- ✅ Test with minimum and maximum versions
- ✅ Test dependency combinations
- ✅ Include integration tests
- ✅ Verify idempotency

### Documentation

- ✅ Clear description
- ✅ Usage examples
- ✅ Variable documentation
- ✅ Platform notes
- ✅ Troubleshooting section

---

## Module Commands

### Create Module

```bash
make create-module MODULE=<module-name>
```

### List Modules

```bash
make list-modules
```

### Validate Module

```bash
make validate-module MODULE=apache
```

### Test Module

```bash
make test-module MODULE=apache
```

### Install Module

```bash
make install-module MODULE=apache
```

### Update Module

```bash
make update-module MODULE=apache
```

---

## Example: Apache + PHP

### Apache Module (Standalone)

```yaml
# roles/apache/MODULE.yml
module:
  name: apache
  dependencies: []
  prerequisites:
    packages:
      fedora: [httpd]
      debian: [apache2]
```

### PHP Module (Depends on Apache)

```yaml
# roles/php/MODULE.yml
module:
  name: php
  dependencies:
    - name: apache
      version: ">=1.0.0"
  prerequisites:
    packages:
      fedora: [php, php-fpm]
      debian: [php, libapache2-mod-php]
```

### Testing

```bash
# Test Apache alone
make test-module MODULE=apache
# ✓ Apache installs
# ✓ Apache serves pages

# Test PHP alone (installs Apache automatically)
make test-module MODULE=php
# ✓ Apache installs (dependency)
# ✓ PHP installs
# ✓ Apache + PHP integration works

# Test both together
make test-modules MODULES="apache,php"
# ✓ Dependency order correct
# ✓ No conflicts
# ✓ Integration works
```

---

## Module Playbooks

### Using Modules in Playbooks

```yaml
---
# playbooks/webserver.yml
- hosts: webservers
  roles:
    - apache
    - php
  
  vars:
    apache_server_name: example.com
    php_version: "8.2"
```

### Conditional Dependencies

```yaml
---
# playbooks/wordpress.yml
- hosts: wordpress
  roles:
    - apache
    - php
    - mysql
    - wordpress
  
  vars:
    wordpress_requires_php: true
    wordpress_requires_mysql: true
```

---

## Module Validation

The module system validates:

- ✅ MODULE.yml syntax
- ✅ Required fields present
- ✅ Dependencies exist
- ✅ Version constraints valid
- ✅ Platform support declared
- ✅ Tests exist
- ✅ Documentation complete

---

## Next Steps

1. Create Apache module
2. Create PHP module
3. Test individually
4. Test together
5. Document integration
6. Add to registry

See [MODULE_FRAMEWORK.md](MODULE_FRAMEWORK.md) for detailed development guide.
