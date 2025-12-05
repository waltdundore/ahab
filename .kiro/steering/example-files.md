---
# Example Files Rule

## Principle

For any file that is necessary for the end user to configure but is also in .gitignore, create a corresponding `.example` file with sanitized content and clear instructions.

## Why This Matters

Users need to know:
1. What files they need to create
2. What format those files should have
3. What values they need to provide
4. Where to find more information

## Required Example Files

### Files That Need Examples

Any file that is:
- ✅ Required for the system to work
- ✅ Contains user-specific or environment-specific data
- ✅ Listed in .gitignore

**Common examples:**
- `hosts.yml` → `hosts.yml.example`
- `config.yml` → `config.yml.example` (if gitignored)
- `.env` → `.env.example`
- `secrets.yml` → `secrets.yml.example`

## Example File Format

### Naming Convention

```
original-file.ext → original-file.ext.example
```

**Examples:**
- `hosts.yml` → `hosts.yml.example`
- `config.yml` → `config.yml.example`
- `.env` → `.env.example`

### File Header

Every example file must have a header:

```yaml
# ==============================================================================
# [File Name] - Example Configuration
# ==============================================================================
# This is an example file. Copy it and customize for your environment.
#
# Setup:
#   1. Copy this file: cp [filename].example [filename]
#   2. Edit the file: vim [filename]
#   3. Replace placeholder values with your actual values
#
# Required Changes:
#   - [List what MUST be changed]
#
# Optional Changes:
#   - [List what CAN be changed]
#
# Documentation: [Link to relevant docs]
```

### Content Guidelines

#### 1. Use Placeholder Values

**Good placeholders:**
```yaml
ansible_user: your_username          # ← Clear placeholder
ssh_key: ~/.ssh/id_ed25519.pub      # ← Realistic example
server: server.example.com          # ← example.com domain
password: "{{ vault_password }}"    # ← Shows proper pattern
```

**Bad placeholders:**
```yaml
ansible_user: wdundore              # ← Real username (security risk)
ssh_key: /Users/wdundore/.ssh/key  # ← Real path (privacy issue)
server: 192.168.1.100               # ← Real IP (security risk)
password: MyPassword123             # ← Real password (critical!)
```

#### 2. Add Inline Comments

```yaml
# SSH Configuration
ssh:
  public_key: ~/.ssh/id_ed25519.pub  # ← CHANGE: Path to YOUR SSH public key

# User Configuration
common:
  timezone: America/New_York          # ← CHANGE: Your timezone
  packages_to_install:
    - git
    - htop
    - vim                             # ← ADD: Your preferred packages
```

#### 3. Show Multiple Examples

```yaml
# Example 1: Single server
docker:
  hosts:
    server1.example.com:

# Example 2: Multiple servers
docker:
  hosts:
    web1.example.com:
    web2.example.com:
    app1.example.com:
```

#### 4. Include Common Patterns

```yaml
# Pattern 1: Development environment
environment: dev
debug: true

# Pattern 2: Production environment
environment: prod
debug: false
```

## Implementation Checklist

For each example file:

- [ ] Has descriptive header with setup instructions
- [ ] Lists required changes
- [ ] Lists optional changes
- [ ] Uses placeholder values (no real data)
- [ ] Has inline comments explaining each field
- [ ] Shows multiple examples where applicable
- [ ] Links to relevant documentation
- [ ] Is tracked in git (not in .gitignore)
- [ ] Matches the format of the real file
- [ ] Is mentioned in README.md

## Example File Templates

### hosts.yml.example

```yaml
# ==============================================================================
# Ansible Inventory - Example Hosts File
# ==============================================================================
# This is an example inventory file. Copy and customize for your environment.
#
# Setup:
#   1. Copy this file: cp hosts.yml.example hosts.yml
#   2. Edit the file: vim hosts.yml
#   3. Replace example.com with your actual hostnames
#   4. Set your SSH username
#
# Required Changes:
#   - ansible_user: Set to your SSH username
#   - Hostnames: Replace example.com with your servers
#
# Documentation: See ~/git/ansible-control/README.md

all:
  vars:
    ansible_user: your_username  # ← CHANGE: Your SSH username
  
  children:
    # Servers that get Docker installed
    docker:
      hosts:
        server1.example.com:     # ← CHANGE: Your server hostname
        server2.example.com:     # ← ADD: More servers as needed
    
    # Servers that get NFS client
    nfs:
      hosts:
        storage.example.com:     # ← CHANGE: Your NFS server
```

### config.yml.example

```yaml
# ==============================================================================
# Ahab Configuration - Example
# ==============================================================================
# This is an example configuration file. Copy and customize.
#
# Setup:
#   1. Copy this file: cp config.yml.example config.yml
#   2. Edit the file: vim config.yml
#   3. Set your SSH key path (REQUIRED)
#   4. Customize other settings as needed
#
# Required Changes:
#   - ssh.public_key: Path to YOUR SSH public key
#
# Optional Changes:
#   - common.timezone: Your timezone
#   - common.packages_to_install: Your preferred packages
#   - docker.users: Users who can run Docker
#
# Documentation: See ~/git/ansible-control/README.md

# REQUIRED: SSH Configuration
ssh:
  public_key: ~/.ssh/id_ed25519.pub  # ← CHANGE: Path to YOUR key

# OPTIONAL: Common Configuration
common:
  timezone: America/New_York          # ← CHANGE: Your timezone
  packages_to_install:
    - git
    - htop
    - vim                             # ← ADD: Your packages

# OPTIONAL: Docker Configuration
docker:
  use_official_repo: false            # true = official Docker repo
  users:
    - your_username                   # ← CHANGE: Your username

# OPTIONAL: NFS Configuration
nfs:
  server: storage.example.com         # ← CHANGE: Your NFS server
  export: /volume1/nas                # ← CHANGE: Export path
  mountpoint: /nas                    # ← CHANGE: Local mount point
```

### .env.example

```bash
# ==============================================================================
# Environment Variables - Example
# ==============================================================================
# Copy this file: cp .env.example .env
# Then edit .env with your actual values

# Ansible Vault Password
ANSIBLE_VAULT_PASSWORD=your_vault_password_here

# API Keys (if needed)
API_KEY=your_api_key_here
API_SECRET=your_api_secret_here

# Database (if needed)
DB_HOST=localhost
DB_USER=your_db_user
DB_PASS=your_db_password
```

## Documentation Requirements

### In README.md

Document the example files:

```markdown
## Configuration

### 1. Configure Inventory

Copy the example file and customize:

```bash
cd ~/git/ansible-inventory/dev
cp hosts.yml.example hosts.yml
vim hosts.yml  # Edit with your servers
```

### 2. Configure Settings

Copy the example file and customize:

```bash
cd ~/git/ansible-config/dev
cp config.yml.example config.yml
vim config.yml  # Edit with your settings
```
```

### In Setup Scripts

Reference example files:

```bash
if [ ! -f "hosts.yml" ]; then
    echo "Creating hosts.yml from example..."
    cp hosts.yml.example hosts.yml
    echo "Please edit hosts.yml with your server information"
fi
```

## Security Considerations

### Never Include in Examples

❌ Real usernames
❌ Real hostnames or IP addresses
❌ Real passwords or API keys
❌ Real SSH keys (private or public)
❌ Real database credentials
❌ Real file paths with usernames
❌ Real email addresses

### Always Use in Examples

✅ Placeholder usernames: `your_username`, `admin`, `user`
✅ Example domains: `example.com`, `server.example.com`
✅ Placeholder passwords: `your_password_here`, `{{ vault_password }}`
✅ Generic paths: `~/.ssh/id_ed25519.pub`, `/path/to/file`
✅ Example emails: `user@example.com`

## Maintenance

### When Adding New Gitignored Files

1. Create the example file immediately
2. Add header with instructions
3. Use placeholder values
4. Add inline comments
5. Update README.md
6. Update setup scripts
7. Test the example file

### When Updating File Format

1. Update the example file
2. Update inline comments
3. Update README documentation
4. Notify users of changes

## Verification

### Check Example Files Exist

```bash
# Find gitignored files
git ls-files --others --ignored --exclude-standard

# Check for corresponding .example files
for file in $(git ls-files --others --ignored --exclude-standard); do
    if [ ! -f "$file.example" ]; then
        echo "Missing: $file.example"
    fi
done
```

### Validate Example Files

- [ ] Has header with instructions
- [ ] Uses placeholder values only
- [ ] Has inline comments
- [ ] Matches real file format
- [ ] Is tracked in git
- [ ] Is documented in README

## Common Mistakes

### Mistake 1: Real Data in Examples

```yaml
# BAD
ansible_user: wdundore
server: 192.168.1.100

# GOOD
ansible_user: your_username
server: server.example.com
```

### Mistake 2: No Instructions

```yaml
# BAD - No header, no comments
ansible_user: your_username

# GOOD - Clear instructions
# Copy this file: cp hosts.yml.example hosts.yml
# Then edit with your username
ansible_user: your_username  # ← CHANGE: Your SSH username
```

### Mistake 3: Missing Example File

```
# BAD
.gitignore contains: config.yml
But no config.yml.example exists

# GOOD
.gitignore contains: config.yml
config.yml.example exists with instructions
```

## Benefits

✅ **User-Friendly** - Clear instructions for setup
✅ **Secure** - No real credentials in git
✅ **Documented** - Self-documenting configuration
✅ **Consistent** - Standard format across repos
✅ **Discoverable** - Easy to find what's needed

## Summary

Every file that users need to configure but is gitignored must have a corresponding `.example` file with:
- Clear setup instructions
- Placeholder values (no real data)
- Inline comments explaining each field
- Links to documentation

This makes the system easier to set up and more secure by keeping real credentials out of git.
