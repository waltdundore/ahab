#!/usr/bin/env bash
# ==============================================================================
# Setup Common Library
# ==============================================================================
# Shared functions for setup scripts (NASA Rule #4 compliant)
# Used by setup-secrets-repository.sh, setup-ansible-vault.sh, etc.
# ==============================================================================

# ==============================================================================
# Secrets Repository Setup Functions
# ==============================================================================

setup_secrets_directory() {
    local secrets_dir="${1:-secrets}"
    
    echo "→ Setting up secrets directory: $secrets_dir"
    
    if [ ! -d "$secrets_dir" ]; then
        mkdir -p "$secrets_dir"
        chmod 700 "$secrets_dir"
        check_pass "Created secrets directory with secure permissions"
    else
        check_pass "Secrets directory already exists"
    fi
    
    # Create .gitignore to prevent accidental commits
    if [ ! -f "$secrets_dir/.gitignore" ]; then
        echo "*" > "$secrets_dir/.gitignore"
        echo "!.gitignore" >> "$secrets_dir/.gitignore"
        check_pass "Created .gitignore to protect secrets"
    fi
}

setup_ansible_vault() {
    local vault_file="${1:-secrets/vault.yml}"
    
    echo "→ Setting up Ansible vault: $vault_file"
    
    if [ ! -f "$vault_file" ]; then
        if command -v ansible-vault >/dev/null 2>&1; then
            ansible-vault create "$vault_file"
            check_pass "Created Ansible vault file"
        else
            check_fail "ansible-vault command not found"
            return 1
        fi
    else
        check_pass "Ansible vault file already exists"
    fi
}

setup_production_credentials() {
    echo "→ Setting up production credential templates"
    
    local templates_dir="secrets/templates"
    mkdir -p "$templates_dir"
    
    # Create template files
    cat > "$templates_dir/database.yml.template" << 'EOF'
# Database credentials template
database:
  host: "REPLACE_WITH_ACTUAL_HOST"
  username: "REPLACE_WITH_ACTUAL_USERNAME"
  password: "REPLACE_WITH_ACTUAL_PASSWORD"
  database: "REPLACE_WITH_ACTUAL_DATABASE"
EOF
    
    cat > "$templates_dir/api-keys.yml.template" << 'EOF'
# API keys template
api_keys:
  service_a: "REPLACE_WITH_ACTUAL_API_KEY"
  service_b: "REPLACE_WITH_ACTUAL_API_KEY"
EOF
    
    check_pass "Created credential templates"
}

# ==============================================================================
# Network Configuration Functions
# ==============================================================================

setup_network_switches() {
    echo "→ Setting up network switch configurations"
    
    local network_dir="config/network"
    mkdir -p "$network_dir"
    
    # Create switch configuration template
    cat > "$network_dir/switches.yml.template" << 'EOF'
# Network switches configuration
switches:
  - name: "main-switch"
    ip: "192.168.1.1"
    username: "REPLACE_WITH_USERNAME"
    password: "REPLACE_WITH_PASSWORD"
    type: "cisco"
  
  - name: "backup-switch"
    ip: "192.168.1.2"
    username: "REPLACE_WITH_USERNAME"
    password: "REPLACE_WITH_PASSWORD"
    type: "cisco"
EOF
    
    check_pass "Created network switch templates"
}

# ==============================================================================
# Testing Setup Functions
# ==============================================================================

setup_nested_test_environment() {
    echo "→ Setting up nested test environment"
    
    local test_dir="tests/nested"
    mkdir -p "$test_dir"
    
    # Create test configuration
    cat > "$test_dir/test-config.yml" << 'EOF'
# Nested test configuration
test_environment:
  vm_memory: "2048"
  vm_cpus: "2"
  test_timeout: "300"
  cleanup_after: true
EOF
    
    # Create test runner script
    cat > "$test_dir/run-nested-tests.sh" << 'EOF'
#!/usr/bin/env bash
# Nested test runner
set -euo pipefail

echo "Running nested tests..."
# Add test logic here

echo "Nested tests completed"
EOF
    
    chmod +x "$test_dir/run-nested-tests.sh"
    check_pass "Created nested test environment"
}

# ==============================================================================
# Validation Functions
# ==============================================================================

validate_setup_prerequisites() {
    echo "→ Validating setup prerequisites"
    
    local required_commands=("ansible" "ansible-vault" "git")
    local missing_count=0
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            check_pass "$cmd is available"
        else
            check_fail "$cmd is not installed"
            ((missing_count++))
        fi
    done
    
    if [ "$missing_count" -gt 0 ]; then
        return 1
    fi
    
    return 0
}

validate_directory_permissions() {
    local dir="$1"
    local expected_perms="${2:-700}"
    
    if [ -d "$dir" ]; then
        local actual_perms
        actual_perms=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%A" "$dir" 2>/dev/null)
        
        if [ "$actual_perms" = "$expected_perms" ]; then
            check_pass "Directory $dir has correct permissions ($expected_perms)"
        else
            check_warn "Directory $dir has permissions $actual_perms (expected $expected_perms)"
        fi
    else
        check_fail "Directory $dir does not exist"
    fi
}

# ==============================================================================
# Repository Creation Functions
# ==============================================================================

create_secrets_repository_structure() {
    local repo_path="$1"
    
    echo "→ Creating secrets repository structure"
    
    # Create main directory
    mkdir -p "$repo_path"
    cd "$repo_path"
    
    # Setup secrets directories
    setup_secrets_directory "credentials"
    setup_secrets_directory "certificates"
    setup_secrets_directory "keys"
    
    # Setup configuration templates
    setup_production_credentials
    setup_network_switches
    
    check_pass "Created repository structure"
}

initialize_secrets_git_repository() {
    local repo_path="$1"
    
    echo "→ Initializing git repository"
    
    cd "$repo_path"
    
    if [ ! -d ".git" ]; then
        git init
        check_pass "Initialized git repository"
    else
        check_pass "Git repository already exists"
    fi
    
    # Create comprehensive .gitignore
    create_secrets_gitignore
    
    # Initial commit
    git add .
    git commit -m "Initial secrets repository structure" || check_pass "Repository already committed"
}

create_secrets_gitignore() {
    cat > ".gitignore" << 'EOF'
# Secrets and sensitive files
*.key
*.pem
*.p12
*.pfx
*password*
*secret*
*credential*

# Temporary files
*.tmp
*.bak
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# But allow template files
!*.template
!examples/
EOF
    
    check_pass "Created comprehensive .gitignore"
}

# ==============================================================================
# Documentation Creation Functions
# ==============================================================================

create_secrets_readme() {
    cat > "README.md" << 'EOF'
# Ahab Secrets Repository

This repository contains sensitive configuration data for the Ahab infrastructure automation system.

## ⚠️ Security Notice

This repository contains sensitive information. Handle with care:

- Never commit unencrypted secrets
- Use Ansible Vault for encryption
- Rotate credentials regularly
- Follow the principle of least privilege

## Structure

```
ahab-secrets/
├── credentials/          # Service credentials
├── certificates/         # SSL certificates
├── keys/                # SSH and API keys
└── templates/           # Configuration templates
```

## Quick Start

1. Copy template files to working directories
2. Replace placeholder values with actual secrets
3. Encrypt sensitive files: `ansible-vault encrypt file.yml`
4. Test configurations in development environment

## Documentation

See `SECURITY.md` for detailed security guidelines.
EOF
    
    check_pass "Created README file"
}

create_secrets_security_documentation() {
    cat > "SECURITY.md" << 'EOF'
# Security Guidelines

## Important Security Practices

1. **Never commit actual secrets to git**
2. **Use Ansible Vault for sensitive data**
3. **Rotate credentials regularly**
4. **Use strong, unique passwords**
5. **Enable 2FA where possible**

## Repository Structure

- `credentials/` - Database and service credentials
- `certificates/` - SSL/TLS certificates
- `keys/` - SSH keys and API keys
- `templates/` - Template files for reference

## Usage

1. Copy template files
2. Replace placeholder values
3. Encrypt with ansible-vault
4. Test in development first
EOF
    
    check_pass "Created security documentation"
}

create_secrets_usage_examples() {
    mkdir -p "examples"
    
    cat > "examples/encrypt-file.sh" << 'EOF'
#!/usr/bin/env bash
# Example: Encrypt a secrets file with Ansible Vault

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <file-to-encrypt>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found"
    exit 1
fi

echo "Encrypting $FILE with Ansible Vault..."
ansible-vault encrypt "$FILE"
echo "File encrypted successfully"
EOF
    
    chmod +x "examples/encrypt-file.sh"
    check_pass "Created usage examples"
}

handle_existing_secrets_directory() {
    local repo_path="$1"
    
    print_warning "Directory $repo_path already exists"
    
    read -p "Continue and overwrite? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup aborted by user"
        exit 0
    fi
    
    print_info "Proceeding with existing directory"
}

# ==============================================================================
# Cleanup Functions
# ==============================================================================

cleanup_setup_artifacts() {
    echo "→ Cleaning up setup artifacts"
    
    # Remove temporary files
    find . -name "*.tmp" -type f -delete 2>/dev/null || true
    find . -name ".setup-*" -type f -delete 2>/dev/null || true
    
    check_pass "Cleaned up temporary setup files"
}
# ==============================================================================
# Secrets Repository Integration Functions
# ==============================================================================

create_sanitized_examples() {
    local files_to_migrate=("$@")
    
    echo "→ Creating sanitized example files"
    
    for file in "${files_to_migrate[@]}"; do
        local example_file="${file}.example"
        
        if [ -f "$file" ] && [ ! -f "$example_file" ]; then
            echo "  Creating sanitized example: $example_file"
            
            # Create sanitized version
            cp "$file" "$example_file"
            
            # Replace real patterns with placeholders
            sed -i.bak \
                -e 's/xoxb-[0-9]\{10,\}-[0-9]\{10,\}-[A-Za-z0-9]\{24\}/PLACEHOLDER_SLACK_TOKEN_PATTERN/g' \
                -e 's/https:\/\/hooks\.slack\.com\/services\/[A-Z0-9]\{9\}\/[A-Z0-9]\{9\}\/[A-Za-z0-9]\{24\}/https:\/\/hooks.slack.com\/services\/PLACEHOLDER\/WEBHOOK\/URL/g' \
                -e 's/sk_live_[A-Za-z0-9]\{24\}/PLACEHOLDER_STRIPE_LIVE_KEY/g' \
                -e 's/sk_test_[A-Za-z0-9]\{24\}/PLACEHOLDER_STRIPE_TEST_KEY/g' \
                -e 's/pk_live_[A-Za-z0-9]\{24\}/PLACEHOLDER_STRIPE_PUBLIC_KEY/g' \
                -e 's/pk_test_[A-Za-z0-9]\{24\}/PLACEHOLDER_STRIPE_PUBLIC_KEY/g' \
                "$example_file"
            
            # Remove backup file
            rm -f "${example_file}.bak"
            
            # Add header comment
            local temp_file
            temp_file=$(mktemp)
            cat > "$temp_file" << 'EOF'
#!/usr/bin/env bash
# ==============================================================================
# SANITIZED EXAMPLE FILE
# ==============================================================================
# This is a sanitized example with placeholder patterns.
# 
# To use real patterns for testing:
# 1. Run: make setup-secrets (requires access to private ahab-secrets repo)
# 2. Or manually replace PLACEHOLDER_* values with real patterns
# 
# See: docs/SECRETS_ARCHITECTURE.md for details
# ==============================================================================

EOF
            cat "$example_file" >> "$temp_file"
            mv "$temp_file" "$example_file"
            
            check_pass "Created $example_file"
        fi
    done
}

setup_git_submodule() {
    local repo_url="$1"
    local submodule_path="$2"
    
    echo "→ Setting up git submodule: $submodule_path"
    
    if [ -d "$submodule_path" ]; then
        echo "  Submodule directory already exists, checking if it's a submodule..."
        
        if git submodule status "$submodule_path" >/dev/null 2>&1; then
            check_pass "Submodule already configured: $submodule_path"
            
            # Update submodule
            echo "  Updating submodule..."
            git submodule update --init --recursive "$submodule_path"
            return 0
        else
            echo "  Directory exists but is not a submodule, backing up..."
            mv "$submodule_path" "${submodule_path}.backup.$(date +%s)"
        fi
    fi
    
    # Add as submodule
    echo "  Adding as git submodule..."
    if git submodule add "$repo_url" "$submodule_path"; then
        check_pass "Added submodule: $submodule_path"
    else
        check_fail "Failed to add submodule"
        return 1
    fi
    
    # Initialize and update
    echo "  Initializing submodule..."
    git submodule update --init --recursive "$submodule_path"
    
    check_pass "Submodule setup complete: $submodule_path"
}
migrate_files_to_secrets_repo() {
    local secrets_dir="$1"
    local backup_dir="$2"
    shift 2
    local files_to_migrate=("$@")
    
    echo "→ Migrating files with real patterns to secrets repository"
    
    if [ ! -d "$secrets_dir" ]; then
        echo "  ERROR: Secrets directory not found: $secrets_dir"
        return 1
    fi
    
    # Create backup
    mkdir -p "$backup_dir"
    
    for file in "${files_to_migrate[@]}"; do
        if [ -f "$file" ]; then
            echo "  Migrating: $file"
            
            # Create backup
            cp "$file" "$backup_dir/"
            
            # Create directory structure in secrets repo
            local secrets_file="$secrets_dir/$file"
            local secrets_file_dir
            secrets_file_dir=$(dirname "$secrets_file")
            mkdir -p "$secrets_file_dir"
            
            # Move file to secrets repo
            mv "$file" "$secrets_file"
            
            check_pass "Moved $file to $secrets_file"
        else
            echo "  WARNING: File not found: $file"
        fi
    done
}
show_secrets_repo_usage() {
    cat << 'EOF'
Setup Secrets Repository Integration

USAGE:
    ./scripts/setup-secrets-repo.sh [command]

COMMANDS:
    setup       Set up complete secrets repository integration (default)
    check       Check access to private secrets repository
    migrate     Migrate files to secrets repository (requires setup first)
    validate    Validate current setup
    help        Show this help message

EXAMPLES:
    ./scripts/setup-secrets-repo.sh           # Full setup
    ./scripts/setup-secrets-repo.sh check     # Check access only
    ./scripts/setup-secrets-repo.sh validate  # Validate setup

REQUIREMENTS:
    - Access to private ahab-secrets repository
    - Git configured with SSH keys or personal access token
    - Run from ahab repository root directory

For more information, see: docs/SECRETS_ARCHITECTURE.md
EOF
}