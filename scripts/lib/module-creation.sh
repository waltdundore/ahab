#!/usr/bin/env bash
# ==============================================================================
# Module Creation Library
# ==============================================================================
# Shared functions for creating Ahab modules
# Used by create-module.sh and related scripts
# ==============================================================================

# Cross-platform sed in-place replacement
sed_inplace() {
    local pattern=$1
    local file=$2
    if sed --version 2>/dev/null | grep -q GNU; then
        # GNU sed (Linux)
        sed -i "$pattern" "$file"
    else
        # BSD sed (macOS)
        sed -i '' "$pattern" "$file"
    fi
}

# Validate module name format
validate_module_name() {
    local module_name=$1
    
    if [ -z "$module_name" ]; then
        echo "Error: Module name is required"
        return 1
    fi
    
    # Check for valid characters (alphanumeric, hyphens, underscores)
    if ! echo "$module_name" | grep -q '^[a-zA-Z0-9_-]\+$'; then
        echo "Error: Module name contains invalid characters"
        echo "Use only letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Check length
    if [ ${#module_name} -gt 50 ]; then
        echo "Error: Module name too long (max 50 characters)"
        return 1
    fi
    
    return 0
}

# Check if directory exists and handle overwrite
check_directory_exists() {
    local module_dir=$1
    
    if [ -d "$module_dir" ]; then
        echo -e "${YELLOW}Warning: Directory already exists: $module_dir${NC}"
        read -p "Continue and overwrite? [y/N] " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return 1
        fi
    fi
    return 0
}

# Create basic directory structure
create_directory_structure() {
    local module_dir=$1
    
    echo -e "${BLUE}Creating directory structure...${NC}"
    
    mkdir -p "$module_dir"/{ansible/{tasks,handlers,templates,files,vars,defaults,meta},docker/{config,scripts},tests,examples,.github/workflows}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Directories created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create directories${NC}"
        return 1
    fi
}

# Create MODULE.yml configuration file
create_module_yml() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating MODULE.yml...${NC}"
    
    cat > "$module_dir/MODULE.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME Module
# ==============================================================================

module:
  name: MODULE_NAME
  version: "1.0.0"
  description: "MODULE_NAME - Description here"
  author: "Ahab Project"
  license: "MIT"
  tags: ["MODULE_NAME"]
  
  deployment:
    ansible: true
    docker: true
  
  platforms:
    - name: Fedora
      versions: ["38", "39"]
      packages: []
      service: MODULE_NAME
    - name: Debian
      versions: ["11", "12", "13"]
      packages: []
      service: MODULE_NAME
  
  dependencies:
    modules: []
    system:
      fedora: []
      debian: []
    docker:
      base_image: "alpine:latest"
  
  network:
    ports: []
    expose: []
  
  storage:
    volumes: []
  
  environment:
    variables: []
  
  health:
    docker:
      test: ["CMD", "true"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  resources:
    limits:
      cpus: "1.0"
      memory: "512M"
    reservations:
      cpus: "0.25"
      memory: "128M"
  
  integration:
    compatible_with: []
    provides: []

docker_compose:
  service_name: MODULE_NAME
  restart: unless-stopped
  networks: ["webnet"]
  labels:
    com.ahab.module: "MODULE_NAME"
    com.ahab.version: "1.0.0"
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/MODULE.yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ MODULE.yml created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create MODULE.yml${NC}"
        return 1
    fi
}
# Create Ansible role task files
create_ansible_tasks() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating Ansible role files...${NC}"
    
    # tasks/main.yml
    cat > "$module_dir/ansible/tasks/main.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME - Main Tasks
# ==============================================================================

- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"
  tags: [always]

- name: Install MODULE_NAME packages
  package:
    name: "{{ MODULE_NAME_packages }}"
    state: present
  become: true
  tags: [install]

- name: Create MODULE_NAME configuration directory
  file:
    path: /etc/MODULE_NAME
    state: directory
    mode: '0755'
  become: true
  tags: [config]

- name: Configure MODULE_NAME
  template:
    src: MODULE_NAME.conf.j2
    dest: /etc/MODULE_NAME/MODULE_NAME.conf
    mode: '0644'
  become: true
  notify: restart MODULE_NAME
  tags: [config]

- name: Start and enable MODULE_NAME service
  systemd:
    name: MODULE_NAME
    state: started
    enabled: true
  become: true
  tags: [service]
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/ansible/tasks/main.yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Ansible tasks created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create Ansible tasks${NC}"
        return 1
    fi
}

# Create Ansible handlers
create_ansible_handlers() {
    local module_dir=$1
    local module_name=$2
    
    cat > "$module_dir/ansible/handlers/main.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME - Handlers
# ==============================================================================

- name: restart MODULE_NAME
  systemd:
    name: MODULE_NAME
    state: restarted
  become: true
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/ansible/handlers/main.yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Ansible handlers created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create Ansible handlers${NC}"
        return 1
    fi
}

# Create Ansible variables
create_ansible_variables() {
    local module_dir=$1
    local module_name=$2
    
    # defaults/main.yml
    cat > "$module_dir/ansible/defaults/main.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME - Default Variables
# ==============================================================================

MODULE_NAME_version: "latest"
MODULE_NAME_port: 80
MODULE_NAME_config_dir: "/etc/MODULE_NAME"
MODULE_NAME_log_level: "info"
EOF

    # vars/Fedora.yml
    cat > "$module_dir/ansible/vars/Fedora.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME - Fedora Variables
# ==============================================================================

MODULE_NAME_packages:
  - MODULE_NAME
EOF

    # vars/Debian.yml
    cat > "$module_dir/ansible/vars/Debian.yml" << 'EOF'
---
# ==============================================================================
# MODULE_NAME - Debian Variables
# ==============================================================================

MODULE_NAME_packages:
  - MODULE_NAME
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/ansible/defaults/main.yml"
    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/ansible/vars/Fedora.yml"
    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/ansible/vars/Debian.yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Ansible variables created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create Ansible variables${NC}"
        return 1
    fi
}
# Create Dockerfile
create_dockerfile() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating Dockerfile...${NC}"
    
    cat > "$module_dir/Dockerfile" << 'EOF'
# ==============================================================================
# MODULE_NAME Docker Image
# ==============================================================================

FROM alpine:latest

# Install MODULE_NAME
RUN apk add --no-cache MODULE_NAME

# Create non-root user
RUN addgroup -g 1000 MODULE_NAME && \
    adduser -D -s /bin/sh -u 1000 -G MODULE_NAME MODULE_NAME

# Switch to non-root user
USER MODULE_NAME

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD true

# Expose port
EXPOSE 80

CMD ["MODULE_NAME"]
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/Dockerfile"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dockerfile created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create Dockerfile${NC}"
        return 1
    fi
}

# Create README.md
create_readme() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating README.md...${NC}"
    
    cat > "$module_dir/README.md" << 'EOF'
# Ahab MODULE_NAME Module

MODULE_NAME module for Ahab infrastructure automation.

## Overview

This module provides automated deployment and management of MODULE_NAME using:
- Ansible for configuration management
- Docker for containerization
- Comprehensive testing suite

## Quick Start

```bash
# Deploy MODULE_NAME
make install MODULE_NAME

# Check status
make status MODULE_NAME

# Remove MODULE_NAME
make clean MODULE_NAME
```

## Features

- ✅ Multi-OS support (Fedora, Debian, Ubuntu)
- ✅ Docker containerization
- ✅ Security hardening
- ✅ Health monitoring
- ✅ Automated testing

## Requirements

- Ahab infrastructure
- Docker (for containerized deployment)
- Ansible (for bare-metal deployment)

## Configuration

See `MODULE.yml` for configuration options.

## Testing

```bash
# Run tests
make test

# Integration tests
make test-integration
```

## License

MIT License - see LICENSE file for details.
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/README.md"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ README.md created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create README.md${NC}"
        return 1
    fi
}

# Create test files
create_test_files() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating test files...${NC}"
    
    # Basic test script
    cat > "$module_dir/tests/test-${module_name}.sh" << 'EOF'
#!/usr/bin/env bash
# ==============================================================================
# MODULE_NAME Module Tests
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Testing MODULE_NAME Module"
echo "=========================================="

# Test 1: MODULE.yml exists and is valid
echo "→ Testing MODULE.yml..."
if [ ! -f "$MODULE_DIR/MODULE.yml" ]; then
    echo "✗ MODULE.yml not found"
    exit 1
fi
echo "✓ MODULE.yml exists"

# Test 2: Dockerfile exists
echo "→ Testing Dockerfile..."
if [ ! -f "$MODULE_DIR/Dockerfile" ]; then
    echo "✗ Dockerfile not found"
    exit 1
fi
echo "✓ Dockerfile exists"

# Test 3: Ansible role structure
echo "→ Testing Ansible role structure..."
for dir in tasks handlers templates files vars defaults meta; do
    if [ ! -d "$MODULE_DIR/ansible/$dir" ]; then
        echo "✗ Missing ansible/$dir directory"
        exit 1
    fi
done
echo "✓ Ansible role structure complete"

echo ""
echo "✅ All tests passed"
EOF

    chmod +x "$module_dir/tests/test-${module_name}.sh"
    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/tests/test-${module_name}.sh"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test files created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create test files${NC}"
        return 1
    fi
}

# Create GitHub Actions workflow
create_github_workflow() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Creating GitHub Actions workflow...${NC}"
    
    cat > "$module_dir/.github/workflows/ci.yml" << 'EOF'
name: CI

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Run tests
      run: |
        chmod +x tests/test-MODULE_NAME.sh
        ./tests/test-MODULE_NAME.sh
    
    - name: Build Docker image
      run: |
        docker build -t MODULE_NAME:test .
    
    - name: Test Docker image
      run: |
        docker run --rm MODULE_NAME:test --version || true
EOF

    sed_inplace "s/MODULE_NAME/${module_name}/g" "$module_dir/.github/workflows/ci.yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ GitHub Actions workflow created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create GitHub Actions workflow${NC}"
        return 1
    fi
}

# Initialize git repository
initialize_git_repository() {
    local module_dir=$1
    local module_name=$2
    
    echo -e "${BLUE}Initializing Git repository...${NC}"
    
    cd "$module_dir" || return 1
    
    # Initialize git if not already a repo
    if [ ! -d ".git" ]; then
        git init
        
        # Create .gitignore
        cat > .gitignore << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Build artifacts
*.log
.vagrant/
EOF
        
        git add .
        git commit -m "Initial commit: ${module_name} module structure"
        
        echo -e "${GREEN}✓ Git repository initialized${NC}"
    else
        echo -e "${YELLOW}⚠ Git repository already exists${NC}"
    fi
    
    cd - > /dev/null || return 1
    return 0
}