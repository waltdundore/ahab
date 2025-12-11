# Ahab Prerequisites Installation

**Date**: December 10, 2025  
**Status**: Active  
**Audience**: Users, Developers

---

## Purpose

This document describes how to install and verify the prerequisites needed to run Ahab infrastructure management system.

---

## Quick Start

```bash
# Check if prerequisites are installed
make check-prerequisites

# Install missing prerequisites (automated)
make install-prerequisites

# Verify installation
make check-prerequisites
```

---

## Required Tools

Ahab requires these tools to be installed on your host system:

### Core Requirements

- **Git** - Version control system
- **Ansible** - Configuration management
- **Vagrant** - VM management
- **VirtualBox** - Virtualization (or Parallels on macOS)
- **Docker** - Container runtime
- **Make** - Build automation
- **Python 3** - Scripting language

### Why These Tools?

- **Git**: Clone repositories and manage code
- **Ansible**: Provision and configure VMs
- **Vagrant**: Create and manage development VMs
- **VirtualBox**: Provide virtualization for VMs
- **Docker**: Run Python scripts in containers (Zero Trust)
- **Make**: Provide consistent command interface
- **Python 3**: Generate configurations and run utilities

---

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
# Navigate to ahab directory
cd ahab

# Install all prerequisites
make install-prerequisites
```

This will:
1. Detect your operating system
2. Install all required packages
3. Configure services (Docker, etc.)
4. Verify installation
5. Provide next steps

**Supported Operating Systems:**
- Fedora 39-43
- Debian 11-13
- Ubuntu 20.04-24.04
- macOS (with Homebrew)

### Method 2: Manual Installation

#### Fedora/RHEL

```bash
# Update system
sudo dnf update -y

# Install basic tools
sudo dnf install -y git make curl wget python3 python3-pip

# Install Ansible
sudo dnf install -y ansible

# Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install VirtualBox
sudo dnf install -y VirtualBox

# Install Vagrant
wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant-2.4.0-1.x86_64.rpm
sudo dnf install -y vagrant-2.4.0-1.x86_64.rpm

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### Debian/Ubuntu

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic tools
sudo apt install -y git make curl wget python3 python3-pip apt-transport-https ca-certificates gnupg lsb-release

# Install Ansible
sudo apt install -y ansible

# Install Docker
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install VirtualBox
sudo apt install -y virtualbox

# Install Vagrant
wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0-1_amd64.deb
sudo dpkg -i vagrant_2.4.0-1_amd64.deb

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### macOS (with Homebrew)

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install git ansible vagrant docker make python3

# Install VirtualBox
brew install --cask virtualbox

# Start Docker Desktop
open -a Docker
```

---

## Verification

### Check Prerequisites

```bash
# Run comprehensive check
make check-prerequisites
```

This will verify:
- All required tools are installed
- Tools are working correctly
- Docker is running
- User permissions are correct
- VirtualBox kernel modules loaded (Linux)

### Expected Output

```
==========================================
Ahab Prerequisites Check
==========================================

==========================================
REQUIRED TOOLS
==========================================

✓ git: git version 2.39.0
✓ ansible: ansible [core 2.14.0]
✓ vagrant: Vagrant 2.4.0
✓ Docker: Running
✓ make: GNU Make 4.3
✓ python3: Python 3.11.0

==========================================
OPTIONAL TOOLS
==========================================

✓ curl: curl 7.87.0
✓ wget: GNU Wget 1.21.3
✓ VirtualBox: 7.0.6r155176

==========================================
SUMMARY
==========================================

✅ All required prerequisites are installed

Ready to run:
  make install
```

---

## Post-Installation Steps

### 1. Log Out and Back In

After installation, you must log out and back in for group membership changes to take effect (especially Docker group on Linux).

### 2. Start Docker

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS:**
```bash
open -a Docker
```

### 3. Verify Installation

```bash
make check-prerequisites
```

### 4. Test Ahab

```bash
# Create a test workstation
make install

# Run tests
make test
```

---

## Troubleshooting

### Docker Not Running

**Symptoms:**
```
⚠ Docker: Installed but not running
```

**Solutions:**

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS:**
```bash
open -a Docker
# Wait for Docker Desktop to start
```

### User Not in Docker Group

**Symptoms:**
```
⚠ User in docker group: No
```

**Solution:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### VirtualBox Kernel Modules Not Loaded

**Symptoms:**
```
⚠ VirtualBox kernel modules: Not loaded
```

**Solution:**
```bash
sudo modprobe vboxdrv vboxnetflt vboxnetadp
```

### Vagrant Plugin Issues

**Symptoms:**
- Vagrant commands fail
- VM creation errors

**Solution:**
```bash
# Update Vagrant plugins
vagrant plugin update

# Reinstall problematic plugins
vagrant plugin uninstall vagrant-vbguest
vagrant plugin install vagrant-vbguest
```

### Permission Denied Errors

**Symptoms:**
- Cannot create VMs
- Docker commands fail

**Solutions:**
1. Ensure user is in correct groups (docker, vboxusers)
2. Log out and back in
3. Check file permissions on ~/.vagrant.d

---

## Security Considerations

### Zero Trust Principles

The prerequisite installation follows Zero Trust principles:

1. **Never Trust**: Each tool installation is verified independently
2. **Always Verify**: Every installation step is checked for success
3. **Assume Breach**: Docker daemon configured with security hardening

### Security Hardening

The installation automatically applies security hardening:

**Docker Configuration:**
- Logging limits to prevent disk exhaustion
- Live restore enabled for container persistence
- Userland proxy disabled for better performance
- No new privileges flag set

**VirtualBox Configuration:**
- Kernel modules properly loaded and verified
- User permissions restricted to necessary access only

---

## Integration with Ahab Workflow

### Before First Use

```bash
# 1. Check prerequisites
make check-prerequisites

# 2. Install if needed
make install-prerequisites

# 3. Verify installation
make check-prerequisites

# 4. Create workstation
make install

# 5. Test system
make test
```

### Regular Maintenance

```bash
# Check prerequisites before major operations
make check-prerequisites

# Update tools as needed
make install-prerequisites  # Re-run to update
```

---

## Related Documentation

- [Ahab Installation Guide](../README.md) - Main installation instructions
- [Workstation Setup](WORKSTATION.md) - VM creation and management
- [Testing Guide](TESTING.md) - How to test your installation
- [Troubleshooting](../TROUBLESHOOTING.md) - Common issues and solutions

---

## Summary

The prerequisite installation system provides:

1. **Automated detection** of your operating system
2. **One-command installation** of all required tools
3. **Comprehensive verification** of installation success
4. **Security hardening** following Zero Trust principles
5. **Clear troubleshooting** guidance for common issues

**Next Steps:**
1. Run `make check-prerequisites` to verify your system
2. Run `make install-prerequisites` if tools are missing
3. Follow post-installation steps (log out/in, start Docker)
4. Proceed with `make install` to create your first workstation

---

**Last Updated**: December 10, 2025  
**Status**: Active  
**Exceptions**: None