<div align="center">

# Ahab Control

![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ansible-control/prod/docs/images/ahab-logo.png)

**Automated Host Administration & Build**

*Ansible-based infrastructure automation for provisioning and managing Linux systems*

</div>

---

## Repository Dependencies

**This repository requires two companion repositories to function:**

1. **[ansible-inventory](https://github.com/waltdundore/ansible-inventory)** - Environment-specific host definitions
2. **[ansible-config](https://github.com/waltdundore/ansible-config)** - Central configuration file

### Quick Setup

```bash
# Clone all three repositories
cd ~/git
git clone git@github.com:waltdundore/ansible-control.git
git clone git@github.com:waltdundore/ansible-inventory.git
git clone git@github.com:waltdundore/ansible-config.git

# Create symlinks
cd ansible-control
ln -s ../ansible-inventory inventory
ln -s ../ansible-config/config.yml config.yml
```

### Repository Structure

```
~/git/
├── ansible-control/      # THIS REPO - Playbooks, roles, Vagrant
│   ├── inventory -> ../ansible-inventory (symlink)
│   └── config.yml -> ../ansible-config/config.yml (symlink)
├── ansible-inventory/    # Host definitions (dev/prod/workstation)
└── ansible-config/       # Configuration settings
```

### Branch Synchronization

All three repositories have matching branches:
- `dev` - Development environment
- `prod` - Production environment
- `workstation` - Workstation setup

**IMPORTANT:** Switch all three repos to the same branch when working:
```bash
cd ~/git/ansible-control && git checkout dev
cd ~/git/ansible-inventory && git checkout dev
cd ~/git/ansible-config && git checkout dev
```

## Summary

This project provides:
- **Unified Management**: Single codebase for x86, ARM/Raspberry Pi systems
- **Environment Separation**: Branch-based dev/prod workflow with safe promotion
- **Local Testing**: Vagrant integration for testing before production deployment
- **Multi-Distribution**: Supports Fedora, Debian, and Raspberry Pi OS
- **Automation First**: Makefile-driven workflows

## Prerequisites

Before starting, ensure you have:
- Ansible
- Vagrant (with libvirt, Parallels, or other provider) - for local testing
- Make
- Git
- SSH

## Workstation Setup (Fedora 43)

If you need to set up your Fedora 43 workstation with all prerequisites, use the `workstation` branch:

```bash
# Switch all repos to workstation branch
cd ~/git/ansible-control && git checkout workstation
cd ~/git/ansible-inventory && git checkout workstation
cd ~/git/ansible-config && git checkout workstation

# Run bootstrap
cd ~/git/ansible-control
./bootstrap.sh
```

**IMPORTANT - Sudo Password:**
- `bootstrap.sh` requires your system sudo password

This will install and configure:
- Ansible, Make, Git (via bootstrap.sh)
- Vagrant with vagrant-libvirt plugin (via Ansible)
- libvirt/KVM virtualization (via Ansible)
- Docker CE (via Ansible)
- VS Code and development tools (via Ansible)

**After provisioning:** Log out and back in, then switch back to dev branch.

## Configuration

**Before running any commands, configure 2 files:**

### 1. Create Inventory File (ansible-inventory repo)

```bash
cd ~/git/ansible-inventory
cp hosts.yml.example dev/hosts.yml
vim dev/hosts.yml
```

Edit two things:
- Replace `your_username` with your SSH username
- Replace example hostnames with your actual hosts

### 2. Edit config.yml (ansible-config repo)

```bash
cd ~/git/ansible-config
vim config.yml
```

**Required changes:**
```yaml
ssh:
  public_key: ~/.ssh/id_ed25519.pub  # Update if you use different key
```

**Optional changes:**
```yaml
vagrant:
  cpus: 4        # Adjust for your system
  memory: 16384  # 16GB - adjust as needed
```

## Quick Start

**After configuration, you can:**

### Local Testing with Vagrant

**VM password** (if needed): `password`

```bash
cd ~/git/ansible-control

# Single VM (configured in config.yml)
make install          # Create and provision single VM
make debug            # Create VM with verbose debug output
make ssh              # SSH into VM as root
make clean            # Destroy all VMs

# Multi VM (configured in config.yml vagrant_multi.vms)
make multi            # Create and provision all VMs
make status           # Show status of all VMs

# Provisioning (works for both single and multi)
make provision        # Re-provision all running VMs using Ansible
```

### Deploy to Real Hosts

```bash
# Deploy to all hosts in current branch inventory
make deploy

# Deploy to specific host
make deploy HOST=hostname.example.com

# Deploy to specific group
make deploy HOST=x86
make deploy HOST=rpi4
make deploy HOST=rpi5
```

### Git Workflow

```bash
# Commit and push current branch
make publish
# Confirms current branch, prompts for commit message
# Option to switch branches before publishing

# Promote dev to prod (merges dev→prod and pushes)
make promote
# Must be on dev branch with no uncommitted changes
# Automatically handles .gitignore conflicts
```

## Additional Information

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Project Structure

```
ansible-control/
├── playbooks/             # Ansible playbooks (orchestration)
│   ├── common.yml         # Base system configuration
│   ├── docker.yml         # Docker installation (default)
│   └── proxy.yml          # Proxy server setup
├── roles/                 # Ansible roles (reusable components)
│   ├── common/            # Base system configuration
│   ├── docker/            # Docker installation
│   └── nfs/               # NFS configuration
├── Makefile               # Automation commands
├── Vagrantfile            # Single VM configuration
└── Vagrantfile.multi      # Multi-VM configuration
```

### Available Playbooks

#### common.yml
Base system configuration for all hosts

#### docker.yml (Default)
Complete Docker development environment

#### proxy.yml
Proxy server base configuration

**Role Composition:**
- `common.yml` → [common]
- `docker.yml` → [common, docker]
- `proxy.yml` → [common, docker, nfs (optional)]

### Important Notes

#### Repository Management
- Always keep all three repos on the same branch
- Inventory files are gitignored (environment-specific)
- Config changes affect all environments

#### Vagrant Notes
- Default Vagrant user password: `password`
- VM uses rsync for synced folders
- SSH agent forwarding enabled

#### Make Commands
- `make provision` automatically detects single or multi VM setup
- `make clean` safely destroys all VMs sequentially
- `make promote` requires clean working directory
- `make publish` confirms branch before committing

#### Performance
- SSH pipelining enabled for faster playbook execution
- Ansible shows diff output (`--diff`) to see changes


---

## About

**Ahab Software, LLC**  
Automated Host Administration & Build

Website: [ahabsoftware.com](https://ahabsoftware.com)  
GitHub: [github.com/waltdundore](https://github.com/waltdundore)

© 2024 Ahab Software, LLC. All rights reserved.
