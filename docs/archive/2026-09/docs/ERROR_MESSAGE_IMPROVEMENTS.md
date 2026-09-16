# Error Message Improvements

**Date**: December 8, 2025  
**Priority**: High (Score: 40.5 from LOW_HANGING_FRUIT.md)  
**Core Principles**: #4 (Never Assume Success), #10 (Teaching Mindset), #11 (Documentation as Education)

---

## Purpose

Improve error messages across all scripts to provide:
1. **Clear message** - What went wrong?
2. **Actionable guidance** - What can I do about it?
3. **Context** - What was the system trying to do?
4. **Links** - Where can I learn more?

---

## Current State Analysis

### Scripts Audited

Analyzed error messages in:
- `scripts/ssh-terminal.sh`
- `scripts/validate-scripts.sh`
- `scripts/install-module.sh`
- `scripts/audit-accountability.sh`
- `scripts/setup-nested-test.sh`
- `scripts/validate-nasa-standards.sh`
- `scripts/release-module.sh`

### Common Issues Found

1. **Terse errors** - "Error: VM name required"
2. **No next steps** - User doesn't know what to do
3. **No context** - Why did this fail?
4. **No links** - Where to get help?

---

## Error Message Template

Every error message should follow this pattern:

```bash
print_error() {
    local message="$1"
    local context="$2"
    local action="$3"
    local link="$4"
    
    echo -e "${RED}✗ ERROR${NC}: $message"
    echo ""
    echo "Context: $context"
    echo ""
    echo "What to try:"
    echo "  $action"
    echo ""
    if [ -n "$link" ]; then
        echo "More help: $link"
        echo ""
    fi
}
```

### Example Usage

**Before**:
```bash
echo "Error: VM name required"
exit 1
```

**After**:
```bash
print_error \
    "VM name required" \
    "The script needs a VM name to connect to the virtual machine" \
    "Run: $0 workstation" \
    "https://github.com/waltdundore/ahab/blob/prod/TROUBLESHOOTING.md#vm-issues"
exit 1
```

---

## Implementation Plan

### Phase 1: Create Helper Functions (PRIORITY)

Add to `scripts/lib/common.sh`:

```bash
# Print error with context and guidance
# Usage: print_error "message" "context" "action" "link"
print_error() {
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
print_error_with_command() {
    local message="$1"
    local command="$2"
    
    echo -e "${RED}✗ ERROR${NC}: $message" >&2
    echo "" >&2
    echo "Try running:" >&2
    echo "  $command" >&2
    echo "" >&2
}

# Print error with multiple suggestions
# Usage: print_error_with_options "message" "option1" "option2" "option3"
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
```

### Phase 2: Update Critical Scripts

Priority order (highest impact first):

1. **ssh-terminal.sh** - Users hit this frequently
2. **install-module.sh** - Core functionality
3. **validate-scripts.sh** - Developer workflow
4. **validate-nasa-standards.sh** - Quality gates

### Phase 3: Test Each Change

For each script updated:

```bash
# 1. Test error conditions
./scripts/ssh-terminal.sh ""  # Missing VM name
./scripts/ssh-terminal.sh "invalid@name"  # Invalid format

# 2. Verify error message quality
# - Is message clear?
# - Is action helpful?
# - Is link correct?

# 3. Test normal operation still works
make ssh  # Should work normally
```

### Phase 4: Document Pattern

Update `DEVELOPMENT_RULES.md` with error message guidelines.

---

## Specific Improvements

### ssh-terminal.sh

**Current**:
```bash
echo "Error: VM name required"
```

**Improved**:
```bash
print_error \
    "VM name required" \
    "This script connects to a virtual machine via SSH" \
    "Specify VM name: $0 workstation" \
    "https://github.com/waltdundore/ahab/blob/prod/README.md#available-commands"
```

### install-module.sh

**Current**:
```bash
echo -e "${RED}Error: Module '$module_name' not found in registry${NC}"
```

**Improved**:
```bash
print_error \
    "Module '$module_name' not found in registry" \
    "Available modules are listed in MODULE_REGISTRY.yml" \
    "See available modules: cat MODULE_REGISTRY.yml | grep 'name:'" \
    "https://github.com/waltdundore/ahab/blob/prod/docs/MODULE_ARCHITECTURE.md"
```

### validate-scripts.sh

**Current**:
```bash
echo -e "${RED}✗ Syntax error${NC}"
```

**Improved**:
```bash
print_error \
    "Syntax error in $script" \
    "The script has a bash syntax error that prevents execution" \
    "Run: bash -n $script" \
    "https://github.com/waltdundore/ahab/blob/prod/DEVELOPMENT_RULES.md#testing"
```

---

## Testing Checklist

For each improved error message:

- [ ] Error message is clear and specific
- [ ] Context explains what was being attempted
- [ ] Action is concrete and runnable
- [ ] Link points to relevant documentation
- [ ] Link is accessible (not 404)
- [ ] Normal operation still works
- [ ] Error handling doesn't break script flow
- [ ] Exit codes are appropriate (1 for errors)

---

## Success Metrics

### Before
- Users see: "Error: VM name required"
- Users think: "What VM name? How do I fix this?"
- Support burden: High

### After
- Users see: Clear error with context and action
- Users think: "I know what to do now"
- Support burden: Low

### Measurement
- Track GitHub issues related to error messages
- Monitor support requests
- User feedback on error helpfulness

---

## Core Principles Applied

### #4: Never Assume Success
- Test every error condition
- Verify error messages actually help
- Don't assume users know what to do

### #10: Teaching Mindset
- Every error is a teaching opportunity
- Explain what went wrong and why
- Guide users to the solution

### #11: Documentation as Education
- Link to relevant documentation
- Error messages teach correct usage
- Build knowledge with each error

---

## Next Steps

1. **Create helper functions** in `scripts/lib/common.sh`
2. **Test helper functions** with various inputs
3. **Update ssh-terminal.sh** as proof of concept
4. **Test updated script** thoroughly
5. **Get user feedback** on improved errors
6. **Roll out to other scripts** systematically
7. **Document pattern** in DEVELOPMENT_RULES.md

---

## Related Documents

- [LOW_HANGING_FRUIT.md](LOW_HANGING_FRUIT.md) - Priority analysis
- [DEVELOPMENT_RULES.md](../DEVELOPMENT_RULES.md) - Core principles
- [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) - Error solutions
- [ACTIONABLE_TASKS.md](../../ACTIONABLE_TASKS.md) - Task tracking

---

**Status**: Ready for implementation  
**Estimated Time**: 2-3 hours for Phase 1-2  
**Impact**: High - Improves user experience significantly
