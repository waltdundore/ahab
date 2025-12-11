# Workstation Inventory

This directory contains inventory files for local workstation environments.

## Purpose

The workstation inventory is used for:
- Local development and testing
- Vagrant-managed VMs on your local machine
- Testing Ansible playbooks before deploying to dev/prod
- Learning and experimentation

## Quick Start

1. **Copy the example file:**
   ```bash
   cp hosts.yml.example hosts.yml
   ```

2. **Edit with your workstation information:**
   ```bash
   vim hosts.yml
   ```

3. **Test connectivity:**
   ```bash
   cd ../..  # Back to ahab directory
   ansible all -i inventory/workstation/hosts.yml -m ping
   ```

## Typical Use Cases

### Local Vagrant VM

```yaml
workstation_vm:
  ansible_host: 127.0.0.1
  ansible_port: 2222
  ansible_user: vagrant
  ansible_connection: ssh
  ansible_ssh_private_key_file: .vagrant/machines/default/virtualbox/private_key
```

### Local Machine (localhost)

```yaml
localhost:
  ansible_host: 127.0.0.1
  ansible_user: "{{ lookup('env', 'USER') }}"
  ansible_connection: local
```

### Development Workstation

```yaml
my_workstation:
  ansible_host: 192.168.1.XXX
  ansible_user: developer
  ansible_connection: ssh
```

## Security

- ✅ `hosts.yml.example` - Committed to git (sanitized example)
- ❌ `hosts.yml` - NOT committed (may contain local network IPs)
- ⚠️ Workstation inventory is less sensitive than prod, but still protect it

## File Structure

```
workstation/
├── README.md              # This file
├── hosts.yml.example      # Example (committed to git)
└── hosts.yml              # Actual inventory (NOT in git)
```

## Testing Workflow

1. **Develop playbook** using workstation inventory
2. **Test locally** on Vagrant VM or local machine
3. **Verify it works** without errors
4. **Deploy to dev** environment for integration testing
5. **Deploy to prod** after thorough testing

## Related Documentation

- [Testing Guide](../../TESTING.md)
- [Development Rules](../../DEVELOPMENT_RULES.md)
- [Vagrant Setup](../../docs/development/VAGRANT_SETUP.md)
