# Vagrantfile Refactoring - Policy Compliance

![Ahab Logo](docs/images/ahab-logo.png)

## Date: December 8, 2025
## Status: ✅ COMPLETE

## Problem

The Vagrantfile contained ~80 lines of inline shell scripting, violating Ahab policy:
- **Policy**: No scripting in Vagrantfile, use Ansible playbooks instead
- **Reason**: Shell scripts in Vagrantfile are hard to test, maintain, and reuse
- **Impact**: Duplication, inconsistency, and violation of DRY principles

## Solution

Replaced inline shell provisioning with Ansible playbook provisioning.

### Before (Vagrantfile with inline shell)
```ruby
config.vm.provision "shell", env: {...}, inline: <<-SHELL
  set -euo pipefail

  echo "=========================================="
  echo "Ahab Workstation Setup (${OS_NAME})"
  echo "=========================================="

  # Update system
  echo "→ Updating system..."
  ${UPDATE_CMD} || exit 1
  ${UPGRADE_CMD} || exit 1

  # Install packages from config
  echo "→ Installing packages..."
  IFS=' ' read -ra PKG_ARRAY <<< "${PACKAGES}"
  ${INSTALL_CMD} "${PKG_ARRAY[@]}" || exit 1

  # ... 60+ more lines of shell script ...
SHELL
```

### After (Vagrantfile with Ansible)
```ruby
# Provision with Ansible (following Ahab policy: no scripting in Vagrantfile)
config.vm.provision "ansible_local" do |ansible|
  ansible.playbook = "playbooks/provision-workstation.yml"
  ansible.verbose = false
  ansible.install = true
  ansible.install_mode = "pip"
end
```

## Changes Made

### 1. Created `playbooks/provision-workstation.yml`

New Ansible playbook that replaces all inline shell scripting:

**Features**:
- Multi-OS support (Fedora, Debian, Ubuntu)
- Idempotent operations
- Proper error handling
- Verification tasks
- Clear task names and documentation

**Tasks**:
- Update package cache
- Upgrade all packages
- Install workstation packages (git, ansible, docker, etc.)
- Start and enable Docker service
- Add vagrant user to docker group
- Install Python dependencies (pyyaml)
- Create Ahab directories
- Set proper ownership
- Verify all installations
- Display installation summary

### 2. Simplified Vagrantfile

**Removed**:
- ~80 lines of inline shell script
- `get_package_commands()` helper function (no longer needed)
- Environment variable passing
- Complex shell logic

**Kept**:
- `read_config()` - Still needed for ahab.conf
- `get_box_name()` - Still needed for OS selection
- VM configuration (memory, CPUs, networking)
- Synced folders

**Result**: Vagrantfile reduced from ~180 lines to ~100 lines (44% reduction)

## Benefits

### 1. Policy Compliance
✅ No scripting in Vagrantfile  
✅ All provisioning via Ansible  
✅ Follows Ahab development rules  

### 2. Maintainability
- Ansible playbook is easier to read and understand
- Tasks are clearly named and documented
- Can be tested independently
- Can be reused for other purposes

### 3. Consistency
- Same provisioning logic for all environments
- Idempotent operations (safe to run multiple times)
- Proper error handling with Ansible modules

### 4. Testability
- Playbook can be tested with `ansible-lint`
- Can be run independently for debugging
- Clear task output for troubleshooting

### 5. Reusability
- Playbook can provision any host, not just Vagrant VMs
- Can be included in other playbooks
- Variables can be overridden

## Testing

```bash
make test  # ✅ ALL TESTS PASS
```

**Validation**:
- ✅ Shellcheck passes
- ✅ Ansible-lint passes (with appropriate noqa annotations)
- ✅ NASA Power of 10 compliance
- ✅ No regressions

## Files Modified

### Created
- `playbooks/provision-workstation.yml` - New Ansible playbook (180 lines)

### Modified
- `Vagrantfile` - Removed inline shell, added Ansible provisioning (reduced 44%)

## Migration Notes

### For Existing VMs
If you have an existing workstation VM:
1. Destroy and recreate: `make clean && make install`
2. Or manually provision: `vagrant provision`

### For Custom Configurations
Variables can be overridden in the playbook:
```yaml
vars:
  workstation_packages:
    - git
    - ansible
    - your-custom-package
```

## Compliance

This refactoring aligns with:
- ✅ **Ahab Policy**: No scripting in Vagrantfile
- ✅ **DRY Principle**: Ansible playbook is reusable
- ✅ **NASA Power of 10**: Proper error handling
- ✅ **Ansible Best Practices**: Idempotent, well-structured

## Lessons Learned

1. **Inline scripts are technical debt** - Hard to maintain and test
2. **Ansible is the right tool** - Designed for provisioning
3. **Policy exists for a reason** - Prevents accumulation of bad practices
4. **Test immediately** - Caught issues early with `make test`

## Next Steps

### Completed ✅
- Remove inline shell from Vagrantfile
- Create Ansible playbook
- Test and validate
- Document changes

### Future Improvements
- Add more verification tasks
- Support additional package managers
- Add configuration file templates
- Create role for workstation provisioning

---

**Status**: Complete and tested  
**Test Status**: ✅ All tests passing  
**Policy Compliance**: ✅ Fully compliant  
**Promotable**: Yes
