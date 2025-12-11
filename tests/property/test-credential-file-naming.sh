#!/bin/bash
# Property Test: Credential File Naming
# Validates: Requirements 3.3 - Credential files follow naming conventions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test helpers
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Property 11: Credential file naming
# All credential files should follow secure naming conventions:
# - End with .template (for templates)
# - End with .example (for examples) 
# - Be in .gitignore (for actual credential files)
# - Not contain actual credentials in templates/examples

test_credential_file_naming() {
    print_test "Property 11: Credential file naming conventions"
    
    local violations=0
    local total_files=0
    
    # Find potential credential files
    local credential_patterns=(
        "*password*"
        "*secret*" 
        "*key*"
        "*token*"
        "*credential*"
        "*auth*"
        "*.pem"
        "*.key"
        "*.crt"
        "*.p12"
        "*.pfx"
        ".env"
        "vault.yml"
        "ansible.cfg"
    )
    
    print_info "Checking credential file naming conventions..."
    
    for pattern in "${credential_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            ((total_files++))
            
            local filename
            filename=$(basename "$file")
            local relative_path
            relative_path=$(realpath --relative-to="$PROJECT_ROOT" "$file")
            
            # Skip files in .git directory
            if [[ "$relative_path" == .git/* ]]; then
                continue
            fi
            
            # Check if it's a template or example (good)
            if [[ "$filename" == *.template ]] || [[ "$filename" == *.example ]]; then
                print_debug "✓ Template/example file: $relative_path"
                continue
            fi
            
            # Check if it's in .gitignore (good for actual credential files)
            if git check-ignore "$file" &>/dev/null; then
                print_debug "✓ Ignored credential file: $relative_path"
                continue
            fi
            
            # Check if it contains template values (good)
            if grep -q "CHANGE_ME\|TODO\|REPLACE_ME\|EXAMPLE" "$file" 2>/dev/null; then
                print_debug "✓ Contains template values: $relative_path"
                continue
            fi
            
            # Check if it's a known safe file
            case "$filename" in
                "ansible.cfg.production"|"daemon.json.template"|"vault.yml.template")
                    print_debug "✓ Known safe template: $relative_path"
                    continue
                    ;;
                "requirements*.txt"|"package*.json")
                    print_debug "✓ Dependency file (safe): $relative_path"
                    continue
                    ;;
            esac
            
            # This might be a real credential file
            print_warning "⚠ Potential credential file not following conventions: $relative_path"
            print_info "  Should be: ${filename}.template or ${filename}.example"
            print_info "  Or add to .gitignore if it's a real credential file"
            ((violations++))
            
        done < <(find "$PROJECT_ROOT" -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    # Check for common credential file patterns that should be templates
    local required_templates=(
        ".env"
        "vault.yml"
        "secrets.yml"
        "credentials.yml"
    )
    
    for template in "${required_templates[@]}"; do
        if [[ -f "$PROJECT_ROOT/$template" ]] && ! git check-ignore "$PROJECT_ROOT/$template" &>/dev/null; then
            if ! grep -q "CHANGE_ME\|TODO\|REPLACE_ME\|EXAMPLE" "$PROJECT_ROOT/$template" 2>/dev/null; then
                print_warning "⚠ Credential file should be template: $template"
                print_info "  Rename to: ${template}.template"
                ((violations++))
            fi
        fi
    done
    
    # Report results
    if [[ $violations -eq 0 ]]; then
        print_pass "All credential files follow naming conventions ($total_files files checked)"
        return 0
    else
        print_fail "$violations credential file naming violations found"
        print_info "Credential files should:"
        print_info "  - End with .template (for templates)"
        print_info "  - End with .example (for examples)"
        print_info "  - Be in .gitignore (for actual credentials)"
        print_info "  - Contain template values like CHANGE_ME"
        return 1
    fi
}

test_no_hardcoded_credentials_in_templates() {
    print_test "No hardcoded credentials in templates"
    
    local violations=0
    
    # Find template and example files
    while IFS= read -r -d '' file; do
        local relative_path
        relative_path=$(realpath --relative-to="$PROJECT_ROOT" "$file")
        
        # Skip .git directory
        if [[ "$relative_path" == .git/* ]]; then
            continue
        fi
        
        # Check for potential hardcoded credentials
        local suspicious_patterns=(
            "password.*=.*[^CHANGE_ME]"
            "secret.*=.*[^CHANGE_ME]"
            "key.*=.*[^CHANGE_ME]"
            "token.*=.*[^CHANGE_ME]"
        )
        
        for pattern in "${suspicious_patterns[@]}"; do
            if grep -i "$pattern" "$file" 2>/dev/null | grep -v "CHANGE_ME\|TODO\|REPLACE_ME\|EXAMPLE" >/dev/null; then
                print_warning "⚠ Potential hardcoded credential in template: $relative_path"
                ((violations++))
            fi
        done
        
    done < <(find "$PROJECT_ROOT" -name "*.template" -o -name "*.example" -type f -print0 2>/dev/null)
    
    if [[ $violations -eq 0 ]]; then
        print_pass "No hardcoded credentials found in templates"
        return 0
    else
        print_fail "$violations potential hardcoded credentials in templates"
        return 1
    fi
}

main() {
    print_header "Property Test: Credential File Naming"
    
    local failures=0
    
    # Run property tests
    test_credential_file_naming || ((failures++))
    test_no_hardcoded_credentials_in_templates || ((failures++))
    
    # Summary
    if [[ $failures -eq 0 ]]; then
        print_success "All credential file naming property tests passed"
        exit 0
    else
        print_error "$failures property test(s) failed"
        exit 1
    fi
}

main "$@"