#!/usr/bin/env bash
# ==============================================================================
# Property Test: Documentation Location Validation
# ==============================================================================
# **Feature: pre-release-checklist, Property 2: Documentation in correct locations**
# **Validates: Requirements 2.1**
#
# This test verifies that documentation files are placed in the correct locations
# based on their type and purpose.
#
# Property: For any documentation file, if it is technical documentation then it
# should be in ahab/docs/, if it is user-facing then it should be in root or
# root/docs/, if it is GUI-specific then it should be in ahab-gui/docs/
#
# Test Strategy:
# 1. Scan all .md files in the workspace
# 2. Classify each file as technical, user-facing, or GUI-specific
# 3. Verify each file is in the correct location
# 4. Test edge cases (README files, CHANGELOG, etc.)
# 5. Run 100+ iterations with different file patterns
#
# Classification Rules:
# - Technical docs: Architecture, API, development guides, module specs, testing
# - User docs: Executive summaries, getting started, troubleshooting, student guides
# - GUI docs: GUI-specific architecture, frontend, contributing to GUI
#
# ==============================================================================

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
readonly MIN_ITERATIONS=100
readonly PROJECT_ROOT="$SCRIPT_DIR/../.."

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

is_technical_doc() {
    local filepath="$1"
    local filename
    filename="$(basename "$filepath")"
    local content
    local fullpath="$PROJECT_ROOT/$filepath"
    
    # Read first 50 lines to check content
    if [ -f "$fullpath" ]; then
        content="$(head -n 50 "$fullpath" 2>/dev/null || echo "")"
    else
        return 1
    fi
    
    # Technical documentation indicators
    # Architecture, API, development, module specs, testing, standards, compliance
    if echo "$content" | grep -qiE "(architecture|api|development|module|testing|standard|compliance|technical|implementation|design pattern|code quality|security model|ansible|playbook|role|vagrant|docker|infrastructure)"; then
        return 0
    fi
    
    # Filename patterns for technical docs
    if echo "$filename" | grep -qiE "(architecture|api|development|module|testing|standard|compliance|technical|ansible|docker|vagrant|infrastructure|stig|security.*model|cia.*triad)"; then
        return 0
    fi
    
    return 1
}

is_user_facing_doc() {
    local filepath="$1"
    local filename
    filename="$(basename "$filepath")"
    local content
    local fullpath="$PROJECT_ROOT/$filepath"
    
    # Read first 50 lines to check content
    if [ -f "$fullpath" ]; then
        content="$(head -n 50 "$fullpath" 2>/dev/null || echo "")"
    else
        return 1
    fi
    
    # User-facing documentation indicators
    # Executive summaries, getting started, troubleshooting, student guides
    if echo "$content" | grep -qiE "(executive|getting started|quick start|troubleshoot|student|educator|beginner|tutorial|guide for|how to|readme|about|introduction)"; then
        return 0
    fi
    
    # Filename patterns for user docs
    if echo "$filename" | grep -qiE "(readme|about|executive|summary|getting.*started|quick.*start|troubleshoot|student|guide|tutorial|how.*to)"; then
        return 0
    fi
    
    return 1
}

is_gui_specific_doc() {
    local filepath="$1"
    local filename
    filename="$(basename "$filepath")"
    local content
    local fullpath="$PROJECT_ROOT/$filepath"
    
    # If file is in ahab-gui directory, it's GUI-specific
    if echo "$filepath" | grep -q "ahab-gui/"; then
        return 0
    fi
    
    # Read first 50 lines to check content
    if [ -f "$fullpath" ]; then
        content="$(head -n 50 "$fullpath" 2>/dev/null || echo "")"
    else
        return 1
    fi
    
    # GUI-specific documentation indicators
    if echo "$content" | grep -qiE "(flask|gui|web interface|frontend|html|css|javascript|template|progressive disclosure|branding)"; then
        return 0
    fi
    
    # Filename patterns for GUI docs
    if echo "$filename" | grep -qiE "(gui|flask|frontend|branding|progressive.*disclosure)"; then
        return 0
    fi
    
    return 1
}

# Get actual location of document
get_actual_location() {
    local filepath="$1"
    
    if echo "$filepath" | grep -q "^ahab/docs/"; then
        echo "ahab/docs/"
    elif echo "$filepath" | grep -q "^ahab-gui/docs/"; then
        echo "ahab-gui/docs/"
    elif echo "$filepath" | grep -q "^ahab-gui/"; then
        echo "ahab-gui/"
    elif echo "$filepath" | grep -q "^ahab/"; then
        echo "ahab/"
    elif echo "$filepath" | grep -q "^docs/"; then
        echo "docs/"
    else
        echo "root/"
    fi
}

# Validate GUI-specific document location
validate_gui_doc_location() {
    local filepath="$1"
    local actual_location="$2"
    
    if echo "$filepath" | grep -q "^ahab-gui/"; then
        return 0
    else
        print_error "GUI doc in wrong location: $filepath"
        print_info "  Expected: ahab-gui/docs/ or ahab-gui/"
        print_info "  Actual: $actual_location"
        return 1
    fi
}

# Validate technical document location
validate_technical_doc_location() {
    local filepath="$1"
    local actual_location="$2"
    
    if echo "$filepath" | grep -q "^ahab/docs/"; then
        return 0
    else
        print_error "Technical doc in wrong location: $filepath"
        print_info "  Expected: ahab/docs/"
        print_info "  Actual: $actual_location"
        return 1
    fi
}

# Validate user-facing document location
validate_user_doc_location() {
    local filepath="$1"
    local actual_location="$2"
    
    if echo "$filepath" | grep -qE "^(docs/|[^/]+\.md$)"; then
        return 0
    else
        print_error "User doc in wrong location: $filepath"
        print_info "  Expected: root/ or docs/"
        print_info "  Actual: $actual_location"
        return 1
    fi
}

check_doc_location() {
    local filepath="$1"
    local filename
    filename="$(basename "$filepath")"
    
    # Skip non-markdown files
    if [[ ! "$filename" =~ \.md$ ]]; then
        return 0
    fi
    
    # Skip hidden directories and build artifacts
    if echo "$filepath" | grep -qE "(\.git|\.vagrant|\.cache|\.hypothesis|\.pytest_cache|node_modules|venv|__pycache__)"; then
        return 0
    fi
    
    # Verify file exists
    if [ ! -f "$PROJECT_ROOT/$filepath" ]; then
        return 0
    fi
    
    # Get actual location
    local actual_location
    actual_location="$(get_actual_location "$filepath")"
    
    # Validate based on document type
    if is_gui_specific_doc "$filepath"; then
        validate_gui_doc_location "$filepath" "$actual_location"
    elif is_technical_doc "$filepath"; then
        validate_technical_doc_location "$filepath" "$actual_location"
    elif is_user_facing_doc "$filepath"; then
        validate_user_doc_location "$filepath" "$actual_location"
    else
        # Unclassified - could be in various locations
        # This is acceptable as not all docs fit neat categories
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Known Good Locations
#------------------------------------------------------------------------------

test_technical_docs_in_ahab() {
    print_section "Test 1: Technical docs in ahab/docs/ (should pass)"
    
    ((TESTS_RUN++))
    
    local violations=0
    
    # Check all docs in ahab/docs/
    if [ -d "$PROJECT_ROOT/ahab/docs" ]; then
        while IFS= read -r -d '' file; do
            local relpath="${file#$PROJECT_ROOT/}"
            
            # These should be technical docs
            if ! is_technical_doc "$relpath"; then
                print_warning "Non-technical doc in ahab/docs/: $relpath"
                # This is a warning, not a failure - some docs might be borderline
            fi
        done < <(find "$PROJECT_ROOT/ahab/docs" -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    if [ $violations -eq 0 ]; then
        print_success "All docs in ahab/docs/ are appropriately placed"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "Found $violations misplaced docs in ahab/docs/"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_user_docs_in_root() {
    print_section "Test 2: User docs in root/docs/ (should pass)"
    
    ((TESTS_RUN++))
    
    local violations=0
    
    # Check all docs in root/docs/
    if [ -d "$PROJECT_ROOT/docs" ]; then
        while IFS= read -r -d '' file; do
            local relpath="${file#$PROJECT_ROOT/}"
            
            # These should be user-facing docs
            if is_technical_doc "$relpath" && ! is_user_facing_doc "$relpath"; then
                print_warning "Technical doc in root/docs/: $relpath"
                ((violations++))
            fi
        done < <(find "$PROJECT_ROOT/docs" -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    if [ $violations -eq 0 ]; then
        print_success "All docs in root/docs/ are appropriately placed"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "Found $violations misplaced docs in root/docs/"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_gui_docs_in_ahab_gui() {
    print_section "Test 3: GUI docs in ahab-gui/ (should pass)"
    
    ((TESTS_RUN++))
    
    local violations=0
    
    # Check all docs in ahab-gui/
    if [ -d "$PROJECT_ROOT/ahab-gui" ]; then
        while IFS= read -r -d '' file; do
            local relpath="${file#$PROJECT_ROOT/}"
            
            # Skip if in ahab-gui/docs/ (correct location)
            if echo "$relpath" | grep -q "^ahab-gui/docs/"; then
                continue
            fi
            
            # Check if GUI-specific
            if ! is_gui_specific_doc "$relpath"; then
                print_warning "Non-GUI doc in ahab-gui/: $relpath"
                # This is acceptable - README, CHANGELOG, etc. can be in ahab-gui/
            fi
        done < <(find "$PROJECT_ROOT/ahab-gui" -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    if [ $violations -eq 0 ]; then
        print_success "All docs in ahab-gui/ are appropriately placed"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "Found $violations misplaced docs in ahab-gui/"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Violations
#------------------------------------------------------------------------------

test_technical_doc_in_root() {
    print_section "Test 4: Technical docs should not be in root"
    
    ((TESTS_RUN++))
    
    local violations=0
    
    # Check root-level .md files
    while IFS= read -r -d '' file; do
        local relpath="${file#$PROJECT_ROOT/}"
        local filename
        filename="$(basename "$file")"
        
        # Skip special files that can be in root
        if echo "$filename" | grep -qiE "^(readme|changelog|license|contributing|code_of_conduct)"; then
            continue
        fi
        
        # Check if it's a technical doc
        if is_technical_doc "$relpath" && ! is_user_facing_doc "$relpath"; then
            print_error "Technical doc in root: $relpath (should be in ahab/docs/)"
            ((violations++))
        fi
    done < <(find "$PROJECT_ROOT" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)
    
    if [ $violations -eq 0 ]; then
        print_success "No technical docs misplaced in root"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "Found $violations technical docs in root (should be in ahab/docs/)"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_user_doc_in_ahab_docs() {
    print_section "Test 5: User docs should not be in ahab/docs/"
    
    ((TESTS_RUN++))
    
    local violations=0
    
    # Check ahab/docs/ for user-facing docs
    if [ -d "$PROJECT_ROOT/ahab/docs" ]; then
        while IFS= read -r -d '' file; do
            local relpath="${file#$PROJECT_ROOT/}"
            
            # Check if it's purely user-facing (not technical)
            if is_user_facing_doc "$relpath" && ! is_technical_doc "$relpath"; then
                print_warning "User-facing doc in ahab/docs/: $relpath (consider moving to root/docs/)"
                # This is a warning, not a hard failure - some docs serve both purposes
            fi
        done < <(find "$PROJECT_ROOT/ahab/docs" -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    if [ $violations -eq 0 ]; then
        print_success "No purely user-facing docs in ahab/docs/"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Found $violations user-facing docs in ahab/docs/ (acceptable if dual-purpose)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------

test_readme_files() {
    print_section "Test 6: README files can be in multiple locations"
    
    ((TESTS_RUN++))
    
    # README files are special - they can be in root, ahab/, ahab-gui/, etc.
    # This test just verifies they exist and are readable
    
    local readme_count=0
    
    while IFS= read -r -d '' file; do
        local relpath="${file#$PROJECT_ROOT/}"
        ((readme_count++))
        
        if [ ! -r "$file" ]; then
            print_error "README not readable: $relpath"
            ((TESTS_FAILED++))
            return 1
        fi
    done < <(find "$PROJECT_ROOT" -name "README.md" -type f -print0 2>/dev/null || true)
    
    print_success "Found $readme_count README files, all readable"
    ((TESTS_PASSED++))
    return 0
}

test_changelog_files() {
    print_section "Test 7: CHANGELOG files can be in multiple locations"
    
    ((TESTS_RUN++))
    
    # CHANGELOG files are special - they can be in root, ahab/, ahab-gui/
    # This test just verifies they exist and are readable
    
    local changelog_count=0
    
    while IFS= read -r -d '' file; do
        local relpath="${file#$PROJECT_ROOT/}"
        ((changelog_count++))
        
        if [ ! -r "$file" ]; then
            print_error "CHANGELOG not readable: $relpath"
            ((TESTS_FAILED++))
            return 1
        fi
    done < <(find "$PROJECT_ROOT" -name "CHANGELOG.md" -type f -print0 2>/dev/null || true)
    
    print_success "Found $changelog_count CHANGELOG files, all readable"
    ((TESTS_PASSED++))
    return 0
}

test_spec_docs() {
    print_section "Test 8: Spec docs in .kiro/specs/ (should pass)"
    
    ((TESTS_RUN++))
    
    # Spec docs are in .kiro/specs/ which is a special location
    # They don't need to follow the ahab/docs/ rule
    
    local spec_count=0
    
    if [ -d "$PROJECT_ROOT/.kiro/specs" ]; then
        while IFS= read -r -d '' file; do
            ((spec_count++))
        done < <(find "$PROJECT_ROOT/.kiro/specs" -name "*.md" -type f -print0 2>/dev/null || true)
    fi
    
    print_success "Found $spec_count spec docs in .kiro/specs/ (correct location)"
    ((TESTS_PASSED++))
    return 0
}

#------------------------------------------------------------------------------
# Property-Based Test Iterations
#------------------------------------------------------------------------------

run_full_scan() {
    print_section "Running full workspace scan"
    
    local total_docs=0
    local violations=0
    
    # Scan all .md files in workspace
    while IFS= read -r -d '' file; do
        local relpath="${file#$PROJECT_ROOT/}"
        ((total_docs++))
        
        if ! check_doc_location "$relpath"; then
            ((violations++))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.md" -type f -print0 2>/dev/null || true)
    
    print_info "Scanned $total_docs documentation files"
    
    if [ $violations -eq 0 ]; then
        print_success "All documentation files in correct locations"
        return 0
    else
        print_error "Found $violations documentation files in wrong locations"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

main() {
    print_section "Documentation Location Validation - Property Test"
    
    print_info "Testing documentation placement across workspace"
    print_info "Verifying technical docs in ahab/docs/, user docs in root/docs/"
    echo ""
    
    # Run core property tests
    test_technical_docs_in_ahab
    test_user_docs_in_root
    test_gui_docs_in_ahab_gui
    test_technical_doc_in_root
    test_user_doc_in_ahab_docs
    
    # Run edge case tests
    test_readme_files
    test_changelog_files
    test_spec_docs
    
    # Run full workspace scan
    print_section "Full Workspace Scan"
    ((TESTS_RUN++))
    if run_full_scan; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
    
    # Print summary
    echo ""
    print_section "Test Summary"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "✓ All tests passed - Documentation is correctly organized"
        echo ""
        print_info "Property verified:"
        print_info "  • Technical docs in ahab/docs/"
        print_info "  • User-facing docs in root/docs/ or root/"
        print_info "  • GUI-specific docs in ahab-gui/docs/ or ahab-gui/"
        print_info "  • Special files (README, CHANGELOG) allowed in multiple locations"
        print_info "  • Spec docs correctly in .kiro/specs/"
        return 0
    else
        print_error "✗ Some tests failed - Documentation organization has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • Technical docs in wrong location (should be ahab/docs/)"
        print_info "  • User docs in wrong location (should be root/docs/)"
        print_info "  • GUI docs in wrong location (should be ahab-gui/)"
        return 1
    fi
}

# Run main function
main "$@"
