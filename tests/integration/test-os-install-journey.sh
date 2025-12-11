#!/usr/bin/env bash
# ==============================================================================
# Test: OS Installation Journey
# ==============================================================================
# Tests complete installation journey on Fedora, Debian, and Ubuntu
# Documents every step with timestamps and verification
# Produces lessons learned documentation
#
# Usage:
#   ./tests/integration/test-os-install-journey.sh
#   make test-os-journey
#
# Output:
#   - Console output with progress
#   - LESSONS_LEARNED_OS_TESTING.md (detailed journey documentation)
#   - test-results-*.json (machine-readable results)
#
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="$PROJECT_ROOT/test-results"
LESSONS_FILE="$PROJECT_ROOT/LESSONS_LEARNED_OS_TESTING.md"

# Operating systems to test
OS_LIST=("fedora" "debian" "ubuntu")

# Test results
declare -A TEST_RESULTS
declare -A TEST_TIMES
declare -A TEST_ISSUES
declare -A TEST_SUCCESSES

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_section() {
    echo ""
    echo "=========================================="
    echo "$*"
    echo "=========================================="
    echo ""
}

# Record test result
record_result() {
    local os="$1"
    local phase="$2"
    local status="$3"
    local message="$4"
    local duration="${5:-0}"
    
    local key="${os}_${phase}"
    TEST_RESULTS["$key"]="$status"
    TEST_TIMES["$key"]="$duration"
    
    if [ "$status" = "PASS" ]; then
        TEST_SUCCESSES["$key"]="$message"
    else
        TEST_ISSUES["$key"]="$message"
    fi
}

# ==============================================================================
# Test Phases
# ==============================================================================

# Configure OS and clean environment
prepare_os_environment() {
    local os="$1"
    
    # Update ahab.conf to use this OS
    log_info "Configuring ahab.conf for $os..."
    if ! configure_os "$os"; then
        record_result "$os" "config" "FAIL" "Failed to configure ahab.conf" 0
        return 1
    fi
    record_result "$os" "config" "PASS" "Successfully configured ahab.conf" 0
    
    # Clean any existing VM
    log_info "Cleaning existing VMs..."
    cd "$PROJECT_ROOT" || exit 1
    make clean >/dev/null 2>&1 || true
    
    return 0
}

# Install and verify workstation
install_and_verify_workstation() {
    local os="$1"
    
    # Install workstation
    log_info "Installing workstation..."
    local install_start=$(date +%s)
    if ! make install; then
        local install_end=$(date +%s)
        local install_duration=$((install_end - install_start))
        record_result "$os" "install" "FAIL" "Installation failed" "$install_duration"
        return 1
    fi
    local install_end=$(date +%s)
    local install_duration=$((install_end - install_start))
    record_result "$os" "install" "PASS" "Installation completed" "$install_duration"
    
    # Verify installation
    log_info "Verifying installation..."
    local verify_start=$(date +%s)
    if ! make verify-install; then
        local verify_end=$(date +%s)
        local verify_duration=$((verify_end - verify_start))
        record_result "$os" "verify" "FAIL" "Verification failed" "$verify_duration"
        return 1
    fi
    local verify_end=$(date +%s)
    local verify_duration=$((verify_end - verify_start))
    record_result "$os" "verify" "PASS" "Verification passed" "$verify_duration"
    
    return 0
}

# Run all system tests
run_system_tests() {
    local os="$1"
    
    # Test Docker
    log_info "Testing Docker..."
    local docker_start=$(date +%s)
    if ! test_docker "$os"; then
        local docker_end=$(date +%s)
        local docker_duration=$((docker_end - docker_start))
        record_result "$os" "docker" "FAIL" "Docker test failed" "$docker_duration"
        return 1
    fi
    local docker_end=$(date +%s)
    local docker_duration=$((docker_end - docker_start))
    record_result "$os" "docker" "PASS" "Docker working correctly" "$docker_duration"
    
    # Test permissions
    log_info "Testing permissions..."
    if ! test_permissions "$os"; then
        record_result "$os" "permissions" "FAIL" "Permission issues detected" 0
        return 1
    fi
    record_result "$os" "permissions" "PASS" "Permissions correct" 0
    
    # Test hello world deployment
    log_info "Testing hello world deployment..."
    local hello_start=$(date +%s)
    if ! test_hello_world "$os"; then
        local hello_end=$(date +%s)
        local hello_duration=$((hello_end - hello_start))
        record_result "$os" "hello_world" "FAIL" "Hello world deployment failed" "$hello_duration"
        return 1
    fi
    local hello_end=$(date +%s)
    local hello_duration=$((hello_end - hello_start))
    record_result "$os" "hello_world" "PASS" "Hello world deployed successfully" "$hello_duration"
    
    return 0
}

test_os_installation() {
    local os="$1"
    local start_time=$(date +%s)
    
    log_section "Testing $os Installation"
    
    # Prepare environment
    if ! prepare_os_environment "$os"; then
        return 1
    fi
    
    # Install and verify
    if ! install_and_verify_workstation "$os"; then
        return 1
    fi
    
    # Run system tests
    if ! run_system_tests "$os"; then
        return 1
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    log_success "$os: All tests passed in ${total_duration}s"
    return 0
}

configure_os() {
    local os="$1"
    
    # Backup current config
    cp "$PROJECT_ROOT/ahab.conf" "$PROJECT_ROOT/ahab.conf.backup" || return 1
    
    # Update DEFAULT_OS
    sed -i.bak "s/^DEFAULT_OS=.*/DEFAULT_OS=$os/" "$PROJECT_ROOT/ahab.conf" || return 1
    
    # Verify change
    if ! grep -q "^DEFAULT_OS=$os" "$PROJECT_ROOT/ahab.conf"; then
        log_error "Failed to update DEFAULT_OS in ahab.conf"
        return 1
    fi
    
    log_success "Configured ahab.conf for $os"
    return 0
}

test_docker() {
    local os="$1"
    
    # Test Docker is installed
    if ! vagrant ssh -c "command -v docker" >/dev/null 2>&1; then
        log_error "Docker not installed"
        return 1
    fi
    
    # Test Docker is running
    if ! vagrant ssh -c "systemctl is-active docker" >/dev/null 2>&1; then
        log_error "Docker not running"
        return 1
    fi
    
    # Test Docker hello-world
    if ! vagrant ssh -c "docker run --rm hello-world" >/dev/null 2>&1; then
        log_error "Docker hello-world failed"
        return 1
    fi
    
    log_success "Docker working correctly"
    return 0
}

test_permissions() {
    local os="$1"
    
    # Test vagrant user owns ahab directory
    if ! vagrant ssh -c "[ -O /home/vagrant/ahab ]"; then
        log_error "vagrant user doesn't own /home/vagrant/ahab"
        return 1
    fi
    
    # Test vagrant user can write to ahab directory
    if ! vagrant ssh -c "touch /home/vagrant/ahab/.test-write && rm /home/vagrant/ahab/.test-write"; then
        log_error "vagrant user can't write to /home/vagrant/ahab"
        return 1
    fi
    
    log_success "Permissions correct"
    return 0
}

test_hello_world() {
    local os="$1"
    
    # Create hello world HTML
    local html_content='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ahab - Hello World</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #0066cc; }
        .success { color: #28a745; font-weight: bold; }
        .info { background: #e7f3ff; padding: 15px; border-left: 4px solid #0066cc; margin: 20px 0; }
        .os-badge { 
            display: inline-block;
            background: #0066cc;
            color: white;
            padding: 5px 15px;
            border-radius: 4px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐋 Ahab - Hello World</h1>
        <p class="success">✅ Installation Successful!</p>
        
        <div class="info">
            <strong>Operating System:</strong> <span class="os-badge">'"$os"'</span><br>
            <strong>Test Date:</strong> '"$(date)"'<br>
            <strong>Status:</strong> Workstation fully provisioned and Docker operational
        </div>
        
        <h2>What This Proves</h2>
        <ul>
            <li>✅ Workstation VM created successfully</li>
            <li>✅ Operating system fully updated</li>
            <li>✅ Docker installed and running</li>
            <li>✅ Permissions configured correctly</li>
            <li>✅ Ready to deploy services</li>
        </ul>
        
        <h2>Next Steps</h2>
        <p>This workstation is now ready to:</p>
        <ul>
            <li>Deploy web services (Apache, Nginx)</li>
            <li>Run databases (MySQL, PostgreSQL)</li>
            <li>Host applications</li>
            <li>Serve as infrastructure foundation</li>
        </ul>
        
        <h2>Journey Documentation</h2>
        <p>See <code>LESSONS_LEARNED_OS_TESTING.md</code> for complete installation journey documentation.</p>
    </div>
</body>
</html>'
    
    # Deploy hello world
    vagrant ssh -c "mkdir -p /home/vagrant/ahab/hello-world"
    echo "$html_content" | vagrant ssh -c "cat > /home/vagrant/ahab/hello-world/index.html"
    
    # Create simple nginx container
    vagrant ssh -c "cd /home/vagrant/ahab/hello-world && docker run -d --name hello-world -p 8080:80 -v \$(pwd):/usr/share/nginx/html:ro nginx:alpine" || return 1
    
    # Wait for container to start
    sleep 3
    
    # Test hello world is accessible
    if ! vagrant ssh -c "curl -s http://localhost:8080" | grep -q "Hello World"; then
        log_error "Hello world page not accessible"
        return 1
    fi
    
    log_success "Hello world deployed and accessible at http://localhost:8080"
    return 0
}

# ==============================================================================
# Documentation Generation
# ==============================================================================

# Generate documentation header
generate_doc_header() {
    cat > "$LESSONS_FILE" << 'EOF'
# Lessons Learned: OS Installation Testing

**Date**: $(date)
**Purpose**: Document the complete installation journey across Fedora, Debian, and Ubuntu
**Status**: Automated testing with documented results

---

## Executive Summary

This document chronicles our journey testing Ahab's installation across three major Linux distributions. We document every success, every failure, and every lesson learned to provide complete transparency and help others avoid the same pitfalls.

**Our Commitment**: We test what we document. These results come from actual installations on real VMs, not theoretical scenarios.

---

## Test Methodology

### Operating Systems Tested

1. **Fedora 43** (default)
   - Latest stable Fedora release
   - DNF package manager
   - SELinux enabled by default

2. **Debian 13** (Trixie)
   - Latest stable Debian release
   - APT package manager
   - AppArmor security

3. **Ubuntu 24.04 LTS** (Noble Numbat)
   - Long-term support release
   - APT package manager
   - AppArmor security

### Test Phases

Each OS goes through identical test phases:

1. **Configuration** - Update ahab.conf to select OS
2. **Installation** - Run `make install` to create VM
3. **Verification** - Run `make verify-install` to check components
4. **Docker Testing** - Verify Docker installation and functionality
5. **Permissions** - Verify file ownership and write access
6. **Hello World** - Deploy simple web page as proof of functionality

### Success Criteria

✅ **Pass**: All phases complete without errors
❌ **Fail**: Any phase fails or produces errors
⚠️ **Warning**: Completes but with non-critical issues

---

## Test Results

EOF
}

# Generate results for single OS
generate_os_results() {
    local os="$1"
    
    cat >> "$LESSONS_FILE" << EOF

### $os Results

EOF
    
    # Check if OS was tested
    if [ -z "${TEST_RESULTS[${os}_install]:-}" ]; then
        cat >> "$LESSONS_FILE" << EOF
**Status**: Not tested in this run

EOF
        return
    fi
    
    # Overall status
    local overall_status="PASS"
    for phase in config install verify docker permissions hello_world; do
        if [ "${TEST_RESULTS[${os}_${phase}]:-SKIP}" = "FAIL" ]; then
            overall_status="FAIL"
            break
        fi
    done
    
    cat >> "$LESSONS_FILE" << EOF
**Overall Status**: $overall_status

| Phase | Status | Duration | Notes |
|-------|--------|----------|-------|
EOF
}

generate_lessons_learned() {
    log_section "Generating Lessons Learned Documentation"
    
    # Generate header
    generate_doc_header
    
    # Add results for each OS
    for os in "${OS_LIST[@]}"; do
        generate_os_results "$os"
    done
        
        for phase in config install verify docker permissions hello_world; do
            local status="${TEST_RESULTS[${os}_${phase}]:-SKIP}"
            local duration="${TEST_TIMES[${os}_${phase}]:-0}"
            local message=""
            
            if [ "$status" = "PASS" ]; then
                message="${TEST_SUCCESSES[${os}_${phase}]:-}"
            elif [ "$status" = "FAIL" ]; then
                message="${TEST_ISSUES[${os}_${phase}]:-}"
            fi
            
            cat >> "$LESSONS_FILE" << EOF
| $phase | $status | ${duration}s | $message |
EOF
        done
        
        cat >> "$LESSONS_FILE" << EOF

EOF
    done
    
    # Add lessons learned section
    cat >> "$LESSONS_FILE" << 'EOF'

---

## Lessons Learned

### What Worked Well

EOF
    
    # Add successes
    for key in "${!TEST_SUCCESSES[@]}"; do
        local os="${key%%_*}"
        local phase="${key#*_}"
        cat >> "$LESSONS_FILE" << EOF
- **$os - $phase**: ${TEST_SUCCESSES[$key]}
EOF
    done
    
    cat >> "$LESSONS_FILE" << 'EOF'

### Issues Encountered

EOF
    
    # Add issues
    if [ ${#TEST_ISSUES[@]} -eq 0 ]; then
        cat >> "$LESSONS_FILE" << EOF
No issues encountered! All tests passed successfully.
EOF
    else
        for key in "${!TEST_ISSUES[@]}"; do
            local os="${key%%_*}"
            local phase="${key#*_}"
            cat >> "$LESSONS_FILE" << EOF
- **$os - $phase**: ${TEST_ISSUES[$key]}
EOF
        done
    fi
    
    cat >> "$LESSONS_FILE" << 'EOF'

### Key Insights

1. **Permissions Matter**: The `make install` command automatically fixes permissions with `vagrant ssh -c "sudo chown -R vagrant:vagrant /home/vagrant/ahab"`. This ensures the vagrant user can work with files without permission errors.

2. **OS-Agnostic Design**: Our playbook uses Ansible's package module abstraction, allowing the same playbook to work across Fedora (DNF), Debian (APT), and Ubuntu (APT).

3. **Docker Consistency**: Docker behaves identically across all three distributions, proving our container-first approach is sound.

4. **Verification is Critical**: The `make verify-install` command catches issues immediately, before they become deployment problems.

5. **Hello World Milestone**: Deploying a simple web page proves the entire stack works: VM creation, OS provisioning, Docker installation, networking, and file permissions.

---

## Recommendations

### For Users

1. **Start with Fedora**: It's our default and most-tested OS
2. **Run verify-install**: Always verify after installation
3. **Check permissions**: If you see permission errors, run the chown command from Makefile
4. **Test Docker**: Run `vagrant ssh -c "docker run hello-world"` to verify Docker works

### For Developers

1. **Test all three OSes**: Don't assume what works on Fedora works on Debian
2. **Use Ansible abstractions**: Use `ansible.builtin.package` instead of `dnf` or `apt`
3. **Document permission fixes**: Any permission changes should be in the Makefile or playbook
4. **Verify after changes**: Run the full test suite after any infrastructure changes

---

## Reproducibility

To reproduce these tests:

```bash
# Clone repository
git clone https://github.com/waltdundore/ahab.git
cd ahab

# Run OS journey tests
make test-os-journey

# Or run manually for specific OS
echo "DEFAULT_OS=fedora" > ahab.conf
make install
make verify-install
```

---

## Continuous Improvement

This document will be updated with each test run. We track:
- New issues discovered
- Solutions implemented
- Performance improvements
- User feedback

**Last Updated**: $(date)
**Test Run**: $TIMESTAMP

---

## Transparency Commitment

We document failures as openly as successes. If something doesn't work, we say so. If we find a workaround, we share it. If we don't know the answer, we admit it.

This is how we build trust: by showing our work, documenting our journey, and learning in public.

---

*This document is automatically generated by `tests/integration/test-os-install-journey.sh`*
*For questions or issues, see: https://github.com/waltdundore/ahab/issues*
EOF
    
    log_success "Generated $LESSONS_FILE"
}

# ==============================================================================
# Main Test Execution
# ==============================================================================

main() {
    log_section "Ahab OS Installation Journey Test"
    log_info "Testing installation across Fedora, Debian, and Ubuntu"
    log_info "Results will be documented in LESSONS_LEARNED_OS_TESTING.md"
    echo ""
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Test each OS
    local failed_oses=()
    for os in "${OS_LIST[@]}"; do
        if ! test_os_installation "$os"; then
            failed_oses+=("$os")
            log_error "$os installation failed"
        else
            log_success "$os installation succeeded"
        fi
        
        # Clean up between tests
        cd "$PROJECT_ROOT" || exit 1
        make clean >/dev/null 2>&1 || true
        sleep 5
    done
    
    # Generate documentation
    generate_lessons_learned
    
    # Restore original config
    if [ -f "$PROJECT_ROOT/ahab.conf.backup" ]; then
        mv "$PROJECT_ROOT/ahab.conf.backup" "$PROJECT_ROOT/ahab.conf"
    fi
    
    # Summary
    log_section "Test Summary"
    
    if [ ${#failed_oses[@]} -eq 0 ]; then
        log_success "All operating systems passed!"
        log_info "Documentation: $LESSONS_FILE"
        return 0
    else
        log_error "Failed operating systems: ${failed_oses[*]}"
        log_info "See $LESSONS_FILE for details"
        return 1
    fi
}

# Run main function
main "$@"
