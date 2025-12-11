# Ahab Security Model

**Last Updated**: December 9, 2025  
**Audience**: All Users  
**Status**: MANDATORY READING

---

## Overview

This document explains **exactly how Ahab executes commands** and **how privilege escalation works**. We believe in complete transparency about security.

---

## The Command Chain (What Really Happens)

When you click a button in the GUI or run a make command, here's the complete chain of execution:

```
YOU
 ↓ click button or run command
ahab-gui (Web Interface)
 ↓ executes only: make <command>
Makefile (Command Interface)
 ↓ calls: vagrant up/provision
Vagrant (VM Manager)
 ↓ creates isolated VM
 ↓ installs Ansible inside VM
Ansible (Configuration Management)
 ↓ uses: become: true (sudo)
 ↓ executes as root INSIDE VM ONLY
System Operations (package install, service config)
```

**Critical Point**: Root access only happens inside the isolated VM, never on your host machine.

---

## How Privilege Escalation Works

### Initial Setup (First Time Only)

When you run `make install`:

1. **Vagrant creates a VM** (Fedora/Debian/Ubuntu)
2. **VM includes a 'vagrant' user** with passwordless sudo (standard for all Vagrant boxes)
3. **Ansible is installed inside the VM** (not on your host)
4. **Ansible is configured to use sudo** for system operations

### Every Command After Setup

When you run `make install apache` or click "Install Apache" in GUI:

1. **GUI executes**: `make install apache` (no sudo, no root)
2. **Makefile executes**: `vagrant provision` (no sudo, no root)
3. **Vagrant runs Ansible inside VM** (as vagrant user)
4. **Ansible uses `become: true`** to escalate to root via sudo
5. **System packages are installed** (as root, inside VM only)

---

## Security Boundaries

### What Each Component CAN Do

**ahab-gui (Web Interface)**
- ✅ Execute whitelisted make commands
- ✅ Read ahab directory (read-only)
- ❌ Cannot sudo
- ❌ Cannot access your host system as root
- ❌ Cannot execute arbitrary commands

**Makefile (Command Interface)**
- ✅ Control Vagrant (create/destroy VMs)
- ✅ Sync files to VM
- ❌ Cannot sudo on your host
- ❌ Cannot access your host system as root

**Vagrant (VM Manager)**
- ✅ Create/destroy isolated VMs
- ✅ Provision VMs with Ansible
- ❌ Cannot sudo on your host
- ❌ Cannot access your host system as root

**Ansible (Inside VM Only)**
- ✅ Install packages inside VM
- ✅ Configure services inside VM
- ✅ Use sudo inside VM (passwordless)
- ❌ Cannot affect your host machine
- ❌ Cannot access your host filesystem (except synced folders)

### What This Means

**Your host machine is protected:**
- No component runs as root on your host
- No component can sudo on your host
- No component can modify your host system files
- All privileged operations happen inside disposable VM

**The VM is isolated:**
- Runs in its own memory space
- Has its own filesystem
- Can be destroyed and recreated anytime
- Cannot access your host system (except synced folders)

---

## Ansible Configuration

### Where Ansible is Configured

**Vagrantfile** (ahab/Vagrantfile):
```ruby
config.vm.provision "ansible_local" do |ansible|
  ansible.provisioning_path = "/home/vagrant/ahab"
  ansible.playbook = "playbooks/provision-workstation.yml"
  ansible.install = true
  ansible.install_mode = "pip3"
end
```

**What this means:**
- `ansible_local`: Ansible runs **inside the VM**, not on your host
- `provisioning_path`: Ansible works in `/home/vagrant/ahab` directory
- `ansible.install = true`: Vagrant installs Ansible inside VM automatically
- No credentials needed: Vagrant user has passwordless sudo by default

### How Ansible Escalates Privileges

**Playbooks** (ahab/playbooks/*.yml):
```yaml
- name: Provision Ahab Workstation
  hosts: all
  become: true  # ← This line enables sudo
  
  tasks:
    - name: Install Docker
      ansible.builtin.dnf:
        name: docker
        state: present
```

**What `become: true` does:**
1. Tells Ansible to use sudo
2. Executes task as root (inside VM)
3. No password required (vagrant user has NOPASSWD sudo)
4. Only affects the VM, not your host

### Why No Password is Required

**Standard Vagrant Configuration:**

All Vagrant boxes (Fedora, Debian, Ubuntu) include this sudoers configuration:
```
vagrant ALL=(ALL) NOPASSWD: ALL
```

**This is safe because:**
- Only exists inside the VM
- VM is isolated from your host
- VM can be destroyed when not needed
- Standard practice for development VMs
- Used by millions of developers worldwide

---

## Complete Transparency: What Gets Installed

### On Your Host Machine

**Nothing runs as root on your host.**

You need these tools (installed by you, not by Ahab):
- Docker (for running ahab-gui)
- Vagrant (for creating VMs)
- A hypervisor (VirtualBox or Parallels)

### Inside the VM (With Root Access)

When you run `make install`, Ansible installs inside the VM:
- Git (version control)
- Docker (container runtime)
- Ansible (configuration management)
- Python 3 (for scripts)
- Make (build automation)

When you run `make install apache`, Ansible installs inside the VM:
- Apache HTTP Server
- Required dependencies
- Firewall rules
- SELinux/AppArmor policies

**All installations happen inside the VM as root.**

---

## How to Verify This Model

### Verify GUI Cannot Sudo

```bash
cd ahab-gui
docker run --rm python:3.11-slim sudo whoami
# Should fail: sudo: command not found
```

### Verify Host User Cannot Sudo (Unless You Already Can)

```bash
cd ahab
make install
# Should NOT prompt for your password
# Should NOT require sudo on host
```

### Verify Ansible Uses Sudo Inside VM

```bash
cd ahab
vagrant ssh -c "sudo -n whoami"
# Should output: root
# -n flag means no password prompt
```

### Verify VM is Isolated

```bash
cd ahab
vagrant ssh -c "ls /home/vagrant"
# Shows VM filesystem (not your host)

vagrant ssh -c "cat /etc/hostname"
# Shows: ahab-workstation (not your host)
```

---

## What If You Don't Trust This Model?

### Option 1: Review the Code

**Everything is open source:**
- Vagrantfile: `ahab/Vagrantfile`
- Ansible playbooks: `ahab/playbooks/*.yml`
- Ansible roles: `ahab/roles/*/tasks/main.yml`
- GUI executor: `ahab-gui/commands/executor.py`
- Makefiles: `ahab/Makefile`, `ahab-gui/Makefile`

**Look for:**
- Any `sudo` commands in Python code (there are none)
- Any `shell=True` in subprocess calls (there are none)
- Any privilege escalation on host (there is none)
- All `become: true` is in playbooks (inside VM only)

### Option 2: Run Without GUI

```bash
cd ahab
make install          # Create VM
make install apache   # Install Apache
make test            # Run tests
```

**No GUI needed.** The GUI just calls these same make commands.

### Option 3: Inspect Before Running

```bash
cd ahab
cat Makefile          # See what make commands do
cat Vagrantfile       # See how VM is created
cat playbooks/*.yml   # See what Ansible does
```

**No hidden behavior.** Everything is in plain text configuration files.

### Option 4: Use Manual Commands

```bash
cd ahab
vagrant up                    # Create VM manually
vagrant ssh                   # SSH into VM
cd /home/vagrant/ahab         # Navigate to synced folder
ansible-playbook playbooks/provision-workstation.yml  # Run Ansible manually
```

**You control every step.**

---

## Frequently Asked Questions

### Q: Why does Ansible need root access?

**A:** To install system packages and configure services. This is standard for any configuration management tool (Ansible, Chef, Puppet, Salt).

**Examples of operations that require root:**
- Installing packages: `dnf install docker`
- Starting services: `systemctl start docker`
- Configuring firewall: `firewall-cmd --add-service=http`
- Setting SELinux policies: `semanage port -a -t http_port_t -p tcp 8080`

### Q: Can I run Ahab without giving it root access?

**A:** No, because system package installation requires root. However:
- Root access is **only inside the VM**
- Your host machine is **never affected**
- You can destroy the VM anytime: `make clean`

### Q: What if the VM is compromised?

**A:** Limited impact:
- VM is isolated from your host
- VM has no access to your host filesystem (except synced folders)
- VM has no network access to your host (except port forwarding)
- Destroy and recreate: `make clean && make install`

### Q: Why use Vagrant instead of Docker?

**A:** Docker containers share the host kernel. For system-level operations (systemd, SELinux, firewall), we need a full VM with its own kernel.

### Q: Can I see what commands Ansible runs?

**A:** Yes:

```bash
cd ahab
vagrant provision --debug
# Shows every command Ansible executes
```

Or review the playbooks:
```bash
cat ahab/playbooks/provision-workstation.yml
cat ahab/roles/apache/tasks/main.yml
```

### Q: Does Ahab send any data externally?

**A:** No. All operations are local:
- VM is created locally
- Packages are downloaded from official repos (Fedora/Debian/Ubuntu)
- No telemetry, no phone-home, no data collection

### Q: Can I use Ahab in production?

**A:** Ahab is designed for **development and education**. For production:
- Use Ansible directly (not via Vagrant)
- Use proper inventory management
- Use vault for secrets
- Follow your organization's security policies

---

## Security Best Practices

### Do's

✅ **Review the code** before running
✅ **Understand what each command does**
✅ **Destroy VMs when not needed**: `make clean`
✅ **Keep Vagrant and VirtualBox updated**
✅ **Use official Vagrant boxes** (bento/fedora, bento/debian)
✅ **Report security issues** to the maintainers

### Don'ts

❌ **Don't run Ahab as root** on your host (not needed, not supported)
❌ **Don't modify sudoers** on your host for Ahab (not needed)
❌ **Don't expose the GUI to the internet** (development only)
❌ **Don't use Ahab for production** without proper security review
❌ **Don't store secrets in playbooks** (use Ansible Vault)

---

## Reporting Security Issues

If you find a security issue:

1. **Do NOT open a public GitHub issue**
2. **Email the maintainers** with details
3. **Include**: Steps to reproduce, impact assessment, suggested fix
4. **We will respond** within 48 hours
5. **We will credit you** in the security advisory (if desired)

---

## Summary

**The security model is simple:**

1. **GUI** → Executes make commands (no root)
2. **Make** → Controls Vagrant (no root)
3. **Vagrant** → Creates isolated VM (no root on host)
4. **Ansible** → Configures VM (root inside VM only)

**Your host machine is never affected by root operations.**

**Everything is transparent, auditable, and under your control.**

---

## Production Deployment

### When to Use Production Mode

Ahab is designed for **development and education** using Vagrant VMs. However, you can deploy on real workstations for production use with proper credential management.

**Use production mode when:**
- Deploying on a real workstation (not Vagrant VM)
- Running in a production environment
- Need to use a specific admin user (not vagrant)
- Automating deployments via CI/CD

### Key Differences: Development vs Production

| Aspect | Development (Vagrant) | Production (Real Workstation) |
|--------|----------------------|-------------------------------|
| **User** | vagrant (built-in) | Custom admin user |
| **Sudo** | Passwordless (built-in) | Configured per environment |
| **Connection** | ansible_local (inside VM) | SSH or local |
| **Credentials** | None needed | Vault or interactive |
| **Isolation** | Full VM isolation | Host system |
| **Security** | Development-grade | Production-grade |

### Setup Process

**1. Run setup script**:
```bash
cd ahab
make setup-production
```

**2. Choose credential method**:
- **Passwordless sudo** (development/testing)
- **Password prompt** (interactive deployments)
- **Ansible Vault** (production - recommended)

**3. Verify configuration**:
```bash
make test-production
```

**4. Deploy as normal**:
```bash
make install
make install apache
```

### Security Considerations

**Passwordless Sudo**:
- ✅ Convenient for development
- ⚠️ Limited to specific commands only
- ❌ Not recommended for production

**Password Prompt**:
- ✅ More secure than passwordless
- ⚠️ Requires interactive session
- ✅ Good for manual deployments

**Ansible Vault** (Recommended for Production):
- ✅ Most secure option
- ✅ No interactive prompts
- ✅ Credentials encrypted at rest
- ⚠️ Requires vault password management

### File Locations

**Configuration files**:
- `ahab/ansible.cfg` - Ansible configuration
- `ahab/inventory/production` - Production inventory
- `ahab/.vault_pass` - Vault password (if using Vault)
- `/etc/sudoers.d/ahab` - Sudo configuration (if passwordless)

**Never commit**:
- `.vault_pass` - Vault password
- `inventory/group_vars/all.yml` - Encrypted credentials

### Credential Rotation

To rotate credentials:
```bash
# 1. Update vault password
ansible-vault rekey inventory/group_vars/all.yml

# 2. Update become password
ansible-vault edit inventory/group_vars/all.yml

# 3. Test new credentials
make test-production
```

### Troubleshooting

**"Permission denied" errors**:
- Verify user has sudo access: `sudo -l -U <user>`
- Check sudoers configuration: `sudo cat /etc/sudoers.d/ahab`
- Test Ansible connection: `ansible localhost -m ping`

**"Become password required" errors**:
- Verify ansible.cfg has correct become_ask_pass setting
- Check vault password is correct
- Verify user's sudo password is correct

**For complete production deployment guide**, see [Production Setup Guide](PRODUCTION_SETUP.md).

---

## Related Documentation

- [Production Setup Guide](PRODUCTION_SETUP.md) - Step-by-step production deployment
- [Production Deployment Guide](PRODUCTION_DEPLOYMENT.md) - Credential management patterns
- [Privilege Escalation Model](../.kiro/steering/privilege-escalation-model.md) - Technical details
- [Development Rules](DEVELOPMENT_RULES.md) - Development guidelines
- [Testing Guide](TESTING.md) - How to verify security

---

**Questions?** Open an issue on GitHub or contact the maintainers.

**Concerns?** Review the code, run the verification commands, or use manual mode.

**We believe in transparency. If something is unclear, let us know.**
