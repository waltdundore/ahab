#!/usr/bin/env bash
# ==============================================================================
# Gitignore Pattern Validation Check
# ==============================================================================
# Validates that .gitignore contains required patterns
# 
# Requirements: 6.2, 6.3, 6.5
# Property: 20 - Required gitignore patterns
# ==============================================================================

set -euo pipefail

# Get script directory for sourcing common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library
# shellcheck source=../lib/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Initialize counters
init_counters

# Pattern category to check
CATEGORY="${1:-all}"

print_section "Gitignore Pattern Validation Check"
print_info "Checking .gitignore for required patterns: $CATEGORY"
echo ""

# Check if .gitignore exists
if [ ! -f .gitignore ]; then
    print_error ".gitignore file not found"
    echo "  Rule Violated: Repository Configuration"
    echo "  Problem: Every repository must have a .gitignore file"
    echo "  Fix: Create .gitignore with appropriate patterns"
    echo ""
    exit 1
fi

# Function to check a single pattern
check_pattern() {
    local pattern="$1"
    local description="$2"
    
    increment_check
    
    # Escape special regex characters in pattern for grep
    local escaped_pattern
    escaped_pattern=$(echo "$pattern" | sed 's/[.*^$[\]]/\\&/g')
    
    if grep -q "^${escaped_pattern}$" .gitignore 2>/dev/null || grep -q "^${pattern}$" .gitignore 2>/dev/null; then
        print_success "Pattern present: $pattern"
    else
        print_warning "Pattern missing: $pattern ($description)"
        increment_warning
    fi
}

# Check temporary file patterns
check_temp_patterns() {
    print_info "Checking Temporary File patterns..."
    check_pattern "*.tmp" "Temporary files"
    check_pattern "*.bak" "Backup files"
    check_pattern "*~" "Editor backup files"
    echo ""
}

# Check build artifact patterns
check_build_patterns() {
    print_info "Checking Build Artifact patterns..."
    check_pattern "__pycache__/" "Python cache directories"
    check_pattern "*.pyc" "Python compiled files"
    check_pattern "*.pyo" "Python optimized files"
    check_pattern "node_modules/" "Node.js dependencies"
    check_pattern "dist/" "Distribution directories"
    check_pattern "build/" "Build directories"
    echo ""
}

# Check sensitive file patterns
check_secret_patterns() {
    print_info "Checking Sensitive File patterns..."
    check_pattern "*.key" "Private keys"
    check_pattern "*.pem" "Certificate files"
    check_pattern ".env" "Environment files"
    check_pattern "*secret*" "Secret files"
    check_pattern "*credential*" "Credential files"
    echo ""
}

# Check patterns based on category
case "$CATEGORY" in
    temp|temporary)
        check_temp_patterns
        ;;
    build|artifacts)
        check_build_patterns
        ;;
    secrets|sensitive)
        check_secret_patterns
        ;;
    all)
        check_temp_patterns
        check_build_patterns
        check_secret_patterns
        ;;
    *)
        print_error "Unknown category: $CATEGORY"
        echo "  Valid categories: temp, build, secrets, all"
        exit 1
        ;;
esac

# Print summary
print_summary "Gitignore Pattern Validation Check"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    print_success "All required .gitignore patterns are present"
fi

exit $exit_code
