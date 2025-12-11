# Design: Containerize Python Tools

![Ahab Logo](../../docs/images/ahab-logo.png)

## Overview

This design eliminates pip dependencies by running Python scripts in Docker containers. The primary target is `generate-compose.py`, which currently requires PyYAML to be installed via pip in the workstation VM.

## Architecture

### Current State (Violates Principle)
```
User runs: make install apache
  ↓
Makefile calls: vagrant ssh -c "python3 scripts/generate-compose.py apache"
  ↓
VM has: python3 + python3-pip + PyYAML (installed via pip)
  ↓
Script runs in VM, generates docker-compose.yml
```

### New State (Follows Principle)
```
User runs: make install apache
  ↓
Makefile calls: vagrant ssh -c "docker run ... python:3.11-slim ..."
  ↓
Docker container has: python3 + PyYAML (in container image)
  ↓
Script runs in container, generates docker-compose.yml
```

## Components

### 1. Docker Wrapper Script

**File**: `scripts/docker-python.sh`

A wrapper script that runs Python commands in a Docker container.

```bash
#!/usr/bin/env bash
# Run Python scripts in Docker container
# Usage: docker-python.sh script.py [args...]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

docker run --rm \
  -v "$PROJECT_ROOT:/workspace" \
  -w /workspace \
  python:3.11-slim \
  bash -c "pip install -q PyYAML && python3 $*"
```

### 2. Updated Makefile

Modify the `install` and `deploy` targets to use Docker instead of direct Python:

```makefile
install:
    # ... existing code ...
    @if [ -n "$(MODULES)" ]; then \
        echo "→ Deploying modules: $(MODULES)"; \
        vagrant ssh -c "cd /home/vagrant/ahab && docker run --rm -v \$(pwd):/workspace -w /workspace python:3.11-slim bash -c 'pip install -q PyYAML && python3 scripts/generate-compose.py $(MODULES)'" || exit 1; \
        vagrant ssh -c "cd /home/vagrant/ahab/generated && docker-compose up -d" || exit 1; \
    fi
```

### 3. Updated Provisioning Playbook

Remove Python pip installation from `playbooks/provision-workstation.yml`:

**Remove:**
- `python3-pip` from workstation_packages
- `python_packages` variable
- "Install Python dependencies" task

**Keep:**
- `python3` (system package, needed by Ansible)
- Docker installation (needed to run containers)

### 4. Remove requirements.txt

Delete `ahab/requirements.txt` as it's no longer needed.

## Data Models

No new data models needed - the script interface remains the same.

## Error Handling

### Docker Not Available
- Check if Docker is running before attempting to use it
- Provide clear error message: "Docker is required but not running"

### Image Pull Failures
- Docker will automatically pull `python:3.11-slim` if not present
- Network errors will be displayed to user

### Volume Mount Issues
- Ensure paths are correct and accessible
- Verify permissions on mounted directories

## Testing Strategy

### Unit Tests
- Test that Docker wrapper script constructs correct commands
- Test that Makefile targets call Docker correctly
- Verify provisioning playbook doesn't install pip

### Integration Tests
- Test `make install apache` with containerized Python
- Test `make install apache mysql` with multiple modules
- Verify generated docker-compose.yml is correct
- Test error handling when Docker is not available

### Validation
- Run dependency audit after changes
- Verify zero pip-related violations
- Confirm no requirements.txt files remain

## Implementation Notes

### Performance Considerations
- First run will pull Python image (~50MB)
- Subsequent runs use cached image
- pip install PyYAML adds ~2 seconds per run
- Consider creating custom image with PyYAML pre-installed for production

### Alternative: Custom Docker Image

For better performance, create a custom image:

```dockerfile
# Dockerfile.python-tools
FROM python:3.11-slim
RUN pip install --no-cache-dir PyYAML
WORKDIR /workspace
```

Then use `ahab/python-tools` instead of installing PyYAML each time.

### Backward Compatibility

The change is transparent to users:
- Same commands: `make install apache`
- Same output format
- Same error messages
- Only difference: runs in container instead of VM

## Migration Path

1. Create Docker wrapper script
2. Update Makefile to use Docker
3. Update provisioning playbook to remove pip
4. Remove requirements.txt
5. Test all workflows
6. Run dependency audit to verify compliance
7. Update documentation

## Success Criteria

- ✅ `make install apache` works correctly
- ✅ `make install apache mysql` works correctly  
- ✅ No pip installations in provisioning playbook
- ✅ No requirements.txt files in repository
- ✅ Dependency audit shows zero pip violations
- ✅ All existing tests pass
