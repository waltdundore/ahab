# Ahab Config

![Ahab Logo](../docs/images/ahab-logo.png)

This directory contains configuration templates and settings for Ahab deployments.

**📖 For complete documentation, see the [main README](../README.md)**

## What's in This Directory

### Configuration Templates (Committed to Git)

- **ansible.cfg.production** - Template for Ansible configuration
- **production-config.yml.template** - Template for production settings
- **sudoers.d.ahab.template** - Template for passwordless sudo configuration
- **inventory/production.template** - Template for production inventory

### Generated Files (NOT Committed to Git)

- **production-config.yml** - Your actual production configuration
- **../ansible.cfg** - Generated Ansible configuration
- **../inventory/production** - Generated production inventory
- **../.vault_pass** - Vault password (if using Ansible Vault)

## Configuration Architecture

### Design Principles

1. **DRY (Don't Repeat Yourself)**: Single source of truth in `production-config.yml`
2. **Template-Based**: All files generated from templates
3. **GUI-Editable**: Simple YAML format that GUI can read and write
4. **Validation**: Built-in validation rules for all fields
5. **Security**: Multiple credential methods for different use cases

### File Relationships

```
production-config.yml (source of truth)
    ↓ (generates)
├── ../ansible.cfg (from ansible.cfg.production template)
├── ../inventory/production (from production.template)
└── /etc/sudoers.d/ahab (from sudoers.d.ahab.template)
```

## Configuration Methods

### Method 1: Passwordless Sudo (Development/Testing)

**Best for**: Development workstations, quick iterations

**Security**: Moderate (limited to specific commands)

**Setup**:
```bash
cd ahab
make setup-production
# Choose option 1: Passwordless sudo
```

**What it creates**:
- `/etc/sudoers.d/ahab` with NOPASSWD for specific commands
- `ansible.cfg` with `become_ask_pass = False`

### Method 2: Password Prompt (Interactive)

**Best for**: Manual deployments, one-off operations

**Security**: Good (no stored credentials)

**Setup**:
```bash
cd ahab
make setup-production
# Choose option 2: Password prompt
```

**What it creates**:
- `ansible.cfg` with `become_ask_pass = True`
- Prompts for password during deployment

### Method 3: Ansible Vault (Production)

**Best for**: Production deployments, automated operations

**Security**: Excellent (encrypted at rest)

**Setup**:
```bash
cd ahab
make setup-production
# Choose option 3: Ansible Vault
```

**What it creates**:
- `.vault_pass` with vault password
- `inventory/group_vars/all.yml` with encrypted credentials
- `ansible.cfg` with vault configuration

## GUI Integration

### Editing Configuration via GUI

The GUI provides a user-friendly interface for editing production configuration:

1. **Navigate**: Settings → Production Configuration
2. **Edit**: Fill in the form fields
3. **Validate**: GUI validates input in real-time
4. **Save**: Click "Save and Apply"
5. **Test**: GUI runs validation tests

### GUI Features

- **Real-time validation**: Checks input as you type
- **Contextual help**: Tooltips explain each field
- **Conditional fields**: Shows/hides fields based on selections
- **Error recovery**: Easy to go back and fix mistakes
- **Test integration**: Validates configuration before applying

### Configuration File Format

The GUI reads and writes `production-config.yml`:

```yaml
deployment:
  type: local  # or remote
  admin_user: "myuser"
  remote:
    hostname: ""
    ssh_key: ""

credentials:
  method: passwordless  # or prompt, vault
  passwordless:
    allowed_commands:
      - /usr/bin/dnf
      - /usr/bin/systemctl
  vault:
    password_file: .vault_pass
    encrypted_vars: inventory/group_vars/all.yml
```

### Editing Workflow

```
User opens GUI
    ↓
GUI reads production-config.yml
    ↓
User edits fields in form
    ↓
GUI validates input
    ↓
User clicks "Save and Apply"
    ↓
GUI writes production-config.yml
    ↓
GUI calls make setup-production
    ↓
Templates regenerated
    ↓
GUI runs make test-production
    ↓
Success or error feedback
```

### Error Recovery

If user misconfigures:

1. **GUI shows error**: Clear message about what's wrong
2. **Form stays populated**: User's input is preserved
3. **Easy to fix**: User can edit and resubmit
4. **Validation before apply**: No broken configs deployed
5. **Rollback option**: Can restore previous working config

## CLI Usage

### Initial Setup

```bash
cd ahab
make setup-production
```

Follow the prompts to configure:
1. Admin username
2. Deployment type (local/remote)
3. Credential method (passwordless/prompt/vault)

### Editing Configuration

```bash
# Edit the configuration file
vim config/production-config.yml

# Validate changes
make validate-production-config

# Apply changes (regenerates templates)
make setup-production

# Test configuration
make test-production
```

### Viewing Current Configuration

```bash
# View production config
cat config/production-config.yml

# View generated ansible.cfg
cat ansible.cfg

# View generated inventory
cat inventory/production
```

## Validation

### Built-in Validation Rules

The configuration includes validation rules for GUI and CLI:

```yaml
validation:
  admin_user:
    required: true
    pattern: "^[a-z_][a-z0-9_-]*$"
    description: "Valid Linux username"
  
  deployment_type:
    required: true
    options: ["local", "remote"]
    description: "Deployment location"
  
  credential_method:
    required: true
    options: ["passwordless", "prompt", "vault"]
    description: "How to handle sudo password"
```

### Testing Configuration

```bash
# Test Ansible connection
make test-production

# Test sudo access
cd ahab
vagrant ssh -c "sudo -n whoami"  # Should output: root

# Test Ansible become
ansible localhost -m ping -b
```

## Security Considerations

### Passwordless Sudo

**Pros**:
- Fast, convenient
- No password prompts
- Good for development

**Cons**:
- Less secure than password prompt
- Limited to specific commands only
- Not recommended for production

**Mitigation**:
- Limited command whitelist
- Only in development environments
- VM is disposable

### Password Prompt

**Pros**:
- More secure than passwordless
- No stored credentials
- User must be present

**Cons**:
- Requires interactive session
- Can't automate
- Slower workflow

**Best for**:
- Manual deployments
- Production environments
- When security > convenience

### Ansible Vault

**Pros**:
- Most secure option
- Encrypted at rest
- Can automate
- Production-ready

**Cons**:
- More complex setup
- Must manage vault password
- Requires vault password file

**Best for**:
- Production deployments
- CI/CD pipelines
- Automated operations

## Troubleshooting

### Configuration Not Applied

**Problem**: Made changes but they don't take effect

**Solution**:
```bash
# Regenerate from templates
cd ahab
make setup-production

# Verify files were updated
ls -la ansible.cfg inventory/production
```

### GUI Can't Save Configuration

**Problem**: GUI shows error when saving

**Solution**:
1. Check file permissions: `ls -la config/production-config.yml`
2. Verify YAML syntax: `make validate-production-config`
3. Check GUI logs for specific error
4. Try CLI: `vim config/production-config.yml`

### Sudo Access Denied

**Problem**: Ansible can't become root

**Solution**:
```bash
# Test sudo access
sudo -l

# Check sudoers file
sudo cat /etc/sudoers.d/ahab

# Verify user in config
grep admin_user config/production-config.yml

# Regenerate sudoers
make setup-production
```

### Vault Password Issues

**Problem**: Vault decryption fails

**Solution**:
```bash
# Check vault password file exists
ls -la .vault_pass

# Test vault decryption
ansible-vault view inventory/group_vars/all.yml

# Regenerate vault
make setup-production
# Choose option 3: Ansible Vault
```

## Links

- **[Main Documentation](../README.md)** - Start here
- **[Production Deployment Guide](../docs/PRODUCTION_DEPLOYMENT.md)** - Complete setup guide
- **[Security Model](../docs/SECURITY_MODEL.md)** - Security architecture
- **[Privilege Escalation Model](../.kiro/steering/privilege-escalation-model.md)** - How sudo works
