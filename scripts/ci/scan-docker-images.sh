#!/bin/bash
# Docker Image Vulnerability Scanner
# Scans all Ahab Docker images for security vulnerabilities using Trivy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Configuration
TRIVY_CACHE_DIR="${HOME}/.cache/trivy"
SCAN_RESULTS_DIR="${PROJECT_ROOT}/scan-results"
SEVERITY_LEVELS="CRITICAL,HIGH,MEDIUM"
EXIT_ON_CRITICAL=true

# Images to scan
IMAGES=(
    "ahab/apache:latest"
    "ahab/php:latest" 
    "ahab/validators:latest"
    "python:3.11-slim"
    "nginx:alpine"
)

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Scan Docker images for security vulnerabilities using Trivy.

OPTIONS:
    -h, --help              Show this help message
    -s, --severity LEVELS   Comma-separated severity levels (default: $SEVERITY_LEVELS)
    -o, --output DIR        Output directory for scan results (default: $SCAN_RESULTS_DIR)
    --no-exit-on-critical   Don't exit with error on critical vulnerabilities
    --cache-dir DIR         Trivy cache directory (default: $TRIVY_CACHE_DIR)

EXAMPLES:
    $0                      # Scan all images with default settings
    $0 -s CRITICAL,HIGH     # Only scan for critical and high severity
    $0 --no-exit-on-critical # Don't fail on critical vulnerabilities

EOF
}

check_trivy_installed() {
    if ! command -v trivy &> /dev/null; then
        print_error "Trivy is not installed"
        print_info "Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
        return 1
    fi
    
    print_success "Trivy is installed: $(trivy --version | head -1)"
}

update_trivy_db() {
    print_info "Updating Trivy vulnerability database..."
    
    if trivy image --download-db-only --cache-dir "$TRIVY_CACHE_DIR"; then
        print_success "Trivy database updated"
    else
        print_error "Failed to update Trivy database"
        return 1
    fi
}

scan_image() {
    local image="$1"
    local output_file="$2"
    
    print_info "Scanning image: $image"
    
    # Create JSON report
    if trivy image \
        --format json \
        --severity "$SEVERITY_LEVELS" \
        --cache-dir "$TRIVY_CACHE_DIR" \
        --output "$output_file.json" \
        "$image"; then
        
        # Create human-readable report
        trivy image \
            --format table \
            --severity "$SEVERITY_LEVELS" \
            --cache-dir "$TRIVY_CACHE_DIR" \
            --output "$output_file.txt" \
            "$image"
        
        print_success "Scan completed: $image"
        return 0
    else
        print_error "Scan failed: $image"
        return 1
    fi
}

analyze_results() {
    local results_file="$1"
    
    if [[ ! -f "$results_file" ]]; then
        print_error "Results file not found: $results_file"
        return 1
    fi
    
    # Count vulnerabilities by severity
    local critical_count
    local high_count
    local medium_count
    
    critical_count=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$results_file" 2>/dev/null || echo "0")
    high_count=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$results_file" 2>/dev/null || echo "0")
    medium_count=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$results_file" 2>/dev/null || echo "0")
    
    echo "CRITICAL: $critical_count"
    echo "HIGH: $high_count"
    echo "MEDIUM: $medium_count"
    
    # Return 1 if critical vulnerabilities found and exit_on_critical is true
    if [[ "$EXIT_ON_CRITICAL" == "true" && "$critical_count" -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

generate_summary_report() {
    local summary_file="$SCAN_RESULTS_DIR/summary.txt"
    
    print_info "Generating summary report..."
    
    {
        echo "Docker Image Vulnerability Scan Summary"
        echo "========================================"
        echo "Scan Date: $(date)"
        echo "Severity Levels: $SEVERITY_LEVELS"
        echo ""
        
        for image in "${IMAGES[@]}"; do
            local safe_name
            safe_name=$(echo "$image" | tr '/:' '_')
            local results_file="$SCAN_RESULTS_DIR/${safe_name}.json"
            
            if [[ -f "$results_file" ]]; then
                echo "Image: $image"
                analyze_results "$results_file" | sed 's/^/  /'
                echo ""
            fi
        done
    } > "$summary_file"
    
    print_success "Summary report generated: $summary_file"
}

main() {
    local severity="$SEVERITY_LEVELS"
    local output_dir="$SCAN_RESULTS_DIR"
    local exit_on_critical=true
    local cache_dir="$TRIVY_CACHE_DIR"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -s|--severity)
                severity="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            --no-exit-on-critical)
                exit_on_critical=false
                shift
                ;;
            --cache-dir)
                cache_dir="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Update global variables
    SEVERITY_LEVELS="$severity"
    SCAN_RESULTS_DIR="$output_dir"
    EXIT_ON_CRITICAL="$exit_on_critical"
    TRIVY_CACHE_DIR="$cache_dir"
    
    print_header "Docker Image Vulnerability Scanning"
    
    # Check prerequisites
    check_trivy_installed || exit 1
    
    # Create output directory
    mkdir -p "$SCAN_RESULTS_DIR"
    
    # Update vulnerability database
    update_trivy_db || exit 1
    
    # Scan all images
    local scan_failures=0
    local critical_found=false
    
    for image in "${IMAGES[@]}"; do
        local safe_name
        safe_name=$(echo "$image" | tr '/:' '_')
        local output_file="$SCAN_RESULTS_DIR/${safe_name}"
        
        if scan_image "$image" "$output_file"; then
            # Analyze results
            if ! analyze_results "$output_file.json" > /dev/null; then
                critical_found=true
                print_warning "Critical vulnerabilities found in: $image"
            fi
        else
            ((scan_failures++))
        fi
    done
    
    # Generate summary report
    generate_summary_report
    
    # Report results
    if [[ $scan_failures -gt 0 ]]; then
        print_error "$scan_failures image scans failed"
        exit 1
    fi
    
    if [[ "$critical_found" == "true" && "$EXIT_ON_CRITICAL" == "true" ]]; then
        print_error "Critical vulnerabilities found. See scan results for details."
        print_info "Results directory: $SCAN_RESULTS_DIR"
        exit 1
    fi
    
    print_success "All image scans completed successfully"
    print_info "Results directory: $SCAN_RESULTS_DIR"
}

main "$@"