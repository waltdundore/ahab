#!/usr/bin/env bash
# ==============================================================================
# Git Publishing Library - Shared Across All Repositories
# ==============================================================================
# Provides standardized git publishing commands following development principles
# Used by: ahab, ahab-gui, waltdundore.github.io
# ==============================================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ==============================================================================
# Configuration
# ==============================================================================

# Default branch for publishing
DEFAULT_BRANCH="${DEFAULT_BRANCH:-dev}"

# Repository-specific configurations
# Get configured branches for current repository
get_repo_branches() {
    local repo_name="$(get_repo_name)"
    case "$repo_name" in
        "ahab")
            echo "dev prod master workstation milestone-system-v1"
            ;;
        "ahab-gui")
            echo "main"
            ;;
        "waltdundore.github.io")
            echo "production main"
            ;;
        *)
            echo "main"  # Default fallback
            ;;
    esac
}

# ==============================================================================
# Core Functions
# ==============================================================================

# Get repository name from current directory
get_repo_name() {
    local repo_path="$(pwd)"
    basename "$repo_path"
}

# This function is now defined above in the repository-specific configurations section

# Check if branch exists locally
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch"
}

# Check if remote exists
remote_exists() {
    local remote="${1:-origin}"
    git remote get-url "$remote" >/dev/null 2>&1
}

# Handle GitHub push protection for fake secrets
handle_push_protection() {
    local branch="$1"
    local push_output="$2"
    
    if echo "$push_output" | grep -q "push declined due to repository rule violations"; then
        print_warning "GitHub push protection detected fake secrets in documentation"
        echo ""
        echo "This is expected for repositories with security documentation."
        echo "The fake secrets are intentional examples for testing and documentation."
        echo ""
        echo "Options:"
        echo "1. Use GitHub web interface to allow these specific fake secrets"
        echo "2. Skip this branch (recommended for documentation branches)"
        echo "3. Remove fake secrets from documentation (not recommended)"
        echo ""
        
        # Extract the GitHub URLs for allowing secrets
        if echo "$push_output" | grep -q "https://github.com.*security/secret-scanning/unblock-secret"; then
            echo "GitHub URLs to allow fake secrets:"
            echo "$push_output" | grep -o "https://github.com[^[:space:]]*unblock-secret[^[:space:]]*" | sort -u
            echo ""
        fi
        
        return 1
    fi
    return 0
}

# ==============================================================================
# Publishing Functions
# ==============================================================================

# Publish single branch with transparency
git_publish_branch() {
    local branch="${1:-$DEFAULT_BRANCH}"
    local remote="${2:-origin}"
    
    print_section "Publishing Branch: $branch"
    
    # Validate inputs
    if [ -z "$branch" ]; then
        print_error "Branch name required"
        return 1
    fi
    
    # Check if branch exists
    if ! branch_exists "$branch"; then
        print_error "Branch '$branch' does not exist locally"
        echo "Available branches:"
        git branch --format='  %(refname:short)'
        return 1
    fi
    
    # Check if remote exists
    if ! remote_exists "$remote"; then
        print_error "Remote '$remote' does not exist"
        echo "Available remotes:"
        git remote -v
        return 1
    fi
    
    # Show what we're doing (transparency principle)
    print_info "→ Running: git push $remote $branch"
    print_info "   Purpose: Publish $branch to GitHub for visibility and collaboration"
    echo ""
    
    # Attempt to push
    local push_output
    if push_output=$(git push "$remote" "$branch" 2>&1); then
        print_success "✓ Successfully published $branch to $remote"
        return 0
    else
        print_error "✗ Failed to publish $branch to $remote"
        echo ""
        echo "Error output:"
        echo "$push_output"
        echo ""
        
        # Handle specific error cases
        if handle_push_protection "$branch" "$push_output"; then
            return 1
        fi
        
        return 1
    fi
}

# Publish all configured branches for current repository
git_publish_all() {
    local remote="${1:-origin}"
    local repo_name="$(get_repo_name)"
    local branches="$(get_repo_branches)"
    
    print_section "Publishing All Branches for $repo_name"
    
    if [ -z "$branches" ]; then
        print_warning "No branches configured for repository: $repo_name"
        echo "Add configuration to REPO_CONFIGS in git-publish-common.sh"
        return 1
    fi
    
    # Check if remote exists
    if ! remote_exists "$remote"; then
        print_error "Remote '$remote' does not exist"
        echo "Available remotes:"
        git remote -v
        return 1
    fi
    
    print_info "Configured branches: $branches"
    echo ""
    
    local success_count=0
    local total_count=0
    local failed_branches=()
    
    # Publish each branch
    for branch in $branches; do
        ((total_count++))
        
        if branch_exists "$branch"; then
            if git_publish_branch "$branch" "$remote"; then
                ((success_count++))
            else
                failed_branches+=("$branch")
            fi
        else
            print_warning "Branch '$branch' does not exist locally - skipping"
            failed_branches+=("$branch (not found)")
        fi
        echo ""
    done
    
    # Summary
    print_section "Publishing Summary"
    print_info "Repository: $repo_name"
    print_info "Remote: $remote"
    print_info "Success: $success_count/$total_count branches"
    
    if [ ${#failed_branches[@]} -gt 0 ]; then
        print_warning "Failed branches:"
        for branch in "${failed_branches[@]}"; do
            echo "  - $branch"
        done
        return 1
    else
        print_success "✓ All branches published successfully"
        return 0
    fi
}

# Force publish (bypasses some safety checks)
git_publish_force() {
    local branch="${1:-$DEFAULT_BRANCH}"
    local remote="${2:-origin}"
    
    print_section "Force Publishing Branch: $branch"
    print_warning "Using force push - this can overwrite remote history"
    
    # Show what we're doing
    print_info "→ Running: git push --force-with-lease $remote $branch"
    print_info "   Purpose: Force publish $branch (safer than --force)"
    echo ""
    
    # Confirm with user
    read -p "Are you sure you want to force push? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Force push cancelled"
        return 0
    fi
    
    # Force push with lease (safer than --force)
    if git push --force-with-lease "$remote" "$branch"; then
        print_success "✓ Force published $branch to $remote"
        return 0
    else
        print_error "✗ Force push failed"
        return 1
    fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Show current repository status
git_publish_status() {
    local repo_name="$(get_repo_name)"
    local branches="$(get_repo_branches)"
    
    print_section "Git Publishing Status for $repo_name"
    
    # Show current branch
    local current_branch="$(git branch --show-current)"
    print_info "Current branch: $current_branch"
    echo ""
    
    # Show configured branches and their status
    print_info "Configured branches:"
    for branch in $branches; do
        if branch_exists "$branch"; then
            local ahead_behind
            if ahead_behind=$(git rev-list --left-right --count "origin/$branch...$branch" 2>/dev/null); then
                local ahead=$(echo "$ahead_behind" | cut -f1)
                local behind=$(echo "$ahead_behind" | cut -f2)
                
                if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
                    echo "  ✓ $branch (up to date)"
                elif [ "$ahead" -gt 0 ] && [ "$behind" -eq 0 ]; then
                    echo "  ↑ $branch (ahead by $ahead commits)"
                elif [ "$ahead" -eq 0 ] && [ "$behind" -gt 0 ]; then
                    echo "  ↓ $branch (behind by $behind commits)"
                else
                    echo "  ↕ $branch (ahead by $ahead, behind by $behind)"
                fi
            else
                echo "  ? $branch (not tracked remotely)"
            fi
        else
            echo "  ✗ $branch (does not exist locally)"
        fi
    done
    echo ""
    
    # Show remotes
    print_info "Configured remotes:"
    git remote -v | sed 's/^/  /'
}

# Sync repository (pull latest changes)
git_publish_sync() {
    local branch="${1:-$DEFAULT_BRANCH}"
    local remote="${2:-origin}"
    
    print_section "Syncing Branch: $branch"
    
    # Show what we're doing
    print_info "→ Running: git pull --rebase $remote $branch"
    print_info "   Purpose: Sync local branch with remote changes"
    echo ""
    
    # Switch to branch if needed
    local current_branch="$(git branch --show-current)"
    if [ "$current_branch" != "$branch" ]; then
        print_info "Switching to branch: $branch"
        git checkout "$branch" || return 1
    fi
    
    # Pull with rebase
    if git pull --rebase "$remote" "$branch"; then
        print_success "✓ Successfully synced $branch from $remote"
        return 0
    else
        print_error "✗ Failed to sync $branch from $remote"
        return 1
    fi
}

# ==============================================================================
# Help Function
# ==============================================================================

git_publish_help() {
    cat << 'EOF'
Git Publishing Library - Shared Functions

USAGE:
    source scripts/lib/git-publish-common.sh
    git_publish_branch [branch] [remote]
    git_publish_all [remote]

FUNCTIONS:
    git_publish_branch <branch> [remote]  - Publish single branch (default: dev)
    git_publish_all [remote]              - Publish all configured branches
    git_publish_force <branch> [remote]   - Force publish branch (use carefully)
    git_publish_status                    - Show repository publishing status
    git_publish_sync [branch] [remote]    - Sync branch with remote
    git_publish_help                      - Show this help

EXAMPLES:
    git_publish_branch                    # Publish dev branch to origin
    git_publish_branch prod               # Publish prod branch to origin
    git_publish_all                       # Publish all configured branches
    git_publish_status                    # Show current status

CONFIGURATION:
    DEFAULT_BRANCH: Default branch for publishing (default: dev)
    REPO_CONFIGS: Branch configuration per repository

TRANSPARENCY PRINCIPLE:
    All functions show what commands they're running and why.
    This follows our development principle of education through transparency.

SAFETY FEATURES:
    - Validates branch and remote existence
    - Handles GitHub push protection gracefully
    - Uses --force-with-lease instead of --force
    - Provides clear error messages and recovery options
EOF
}

# ==============================================================================
# Validation
# ==============================================================================

# Validate that we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    print_error "Not in a git repository"
    return 1 2>/dev/null || exit 1
fi

# Export functions for use in other scripts
export -f git_publish_branch
export -f git_publish_all
export -f git_publish_force
export -f git_publish_status
export -f git_publish_sync
export -f git_publish_help