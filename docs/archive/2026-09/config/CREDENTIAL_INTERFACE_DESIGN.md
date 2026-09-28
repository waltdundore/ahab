# Credential Interface Design

**Date**: December 9, 2025  
**Status**: Design Complete  
**Task**: M0.5.2 - Design Credential Interface

---

## Overview

This document describes the credential interface design for Ahab production deployments. The design prioritizes:

1. **DRY Principle**: Single source of truth for all configuration
2. **GUI-Editable**: Simple format that GUI can read and write
3. **Error Recovery**: Easy to fix mistakes and reconfigure
4. **Security**: Multiple methods for different security requirements
5. **Validation**: Built-in validation rules prevent misconfigurations

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐              ┌──────────────────┐        │
│  │   CLI Interface  │              │   GUI Interface  │        │
│  │                  │              │                  │        │
│  │  make setup-     │              │  Settings →      │        │
│  │  production      │              │  Production      │        │
│  │                  │              │  Configuration   │        │
│  └────────┬─────────┘              └────────┬─────────┘        │
│           │                                 │                  │
└───────────┼─────────────────────────────────┼──────────────────┘
            │                                 │
            ↓                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Single Source of Truth                        │
│                                                                 │
│              config/production-config.yml                       │
│                                                                 │
│  deployment:                                                    │
│    type: local                                                  │
│    admin_user: "myuser"                                         │
│  credentials:                                                   │
│    method: passwordless                                         │
│                                                                 │
└───────────┬─────────────────────────────────────────────────────┘
            │
            │ (Template Engine)
            │
            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Generated Files                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  ansible.cfg     │  │  inventory/      │  │  /etc/       │ │
│  │                  │  │  production      │  │  sudoers.d/  │ │
│  │  [defaults]      │  │                  │  │  ahab        │ │
│  │  inventory=...   │  │  [workstation]   │  │              │ │
│  │  [privilege_     │  │  localhost       │  │  user ALL=   │ │
│  │  escalation]     │  │                  │  │  NOPASSWD:   │ │
│  │  become=True     │  │  [vars]          │  │  /usr/bin/   │ │
│  │                  │  │  ansible_user=   │  │  dnf,...     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure

### Template Files (Committed to Git)

```
ahab/config/
├── ansible.cfg.production          # Ansible config template
├── production-config.yml.template  # Configuration template
├── sudoers.d.ahab.template        # Sudoers template
└── README.md                       # Documentation

ahab/inventory/
└── production.template             # Inventory template
```

### Generated Files (NOT Committed to Git)

```
ahab/
├── ansible.cfg                     # Generated from template
├── .vault_pass                     # Vault password (if using vault)
├── config/
│   └── production-config.yml       # User's actual configuration
└── inventory/
    ├── production                  # Generated from template
    └── group_vars/
        └── all.yml                 # Encrypted credentials (if using vault)

/etc/sudoers.d/
└── ahab                           # Generated from template (if passwordless)
```

---

## Configuration File Format

### production-config.yml Structure

```yaml
# Deployment Configuration
deployment:
  type: local              # Options: local, remote
  admin_user: "myuser"     # Linux username with sudo
  remote:                  # Only for type: remote
    hostname: ""           # e.g., workstation.example.com
    ssh_key: ""            # e.g., ~/.ssh/id_rsa

# Credential Method
credentials:
  method: passwordless     # Options: passwordless, prompt, vault
  
  passwordless:            # Config for method: passwordless
    allowed_commands:
      - /usr/bin/dnf
      - /usr/bin/apt
      - /usr/bin/apt-get
      - /usr/bin/systemctl
      - /usr/bin/firewall-cmd
      - /usr/bin/ufw
  
  vault:                   # Config for method: vault
    password_file: .vault_pass
    encrypted_vars: inventory/group_vars/all.yml

# Validation Rules (for GUI)
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

# GUI Display Configuration
gui:
  help:
    admin_user: "Linux user with sudo privileges"
    deployment_type: "Choose 'local' for same machine, 'remote' for SSH"
    credential_method: |
      - passwordless: Fast, convenient (development)
      - prompt: Secure, interactive (manual)
      - vault: Most secure, automated (production)
  
  field_order:
    - deployment.type
    - deployment.admin_user
    - deployment.remote.hostname
    - deployment.remote.ssh_key
    - credentials.method
  
  conditional_fields:
    deployment.remote.hostname:
      show_when: "deployment.type == 'remote'"
    deployment.remote.ssh_key:
      show_when: "deployment.type == 'remote'"
```

---

## GUI Interface Design

### Configuration Form

```
┌─────────────────────────────────────────────────────────────┐
│  Production Configuration                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Deployment Type: ⦿ Local    ○ Remote                      │
│  ℹ️ Choose 'local' for same machine, 'remote' for SSH      │
│                                                             │
│  Admin User: [myuser________________]                      │
│  ℹ️ Linux user with sudo privileges                        │
│                                                             │
│  Credential Method:                                         │
│  ⦿ Passwordless Sudo (Development)                         │
│  ○ Password Prompt (Interactive)                           │
│  ○ Ansible Vault (Production)                              │
│  ℹ️ Passwordless: Fast, convenient                         │
│     Prompt: Secure, interactive                            │
│     Vault: Most secure, automated                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ ⚠️  Configuration Preview                           │  │
│  │                                                      │  │
│  │ This will create:                                   │  │
│  │ • ansible.cfg (Ansible configuration)               │  │
│  │ • inventory/production (Host inventory)             │  │
│  │ • /etc/sudoers.d/ahab (Passwordless sudo)          │  │
│  │                                                      │  │
│  │ Admin user 'myuser' will be able to:                │  │
│  │ • Install packages (dnf, apt)                       │  │
│  │ • Manage services (systemctl)                       │  │
│  │ • Configure firewall (firewall-cmd, ufw)            │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  [Cancel]  [Save and Apply]  [Save and Test]              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Validation Feedback

```
┌─────────────────────────────────────────────────────────────┐
│  Production Configuration                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Admin User: [my-user_______________]                      │
│  ❌ Invalid username: must start with lowercase letter     │
│                                                             │
│  Credential Method:                                         │
│  ○ Passwordless Sudo (Development)                         │
│  ○ Password Prompt (Interactive)                           │
│  ○ Ansible Vault (Production)                              │
│  ❌ Please select a credential method                      │
│                                                             │
│  [Cancel]  [Save and Apply] (disabled)                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Success Confirmation

```
┌─────────────────────────────────────────────────────────────┐
│  ✅ Configuration Applied Successfully                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Your production configuration has been saved and applied.  │
│                                                             │
│  Files created:                                             │
│  ✓ ansible.cfg                                              │
│  ✓ inventory/production                                     │
│  ✓ /etc/sudoers.d/ahab                                      │
│                                                             │
│  Validation tests:                                          │
│  ✓ Ansible connection: OK                                   │
│  ✓ Sudo access: OK                                          │
│  ✓ Configuration valid: OK                                  │
│                                                             │
│  You can now deploy services using:                         │
│  • make install (workstation setup)                         │
│  • make install apache (deploy Apache)                      │
│                                                             │
│  [Edit Configuration]  [Close]                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Error Recovery

```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️  Configuration Error                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Failed to apply configuration:                             │
│                                                             │
│  ❌ User 'myuser' does not have sudo access                │
│                                                             │
│  Suggestions:                                               │
│  1. Grant sudo access:                                      │
│     sudo usermod -aG sudo myuser                            │
│                                                             │
│  2. Use a different user with sudo access                   │
│                                                             │
│  3. Choose "Password Prompt" method instead                 │
│                                                             │
│  Your configuration has been saved but not applied.         │
│  You can fix the issue and try again.                       │
│                                                             │
│  [Edit Configuration]  [Try Again]  [Cancel]               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Workflow Diagrams

### Initial Setup Workflow

```
User opens GUI
    ↓
GUI checks if production-config.yml exists
    ↓
    ├─ No → Show setup wizard
    │         ↓
    │      User fills form
    │         ↓
    │      GUI validates input
    │         ↓
    │      GUI writes production-config.yml
    │         ↓
    │      GUI calls make setup-production
    │         ↓
    │      Templates regenerated
    │         ↓
    │      GUI runs make test-production
    │         ↓
    │      Success → Show confirmation
    │         ↓
    │      Error → Show error + recovery options
    │
    └─ Yes → Show edit form with current values
              ↓
           User can edit and reapply
```

### Edit Configuration Workflow

```
User clicks "Edit Configuration"
    ↓
GUI reads production-config.yml
    ↓
GUI populates form with current values
    ↓
User modifies fields
    ↓
GUI validates in real-time
    ↓
User clicks "Save and Apply"
    ↓
GUI validates all fields
    ↓
    ├─ Invalid → Show errors, keep form populated
    │             ↓
    │          User fixes errors
    │             ↓
    │          (loop back to validation)
    │
    └─ Valid → GUI writes production-config.yml
                ↓
             GUI calls make setup-production
                ↓
             Templates regenerated
                ↓
             GUI runs make test-production
                ↓
                ├─ Success → Show confirmation
                │             ↓
                │          User can continue
                │
                └─ Error → Show error details
                            ↓
                         Show recovery options:
                         • Edit configuration
                         • View logs
                         • Restore previous config
                         • Get help
```

### Error Recovery Workflow

```
Configuration fails
    ↓
GUI shows error message
    ↓
GUI preserves user's input
    ↓
GUI offers recovery options:
    ↓
    ├─ Edit Configuration
    │   ↓
    │  Form reopens with user's values
    │   ↓
    │  User fixes issue
    │   ↓
    │  Try again
    │
    ├─ View Logs
    │   ↓
    │  Show detailed error logs
    │   ↓
    │  User diagnoses issue
    │   ↓
    │  Back to edit
    │
    ├─ Restore Previous Config
    │   ↓
    │  GUI loads backup config
    │   ↓
    │  Apply previous working config
    │   ↓
    │  Success
    │
    └─ Get Help
        ↓
       Show troubleshooting guide
        ↓
       Link to documentation
        ↓
       Back to edit
```

---

## Security Design

### Credential Method Comparison

| Method | Security | Convenience | Use Case | Stored Credentials |
|--------|----------|-------------|----------|-------------------|
| Passwordless | Moderate | High | Development | Sudoers file |
| Prompt | Good | Medium | Manual ops | None |
| Vault | Excellent | High | Production | Encrypted |

### Security Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│  GUI (ahab-gui)                                             │
│  • Runs in container                                        │
│  • No root access                                           │
│  • Can only execute make commands                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓ (make commands)
┌─────────────────────────────────────────────────────────────┐
│  Host System                                                │
│  • Runs make commands as user                               │
│  • No sudo access                                           │
│  • Can create/destroy VMs                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓ (Vagrant)
┌─────────────────────────────────────────────────────────────┐
│  Workstation VM                                             │
│  • Isolated from host                                       │
│  • Admin user has sudo (via chosen method)                  │
│  • Ansible runs here with become                            │
└─────────────────────────────────────────────────────────────┘
```

### Principle of Least Privilege

**Passwordless Sudo**:
- ✅ Limited to specific commands only
- ✅ No full sudo access
- ✅ Commands whitelisted in sudoers file
- ❌ Still allows package installation
- ❌ Still allows service management

**Command Whitelist**:
```
/usr/bin/dnf          # Package management (Fedora)
/usr/bin/apt          # Package management (Debian/Ubuntu)
/usr/bin/apt-get      # Package management (Debian/Ubuntu)
/usr/bin/systemctl    # Service management
/usr/bin/firewall-cmd # Firewall (Fedora)
/usr/bin/ufw          # Firewall (Debian/Ubuntu)
```

**NOT Allowed**:
- Full sudo access (`sudo su`)
- Arbitrary commands
- File system modifications outside package management
- User management
- Network configuration (beyond firewall)

---

## Validation Rules

### Field Validation

```python
# Admin User Validation
def validate_admin_user(username: str) -> bool:
    """
    Valid Linux username:
    - Starts with lowercase letter or underscore
    - Contains only lowercase letters, digits, underscores, hyphens
    - Length: 1-32 characters
    """
    pattern = r'^[a-z_][a-z0-9_-]{0,31}$'
    return re.match(pattern, username) is not None

# Deployment Type Validation
def validate_deployment_type(type: str) -> bool:
    """Must be 'local' or 'remote'"""
    return type in ['local', 'remote']

# Credential Method Validation
def validate_credential_method(method: str) -> bool:
    """Must be 'passwordless', 'prompt', or 'vault'"""
    return method in ['passwordless', 'prompt', 'vault']

# Remote Hostname Validation (if type=remote)
def validate_hostname(hostname: str) -> bool:
    """
    Valid hostname or IP:
    - Hostname: letters, digits, dots, hyphens
    - IPv4: xxx.xxx.xxx.xxx
    """
    hostname_pattern = r'^[a-zA-Z0-9.-]+$'
    ipv4_pattern = r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
    return (re.match(hostname_pattern, hostname) or 
            re.match(ipv4_pattern, hostname))

# SSH Key Validation (if type=remote)
def validate_ssh_key(path: str) -> bool:
    """
    Valid SSH key path:
    - File exists
    - Readable
    - Correct permissions (600 or 400)
    """
    if not os.path.exists(path):
        return False
    if not os.access(path, os.R_OK):
        return False
    stat_info = os.stat(path)
    mode = stat_info.st_mode & 0o777
    return mode in [0o600, 0o400]
```

### Configuration Validation

```python
def validate_configuration(config: dict) -> List[str]:
    """
    Validate entire configuration.
    Returns list of error messages (empty if valid).
    """
    errors = []
    
    # Required fields
    if 'deployment' not in config:
        errors.append("Missing 'deployment' section")
    if 'credentials' not in config:
        errors.append("Missing 'credentials' section")
    
    # Deployment validation
    if 'deployment' in config:
        deployment = config['deployment']
        
        if 'type' not in deployment:
            errors.append("Missing deployment type")
        elif not validate_deployment_type(deployment['type']):
            errors.append("Invalid deployment type")
        
        if 'admin_user' not in deployment:
            errors.append("Missing admin user")
        elif not validate_admin_user(deployment['admin_user']):
            errors.append("Invalid admin username")
        
        # Remote-specific validation
        if deployment.get('type') == 'remote':
            if not deployment.get('remote', {}).get('hostname'):
                errors.append("Remote hostname required for remote deployment")
            elif not validate_hostname(deployment['remote']['hostname']):
                errors.append("Invalid remote hostname")
            
            if not deployment.get('remote', {}).get('ssh_key'):
                errors.append("SSH key required for remote deployment")
            elif not validate_ssh_key(deployment['remote']['ssh_key']):
                errors.append("Invalid or inaccessible SSH key")
    
    # Credentials validation
    if 'credentials' in config:
        credentials = config['credentials']
        
        if 'method' not in credentials:
            errors.append("Missing credential method")
        elif not validate_credential_method(credentials['method']):
            errors.append("Invalid credential method")
    
    return errors
```

---

## Implementation Checklist

### Files Created ✅

- [x] `config/ansible.cfg.production` - Ansible config template
- [x] `config/production-config.yml.template` - Configuration template
- [x] `config/sudoers.d.ahab.template` - Sudoers template
- [x] `inventory/production.template` - Inventory template
- [x] `config/README.md` - Updated documentation
- [x] `config/CREDENTIAL_INTERFACE_DESIGN.md` - This document

### Design Principles ✅

- [x] DRY: Single source of truth (production-config.yml)
- [x] GUI-Editable: Simple YAML format
- [x] Error Recovery: Easy to fix and reconfigure
- [x] Security: Multiple methods for different needs
- [x] Validation: Built-in validation rules

### GUI Requirements ✅

- [x] Form-based configuration interface
- [x] Real-time validation
- [x] Contextual help text
- [x] Conditional fields (show/hide based on selections)
- [x] Error messages with recovery options
- [x] Configuration preview
- [x] Test integration

### Security Requirements ✅

- [x] Principle of least privilege
- [x] Command whitelisting for passwordless sudo
- [x] Multiple credential methods
- [x] Encrypted storage option (Vault)
- [x] No credentials in GUI code

### Documentation ✅

- [x] Architecture diagrams
- [x] File structure documentation
- [x] Workflow diagrams
- [x] GUI mockups
- [x] Validation rules
- [x] Security considerations
- [x] Troubleshooting guide

---

## Next Steps

### M0.5.3: Create Credential Setup Script

Implement `scripts/setup-production-credentials.sh` that:
1. Reads production-config.yml
2. Validates configuration
3. Generates files from templates
4. Tests configuration
5. Provides feedback

### M0.5.4: Document Production Deployment

Update documentation:
1. `docs/PRODUCTION_DEPLOYMENT.md` - Add credential interface section
2. `docs/SECURITY_MODEL.md` - Add production deployment section
3. Create `docs/PRODUCTION_SETUP.md` - Step-by-step guide

### M0.5.5: Create Production Test Suite

Implement `tests/test-production-credentials.sh` that:
1. Tests ansible.cfg validity
2. Tests inventory validity
3. Tests Ansible connection
4. Tests sudo access
5. Tests configuration consistency

---

## Summary

The credential interface design provides:

✅ **Single Source of Truth**: All configuration in one file  
✅ **GUI-Friendly**: Simple YAML format, easy to read/write  
✅ **Error Recovery**: Easy to fix mistakes and reconfigure  
✅ **Security**: Multiple methods for different security needs  
✅ **Validation**: Built-in rules prevent misconfigurations  
✅ **Documentation**: Comprehensive guides and examples  
✅ **Testability**: Validation tests ensure correctness  

The design is complete and ready for implementation in M0.5.3.
