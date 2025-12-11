# Network Switch Credential Management

**Date**: December 9, 2025  
**Status**: Active  
**Audience**: Network Administrators, Developers  

---

## Purpose

This document describes how to securely store and manage network switch credentials using Ansible Vault, following Zero Trust Development principles and STIG compliance.

---

## Overview

Network switch credentials are stored using Ansible Vault encryption, ensuring:
- **Confidentiality**: Credentials encrypted at rest
- **Integrity**: Tamper-evident storage
- **Availability**: Accessible to authorized automation
- **Auditability**: All access logged
- **Compliance**: Meets DoD STIG requirements

---

## Quick Start

### 1. Set Up Vault Password

```bash
# Create secure vault password file
echo "your-strong-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Or use the setup script
cd ahab
./scripts/setup-ansible-vault.sh
```

### 2. Store Switch Credentials

```bash
# Method 1: Encrypt individual passwords
ansible-vault encrypt_string 'switch_admin_password' \
    --name 'switch_admin_password' \
    --vault-password-file ~/.ansible_vault_pass

# Method 2: Create dedicated switch vault
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

### 3. Use in Inventory

```yaml
# inventory/dev/network-switches.yml
all:
  children:
    network_switches:
      children:
        aruba_switches:
          hosts:
            switch-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              ansible_ssh_pass: "{{ switch_admin_password }}"
```

---

## Storage Methods

### Method 1: Individual Encrypted Strings (Recommended)

**Best for**: Small number of switches with same credentials

```bash
# Encrypt the password
ansible-vault encrypt_string 'MySecurePassword123!' \
    --name 'aruba_admin_password' \
    --vault-password-file ~/.ansible_vault_pass
```

**Output**:
```yaml
aruba_admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653937336464643464396662353330363965663761363938316334643266613064613534
          3438626139316232393037313963653965363832663539640a626438346336643965663836643030
          65373435366363643735316464626566653864643863386365316365643031656438323264383765
          3135373334373964320a373736323835653432643938336662663932643566653264363864643834
          3764
```

**Use in inventory**:
```yaml
# inventory/dev/network-switches.yml
all:
  children:
    network_switches:
      vars:
        # Encrypted password (paste output from encrypt_string)
        aruba_admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653937336464643464396662353330363965663761363938316334643266613064613534
          3438626139316232393037313963653965363832663539640a626438346336643965663836643030
          65373435366363643735316464626566653864643863386365316365643031656438323264383765
          3135373334373964320a373736323835653432643938336662663932643566653264363864643834
          3764
      children:
        aruba_switches:
          hosts:
            switch-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              ansible_ssh_pass: "{{ aruba_admin_password }}"
```

### Method 2: Dedicated Vault File (Recommended for Multiple Switches)

**Best for**: Many switches with different credentials

```bash
# Create dedicated vault file
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

**Content of vault.yml**:
```yaml
# Network Switch Credentials
# Encrypted with Ansible Vault

# Aruba switches
aruba_admin_password: "MySecurePassword123!"
aruba_enable_password: "MyEnablePassword456!"

# Ruckus switches  
ruckus_admin_password: "RuckusPassword789!"
ruckus_enable_password: "RuckusEnable012!"

# Per-switch credentials (if needed)
switch_credentials:
  core-01:
    username: "admin"
    password: "CoreSwitch123!"
  access-01:
    username: "netadmin"
    password: "AccessSwitch456!"
```

**Use in inventory**:
```yaml
# inventory/dev/network-switches.yml
all:
  children:
    network_switches:
      children:
        aruba_switches:
          hosts:
            switch-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              ansible_ssh_pass: "{{ aruba_admin_password }}"
            
        ruckus_switches:
          hosts:
            switch-access-01:
              ansible_host: 192.168.1.20
              ansible_user: admin
              ansible_ssh_pass: "{{ ruckus_admin_password }}"
```

### Method 3: SSH Key Authentication (Most Secure)

**Best for**: Production environments

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/network_switches_key -C "network-switches"
chmod 600 ~/.ssh/network_switches_key

# Copy public key to switches (switch-specific process)
# For Aruba: copy ssh-key command
# For Ruckus: ip ssh pub-key-file command
```

**Use in inventory**:
```yaml
# inventory/prod/network-switches.yml
all:
  children:
    network_switches:
      vars:
        ansible_ssh_private_key_file: ~/.ssh/network_switches_key
      children:
        aruba_switches:
          hosts:
            switch-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              # No password needed with SSH keys
```

---

## Directory Structure

```
ahab/
├── inventory/
│   ├── group_vars/
│   │   ├── all/
│   │   │   └── vault.yml                    # Global encrypted vars
│   │   └── network_switches/
│   │       ├── vars.yml                     # Non-sensitive vars
│   │       └── vault.yml                    # Switch credentials
│   ├── dev/
│   │   └── network-switches.yml             # Dev inventory
│   └── prod/
│       └── network-switches.yml             # Prod inventory
├── scripts/
│   └── setup-ansible-vault.sh              # Vault setup script
└── ~/.ansible_vault_pass                   # Vault password (secure)
```

---

## Security Best Practices

### Vault Password Security

```bash
# ✅ GOOD: Secure vault password file
echo "complex-random-password-123!" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# ✅ GOOD: Use password manager
# Store vault password in 1Password, Bitwarden, etc.

# ❌ BAD: Weak password
echo "password" > ~/.ansible_vault_pass

# ❌ BAD: World-readable file
chmod 644 ~/.ansible_vault_pass
```

### Credential Rotation

```bash
# 1. Generate new password
NEW_PASSWORD="NewSecurePassword789!"

# 2. Update vault
ansible-vault edit inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# 3. Test with new credentials
make network-switches-test ENV=dev

# 4. Update switches with new password (switch-specific)
```

### Environment Separation

```yaml
# ✅ GOOD: Separate credentials per environment
inventory/
├── dev/
│   └── network-switches.yml      # Dev switch IPs and dev credentials
└── prod/
    └── network-switches.yml      # Prod switch IPs and prod credentials

# ❌ BAD: Same credentials everywhere
```

---

## Implementation Examples

### Example 1: Single Environment with Vault File

```bash
# 1. Create vault file
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

**Vault content**:
```yaml
# Switch credentials
switch_admin_password: "SecurePassword123!"
switch_enable_password: "EnablePassword456!"
```

**Inventory**:
```yaml
# inventory/dev/network-switches.yml
all:
  children:
    network_switches:
      children:
        aruba_switches:
          hosts:
            switch-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
              ansible_ssh_pass: "{{ switch_admin_password }}"
```

### Example 2: Multiple Environments with Different Credentials

**Development vault**:
```bash
ansible-vault create inventory/group_vars/network_switches/vault_dev.yml \
    --vault-password-file ~/.ansible_vault_pass
```

**Production vault**:
```bash
ansible-vault create inventory/group_vars/network_switches/vault_prod.yml \
    --vault-password-file ~/.ansible_vault_pass
```

**Playbook with environment-specific vars**:
```yaml
# playbooks/network-switches.yml
- name: Network Switch Management
  hosts: network_switches
  vars_files:
    - "../inventory/group_vars/network_switches/vault_{{ env | default('dev') }}.yml"
```

### Example 3: SSH Key + Vault for Enable Password

```yaml
# inventory/prod/network-switches.yml
all:
  children:
    network_switches:
      vars:
        # SSH key for authentication
        ansible_ssh_private_key_file: ~/.ssh/network_switches_key
        # Vault for enable password
        ansible_become_pass: "{{ switch_enable_password }}"
      children:
        aruba_switches:
          hosts:
            switch-core-01:
              ansible_host: 192.168.1.10
              ansible_user: admin
```

---

## Testing Credentials

### Test Vault Decryption

```bash
# Verify vault can be decrypted
ansible-vault view inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# Should show plaintext credentials
```

### Test Switch Connectivity

```bash
# Test with encrypted credentials
cd ahab
make network-switches-test ENV=dev

# Should connect successfully using vault credentials
```

### Debug Connection Issues

```bash
# Test single switch with verbose output
ansible switch-core-01 \
    -i inventory/dev/network-switches.yml \
    -m ping \
    --vault-password-file ~/.ansible_vault_pass \
    -vvv
```

---

## GUI Integration

The Ahab GUI automatically handles vault credentials:

### Automatic Vault Password

```python
# ahab-gui/commands/executor.py
def execute_network_command(self, action, env='dev'):
    """Execute network switch command with vault support."""
    
    # Check for vault password file
    vault_file = os.path.expanduser('~/.ansible_vault_pass')
    
    cmd = ['make', f'network-switches-{action}', f'ENV={env}']
    
    # Add vault password if file exists
    if os.path.exists(vault_file):
        env_vars = os.environ.copy()
        env_vars['ANSIBLE_VAULT_PASSWORD_FILE'] = vault_file
        
        result = subprocess.run(cmd, 
                              cwd=self.ahab_path,
                              env=env_vars,
                              capture_output=True,
                              text=True)
    else:
        # Prompt for vault password
        result = subprocess.run(cmd + ['--ask-vault-pass'],
                              cwd=self.ahab_path,
                              capture_output=True,
                              text=True)
    
    return result
```

### User Experience

1. **Vault password configured**: Commands run automatically
2. **No vault password**: GUI prompts for password
3. **Wrong vault password**: Clear error message with recovery steps

---

## Troubleshooting

### Common Issues

#### 1. Vault Password Not Found

**Symptoms**: `ERROR! Attempting to decrypt but no vault secrets found`

**Solutions**:
```bash
# Check vault password file exists
ls -la ~/.ansible_vault_pass

# Create if missing
./scripts/setup-ansible-vault.sh

# Test decryption
ansible-vault view inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

#### 2. Wrong Vault Password

**Symptoms**: `ERROR! Decryption failed (no vault secrets were found that could decrypt)`

**Solutions**:
```bash
# Verify password is correct
ansible-vault view inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# If wrong, update password file
echo "correct-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

#### 3. Switch Authentication Failed

**Symptoms**: `Permission denied (publickey,password)`

**Solutions**:
```bash
# Test credentials manually
ssh admin@192.168.1.10

# Check vault contains correct password
ansible-vault view inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# Update password in vault
ansible-vault edit inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

#### 4. Vault File Corrupted

**Symptoms**: `ERROR! input is not vault encrypted data`

**Solutions**:
```bash
# Check file format
head -n1 inventory/group_vars/network_switches/vault.yml
# Should start with: $ANSIBLE_VAULT;1.1;AES256

# If corrupted, restore from backup or recreate
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass
```

---

## Compliance and Auditing

### STIG Compliance

- ✅ **V-235791**: No secrets embedded in images/code
- ✅ **V-235792**: Credentials encrypted at rest
- ✅ **V-235793**: Access logging enabled
- ✅ **V-235794**: Credential rotation supported

### Audit Trail

```bash
# All vault operations are logged
tail -f /var/log/ansible.log | grep vault

# Switch access logged
tail -f /var/log/ansible.log | grep network_switches
```

### Compliance Checks

```bash
# Run security validation
cd ahab
make audit-secrets

# Should pass with vault-encrypted credentials
```

---

## Migration Guide

### From Plaintext to Vault

```bash
# 1. Backup current inventory
cp inventory/dev/network-switches.yml inventory/dev/network-switches.yml.backup

# 2. Create vault file
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# 3. Move passwords to vault
# Edit vault.yml and add: switch_admin_password: "your_password"

# 4. Update inventory to use variables
# Change: ansible_ssh_pass: "plaintext_password"
# To:     ansible_ssh_pass: "{{ switch_admin_password }}"

# 5. Test
make network-switches-test ENV=dev

# 6. Remove backup if successful
rm inventory/dev/network-switches.yml.backup
```

### From SSH Keys to Vault

```bash
# 1. Create vault with passwords
ansible-vault create inventory/group_vars/network_switches/vault.yml \
    --vault-password-file ~/.ansible_vault_pass

# 2. Update inventory
# Remove: ansible_ssh_private_key_file
# Add:    ansible_ssh_pass: "{{ switch_admin_password }}"

# 3. Test connectivity
make network-switches-test ENV=dev
```

---

## Summary

**Secure credential storage for network switches:**

1. **Use Ansible Vault** for all passwords and sensitive data
2. **Separate credentials** by environment (dev/prod)
3. **Prefer SSH keys** for production environments
4. **Rotate credentials** regularly
5. **Test access** after any credential changes
6. **Monitor and audit** all switch access

**Storage locations:**
- **Vault password**: `~/.ansible_vault_pass` (secure file)
- **Switch credentials**: `inventory/group_vars/network_switches/vault.yml` (encrypted)
- **Inventory**: `inventory/{env}/network-switches.yml` (references vault vars)

**This approach ensures Zero Trust compliance while maintaining operational efficiency.**

---

**Last Updated**: December 9, 2025  
**Next Review**: January 9, 2026