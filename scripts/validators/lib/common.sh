#!/bin/bash
# Pre-Release Checklist - Common Utilities
# Shared functions for all validators

# Source colors library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ -f "$PROJECT_ROOT/lib/colors.sh" ]; then
    source "$PROJECT_ROOT/lib/colors.sh"
else
    # Fallback if colors.sh not available
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Error counter
ERROR_COUNT=0
WARNING_COUNT=0

# Strict mode flag (set by orchestrator)
STRICT_MODE="${STRICT_MODE:-false}"

# ============================================================================
# Error Reporting Functions
# ============================================================================

# Report an error
# Usage: report_error "Error message"
report_error() {
    local message="$1"
    echo -e "${RED}ERROR:${NC} $message" >&2
    ((ERROR_COUNT++))
}

# Report a warning
# Usage: report_warning "Warning message"
report_warning() {
    local message="$1"
    echo -e "${YELLOW}WARNING:${NC} $message" >&2
    ((WARNING_COUNT++))
    
    # In strict mode, warnings are errors
    if [ "$STRICT_MODE" = "true" ]; then
        ((ERROR_COUNT++))
    fi
}

# Report success
# Usage: report_success "Success message"
report_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
}

# Report info
# Usage: report_info "Info message"
report_info() {
    local message="$1"
    echo -e "${BLUE}→${NC} $message"
}

# ============================================================================
# File Scanning Functions
# ============================================================================

# Find all files matching pattern, excluding common ignore patterns
# Usage: find_files "*.sh"
find_files() {
    local pattern="$1"
    local base_dir="${2:-.}"
    
    find "$base_dir" -name "$pattern" \
        -not -path "*/\.git/*" \
        -not -path "*/\.vagrant/*" \
        -not -path "*/\.hypothesis/*" \
        -not -path "*/\.pytest_cache/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/venv/*" \
        -not -path "*/\.venv/*" \
        -not -path "*/backups/*" \
        -not -path "*/\.kiro/*" \
        -type f
}

# Find all shell scripts
# Usage: find_shell_scripts
find_shell_scripts() {
    find_files "*.sh"
}

# Find all Python files
# Usage: find_python_files
find_python_files() {
    find_files "*.py"
}

# Find all Markdown files
# Usage: find_markdown_files
find_markdown_files() {
    find_files "*.md"
}

# Find all Makefiles
# Usage: find_makefiles
find_makefiles() {
    find . -name "Makefile" -o -name "Makefile.*" \
        -not -path "*/\.git/*" \
        -not -path "*/\.vagrant/*" \
        -type f
}

# ============================================================================
# Pattern Matching Functions
# ============================================================================

# Check if file contains pattern
# Usage: file_contains "pattern" "file"
file_contains() {
    local pattern="$1"
    local file="$2"
    
    grep -q "$pattern" "$file" 2>/dev/null
}

# Check if file contains pattern (case insensitive)
# Usage: file_contains_ci "pattern" "file"
file_contains_ci() {
    local pattern="$1"
    local file="$2"
    
    grep -qi "$pattern" "$file" 2>/dev/null
}

# Count occurrences of pattern in file
# Usage: count_pattern "pattern" "file"
count_pattern() {
    local pattern="$1"
    local file="$2"
    
    grep -c "$pattern" "$file" 2>/dev/null || echo "0"
}

# Find files containing pattern
# Usage: find_files_with_pattern "pattern" "*.sh"
find_files_with_pattern() {
    local pattern="$1"
    local file_pattern="${2:-*}"
    
    find_files "$file_pattern" | while read -r file; do
        if file_contains "$pattern" "$file"; then
            echo "$file"
        fi
    done
}

# ============================================================================
# Validation Helper Functions
# ============================================================================

# Check if command exists
# Usage: command_exists "shellcheck"
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Check if file is tracked by git
# Usage: is_tracked_by_git "file"
is_tracked_by_git() {
    local file="$1"
    git ls-files --error-unmatch "$file" >/dev/null 2>&1
}

# Check if file matches gitignore pattern
# Usage: is_gitignored "file"
is_gitignored() {
    local file="$1"
    git check-ignore -q "$file" 2>/dev/null
}

# Check if file is a temporary file
# Usage: is_temp_file "file"
is_temp_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    case "$basename" in
        *.tmp|*.bak|*~|*.swp|*.swo|.*.swp|.*.swo)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if file is a build artifact
# Usage: is_build_artifact "file"
is_build_artifact() {
    local file="$1"
    
    case "$file" in
        *.pyc|*/__pycache__/*|*.o|*.so|*.a|*.class|*.jar)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Progress Indicators
# ============================================================================

# Show progress spinner
# Usage: show_spinner "message" &
#        SPINNER_PID=$!
#        # do work
#        kill $SPINNER_PID
show_spinner() {
    local message="$1"
    local timeout="${2:-300}"  # Default 5 minute timeout
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local count=0
    local max_iterations=$((timeout * 10))  # 0.1s sleep = 10 iterations per second
    
    while [ $count -lt $max_iterations ]; do
        i=$(( (i+1) % 10 ))
        printf "\r${BLUE}${spin:$i:1}${NC} %s" "$message"
        sleep 0.1
        count=$((count + 1))
    done
    
    # Timeout reached
    printf "\r${YELLOW}⚠${NC} %s (timeout after %ds)\n" "$message" "$timeout"
}

# ============================================================================
# Result Summary Functions
# ============================================================================

# Print validation summary
# Usage: print_summary "Validator Name"
print_summary() {
    local validator_name="$1"
    
    echo ""
    echo "=========================================="
    echo "Summary: $validator_name"
    echo "=========================================="
    echo "Errors:   $ERROR_COUNT"
    echo "Warnings: $WARNING_COUNT"
    echo "=========================================="
    echo ""
}

# Return appropriate exit code based on error count
# Usage: exit_with_status
exit_with_status() {
    if [ "$ERROR_COUNT" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# ============================================================================
# Color Output Functions
# ============================================================================

# Print colored header
# Usage: print_header "Header Text"
print_header() {
    local text="$1"
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$text"
    echo -e "==========================================${NC}"
    echo ""
}

# Print colored section
# Usage: print_section "Section Text"
print_section() {
    local text="$1"
    echo ""
    echo -e "${BLUE}→ $text${NC}"
}

# ============================================================================
# Export Functions
# ============================================================================

# Export all functions for use in validators
export -f report_error
export -f report_warning
export -f report_success
export -f report_info
export -f find_files
export -f find_shell_scripts
export -f find_python_files
export -f find_markdown_files
export -f find_makefiles
export -f file_contains
export -f file_contains_ci
export -f count_pattern
export -f find_files_with_pattern
export -f command_exists
export -f is_tracked_by_git
export -f is_gitignored
export -f is_temp_file
export -f is_build_artifact
export -f show_spinner
export -f print_summary
export -f exit_with_status
export -f print_header
export -f print_section
