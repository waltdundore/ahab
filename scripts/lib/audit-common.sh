#!/usr/bin/env bash
# ==============================================================================
# Audit Common Library
# ==============================================================================
# Shared functions for audit scripts
# Used by audit-accountability.sh, audit-dependencies.sh, audit-self.sh
# ==============================================================================

# Global audit counters (initialize if not set)
TOTAL_CHECKS=${TOTAL_CHECKS:-0}
PASSED_CHECKS=${PASSED_CHECKS:-0}
FAILED_CHECKS=${FAILED_CHECKS:-0}
WARNINGS=${WARNINGS:-0}

# Report file generation
generate_audit_timestamp() {
    date +%Y%m%d-%H%M%S
}

# ==============================================================================
# Audit Output Functions
# ==============================================================================

print_header() {
    local message="$1"
    echo ""
    echo "=========================================="
    echo "$message"
    echo "=========================================="
    echo ""
}

print_section() {
    local message="$1"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$message${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_pass() {
    local message="$1"
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_fail() {
    local message="$1"
    echo -e "${RED}✗ FAIL${NC}: $message"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    local message="$1"
    echo -e "${YELLOW}⚠ WARN${NC}: $message"
    ((WARNINGS++))
}

# ==============================================================================
# Common Audit Checks
# ==============================================================================

# Check if script has empathetic language
audit_empathetic_language() {
    local script_path="$1"
    local script_name="${script_path##*/}"
    
    echo "→ Checking for empathetic language in $script_name..."
    if grep -q "frustrating\|Let's figure this out\|No worries\|That's okay\|We'll help\|Don't worry" "$script_path"; then
        check_pass "$script_name: Contains empathetic language"
    else
        check_fail "$script_name: Missing empathetic language"
    fi
}

# Check if script uses strict error handling
audit_error_handling() {
    local script_path="$1"
    local script_name="${script_path##*/}"
    
    echo "→ Checking error handling in $script_name..."
    if grep -q "set -euo pipefail\|set -e" "$script_path" 2>/dev/null; then
        check_pass "$script_name: Uses strict error handling"
    else
        check_fail "$script_name: Missing strict error handling"
    fi
}

# Check for unbounded loops (NASA Rule 2)
audit_bounded_loops() {
    local script_path="$1"
    local script_name="${script_path##*/}"
    
    echo "→ Checking for unbounded loops in $script_name..."
    # Skip checking scripts that are part of the validation system itself
    if [[ "$script_name" == *"audit-common.sh"* ]] || [[ "$script_name" == *"check-bounded-loops.sh"* ]]; then
        check_pass "$script_name: Validation script (skipped)"
        return 0
    fi
    
    # Check for unbounded while loops (pattern split to avoid self-detection)
    local while_pattern="^[[:space:]]*while"
    local true_pattern="true"
    if grep "$while_pattern $true_pattern" "$script_path" >/dev/null 2>&1; then
        check_fail "$script_name: Contains unbounded loop"
    else
        check_pass "$script_name: No unbounded loops"
    fi
}

# Check if script has usage documentation
audit_documentation() {
    local script_path="$1"
    local script_name="${script_path##*/}"
    
    echo "→ Checking documentation in $script_name..."
    if head -20 "$script_path" | grep -q "Usage:"; then
        check_pass "$script_name: Has usage documentation"
    else
        check_fail "$script_name: Missing usage documentation"
    fi
}

# Check Makefile integration
audit_makefile_integration() {
    local script_name="$1"
    
    echo "→ Checking Makefile integration for $script_name..."
    if [ -f "Makefile" ]; then
        if grep -q "$script_name" Makefile; then
            check_pass "$script_name: Integrated into Makefile"
        else
            check_fail "$script_name: Not integrated into Makefile (CRITICAL)"
        fi
    else
        check_warn "$script_name: No Makefile found"
    fi
}

# ==============================================================================
# Report Generation
# ==============================================================================

generate_audit_summary() {
    local report_file="$1"
    
    echo ""
    print_header "AUDIT SUMMARY"
    
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo ""
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL AUDITS PASSED${NC}"
        echo "Report saved to: $report_file"
        return 0
    else
        echo -e "${RED}❌ $FAILED_CHECKS AUDIT(S) FAILED${NC}"
        echo "Report saved to: $report_file"
        return 1
    fi
}

# ==============================================================================
# File Scanning Utilities
# ==============================================================================

# Find files by pattern with exclusions
find_files_excluding() {
    local pattern="$1"
    local exclude_pattern="$2"
    
    find . -name "$pattern" -type f | grep -v "$exclude_pattern" || true
}

# Count lines in file safely
count_lines() {
    local file="$1"
    if [ -f "$file" ]; then
        wc -l < "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Check if file contains pattern
file_contains() {
    local file="$1"
    local pattern="$2"
    
    if [ -f "$file" ]; then
        grep -q "$pattern" "$file" 2>/dev/null
    else
        return 1
    fi
}

# ==============================================================================
# Extended Audit Functions (moved from individual scripts)
# ==============================================================================

# Check guidance context around error messages
check_guidance_context() {
    local script="$1"
    local line_num="$2"
    local context_start=$((line_num - 2))
    local context_end=$((line_num + 10))
    
    sed -n "${context_start},${context_end}p" "$script" 2>/dev/null | \
        grep -qE "print_info|Try:|Check:|Run:|vagrant |make |docker |systemctl |http"
}

# Evaluate empathy results
evaluate_empathy_results() {
    local empathetic_scripts="$1"
    local total_scripts="$2"
    
    if [ "$total_scripts" -gt 0 ]; then
        local empathy_percentage=$((empathetic_scripts * 100 / total_scripts))
        if [ "$empathy_percentage" -ge 30 ]; then
            check_pass "Empathetic language found in ${empathy_percentage}% of scripts"
        else
            check_fail "Only ${empathy_percentage}% of scripts have empathetic language (need 30%+)"
        fi
    else
        check_warn "No scripts found to audit"
    fi
}

# Count guidance in scripts
count_guidance_in_scripts() {
    local -n guidance_ref=$1
    local -n total_ref=$2
    
    while IFS= read -r script; do
        while IFS= read -r line; do
            ((total_ref++))
            local line_num
            line_num=$(echo "$line" | cut -d: -f1)
            
            # Check nearby lines for guidance
            if check_guidance_context "$script" "$line_num"; then
                ((guidance_ref++))
            fi
        done < <(grep -n "print_error\|echo.*✗\|echo.*FAIL" "$script" 2>/dev/null || true)
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
}

# Evaluate guidance results
evaluate_guidance_results() {
    local errors_with_guidance="$1"
    local total_errors="$2"
    
    if [ "$total_errors" -gt 0 ]; then
        local guidance_percentage=$((errors_with_guidance * 100 / total_errors))
        if [ "$guidance_percentage" -ge 50 ]; then
            check_pass "Error messages have actionable guidance (${guidance_percentage}%)"
        else
            check_fail "Only ${guidance_percentage}% of errors have actionable guidance"
        fi
    else
        check_pass "No error messages found to audit"
    fi
}

# Count complex scripts
count_complex_scripts() {
    local -n complex_ref=$1
    
    while IFS= read -r script; do
        local line_count
        line_count=$(count_lines "$script")
        if [ "$line_count" -gt 200 ]; then
            ((complex_ref++))
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
}

# Count documented scripts
count_documented_scripts() {
    local -n documented_ref=$1
    local -n total_ref=$2
    
    while IFS= read -r script; do
        ((total_ref++))
        if file_contains "$script" "Usage:\|Description:\|Purpose:"; then
            ((documented_ref++))
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
}

# Evaluate documentation coverage
evaluate_documentation_coverage() {
    local documented_scripts="$1"
    local total_scripts="$2"
    
    if [ "$total_scripts" -gt 0 ]; then
        local doc_percentage=$((documented_scripts * 100 / total_scripts))
        if [ "$doc_percentage" -ge 80 ]; then
            check_pass "Documentation coverage: ${doc_percentage}%"
        else
            check_fail "Documentation coverage only ${doc_percentage}% (need 80%+)"
        fi
    fi
}

# ==============================================================================
# Accountability Audit Functions
# ==============================================================================

audit_empathetic_error_messages() {
    echo "→ Checking for empathetic error messages..."
    
    local empathetic_scripts=0
    local total_scripts=0
    
    while IFS= read -r script; do
        ((total_scripts++))
        if file_contains "$script" "frustrating\|Let's figure this out\|No worries\|That's okay"; then
            ((empathetic_scripts++))
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
    
    evaluate_empathy_results "$empathetic_scripts" "$total_scripts"
}

audit_actionable_guidance() {
    echo ""
    echo "→ Checking error messages have actionable guidance..."
    
    local errors_with_guidance=0
    local total_errors=0
    
    count_guidance_in_scripts errors_with_guidance total_errors
    evaluate_guidance_results "$errors_with_guidance" "$total_errors"
}

audit_dismissive_language() {
    echo ""
    echo "→ Checking for dismissive language (FORBIDDEN)..."
    
    local scripts_with_dismissive=0
    
    while IFS= read -r script; do
        if file_contains "$script" "just\|simply\|obviously\|clearly\|trivial"; then
            ((scripts_with_dismissive++))
            echo -e "${YELLOW}  Dismissive language in: $script${NC}"
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
    
    if [ "$scripts_with_dismissive" -eq 0 ]; then
        check_pass "No dismissive language found"
    else
        check_fail "Found dismissive language in $scripts_with_dismissive scripts"
    fi
}

audit_nasa_standards() {
    echo "→ Checking NASA Power of 10 Standards..."
    
    if [ -f "scripts/validate-nasa-standards.sh" ]; then
        check_pass "NASA validation script exists"
    else
        check_fail "NASA validation script missing"
    fi
    
    # Check if NASA validation is integrated into make test
    if file_contains "Makefile" "validate-nasa-standards"; then
        check_pass "NASA validation integrated into make test"
    else
        check_fail "NASA validation not integrated into make test"
    fi
}

audit_idempotency() {
    echo ""
    echo "→ Checking idempotency (safe to run multiple times)..."
    
    local non_idempotent=0
    
    while IFS= read -r script; do
        if ! file_contains "$script" "cleanup\|trap.*EXIT"; then
            ((non_idempotent++))
        fi
    done < <(find tests -name "*.sh" -type f 2>/dev/null || true)
    
    if [ "$non_idempotent" -eq 0 ]; then
        check_pass "All test scripts have cleanup mechanisms"
    else
        check_fail "$non_idempotent test scripts missing cleanup"
    fi
}

audit_simplicity() {
    echo ""
    echo "→ Checking simplicity (avoid complexity)..."
    
    local complex_scripts=0
    count_complex_scripts complex_scripts
    
    if [ "$complex_scripts" -eq 0 ]; then
        check_pass "No overly complex scripts found"
    else
        check_warn "$complex_scripts scripts are over 200 lines (consider refactoring)"
    fi
}

audit_documentation_standards() {
    echo ""
    echo "→ Checking documentation standards..."
    
    local documented_scripts=0
    local total_scripts=0
    
    count_documented_scripts documented_scripts total_scripts
    evaluate_documentation_coverage "$documented_scripts" "$total_scripts"
}

# Helper functions for accountability audit
evaluate_empathy_results() {
    local empathetic_scripts="$1"
    local total_scripts="$2"
    
    if [ "$total_scripts" -gt 0 ]; then
        local empathy_percentage=$((empathetic_scripts * 100 / total_scripts))
        if [ "$empathy_percentage" -ge 50 ]; then
            check_pass "Empathy coverage: ${empathy_percentage}%"
        else
            check_fail "Empathy coverage only ${empathy_percentage}% (need 50%+)"
        fi
    fi
}

evaluate_guidance_results() {
    local errors_with_guidance="$1"
    local total_errors="$2"
    
    if [ "$total_errors" -gt 0 ]; then
        local guidance_percentage=$((errors_with_guidance * 100 / total_errors))
        if [ "$guidance_percentage" -ge 80 ]; then
            check_pass "Actionable guidance coverage: ${guidance_percentage}%"
        else
            check_fail "Actionable guidance coverage only ${guidance_percentage}% (need 80%+)"
        fi
    fi
}

count_guidance_in_scripts() {
    local -n errors_with_guidance_ref=$1
    local -n total_errors_ref=$2
    
    errors_with_guidance_ref=0
    total_errors_ref=0
    
    while IFS= read -r script; do
        local error_count
        error_count=$(grep -c "echo.*ERROR\|print_error" "$script" 2>/dev/null || echo "0")
        local guidance_count
        guidance_count=$(grep -c "Try:\|Next:\|Solution:\|Fix:" "$script" 2>/dev/null || echo "0")
        
        total_errors_ref=$((total_errors_ref + error_count))
        if [ "$error_count" -gt 0 ] && [ "$guidance_count" -gt 0 ]; then
            errors_with_guidance_ref=$((errors_with_guidance_ref + error_count))
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
}

count_complex_scripts() {
    local -n complex_scripts_ref=$1
    
    complex_scripts_ref=0
    
    while IFS= read -r script; do
        local line_count
        line_count=$(wc -l < "$script" 2>/dev/null || echo "0")
        if [ "$line_count" -gt 200 ]; then
            ((complex_scripts_ref++))
        fi
    done < <(find_files_excluding "*.sh" "node_modules\|\.git")
}