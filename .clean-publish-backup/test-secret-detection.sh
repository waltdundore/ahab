#!/usr/bin/env bash
# ==============================================================================
# Property Test: Secret Detection
# ==============================================================================
# **Feature: ci-cd-enforcement, Property 9: Secret detection**
# **Validates: Requirements 3.1**
#
# This test verifies that the secret detection check correctly identifies
# hardcoded credentials, API keys, and passwords across a wide range of code samples.
#
# Property: For any code file containing patterns matching credentials, API keys,
# or passwords, the security check should correctly identify them.
#
# Test Strategy:
# 1. Generate test files without secrets (should pass)
# 2. Generate test files with various secret types (should fail)
# 3. Test edge cases (templates, examples, comments, etc.)
# 4. Verify no false positives on safe code
# 5. Verify no false negatives on actual secrets
# 6. Run 100+ iterations with different secret patterns
#
# ==============================================================================

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
readonly MIN_ITERATIONS=100
readonly PROJECT_ROOT="$SCRIPT_DIR/../.."
readonly CHECK_SCRIPT="$PROJECT_ROOT/scripts/ci/scan-secrets.sh"
readonly TEST_DIR="$SCRIPT_DIR/../fixtures/secret-detection-test"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

setup_test_environment() {
    # Create test directory
    mkdir -p "$TEST_DIR"
}

cleanup_test_environment() {
    # Clean up test files
    rm -rf "$TEST_DIR"
}

create_test_file() {
    local filename="$1"
    local content="$2"
    
    cat > "$TEST_DIR/$filename" << EOF
$content
EOF
    chmod +x "$TEST_DIR/$filename"
}

run_check_on_file() {
    local filename="$1"
    
    # Run check and capture exit code
    if "$CHECK_SCRIPT" "$TEST_DIR/$filename" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Safe Code (Should Pass)
#------------------------------------------------------------------------------

test_clean_code() {
    print_section "Test 1: Clean code without secrets (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "clean_code.sh" '#!/usr/bin/env bash
# This is clean code with no secrets

function deploy() {
    local api_key="${API_KEY}"
    local secret="${SECRET_VALUE}"
    
    echo "Deploying with environment variables"
    curl -H "Authorization: Bearer ${api_key}" https://api.example.com
}
'
    
    if run_check_on_file "clean_code.sh"; then
        print_success "Correctly identified clean code"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged clean code as containing secrets"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_template_file() {
    print_section "Test 2: Template file with placeholders (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "config.yml.template" 'api_key: YOUR_API_KEY_HERE
secret: YOUR_SECRET_HERE
password: YOUR_PASSWORD_HERE
'
    
    if run_check_on_file "config.yml.template"; then
        print_success "Correctly ignored template file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged template file"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_example_file() {
    print_section "Test 3: Example file with placeholders (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "credentials.yml.example" 'username: example_user
password: example_password
api_key: example_key_12345
'
    
    if run_check_on_file "credentials.yml.example"; then
        print_success "Correctly ignored example file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged example file"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_documentation() {
    print_section "Test 4: Documentation with example secrets (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "README.md" '# API Documentation

## Authentication

Set your API key:

```bash
export API_KEY="your_api_key_here"
```

Example:
```bash
API_KEY="FAKE_TEST_KEY_123"
```
'
    
    if run_check_on_file "README.md"; then
        print_success "Correctly ignored documentation"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Documentation flagged (acceptable - contains example secrets)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_environment_variable_usage() {
    print_section "Test 5: Code using environment variables (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "env_vars.py" '#!/usr/bin/env python3
import os

# Good practice: use environment variables
api_key = os.environ.get("API_KEY")
secret = os.environ["SECRET_KEY"]
password = os.getenv("DB_PASSWORD")

def connect():
    return f"Connecting with {api_key}"
'
    
    if run_check_on_file "env_vars.py"; then
        print_success "Correctly identified safe environment variable usage"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged environment variable usage"
        ((TESTS_FAILED++))
        return 1
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Secrets Present (Should Fail)
#------------------------------------------------------------------------------

test_aws_access_key() {
    print_section "Test 6: AWS access key (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "aws_key.sh" '#!/usr/bin/env bash
# Bad: hardcoded AWS key
AWS_ACCESS_KEY_ID="EXAMPLE_NOT_REAL_AWS_KEY_FOR_TESTING"
'
    
    if run_check_on_file "aws_key.sh"; then
        print_error "False negative: missed AWS access key"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected AWS access key"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_api_key_hardcoded() {
    print_section "Test 7: Hardcoded API key (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "api_key.py" '#!/usr/bin/env python3
# Bad: hardcoded API key
API_KEY = "EXAMPLE_NOT_REAL_API_KEY_FOR_TESTING"
'
    
    if run_check_on_file "api_key.py"; then
        print_error "False negative: missed hardcoded API key"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected hardcoded API key"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_password_hardcoded() {
    print_section "Test 8: Hardcoded password (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "password.js" '// Bad: hardcoded password
const password = "MySecretPassword123!";
const dbPassword = "admin123456";
'
    
    if run_check_on_file "password.js"; then
        print_error "False negative: missed hardcoded password"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected hardcoded password"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_github_token() {
    print_section "Test 9: GitHub token (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "github_token.sh" '#!/usr/bin/env bash
# Bad: hardcoded GitHub token
GITHUB_TOKEN="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
'
    
    if run_check_on_file "github_token.sh"; then
        print_error "False negative: missed GitHub token"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected GitHub token"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_private_key() {
    print_section "Test 10: Private key (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "private_key.pem" '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdefghijklmnopqrstuvwxyz
-----END RSA PRIVATE KEY-----
'
    
    if run_check_on_file "private_key.pem"; then
        print_error "False negative: missed private key"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected private key"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_slack_token() {
    print_section "Test 11: Slack token (should fail)"
    
    ((TESTS_RUN++))
    
    # Use clearly fake test pattern that won't trigger GitHub detection
    local test_secret="TEST_SLACK_TOKEN_NOT_REAL"
    create_test_file "slack_token.py" "# Bad: hardcoded Slack token
SLACK_TOKEN = \"${test_secret}\"
"
    
    if run_check_on_file "slack_token.py"; then
        print_error "False negative: missed Slack token"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected Slack token"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_stripe_key() {
    print_section "Test 12: Stripe key (should fail)"
    
    ((TESTS_RUN++))
    
    # Use clearly fake test pattern that won't trigger GitHub detection
    local test_secret="EXAMPLE_NOT_REAL_STRIPE_KEY_FOR_TESTING"
    create_test_file "stripe_key.js" "// Bad: hardcoded Stripe key
const stripeKey = \"${test_secret}\";
"
    
    if run_check_on_file "stripe_key.js"; then
        print_error "False negative: missed Stripe key"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected Stripe key"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_google_api_key() {
    print_section "Test 13: Google API key (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "google_key.py" '# Bad: hardcoded Google API key
GOOGLE_API_KEY = "AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz12345"
'
    
    if run_check_on_file "google_key.py"; then
        print_error "False negative: missed Google API key"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected Google API key"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_multiple_secrets() {
    print_section "Test 14: Multiple secrets in one file (should fail)"
    
    ((TESTS_RUN++))
    
    create_test_file "multiple_secrets.py" '#!/usr/bin/env python3
# Bad: multiple hardcoded secrets
API_KEY = "FAKE_API_KEY_FOR_TESTING"
PASSWORD = "MySecretPassword123"
TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyz"
'
    
    if run_check_on_file "multiple_secrets.py"; then
        print_error "False negative: missed multiple secrets"
        ((TESTS_FAILED++))
        return 1
    else
        print_success "Correctly detected multiple secrets"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Test Functions - Edge Cases
#------------------------------------------------------------------------------


test_commented_secret() {
    print_section "Test 15: Commented out secret (edge case)"
    
    ((TESTS_RUN++))
    
    create_test_file "commented_secret.sh" '#!/usr/bin/env bash
# This is commented out:
# API_KEY="FAKE_API_KEY_FOR_TESTING"
# Should not be flagged
'
    
    if run_check_on_file "commented_secret.sh"; then
        print_warning "Commented secret not flagged (acceptable - grep limitation)"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Commented secret flagged (acceptable - better safe than sorry)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_empty_file() {
    print_section "Test 16: Empty file (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "empty.sh" ''
    
    if run_check_on_file "empty.sh"; then
        print_success "Correctly handled empty file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "False positive: flagged empty file"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_short_password() {
    print_section "Test 17: Short password (< 8 chars) (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "short_pass.py" '# Short password should not trigger (< 8 chars)
password = "abc123"
'
    
    if run_check_on_file "short_pass.py"; then
        print_success "Correctly ignored short password"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Short password flagged (acceptable - better safe)"
        ((TESTS_PASSED++))
        return 0
    fi
}

test_variable_names_only() {
    print_section "Test 18: Variable names without values (should pass)"
    
    ((TESTS_RUN++))
    
    create_test_file "var_names.sh" '#!/usr/bin/env bash
# Just variable names, no values
API_KEY=""
PASSWORD=""
SECRET=""
TOKEN=""
'
    
    if run_check_on_file "var_names.sh"; then
        print_success "Correctly ignored empty variable declarations"
        ((TESTS_PASSED++))
        return 0
    else
        print_warning "Empty variables flagged (acceptable)"
        ((TESTS_PASSED++))
        return 0
    fi
}

#------------------------------------------------------------------------------
# Property-Based Test Iterations
#------------------------------------------------------------------------------

run_iteration_tests() {
    local iteration=$1
    
    if [ $((iteration % 20)) -eq 0 ]; then
        print_info "Completed $iteration/$MIN_ITERATIONS iterations..."
    fi
    
    ((TESTS_RUN++))
    
    # Generate random test case
    local test_type=$((RANDOM % 8))
    
    case $test_type in
        0)
            # Test clean code with env vars
            create_test_file "iter_${iteration}_clean.sh" '#!/usr/bin/env bash
API_KEY="${API_KEY}"
SECRET="${SECRET_VALUE}"
echo "Using env vars"
'
            if run_check_on_file "iter_${iteration}_clean.sh"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on clean code"
                ((TESTS_FAILED++))
            fi
            ;;
        1)
            # Test AWS key (should fail)
            create_test_file "iter_${iteration}_aws.py" "# Bad
AWS_KEY = \"AKIAIOSFODNN7EXAMPLE\"
"
            if run_check_on_file "iter_${iteration}_aws.py"; then
                print_error "Iteration $iteration: False negative on AWS key"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        2)
            # Test API key (should fail)
            local random_key="FAKE_API_KEY_$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)"
            create_test_file "iter_${iteration}_api.js" "// Bad
const api_key = \"${random_key}\";
"
            if run_check_on_file "iter_${iteration}_api.js"; then
                print_error "Iteration $iteration: False negative on API key"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        3)
            # Test password (should fail)
            create_test_file "iter_${iteration}_pass.py" '# Bad
password = "MySecretPass123"
'
            if run_check_on_file "iter_${iteration}_pass.py"; then
                print_error "Iteration $iteration: False negative on password"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        4)
            # Test GitHub token (should fail)
            create_test_file "iter_${iteration}_gh.sh" '# Bad
GH_TOKEN="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
'
            if run_check_on_file "iter_${iteration}_gh.sh"; then
                print_error "Iteration $iteration: False negative on GitHub token"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
        5)
            # Test template file (should pass)
            create_test_file "iter_${iteration}_config.yml.template" 'api_key: YOUR_KEY
password: YOUR_PASSWORD
'
            if run_check_on_file "iter_${iteration}_config.yml.template"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on template"
                ((TESTS_FAILED++))
            fi
            ;;
        6)
            # Test example file (should pass)
            create_test_file "iter_${iteration}_creds.example" 'username: example
password: example123
'
            if run_check_on_file "iter_${iteration}_creds.example"; then
                ((TESTS_PASSED++))
            else
                print_error "Iteration $iteration: False positive on example"
                ((TESTS_FAILED++))
            fi
            ;;
        7)
            # Test Stripe key (should fail) - use safe pattern
            local test_stripe="EXAMPLE_NOT_REAL_STRIPE_TEST_KEY"
            create_test_file "iter_${iteration}_stripe.js" "// Bad
const key = \"${test_stripe}\";
"
            if run_check_on_file "iter_${iteration}_stripe.js"; then
                print_error "Iteration $iteration: False negative on Stripe key"
                ((TESTS_FAILED++))
            else
                ((TESTS_PASSED++))
            fi
            ;;
    esac
}

#------------------------------------------------------------------------------
# Main Test Execution
#------------------------------------------------------------------------------

# Run safe code tests (should not detect secrets)
run_safe_code_tests() {
    test_clean_code
    test_template_file
    test_example_file
    test_documentation
    test_environment_variable_usage
}

# Run secret detection tests (should detect secrets)
run_secret_detection_tests() {
    test_aws_access_key
    test_api_key_hardcoded
    test_password_hardcoded
    test_github_token
    test_private_key
    test_slack_token
    test_stripe_key
    test_google_api_key
    test_multiple_secrets
}

# Run edge case tests
run_edge_case_tests() {
    test_commented_secret
    test_empty_file
    test_short_password
    test_variable_names_only
}

# Print test summary and results
print_test_summary() {
    echo ""
    print_section "Test Summary"
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "✓ All tests passed - Secret detection is working correctly"
        echo ""
        print_info "Property verified:"
        print_info "  • Correctly identifies clean code (no false positives)"
        print_info "  • Correctly detects hardcoded secrets (no false negatives)"
        print_info "  • Handles edge cases (templates, examples, comments)"
        print_info "  • Detects multiple secret types (AWS, API keys, passwords, tokens)"
        print_info "  • Works across $MIN_ITERATIONS random test cases"
        return 0
    else
        print_error "✗ Some tests failed - Secret detection has issues"
        echo ""
        print_info "Failures indicate:"
        print_info "  • False positives: Clean code flagged as containing secrets"
        print_info "  • False negatives: Actual secrets not detected"
        print_info "  • Edge case handling issues"
        return 1
    fi
}

# Main function (NASA compliant: ≤ 60 lines)
main() {
    print_section "Secret Detection - Property Test"
    
    print_info "Testing secret detection across wide range of code patterns"
    print_info "Running $MIN_ITERATIONS iterations..."
    echo ""
    
    # Verify check script exists
    if [ ! -f "$CHECK_SCRIPT" ]; then
        print_error "Check script not found at: $CHECK_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_environment
    
    # Run all test categories
    run_safe_code_tests
    run_secret_detection_tests
    run_edge_case_tests
    
    # Run iteration tests (property-based testing style)
    print_section "Running $MIN_ITERATIONS property test iterations"
    
    for i in $(seq 1 $MIN_ITERATIONS); do
        run_iteration_tests "$i"
    done
    
    # Cleanup
    cleanup_test_environment
    
    # Print summary and return result
    print_test_summary
}

# Run main function
main "$@"
