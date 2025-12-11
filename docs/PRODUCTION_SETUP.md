# Production Setup Guide

**Last Updated**: December 9, 2025  
**Audience**: System Administrators, DevOps Engineers  
**Status**: Active  
**Purpose**: Step-by-step guide for deploying Ahab on production workstations

---

## Overview

This guide walks you through deploying Ahab on a real workstation (not a Vagrant VM) for production use. You'll learn how to configure credentials, set up security, and deploy services safely.

**Prerequisites**:
- Linux workstation (Fedora 43, Debian 13, or Ubuntu 24.04)
- Admin user with sudo access
- Ahab repository cloned
- Basic understanding of Ansible and sudo

---

## Quick Start (5 Minutes)

For experienced users who want to get started quickly:

```bash
# 1. Navigate to ahab directory
cd ahab

# 2. Run setup script
make setup-production

# 3. Follow prompts to configure credentials

# 4. Verify configuration
make test-production

# 5. Deploy workstation
make install
```

**Done!** Skip to [Deploying Services](#deploying-services) section.

---

## Detailed Setup (Step-by-Step)

### Step 1: Verify Prerequisites

**Check you're on a real workstation** (not Vagrant VM):
```bash
hostname
# Should NOT be "ahab-workstation"

# Check for Vagrant indicator
ls -la /home/vagrant/.vagrant 2>/dev/null
# Should output: No such file or directory
```

**Check admin user exists**:
```bash
id <admin-user>
# Should output: uid=1000(admin-user) gid=1000(admin-user) groups=...
```

**Check admin user has sudo**:
```bash
sudo -l -U <admin-user>
# Should list sudo privileges
```

**Check Ahab is cloned**:
```bash
cd ahab
ls -la Makefile playbooks/ roles/
# Should show Ahab directory structure
```

---

### Step 2: Run Setup Script

The setup script will guide you through credential configuration:

```bash
cd ahab
make setup-production
```

**What the script does**:
1. Verifies you're not in a Vagrant VM
2. Prompts for admin username
3. Validates user exists and has sudo
4. Asks you to choose credential method
5. Generates configuration files
6. Tests the configuration

**Expected output**:
```
========================================
Ahab Production Credential Setup
========================================

✓ Not running in Vagrant VM
✓ Checking admin user...

Enter admin username (must have sudo access): admin_user
✓ User admin_user exists
✓ User admin_user has sudo access

Choose credential method:
  1) Passwordless sudo (recommended for development)
  2) Password prompt (interactive)
  3) Ansible Vault (most secure)
Choice [1-3]: 
```

---

### Step 3: Choose Credential Method

#### Method 1: Passwordless Sudo (Development/Testing)

**Best for**: Development workstations, testing environments

**How it works**:
- Creates `/etc/sudoers.d/ahab` with command whitelist
- Allows specific commands without password
- Limited to: dnf, apt, systemctl, firewall-cmd, docker

**Setup**:
```bash
# Choose option 1 in setup script
Choice [1-3]: 1

# Script will:
# 1. Generate ansible.cfg
# 2. Generate inventory/production
# 3. Create /etc/sudoers.d/ahab (requires your password once)
# 4. Test configuration
```

**Security level**: Moderate (limited command set)

**Pros**:
- ✅ No password prompts
- ✅ Fast for development
- ✅ Easy to use

**Cons**:
- ⚠️ Passwordless access (even if limited)
- ❌ Not recommended for production

---

#### Method 2: Password Prompt (Interactive)

**Best for**: Manual deployments, one-off installations

**How it works**:
- Prompts for sudo password when needed
- No stored credentials
- Requires interactive terminal session

**Setup**:
```bash
# Choose option 2 in setup script
Choice [1-3]: 2

# Script will:
# 1. Generate ansible.cfg with become_ask_pass = True
# 2. Generate inventory/production
# 3. Test configuration (will prompt for password)
```

**Security level**: Good (no stored passwords)

**Pros**:
- ✅ No stored credentials
- ✅ Standard sudo security
- ✅ Simple setup

**Cons**:
- ⚠️ Requires interactive session
- ⚠️ Not suitable for automation
- ⚠️ Must enter password for each deployment

---

#### Method 3: Ansible Vault (Production - Recommended)

**Best for**: Production deployments, CI/CD automation

**How it works**:
- Encrypts sudo password with Ansible Vault
- Stores encrypted password in `inventory/group_vars/all.yml`
- Vault password stored in `.vault_pass` (not committed to git)
- No interactive prompts needed

**Setup**:
```bash
# Choose option 3 in setup script
Choice [1-3]: 3

# Script will prompt:
Enter vault password: ********
Enter sudo password for admin user: ********

# Script will:
# 1. Generate ansible.cfg with vault configuration
# 2. Generate inventory/production
# 3. Create .vault_pass file
# 4. Encrypt sudo password with Vault
# 5. Store in inventory/group_vars/all.yml
# 6. Test configuration
```

**Security level**: Excellent (encrypted at rest)

**Pros**:
- ✅ Credentials encrypted
- ✅ No interactive prompts
- ✅ Suitable for automation
- ✅ Audit trail possible

**Cons**:
- ⚠️ Requires vault password management
- ⚠️ More complex setup

**Important**: Keep `.vault_pass` secure and never commit to git!

---

### Step 4: Verify Configuration

After setup completes, verify everything works:

```bash
make test-production
```

**Expected output**:
```
========================================
Testing Production Configuration
========================================

✓ ansible.cfg exists
✓ ansible.cfg is valid
✓ inventory/production exists
✓ Ansible can connect to localhost
✓ Ansible can escalate privileges
✓ Sudo configuration valid
✓ Vault configuration (if applicable)

========================================
All production credential tests passed
========================================
```

**If tests fail**, see [Troubleshooting](#troubleshooting) section.

---

### Step 5: Deploy Workstation

Now you can deploy Ahab on your workstation:

```bash
make install
```

**What this does**:
- Installs Docker and Docker Compose
- Installs Ansible automation tools
- Configures firewall (SELinux/AppArmor)
- Sets up security hardening
- Prepares system for service deployment

**Expected output**:
```
========================================
Installing Ahab Workstation
========================================

PLAY [Provision Ahab Workstation] ******

TASK [Install Docker] ******************
changed: [localhost]

TASK [Start Docker service] ************
changed: [localhost]

TASK [Configure firewall] **************
changed: [localhost]

PLAY RECAP *****************************
localhost: ok=15 changed=12 unreachable=0 failed=0
```

**Duration**: 5-10 minutes (depending on internet speed)

---

## Deploying Services

After workstation is installed, deploy services:

### Deploy Apache Web Server

```bash
make install apache
```

**What this does**:
- Installs Apache HTTP Server
- Configures virtual hosts
- Opens firewall ports
- Starts Apache service

**Verify**:
```bash
# Check Apache is running
systemctl status httpd  # Fedora
systemctl status apache2  # Debian/Ubuntu

# Test web server
curl http://localhost
```

### Deploy MySQL Database

```bash
make install mysql
```

### Deploy PHP

```bash
make install php
```

### Deploy Multiple Services

```bash
make install apache mysql php
```

---

## File Structure

After setup, your ahab directory will contain:

```
ahab/
├── ansible.cfg                    # Generated by setup script
├── .vault_pass                    # Vault password (if using Vault)
├── inventory/
│   ├── production                 # Generated by setup script
│   └── group_vars/
│       └── all.yml               # Encrypted credentials (if using Vault)
├── config/
│   ├── ansible.cfg.production    # Template (committed to git)
│   └── production-config.yml.template  # Template (committed to git)
└── scripts/
    └── setup-production-credentials.sh  # Setup script
```

**Committed to git**:
- Templates (`.production`, `.template`)
- Setup scripts
- Documentation

**NOT committed to git** (in .gitignore):
- `ansible.cfg` (generated)
- `inventory/production` (generated)
- `.vault_pass` (sensitive)
- `inventory/group_vars/all.yml` (encrypted credentials)

---

## Security Best Practices

### Credential Management

**Do's**:
- ✅ Use Ansible Vault for production
- ✅ Use strong, randomly generated vault passwords
- ✅ Store vault password in secure location (password manager, secret management system)
- ✅ Rotate credentials quarterly (minimum)
- ✅ Use different credentials for dev/staging/prod
- ✅ Enable audit logging for sudo commands
- ✅ Limit sudo commands to minimum needed

**Don'ts**:
- ❌ Never commit `.vault_pass` to git
- ❌ Never commit unencrypted passwords
- ❌ Never share vault passwords via email/chat
- ❌ Never use same password across environments
- ❌ Never grant full sudo access (use command whitelist)
- ❌ Never disable sudo logging

### Vault Password Management

**Generate strong vault password**:
```bash
# Generate 32-character random password
openssl rand -base64 32 > .vault_pass
chmod 600 .vault_pass
```

**Store vault password securely**:
- Use password manager (1Password, LastPass, Bitwarden)
- Use secret management system (HashiCorp Vault, AWS Secrets Manager)
- Use encrypted USB drive for offline storage
- Never store in plain text files
- Never store in version control

**Rotate vault password**:
```bash
# 1. Create new vault password
openssl rand -base64 32 > .vault_pass.new

# 2. Rekey encrypted files
ansible-vault rekey inventory/group_vars/all.yml \
  --vault-password-file .vault_pass \
  --new-vault-password-file .vault_pass.new

# 3. Replace old vault password
mv .vault_pass.new .vault_pass
chmod 600 .vault_pass

# 4. Test configuration
make test-production
```

### Sudo Configuration

**Review sudo access**:
```bash
# Check what commands user can run
sudo -l -U admin_user

# Check sudoers file
sudo cat /etc/sudoers.d/ahab
```

**Limit sudo commands** (if using passwordless):
```bash
# Edit /etc/sudoers.d/ahab
sudo visudo -f /etc/sudoers.d/ahab

# Only allow specific commands:
admin_user ALL=(ALL) NOPASSWD: /usr/bin/dnf install *, /usr/bin/dnf remove *
admin_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *
admin_user ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd *
admin_user ALL=(ALL) NOPASSWD: /usr/bin/docker *

# Explicitly deny dangerous commands:
admin_user ALL=(ALL) !NOPASSWD: /usr/bin/rm -rf /, /usr/bin/dd, /usr/bin/mkfs.*
```

**Enable sudo logging**:
```bash
# Ensure sudo logs are enabled
sudo grep -r "Defaults.*logfile" /etc/sudoers /etc/sudoers.d/

# View sudo logs
sudo tail -f /var/log/sudo.log  # or /var/log/auth.log
```

### Network Security

**Firewall configuration**:
```bash
# Only allow SSH from specific networks
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" service name="ssh" accept'
sudo firewall-cmd --reload

# Or using ufw (Debian/Ubuntu)
sudo ufw allow from 10.0.0.0/8 to any port 22
```

**SSH hardening**:
```bash
# Edit /etc/ssh/sshd_config
sudo vim /etc/ssh/sshd_config

# Recommended settings:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers admin_user

# Restart SSH
sudo systemctl restart sshd
```

---

## Credential Rotation

Regular credential rotation is essential for security.

### Rotate Sudo Password

**Method 1: Interactive (Password Prompt)**:
```bash
# 1. Change user's sudo password
passwd admin_user

# 2. Test new password
sudo -k  # Clear sudo cache
sudo whoami  # Should prompt for new password
```

**Method 2: Vault (Encrypted)**:
```bash
# 1. Change user's sudo password
passwd admin_user

# 2. Update encrypted password in Vault
ansible-vault edit inventory/group_vars/all.yml \
  --vault-password-file .vault_pass

# 3. Update ansible_become_pass with new password
# (Edit the file, save, and exit)

# 4. Test new password
make test-production
```

### Rotate Vault Password

```bash
# 1. Generate new vault password
openssl rand -base64 32 > .vault_pass.new

# 2. Rekey all encrypted files
ansible-vault rekey inventory/group_vars/all.yml \
  --vault-password-file .vault_pass \
  --new-vault-password-file .vault_pass.new

# 3. Replace old vault password
mv .vault_pass.new .vault_pass
chmod 600 .vault_pass

# 4. Test configuration
make test-production

# 5. Update vault password in secure storage
# (Update password manager, secret management system, etc.)
```

### Rotation Schedule

**Recommended schedule**:
- **Sudo passwords**: Quarterly (every 3 months)
- **Vault passwords**: Quarterly (every 3 months)
- **SSH keys**: Annually (every 12 months)
- **After security incident**: Immediately

**Set reminders**:
```bash
# Add to crontab for quarterly reminder
crontab -e

# Add line:
0 9 1 */3 * echo "Time to rotate Ahab credentials" | mail -s "Credential Rotation Reminder" admin@example.com
```

---

## Troubleshooting

### Setup Script Fails

**Error**: "User does not have sudo access"

**Solution**:
```bash
# Grant sudo access to user
sudo usermod -aG sudo admin_user    # Debian/Ubuntu
sudo usermod -aG wheel admin_user   # Fedora/RHEL

# Verify
sudo -l -U admin_user
```

---

**Error**: "Not running in Vagrant VM" check fails incorrectly

**Solution**:
```bash
# Manually verify you're not in Vagrant
hostname  # Should not be "ahab-workstation"
ls /home/vagrant/.vagrant  # Should not exist

# If you're certain you're not in Vagrant, edit the script:
vim scripts/setup-production-credentials.sh
# Comment out the Vagrant check (line ~20)
```

---

### Ansible Connection Fails

**Error**: "Permission denied"

**Solution**:
```bash
# Test Ansible connection manually
ansible localhost -m ping -vvv

# Check ansible.cfg
cat ansible.cfg

# Check inventory
cat inventory/production

# Verify user in inventory matches current user
whoami
grep ansible_user inventory/production
```

---

**Error**: "Could not match supplied host pattern"

**Solution**:
```bash
# Check inventory file exists
ls -la inventory/production

# Check inventory syntax
ansible-inventory --list -i inventory/production

# Verify [workstation] group exists
grep "\[workstation\]" inventory/production
```

---

### Privilege Escalation Fails

**Error**: "Become password required"

**Solution**:
```bash
# Check become configuration
grep become ansible.cfg

# If using password prompt:
# Ensure become_ask_pass = True

# If using vault:
# Check vault password is correct
ansible-vault view inventory/group_vars/all.yml \
  --vault-password-file .vault_pass

# Test sudo access manually
sudo -l
sudo whoami  # Should output: root
```

---

**Error**: "Incorrect sudo password"

**Solution**:
```bash
# Test sudo password manually
sudo -k  # Clear sudo cache
sudo whoami  # Enter password

# If using vault, update encrypted password:
ansible-vault edit inventory/group_vars/all.yml \
  --vault-password-file .vault_pass

# Update ansible_become_pass with correct password
```

---

### Vault Issues

**Error**: "Vault password required"

**Solution**:
```bash
# Check .vault_pass exists
ls -la .vault_pass

# Check ansible.cfg references it
grep vault_password_file ansible.cfg

# Test vault password
ansible-vault view inventory/group_vars/all.yml \
  --vault-password-file .vault_pass
```

---

**Error**: "Decryption failed"

**Solution**:
```bash
# Vault password is incorrect
# Try entering password manually:
ansible-vault view inventory/group_vars/all.yml --ask-vault-pass

# If that works, update .vault_pass:
echo "correct-vault-password" > .vault_pass
chmod 600 .vault_pass
```

---

### Deployment Fails

**Error**: "Package installation failed"

**Solution**:
```bash
# Check internet connectivity
ping -c 3 google.com

# Check package manager works
sudo dnf check-update  # Fedora
sudo apt update        # Debian/Ubuntu

# Check firewall isn't blocking
sudo firewall-cmd --list-all  # Fedora
sudo ufw status              # Debian/Ubuntu

# Try manual installation
sudo dnf install docker  # Fedora
sudo apt install docker.io  # Debian/Ubuntu
```

---

**Error**: "Service failed to start"

**Solution**:
```bash
# Check service status
sudo systemctl status docker

# Check service logs
sudo journalctl -u docker -n 50

# Try starting manually
sudo systemctl start docker

# Check for port conflicts
sudo ss -tulpn | grep :80  # Check if port 80 is in use
```

---

## Advanced Configuration

### Multiple Workstations

Deploy to multiple workstations:

**Create inventory**:
```ini
# inventory/production
[workstations]
workstation-01 ansible_host=192.168.1.10 ansible_user=admin_user
workstation-02 ansible_host=192.168.1.11 ansible_user=admin_user
workstation-03 ansible_host=192.168.1.12 ansible_user=admin_user

[workstations:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Deploy to all**:
```bash
ansible-playbook playbooks/provision-workstation.yml
```

**Deploy to specific workstation**:
```bash
ansible-playbook playbooks/provision-workstation.yml --limit workstation-01
```

---

### Remote Workstations (SSH)

Deploy to remote workstations via SSH:

**Set up SSH keys**:
```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/ahab_deploy

# Copy to remote workstation
ssh-copy-id -i ~/.ssh/ahab_deploy.pub admin_user@workstation.example.com
```

**Configure ansible.cfg**:
```ini
[defaults]
inventory = inventory/production
private_key_file = ~/.ssh/ahab_deploy

[ssh_connection]
pipelining = True
```

**Update inventory**:
```ini
[workstations]
workstation ansible_host=workstation.example.com ansible_user=admin_user
```

**Deploy**:
```bash
ansible-playbook playbooks/provision-workstation.yml
```

---

### CI/CD Integration

Integrate with CI/CD pipelines:

**GitHub Actions example**:
```yaml
# .github/workflows/deploy.yml
name: Deploy Ahab

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up vault password
        run: echo "${{ secrets.VAULT_PASSWORD }}" > .vault_pass
      
      - name: Deploy workstation
        run: |
          cd ahab
          ansible-playbook playbooks/provision-workstation.yml
      
      - name: Clean up
        run: rm -f .vault_pass
```

**Store secrets**:
- Add `VAULT_PASSWORD` to GitHub Secrets
- Never commit `.vault_pass` to repository

---

## Comparison: Development vs Production

| Feature | Development (Vagrant) | Production (Real Workstation) |
|---------|----------------------|-------------------------------|
| **Setup** | `make install` | `make setup-production` + `make install` |
| **User** | vagrant (built-in) | Custom admin user |
| **Sudo** | Passwordless (built-in) | Configured (passwordless/prompt/vault) |
| **Connection** | ansible_local (inside VM) | local or SSH |
| **Credentials** | None needed | Vault or interactive |
| **Isolation** | Full VM isolation | Host system |
| **Persistence** | Disposable VM | Persistent workstation |
| **Destroy** | `make clean` (safe) | Affects real system |
| **Security** | Development-grade | Production-grade |
| **Use Case** | Learning, testing | Production deployments |

---

## Related Documentation

- [Security Model](SECURITY_MODEL.md) - Complete security documentation
- [Production Deployment Guide](PRODUCTION_DEPLOYMENT.md) - Credential management patterns
- [Privilege Escalation Model](../.kiro/steering/privilege-escalation-model.md) - Technical details
- [Development Rules](DEVELOPMENT_RULES.md) - Development guidelines
- [Testing Guide](TESTING.md) - How to verify security

---

## Summary

**Production deployment in 5 steps**:

1. **Verify prerequisites**: Linux workstation, admin user with sudo, Ahab cloned
2. **Run setup**: `make setup-production`
3. **Choose credentials**: Passwordless (dev), Password prompt (manual), or Vault (production)
4. **Verify**: `make test-production`
5. **Deploy**: `make install`

**Security priorities**:
- ✅ Use Ansible Vault for production
- ✅ Rotate credentials quarterly
- ✅ Limit sudo commands
- ✅ Enable audit logging
- ✅ Keep vault password secure

**Next steps**:
- Deploy services: `make install apache`
- Set up monitoring
- Configure backups
- Document your deployment

---

**Questions or issues?** Refer to the [Troubleshooting](#troubleshooting) section or consult the [Security Model](SECURITY_MODEL.md).

**Ready for production?** Follow this guide step-by-step and you'll have a secure, well-configured Ahab deployment.
