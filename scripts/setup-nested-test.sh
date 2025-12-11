#!/usr/bin/env bash
# ==============================================================================
# Ahab Nested Test Setup Script (Refactored)
# ==============================================================================
# Automatically sets up the nested testing environment for Ahab
#
# This script:
#   1. Checks prerequisites on your workstation
#   2. Creates test directory structure
#   3. Generates Vagrantfiles for Fedora and Debian
#   4. Provides instructions for running tests
#
# Usage:
#   ./setup-nested-test.sh [options]
#
# Options:
#   --test-dir DIR    Test directory (default: ~/ahab-nested-test)
#   --skip-checks     Skip prerequisite checks
#   --help            Show this help message
# ==============================================================================

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/setup-common.sh
source "$SCRIPT_DIR/lib/setup-common.sh"
# shellcheck source=./lib/nested-test-common.sh
source "$SCRIPT_DIR/lib/nested-test-common.sh"

# Configuration
TEST_DIR="${HOME}/ahab-nested-test"
SKIP_CHECKS=false

# Argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-dir)
                TEST_DIR="$2"
                shift 2
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
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
    echo "  --test-dir DIR    Test directory (default: ~/ahab-nested-test)"
    echo "  --skip-checks     Skip prerequisite checks"
    echo "  -h, --help        Show this help message"
}

# Main function
main() {
    parse_arguments "$@"
    
    print_header "AHAB NESTED TEST SETUP"
    
    echo "Setting up nested testing environment for Ahab"
    echo "Test directory: $TEST_DIR"
    echo ""
    
    # Check prerequisites unless skipped
    if [ "$SKIP_CHECKS" = "false" ]; then
        if ! check_prerequisites; then
            print_error "Prerequisites check failed"
            echo "Use --skip-checks to bypass this check"
            exit 1
        fi
    else
        print_warning "Skipping prerequisite checks"
    fi
    
    # Create directory structure
    create_test_directory_structure "$TEST_DIR"
    
    # Generate Vagrantfiles
    generate_fedora_vagrantfile "$TEST_DIR"
    generate_debian_vagrantfile "$TEST_DIR"
    
    # Generate test scripts
    generate_test_scripts "$TEST_DIR"
    
    # Generate documentation
    generate_test_documentation "$TEST_DIR"
    
    # Print summary
    print_setup_summary "$TEST_DIR"
}

# Run main function
main "$@"