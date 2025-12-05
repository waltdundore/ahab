---
# Makefile Consistency Rule

## Principle

All Makefiles across the three Ahab repositories must be consistent and provide the same core commands. Users should be able to use the same `make` commands regardless of which repository they're in.

## Required Makefile Targets

### Core Targets (All Repositories)

These targets MUST exist in all three repositories:

```makefile
.PHONY: help sync status publish

help:        # Show available commands
sync:        # Pull latest changes from git
status:      # Show git status
publish:     # Commit and push changes
```

### Repository-Specific Targets

Additional targets specific to ansible-control:
- `install` - Vagrant VM creation
- `deploy` - Ansible deployment
- `provision` - Re-provision VMs
- `clean` - Destroy VMs
- `ssh` - SSH into VM

## Standard Makefile Structure

### Header

```makefile
# ==============================================================================
# Ahab [Repository Name] - Makefile
# ==============================================================================
# Common automation commands
#
# Usage:
#   make help     - Show available commands
#   make sync     - Pull latest changes
#   make publish  - Commit and push changes

.PHONY: help sync status publish [other-targets]
```

### Help Target (Always First)

```makefile
help:
	@echo "Ahab [Repository Name] - Available Commands:"
	@echo ""
	@echo "  make help      - Show this help message"
	@echo "  make sync      - Pull latest changes from git"
	@echo "  make status    - Show git status"
	@echo "  make publish   - Commit and push changes"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-12s - %s\n", $$1, $$2}'
```

### Core Targets Implementation

```makefile
sync:  ## Pull latest changes from git
	@git fetch origin
	@git pull origin $(shell git branch --show-current)
	@echo "✓ Synced with remote"

status:  ## Show git status
	@git status

publish:  ## Commit and push changes
	@read -p "Commit message: " msg; \
	git add -A; \
	if git diff --cached --quiet; then \
		echo "No changes to commit"; \
	else \
		git commit -m "$$msg" && \
		git push origin $(shell git branch --show-current) && \
		echo "✓ Published to $(shell git branch --show-current)"; \
	fi
```

## Consistency Requirements

### Variable Naming

Use consistent variable names:
```makefile
CURRENT_BRANCH := $(shell git branch --show-current)
REPO_NAME := $(shell basename $(CURDIR))
```

### Error Handling

Consistent error messages:
```makefile
@echo "Error: [description]"
@exit 1
```

### Success Messages

Consistent success indicators:
```makefile
@echo "✓ [action] complete"
```

### Command Suppression

Use `@` to suppress command echo for clean output:
```makefile
@git status    # Good - clean output
git status     # Bad - shows command
```

## Testing Makefiles

### Verify Consistency

```bash
# Test in each repository
cd ~/git/ansible-control && make help
cd ~/git/ansible-inventory && make help
cd ~/git/ansible-config && make help

# All should show similar structure
```

### Test Core Commands

```bash
# In each repository
make status   # Should work
make sync     # Should work
make publish  # Should work
```

## Documentation

### In README.md

Each repository's README should document available make commands:

```markdown
## Available Commands

```bash
make help      # Show available commands
make sync      # Pull latest changes
make status    # Show git status
make publish   # Commit and push changes
```
```

### In Makefile Comments

Use `##` for help text:
```makefile
target:  ## Description shown in help
	@command
```

## Anti-Patterns

### Don't Do This

❌ Different command names for same action:
```makefile
# ansible-control
make publish

# ansible-inventory
make push      # BAD - inconsistent
```

❌ Missing core commands:
```makefile
# ansible-inventory Makefile with no 'publish' target
# BAD - users expect this command
```

❌ Different behavior for same command:
```makefile
# In one repo: publish commits and pushes
# In another: publish only commits
# BAD - inconsistent behavior
```

## Implementation Checklist

When creating or updating a Makefile:

- [ ] Includes header with repository name
- [ ] Has `.PHONY` declarations
- [ ] Implements `help` target (first target)
- [ ] Implements `sync` target
- [ ] Implements `status` target
- [ ] Implements `publish` target
- [ ] Uses consistent variable names
- [ ] Uses `@` for clean output
- [ ] Has consistent error/success messages
- [ ] Documents commands in README
- [ ] Tested all targets

## Maintenance

### When Adding New Targets

1. Consider if it should be in all repositories
2. Use consistent naming
3. Add to help output
4. Document in README
5. Test in all applicable repos

### When Updating Targets

1. Update in all repositories simultaneously
2. Keep behavior consistent
3. Update documentation
4. Test changes

## Examples

### Minimal Makefile (ansible-inventory, ansible-config)

```makefile
# ==============================================================================
# Ahab Inventory - Makefile
# ==============================================================================

.PHONY: help sync status publish

help:
	@echo "Ahab Inventory - Available Commands:"
	@echo ""
	@echo "  make help      - Show this help"
	@echo "  make sync      - Pull latest changes"
	@echo "  make status    - Show git status"
	@echo "  make publish   - Commit and push"

sync:
	@git fetch origin
	@git pull origin $(shell git branch --show-current)
	@echo "✓ Synced"

status:
	@git status

publish:
	@read -p "Commit message: " msg; \
	git add -A; \
	if git diff --cached --quiet; then \
		echo "No changes to commit"; \
	else \
		git commit -m "$$msg" && \
		git push origin $(shell git branch --show-current) && \
		echo "✓ Published"; \
	fi
```

### Extended Makefile (ansible-control)

Includes core targets plus repository-specific targets like `install`, `deploy`, etc.

## Benefits

✅ **Consistency** - Same commands work everywhere
✅ **Predictability** - Users know what to expect
✅ **Efficiency** - Muscle memory works across repos
✅ **Maintainability** - Easy to update all repos
✅ **Documentation** - Self-documenting with help target

## Summary

All Ahab repositories must have consistent Makefiles with the same core commands (`help`, `sync`, `status`, `publish`). This ensures a consistent user experience and makes the system easier to use and maintain.
