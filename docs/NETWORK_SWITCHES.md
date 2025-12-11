# Network Switch Management

**Date**: December 9, 2025  
**Status**: Active  
**Audience**: Users, Developers  

---

## Purpose

This document describes the network switch management feature in Ahab, which provides automated management of HP Aruba and Ruckus network switches through Ansible playbooks and the Ahab GUI.

---

## Overview

The network switch management feature allows you to:

- **Show version information** from HP Aruba and Ruckus switches
- **Test connectivity** to network switches
- **Manage switches** through a web interface
- **Automate switch operations** using Ansible playbooks

### Supported Switch Types

- **HP Aruba switches**: 2930F, 2540, 3810M series
- **Ruckus switches**: ICX 7450, 7150 series  
- **Generic switches**: Any SSH-enabled network switch

---

## Quick Start

### 1. Set Up Inventory

```bash
# Copy the example inventory
cp inventory/dev/network-switches.yml.example inventory/dev/network-switches.yml

# Edit with your switch information
vim inventory/dev/network-switches.yml
```

### 2. Test Connectivity

```bash
# Test connectivity to switches
make network-switches-test ENV=dev
```

### 3. Show Version Information

```bash
# Get version information from all switches
make network-switches-version ENV=dev
```

### 4. Full Management

```bash
# Run complete switch management
make network-switches ENV=dev
```

---

## Make Commands

### Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `make network-switches ENV=dev` | Full switch management | Shows version and tests connectivity |
| `make network-switches-version ENV=dev` | Version information only | Gets switch version and uptime |
| `make network-switches-test ENV=dev` | Connectivity test only | Tests SSH connectivity |

### Command Examples

```bash
# Development environment
make network-switches ENV=dev
make network-switches-version ENV=dev
make network-switches-test ENV=dev

# Production environment  
make network-switches ENV=prod
make network-switches-version ENV=prod
make network-switches-test ENV=prod
```

---

## Inventory Configuration

### Directory Structure

```
ahab/inventory/
├── dev/
│   ├── network-switches.yml.example    # Template (committed)
│   └── network-switches.yml            # Your config (not committed)
└── prod/
    ├── network-switches.yml.example    # Template (committed)
    └── network-switches.yml            # Your config (not committed)
```

### Example Configuration

```yaml
all:
  children:
    network_switches:
      children:
        aruba_switches:
          hosts:
            aruba-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              ansible_connection: network_cli
              ansible_network_os: arubaoss
              switch_type: aruba
              switch_model: "2930F-48G"
              location: "Main Building - Core"
        
        ruckus_switches:
          hosts:
            ruckus-access-01:
              ansible_host: 192.168.1.20
              ansible_user: admin
              ansible_connection: network_cli
              ansible_network_os: icx
              switch_type: ruckus
              switch_model: "ICX7150-24P"
              location: "Building A - IDF 1"
```

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ansible_host` | IP address of switch | `192.168.1.10` |
| `ansible_user` | Username with privileges | `admin` |
| `ansible_connection` | Connection type | `network_cli` or `ssh` |
| `switch_type` | Switch brand | `aruba`, `ruckus`, or `generic` |

### Optional Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `switch_model` | Model number | `2930F-48G` |
| `location` | Physical location | `Building A - Floor 1` |
| `ansible_network_os` | Network OS type | `arubaoss`, `icx` |

---

## Authentication

### SSH Key Authentication (Recommended)

```yaml
# In inventory file
vars:
  ansible_ssh_private_key_file: ~/.ssh/network_switches_key
```

### Password Authentication (Use Ansible Vault)

```bash
# Encrypt password
ansible-vault encrypt_string 'your_password' --name 'ansible_ssh_pass'

# Add to inventory
ansible_ssh_pass: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  [encrypted password here]
```

---

## GUI Integration

### Accessing the Network Interface

1. Start the Ahab GUI: `make ui`
2. Navigate to **Network** in the main menu
3. Click **Manage Switches**
4. Select environment (Development/Production)
5. Choose action:
   - **Show Version**: Get version information
   - **Test Connectivity**: Test SSH connectivity  
   - **Full Management**: Run all management tasks

### GUI Features

- **Environment selection**: Switch between dev/prod
- **Real-time output**: See command execution in real-time
- **Error handling**: Clear error messages and recovery steps
- **Security**: All commands are whitelisted and validated

---

## Security

### Network Security

- **SSH-only access**: No telnet or insecure protocols
- **Key-based authentication**: SSH keys recommended over passwords
- **Encrypted credentials**: Passwords stored in Ansible Vault
- **Network segmentation**: Switches isolated on management network

### Access Control

- **Whitelisted commands**: Only approved make targets can be executed
- **Environment isolation**: Separate dev/prod inventories
- **Audit logging**: All switch operations are logged
- **CSRF protection**: GUI protected against cross-site attacks

### Credential Protection

- **No hardcoded passwords**: All credentials in environment or vault
- **Gitignore protection**: Inventory files excluded from git
- **Vault encryption**: Sensitive data encrypted at rest
- **Minimal privileges**: Switch users have only required permissions

---

## Troubleshooting

### Common Issues

#### 1. Connection Timeout

**Symptoms**: `ansible.builtin.raw` tasks timeout

**Solutions**:
```bash
# Check network connectivity
ping 192.168.1.10

# Verify SSH access
ssh admin@192.168.1.10

# Check inventory configuration
make inventory-validate ENV=dev
```

#### 2. Authentication Failed

**Symptoms**: Permission denied errors

**Solutions**:
```bash
# Verify credentials
ssh admin@192.168.1.10

# Check SSH key permissions
chmod 600 ~/.ssh/network_switches_key

# Test with password (temporarily)
ansible network_switches -i inventory/dev/network-switches.yml -m ping --ask-pass
```

#### 3. Inventory Not Found

**Symptoms**: `inventory/dev/network-switches.yml not found`

**Solutions**:
```bash
# Copy example file
cp inventory/dev/network-switches.yml.example inventory/dev/network-switches.yml

# Edit with your switch IPs
vim inventory/dev/network-switches.yml
```

#### 4. Command Not Recognized

**Symptoms**: Switch doesn't recognize `show version`

**Solutions**:
- Verify switch type in inventory (`switch_type: aruba/ruckus/generic`)
- Check if switch uses different commands
- Try generic connection type: `ansible_connection: ssh`

### Debug Mode

```bash
# Run with verbose output
ansible-playbook playbooks/network-switches.yml -i inventory/dev/network-switches.yml -vvv

# Test single switch
ansible aruba-core-01 -i inventory/dev/network-switches.yml -m ping

# Check inventory parsing
ansible-inventory -i inventory/dev/network-switches.yml --list
```

---

## Architecture

### File Structure

```
ahab/
├── playbooks/
│   └── network-switches.yml           # Main playbook
├── inventory/
│   ├── dev/
│   │   ├── network-switches.yml.example
│   │   └── network-switches.yml       # Your dev switches
│   └── prod/
│       ├── network-switches.yml.example  
│       └── network-switches.yml       # Your prod switches
├── Makefile                           # Make targets
└── docs/
    └── NETWORK_SWITCHES.md           # This document
```

### Playbook Design

The `network-switches.yml` playbook:

1. **Connects** to switches using SSH/network_cli
2. **Executes** switch-specific commands (`show version`, `show uptime`)
3. **Displays** formatted output with switch information
4. **Handles** different switch types (Aruba, Ruckus, Generic)
5. **Reports** summary of operations

### Make Target Design

Following the transparency principle, each make target:

1. **Shows** the actual command being executed
2. **Explains** the purpose of the operation
3. **Validates** required parameters (ENV)
4. **Checks** for inventory file existence
5. **Executes** the Ansible playbook with proper parameters

---

## Integration

### With Ahab Core

- **Make commands**: Integrated into main Makefile
- **Help system**: Listed in `make help` output
- **Testing**: Included in test suite validation
- **Documentation**: Part of main documentation system

### With Ahab GUI

- **Navigation**: Network section in main menu
- **API endpoints**: RESTful API for switch operations
- **Real-time feedback**: Live command output display
- **Error handling**: User-friendly error messages

### With Security Framework

- **Zero Trust**: Never trust switch responses, always validate
- **CIA Triad**: Confidentiality (encrypted creds), Integrity (command validation), Availability (timeout protection)
- **STIG Compliance**: Follows DoD security guidelines
- **Audit Trail**: All operations logged for accountability

---

## Future Enhancements

### Planned Features

- **Configuration backup**: Automated switch config backups
- **Firmware updates**: Automated firmware deployment
- **VLAN management**: VLAN creation and management
- **Port configuration**: Automated port configuration
- **Monitoring integration**: Integration with monitoring systems

### Extensibility

- **Additional vendors**: Support for Cisco, Juniper switches
- **Custom commands**: User-defined command execution
- **Scheduled operations**: Cron-based automation
- **Reporting**: Automated switch inventory reports

---

## Related Documentation

- [Ahab GUI Integration](../docs/AHAB_GUI_INTEGRATION.md) - GUI development guide
- [Security Framework](SECURITY_CIA_TRIAD.md) - Security implementation
- [Inventory Management](../inventory/README.md) - Inventory configuration
- [Make Commands](../README.md) - Core make command documentation

---

## Examples

### Basic Usage

```bash
# Set up development environment
cp inventory/dev/network-switches.yml.example inventory/dev/network-switches.yml
vim inventory/dev/network-switches.yml  # Add your switch IPs

# Test connectivity
make network-switches-test ENV=dev

# Get version information
make network-switches-version ENV=dev

# Full management
make network-switches ENV=dev
```

### Production Deployment

```bash
# Set up production environment
cp inventory/prod/network-switches.yml.example inventory/prod/network-switches.yml
vim inventory/prod/network-switches.yml  # Add production switch IPs

# Use Ansible Vault for production passwords
ansible-vault encrypt_string 'prod_password' --name 'ansible_ssh_pass'

# Test production connectivity (carefully)
make network-switches-test ENV=prod

# Production version check
make network-switches-version ENV=prod
```

### GUI Usage

1. **Start GUI**: `make ui`
2. **Navigate**: Go to Network → Switches
3. **Select Environment**: Choose Development or Production
4. **Execute**: Click "Show Versions", "Test Connectivity", or "Manage All"
5. **Monitor**: Watch real-time output in the command output section

---

## Summary

The network switch management feature provides:

- **Automated switch operations** through Ansible playbooks
- **Web-based management** through the Ahab GUI
- **Security-first design** with encrypted credentials and audit logging
- **Multi-vendor support** for HP Aruba and Ruckus switches
- **Educational transparency** showing actual commands executed

This feature enables network administrators to efficiently manage switch infrastructure while maintaining security and operational visibility.

---

**Last Updated**: December 9, 2025  
**Next Review**: January 9, 2026