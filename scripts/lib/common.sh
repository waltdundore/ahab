#!/usr/bin/env bash
# ==============================================================================
# Common Script Functions
# ==============================================================================
# Shared utilities for all scripts
# DRY: Single source of truth for common script operations
#
# This library provides:
# - Error handling functions with empathetic messaging
# - Configuration loading from ahab.conf
# - Input validation and sanitization
# - Cross-platform helper functions
# - Progress feedback utilities
# ==============================================================================

# Color definitions (idempotent - safe to source multiple times)
if [ -z "${RED:-}" ]; then
    readonly RED='\033[0;31m'      # Red text for errors
    readonly GREEN='\033[0;32m'    # Green text for success
    readonly YELLOW='\033[1;33m'   # Yellow text for warnings
    readonly BLUE='\033[0;34m'     # Blue text for info
    readonly NC='\033[0m'          # No Color - reset to default
    readonly RESET='\033[0m'       # Alias for NC (some scripts use RESET)
fi

#------------------------------------------------------------------------------
# Configuration Management
#------------------------------------------------------------------------------

# Global variable to track if config is loaded
_CONFIG_LOADED=false

# Load configuration from ahab.conf
# This function finds ahab.conf by searching up the directory tree
load_config() {
    if [ "$_CONFIG_LOADED" = true ]; then
        return 0
    fi
    
    local config_file="ahab.conf"
    local search_dir="$PWD"
    local max_depth=5
    local depth=0
    
    # Search up the directory tree for ahab.conf
    while [ $depth -lt $max_depth ]; do
        if [ -f "$search_dir/$config_file" ]; then
            # shellcheck source=/dev/null
            source "$search_dir/$config_file"
            _CONFIG_LOADED=true
            return 0
        fi
        
        # Move up one directory
        search_dir="$(dirname "$search_dir")"
        ((depth++))
        
        # Stop if we've reached root
        if [ "$search_dir" = "/" ]; then
            break
        fi
    done
    
    # Config file not found - this is not always an error
    # Some scripts may not need configuration
    return 1
}

# Get configuration value with optional default
# Usage: get_config "KEY_NAME" "default_value"
get_config() {
    local key="$1"
    local default="${2:-}"
    
    # Ensure config is loaded
    load_config || true
    
    # Get the value using indirect expansion
    local value="${!key:-$default}"
    
    echo "$value"
}

# Require a configuration value (fail if not set)
require_config() {
    local key="$1"
    local error_msg="${2:-Configuration value $key is required}"
    
    load_config || die "Configuration file ahab.conf not found"
    
    local value="${!key:-}"
    
    if [ -z "$value" ]; then
        print_error "$error_msg"
        print_info "Add $key to ahab.conf"
        exit 1
    fi
    
    echo "$value"
}

#------------------------------------------------------------------------------
# Output Functions
#------------------------------------------------------------------------------

print_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} ${message}"
}

print_error() {
    local message="$1"
    echo -e "${RED}✗${NC} ${message}" >&2
}

print_info() {
    local message="$1"
    echo -e "${BLUE}→${NC} ${message}"
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} ${message}"
}

print_section() {
    local title="$1"
    echo ""
    echo "=========================================="
    echo "$title"
    echo "=========================================="
    echo ""
}

print_subsection() {
    local title="$1"
    echo ""
    echo "--- $title ---"
    echo ""
}

#------------------------------------------------------------------------------
# Error Handling Functions
#------------------------------------------------------------------------------

die() {
    local message="$1"
    local exit_code="${2:-1}"
    
    print_error "$message"
    exit "$exit_code"
}

require_file() {
    local file="$1"
    local error_msg="${2:-File not found: $file}"
    
    if [ ! -f "$file" ]; then
        die "$error_msg"
    fi
}

require_dir() {
    local dir="$1"
    local error_msg="${2:-Directory not found: $dir}"
    
    if [ ! -d "$dir" ]; then
        die "$error_msg"
    fi
}

require_command() {
    local cmd="$1"
    local install_msg="${2:-Install $cmd to continue}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "$cmd is not installed. $install_msg"
    fi
}

#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------

validate_version_format() {
    local version="$1"
    
    if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version"
        print_info "Version must follow MAJOR.MINOR.PATCH format"
        print_info "Examples:"
        print_info "  ✓ 1.0.0"
        print_info "  ✓ 2.5.3"
        print_info "  ✗ 1.0"
        print_info "  ✗ v1.0.0"
        exit 1
    fi
}

validate_identifier() {
    local identifier="$1"
    local name="${2:-identifier}"
    
    if ! [[ $identifier =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid $name format: $identifier"
        print_info "The $name must contain only:"
        print_info "  - Letters (a-z, A-Z)"
        print_info "  - Numbers (0-9)"
        print_info "  - Hyphens (-)"
        print_info "  - Underscores (_)"
        print_info ""
        print_info "Examples:"
        print_info "  ✓ my-module"
        print_info "  ✓ test_module_123"
        print_info "  ✗ my module (spaces not allowed)"
        print_info "  ✗ my.module (dots not allowed)"
        exit 1
    fi
}

validate_not_empty() {
    local value="$1"
    local name="${2:-value}"
    
    if [ -z "$value" ]; then
        print_error "$name is required"
        exit 1
    fi
}

# Validate and sanitize user input to prevent command injection
# Returns 0 if valid, 1 if invalid
validate_input() {
    local input="$1"
    local pattern="${2:-^[a-zA-Z0-9_-]+$}"
    local name="${3:-input}"
    
    if ! [[ $input =~ $pattern ]]; then
        print_error "Invalid $name: $input"
        print_info "The $name contains invalid characters"
        print_info "This is a security measure to prevent command injection"
        return 1
    fi
    
    return 0
}

# Check if a command exists and provide installation instructions if not
check_command() {
    local cmd="$1"
    local install_instructions="${2:-}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$cmd is not installed"
        print_info "This script requires $cmd to function"
        
        if [ -n "$install_instructions" ]; then
            print_info ""
            print_info "To install $cmd:"
            print_info "  $install_instructions"
        else
            # Provide default installation instructions based on common tools
            case "$cmd" in
                docker)
                    print_info ""
                    print_info "To install Docker:"
                    print_info "  Fedora/RHEL: sudo dnf install docker"
                    print_info "  Debian/Ubuntu: sudo apt install docker.io"
                    print_info "  macOS: brew install docker"
                    print_info "  Or visit: https://docs.docker.com/get-docker/"
                    ;;
                ansible)
                    print_info ""
                    print_info "To install Ansible:"
                    print_info "  pip3 install ansible"
                    print_info "  Or visit: https://docs.ansible.com/ansible/latest/installation_guide/"
                    ;;
                vagrant)
                    print_info ""
                    print_info "To install Vagrant:"
                    print_info "  Visit: https://www.vagrantup.com/downloads"
                    ;;
                git)
                    print_info ""
                    print_info "To install Git:"
                    print_info "  Fedora/RHEL: sudo dnf install git"
                    print_info "  Debian/Ubuntu: sudo apt install git"
                    print_info "  macOS: brew install git"
                    ;;
                make)
                    print_info ""
                    print_info "To install Make:"
                    print_info "  Fedora/RHEL: sudo dnf install make"
                    print_info "  Debian/Ubuntu: sudo apt install make"
                    print_info "  macOS: xcode-select --install"
                    ;;
                *)
                    print_info ""
                    print_info "Please install $cmd and try again"
                    ;;
            esac
        fi
        
        return 1
    fi
    
    return 0
}

# Check if a file exists with helpful error message
check_file() {
    local file="$1"
    local error_msg="${2:-}"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        
        if [ -n "$error_msg" ]; then
            print_info "$error_msg"
        else
            print_info "This file is required for the script to work"
            print_info "Please ensure the file exists and try again"
        fi
        
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Git Functions
#------------------------------------------------------------------------------

check_git_repo() {
    if [ ! -d ".git" ]; then
        die "Not a git repository. Run this from the repository root."
    fi
}

check_git_clean() {
    if ! git diff-index --quiet HEAD --; then
        print_error "You have uncommitted changes"
        echo ""
        git status --short
        echo ""
        die "Commit or stash changes before continuing"
    fi
}

check_git_tag_exists() {
    local tag="$1"
    
    if git rev-parse "$tag" >/dev/null 2>&1; then
        die "Tag $tag already exists"
    fi
}

check_git_branch_exists() {
    local branch="$1"
    
    if git rev-parse "origin/$branch" >/dev/null 2>&1; then
        die "Branch $branch already exists on remote"
    fi
}

get_current_commit() {
    git rev-parse HEAD
}

get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

#------------------------------------------------------------------------------
# YAML Functions
#------------------------------------------------------------------------------

check_yaml_field() {
    local file="$1"
    local field="$2"
    local error_msg="${3:-Missing required field: $field}"
    
    if ! grep -q "^${field}:" "$file"; then
        die "$error_msg"
    fi
}

get_yaml_value() {
    local file="$1"
    local field="$2"
    
    grep "^${field}:" "$file" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | tr -d '"'
}

check_yaml_placeholders() {
    local file="$1"
    
    if grep -i "PLACEHOLDER" "$file" >/dev/null 2>&1; then
        print_error "Found PLACEHOLDER values in $file"
        grep -n -i "PLACEHOLDER" "$file" | head -5
        return 1
    fi
    
    if grep "REQUIRED:" "$file" >/dev/null 2>&1; then
        print_error "Found REQUIRED: placeholder text in $file"
        grep -n "REQUIRED:" "$file" | head -5
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# File Operations
#------------------------------------------------------------------------------

create_backup() {
    local file="$1"
    local backup="${file}.bak"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup"
        print_info "Created backup: $backup"
    fi
}

safe_remove() {
    local path="$1"
    
    if [ -e "$path" ]; then
        rm -rf "$path"
        print_info "Removed: $path"
    fi
}

ensure_dir() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_info "Created directory: $dir"
    fi
}

#------------------------------------------------------------------------------
# Prerequisite Checking
#------------------------------------------------------------------------------

check_prerequisites() {
    local -a required_commands=("$@")
    local missing=0
    
    print_info "Checking prerequisites..."
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_success "$cmd installed"
        else
            print_error "$cmd not installed"
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        echo ""
        die "Please install missing prerequisites"
    fi
    
    echo ""
}

#------------------------------------------------------------------------------
# Counter Functions (for validation scripts)
#------------------------------------------------------------------------------

init_counters() {
    ERRORS=0
    WARNINGS=0
    TOTAL_CHECKS=0
}

increment_error() {
    ((ERRORS++)) || true
}

increment_warning() {
    ((WARNINGS++)) || true
}

increment_check() {
    ((TOTAL_CHECKS++)) || true
}

print_summary() {
    local script_name="${1:-Script}"
    
    echo ""
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo "Total checks: $TOTAL_CHECKS"
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    
    if [ $ERRORS -eq 0 ]; then
        print_success "$script_name validation passed"
        return 0
    else
        print_error "$script_name validation failed with $ERRORS error(s)"
        if [ $WARNINGS -gt 0 ]; then
            print_warning "Also found $WARNINGS warning(s)"
        fi
        return 1
    fi
}

#------------------------------------------------------------------------------
# Argument Parsing Helpers
#------------------------------------------------------------------------------

show_usage() {
    local script_name="$1"
    local usage_text="$2"
    
    echo "Usage: $script_name $usage_text"
    echo ""
}

require_arg() {
    local arg_value="$1"
    local arg_name="$2"
    local usage="$3"
    
    if [ -z "$arg_value" ]; then
        print_error "$arg_name is required"
        echo ""
        show_usage "$(basename "$0")" "$usage"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Module Registry Functions
#------------------------------------------------------------------------------

get_module_info() {
    local module_name="$1"
    local field="$2"
    local registry="${3:-MODULE_REGISTRY.yml}"
    
    require_file "$registry" "MODULE_REGISTRY.yml not found"
    
    # Extract value using yq or grep
    if command -v yq >/dev/null 2>&1; then
        yq eval ".modules[] | select(.name == \"$module_name\") | .$field" "$registry"
    else
        # Fallback to grep (less reliable but works without yq)
        awk "/name: $module_name/,/^[[:space:]]*-/ {print}" "$registry" | grep "^[[:space:]]*$field:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | tr -d '"'
    fi
}

check_module_exists() {
    local module_name="$1"
    local registry="${2:-MODULE_REGISTRY.yml}"
    
    local repo
    repo=$(get_module_info "$module_name" "repository" "$registry")
    
    if [ "$repo" = "null" ] || [ -z "$repo" ]; then
        die "Module '$module_name' not found in registry"
    fi
}

#------------------------------------------------------------------------------
# Cross-Platform Helper Functions
#------------------------------------------------------------------------------

# Detect the operating system
# Returns: linux, darwin (macOS), or unknown
detect_os() {
    local os
    os="$(uname -s)"
    
    case "$os" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "darwin"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Cross-platform sed in-place editing
# Usage: sed_inplace 's/old/new/g' file.txt
sed_inplace() {
    local expression="$1"
    local file="$2"
    
    local os
    os=$(detect_os)
    
    case "$os" in
        darwin)
            # macOS requires empty string after -i
            sed -i '' "$expression" "$file"
            ;;
        linux)
            # Linux doesn't need the empty string
            sed -i "$expression" "$file"
            ;;
        *)
            print_warning "Unknown OS, attempting Linux-style sed"
            sed -i "$expression" "$file"
            ;;
    esac
}

# Get the number of CPU cores (cross-platform)
get_cpu_count() {
    local os
    os=$(detect_os)
    
    case "$os" in
        darwin)
            sysctl -n hw.ncpu
            ;;
        linux)
            nproc
            ;;
        *)
            echo "1"  # Safe default
            ;;
    esac
}

#------------------------------------------------------------------------------
# Progress Feedback Functions
#------------------------------------------------------------------------------

# Write current state to diagnostic file for troubleshooting
# This helps debug scripts that might hang or take a long time
write_state() {
    local state="$1"
    local state_file="${2:-.script-state}"
    
    echo "$state" > "$state_file"
}

# Clear the diagnostic state file
clear_state() {
    local state_file="${1:-.script-state}"
    
    if [ -f "$state_file" ]; then
        rm -f "$state_file"
    fi
}

# Show progress for processing multiple items
# Usage: show_progress 5 10 "Processing files"
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    
    echo -ne "\r${BLUE}→${NC} $message [$current/$total]"
    
    # Add newline if we're done
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Simple spinner for long-running operations
# Usage: start_spinner "Loading..." ; long_operation ; stop_spinner
start_spinner() {
    local message="${1:-Working}"
    local timeout="${2:-300}"  # Default 5 minute timeout
    
    # Start spinner in background
    (
        local spin='-\|/'
        local i=0
        local count=0
        local max_iterations=$((timeout * 10))  # 0.1s sleep = 10 iterations per second
        
        while [ $count -lt $max_iterations ]; do
            i=$(( (i+1) %4 ))
            printf "\r${BLUE}→${NC} %s %s" "$message" "${spin:$i:1}"
            sleep 0.1
            count=$((count + 1))
        done
        
        # Timeout reached
        printf "\r${YELLOW}⚠${NC} %s (timeout after %ds)\n" "$message" "$timeout"
    ) &
    
    # Save spinner PID
    SPINNER_PID=$!
}

stop_spinner() {
    if [ -n "${SPINNER_PID:-}" ]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        unset SPINNER_PID
        printf "\r"
    fi
}

#------------------------------------------------------------------------------
# Test Assertion Functions
#------------------------------------------------------------------------------
# Functions for writing tests - consolidated from shell-common.sh
# These provide test-friendly assertions with clear error messages
#------------------------------------------------------------------------------

# Assert command exists
# Usage: assert_command "docker" "Docker must be installed"
assert_command() {
    local cmd="$1"
    local error_msg="${2:-Command '$cmd' not found}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert file exists
# Usage: assert_file_exists "config.yml" "Config file is required"
assert_file_exists() {
    local file="$1"
    local error_msg="${2:-File '$file' does not exist}"
    
    if [ ! -f "$file" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert directory exists
# Usage: assert_dir_exists "/path/to/dir" "Directory must exist"
assert_dir_exists() {
    local dir="$1"
    local error_msg="${2:-Directory '$dir' does not exist}"
    
    if [ ! -d "$dir" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string equals
# Usage: assert_equals "expected" "$actual" "Values should match"
assert_equals() {
    local expected="$1"
    local actual="$2"
    local error_msg="${3:-Expected '$expected' but got '$actual'}"
    
    if [ "$expected" != "$actual" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string not empty
# Usage: assert_not_empty "$value" "Value cannot be empty"
assert_not_empty() {
    local value="$1"
    local error_msg="${2:-Value is empty}"
    
    if [ -z "$value" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert string contains substring
# Usage: assert_contains "$haystack" "needle" "Should contain needle"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local error_msg="${3:-String does not contain '$needle'}"
    
    if [[ ! "$haystack" =~ $needle ]]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Assert exit code equals expected
# Usage: assert_exit_code 0 $? "Command should succeed"
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local error_msg="${3:-Expected exit code $expected but got $actual}"
    
    if [ "$expected" -ne "$actual" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Print header (larger than section)
# Usage: print_header "MAIN AUDIT REPORT"
print_header() {
    local message="$1"
    echo ""
    echo "=========================================="
    echo "$message"
    echo "=========================================="
    echo ""
}

#------------------------------------------------------------------------------
# Enhanced Error Message Functions
#------------------------------------------------------------------------------
# Added: 2025-12-08
# Purpose: Provide helpful, actionable error messages
# Core Principles: #4 (Never Assume Success), #10 (Teaching Mindset)
#------------------------------------------------------------------------------

# Print error with full context and guidance
# Usage: print_error_detailed "message" "context" "action" "link"
# Example:
#   print_error_detailed \
#       "VM name required" \
#       "This script connects to a virtual machine via SSH" \
#       "Run: $0 workstation" \
#       "https://github.com/${GITHUB_USER}/ahab/blob/prod/README.md"
print_error_detailed() {
    local message="$1"
    local context="${2:-}"
    local action="${3:-}"
    local link="${4:-}"
    
    echo -e "${RED}✗ ERROR${NC}: $message" >&2
    echo "" >&2
    
    if [ -n "$context" ]; then
        echo "Context: $context" >&2
        echo "" >&2
    fi
    
    if [ -n "$action" ]; then
        echo "What to try:" >&2
        echo "  $action" >&2
        echo "" >&2
    fi
    
    if [ -n "$link" ]; then
        echo "More help: $link" >&2
        echo "" >&2
    fi
}

# Print error with command suggestion
# Usage: print_error_with_command "message" "command"
# Example:
#   print_error_with_command \
#       "Configuration file not found" \
#       "cp ahab.conf.example ahab.conf"
print_error_with_command() {
    local message="$1"
    local command="$2"
    
    echo -e "${RED}✗ ERROR${NC}: $message" >&2
    echo "" >&2
    echo "Try running:" >&2
    echo "  ${BLUE}$command${NC}" >&2
    echo "" >&2
}

# Print error with multiple options
# Usage: print_error_with_options "message" "option1" "option2" "option3"
# Example:
#   print_error_with_options \
#       "No terminal emulator found" \
#       "Install iTerm2: brew install --cask iterm2" \
#       "Install Terminal.app (built-in on macOS)" \
#       "Install Alacritty: brew install --cask alacritty"
print_error_with_options() {
    local message="$1"
    shift
    
    echo -e "${RED}✗ ERROR${NC}: $message" >&2
    echo "" >&2
    echo "Try one of these:" >&2
    for option in "$@"; do
        echo "  • $option" >&2
    done
    echo "" >&2
}

# Print error for missing prerequisite
# Usage: print_error_missing_prereq "tool" "install_command" "link"
# Example:
#   print_error_missing_prereq \
#       "docker" \
#       "brew install --cask docker" \
#       "https://docs.docker.com/get-docker/"
print_error_missing_prereq() {
    local tool="$1"
    local install_cmd="$2"
    local link="${3:-}"
    
    echo -e "${RED}✗ ERROR${NC}: $tool is not installed" >&2
    echo "" >&2
    echo "Context: This script requires $tool to function" >&2
    echo "" >&2
    echo "To install:" >&2
    echo "  ${BLUE}$install_cmd${NC}" >&2
    echo "" >&2
    
    if [ -n "$link" ]; then
        echo "Installation guide: $link" >&2
        echo "" >&2
    fi
}

# Print error for invalid input with examples
# Usage: print_error_invalid_input "input" "field_name" "valid_example1" "valid_example2"
# Example:
#   print_error_invalid_input \
#       "v1.0" \
#       "version number" \
#       "1.0.0" \
#       "2.5.3"
print_error_invalid_input() {
    local input="$1"
    local field_name="$2"
    shift 2
    
    echo -e "${RED}✗ ERROR${NC}: Invalid $field_name: $input" >&2
    echo "" >&2
    echo "Valid examples:" >&2
    for example in "$@"; do
        echo "  ${GREEN}✓${NC} $example" >&2
    done
    echo "" >&2
}

#------------------------------------------------------------------------------
# END OF COMMON LIBRARY
#------------------------------------------------------------------------------
# All common functions consolidated here from:
#   - scripts/lib/shell-common.sh (merged 2024-12-08)
#   - scripts/lib/colors.sh (colors already included)
#
# This is the SINGLE SOURCE OF TRUTH for common shell functions.
# DO NOT create duplicate functions in other files.
# ALWAYS source this file instead.
#------------------------------------------------------------------------------
