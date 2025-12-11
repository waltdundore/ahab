#!/bin/bash
# Pre-Release Checklist Validator: Documentation
# Purpose: Verify documentation accuracy and completeness
#
# Checks:
# - All docs in correct locations per workspace organization
# - All docs have required format (date, status, audience)
# - Cross-references are valid and not broken
# - Technical accuracy (OS versions, features)
#
# Requirements: 2.1, 2.3, 2.4, 2.5

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Project root
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ============================================================================
# Configuration
# ============================================================================

# Technical documentation keywords (indicate doc should be in ahab/docs/)
TECHNICAL_KEYWORDS=(
    "architecture"
    "API"
    "implementation"
    "module"
    "playbook"
    "ansible"
    "vagrant"
    "docker"
    "development"
    "testing"
    "property-based"
    "integration test"
    "unit test"
    "code quality"
    "standards compliance"
    "technical specification"
)

# Outdated OS versions that should not appear
OUTDATED_OS_VERSIONS=(
    "Rocky Linux 9"
    "Fedora 40"
    "Fedora 41"
    "Fedora 42"
    "Debian 12"
    "Ubuntu 22.04"
    "Ubuntu 23"
)

# Current supported OS versions
CURRENT_OS_VERSIONS=(
    "Fedora 43"
    "Debian 13"
    "Ubuntu 24.04"
)

# ============================================================================
# Helper Functions
# ============================================================================

# Check if file is technical documentation
# Usage: is_technical_doc "file.md"
is_technical_doc() {
    local file="$1"
    local content
    content=$(head -n 50 "$file" 2>/dev/null || echo "")
    
    # Check for technical keywords in first 50 lines
    for keyword in "${TECHNICAL_KEYWORDS[@]}"; do
        if echo "$content" | grep -qi "$keyword"; then
            return 0
        fi
    done
    
    return 1
}

# Check if file has required frontmatter
# Usage: has_required_frontmatter "file.md"
has_required_frontmatter() {
    local file="$1"
    
    # Read first 20 lines
    local header
    header=$(head -n 20 "$file" 2>/dev/null || echo "")
    
    # Check for date field
    if ! echo "$header" | grep -qi "^\*\*Date\*\*:\|^Date:"; then
        return 1
    fi
    
    # Check for status field
    if ! echo "$header" | grep -qi "^\*\*Status\*\*:\|^Status:"; then
        return 1
    fi
    
    # Check for audience field
    if ! echo "$header" | grep -qi "^\*\*Audience\*\*:\|^Audience:"; then
        return 1
    fi
    
    return 0
}

# Extract links from markdown file
# Usage: extract_links "file.md"
extract_links() {
    local file="$1"
    
    # Extract markdown links: [text](url)
    # Use sed instead of grep -P for macOS compatibility
    grep -o '\[[^]]*\]([^)]*)' "$file" 2>/dev/null | \
        sed 's/.*(\([^)]*\)).*/\1/'
}

# Check if link is valid
# Usage: is_valid_link "link" "source_file"
is_valid_link() {
    local link="$1"
    local source_file="$2"
    local source_dir
    source_dir=$(dirname "$source_file")
    
    # Skip external URLs (http/https)
    if [[ "$link" =~ ^https?:// ]]; then
        return 0
    fi
    
    # Skip anchors within same file
    if [[ "$link" =~ ^# ]]; then
        return 0
    fi
    
    # Remove anchor from link
    local file_path="${link%%#*}"
    
    # Resolve relative path
    local resolved_path
    if [[ "$file_path" =~ ^/ ]]; then
        # Absolute path from project root
        resolved_path="$PROJECT_ROOT$file_path"
    else
        # Relative path from source file
        resolved_path="$source_dir/$file_path"
    fi
    
    # Normalize path
    resolved_path=$(realpath -m "$resolved_path" 2>/dev/null || echo "$resolved_path")
    
    # Check if file exists
    if [ -f "$resolved_path" ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================

# Check for documentation in correct locations
# Requirement 2.1: Technical docs in ahab/docs/, user docs in root
# Check ahab directory for misplaced docs
check_ahab_docs() {
    local errors=0
    local checked=0
    
    while IFS= read -r file; do
        # Skip files already in docs/
        if [[ "$file" =~ /docs/ ]]; then
            continue
        fi
        
        # Skip special files
        local basename=$(basename "$file")
        case "$basename" in
            README.md|CHANGELOG.md|LICENSE|CONTRIBUTING.md|ABOUT.md)
                continue
                ;;
        esac
        
        ((checked++))
        
        # Check if this is technical documentation
        if is_technical_doc "$file"; then
            report_error "Technical documentation not in ahab/docs/: $file"
            echo "  Move to: ahab/docs/$(basename "$file")"
            ((errors++))
        fi
    done < <(find "$PROJECT_ROOT/ahab" -name "*.md" -type f 2>/dev/null)
    
    echo "$errors:$checked"
}

# Check ahab-gui directory for misplaced docs
check_ahab_gui_docs() {
    local errors=0
    local checked=0
    
    if [ -d "$PROJECT_ROOT/ahab-gui" ]; then
        while IFS= read -r file; do
            # Skip files already in docs/
            if [[ "$file" =~ /docs/ ]]; then
                continue
            fi
            
            # Skip special files
            local basename=$(basename "$file")
            case "$basename" in
                README.md|CHANGELOG.md|LICENSE|CONTRIBUTING.md|BRANDING.md|SECURITY.md)
                    continue
                    ;;
            esac
            
            ((checked++))
            
            # Check if this is technical documentation
            if is_technical_doc "$file"; then
                report_error "Technical documentation not in ahab-gui/docs/: $file"
                echo "  Move to: ahab-gui/docs/$(basename "$file")"
                ((errors++))
            fi
        done < <(find "$PROJECT_ROOT/ahab-gui" -name "*.md" -type f 2>/dev/null)
    fi
    
    echo "$errors:$checked"
}

validate_documentation_locations() {
    print_section "Checking documentation locations"
    
    local total_errors=0
    local total_checked=0
    
    # Check ahab directory
    local ahab_result
    ahab_result=$(check_ahab_docs)
    local ahab_errors=${ahab_result%:*}
    local ahab_checked=${ahab_result#*:}
    
    # Check ahab-gui directory
    local gui_result
    gui_result=$(check_ahab_gui_docs)
    local gui_errors=${gui_result%:*}
    local gui_checked=${gui_result#*:}
    
    total_errors=$((ahab_errors + gui_errors))
    total_checked=$((ahab_checked + gui_checked))
    
    if [ $total_errors -eq 0 ]; then
        report_success "Documentation locations correct ($total_checked files checked)"
    fi
    
    return $total_errors
}

# Check for required documentation format
# Requirement 2.5: All docs have date, status, audience
validate_documentation_format() {
    print_section "Checking documentation format"
    
    local errors=0
    local checked=0
    
    # Check all markdown files
    while IFS= read -r file; do
        # Skip certain files that don't need frontmatter
        local basename=$(basename "$file")
        case "$basename" in
            README.md|LICENSE|CHANGELOG.md)
                continue
                ;;
        esac
        
        # Skip archived files
        if [[ "$file" =~ /archive/ ]] || [[ "$file" =~ /backups/ ]]; then
            continue
        fi
        
        ((checked++))
        
        # Check for required frontmatter
        if ! has_required_frontmatter "$file"; then
            report_error "Missing required format: $file"
            echo "  Required: **Date**, **Status**, **Audience** fields"
            echo "  Example:"
            echo "    **Date**: $(date +%Y-%m-%d)"
            echo "    **Status**: Draft|Active|Deprecated"
            echo "    **Audience**: Users|Developers|Educators|Leaders"
            ((errors++))
        fi
    done < <(find_markdown_files)
    
    if [ $errors -eq 0 ]; then
        report_success "Documentation format correct ($checked files checked)"
    fi
    
    return $errors
}

# Check for valid cross-references
# Requirement 2.3: All documentation cross-references are valid
validate_cross_references() {
    print_section "Checking cross-references"
    
    local errors=0
    local checked=0
    local links_checked=0
    
    # Check all markdown files for broken links
    while IFS= read -r file; do
        ((checked++))
        
        # Extract all links from file
        while IFS= read -r link; do
            [ -z "$link" ] && continue
            
            ((links_checked++))
            
            # Check if link is valid
            if ! is_valid_link "$link" "$file"; then
                report_error "Broken link in $file"
                echo "  Link: $link"
                echo "  Target file not found"
                ((errors++))
            fi
        done < <(extract_links "$file")
    done < <(find_markdown_files)
    
    if [ $errors -eq 0 ]; then
        report_success "Cross-references valid ($links_checked links in $checked files checked)"
    fi
    
    return $errors
}

# Check for technical accuracy
# Requirement 2.4: Technical accuracy of OS versions and features
validate_technical_accuracy() {
    print_section "Checking technical accuracy"
    
    local errors=0
    local warnings=0
    local checked=0
    
    # Check for outdated OS version references
    while IFS= read -r file; do
        ((checked++))
        
        # Check for outdated OS versions
        for os_version in "${OUTDATED_OS_VERSIONS[@]}"; do
            if grep -n "$os_version" "$file" 2>/dev/null | grep -v "^[[:space:]]*#"; then
                report_error "Outdated OS version in $file: $os_version"
                echo "  Current supported versions:"
                for current in "${CURRENT_OS_VERSIONS[@]}"; do
                    echo "    - $current"
                done
                ((errors++))
            fi
        done
        
        # Check for references to deprecated features
        if grep -ni "rocky linux" "$file" 2>/dev/null | grep -v "no longer\|deprecated\|removed"; then
            report_warning "Reference to Rocky Linux in $file"
            echo "  Rocky Linux is no longer supported (use Fedora 43, Debian 13, or Ubuntu 24.04)"
            ((warnings++))
        fi
        
        # Check for outdated Python versions
        if grep -n "python 3\.[0-9]" "$file" 2>/dev/null | grep -v "3.11\|3.12"; then
            report_warning "Outdated Python version reference in $file"
            echo "  Current Python version: 3.11"
            ((warnings++))
        fi
    done < <(find_markdown_files)
    
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        report_success "Technical accuracy verified ($checked files checked)"
    fi
    
    return $errors
}

# ============================================================================
# Main Validation
# ============================================================================

main() {
    print_header "Documentation Validator"
    
    cd "$PROJECT_ROOT" || exit 1
    
    local total_errors=0
    
    # Run all validation checks
    validate_documentation_locations || ((total_errors+=$?))
    validate_documentation_format || ((total_errors+=$?))
    validate_cross_references || ((total_errors+=$?))
    validate_technical_accuracy || ((total_errors+=$?))
    
    # Print summary
    print_summary "Documentation"
    
    # Return appropriate exit code
    if [ $total_errors -gt 0 ]; then
        return 1
    else
        report_success "All documentation checks passed"
        return 0
    fi
}

# Run main function
main "$@"
