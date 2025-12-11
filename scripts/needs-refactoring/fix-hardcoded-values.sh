#!/usr/bin/env bash
# ==============================================================================
# Fix Hardcoded Values Script
# ==============================================================================
# Systematically replaces hardcoded values with configuration variables
#
# This script:
# 1. Reads configuration from ahab.conf
# 2. Identifies hardcoded values that should be variables
# 3. Replaces them with proper variable references
# 4. Updates scripts to use get_config() function
#
# Usage:
#   ./fix-hardcoded-values.sh [--dry-run] [--category CATEGORY]
#
# Categories:
#   usernames  - Replace hardcoded usernames
#   paths      - Replace hardcoded paths
#   urls       - Replace hardcoded URLs
#   all        - Fix all categories (default)
# ==============================================================================

set -e

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Configuration
DRY_RUN=false
CATEGORY="all"
FIXES_APPLIED=0
BACKUP_DIR="hardcoded-fixes-backup-$(date +%Y%m%d-%H%M%S)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --help)
            grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            die "Unknown option: $1. Run '$0 --help' for usage information"
            ;;
    esac
done

print_header() {
    echo "=============================================="
    echo "Fix Hardcoded Values"
    echo "=============================================="
    echo ""
    echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "APPLY FIXES")"
    echo "Category: $CATEGORY"
    echo ""
}

create_backup() {
    local file="$1"
    
    if [ "$DRY_RUN" = false ]; then
        # Create backup directory if it doesn't exist
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        
        # Copy original file to backup
        cp "$file" "$BACKUP_DIR/$file"
    fi
}

apply_fix() {
    local file="$1"
    local old_pattern="$2"
    local new_pattern="$3"
    local description="$4"
    
    if grep -q "$old_pattern" "$file" 2>/dev/null; then
        echo "  → Fixing: $description"
        echo "    File: $file"
        echo "    Pattern: $old_pattern → $new_pattern"
        
        if [ "$DRY_RUN" = false ]; then
            create_backup "$file"
            sed -i.bak "s|$old_pattern|$new_pattern|g" "$file"
            rm -f "$file.bak"
        fi
        
        ((FIXES_APPLIED++))
        echo ""
    fi
}

fix_usernames() {
    print_info "Fixing hardcoded usernames..."
    
    # Get GitHub user from config
    local github_user
    github_user=$(get_config "GITHUB_USER" "waltdundore")
    
    # Skip if already using variable
    if [ "$github_user" = "\${GITHUB_USER}" ]; then
        print_info "GitHub user already uses variable, skipping username fixes"
        return
    fi
    
    # Files to fix (excluding documentation and examples)
    local files_to_fix=(
        "bootstrap.sh"
        "ahab.conf"
        "scripts/lib/common.sh"
    )
    
    for file in "${files_to_fix[@]}"; do
        if [ -f "$file" ]; then
            # Replace hardcoded GitHub username with variable
            apply_fix "$file" \
                "waltdundore" \
                "\${GITHUB_USER}" \
                "Replace hardcoded username with variable"
            
            # Replace hardcoded GitHub URLs
            apply_fix "$file" \
                "git@github.com:waltdundore/" \
                "git@github.com:\${GITHUB_USER}/" \
                "Replace hardcoded GitHub URL with variable"
            
            apply_fix "$file" \
                "https://github.com/waltdundore/" \
                "https://github.com/\${GITHUB_USER}/" \
                "Replace hardcoded GitHub HTTPS URL with variable"
        fi
    done
}

fix_paths() {
    print_info "Fixing hardcoded paths..."
    
    # Files to fix
    local files_to_fix=(
        "ahab.conf"
        "bootstrap.sh"
    )
    
    for file in "${files_to_fix[@]}"; do
        if [ -f "$file" ]; then
            # Replace hardcoded /Users/username paths
            apply_fix "$file" \
                "/Users/waltdundore/" \
                "\${HOME}/" \
                "Replace hardcoded user path with HOME variable"
            
            # Replace hardcoded base directory paths
            apply_fix "$file" \
                "/Users/waltdundore/git/AHAB" \
                "\${BASE_DIR}" \
                "Replace hardcoded base directory with variable"
        fi
    done
}

fix_urls() {
    print_info "Fixing hardcoded URLs..."
    
    # Files to fix (excluding documentation)
    local files_to_fix=(
        "ahab.conf"
        "scripts/lib/common.sh"
    )
    
    for file in "${files_to_fix[@]}"; do
        if [ -f "$file" ]; then
            # Replace hardcoded repository URLs
            apply_fix "$file" \
                "https://github.com/waltdundore" \
                "\${MODULE_REPO_BASE}" \
                "Replace hardcoded repository base URL with variable"
            
            # Replace hardcoded website URLs
            apply_fix "$file" \
                "https://waltdundore.github.io" \
                "https://\${GITHUB_USER}.github.io" \
                "Replace hardcoded website URL with variable"
        fi
    done
}

update_scripts_to_use_config() {
    print_info "Updating scripts to use get_config() function..."
    
    # Find shell scripts that might need updating
    while IFS= read -r -d '' script; do
        if [ -f "$script" ] && [[ "$script" == *.sh ]]; then
            # Check if script uses hardcoded values that should be from config
            if grep -q "GITHUB_USER=" "$script" && ! grep -q "get_config" "$script"; then
                echo "  → Updating script to use get_config(): $script"
                
                if [ "$DRY_RUN" = false ]; then
                    create_backup "$script"
                    
                    # Add get_config usage for GITHUB_USER
                    sed -i.bak '/GITHUB_USER=/c\
GITHUB_USER=$(get_config "GITHUB_USER" "waltdundore")' "$script"
                    rm -f "$script.bak"
                fi
                
                ((FIXES_APPLIED++))
            fi
        fi
    done < <(find scripts/ -name "*.sh" -type f -print0 2>/dev/null || true)
}

validate_fixes() {
    print_info "Validating fixes..."
    
    # Check that configuration variables are properly defined
    local required_vars=("GITHUB_USER" "BASE_DIR" "MODULE_REPO_BASE")
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" ahab.conf 2>/dev/null; then
            print_warning "Configuration variable $var not found in ahab.conf"
            echo "  Add: $var=<appropriate_value>"
        else
            print_success "Configuration variable $var found in ahab.conf"
        fi
    done
    
    # Check that scripts source common.sh
    while IFS= read -r -d '' script; do
        if [ -f "$script" ] && [[ "$script" == *.sh ]] && [[ "$script" != */lib/* ]]; then
            if grep -q "get_config" "$script" && ! grep -q "source.*common.sh" "$script"; then
                print_warning "Script uses get_config but doesn't source common.sh: $script"
            fi
        fi
    done < <(find scripts/ -name "*.sh" -type f -print0 2>/dev/null || true)
}

print_summary() {
    echo "=============================================="
    echo "Fix Summary"
    echo "=============================================="
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN - No changes applied"
        echo "Found $FIXES_APPLIED potential fixes"
        echo ""
        echo "To apply fixes, run without --dry-run"
    else
        echo "Applied $FIXES_APPLIED fixes"
        echo ""
        if [ $FIXES_APPLIED -gt 0 ]; then
            echo "Backup created: $BACKUP_DIR"
            echo ""
            echo "Next steps:"
            echo "1. Test the changes: make test"
            echo "2. Verify configuration: make audit-hardcoded"
            echo "3. If issues, restore from backup"
        else
            echo "No fixes needed - all values already use variables"
        fi
    fi
    echo ""
}

# Main execution
main() {
    print_header
    
    case "$CATEGORY" in
        usernames)
            fix_usernames
            ;;
        paths)
            fix_paths
            ;;
        urls)
            fix_urls
            ;;
        all)
            fix_usernames
            fix_paths
            fix_urls
            update_scripts_to_use_config
            ;;
        *)
            die "Unknown category: $CATEGORY. Use: usernames, paths, urls, or all"
            ;;
    esac
    
    if [ "$DRY_RUN" = false ] && [ $FIXES_APPLIED -gt 0 ]; then
        validate_fixes
    fi
    
    print_summary
}

# Run main function
main "$@"