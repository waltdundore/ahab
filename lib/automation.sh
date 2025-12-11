#!/usr/bin/env bash
# ==============================================================================
# Automation Library - DRY Single Source of Truth
# ==============================================================================
# Shared functions for automation-friendly scripts
# Handles input prompts, force flags, and CI/CD environments
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/automation.sh"
#   check_force_flag "$@"
#   if safe_confirm "Delete files?"; then
#       # proceed with action
#   fi
# ==============================================================================

# Source colors if not already loaded
if [ -z "${AHAB_COLORS_LOADED:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/colors.sh"
fi

#------------------------------------------------------------------------------
# Automation Detection
#------------------------------------------------------------------------------

# Check if running in automated environment
is_automated() {
    # Check for common CI/automation environment variables
    [ -n "${CI:-}" ] || \
    [ -n "${GITHUB_ACTIONS:-}" ] || \
    [ -n "${JENKINS_URL:-}" ] || \
    [ -n "${BUILDKITE:-}" ] || \
    [ -n "${TRAVIS:-}" ] || \
    [ -n "${GITLAB_CI:-}" ] || \
    [ -n "${CIRCLECI:-}" ] || \
    [ "${TERM:-}" = "dumb" ] || \
    [ ! -t 0 ]  # stdin is not a terminal
}

# Check if running in non-interactive mode
is_non_interactive() {
    [ -n "${BATCH_MODE:-}" ] || \
    [ -n "${NON_INTERACTIVE:-}" ] || \
    [ "${DEBIAN_FRONTEND:-}" = "noninteractive" ] || \
    is_automated
}

#------------------------------------------------------------------------------
# Force Flag Handling
#------------------------------------------------------------------------------

# Global variable for force mode
FORCE_MODE=false

# Check command line arguments for force flags
# Usage: check_force_flag "$@"
# Sets global FORCE_MODE=true if --force, --yes, -y, or -f found
check_force_flag() {
    FORCE_MODE=false
    
    for arg in "$@"; do
        case "$arg" in
            --force|--yes|-y|-f|--non-interactive|--batch)
                FORCE_MODE=true
                break
                ;;
        esac
    done
    
    # Also check if automated environment
    if is_automated; then
        FORCE_MODE=true
    fi
    
    # Export for child processes
    export FORCE_MODE
}

# Check if force mode is enabled
is_force_mode() {
    [ "${FORCE_MODE:-false}" = true ]
}

#------------------------------------------------------------------------------
# Safe Input Functions
#------------------------------------------------------------------------------

# Automation-friendly confirmation prompt
# Usage: confirm_action "Delete files?" [default_answer]
# Returns 0 for yes, 1 for no
# In automated environments, uses default or fails safely
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"  # Default to 'no' for safety
    
    # In automated/non-interactive environments, use default
    if is_non_interactive; then
        case "$default" in
            y|Y|yes|YES|true|1)
                print_info "Non-interactive mode: answering YES to '$prompt'"
                return 0
                ;;
            *)
                print_info "Non-interactive mode: answering NO to '$prompt'"
                return 1
                ;;
        esac
    fi
    
    # Interactive environment - prompt user with bounded retries
    local answer
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        read -p "$prompt [y/N]: " -r answer
        case "$answer" in
            y|Y|yes|YES)
                return 0
                ;;
            n|N|no|NO|"")
                return 1
                ;;
            *)
                echo "Please answer y or n (attempt $attempt/$max_attempts)"
                attempt=$((attempt + 1))
                ;;
        esac
    done
    
    # Max attempts reached - default to 'no' for safety
    print_warning "Maximum attempts reached, defaulting to 'no'"
    return 1
}

# Safe confirmation that respects force mode
# Usage: safe_confirm "Delete files?"
# Returns 0 if should proceed, 1 if should abort
safe_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    # If force mode is enabled, always proceed
    if is_force_mode; then
        print_info "Force mode: proceeding with '$prompt'"
        return 0
    fi
    
    # Otherwise use normal confirmation
    confirm_action "$prompt" "$default"
}

# Safe input prompt with timeout and default
# Usage: safe_input "Enter username:" "default_user" 30
# Returns the input or default if timeout/automated
safe_input() {
    local prompt="$1"
    local default="${2:-}"
    local timeout="${3:-30}"
    
    # In automated environments, use default
    if is_non_interactive; then
        if [ -n "$default" ]; then
            print_info "Non-interactive mode: using default '$default' for '$prompt'"
            echo "$default"
            return 0
        else
            print_error "Non-interactive mode: no default provided for '$prompt'"
            return 1
        fi
    fi
    
    # Interactive environment with timeout
    local answer
    if [ -n "$default" ]; then
        read -t "$timeout" -p "$prompt [$default]: " -r answer
        echo "${answer:-$default}"
    else
        read -t "$timeout" -p "$prompt: " -r answer
        echo "$answer"
    fi
}

#------------------------------------------------------------------------------
# Script Argument Parsing
#------------------------------------------------------------------------------

# Show usage information
# Usage: show_usage "script-name" "arguments" "description"
show_usage() {
    local script_name="$1"
    local arguments="$2"
    local description="$3"
    
    echo "Usage: $script_name $arguments"
    echo ""
    echo "$description"
    echo ""
    echo "Options:"
    echo "  -f, --force         Skip confirmation prompts"
    echo "  -y, --yes           Same as --force"
    echo "  --non-interactive   Run in batch mode"
    echo "  -h, --help          Show this help"
    echo ""
}

# Parse common script arguments
# Usage: parse_common_args "$@"
# Sets global variables: FORCE_MODE, HELP_MODE, VERBOSE_MODE
parse_common_args() {
    HELP_MODE=false
    VERBOSE_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force|-y|--yes|--non-interactive|--batch)
                FORCE_MODE=true
                shift
                ;;
            -h|--help)
                HELP_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            *)
                # Unknown option, let calling script handle it
                break
                ;;
        esac
    done
    
    # Export for child processes
    export FORCE_MODE HELP_MODE VERBOSE_MODE
}

#------------------------------------------------------------------------------
# Timeout Protection
#------------------------------------------------------------------------------

# Run command with timeout protection
# Usage: run_with_timeout 300 "long_running_command arg1 arg2"
# Returns command exit code, or 124 if timeout
run_with_timeout() {
    local timeout_seconds="$1"
    shift
    local command="$@"
    
    if command -v timeout >/dev/null 2>&1; then
        # Use GNU timeout if available
        timeout "$timeout_seconds" bash -c "$command"
    else
        # Fallback for systems without timeout command
        (
            eval "$command" &
            local cmd_pid=$!
            
            # Start timeout in background
            (
                sleep "$timeout_seconds"
                kill -TERM "$cmd_pid" 2>/dev/null
                sleep 5
                kill -KILL "$cmd_pid" 2>/dev/null
            ) &
            local timeout_pid=$!
            
            # Wait for command to complete
            wait "$cmd_pid"
            local exit_code=$?
            
            # Kill timeout process
            kill "$timeout_pid" 2>/dev/null
            
            exit $exit_code
        )
    fi
}

# Run command with progress indicator and timeout
# Usage: run_with_progress "Installing packages" 300 "apt-get update && apt-get install -y docker"
run_with_progress() {
    local description="$1"
    local timeout_seconds="$2"
    shift 2
    local command="$@"
    
    print_info "$description (timeout: ${timeout_seconds}s)"
    
    # Write state for debugging
    echo "$description" > .script-state
    
    if run_with_timeout "$timeout_seconds" "$command"; then
        print_success "$description completed"
        rm -f .script-state
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "$description timed out after ${timeout_seconds}s"
            echo "TIMEOUT: $description" >> .script-state
        else
            print_error "$description failed (exit code: $exit_code)"
            echo "FAILED: $description (exit $exit_code)" >> .script-state
        fi
        return $exit_code
    fi
}

#------------------------------------------------------------------------------
# Environment Setup
#------------------------------------------------------------------------------

# Set up automation-friendly environment
# Usage: setup_automation_env
setup_automation_env() {
    # Disable interactive prompts for common tools
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a  # Automatic restart services
    export UCF_FORCE_CONFFNEW=1  # Use new config files
    export ANSIBLE_HOST_KEY_CHECKING=False
    export ANSIBLE_STDOUT_CALLBACK=minimal
    
    # Set locale to avoid encoding issues
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    
    # Disable pager for git and other tools
    export GIT_PAGER=cat
    export PAGER=cat
    
    # Set reasonable defaults for interactive tools
    export EDITOR=nano
    export VISUAL=nano
}

# Check if required environment variables are set
# Usage: require_env_vars "VAR1" "VAR2" "VAR3"
require_env_vars() {
    local missing_vars=()
    
    for var in "$@"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Required environment variables not set:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""
        print_info "Set these variables and try again"
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Logging and State Management
#------------------------------------------------------------------------------

# Initialize logging for automation
# Usage: init_automation_log [log_file]
init_automation_log() {
    local log_file="${1:-.automation.log}"
    
    # Create log file with timestamp
    {
        echo "=========================================="
        echo "Automation Log Started: $(date)"
        echo "Script: ${BASH_SOURCE[1]:-unknown}"
        echo "Arguments: $*"
        echo "Force Mode: ${FORCE_MODE:-false}"
        echo "Automated: $(is_automated && echo true || echo false)"
        echo "=========================================="
    } > "$log_file"
    
    # Export log file location
    export AUTOMATION_LOG="$log_file"
}

# Log automation events
# Usage: log_automation "event description"
log_automation() {
    local message="$1"
    local log_file="${AUTOMATION_LOG:-.automation.log}"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

# Save current state for debugging
# Usage: save_state "current operation"
save_state() {
    local state="$1"
    local state_file="${AUTOMATION_STATE_FILE:-.script-state}"
    
    echo "$state" > "$state_file"
    log_automation "STATE: $state"
}

# Clear saved state
# Usage: clear_state
clear_state() {
    local state_file="${AUTOMATION_STATE_FILE:-.script-state}"
    
    rm -f "$state_file"
    log_automation "STATE: cleared"
}

#------------------------------------------------------------------------------
# Error Handling
#------------------------------------------------------------------------------

# Set up error handling for automation
# Usage: setup_error_handling
setup_error_handling() {
    set -e  # Exit on error
    set -u  # Exit on undefined variable
    set -o pipefail  # Exit on pipe failure
    
    # Trap errors and provide context
    trap 'automation_error_handler $? $LINENO' ERR
}

# Error handler for automation scripts
automation_error_handler() {
    local exit_code=$1
    local line_number=$2
    local script_name="${BASH_SOURCE[1]:-unknown}"
    
    print_error "Script failed at line $line_number (exit code: $exit_code)"
    print_info "Script: $script_name"
    
    # Show current state if available
    if [ -f ".script-state" ]; then
        print_info "Last operation: $(cat .script-state)"
    fi
    
    # Log the error
    log_automation "ERROR: Script failed at line $line_number (exit $exit_code)"
    
    # In automated environments, provide more context
    if is_automated; then
        print_info "Running in automated environment"
        print_info "Check logs for more details: ${AUTOMATION_LOG:-.automation.log}"
    fi
    
    exit $exit_code
}

#------------------------------------------------------------------------------
# Integration with Make Commands
#------------------------------------------------------------------------------

# Check if running via make command
# Usage: is_make_command
is_make_command() {
    [ -n "${MAKELEVEL:-}" ] || \
    [[ "${0##*/}" == "make" ]] || \
    [[ "$0" =~ make ]]
}

# Ensure script is run via make command (following ahab-development.md)
# Usage: require_make_command "test"
require_make_command() {
    local make_target="$1"
    
    if ! is_make_command && ! is_force_mode; then
        print_error "This script should be run via make command"
        print_info "Use: make $make_target"
        print_info "Direct execution bypasses tested interface"
        echo ""
        print_info "To override this check, use: $0 --force"
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------

# Validate that script has automation support
# Usage: validate_automation_support
validate_automation_support() {
    local script_name="${BASH_SOURCE[1]:-unknown}"
    
    # Check if script sources this library
    if [ -z "${AHAB_AUTOMATION_LOADED:-}" ]; then
        print_warning "Script may not have full automation support"
        print_info "Consider sourcing automation.sh library"
    fi
    
    # Check if script handles force flag
    if ! is_force_mode && ! is_automated; then
        print_info "Script supports interactive mode"
    fi
    
    return 0
}

# Mark library as loaded
readonly AHAB_AUTOMATION_LOADED=1

#------------------------------------------------------------------------------
# Usage Examples (for documentation)
#------------------------------------------------------------------------------

# Example 1: Basic automation-friendly script
example_basic_script() {
    cat << 'EOF'
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/automation.sh"

# Parse arguments
check_force_flag "$@"
setup_automation_env
init_automation_log

# Main logic
if safe_confirm "Proceed with operation?"; then
    run_with_progress "Doing work" 60 "sleep 5 && echo done"
    print_success "Operation completed"
else
    print_info "Operation cancelled"
fi
EOF
}

# Example 2: Script with timeout protection
example_timeout_script() {
    cat << 'EOF'
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/automation.sh"

check_force_flag "$@"
setup_error_handling

# Long-running operation with timeout
if ! run_with_timeout 300 "make install"; then
    print_error "Installation timed out or failed"
    exit 1
fi
EOF
}

# Example 3: Make target integration
example_make_target() {
    cat << 'EOF'
.PHONY: example-target
example-target:
	@echo "→ Running: ./scripts/example.sh"
	@echo "   Purpose: Example automation-friendly operation"
	@./scripts/example.sh --force
EOF
}