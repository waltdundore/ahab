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

Six playbooks are live today, plus three deprecated shims that fail with
migration instructions. There is **no `site.yml` or `webservers.yml`** — those
were planned (see `SPEC.md` §4) but never built. Deploy individual services
with `deploy-service.yml`, or use the Docker Compose path (`make install <module>`).

### Live playbooks

| Playbook | Purpose | Target |
|----------|---------|--------|
| `provision-workstation.yml` | Install workstation tools (git, Ansible, Docker, compose, make, Python deps) | `all` (the VM) |
| `workstation.yml` | Provision a workstation with Ansible, Docker, dev tools | `all` (the VM) |
| `install-prerequisites.yml` | Install host prerequisites (Vagrant, VirtualBox, Ansible, Docker) on the control node | `localhost` |
| `deploy-service.yml` | Deploy one service by including its role | `all` |
| `deploy-workstation.yml` | Deploy Ahab to a physical Fedora 43 workstation (user, Docker, firewall) | `workstations` |
| `network-switches.yml` | Manage HP Aruba / Ruckus switches (version, uptime, connectivity) | `network_switches` |

**Notes**
- The `Vagrantfile` provisions via `playbooks/provision-workstation.yml`
  (`config.vm.provision "ansible_local"`), not `workstation.yml`.
- `deploy-service.yml` takes the service as an extra var (must be `apache`,
  `mysql`, or `php`):
  ```bash
  ansible-playbook -i inventory/dev/hosts.yml playbooks/deploy-service.yml -e service=apache
  ```

### Deprecated shims (fail with migration instructions)

| Playbook | Why deprecated | Use instead |
|----------|----------------|-------------|
| `lamp.yml` | Misleading name (no MySQL role); duplicated | `make install apache php` or `deploy-service.yml` |
| `webserver.yml` | Duplicated the apache role; hardcoded | `make install apache` or `deploy-service.yml -e service=apache` |
| `webserver-docker.yml` | Docker belongs in Compose, not Ansible | `make install apache` |

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
  # Configuration comes from inventory (group_vars/ + inventory/<env>/), not the playbook

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

```bash
# ✅ GOOD: One playbook, multiple environments (same playbook, different inventory)
ansible-playbook -i inventory/dev/hosts.yml playbooks/deploy-service.yml -e service=apache
ansible-playbook -i inventory/prod/hosts.yml playbooks/deploy-service.yml -e service=apache

# ❌ BAD: Separate playbooks for each environment (dev-site.yml, prod-site.yml, ...)
#    — that is duplication; the inventory is what differs, not the playbook
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
ansible-playbook -i inventory/prod/hosts.yml playbooks/deploy-service.yml -e service=apache
```

**Why**: Production needs multi-host orchestration, configuration management, and idempotency.

---

## Teaching Mindset

**Every playbook teaches**:
- Clear purpose in header comment
- Why this playbook exists
- When to use it vs alternatives
- Example commands

**Example** (from the live `deploy-service.yml`):
```yaml
---
# ==============================================================================
# Deploy Service with Modular Configuration
# ==============================================================================
# Deploys a single service by including its role (apache, mysql, or php)
#
# Usage:
#   ansible-playbook -i inventory/dev/hosts.yml playbooks/deploy-service.yml -e service=apache
#
# Why this exists:
#   One entry point per service; configuration comes from the site config.
#
# Alternative:
#   For development: make install apache php (uses Docker Compose)
# ==============================================================================
```

---

## History: the web-server playbooks were consolidated

The original `webserver.yml`, `webserver-docker.yml`, and `lamp.yml` each
deployed Apache (and PHP) with overlapping, partly hardcoded logic. They are
now **deprecated shims** that fail with migration instructions, so old commands
still surface a pointer instead of a silent no-op. The live structure is the
six playbooks in the table above; service deployment goes through
`deploy-service.yml` (roles do the work) or Docker Compose for development.

---

## Quick Reference

| Playbook | Purpose | Usage |
|----------|---------|-------|
| provision-workstation.yml | Provision the Vagrant workstation | `make install` (via Vagrantfile) |
| deploy-service.yml | Deploy one service (apache/mysql/php) | `ansible-playbook -i inventory/dev/hosts.yml playbooks/deploy-service.yml -e service=apache` |
| deploy-workstation.yml | Deploy to a physical workstation | `ansible-playbook -i inventory/workstation/hosts.yml playbooks/deploy-workstation.yml` |
| install-prerequisites.yml | Host prerequisites on the control node | `ansible-playbook playbooks/install-prerequisites.yml --ask-become-pass` |
| network-switches.yml | Inspect/manage HP Aruba / Ruckus | `ansible-playbook -i inventory/dev/network-switches.yml playbooks/network-switches.yml` |

---

## Next Steps

1. **For development**: Use `make install apache` (Docker Compose)
2. **For a single service**: Use `ansible-playbook playbooks/deploy-service.yml -e service=<apache|mysql|php>` (Ansible)
3. **For workstation bring-up**: Use `make install` (Vagrant) or `deploy-workstation.yml` (physical)

---

*Last updated: December 8, 2025*
