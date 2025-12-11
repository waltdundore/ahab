#!/usr/bin/env bash
# ==============================================================================
# Pre-Release Checklist Orchestrator (Refactored)
# ==============================================================================
# Coordinates all validation checks and produces final report
#
# Usage: ./scripts/pre-release-check.sh [--strict] [--fix]
#
# Options:
#   --strict    Fail on warnings (not just errors)
#   --fix       Attempt to auto-fix issues where possible
#   --parallel  Run validators in parallel
#   --format    Report format: text, json (default: text)
#   --output    Output file for report
#
# Exit Codes:
#   0 - All checks passed
#   1 - One or more checks failed
#   2 - Invalid arguments
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/pre-release-common.sh
source "$SCRIPT_DIR/lib/pre-release-common.sh"

# Default configuration
STRICT_MODE=false
FIX_MODE=false
PARALLEL_MODE=false
REPORT_FORMAT="text"
REPORT_FILE="pre-release-report.txt"

# Validators to run (in order)
VALIDATORS=(
    "nasa-standards"
    "documentation"
    "code-compliance"
    "security"
    "dependencies"
    "integration"
)

# Argument Parsing

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            --parallel)
                PARALLEL_MODE=true
                shift
                ;;
            --format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --output)
                REPORT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 2
                ;;
        esac
    done
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --strict     Fail on warnings (not just errors)"
    echo "  --fix        Attempt to auto-fix issues where possible"
    echo "  --parallel   Run validators in parallel"
    echo "  --format     Report format: text, json (default: text)"
    echo "  --output     Output file for report"
    echo "  -h, --help   Show this help message"
}

# Main Validation Logic

run_validators_sequential() {
    local passed=0
    local failed=0
    local temp_results
    temp_results=$(mktemp)
    
    for validator in "${VALIDATORS[@]}"; do
        print_info "Running validator: $validator"
        
        local result=0
        case "$validator" in
            "nasa-standards")
                run_nasa_standards_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
            "documentation")
                run_documentation_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
            "code-compliance")
                run_code_compliance_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
            "security")
                run_security_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
            "dependencies")
                run_dependencies_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
            "integration")
                run_integration_validator "$STRICT_MODE" "$FIX_MODE" || result=$?
                ;;
        esac
        
        if [ $result -eq 0 ]; then
            echo "$validator:PASS:" >> "$temp_results"
            ((passed++))
        else
            echo "$validator:FAIL:Validation failed" >> "$temp_results"
            ((failed++))
        fi
    done
    
    # Generate report
    case "$REPORT_FORMAT" in
        "json")
            generate_json_report "$temp_results" "$REPORT_FILE"
            ;;
        *)
            generate_text_report "$temp_results" "$REPORT_FILE"
            ;;
    esac
    
    # Cleanup
    rm -f "$temp_results"
    
    # Print summary
    print_validation_summary "${#VALIDATORS[@]}" "$passed" "$failed"
    
    return $failed
}

# Main Function

main() {
    print_header "PRE-RELEASE VALIDATION"
    
    echo "Configuration:"
    echo "  Strict mode: $STRICT_MODE"
    echo "  Fix mode: $FIX_MODE"
    echo "  Parallel mode: $PARALLEL_MODE"
    echo "  Report format: $REPORT_FORMAT"
    echo "  Report file: $REPORT_FILE"
    echo ""
    
    # Run validators
    local exit_code=0
    if [ "$PARALLEL_MODE" = "true" ]; then
        print_info "Running validators in parallel..."
        run_validators_parallel "${VALIDATORS[@]}" "$STRICT_MODE" "$FIX_MODE" || exit_code=$?
    else
        print_info "Running validators sequentially..."
        run_validators_sequential || exit_code=$?
    fi
    
    # Show report location
    if [ -f "$REPORT_FILE" ]; then
        print_info "Detailed report saved to: $REPORT_FILE"
    fi
    
    exit $exit_code
}

# Parse arguments and run
parse_arguments "$@"
main