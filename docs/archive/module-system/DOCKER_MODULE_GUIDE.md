# Ahab Docker Module System Guide

## Overview

The Ahab module system provides a unified way to deploy services using either:
- **Ansible** (bare metal, VMs)
- **Docker** (containers)
- **Both** (hybrid deployments)

Modules are self-contained with metadata that automatically generates Docker Compose configurations.

---

## Quick Start

### Generate Docker Compose for Apache

```bash
cd ahab
./scripts/generate-docker-compose.py apache
docker-compose up -d
```

### Generate Docker Compose for Apache + PHP

```bash
./scripts/generate-docker-compose.py apache php
docker-compose up -d
```

### Generate for All Modules

```bash
./scripts/generate-docker-compose.py --all
docker-compose up -d
```

---

## Module Structure

Each module contains:

```
roles/apache/
├── MODULE.yml          # Metadata (dependencies, config, docker settings)
├── Dockerfile          # Docker image definition
├── tasks/              # Ansible tasks
│   └── main.yml
├── templates/          # Configuration templates
├── defaults/           # Default variables
├── handlers/           # Service handlers
├── tests/              # Test playbooks
├── config/             # Docker config files
├── html/               # Docker web content
└── README.md           # Documentation
```

---

## MODULE.yml Format

### Complete Example (Apache)

```yaml
---
module:
  name: apache
  version: "1.0.0"
  description: "Apache HTTP Server"
  
  # Deployment methods supported
  deployment:
    ansible: true
    docker: true
  
  # Supported platforms (for Ansible)
  platforms:
    - name: Fedora
      versions: ["38", "39"]
      packages: ["httpd", "mod_ssl"]
      service: httpd
    - name: Debian
      versions: ["11", "12"]
      packages: ["apache2"]
      service: apache2
  
  # Dependencies
  dependencies:
    modules: []  # No module dependencies
    system:
      fedora: ["httpd", "mod_ssl"]
      debian: ["apache2"]
    docker:
      base_image: "httpd:2.4-alpine"
  
  # Network configuration
  network:
    ports:
      - port: 80
        protocol: tcp
        description: "HTTP"
      - port: 443
        protocol: tcp
        description: "HTTPS"
    expose: [80, 443]
  
  # Storage configuration
  storage:
    volumes:
      - type: bind
        source: ./html
        target: /usr/local/apache2/htdocs
        description: "Web content"
  
  # Environment variables
  environment:
    variables:
      - name: APACHE_SERVER_NAME
        default: "localhost"
      - name: APACHE_PORT
        default: "80"
  
  # Health checks
  health:
    docker:
      test: ["CMD", "httpd", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  # Resource limits
  resources:
    limits:
      cpus: "1.0"
      memory: "512M"
    reservations:
      cpus: "0.25"
      memory: "128M"
  
  # Integration
  integration:
    compatible_with: ["php", "python"]
    provides: ["webserver"]
    requires: []

# Docker Compose specific settings
docker_compose:
  service_name: apache
  restart: unless-stopped
  networks: ["webnet"]
  labels:
    com.ahab.module: "apache"
```

---

## Creating a New Module

### Step 1: Create Module Directory

```bash
mkdir -p ahab/roles/mymodule/{tasks,templates,defaults,handlers,tests,config}
```

### Step 2: Create MODULE.yml

```bash
cat > ahab/roles/mymodule/MODULE.yml << 'EOF'
---
module:
  name: mymodule
  version: "1.0.0"
  description: "My custom module"
  
  deployment:
    ansible: true
    docker: true
  
  dependencies:
    modules: []
    docker:
      base_image: "alpine:latest"
  
  network:
    ports:
      - port: 8080
        protocol: tcp
    expose: [8080]
  
  environment:
    variables:
      - name: MY_VAR
        default: "value"

docker_compose:
  service_name: mymodule
  restart: unless-stopped
EOF
```

### Step 3: Create Dockerfile

```bash
cat > ahab/roles/mymodule/Dockerfile << 'EOF'
FROM alpine:latest

LABEL com.ahab.module="mymodule"
LABEL com.ahab.version="1.0.0"

RUN apk add --no-cache curl bash

EXPOSE 8080

CMD ["sh", "-c", "while true; do sleep 3600; done"]
EOF
```

### Step 4: Generate Docker Compose

```bash
cd ahab
./scripts/generate-docker-compose.py mymodule
```

---

## Module Dependencies

### Declaring Dependencies

In `MODULE.yml`:

```yaml
dependencies:
  modules:
    - name: apache
      version: ">=1.0.0"
      optional: false
      reason: "Requires web server"
    - name: mysql
      version: ">=8.0"
      optional: true
      reason: "Optional database backend"
```

### Automatic Resolution

The generator automatically:
1. Resolves all dependencies
2. Orders services correctly
3. Adds `depends_on` in docker-compose
4. Validates compatibility

### Example: PHP depends on Apache

```bash
# Generate PHP (automatically includes Apache)
./scripts/generate-docker-compose.py php

# Generated docker-compose.yml includes:
# - apache service (dependency)
# - php service (depends_on: apache)
```

---

## Docker Compose Generation

### Basic Usage

```bash
# Single module
./scripts/generate-docker-compose.py apache

# Multiple modules
./scripts/generate-docker-compose.py apache php mysql

# All modules
./scripts/generate-docker-compose.py --all

# Custom output file
./scripts/generate-docker-compose.py -o custom.yml apache php

# Validate without generating
./scripts/generate-docker-compose.py --validate apache
```

### Generated Structure

```yaml
version: '3.8'

services:
  apache:
    image: httpd:2.4-alpine
    container_name: apache
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/local/apache2/htdocs
    networks:
      - webnet
    healthcheck:
      test: ["CMD", "httpd", "-t"]
      interval: 30s
    labels:
      com.ahab.module: "apache"
  
  php:
    image: php:8.2-fpm-alpine
    container_name: php
    restart: unless-stopped
    expose:
      - 9000
    volumes:
      - ./app:/var/www/html
    networks:
      - webnet
    depends_on:
      - apache
    labels:
      com.ahab.module: "php"

networks:
  webnet:
    driver: bridge
```

---

## Testing Modules

### Test Individual Module (Docker)

```bash
# Build image
cd ahab/roles/apache
docker build -t ahab/apache:1.0.0 .

# Test standalone
docker run -d -p 80:80 --name apache-test ahab/apache:1.0.0

# Verify
curl http://localhost

# Cleanup
docker stop apache-test && docker rm apache-test
```

### Test with Docker Compose

```bash
# Generate compose file
./scripts/generate-docker-compose.py apache

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs apache

# Test
curl http://localhost

# Cleanup
docker-compose down
```

### Test Module Integration

```bash
# Generate Apache + PHP
./scripts/generate-docker-compose.py apache php

# Start services
docker-compose up -d

# Test Apache
curl http://localhost

# Test PHP
curl http://localhost/index.php

# Cleanup
docker-compose down
```

---

## Deployment Scenarios

### Scenario 1: Docker Only

```bash
# Generate docker-compose.yml
./scripts/generate-docker-compose.py apache php mysql

# Deploy
docker-compose up -d

# Scale services
docker-compose up -d --scale php=3
```

### Scenario 2: Ansible Only

```bash
# Deploy to bare metal/VMs
cd ahab
ansible-playbook -i inventory/prod/hosts.yml playbooks/webserver.yml
```

### Scenario 3: Hybrid (Docker on VMs)

```bash
# Use Ansible to deploy Docker Compose on VMs
ansible-playbook -i inventory/prod/hosts.yml playbooks/docker-deploy.yml \
  -e "modules=apache,php"
```

---

## Module Registry

Track all modules in `MODULE_REGISTRY.yml`:

```yaml
---
modules:
  apache:
    path: roles/apache
    version: "1.0.0"
    status: stable
    deployment: [ansible, docker]
    dependencies: []
  
  php:
    path: roles/php
    version: "1.0.0"
    status: stable
    deployment: [ansible, docker]
    dependencies: [apache]
  
  mysql:
    path: roles/mysql
    version: "1.0.0"
    status: stable
    deployment: [ansible, docker]
    dependencies: []
```

---

## Best Practices

### Module Design

✅ **DO:**
- Keep modules focused (single responsibility)
- Support both Ansible and Docker when possible
- Document all dependencies
- Include health checks
- Provide sensible defaults
- Version your modules

❌ **DON'T:**
- Mix multiple services in one module
- Hardcode configuration
- Forget to document variables
- Skip health checks
- Ignore resource limits

### Docker Images

✅ **DO:**
- Use official base images
- Use Alpine for smaller images
- Include health checks
- Label images properly
- Document exposed ports
- Use multi-stage builds when needed

❌ **DON'T:**
- Use `latest` tag in production
- Run as root unnecessarily
- Include secrets in images
- Forget to clean up in Dockerfile
- Ignore security updates

### Dependencies

✅ **DO:**
- Minimize dependencies
- Document why dependencies exist
- Use version constraints
- Test with and without optional deps
- Validate compatibility

❌ **DON'T:**
- Create circular dependencies
- Use wildcards for versions
- Forget to test dependency order
- Assume dependencies are installed

---

## Troubleshooting

### Module Not Found

```bash
# List available modules
ls ahab/roles/

# Validate module
./scripts/generate-docker-compose.py --validate apache
```

### Dependency Resolution Fails

```bash
# Check MODULE.yml syntax
cd ahab/roles/mymodule
python3 -c "import yaml; yaml.safe_load(open('MODULE.yml'))"

# Verify dependencies exist
ls ahab/roles/dependency-name/
```

### Docker Compose Generation Fails

```bash
# Run with debug output
python3 -v ./scripts/generate-docker-compose.py apache

# Validate YAML
yamllint ahab/roles/apache/MODULE.yml
```

### Services Won't Start

```bash
# Check logs
docker-compose logs service-name

# Check health
docker-compose ps

# Inspect service
docker inspect container-name
```

---

## Examples

### Example 1: Simple Web Server

```bash
# Generate Apache only
./scripts/generate-docker-compose.py apache

# Start
docker-compose up -d

# Test
curl http://localhost
```

### Example 2: LAMP Stack

```bash
# Generate Linux + Apache + MySQL + PHP
./scripts/generate-docker-compose.py apache mysql php

# Start
docker-compose up -d

# Test
curl http://localhost/index.php
```

### Example 3: Custom Application

```bash
# Create custom module
mkdir -p roles/myapp
# ... create MODULE.yml and Dockerfile ...

# Generate with dependencies
./scripts/generate-docker-compose.py apache php mysql myapp

# Deploy
docker-compose up -d
```

---

## Integration with Ahab

### Use with Vagrant

```bash
# Test in Vagrant VM
vagrant up
vagrant ssh

# Inside VM
cd ~/git/ahab
./scripts/generate-docker-compose.py apache php
docker-compose up -d
```

### Use with Ansible

```bash
# Deploy Docker Compose via Ansible
ansible-playbook -i inventory/prod/hosts.yml playbooks/docker-stack.yml \
  -e "stack_modules=apache,php,mysql"
```

---

## Next Steps

1. **Create your first module** - Follow the creation guide
2. **Test locally** - Use Docker Compose
3. **Deploy to VMs** - Use Ansible
4. **Scale services** - Use Docker Swarm or Kubernetes
5. **Monitor** - Add monitoring modules

---

## Reference

- **MODULE.yml Schema:** See MODULE_FRAMEWORK.md
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **Ansible Docs:** https://docs.ansible.com/
- **Best Practices:** See MODULE_SYSTEM.md

---

**Ready to build modular infrastructure!** 🚀
