#!/usr/bin/env bash
# ==============================================================================
# Setup Secrets Repository Integration
# ==============================================================================
# Sets up the private ahab-secrets repository as a git submodule and integrates
# real secret patterns for security testing while maintaining public examples.
#
# This is the orchestrator; config and implementation functions live in
# scripts/lib/secrets-repo-setup.sh (kept under the 200-line script rule).
# ==============================================================================

set -euo pipefail

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/secrets-repo-setup.sh"

# ==============================================================================
# Helper Functions
# ==============================================================================

check_git_repo() {
    if [ ! -d ".git" ]; then
        die "Not in a git repository. Run this from the ahab repository root."
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
