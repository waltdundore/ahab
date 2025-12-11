#!/usr/bin/env bash
# ==============================================================================
# Unused Files Audit Script (Refactored)
# ==============================================================================
# Identifies files that are not referenced anywhere in the codebase
# Usage: make audit-unused
# Exit Codes: 0=complete, 1=error
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/audit-common.sh
source "$SCRIPT_DIR/lib/audit-common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Core files that are always kept
CORE_FILES=(
    "README.md" "ABOUT.md" "DEVELOPMENT_RULES.md" "CHANGELOG.md"
    "TROUBLESHOOTING.md" "ahab.conf" "index.html" "LICENSE"
)

# Counters
TOTAL_FILES=0
USED_FILES=0
UNUSED_FILES=0

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    print_header "UNUSED FILES AUDIT"
    
    echo "Scanning for unused files in the codebase..."
    echo ""
    
    scan_for_unused_files
    generate_unused_files_report
}

#------------------------------------------------------------------------------
# File Scanning
#------------------------------------------------------------------------------

scan_for_unused_files() {
    print_info "Scanning files..."
    
    # Get all files (excluding common ignore patterns)
    local all_files
    mapfile -t all_files < <(find . -type f \
        -not -path "./.git/*" \
        -not -path "./.vagrant/*" \
        -not -path "./node_modules/*" \
        -not -path "./.kiro/*" \
        -not -name "*.log" \
        -not -name "*.tmp" \
        2>/dev/null)
    
    TOTAL_FILES=${#all_files[@]}
    print_info "Found $TOTAL_FILES files to analyze"
    
    # Check each file
    for file in "${all_files[@]}"; do
        local filename
        filename=$(basename "$file")
        
        if is_core_file "$filename"; then
            ((USED_FILES++))
        elif is_file_referenced "$file"; then
            ((USED_FILES++))
        else
            report_unused_file "$file"
            ((UNUSED_FILES++))
        fi
    done
}

#------------------------------------------------------------------------------
# File Analysis Functions
#------------------------------------------------------------------------------

is_core_file() {
    local filename="$1"
    
    for core_file in "${CORE_FILES[@]}"; do
        if [[ "$filename" == "$core_file" ]]; then
            return 0
        fi
    done
    return 1
}

is_file_referenced() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    local basename_no_ext="${filename%.*}"
    
    # Skip self-references
    local search_files
    mapfile -t search_files < <(find . -type f \
        -not -path "./.git/*" \
        -not -path "./.vagrant/*" \
        -not -path "./node_modules/*" \
        -not -name "*.log" \
        -not -name "*.tmp" \
        ! -samefile "$file" \
        2>/dev/null)
    
    # Search for references
    for search_file in "${search_files[@]}"; do
        # Check for filename references
        if grep -q "$filename" "$search_file" 2>/dev/null; then
            return 0
        fi
        
        # Check for basename references (without extension)
        if [[ "$basename_no_ext" != "$filename" ]] && \
           grep -q "$basename_no_ext" "$search_file" 2>/dev/null; then
            return 0
        fi
    done
    
    return 1
}

report_unused_file() {
    local file="$1"
    echo -e "${YELLOW}  Unused: $file${NC}"
}

#------------------------------------------------------------------------------
# Report Generation
#------------------------------------------------------------------------------

generate_unused_files_report() {
    local timestamp
    timestamp=$(generate_audit_timestamp)
    local report_file="unused-files-audit-${timestamp}.md"
    
    print_section "AUDIT SUMMARY"
    
    echo "Total files scanned: $TOTAL_FILES"
    echo -e "Used files: ${GREEN}$USED_FILES${NC}"
    echo -e "Unused files: ${YELLOW}$UNUSED_FILES${NC}"
    
    local usage_percentage
    if [ $TOTAL_FILES -gt 0 ]; then
        usage_percentage=$((USED_FILES * 100 / TOTAL_FILES))
        echo "Usage percentage: ${usage_percentage}%"
    fi
    
    # Generate detailed report
    {
        echo "# Unused Files Audit Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Summary"
        echo "- Total files: $TOTAL_FILES"
        echo "- Used files: $USED_FILES"
        echo "- Unused files: $UNUSED_FILES"
        echo "- Usage percentage: ${usage_percentage}%"
        echo ""
        echo "## Recommendations"
        if [ $UNUSED_FILES -gt 0 ]; then
            echo "- Review unused files for potential removal"
            echo "- Verify files are truly unused before deleting"
            echo "- Consider if files are used by external systems"
        else
            echo "- All files appear to be in use"
        fi
    } > "$report_file"
    
    print_success "Report saved to: $report_file"
    
    # Final status
    if [ $UNUSED_FILES -eq 0 ]; then
        print_success "No unused files detected"
        return 0
    else
        print_warning "$UNUSED_FILES potentially unused files found"
        return 0  # Not an error, just findings
    fi
}

#------------------------------------------------------------------------------
# Script Entry Point
#------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi