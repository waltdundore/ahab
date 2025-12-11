#!/usr/bin/env bash
# ==============================================================================
# Setup Secrets Repository Integration
# ==============================================================================
# Sets up the private ahab-secrets repository as a git submodule and integrates
# real secret patterns for security testing while maintaining public examples
# ==============================================================================

set -euo pipefail

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ==============================================================================
# Configuration
# ==============================================================================

SECRETS_REPO_URL="https://github.com/waltdundore/ahab-secrets.git"
SECRETS_DIR="secrets"
BACKUP_DIR=".secrets-migration-backup"

# Files to migrate to secrets repository
declare -a FILES_TO_MIGRATE=(
    "tests/property/test-secret-detection.sh"
    "docs/SECRETS_REPOSITORY.md"
)

# ==============================================================================
# Helper Functions
# ==============================================================================

check_git_repo() {
    if [ ! -d ".git" ]; then
        die "Not in a git repository. Run this from the ahab repository root."
    fi
}

check_secrets_repo_access() {
    print_info "Checking access to private secrets repository..."
    
    if git ls-remote "$SECRETS_REPO_URL" >/dev/null 2>&1; then
        print_success "✓ Access to ahab-secrets repository confirmed"
        return 0
    else
        print_error "✗ Cannot access ahab-secrets repository"
        echo ""
        echo "This could mean:"
        echo "  1. You don't have access to the private repository"
        echo "  2. Your GitHub authentication is not set up"
        echo "  3. The repository doesn't exist yet"
        echo ""
        echo "To get access:"
        echo "  1. Ask the repository owner for access"
        echo "  2. Set up GitHub SSH keys or personal access token"
        echo "  3. Test access: git ls-remote $SECRETS_REPO_URL"
        echo ""
        return 1
    fi
}

setup_submodule() {
    print_section "Setting up ahab-secrets as git submodule"
    
    if [ -d "$SECRETS_DIR" ]; then
        print_info "Secrets directory already exists, checking if it's a submodule..."
        
        if git submodule status "$SECRETS_DIR" >/dev/null 2>&1; then
            print_success "✓ Secrets submodule already configured"
            
            # Update submodule
            print_info "Updating submodule..."
            git submodule update --init --recursive "$SECRETS_DIR"
            return 0
        else
            print_warning "Secrets directory exists but is not a submodule"
            print_info "Moving existing directory to backup..."
            mv "$SECRETS_DIR" "${SECRETS_DIR}.backup.$(date +%s)"
        fi
    fi
    
    # Add as submodule
    print_info "Adding ahab-secrets as git submodule..."
    git submodule add "$SECRETS_REPO_URL" "$SECRETS_DIR"
    
    # Initialize and update
    print_info "Initializing submodule..."
    git submodule update --init --recursive "$SECRETS_DIR"
    
    print_success "✓ Secrets repository set up as submodule"
}

create_sanitized_examples() {
    print_section "Creating sanitized example files"
    
    for file in "${FILES_TO_MIGRATE[@]}"; do
        local example_file="${file}.example"
        
        if [ -f "$file" ] && [ ! -f "$example_file" ]; then
            print_info "Creating sanitized example: $example_file"
            
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
            local temp_file=$(mktemp)
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
            
            print_success "✓ Created $example_file"
        fi
    done
}

migrate_files_to_secrets() {
    print_section "Migrating files with real patterns to secrets repository"
    
    if [ ! -d "$SECRETS_DIR" ]; then
        print_error "Secrets directory not found. Run setup first."
        return 1
    fi
    
    # Create backup
    mkdir -p "$BACKUP_DIR"
    
    for file in "${FILES_TO_MIGRATE[@]}"; do
        if [ -f "$file" ]; then
            print_info "Migrating: $file"
            
            # Create backup
            cp "$file" "$BACKUP_DIR/"
            
            # Create directory structure in secrets repo
            local secrets_file="$SECRETS_DIR/$file"
            local secrets_dir=$(dirname "$secrets_file")
            mkdir -p "$secrets_dir"
            
            # Move file to secrets repo
            mv "$file" "$secrets_file"
            
            print_success "✓ Moved $file to $secrets_file"
        else
            print_warning "File not found: $file"
        fi
    done
}

setup_symlinks() {
    print_section "Setting up symlinks for development"
    
    for file in "${FILES_TO_MIGRATE[@]}"; do
        local secrets_file="$SECRETS_DIR/$file"
        
        if [ -f "$secrets_file" ] && [ ! -f "$file" ]; then
            print_info "Creating symlink: $file -> $secrets_file"
            ln -sf "../$secrets_file" "$file"
            print_success "✓ Created symlink for $file"
        fi
    done
}

update_gitignore() {
    print_section "Updating .gitignore for real pattern files"
    
    local gitignore_additions=""
    
    for file in "${FILES_TO_MIGRATE[@]}"; do
        if ! grep -q "^$file$" .gitignore 2>/dev/null; then
            gitignore_additions="$gitignore_additions$file\n"
        fi
    done
    
    if [ -n "$gitignore_additions" ]; then
        print_info "Adding files to .gitignore..."
        echo "" >> .gitignore
        echo "# Real secret pattern files (symlinked from private repo)" >> .gitignore
        echo -e "$gitignore_additions" >> .gitignore
        print_success "✓ Updated .gitignore"
    else
        print_info "✓ .gitignore already up to date"
    fi
}

commit_changes() {
    print_section "Committing changes"
    
    # Add all changes
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        print_info "No changes to commit"
        return 0
    fi
    
    # Commit changes
    git commit -m "Set up secrets repository integration

- Add ahab-secrets as git submodule
- Create sanitized example files with placeholder patterns
- Set up symlinks for development with real patterns
- Update .gitignore for real pattern files

This resolves GitHub push protection issues by separating
real secret patterns (private repo) from sanitized examples (public repo).

See: docs/SECRETS_ARCHITECTURE.md for details"
    
    print_success "✓ Changes committed"
}

validate_setup() {
    print_section "Validating setup"
    
    local validation_passed=true
    
    # Check submodule
    if git submodule status "$SECRETS_DIR" >/dev/null 2>&1; then
        print_success "✓ Secrets submodule configured correctly"
    else
        print_error "✗ Secrets submodule not configured"
        validation_passed=false
    fi
    
    # Check example files
    for file in "${FILES_TO_MIGRATE[@]}"; do
        local example_file="${file}.example"
        if [ -f "$example_file" ]; then
            print_success "✓ Example file exists: $example_file"
        else
            print_error "✗ Example file missing: $example_file"
            validation_passed=false
        fi
    done
    
    # Check symlinks (if secrets repo accessible)
    if [ -d "$SECRETS_DIR" ]; then
        for file in "${FILES_TO_MIGRATE[@]}"; do
            if [ -L "$file" ]; then
                print_success "✓ Symlink exists: $file"
            else
                print_warning "⚠ Symlink missing: $file (will use example file)"
            fi
        done
    fi
    
    if [ "$validation_passed" = true ]; then
        print_success "✓ Setup validation passed"
        return 0
    else
        print_error "✗ Setup validation failed"
        return 1
    fi
}

show_usage() {
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

# ==============================================================================
# Main Functions
# ==============================================================================

setup_full() {
    print_section "Setting up secrets repository integration"
    
    check_git_repo
    
    if check_secrets_repo_access; then
        setup_submodule
        create_sanitized_examples
        migrate_files_to_secrets
        setup_symlinks
        update_gitignore
        commit_changes
        validate_setup
        
        print_section "Setup Complete"
        print_success "✓ Secrets repository integration set up successfully"
        echo ""
        echo "What was done:"
        echo "  - Added ahab-secrets as git submodule"
        echo "  - Created sanitized example files"
        echo "  - Migrated real patterns to private repository"
        echo "  - Set up symlinks for development"
        echo "  - Updated .gitignore"
        echo ""
        echo "Next steps:"
        echo "  - Run: make test-security-real (to test with real patterns)"
        echo "  - Or: make test-security-sanitized (to test with examples)"
        echo ""
    else
        print_warning "Cannot access private repository, setting up example files only"
        create_sanitized_examples
        update_gitignore
        
        echo ""
        echo "Limited setup completed:"
        echo "  - Created sanitized example files"
        echo "  - Updated .gitignore"
        echo ""
        echo "To complete setup:"
        echo "  1. Get access to ahab-secrets repository"
        echo "  2. Run this script again"
        echo ""
    fi
}

check_access() {
    print_section "Checking secrets repository access"
    check_git_repo
    check_secrets_repo_access
}

migrate_only() {
    print_section "Migrating files to secrets repository"
    check_git_repo
    migrate_files_to_secrets
    setup_symlinks
    update_gitignore
    commit_changes
}

validate_only() {
    print_section "Validating secrets repository setup"
    check_git_repo
    validate_setup
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    local command="${1:-setup}"
    
    case "$command" in
        "setup")
            setup_full
            ;;
        "check")
            check_access
            ;;
        "migrate")
            migrate_only
            ;;
        "validate")
            validate_only
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"