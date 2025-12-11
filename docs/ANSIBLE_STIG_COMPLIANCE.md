# Ansible STIG Compliance Audit

**Date**: December 9, 2025  
**Status**: Security Audit  
**Reference**: [Red Hat Ansible Automation Controller STIG](https://stigviewer.cyberprotection.com/stigs/red_hat_ansible_automation_controller_application_server)

---

## Executive Summary

This document audits Ahab's Ansible implementation against the Security Technical Implementation Guide (STIG) for Red Hat Ansible Automation Controller. While Ahab uses Ansible in a development/workstation context (not the full Automation Controller), we apply relevant security controls.

**Overall Status**: ⚠️ **NEEDS IMPROVEMENT**

**Critical Findings**:
- ❌ No Ansible Vault usage for secrets
- ❌ No `no_log` protection for sensitive data
- ⚠️ Host key checking disabled in production config
- ⚠️ Missing centralized logging configuration
- ⚠️ No audit trail for privilege escalation

**Strengths**:
- ✅ Privilege escalation properly configured
- ✅ No hardcoded credentials in playbooks
- ✅ Proper use of `become` for privilege escalation
- ✅ Timeout protection configured

---

## STIG Requirements Analysis

### 1. Authentication & Authorization

#### STIG-ANSI-AC-000001: Privilege Escalation Must Be Controlled

**Requirement**: Ansible must enforce approved authorizations for controlling the flow of information within the system based on organization-defined information flow control policies.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
- name: Provision Ahab Workstation
  hosts: all
  become: true  # ✅ Explicit privilege escalation
```

**Status**: ✅ **COMPLIANT**

**Evidence**:
- All playbooks use explicit `become: true`
- Privilege escalation configured in `ansible.cfg.production`
- Uses sudo method (standard and auditable)

**Recommendation**: None - properly implemented.

---

#### STIG-ANSI-AC-000002: Least Privilege Principle

**Requirement**: Ansible must enforce the principle of least privilege by limiting privilege escalation to only necessary tasks.

**Current Implementation**:
```yaml
# Current: Global become for entire playbook
- name: Provision Ahab Workstation
  hosts: all
  become: true  # ⚠️ All tasks run as root
```

**Status**: ⚠️ **NEEDS IMPROVEMENT**

**Issue**: `become: true` is set at playbook level, meaning ALL tasks run as root, even those that don't need it.

**Recommendation**:
```yaml
# ✅ BETTER: Task-level privilege escalation
- name: Provision Ahab Workstation
  hosts: all
  # No global become

  tasks:
    - name: Install packages
      ansible.builtin.dnf:
        name: docker
        state: present
      become: true  # Only this task needs root

    - name: Check user directory
      ansible.builtin.stat:
        path: /home/vagrant
      # No become - runs as vagrant user
```

**Action Required**: Refactor playbooks to use task-level `become` only where needed.

---

### 2. Secrets Management

#### STIG-ANSI-IA-000001: Credentials Must Be Protected

**Requirement**: Ansible must protect the confidentiality and integrity of transmitted and stored information, including credentials and sensitive data.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
# ❌ No Ansible Vault usage
# ❌ No encrypted variables
# ❌ No vault_password_file configured
```

**Status**: ❌ **NON-COMPLIANT**

**Issue**: While no hardcoded secrets exist currently, there's no mechanism to securely handle secrets when needed.

**Recommendation**:
```yaml
# ✅ Use Ansible Vault for secrets
# 1. Create encrypted variables file
ansible-vault create group_vars/all/vault.yml

# 2. Store secrets encrypted
---
vault_db_password: "encrypted_password_here"
vault_api_key: "encrypted_key_here"

# 3. Reference in playbooks
- name: Configure database
  ansible.builtin.template:
    src: db_config.j2
    dest: /etc/db.conf
  vars:
    db_password: "{{ vault_db_password }}"
  no_log: true  # Prevent logging
```

**Action Required**:
1. Create `ahab/group_vars/all/vault.yml` for encrypted secrets
2. Configure `vault_password_file` in ansible.cfg
3. Document vault usage in PRODUCTION_DEPLOYMENT.md

---

#### STIG-ANSI-IA-000002: Sensitive Data Must Not Be Logged

**Requirement**: Ansible must not log sensitive information such as passwords, keys, or tokens.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
- name: Verify Docker installation
  ansible.builtin.command: docker --version
  register: docker_version  # ⚠️ No no_log protection
  changed_when: false

- name: Display installation summary
  ansible.builtin.debug:
    msg:
      - "Docker: {{ docker_version.stdout }}"  # ⚠️ Could expose sensitive data
```

**Status**: ⚠️ **NEEDS IMPROVEMENT**

**Issue**: No `no_log: true` on tasks that could potentially handle sensitive data.

**Recommendation**:
```yaml
# ✅ Protect sensitive operations
- name: Configure API credentials
  ansible.builtin.template:
    src: api_config.j2
    dest: /etc/api.conf
  no_log: true  # Prevent logging of sensitive data

- name: Set database password
  ansible.builtin.user:
    name: dbuser
    password: "{{ vault_db_password | password_hash('sha512') }}"
  no_log: true  # Never log password operations
```

**Action Required**:
1. Add `no_log: true` to any task handling credentials
2. Add `no_log: true` to tasks with `register` that might capture secrets
3. Review all `debug` tasks to ensure no sensitive data exposure

---

### 3. Network Security

#### STIG-ANSI-SC-000001: SSH Host Key Verification

**Requirement**: Ansible must verify SSH host keys to prevent man-in-the-middle attacks.

**Current Implementation**:
```ini
# ahab/config/ansible.cfg.production
[defaults]
host_key_checking = False  # ❌ SECURITY RISK
```

**Status**: ❌ **NON-COMPLIANT**

**Issue**: Disabling host key checking allows man-in-the-middle attacks.

**Recommendation**:
```ini
# ✅ Enable host key checking
[defaults]
host_key_checking = True

# For new hosts, use:
# ssh-keyscan -H hostname >> ~/.ssh/known_hosts
```

**Exception**: For development workstations (Vagrant VMs), this is acceptable since:
- VMs are ephemeral and recreated frequently
- VMs run on localhost (no network exposure)
- SSH keys change on each `vagrant destroy/up`

**Action Required**:
1. Keep `host_key_checking = False` for development (Vagrant)
2. Create separate `ansible.cfg.production` with `host_key_checking = True`
3. Document the security trade-off in PRODUCTION_DEPLOYMENT.md

---

#### STIG-ANSI-SC-000002: Connection Timeout

**Requirement**: Ansible must terminate inactive sessions after an organization-defined time period.

**Current Implementation**:
```ini
# ahab/config/ansible.cfg.production
[defaults]
timeout = 30  # ✅ 30 second timeout
```

**Status**: ✅ **COMPLIANT**

**Evidence**: Timeout configured to prevent hanging connections.

**Recommendation**: None - properly implemented.

---

### 4. Audit & Accountability

#### STIG-ANSI-AU-000001: Audit Logging Must Be Enabled

**Requirement**: Ansible must generate audit records containing information that establishes what type of event occurred, when the event occurred, where the event occurred, the source of the event, the outcome of the event, and the identity of any individuals or subjects associated with the event.

**Current Implementation**:
```ini
# ahab/config/ansible.cfg.production
# Logging (optional - uncomment to enable)
# log_path = /var/log/ansible/ansible.log  # ❌ Commented out
```

**Status**: ❌ **NON-COMPLIANT**

**Issue**: No centralized audit logging configured.

**Recommendation**:
```ini
# ✅ Enable audit logging
[defaults]
log_path = /var/log/ansible/ansible.log

# Ensure log directory exists and has proper permissions
# mkdir -p /var/log/ansible
# chmod 750 /var/log/ansible
# chown ansible:ansible /var/log/ansible
```

**Action Required**:
1. Enable `log_path` in production ansible.cfg
2. Create log directory with proper permissions
3. Implement log rotation (logrotate)
4. Document log location in PRODUCTION_DEPLOYMENT.md

---

#### STIG-ANSI-AU-000002: Privilege Escalation Must Be Audited

**Requirement**: Ansible must audit all uses of privilege escalation (sudo).

**Current Implementation**:
```yaml
# No explicit audit logging for become operations
- name: Install packages
  ansible.builtin.dnf:
    name: docker
    state: present
  become: true  # ⚠️ Not explicitly audited
```

**Status**: ⚠️ **NEEDS IMPROVEMENT**

**Issue**: While Ansible logs to file (when enabled), there's no explicit audit trail for privilege escalation.

**Recommendation**:
```yaml
# ✅ Add audit logging for privileged operations
- name: Install packages (PRIVILEGED OPERATION)
  ansible.builtin.dnf:
    name: docker
    state: present
  become: true
  tags:
    - privileged
    - audit

# Use callback plugins for enhanced auditing
# ansible.cfg:
# [defaults]
# callback_whitelist = profile_tasks, timer, log_plays
```

**Action Required**:
1. Tag all privileged tasks with `privileged` and `audit`
2. Enable callback plugins for detailed logging
3. Consider integration with syslog for centralized audit

---

### 5. Configuration Management

#### STIG-ANSI-CM-000001: Idempotency Must Be Enforced

**Requirement**: Ansible playbooks must be idempotent - running multiple times should produce the same result without unintended side effects.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
- name: Install workstation packages (Fedora)
  ansible.builtin.dnf:
    name: "{{ workstation_packages }}"
    state: present  # ✅ Idempotent
  when: ansible_distribution == 'Fedora'

- name: Get Git version
  ansible.builtin.command: git --version
  register: git_ver
  changed_when: false  # ✅ Marked as non-changing
```

**Status**: ✅ **COMPLIANT**

**Evidence**:
- Uses declarative modules (dnf, systemd, file)
- Commands marked with `changed_when: false`
- Proper use of `state: present/started/enabled`

**Recommendation**: None - properly implemented.

---

#### STIG-ANSI-CM-000002: Return Values Must Be Checked

**Requirement**: All operations must verify success/failure and handle errors appropriately.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
- name: Verify Docker is running
  ansible.builtin.systemd:
    name: docker
    state: started
  register: docker_status
  failed_when: docker_status.status.ActiveState != 'active'  # ✅ Explicit check
```

**Status**: ✅ **COMPLIANT**

**Evidence**: Critical operations verify success with `failed_when` conditions.

**Recommendation**: Extend to all critical operations.

---

### 6. System Integrity

#### STIG-ANSI-SI-000001: Input Validation

**Requirement**: Ansible must validate all input data to prevent injection attacks.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
vars:
  workstation_packages:  # ✅ Hardcoded list (safe)
    - git
    - ansible
    - docker

# No user input directly used in commands
```

**Status**: ✅ **COMPLIANT**

**Evidence**:
- No direct user input in playbooks
- Variables are predefined lists
- No shell commands with user-supplied data

**Recommendation**: If adding user input, implement whitelist validation:
```yaml
# ✅ Validate user input
- name: Validate service name
  ansible.builtin.assert:
    that:
      - service_name in ['apache', 'mysql', 'nginx']
    fail_msg: "Invalid service: {{ service_name }}"
```

---

#### STIG-ANSI-SI-000002: Command Injection Prevention

**Requirement**: Ansible must prevent command injection through proper use of modules vs shell commands.

**Current Implementation**:
```yaml
# ahab/playbooks/provision-workstation.yml
- name: Get Git version
  ansible.builtin.command: git --version  # ✅ Uses command module
  register: git_ver
  changed_when: false
  failed_when: git_ver.rc != 0
```

**Status**: ✅ **COMPLIANT**

**Evidence**:
- Uses `ansible.builtin.command` (not `shell`)
- No variable interpolation in commands
- Proper use of declarative modules

**Recommendation**: Continue avoiding `shell` module. If needed, use with extreme caution:
```yaml
# ❌ DANGEROUS
- name: Bad example
  ansible.builtin.shell: "echo {{ user_input }}"  # Injection risk

# ✅ SAFE
- name: Good example
  ansible.builtin.command:
    cmd: echo
    args:
      - "{{ user_input }}"  # Properly escaped
```

---

## Compliance Summary

### Compliant Controls ✅

1. **Privilege Escalation Control** - Explicit `become` usage
2. **Connection Timeout** - 30 second timeout configured
3. **Idempotency** - Proper use of declarative modules
4. **Return Value Checking** - Critical operations verified
5. **Input Validation** - No direct user input, predefined variables
6. **Command Injection Prevention** - Proper module usage

### Non-Compliant Controls ❌

1. **Secrets Management** - No Ansible Vault implementation
2. **Sensitive Data Logging** - No `no_log` protection
3. **SSH Host Key Verification** - Disabled in production config
4. **Audit Logging** - Not enabled by default

### Needs Improvement ⚠️

1. **Least Privilege** - Global `become` instead of task-level
2. **Privilege Escalation Auditing** - No explicit audit trail

---

## Remediation Plan

### Priority 1: Critical (Implement Immediately)

#### 1.1 Enable Audit Logging
```bash
# Create log directory
sudo mkdir -p /var/log/ansible
sudo chmod 750 /var/log/ansible

# Update ansible.cfg
sed -i 's/# log_path/log_path/' ahab/config/ansible.cfg.production

# Configure logrotate
cat > /etc/logrotate.d/ansible << 'EOF'
/var/log/ansible/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ansible ansible
}
EOF
```

#### 1.2 Implement Ansible Vault
```bash
# Create vault password file (secure location)
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Create encrypted variables file
ansible-vault create ahab/group_vars/all/vault.yml

# Update ansible.cfg
echo "vault_password_file = ~/.ansible_vault_pass" >> ahab/config/ansible.cfg.production
```

#### 1.3 Add no_log Protection
```yaml
# Update all playbooks with sensitive operations
- name: Any task with credentials
  ansible.builtin.template:
    src: config.j2
    dest: /etc/config
  no_log: true  # Add this
```

### Priority 2: High (Implement Soon)

#### 2.1 Refactor to Task-Level Privilege Escalation
```yaml
# Before (global become)
- name: Playbook
  hosts: all
  become: true
  tasks: [...]

# After (task-level become)
- name: Playbook
  hosts: all
  tasks:
    - name: Privileged task
      ansible.builtin.dnf: [...]
      become: true
    
    - name: Unprivileged task
      ansible.builtin.stat: [...]
      # No become
```

#### 2.2 Enable Host Key Checking for Production
```ini
# Create separate configs
# ahab/config/ansible.cfg.development
[defaults]
host_key_checking = False  # OK for Vagrant

# ahab/config/ansible.cfg.production
[defaults]
host_key_checking = True  # Required for production
```

### Priority 3: Medium (Implement When Possible)

#### 3.1 Enhanced Audit Trail
```yaml
# Tag privileged operations
- name: Install package
  ansible.builtin.dnf:
    name: docker
    state: present
  become: true
  tags:
    - privileged
    - audit
    - package_management

# Enable callback plugins
# ansible.cfg:
callback_whitelist = profile_tasks, timer, log_plays
```

#### 3.2 Input Validation Framework
```yaml
# Create validation role
# roles/validate_input/tasks/main.yml
- name: Validate service name
  ansible.builtin.assert:
    that:
      - service_name is defined
      - service_name in valid_services
    fail_msg: "Invalid service: {{ service_name }}"
```

---

## Testing & Verification

### Verify Audit Logging
```bash
# Run playbook
cd ahab
make install

# Check log file created
ls -la /var/log/ansible/ansible.log

# Verify log content
tail -f /var/log/ansible/ansible.log
```

### Verify Vault Encryption
```bash
# Create test secret
ansible-vault create test_vault.yml

# Verify encrypted
cat test_vault.yml  # Should show encrypted content

# Verify decryption works
ansible-vault view test_vault.yml  # Should show plaintext
```

### Verify no_log Protection
```bash
# Run playbook with sensitive data
ansible-playbook playbook.yml -vvv

# Verify no secrets in output
# Should see: "censored: 'the output has been hidden due to the fact that 'no_log: true' was specified for this result'"
```

---

## Continuous Compliance

### Pre-Commit Checks
```bash
# Add to .git/hooks/pre-commit
#!/bin/bash

# Check for hardcoded secrets
if grep -r "password\|secret\|api_key" ahab/playbooks/; then
    echo "ERROR: Potential hardcoded secret found"
    exit 1
fi

# Check for missing no_log on sensitive tasks
if grep -A5 "password\|secret" ahab/playbooks/ | grep -v "no_log: true"; then
    echo "WARNING: Sensitive task without no_log protection"
fi
```

### CI/CD Pipeline
```yaml
# .github/workflows/ansible-security.yml
name: Ansible Security Audit

on: [push, pull_request]

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install ansible-lint
        run: pip install ansible-lint
      
      - name: Run ansible-lint
        run: ansible-lint ahab/playbooks/
      
      - name: Check for secrets
        run: |
          if grep -r "password\|secret" ahab/playbooks/; then
            echo "ERROR: Potential secret found"
            exit 1
          fi
      
      - name: Verify no_log usage
        run: |
          # Check sensitive tasks have no_log
          ./scripts/validators/validate-ansible-security.sh
```

---

## Documentation Requirements

### Update Production Deployment Guide
```markdown
# ahab/docs/PRODUCTION_DEPLOYMENT.md

## Security Configuration

### Ansible Vault Setup
1. Create vault password file: `~/.ansible_vault_pass`
2. Encrypt sensitive variables: `ansible-vault create group_vars/all/vault.yml`
3. Configure ansible.cfg: `vault_password_file = ~/.ansible_vault_pass`

### Audit Logging
- Log location: `/var/log/ansible/ansible.log`
- Rotation: Daily, 30 day retention
- Permissions: 0640, owned by ansible:ansible

### SSH Security
- Host key checking: ENABLED (production)
- Connection timeout: 30 seconds
- Pipelining: Enabled for performance
```

---

## Related Standards

This STIG compliance aligns with:
- **Zero Trust Development** (.kiro/steering/zero-trust-development.md)
- **CIA Triad Enforcement** (.kiro/steering/cia-triad-enforcement.md)
- **Privilege Escalation Model** (.kiro/steering/privilege-escalation-model.md)

---

## Approval & Sign-Off

**Security Review**: ⚠️ PENDING  
**Compliance Officer**: ⚠️ PENDING  
**Technical Lead**: ⚠️ PENDING  

**Next Review Date**: 2026-03-09 (90 days)

---

**Last Updated**: December 9, 2025  
**Status**: AUDIT COMPLETE - REMEDIATION REQUIRED  
**Priority**: HIGH
