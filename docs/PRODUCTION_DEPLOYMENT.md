# Production Deployment Guide

**Last Updated**: December 9, 2025  
**Audience**: System Administrators, DevOps Engineers  
**Status**: Active Development  
**Purpose**: Document credential management patterns for non-Vagrant production deployments

---

## Overview

This document explains how to deploy Ahab on real workstations (not Vagrant VMs) in production environments. When running on actual infrastructure, you need secure credential management for Ansible privilege escalation.

**Key Difference from Development**:
- **Development (Vagrant)**: Uses built-in `vagrant` user with passwordless sudo
- **Production (Real Workstation)**: Uses your admin user with configurable sudo access

---

## Understanding Ansible Credential Patterns

### 1. Ansible become_user Configuration

Ansible's privilege escalation system uses the `become` directive to execute tasks with elevated privileges.

**Basic Pattern**:
```yaml
- name: Install system package
  hosts: all
  become: true          # Enable privilege escalation
  become_method: sudo   # Use sudo (default)
  become_user: root     # Become root user (default)
  
  tasks:
    - name: Install Docker
      ansible.builtin.dnf:
        name: docker
        state: present
```

**How it works**:
1. Ansible connects to target host as specified user
2. `become: true` triggers privilege escalation
3. `become_method: sudo` uses sudo command
4. `become_user: root` escalates to root user
5. Task executes with root privileges

### 2. ansible.cfg Privilege Escalation Options

Ansible configuration can be set globally in `ansible.cfg` to avoid repeating in every playbook.

**Configuration Hierarchy** (highest to lowest precedence):
1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory)
3. `~/.ansible.cfg` (user home)
4. `/etc/ansible/ansible.cfg` (system-wide)

**Standard Production Configuration**:
```ini
[defaults]
# Inventory location
inventory = inventory/production

# Connection settings
host_key_checking = False
retry_files_enabled = False
timeout = 30

# Output settings
stdout_callback = yaml
bin_ansible_callbacks = True

[privilege_escalation]
# Enable privilege escalation by default
become = True

# Method to use for privilege escalation
become_method = sudo

# User to become (default: root)
become_user = root

# Ask for privilege escalation password
become_ask_pass = False  # Set to True for interactive password prompt

# Password file for non-interactive (used with Vault)
# become_password_file = .vault_pass
```

**Key Options Explained**:

- `become = True`: Enable privilege escalation for all plays (can be overridden per-play)
- `become_method = sudo`: Use sudo for escalation (alternatives: su, pbrun, pfexec, doas, dzdo, ksu, runas, machinectl)
- `become_user = root`: Target user for escalation (usually root)
- `become_ask_pass = False`: Don't prompt for password (requires passwordless sudo or vault)
- `become_password_file`: Path to file containing become password (encrypted with Ansible Vault)

### 3. Ansible Vault for Credential Storage

Ansible Vault encrypts sensitive data at rest, including passwords, API keys, and certificates.

**Vault Workflow**:
```bash
# 1. Create vault password file
echo "your-strong-vault-password" > .vault_pass
chmod 600 .vault_pass

# 2. Encrypt the become password
ansible-vault encrypt_string 'your-sudo-password' \
  --name 'ansible_become_pass' \
  --vault-password-file .vault_pass \
  > inventory/group_vars/all.yml

# 3. Result in all.yml:
# ansible_become_pass: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   66386439653765386161316235...

# 4. Use in ansible.cfg:
# vault_password_file = .vault_pass
```

**Vault Best Practices**:
- ✅ Store `.vault_pass` outside version control (add to .gitignore)
- ✅ Use strong, randomly generated vault passwords
- ✅ Rotate vault passwords regularly
- ✅ Use different vault passwords for dev/staging/prod
- ✅ Consider using external secret management (HashiCorp Vault, AWS Secrets Manager)
- ❌ Never commit `.vault_pass` to git
- ❌ Never commit unencrypted passwords
- ❌ Never share vault passwords via insecure channels

### 4. Sudo Configuration for Non-Vagrant Users

Production deployments require proper sudo configuration for the admin user.

**Option 1: Passwordless Sudo (Development/Testing)**

Create `/etc/sudoers.d/ahab`:
```bash
# Ahab admin user - passwordless sudo for specific commands
# WARNING: Use only in development/testing environments

ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/dnf, /usr/bin/apt, /usr/bin/apt-get, /usr/bin/systemctl, /usr/bin/firewall-cmd, /usr/bin/ufw, /usr/bin/docker

# Explanation:
# ahab_admin: The admin username
# ALL=(ALL): From any host, as any user
# NOPASSWD: No password required
# Command list: Only these specific commands allowed
```

**Security Considerations**:
- ✅ Limits commands to specific binaries
- ✅ Prevents arbitrary command execution
- ⚠️ Still allows significant system changes
- ❌ Not recommended for production

**Option 2: Password Prompt (Interactive)**

Standard sudo configuration (no special sudoers file needed):
```bash
# User must be in sudo/wheel group
sudo usermod -aG sudo ahab_admin    # Debian/Ubuntu
sudo usermod -aG wheel ahab_admin   # Fedora/RHEL

# In ansible.cfg:
[privilege_escalation]
become_ask_pass = True  # Prompt for password
```

**Security Considerations**:
- ✅ Requires password for each escalation
- ✅ Standard sudo security model
- ⚠️ Requires interactive session
- ⚠️ Not suitable for automation

**Option 3: Ansible Vault (Production)**

Combine encrypted password with sudo configuration:
```bash
# 1. User in sudo/wheel group (standard sudo)
sudo usermod -aG sudo ahab_admin

# 2. Encrypt sudo password with Vault
ansible-vault encrypt_string 'admin-sudo-password' \
  --name 'ansible_become_pass' \
  --vault-password-file .vault_pass \
  > inventory/group_vars/all.yml

# 3. Configure ansible.cfg
[privilege_escalation]
become_ask_pass = False
vault_password_file = .vault_pass
```

**Security Considerations**:
- ✅ Password encrypted at rest
- ✅ No interactive prompts needed
- ✅ Suitable for automation
- ✅ Audit trail via vault access logs
- ⚠️ Requires secure vault password management

---

## Standard Patterns for Production Deployments

### Pattern 1: Single Admin Workstation (Development)

**Use Case**: Developer workstation, testing environment

**Configuration**:
```ini
# ansible.cfg
[defaults]
inventory = inventory/localhost

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = True  # Interactive password
```

```ini
# inventory/localhost
[workstation]
localhost ansible_connection=local ansible_user=admin_user
```

**Pros**:
- ✅ Simple setup
- ✅ Interactive password entry
- ✅ No stored credentials

**Cons**:
- ❌ Requires human interaction
- ❌ Not suitable for automation

---

### Pattern 2: Automated Deployment (CI/CD)

**Use Case**: Continuous deployment, automated provisioning

**Configuration**:
```ini
# ansible.cfg
[defaults]
inventory = inventory/production
vault_password_file = .vault_pass

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = False
```

```ini
# inventory/production
[workstations]
workstation-01 ansible_host=192.168.1.10 ansible_user=deploy_user
workstation-02 ansible_host=192.168.1.11 ansible_user=deploy_user

[workstations:vars]
ansible_python_interpreter=/usr/bin/python3
```

```yaml
# inventory/group_vars/all.yml (encrypted with Vault)
ansible_become_pass: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653765386161316235...
```

**Pros**:
- ✅ Fully automated
- ✅ Credentials encrypted
- ✅ Suitable for CI/CD

**Cons**:
- ⚠️ Requires vault password management
- ⚠️ More complex setup

---

### Pattern 3: SSH Key-Based with Passwordless Sudo (Staging)

**Use Case**: Staging environment, semi-automated deployments

**Configuration**:
```bash
# 1. Set up SSH key authentication
ssh-copy-id -i ~/.ssh/id_rsa.pub deploy_user@workstation

# 2. Configure passwordless sudo for specific commands
# /etc/sudoers.d/ahab on target workstation
deploy_user ALL=(ALL) NOPASSWD: /usr/bin/dnf, /usr/bin/apt, /usr/bin/systemctl, /usr/bin/docker
```

```ini
# ansible.cfg
[defaults]
inventory = inventory/staging
private_key_file = ~/.ssh/id_rsa

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = False  # Passwordless sudo configured
```

**Pros**:
- ✅ No password storage needed
- ✅ SSH key security
- ✅ Suitable for automation

**Cons**:
- ⚠️ Requires SSH key management
- ⚠️ Passwordless sudo security considerations

---

### Pattern 4: Jump Host / Bastion (Production)

**Use Case**: Production environment with bastion host

**Configuration**:
```ini
# ansible.cfg
[defaults]
inventory = inventory/production
vault_password_file = .vault_pass

[ssh_connection]
ssh_args = -o ProxyCommand="ssh -W %h:%p -q bastion_user@bastion.example.com"
pipelining = True
```

```ini
# inventory/production
[workstations]
prod-ws-01 ansible_host=10.0.1.10 ansible_user=admin_user
prod-ws-02 ansible_host=10.0.1.11 ansible_user=admin_user

[workstations:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p bastion_user@bastion.example.com"'
```

**Pros**:
- ✅ Enhanced security (bastion)
- ✅ Centralized access control
- ✅ Audit trail

**Cons**:
- ⚠️ More complex network setup
- ⚠️ Requires bastion host management

---

## Security Best Practices

### Credential Management

**Do's**:
- ✅ Use Ansible Vault for production passwords
- ✅ Rotate credentials regularly (quarterly minimum)
- ✅ Use strong, randomly generated passwords
- ✅ Store vault passwords in secure secret management system
- ✅ Use different credentials for dev/staging/prod
- ✅ Implement least privilege (limit sudo commands)
- ✅ Enable audit logging for sudo commands
- ✅ Use SSH key authentication when possible

**Don'ts**:
- ❌ Never commit passwords to version control
- ❌ Never use same password across environments
- ❌ Never share vault passwords via email/chat
- ❌ Never use weak or default passwords
- ❌ Never grant full sudo access (use command whitelist)
- ❌ Never disable sudo logging
- ❌ Never store passwords in plain text

### Sudo Configuration

**Secure Sudoers Pattern**:
```bash
# /etc/sudoers.d/ahab
# Principle of least privilege - only allow necessary commands

# Package management
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/dnf install *, /usr/bin/dnf remove *, /usr/bin/dnf update *
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/apt install *, /usr/bin/apt remove *, /usr/bin/apt update *

# Service management
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl enable *, /usr/bin/systemctl disable *

# Firewall management
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd *
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/ufw *

# Docker management
ahab_admin ALL=(ALL) NOPASSWD: /usr/bin/docker *

# Explicitly deny dangerous commands
ahab_admin ALL=(ALL) !NOPASSWD: /usr/bin/rm -rf /, /usr/bin/dd, /usr/bin/mkfs.*
```

**Validation**:
```bash
# Always validate sudoers syntax before deploying
sudo visudo -c -f /etc/sudoers.d/ahab

# Test sudo access
sudo -l -U ahab_admin
```

### Network Security

**Firewall Rules**:
```bash
# Only allow SSH from specific networks
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" service name="ssh" accept'
firewall-cmd --reload

# Or using ufw
ufw allow from 10.0.0.0/8 to any port 22
```

**SSH Hardening**:
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers ahab_admin deploy_user
```

---

## Comparison: Development vs Production

| Aspect | Development (Vagrant) | Production (Real Workstation) |
|--------|----------------------|-------------------------------|
| **User** | vagrant (built-in) | Custom admin user |
| **Sudo** | Passwordless (built-in) | Configured per environment |
| **Connection** | ansible_local (inside VM) | SSH or local |
| **Credentials** | None needed | Vault or interactive |
| **Isolation** | Full VM isolation | Host system |
| **Persistence** | Disposable VM | Persistent workstation |
| **Security** | Development-grade | Production-grade |

---

## Migration Path: Vagrant to Production

### Step 1: Understand Current Setup

**Vagrant Development**:
```ruby
# Vagrantfile
config.vm.provision "ansible_local" do |ansible|
  ansible.playbook = "playbooks/provision-workstation.yml"
  # No credentials needed - vagrant user has passwordless sudo
end
```

### Step 2: Create Production Configuration

**Create ansible.cfg**:
```bash
cd ahab
cp config/ansible.cfg.production ansible.cfg
# Edit ansible.cfg for your environment
```

**Create inventory**:
```bash
cp inventory/production.template inventory/production
# Edit inventory/production with your workstation details
```

### Step 3: Configure Credentials

**Option A: Interactive (Testing)**:
```ini
# ansible.cfg
[privilege_escalation]
become_ask_pass = True
```

**Option B: Vault (Production)**:
```bash
# Create vault
echo "strong-vault-password" > .vault_pass
chmod 600 .vault_pass

# Encrypt sudo password
ansible-vault encrypt_string 'sudo-password' \
  --name 'ansible_become_pass' \
  --vault-password-file .vault_pass \
  > inventory/group_vars/all.yml

# Configure ansible.cfg
# vault_password_file = .vault_pass
```

### Step 4: Test Connection

```bash
# Test Ansible can connect
ansible localhost -m ping

# Test privilege escalation
ansible localhost -b -m command -a "whoami"
# Should output: root
```

### Step 5: Run Playbook

```bash
# Run workstation provisioning
ansible-playbook playbooks/provision-workstation.yml

# Or use make command (if configured)
make install
```

---

## Troubleshooting

### Issue: "Become password required"

**Symptoms**:
```
FAILED! => {"msg": "Missing sudo password"}
```

**Solutions**:
1. **Enable password prompt**:
   ```ini
   # ansible.cfg
   [privilege_escalation]
   become_ask_pass = True
   ```

2. **Configure vault**:
   ```bash
   ansible-vault encrypt_string 'your-password' \
     --name 'ansible_become_pass' \
     > inventory/group_vars/all.yml
   ```

3. **Configure passwordless sudo** (development only):
   ```bash
   sudo visudo -f /etc/sudoers.d/ahab
   # Add: username ALL=(ALL) NOPASSWD: ALL
   ```

### Issue: "Permission denied (publickey)"

**Symptoms**:
```
fatal: [workstation]: UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}
```

**Solutions**:
1. **Set up SSH key**:
   ```bash
   ssh-keygen -t ed25519
   ssh-copy-id user@workstation
   ```

2. **Specify key in ansible.cfg**:
   ```ini
   [defaults]
   private_key_file = ~/.ssh/id_ed25519
   ```

3. **Test SSH connection**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 user@workstation
   ```

### Issue: "Vault password required"

**Symptoms**:
```
ERROR! Attempting to decrypt but no vault secrets found
```

**Solutions**:
1. **Create vault password file**:
   ```bash
   echo "vault-password" > .vault_pass
   chmod 600 .vault_pass
   ```

2. **Specify in ansible.cfg**:
   ```ini
   [defaults]
   vault_password_file = .vault_pass
   ```

3. **Or prompt for password**:
   ```bash
   ansible-playbook playbook.yml --ask-vault-pass
   ```

---

## Related Documentation

- [Production Setup Guide](PRODUCTION_SETUP.md) - Step-by-step production deployment
- [Security Model](SECURITY_MODEL.md) - Complete security documentation
- [Privilege Escalation Model](../.kiro/steering/privilege-escalation-model.md) - Technical details
- [Development Rules](DEVELOPMENT_RULES.md) - Development guidelines

---

## Summary

**Key Takeaways**:

1. **Development (Vagrant)**: Uses built-in vagrant user with passwordless sudo - no configuration needed
2. **Production (Real Workstation)**: Requires explicit credential configuration via ansible.cfg and inventory
3. **Three Credential Options**:
   - Interactive password prompt (testing)
   - Passwordless sudo (development)
   - Ansible Vault (production)
4. **Security Priority**: Use Ansible Vault for production, limit sudo commands, rotate credentials regularly
5. **Migration Path**: Create ansible.cfg → Configure inventory → Set up credentials → Test → Deploy

**Next Steps**:
- Review [M0.5.2: Design Credential Interface](../../.kiro/specs/cmu-web-standards-compliance/tasks.md) for implementation details
- Create production configuration templates
- Set up credential management workflow
- Test on staging environment before production

---

**Questions or Issues?** Refer to the troubleshooting section or consult the related documentation.
