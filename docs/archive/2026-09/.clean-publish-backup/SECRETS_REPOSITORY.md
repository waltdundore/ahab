# Secrets Repository Management

**Date**: December 9, 2025  
**Status**: Active  
**Audience**: Developers, System Administrators  

---

## Purpose

This document describes the secure management of sensitive configuration data using the private `ahab-secrets` repository, following Zero Trust Development principles and STIG compliance.

---

## Overview

The `ahab-secrets` repository provides secure storage for:
- **Network switch credentials** (encrypted with Ansible Vault)
- **Production environment configurations**
- **SSH keys and certificates**
- **API keys and tokens**
- **Database credentials**
- **TLS/SSL certificates**

### Repository Information

- **Repository**: https://github.com/waltdundore/ahab-secrets
- **Visibility**: Private (restricted access)
- **Purpose**: Secure credential storage
- **Encryption**: Ansible Vault + Git-crypt
- **Access**: Need-to-know basis only

---

## Security Model

### Zero Trust Implementation

**Never Trust**:
- Repository contents are encrypted at rest
- No plaintext secrets in git history
- Access requires multiple authentication factors

**Always Verify**:
- All access logged and audited
- Credentials rotated regularly
- Access permissions reviewed quarterly

**Assume Breach**:
- Secrets compartmentalized by environment
- Blast radius limited through segmentation
- Incident response procedures documented

### CIA Triad Compliance

**Confidentiality**:
- Ansible Vault encryption (AES-256)
- Git-crypt for additional file-level encryption
- Private repository with restricted access
- No secrets in commit messages or metadata

**Integrity**:
- Git commit signing required
- Checksums for all secret files
- Tamper detection through git history
- Backup verification procedures

**Availability**:
- Multiple authorized personnel have access
- Backup procedures documented
- Recovery procedures tested
- Offline backup storage

---

## Repository Structure

```
ahab-secrets/
├── README.md                           # Repository overview
├── .gitattributes                      # Git-crypt configuration
├── .gitignore                          # Ignore patterns
├── scripts/
│   ├── setup-secrets.sh                # Initial setup script
│   ├── rotate-credentials.sh           # Credential rotation
│   ├── backup-secrets.sh               # Backup procedures
│   └── validate-secrets.sh             # Validation checks
├── ansible/
│   ├── vault-password.txt              # Vault password (git-crypt encrypted)
│   └── group_vars/
│       ├── all/
│       │   └── vault.yml               # Global secrets (Ansible Vault)
│       ├── network_switches/
│       │   ├── vault_dev.yml           # Dev switch credentials
│       │   └── vault_prod.yml          # Prod switch credentials
│       ├── databases/
│       │   ├── vault_dev.yml           # Dev database credentials
│       │   └── vault_prod.yml          # Prod database credentials
│       └── services/
│           ├── vault_dev.yml           # Dev service credentials
│           └── vault_prod.yml          # Prod service credentials
├── ssh-keys/
│   ├── network-switches/
│   │   ├── dev_rsa                     # Dev environment SSH key
│   │   ├── dev_rsa.pub
│   │   ├── prod_rsa                    # Prod environment SSH key
│   │   └── prod_rsa.pub
│   └── servers/
│       ├── ansible_rsa                 # Ansible automation key
│       └── ansible_rsa.pub
├── certificates/
│   ├── dev/
│   │   ├── server.crt                  # Dev TLS certificates
│   │   └── server.key
│   └── prod/
│       ├── server.crt                  # Prod TLS certificates
│       └── server.key
├── api-keys/
│   ├── vault_dev.yml                   # Dev API keys (Ansible Vault)
│   └── vault_prod.yml                  # Prod API keys (Ansible Vault)
└── examples/
    ├── network-switches-vault.yml      # Example switch credentials
    ├── database-vault.yml              # Example database credentials
    └── api-keys-vault.yml              # Example API keys
```

---

## Setup and Access

### Initial Repository Setup

```bash
# 1. Clone the private repository (requires access)
git clone https://github.com/waltdundore/ahab-secrets.git
cd ahab-secrets

# 2. Set up git-crypt (one-time setup)
git-crypt unlock

# 3. Set up Ansible Vault password
./scripts/setup-secrets.sh

# 4. Verify access to encrypted files
ansible-vault view ansible/group_vars/all/vault.yml
```

### Prerequisites

**Required Software**:
- Git with SSH key authentication
- Git-crypt for file-level encryption
- Ansible for vault operations
- GPG for additional encryption (optional)

**Required Access**:
- GitHub account with repository access
- SSH key added to GitHub account
- Git-crypt key provided by administrator

### Access Verification

```bash
# Test repository access
git clone https://github.com/waltdundore/ahab-secrets.git

# Test git-crypt unlock
cd ahab-secrets
git-crypt unlock

# Test Ansible Vault access
ansible-vault view ansible/group_vars/all/vault.yml \
    --vault-password-file ansible/vault-password.txt
```

---

## Usage Patterns

### Network Switch Credentials

**Development Environment**:
```bash
# Link dev credentials to ahab
ln -sf $(pwd)/ahab-secrets/ansible/group_vars/network_switches/vault_dev.yml \
       ahab/inventory/group_vars/network_switches/vault.yml

# Test connectivity
cd ahab
make network-switches-test ENV=dev
```

**Production Environment**:
```bash
# Link prod credentials to ahab
ln -sf $(pwd)/ahab-secrets/ansible/group_vars/network_switches/vault_prod.yml \
       ahab/inventory/group_vars/network_switches/vault.yml

# Test connectivity (carefully)
cd ahab
make network-switches-test ENV=prod
```

### Database Credentials

```bash
# Link database credentials
ln -sf $(pwd)/ahab-secrets/ansible/group_vars/databases/vault_dev.yml \
       ahab/inventory/group_vars/databases/vault.yml

# Use in playbooks
ansible-playbook playbooks/database-setup.yml \
    --vault-password-file ../ahab-secrets/ansible/vault-password.txt
```

### SSH Key Management

```bash
# Use network switch SSH keys
ssh -i ahab-secrets/ssh-keys/network-switches/dev_rsa admin@192.168.1.10

# Use in Ansible inventory
ansible_ssh_private_key_file: ../ahab-secrets/ssh-keys/network-switches/dev_rsa
```

---

## Creating New Secrets

### Network Switch Credentials

```bash
# 1. Create new vault file
cd ahab-secrets
ansible-vault create ansible/group_vars/network_switches/vault_new_env.yml \
    --vault-password-file ansible/vault-password.txt

# 2. Add credentials (example content)
```

**Example vault content**:
```yaml
# Network Switch Credentials - New Environment
# Created: 2025-12-09
# Environment: new_env

# Aruba switches
aruba_admin_username: "admin"
aruba_admin_password: "SecureArubaPassword123!"
aruba_enable_password: "SecureArubaEnable456!"

# Ruckus switches
ruckus_admin_username: "admin"
ruckus_admin_password: "SecureRuckusPassword789!"
ruckus_enable_password: "SecureRuckusEnable012!"

# Per-switch credentials (if needed)
switch_credentials:
  core-switch-01:
    username: "netadmin"
    password: "CoreSwitch123!"
    enable_password: "CoreEnable456!"
  access-switch-01:
    username: "netadmin"
    password: "AccessSwitch789!"
    enable_password: "AccessEnable012!"

# SNMP credentials
snmp_community_ro: "ReadOnlyCommunity123"
snmp_community_rw: "ReadWriteCommunity456"
snmp_v3_username: "snmpv3user"
snmp_v3_password: "SNMPv3Password789!"
```

### Database Credentials

```bash
# Create database vault
ansible-vault create ansible/group_vars/databases/vault_new_env.yml \
    --vault-password-file ansible/vault-password.txt
```

**Example database vault**:
```yaml
# Database Credentials - New Environment
# Created: 2025-12-09
# Environment: new_env

# PostgreSQL
postgres_admin_user: "postgres"
postgres_admin_password: "PostgresAdmin123!"
postgres_app_user: "ahab_app"
postgres_app_password: "AhabAppPassword456!"

# MySQL/MariaDB
mysql_root_password: "MySQLRoot789!"
mysql_app_user: "ahab_app"
mysql_app_password: "MySQLAppPassword012!"

# MongoDB
mongodb_admin_user: "admin"
mongodb_admin_password: "MongoAdmin345!"
mongodb_app_user: "ahab_app"
mongodb_app_password: "MongoAppPassword678!"

# Connection strings (encrypted)
database_urls:
  postgres: "postgresql://ahab_app:AhabAppPassword456!@localhost:5432/ahab"
  mysql: "mysql://ahab_app:MySQLAppPassword012!@localhost:3306/ahab"
  mongodb: "mongodb://ahab_app:MongoAppPassword678!@localhost:27017/ahab"
```

### API Keys and Tokens

```bash
# Create API keys vault
ansible-vault create api-keys/vault_new_env.yml \
    --vault-password-file ansible/vault-password.txt
```

**Example API keys vault**:
```yaml
# API Keys and Tokens - New Environment
# Created: 2025-12-09
# Environment: new_env

# Cloud providers
aws_access_key_id: "AKIAIOSFODNN7EXAMPLE"
aws_secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
azure_client_id: "12345678-1234-1234-1234-123456789012"
azure_client_secret: "AzureClientSecret123!"

# Monitoring services
datadog_api_key: "1234567890abcdef1234567890abcdef"
newrelic_license_key: "1234567890abcdef1234567890abcdef12345678"

# Communication services
slack_webhook_url: "https://example.com/fake-webhook-for-documentation-only"
email_smtp_password: "EmailSMTPPassword123!"

# External APIs
github_token: "ghp_1234567890abcdef1234567890abcdef123456"
docker_registry_token: "DockerRegistryToken123!"
```

---

## Sanitized Examples

### Network Switch Example (Public)

For documentation and setup purposes, sanitized examples are provided:

```yaml
# Example: Network Switch Credentials (SANITIZED)
# File: examples/network-switches-vault.yml
# Use this as a template for your actual credentials

# Aruba switches
aruba_admin_username: "admin"
aruba_admin_password: "REPLACE_WITH_SECURE_PASSWORD"
aruba_enable_password: "REPLACE_WITH_SECURE_ENABLE_PASSWORD"

# Ruckus switches
ruckus_admin_username: "admin"
ruckus_admin_password: "REPLACE_WITH_SECURE_PASSWORD"
ruckus_enable_password: "REPLACE_WITH_SECURE_ENABLE_PASSWORD"

# Per-switch credentials template
switch_credentials:
  switch-hostname-01:
    username: "REPLACE_WITH_USERNAME"
    password: "REPLACE_WITH_PASSWORD"
    enable_password: "REPLACE_WITH_ENABLE_PASSWORD"

# SNMP credentials template
snmp_community_ro: "REPLACE_WITH_RO_COMMUNITY"
snmp_community_rw: "REPLACE_WITH_RW_COMMUNITY"
snmp_v3_username: "REPLACE_WITH_SNMP_USERNAME"
snmp_v3_password: "REPLACE_WITH_SNMP_PASSWORD"
```

### Database Example (Public)

```yaml
# Example: Database Credentials (SANITIZED)
# File: examples/database-vault.yml
# Use this as a template for your actual credentials

# PostgreSQL
postgres_admin_user: "postgres"
postgres_admin_password: "REPLACE_WITH_POSTGRES_ADMIN_PASSWORD"
postgres_app_user: "your_app_user"
postgres_app_password: "REPLACE_WITH_APP_PASSWORD"

# MySQL/MariaDB
mysql_root_password: "REPLACE_WITH_MYSQL_ROOT_PASSWORD"
mysql_app_user: "your_app_user"
mysql_app_password: "REPLACE_WITH_MYSQL_APP_PASSWORD"

# Connection strings template
database_urls:
  postgres: "postgresql://USER:PASSWORD@HOST:PORT/DATABASE"
  mysql: "mysql://USER:PASSWORD@HOST:PORT/DATABASE"
```

---

## Security Procedures

### Credential Rotation

```bash
# 1. Generate new credentials
./scripts/rotate-credentials.sh network_switches dev

# 2. Update vault files
ansible-vault edit ansible/group_vars/network_switches/vault_dev.yml \
    --vault-password-file ansible/vault-password.txt

# 3. Test new credentials
cd ../ahab
make network-switches-test ENV=dev

# 4. Update production (if dev tests pass)
cd ../ahab-secrets
./scripts/rotate-credentials.sh network_switches prod
```

### Access Audit

```bash
# Review repository access
git log --oneline --since="1 month ago"

# Check vault file modifications
git log --follow ansible/group_vars/network_switches/vault_prod.yml

# Validate all vault files
./scripts/validate-secrets.sh
```

### Backup Procedures

```bash
# Create encrypted backup
./scripts/backup-secrets.sh

# Verify backup integrity
./scripts/validate-backup.sh backup-2025-12-09.tar.gz.gpg

# Test restore procedure (in test environment)
./scripts/restore-secrets.sh backup-2025-12-09.tar.gz.gpg
```

---

## Integration with Ahab

### Linking Secrets to Ahab

```bash
# Method 1: Symbolic links (recommended for development)
cd ahab
ln -sf ../ahab-secrets/ansible/group_vars/network_switches/vault_dev.yml \
       inventory/group_vars/network_switches/vault.yml

# Method 2: Copy files (for production deployment)
cp ../ahab-secrets/ansible/group_vars/network_switches/vault_prod.yml \
   inventory/group_vars/network_switches/vault.yml

# Method 3: Environment variable (for CI/CD)
export ANSIBLE_VAULT_PASSWORD_FILE="../ahab-secrets/ansible/vault-password.txt"
```

### Makefile Integration

Add to `ahab/Makefile`:

```makefile
# Secrets management targets
.PHONY: secrets-setup secrets-test secrets-rotate

secrets-setup:
	@echo "→ Setting up secrets repository link"
	@if [ ! -d "../ahab-secrets" ]; then \
		echo "ERROR: ahab-secrets repository not found"; \
		echo "Clone from: https://github.com/waltdundore/ahab-secrets"; \
		exit 1; \
	fi
	@ln -sf ../ahab-secrets/ansible/group_vars/network_switches/vault_$(ENV).yml \
		inventory/group_vars/network_switches/vault.yml
	@echo "✓ Secrets linked for environment: $(ENV)"

secrets-test:
	@echo "→ Testing secrets access"
	@ansible-vault view inventory/group_vars/network_switches/vault.yml \
		--vault-password-file ../ahab-secrets/ansible/vault-password.txt
	@echo "✓ Secrets accessible"

secrets-rotate:
	@echo "→ Rotating credentials for environment: $(ENV)"
	@cd ../ahab-secrets && ./scripts/rotate-credentials.sh network_switches $(ENV)
	@echo "✓ Credentials rotated"
```

### GUI Integration

Update `ahab-gui/config.py`:

```python
# Secrets repository configuration
SECRETS_REPO_PATH = os.path.join(os.path.dirname(AHAB_PATH), 'ahab-secrets')
VAULT_PASSWORD_FILE = os.path.join(SECRETS_REPO_PATH, 'ansible', 'vault-password.txt')

# Check if secrets repository is available
SECRETS_AVAILABLE = os.path.exists(SECRETS_REPO_PATH)
```

Update `ahab-gui/commands/executor.py`:

```python
def execute_with_vault(self, command, env='dev'):
    """Execute command with Ansible Vault support."""
    
    # Check for vault password file
    vault_file = os.path.join(current_app.config['SECRETS_REPO_PATH'], 
                             'ansible', 'vault-password.txt')
    
    if os.path.exists(vault_file):
        # Set vault password file environment variable
        env_vars = os.environ.copy()
        env_vars['ANSIBLE_VAULT_PASSWORD_FILE'] = vault_file
        
        result = subprocess.run(command,
                              cwd=self.ahab_path,
                              env=env_vars,
                              capture_output=True,
                              text=True)
    else:
        # Fallback to asking for vault password
        result = subprocess.run(command + ['--ask-vault-pass'],
                              cwd=self.ahab_path,
                              capture_output=True,
                              text=True)
    
    return result
```

---

## Scripts

### Setup Script

Create `ahab-secrets/scripts/setup-secrets.sh`:

```bash
#!/bin/bash
# Setup script for ahab-secrets repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Setting up ahab-secrets repository..."

# Check prerequisites
if ! command -v git-crypt &> /dev/null; then
    echo "ERROR: git-crypt not found. Please install git-crypt first."
    exit 1
fi

if ! command -v ansible-vault &> /dev/null; then
    echo "ERROR: ansible-vault not found. Please install Ansible first."
    exit 1
fi

# Unlock git-crypt
echo "Unlocking git-crypt..."
cd "$REPO_ROOT"
git-crypt unlock

# Verify vault password file exists
VAULT_PASSWORD_FILE="$REPO_ROOT/ansible/vault-password.txt"
if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
    echo "ERROR: Vault password file not found: $VAULT_PASSWORD_FILE"
    echo "This file should be encrypted with git-crypt."
    exit 1
fi

# Test vault access
echo "Testing Ansible Vault access..."
if ansible-vault view ansible/group_vars/all/vault.yml \
    --vault-password-file "$VAULT_PASSWORD_FILE" > /dev/null 2>&1; then
    echo "✓ Ansible Vault access verified"
else
    echo "ERROR: Cannot access Ansible Vault files"
    echo "Check vault password file: $VAULT_PASSWORD_FILE"
    exit 1
fi

# Create example files if they don't exist
echo "Creating example files..."
mkdir -p examples

if [ ! -f "examples/network-switches-vault.yml" ]; then
    cat > examples/network-switches-vault.yml << 'EOF'
# Example: Network Switch Credentials (SANITIZED)
# Use this as a template for your actual credentials

# Aruba switches
aruba_admin_username: "admin"
aruba_admin_password: "REPLACE_WITH_SECURE_PASSWORD"
aruba_enable_password: "REPLACE_WITH_SECURE_ENABLE_PASSWORD"

# Ruckus switches
ruckus_admin_username: "admin"
ruckus_admin_password: "REPLACE_WITH_SECURE_PASSWORD"
ruckus_enable_password: "REPLACE_WITH_SECURE_ENABLE_PASSWORD"
EOF
fi

echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Link secrets to ahab: cd ../ahab && make secrets-setup ENV=dev"
echo "2. Test connectivity: make network-switches-test ENV=dev"
echo "3. Review security procedures in README.md"
```

### Validation Script

Create `ahab-secrets/scripts/validate-secrets.sh`:

```bash
#!/bin/bash
# Validate all secrets in the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VAULT_PASSWORD_FILE="$REPO_ROOT/ansible/vault-password.txt"

echo "Validating secrets repository..."

# Check vault password file
if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
    echo "ERROR: Vault password file not found: $VAULT_PASSWORD_FILE"
    exit 1
fi

# Validate all vault files
VAULT_FILES=$(find "$REPO_ROOT" -name "vault*.yml" -type f)
ERRORS=0

for vault_file in $VAULT_FILES; do
    echo "Checking: $vault_file"
    
    if ansible-vault view "$vault_file" \
        --vault-password-file "$VAULT_PASSWORD_FILE" > /dev/null 2>&1; then
        echo "  ✓ Valid"
    else
        echo "  ✗ Invalid or corrupted"
        ((ERRORS++))
    fi
done

# Check SSH key permissions
SSH_KEYS=$(find "$REPO_ROOT/ssh-keys" -name "*_rsa" -type f 2>/dev/null || true)
for key_file in $SSH_KEYS; do
    echo "Checking SSH key: $key_file"
    
    PERMS=$(stat -c "%a" "$key_file")
    if [ "$PERMS" = "600" ]; then
        echo "  ✓ Correct permissions (600)"
    else
        echo "  ✗ Incorrect permissions ($PERMS), should be 600"
        ((ERRORS++))
    fi
done

# Summary
if [ $ERRORS -eq 0 ]; then
    echo "✓ All secrets validated successfully"
    exit 0
else
    echo "✗ Found $ERRORS errors"
    exit 1
fi
```

---

## Troubleshooting

### Common Issues

#### 1. Repository Access Denied

**Symptoms**: `Permission denied (publickey)` when cloning

**Solutions**:
```bash
# Check SSH key is added to GitHub
ssh -T git@github.com

# Verify repository access
# Contact repository administrator for access

# Use HTTPS with token (temporary)
git clone https://github.com/waltdundore/ahab-secrets.git
```

#### 2. Git-crypt Unlock Failed

**Symptoms**: `git-crypt: error: key not available`

**Solutions**:
```bash
# Check git-crypt status
git-crypt status

# Request git-crypt key from administrator
# Key should be provided securely (not via email/chat)

# Verify git-crypt installation
git-crypt --version
```

#### 3. Vault Decryption Failed

**Symptoms**: `ERROR! Decryption failed`

**Solutions**:
```bash
# Check vault password file exists and is readable
ls -la ansible/vault-password.txt

# Verify file is decrypted by git-crypt
file ansible/vault-password.txt
# Should show: ASCII text (not binary)

# Test vault password manually
ansible-vault view ansible/group_vars/all/vault.yml \
    --vault-password-file ansible/vault-password.txt
```

#### 4. Secrets Not Found in Ahab

**Symptoms**: `inventory/group_vars/network_switches/vault.yml not found`

**Solutions**:
```bash
# Check if secrets are linked
ls -la ahab/inventory/group_vars/network_switches/vault.yml

# Link secrets for development
cd ahab
make secrets-setup ENV=dev

# Verify link target exists
ls -la ../ahab-secrets/ansible/group_vars/network_switches/vault_dev.yml
```

---

## Compliance and Auditing

### STIG Compliance

- ✅ **V-235791**: No secrets embedded in code or images
- ✅ **V-235792**: Credentials encrypted at rest (Ansible Vault + Git-crypt)
- ✅ **V-235793**: Access logging enabled (Git history)
- ✅ **V-235794**: Credential rotation procedures documented
- ✅ **V-235795**: Backup and recovery procedures implemented

### Audit Requirements

**Monthly Reviews**:
- Repository access permissions
- Credential rotation status
- Backup verification
- Security incident review

**Quarterly Reviews**:
- Access control effectiveness
- Encryption key rotation
- Backup and recovery testing
- Security procedure updates

### Compliance Checks

```bash
# Run security validation
./scripts/validate-secrets.sh

# Check for plaintext secrets (should find none)
grep -r "password\|secret\|key" . --exclude-dir=.git | grep -v "REPLACE_WITH"

# Verify encryption status
git-crypt status
```

---

## Related Documentation

- [Network Switch Credentials](NETWORK_SWITCH_CREDENTIALS.md) - Detailed credential management
- [Security Framework](SECURITY_CIA_TRIAD.md) - Security implementation
- [Zero Trust Development](../../.kiro/steering/zero-trust-development.md) - Security principles
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html) - Official documentation

---

## Summary

The `ahab-secrets` repository provides:

1. **Secure Storage**: Private repository with git-crypt and Ansible Vault encryption
2. **Environment Separation**: Separate credentials for dev/prod environments
3. **Access Control**: Need-to-know access with audit logging
4. **Integration**: Seamless integration with Ahab automation and GUI
5. **Compliance**: Meets STIG requirements and Zero Trust principles
6. **Procedures**: Documented rotation, backup, and recovery procedures

**Key Security Features**:
- Double encryption (git-crypt + Ansible Vault)
- Private repository with restricted access
- Credential rotation procedures
- Audit logging and compliance checks
- Sanitized examples for documentation

**This approach ensures secure credential management while maintaining operational efficiency and compliance requirements.**

---

**Last Updated**: December 9, 2025  
**Next Review**: January 9, 2026  
**Repository**: https://github.com/waltdundore/ahab-secrets (Private)