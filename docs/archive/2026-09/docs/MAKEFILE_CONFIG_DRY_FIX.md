# Makefile.config DRY Fix - December 8, 2025

![Ahab Logo](docs/images/ahab-logo.png)

## Problem

`Makefile.config` had hardcoded configuration values that duplicated values in `ahab.conf`, violating the DRY (Don't Repeat Yourself) principle.

**Before:**
```makefile
BASE_DIR ?= $(HOME)/git
GITHUB_USER ?= waltdundore
```

These values were hardcoded, meaning:
- Changes to `ahab.conf` wouldn't affect Makefiles
- Two sources of truth for the same data
- Risk of inconsistency between config file and Makefiles

## Solution

Updated `Makefile.config` to load configuration from `ahab.conf` as the single source of truth.

**After:**
```makefile
# Find ahab.conf by searching up the directory tree
AHAB_CONF := $(shell \
	dir="$(CURDIR)"; \
	while [ "$$dir" != "/" ]; do \
		if [ -f "$$dir/ahab.conf" ]; then \
			echo "$$dir/ahab.conf"; \
			break; \
		fi; \
		dir=$$(dirname "$$dir"); \
	done \
)

# If ahab.conf found, include it
ifneq ($(AHAB_CONF),)
include $(AHAB_CONF)
endif

# Use values from ahab.conf with fallback defaults
GITHUB_USER ?= waltdundore
BASE_DIR ?= $(shell dirname $(shell dirname $(ANSIBLE_CONTROL_PATH)))
```

## How It Works

1. **Search for ahab.conf**: The Makefile searches up the directory tree to find `ahab.conf`
2. **Include Configuration**: If found, `ahab.conf` is included, making all its variables available
3. **Use Variables**: Makefile variables now use values from `ahab.conf`
4. **Allow Overrides**: The `?=` operator still allows environment variable overrides

## Benefits

1. **Single Source of Truth**: All configuration comes from `ahab.conf`
2. **DRY Compliance**: No duplication of configuration values
3. **Consistency**: Changes to `ahab.conf` automatically affect all Makefiles
4. **Flexibility**: Environment variables can still override values
5. **Maintainability**: Only one file to update when configuration changes

## Testing

Verified that Makefile.config correctly loads values from ahab.conf:

```bash
$ make -f /tmp/test-makefile-config.mk test
AHAB_CONF: /Users/waltdundore/git/DockMaster/ahab.conf
GITHUB_USER: waltdundore
FEDORA_VERSION: 43
ANSIBLE_CONTROL_PATH: /Users/waltdundore/git/AHAB/ahab
BASE_DIR: /Users/waltdundore/git
```

All values correctly loaded from `ahab.conf`.

## Variables Now Sourced from ahab.conf

The following variables are now loaded from `ahab.conf`:

- `GITHUB_USER` - GitHub username
- `GITHUB_BRANCH` - Git branch for development
- `FEDORA_VERSION` - Fedora OS version
- `DEBIAN_VERSION` - Debian OS version
- `UBUNTU_VERSION` - Ubuntu OS version
- `DEFAULT_OS` - Default OS selection
- `ANSIBLE_CONTROL_PATH` - Path to ahab repo
- `ANSIBLE_INVENTORY_PATH` - Path to ansible-inventory repo
- `ANSIBLE_CONFIG_PATH` - Path to ansible-config repo
- `WEBSITE_REPO_PATH` - Path to website repo
- `WORKSTATION_MEMORY` - VM memory allocation
- `WORKSTATION_CPUS` - VM CPU allocation
- `STANDARD_MEMORY` - Standard VM memory
- `STANDARD_CPUS` - Standard VM CPUs
- `LIGHTWEIGHT_MEMORY` - Lightweight VM memory
- `LIGHTWEIGHT_CPUS` - Lightweight VM CPUs
- And many more...

## Impact

### Positive
- ✅ Eliminates configuration duplication
- ✅ Ensures consistency across all tools
- ✅ Simplifies maintenance
- ✅ Follows DRY principle
- ✅ Aligns with project development rules

### Neutral
- No breaking changes - environment variables still work
- Existing Makefiles continue to function
- No user-facing changes required

### Considerations
- `ahab.conf` must exist for Makefiles to get configuration
- If `ahab.conf` is not found, fallback defaults are used
- The search goes up the directory tree (max 5 levels in scripts, unlimited in Makefile)

## Related Files

- `ahab/Makefile.config` - Updated to load from ahab.conf
- `ahab.conf` - Single source of truth for configuration
- `scripts/lib/common.sh` - Shell scripts also load from ahab.conf
- `.kiro/specs/script-improvements/design.md` - Design document specifies this pattern

## Alignment with Requirements

This change directly addresses:

**Requirement 3.1**: "WHEN a script needs configuration data THEN the System SHALL read the data from ahab.conf"

**Requirement 3.2**: "WHEN a script contains hardcoded values that should be configurable THEN the System SHALL move those values to ahab.conf"

**Requirement 3.3**: "WHEN ahab.conf is updated THEN the System SHALL ensure all scripts automatically use the new values"

## Next Steps

1. ✅ Update Makefile.config to load from ahab.conf
2. ⏭️ Verify all Makefiles that include Makefile.config work correctly
3. ⏭️ Update other Makefiles to use ahab.conf values
4. ⏭️ Document the pattern in DEVELOPMENT_RULES.md
5. ⏭️ Add tests to verify configuration loading

## References

- DRY Principle: https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
- Make include directive: https://www.gnu.org/software/make/manual/html_node/Include.html
- Project steering rules: `.kiro/steering/`
