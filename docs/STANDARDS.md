# Ahab Project Standards

**Date**: December 8, 2025  
**Status**: MANDATORY - All code, documentation, and content must comply  
**Core Principles**: Professional, Accessible, Best Practices

---

## Purpose

This document defines strict, non-negotiable standards for:
- Code layout and formatting
- Documentation structure and content
- Web accessibility (WCAG 2.1 AA minimum)
- Error messages and user communication
- Testing and validation
- Security and safety

**These are not guidelines. These are requirements.**

---

## 1. Code Standards

### 1.1 Shell Scripts

**File Structure** (MANDATORY):
```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Name and Purpose (One Line)
# ==============================================================================
# Detailed description of what this script does
# Why it exists and when to use it
#
# Usage: script-name.sh [options] <required-arg>
#
# Core Principles: #X (Principle Name)
# ==============================================================================

set -euo pipefail  # MANDATORY - Strict error handling

# Constants (UPPERCASE)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common library (MANDATORY)
# shellcheck source=path/to/common.sh
source "$PROJECT_ROOT/scripts/lib/common.sh"

# Main script logic here
```

**Naming Conventions** (MANDATORY):
- Scripts: `kebab-case.sh` (e.g., `install-module.sh`)
- Functions: `snake_case` (e.g., `validate_input`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`)
- Variables: `snake_case` (e.g., `module_name`)

**Error Handling** (MANDATORY):
```bash
# ALWAYS use enhanced error functions
print_error_detailed \
    "Clear error message" \
    "Context: What was being attempted" \
    "Action: Specific command to fix" \
    "Link: https://docs.example.com/help"

# NEVER use bare echo for errors
# ❌ BAD: echo "Error: something failed"
# ✅ GOOD: print_error_detailed "..." "..." "..." "..."
```

**Function Documentation** (MANDATORY):
```bash
# Function description
# Usage: function_name "arg1" "arg2"
# Arguments:
#   arg1 - Description of first argument
#   arg2 - Description of second argument
# Returns:
#   0 on success, 1 on failure
# Example:
#   function_name "value1" "value2"
function_name() {
    local arg1="$1"
    local arg2="$2"
    
    # Function body
}
```

**NASA Power of 10 Compliance** (MANDATORY):
1. ✅ Restrict all code to simple control flow (no goto, no recursion)
2. ✅ All loops must have fixed upper bounds
3. ✅ No dynamic memory allocation after initialization
4. ✅ Functions must be short (< 60 lines)
5. ✅ Assertions must be used to check return values
6. ✅ Data must be declared at smallest scope
7. ✅ Check return value of all functions
8. ✅ Preprocessor use must be limited
9. ✅ Pointer use must be restricted
10. ✅ Compile with all warnings enabled

**Validation** (MANDATORY):
```bash
# Run before every commit
make validate-scripts  # Must pass
shellcheck script.sh   # Must have no warnings
bash -n script.sh      # Must have no syntax errors
```

---

## 2. Documentation Standards

### 2.1 Markdown Files

**File Structure** (MANDATORY):
```markdown
# Document Title

**Date**: YYYY-MM-DD  
**Status**: Draft|Active|Deprecated  
**Purpose**: One-line description

---

## Purpose

Clear explanation of why this document exists.

---

## Section 1

Content organized logically.

### Subsection 1.1

Detailed content.

---

## Related Documents

- [Link](path/to/doc.md) - Description
```

**Formatting Rules** (MANDATORY):
- **Headers**: Use ATX-style (`#`, `##`, `###`)
- **Lists**: Use `-` for unordered, `1.` for ordered
- **Code blocks**: Always specify language (```bash, ```yaml, ```python)
- **Links**: Use reference-style for repeated links
- **Line length**: Max 120 characters (except code blocks)
- **Blank lines**: One blank line between sections
- **Emphasis**: `**bold**` for important, `*italic*` for emphasis

**Required Sections** (MANDATORY for all docs):
1. **Title and metadata** (Date, Status, Purpose)
2. **Purpose** - Why this document exists
3. **Content** - Organized with clear headers
4. **Related Documents** - Links to related docs

**Accessibility** (MANDATORY):
- ✅ Use descriptive link text (not "click here")
- ✅ Provide alt text for images
- ✅ Use semantic headers (don't skip levels)
- ✅ Use tables for tabular data only
- ✅ Avoid ASCII art (use Mermaid diagrams instead)

### 2.2 Code Comments

**Inline Comments** (MANDATORY):
```bash
# GOOD: Explain WHY, not WHAT
# Retry 3 times because network can be flaky
for i in {1..3}; do
    if curl "$url"; then break; fi
done

# BAD: Explain WHAT (code already shows this)
# Loop 3 times
for i in {1..3}; do
    curl "$url"
done
```

**Function Comments** (MANDATORY):
- Purpose: What does this function do?
- Usage: How to call it
- Arguments: What each parameter means
- Returns: What it returns
- Example: Working example

---

## 3. Web Standards

### 3.1 HTML

**Document Structure** (MANDATORY):
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Descriptive text for SEO">
    <title>Page Title - Site Name</title>
    <!-- Styles -->
</head>
<body>
    <!-- Content -->
</body>
</html>
```

**Semantic HTML** (MANDATORY):
```html
<!-- ✅ GOOD: Semantic elements -->
<header>
    <nav>
        <ul>
            <li><a href="/">Home</a></li>
        </ul>
    </nav>
</header>
<main>
    <article>
        <h1>Article Title</h1>
        <section>
            <h2>Section Title</h2>
            <p>Content</p>
        </section>
    </article>
</main>
<footer>
    <p>&copy; 2025 Company</p>
</footer>

<!-- ❌ BAD: Div soup -->
<div class="header">
    <div class="nav">
        <div class="link">Home</div>
    </div>
</div>
```

**Accessibility** (MANDATORY - WCAG 2.1 AA):
```html
<!-- ✅ Images must have alt text -->
<img src="logo.png" alt="Ahab logo - whale tail">

<!-- ✅ Links must be descriptive -->
<a href="/docs">Read the documentation</a>
<!-- ❌ NOT: <a href="/docs">Click here</a> -->

<!-- ✅ Forms must have labels -->
<label for="email">Email Address</label>
<input type="email" id="email" name="email" required>

<!-- ✅ Buttons must describe action -->
<button type="submit">Submit Form</button>
<!-- ❌ NOT: <button>Submit</button> -->

<!-- ✅ Use ARIA when needed -->
<button aria-label="Close dialog" aria-expanded="false">
    <span aria-hidden="true">×</span>
</button>

<!-- ✅ Keyboard navigation -->
<a href="#main-content" class="skip-link">Skip to main content</a>
```

**Color Contrast** (MANDATORY):
- Normal text: 4.5:1 minimum
- Large text (18pt+): 3:1 minimum
- UI components: 3:1 minimum
- Test with: https://webaim.org/resources/contrastchecker/

**Responsive Design** (MANDATORY):
```css
/* Mobile first approach */
.container {
    width: 100%;
    padding: 20px;
}

/* Tablet */
@media (min-width: 768px) {
    .container {
        max-width: 720px;
        margin: 0 auto;
    }
}

/* Desktop */
@media (min-width: 1024px) {
    .container {
        max-width: 960px;
    }
}
```

### 3.2 CSS

**Organization** (MANDATORY):
```css
/* 1. CSS Reset/Normalize */
/* 2. CSS Variables */
:root {
    --color-primary: #3d5a6c;
    --color-error: #dc3545;
    --spacing-unit: 8px;
}

/* 3. Base Styles */
body {
    font-family: system-ui, -apple-system, sans-serif;
    line-height: 1.6;
}

/* 4. Layout */
.container { }

/* 5. Components */
.button { }

/* 6. Utilities */
.text-center { }

/* 7. Media Queries */
@media (min-width: 768px) { }
```

**Naming Convention** (MANDATORY):
```css
/* Use BEM (Block Element Modifier) */
.block { }
.block__element { }
.block--modifier { }

/* Example */
.card { }
.card__title { }
.card__body { }
.card--featured { }
```

**Accessibility** (MANDATORY):
```css
/* ✅ Focus indicators */
a:focus,
button:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
}

/* ✅ Reduced motion */
@media (prefers-reduced-motion: reduce) {
    * {
        animation-duration: 0.01ms !important;
        transition-duration: 0.01ms !important;
    }
}

/* ✅ High contrast mode */
@media (prefers-contrast: high) {
    .button {
        border: 2px solid currentColor;
    }
}
```

---

## 4. Error Message Standards

### 4.1 Structure (MANDATORY)

Every error message MUST include:

1. **Clear Message**: What went wrong?
2. **Context**: What was being attempted?
3. **Action**: Specific steps to fix
4. **Link**: Where to get more help

**Template**:
```bash
print_error_detailed \
    "Module 'apache' not found in registry" \
    "Attempted to install module but it's not in MODULE_REGISTRY.yml" \
    "See available modules: cat MODULE_REGISTRY.yml | grep 'name:'" \
    "https://github.com/waltdundore/ahab/blob/prod/docs/MODULE_ARCHITECTURE.md"
```

### 4.2 Language (MANDATORY)

**DO**:
- ✅ Use active voice: "Cannot find file"
- ✅ Be specific: "Port 8080 is already in use"
- ✅ Provide commands: "Run: make clean"
- ✅ Link to docs: "See: TROUBLESHOOTING.md"

**DON'T**:
- ❌ Be vague: "Something went wrong"
- ❌ Blame user: "You didn't provide..."
- ❌ Use jargon: "ENOENT error occurred"
- ❌ Dead-end: "Error" (with no guidance)

### 4.3 Tone (MANDATORY)

- **Professional**: Not casual or jokey
- **Helpful**: Focus on solutions
- **Respectful**: Never condescending
- **Clear**: No ambiguity

**Examples**:
```bash
# ✅ GOOD
print_error_detailed \
    "Docker is not installed" \
    "This script requires Docker to create containers" \
    "Install Docker: brew install --cask docker" \
    "https://docs.docker.com/get-docker/"

# ❌ BAD
echo "Oops! Docker not found. Maybe install it?"
```

---

## 5. Testing Standards

### 5.1 Test Structure (MANDATORY)

```bash
#!/usr/bin/env bash
# Test script structure

set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/lib/common.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_something() {
    # Arrange
    local input="value"
    
    # Act
    local result
    result=$(function_to_test "$input")
    
    # Assert
    if [ "$result" = "expected" ]; then
        return 0
    else
        echo "Expected 'expected', got '$result'"
        return 1
    fi
}

# Run tests
test_function "Test name" test_something

# Report results
if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed"
    exit 0
else
    print_error "$TESTS_FAILED test(s) failed"
    exit 1
fi
```

### 5.2 Test Coverage (MANDATORY)

**Every script MUST have tests for**:
- ✅ Normal operation (happy path)
- ✅ Error conditions (sad path)
- ✅ Edge cases (empty input, max values)
- ✅ Invalid input (wrong format, wrong type)

**Test Naming** (MANDATORY):
- Test files: `test-feature-name.sh`
- Test functions: `test_specific_behavior()`
- Be descriptive: `test_validates_version_format()`

---

## 6. Security Standards

### 6.1 Input Validation (MANDATORY)

```bash
# ✅ ALWAYS validate input
validate_module_name() {
    local name="$1"
    
    # Check not empty
    if [ -z "$name" ]; then
        print_error "Module name cannot be empty"
        return 1
    fi
    
    # Check format (alphanumeric, dash, underscore only)
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error_invalid_input "$name" "module name" "apache" "mysql"
        return 1
    fi
    
    return 0
}

# ❌ NEVER trust user input
# BAD: eval "$user_input"
# BAD: rm -rf "$user_path"
# BAD: mysql -e "$user_query"
```

### 6.2 Secrets Management (MANDATORY)

```bash
# ✅ Use environment variables
DB_PASSWORD="${DB_PASSWORD:-}"

# ✅ Use Ansible Vault for secrets
ansible-vault encrypt secrets.yml

# ✅ Never commit secrets
# Add to .gitignore:
*.key
*.pem
secrets.yml
.env

# ❌ NEVER hardcode secrets
# BAD: PASSWORD="secret123"
# BAD: API_KEY="abc123xyz"
```

### 6.3 Command Injection Prevention (MANDATORY)

```bash
# ✅ Quote variables
rm -f "$file_path"

# ✅ Validate before using
if [[ "$vm_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    vagrant ssh "$vm_name"
fi

# ❌ NEVER use eval with user input
# BAD: eval "$user_command"

# ❌ NEVER use unquoted variables
# BAD: rm -f $file_path
```

---

## 7. Git Standards

### 7.1 Commit Messages (MANDATORY)

**Format**:
```
Short summary (50 chars max)

Detailed explanation of what changed and why.
Wrap at 72 characters.

- Bullet points for multiple changes
- Reference issues: Fixes #123
- Reference docs: See DESIGN.md

Core Principles: #4 (Never Assume Success)
```

**Examples**:
```
✅ GOOD:
Add enhanced error message functions to common.sh

Created print_error_detailed, print_error_with_command, and
print_error_with_options functions to provide helpful, actionable
error messages.

- Added 5 new error functions
- Created test suite in tests/test-error-messages.sh
- Updated ERROR_MESSAGE_IMPROVEMENTS.md with usage examples

Core Principles: #4 (Never Assume Success), #10 (Teaching Mindset)

❌ BAD:
fixed stuff
```

### 7.2 Branch Naming (MANDATORY)

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation only
- `refactor/description` - Code refactoring
- `test/description` - Test additions

---

## 8. Validation Checklist

### Before Every Commit (MANDATORY):

- [ ] Code passes `shellcheck` with no warnings
- [ ] Code passes `bash -n` syntax check
- [ ] All tests pass: `make test`
- [ ] NASA standards validated: `make validate-nasa`
- [ ] Documentation updated
- [ ] Error messages are helpful
- [ ] Commit message follows format
- [ ] No secrets committed
- [ ] Accessibility checked (for web changes)

### Before Every Release (MANDATORY):

- [ ] All tests pass on all platforms
- [ ] Security audit passed
- [ ] Documentation complete and accurate
- [ ] CHANGELOG.md updated
- [ ] Version number incremented
- [ ] Release notes written
- [ ] All branches synchronized

---

## 9. Enforcement

### Automated Checks (MANDATORY):

```bash
# Pre-commit hook
make validate-scripts  # Must pass
make test              # Must pass
make validate-nasa     # Must pass
```

### Code Review (MANDATORY):

Every change must be reviewed for:
- Standards compliance
- Error message quality
- Test coverage
- Documentation accuracy
- Accessibility (for web changes)

### Consequences of Non-Compliance:

- ❌ Code will not be merged
- ❌ Release will be blocked
- ❌ Must be fixed before proceeding

---

## 10. Resources

### Tools (MANDATORY):

- **ShellCheck**: https://www.shellcheck.net/
- **WAVE**: https://wave.webaim.org/ (accessibility)
- **Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **HTML Validator**: https://validator.w3.org/
- **CSS Validator**: https://jigsaw.w3.org/css-validator/

### References (MANDATORY):

- **WCAG 2.1**: https://www.w3.org/WAI/WCAG21/quickref/
- **NASA Power of 10**: https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code
- **Semantic HTML**: https://developer.mozilla.org/en-US/docs/Glossary/Semantics
- **BEM CSS**: http://getbem.com/

---

## Conclusion

These standards are **NON-NEGOTIABLE**.

Every line of code, every document, every web page must meet these standards.

**Quality is not optional. Accessibility is not optional. Professionalism is not optional.**

We build software that teaches. We build software that lasts. We build software that matters.

**Do it right, or don't do it at all.**

---

**Last Updated**: December 8, 2025  
**Status**: ACTIVE - MANDATORY COMPLIANCE  
**Review**: Quarterly or when standards evolve
