#!/usr/bin/env bash
# ==============================================================================
# Setup Secrets Repository (NASA Rule #4 Compliant)
# ==============================================================================
# Creates ahab-secrets repository structure with secure defaults
#
# Usage:
#   ./scripts/setup-secrets-repository.sh
#   make setup-secrets
#
# Exit Codes:
#   0 - Setup completed successfully
#   1 - Setup failed
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/setup-common.sh
source "$SCRIPT_DIR/lib/setup-common.sh"

# Configuration
readonly SECRETS_REPO_NAME="ahab-secrets"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_ROOT
readonly SECRETS_REPO_PATH="$PROJECT_ROOT/../$SECRETS_REPO_NAME"

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "AHAB SECRETS REPOSITORY SETUP"
    
    echo "Setting up secrets repository structure..."
    echo "Target directory: $SECRETS_REPO_PATH"
    echo ""
    
    # Validate prerequisites
    if ! validate_setup_prerequisites; then
        print_error "Prerequisites not met"
        exit 1
    fi
    
    # Check for existing directory
    if [ -d "$SECRETS_REPO_PATH" ]; then
        handle_existing_secrets_directory "$SECRETS_REPO_PATH"
    fi
    
    # Create repository structure
    print_section "Creating Repository Structure"
    create_secrets_repository_structure "$SECRETS_REPO_PATH"
    
    # Initialize git repository
    print_section "Initializing Git Repository"
    initialize_secrets_git_repository "$SECRETS_REPO_PATH"
    
    # Create documentation
    print_section "Creating Documentation"
    cd "$SECRETS_REPO_PATH"
    create_secrets_readme
    create_secrets_security_documentation
    create_secrets_usage_examples
    
    print_success "Secrets repository setup completed successfully"
    print_info "Repository created at: $SECRETS_REPO_PATH"
    print_info "Next steps:"
    print_info "  1. cd $SECRETS_REPO_PATH"
    print_info "  2. Review and customize templates"
    print_info "  3. Add your actual secrets"
    print_info "  4. Commit and push to secure remote"
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi