# Playbooks Directory

![Ahab Logo](docs/images/ahab-logo.png)

**Purpose**: Orchestrate roles for specific deployment scenarios

---

## Core Principle: Playbooks Orchestrate, Roles Execute

**Playbooks** define WHAT to deploy and WHERE  
**Roles** define HOW to deploy

**Example**:
- ❌ BAD: Playbook contains 100 lines of Apache installation logic
- ✅ GOOD: Playbook calls apache role with specific configuration

---

## Available Playbooks

### 1. workstation.yml
**Purpose**: Provision Ahab workstation with development tools  
**Usage**: `ansible-playbook playbooks/workstation.yml`  
**Called by**: `make install` (via Vagrant)  
**Installs**: Git, Ansible, Docker, development tools

**Why this exists**: Every Ahab deployment starts with a workstation. This is the foundation.

---

### 2. site.yml
**Purpose**: Deploy complete infrastructure (all services)  
**Usage**: `ansible-playbook -i inventory/dev/hosts.yml playbooks/site.yml`  
**Deploys**: All configured services for an environment  
**Tags**: Use tags to deploy specific services

**Why this exists**: Production deployments need everything. One command, complete infrastructure.

**Example**:
```bash
# Deploy everything
ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml

# Deploy only web servers
ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml --tags webserver

# Deploy only databases
ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml --tags database
```

---

### 3. webservers.yml
**Purpose**: Deploy web server infrastructure (Apache + PHP)  
**Usage**: `ansible-playbook -i inventory/dev/hosts.yml playbooks/webservers.yml`  
**Deploys**: Apache, PHP, web content  
**Tags**: apache, php

**Why this exists**: Sometimes you only need web servers, not the entire infrastructure.

**Example**:
```bash
# Deploy Apache + PHP
ansible-playbook -i inventory/dev/hosts.yml playbooks/webservers.yml

# Deploy only Apache
ansible-playbook -i inventory/dev/hosts.yml playbooks/webservers.yml --tags apache
```

---

## Playbook Organization Rules

### Rule #1: Playbooks Call Roles
**Playbooks orchestrate. Roles execute.**

```yaml
# ✅ GOOD: Playbook calls role
- name: Deploy web servers
  hosts: webservers
  roles:
    - apache
    - php

# ❌ BAD: Playbook duplicates role logic
- name: Deploy web servers
  hosts: webservers
  tasks:
    - name: Install Apache
      dnf:
        name: httpd
        state: present
    # ... 50 more lines of Apache logic
```

### Rule #2: Use Inventory for Configuration
**Playbooks define WHAT. Inventory defines WHERE and HOW.**

```yaml
# ✅ GOOD: Configuration in inventory
- name: Deploy Apache
  hosts: webservers
  roles:
    - apache
  # Configuration comes from inventory/group_vars/webservers.yml

# ❌ BAD: Configuration hardcoded in playbook
- name: Deploy Apache
  hosts: webservers
  vars:
    apache_port: 80
    apache_document_root: /var/www/html
  roles:
    - apache
```

### Rule #3: Use Tags for Selective Deployment
**Tags allow deploying specific services.**

```yaml
# ✅ GOOD: Tags for selective deployment
- name: Deploy web infrastructure
  hosts: webservers
  roles:
    - role: apache
      tags: [apache, webserver]
    - role: php
      tags: [php, webserver]
```

### Rule #4: Single Source of Truth (DRY)
**No duplication. Use roles.**

```yaml
# ✅ GOOD: One playbook, multiple environments
ansible-playbook -i inventory/dev/hosts.yml playbooks/site.yml
ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml

# ❌ BAD: Separate playbooks for each environment
playbooks/dev-site.yml
playbooks/prod-site.yml
```

---

## Relationship to Make Commands

### Make Commands Use Docker Compose
```bash
make install apache       # Uses Docker Compose (not Ansible playbooks)
make install apache mysql # Uses Docker Compose (not Ansible playbooks)
```

**Why**: Docker Compose is faster for development and testing.

### Playbooks Are for Production
```bash
# Development: Docker Compose (fast, isolated)
make install apache

# Production: Ansible Playbooks (flexible, multi-host)
ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml
```

**Why**: Production needs multi-host orchestration, configuration management, and idempotency.

---

## Teaching Mindset

**Every playbook teaches**:
- Clear purpose in header comment
- Why this playbook exists
- When to use it vs alternatives
- Example commands

**Example**:
```yaml
---
# ==============================================================================
# Web Servers Playbook
# ==============================================================================
# Deploys Apache + PHP for web hosting
#
# Usage:
#   ansible-playbook -i inventory/dev/hosts.yml playbooks/webservers.yml
#
# Why this exists:
#   Sometimes you only need web servers, not the entire infrastructure.
#   This is faster than deploying everything with site.yml.
#
# Alternative:
#   For development: make install apache php (uses Docker Compose)
#   For everything: ansible-playbook playbooks/site.yml
# ==============================================================================
```

---

## Migration from Old Structure

### Old Structure (WRONG)
```
playbooks/
├── webserver.yml          # Duplicates apache role
├── webserver-docker.yml   # Duplicates apache role
├── lamp.yml               # Calls roles (correct approach)
└── workstation.yml        # Provisions workstation
```

**Problems**:
- `webserver.yml` duplicates apache role logic
- `webserver-docker.yml` duplicates apache role logic
- Two playbooks doing the same thing (DRY violation)
- Unclear which to use

### New Structure (CORRECT)
```
playbooks/
├── README.md              # This file (explains everything)
├── workstation.yml        # Provision workstation (unchanged)
├── site.yml               # Deploy everything
└── webservers.yml         # Deploy web servers only
```

**Benefits**:
- Clear purpose for each playbook
- No duplication (DRY compliant)
- Playbooks call roles (correct pattern)
- Easy to understand which to use

---

## Quick Reference

| Playbook | Purpose | Usage |
|----------|---------|-------|
| workstation.yml | Provision workstation | `make install` |
| site.yml | Deploy everything | `ansible-playbook -i inventory/prod/hosts.yml playbooks/site.yml` |
| webservers.yml | Deploy web servers | `ansible-playbook -i inventory/dev/hosts.yml playbooks/webservers.yml` |

---

## Next Steps

1. **For development**: Use `make install apache` (Docker Compose)
2. **For production**: Use `ansible-playbook playbooks/site.yml` (Ansible)
3. **For specific services**: Use tags or specific playbooks

---

*Last updated: December 8, 2025*
