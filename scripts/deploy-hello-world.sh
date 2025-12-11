#!/usr/bin/env bash
# ==============================================================================
# Deploy Hello World
# ==============================================================================
# Deploys a simple hello world web page to prove workstation functionality
#
# Usage:
#   ./scripts/deploy-hello-world.sh [os_name]
#
# Example:
#   ./scripts/deploy-hello-world.sh fedora
#
# ==============================================================================

set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Get OS name (default to current)
OS_NAME="${1:-$(grep '^DEFAULT_OS=' ../ahab.conf 2>/dev/null | cut -d'=' -f2 || echo 'unknown')}"

# Load GitHub user from config
# shellcheck disable=SC2034
GITHUB_USER=$(get_config "GITHUB_USER" "waltdundore")

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "=========================================="
echo "Deploying Hello World"
echo "=========================================="
echo ""

# Generate HTML from template
generate_hello_world_html() {
    local template_file="$SCRIPT_DIR/templates/hello-world.html"
    local output_file="hello-world.html"
    local deploy_time
    
    deploy_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    print_info "Generating hello world HTML..."
    
    # Check if template exists
    if [ ! -f "$template_file" ]; then
        print_error "Template file not found: $template_file"
        return 1
    fi
    
    # Replace placeholders in template
    sed -e "s/{{OS_NAME}}/$OS_NAME/g" \
        -e "s/{{DEPLOY_TIME}}/$deploy_time/g" \
        -e "s/{{GITHUB_USER}}/$GITHUB_USER/g" \
        "$template_file" > "$output_file"
    
    print_success "Generated: $output_file"
}

# Deploy to workstation
deploy_to_workstation() {
    local html_file="hello-world.html"
    
    print_info "Deploying to workstation..."
    
    # Check if workstation is running
    if ! vagrant status | grep -q "running"; then
        print_error "Workstation is not running. Start it with: make install"
        return 1
    fi
    
    # Copy file to workstation
    vagrant upload "$html_file" "/tmp/$html_file"
    
    # Move to web directory and start simple server
    vagrant ssh -c "
        sudo mkdir -p /var/www/html
        sudo cp /tmp/$html_file /var/www/html/index.html
        sudo chown -R www-data:www-data /var/www/html 2>/dev/null || sudo chown -R apache:apache /var/www/html 2>/dev/null || true
        sudo chmod 644 /var/www/html/index.html
        
        # Start simple Python web server if no web server is running
        if ! sudo netstat -tlnp | grep -q ':80 '; then
            echo 'Starting simple web server on port 8080...'
            cd /var/www/html
            nohup python3 -m http.server 8080 > /dev/null 2>&1 &
            echo 'Web server started'
        fi
    "
    
    print_success "Deployed to workstation"
}

# Get workstation IP
get_workstation_info() {
    print_info "Getting workstation information..."
    
    local ip_address
    ip_address=$(vagrant ssh -c "hostname -I | awk '{print \$1}'" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "$ip_address" ]; then
        echo ""
        echo -e "${GREEN}✓ Deployment Complete!${NC}"
        echo ""
        echo "Access your hello world page:"
        echo "  • From host: http://localhost:8080 (if port forwarded)"
        echo "  • From workstation: http://$ip_address:8080"
        echo "  • SSH to workstation: make ssh"
        echo ""
        echo "To view in workstation:"
        echo "  vagrant ssh -c 'curl http://localhost:8080'"
        echo ""
    else
        print_warning "Could not determine workstation IP address"
    fi
}

# Cleanup function
cleanup() {
    print_info "Cleaning up temporary files..."
    rm -f hello-world.html
}

# Main execution
main() {
    print_header "HELLO WORLD DEPLOYMENT"
    
    echo "Deploying hello world page for $OS_NAME workstation"
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Generate HTML
    if ! generate_hello_world_html; then
        print_error "Failed to generate HTML"
        exit 1
    fi
    
    # Deploy to workstation
    if ! deploy_to_workstation; then
        print_error "Failed to deploy to workstation"
        exit 1
    fi
    
    # Show access information
    get_workstation_info
    
    print_success "Hello world deployment completed successfully!"
}

# Run main function
main "$@"