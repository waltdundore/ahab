# Parnas's Principle - Quick Reference Card

![Ahab Logo](../docs/images/ahab-logo.png)

## The Principle in One Sentence

> **For any set of alternatives, exactly one file should contain the complete list, and all other code should read from that file.**

---

## Ahab's Single Sources of Truth

| What | Where | Contains |
|------|-------|----------|
| **Modules** | `MODULE_REGISTRY.yml` | All available modules (apache, mysql, php, etc.) |
| **Configuration** | `ahab.conf` | OS versions, VM settings, package lists |

---

## Quick Rules

### ✅ DO

```bash
# Read from MODULE_REGISTRY.yml
MODULES=$(yq eval '.registry.modules | keys | .[]' MODULE_REGISTRY.yml)

# Source ahab.conf
source ahab.conf
echo "Using Fedora $FEDORA_VERSION"

# Check if module exists in registry
if yq eval ".registry.modules | has(\"$MODULE\")" MODULE_REGISTRY.yml | grep -q "true"; then
    echo "Valid module"
fi
```

### ❌ DON'T

```bash
# Don't hardcode module lists
MODULES="apache mysql php"  # ❌ WRONG

# Don't hardcode OS versions
FEDORA_VERSION=43  # ❌ WRONG

# Don't use config variables without sourcing
echo "Using Fedora $FEDORA_VERSION"  # ❌ WRONG (if ahab.conf not sourced)
```

---

## Running the Test

```bash
# Run Parnas principle test
./tests/property/test-parnas-principle.sh

# Or run all property tests
make test-property

# Or run full test suite
make test
```

---

## Common Violations and Fixes

### Violation: Hardcoded Module List

**Error:**
```
⚠ Hardcoded module list in: install-services.sh
```

**Find it:**
```bash
grep -n "apache.*mysql\|mysql.*apache" install-services.sh
```

**Fix it:**
```bash
# Before (WRONG)
MODULES="apache mysql php"

# After (CORRECT)
MODULES=$(yq eval '.registry.modules | keys | .[]' MODULE_REGISTRY.yml | tr '\n' ' ')
```

---

### Violation: Hardcoded OS Version

**Error:**
```
⚠ Hardcoded OS version assignment in: Dockerfile
```

**Find it:**
```bash
grep -n "FEDORA_VERSION=\|fedora:4[0-9]" Dockerfile
```

**Fix it:**
```dockerfile
# Before (WRONG)
FROM fedora:43

# After (CORRECT)
ARG FEDORA_VERSION=43
FROM fedora:${FEDORA_VERSION}
```

Then build with:
```bash
source ahab.conf
docker build --build-arg FEDORA_VERSION=$FEDORA_VERSION -t myimage .
```

---

### Violation: Script Doesn't Source Config

**Error:**
```
✗ create-vm.sh uses config variables without sourcing ahab.conf
```

**Find it:**
```bash
# Check if script uses config variables
grep -n '\$FEDORA_VERSION' create-vm.sh

# Check if script sources config
grep -n 'source.*ahab\.conf' create-vm.sh
```

**Fix it:**
```bash
# Before (WRONG)
#!/bin/bash
vagrant box add fedora/$FEDORA_VERSION

# After (CORRECT)
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../ahab.conf"
vagrant box add fedora/$FEDORA_VERSION
```

---

### Violation: Module Not in Registry

**Error:**
```
⚠ Module 'redis' referenced but not in registry
```

**Fix Option 1 - Add to registry:**
```yaml
# In MODULE_REGISTRY.yml
registry:
  modules:
    redis:
      repository: "https://github.com/waltdundore/ahab-module-redis.git"
      version: "v1.0.0"
      description: "Redis Cache Server"
      deployment_methods: [docker]
      status: stable
```

**Fix Option 2 - Remove from documentation:**
Remove references to redis from README.md and other docs.

---

## Adding New Alternatives

### Adding a New Module

**Only update MODULE_REGISTRY.yml:**
```yaml
registry:
  modules:
    nginx:  # Add this
      repository: "https://github.com/waltdundore/ahab-module-nginx.git"
      version: "v1.0.0"
      description: "Nginx Web Server"
      deployment_methods: [docker]
      status: stable
```

**That's it!** All code automatically knows about nginx.

### Adding a New OS Version

**Only update ahab.conf:**
```ini
[system]
FEDORA_VERSION=44  # Update this
DEBIAN_VERSION=13
UBUNTU_VERSION=24.04
```

**That's it!** All code automatically uses the new version.

---

## Why This Matters

| Without Parnas | With Parnas |
|----------------|-------------|
| Update 5 files to add a module | Update 1 file |
| Easy to forget a location | Impossible to forget |
| Inconsistency risk | Guaranteed consistency |
| Hard to maintain | Easy to maintain |
| Test fails | Test passes |

---

## Need More Help?

**Full guide:** `docs/development/PARNAS_PRINCIPLE_GUIDE.md`

**Covers:**
- Detailed explanation of the principle
- What each test does
- Step-by-step fix instructions
- Examples and anti-patterns
- Why this matters for maintainability

---

## Test Output Interpretation

### ✅ Success
```
✓ All tests passed - Parnas's principle is upheld
```
**Meaning:** Your code follows the principle. Adding new alternatives only requires updating one file.

### ❌ Failure
```
✗ Some tests failed - Parnas's principle violations found
```
**Meaning:** Some code has hardcoded alternatives. See the test output for specific files and line numbers.

**Next steps:**
1. Read the test output to find which files have violations
2. Use the "Common Violations and Fixes" section above
3. Consult the full guide if needed
4. Fix the violations
5. Run the test again

---

**Remember:** The test is your friend. It catches problems before they cause bugs!

Print this card and keep it handy while developing.
