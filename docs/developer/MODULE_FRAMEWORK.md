# Ahab Module Framework

## Overview

The Ahab Module Framework provides a unified way to define, deploy, and manage services across:
- **Bare Metal/VMs** - Using Ansible
- **Containers** - Using Docker/Docker Compose
- **Hybrid** - Mix of both

Each module is self-contained with metadata that can generate both Ansible playbooks and Docker configurations.

---

## Module Structure

```
ahab/
├── modules/
│   ├── apache/
│   │   ├── module.yml              # Module metadata (THE SOURCE OF TRUTH)
│   │   ├── ansible/
│   │   │   ├── tasks/
│   │   │   │   └── main.yml        # Ansible tasks
│   │   │   ├── handlers/
│   │   │   │   └── main.yml        # Service handlers
│   │   │   ├── templates/
│   │   │   │   └── httpd.conf.j2   # Config templates
│   │   │   └── defaults/
│   │   │       └── main.yml        # Default variables
│   │   ├── docker/
│   │   │   ├── Dockerfile          # Container image
│   │   │   ├── docker-compose.yml  # Standalone compose
│   │   │   └── entrypoint.sh       # Container entrypoint
│   │   ├── tests/
│   │   │   ├── ansible-test.yml    # Ansible test
│   │   │   ├── docker-test.yml     # Docker test
│   │   │   └── integration-test.sh # Integration test
│   │   └── README.md               # Module documentation
│   │
│   ├── php/
│   │   ├── module.yml
│   │   ├── ansible/
│   │   ├── docker/
│   │   ├── tests/
│   │   └── README.md
│   │
│   └── mysql/
│       ├── module.yml
│       ├── ansible/
│       ├── docker/
│       ├── tests/
│       └── README.md
│
├── scripts/
│   ├── create-module.sh            # Generate module structure
│   ├── generate-compose.sh         # Generate docker-compose from modules
│   ├── validate-module.sh          # Validate module metadata
│   └── test-module.sh              # Test module (ansible + docker)
│
└── MODULE_REGISTRY.yml             # Registry of all modules
```

---

## module.yml Format (The Source of Truth)

```yaml
---
# ==============================================================================
# Module Metadata
# ==============================================================================
# This file is the single source of truth for the module.
# It defines how the module works in both Ansible and Docker contexts.

module:
  # Basic Information
  name: apache
  version: "1.0.0"
  description: "Apache HTTP Server"
  author: "Ahab Project"
  license: "MIT"
  tags: ["webserver", "http", "apache"]
  
  # Deployment Modes
  deployment:
    ansible: true      # Can be deployed via Ansible
    docker: true       # Can be deployed via Docker
    kubernetes: false  # Future: K8s support
  
  # Platform Support (for Ansible)
  platforms:
    - name: Fedora
      versions: ["38", "39"]
      packages: ["httpd", "mod_ssl"]
      service: httpd
    - name: Debian
      versions: ["11", "12"]
      packages: ["apache2", "apache2-utils"]
      service: apache2
    - name: Ubuntu
      versions: ["20.04", "22.04"]
      packages: ["apache2", "apache2-utils"]
      service: apache2
  
  # Module Dependencies
  dependencies:
    # Other Ahab modules this module needs
    modules: []
    
    # System packages (for Ansible)
    system:
      fedora: ["httpd", "mod_ssl"]
      debian: ["apache2", "apache2-utils"]
    
    # Docker images (for Docker)
    docker:
      base_image: "httpd:2.4"
      # Or for custom builds:
      # build: "./docker"
  
  # Network Configuration
  network:
    ports:
      - port: 80
        protocol: tcp
        description: "HTTP"
      - port: 443
        protocol: tcp
        description: "HTTPS"
    
    # For Docker Compose
    expose:
      - 80
      - 443
  
  # Storage/Volumes
  storage:
    # For Ansible
    directories:
      - path: /var/www/html
        owner: apache
        group: apache
        mode: "0755"
      - path: /etc/httpd/conf.d
        owner: root
        group: root
        mode: "0755"
    
    # For Docker
    volumes:
      - type: bind
        source: ./html
        target: /usr/local/apache2/htdocs
      - type: bind
        source: ./config
        target: /usr/local/apache2/conf
  
  # Environment Variables
  environment:
    # Variables used by both Ansible and Docker
    variables:
      - name: APACHE_SERVER_NAME
        description: "Server name"
        required: false
        default: "localhost"
      
      - name: APACHE_PORT
        description: "HTTP port"
        required: false
        default: "80"
      
      - name: APACHE_SSL_PORT
        description: "HTTPS port"
        required: false
        default: "443"
      
      - name: APACHE_DOCUMENT_ROOT
        description: "Document root directory"
        required: false
        default: "/var/www/html"
  
  # Health Checks
  health:
    # For Docker
    docker:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    # For Ansible (verification)
    ansible:
      - command: "curl -I http://localhost"
        expected: "HTTP/1.1 200 OK"
      - command: "systemctl is-active {{ apache_service }}"
        expected: "active"
  
  # Resource Limits (for Docker)
  resources:
    limits:
      cpus: "1.0"
      memory: "512M"
    reservations:
      cpus: "0.5"
      memory: "256M"
  
  # Integration Points
  integration:
    # Services this module can integrate with
    compatible_with:
      - php
      - python
      - nodejs
    
    # Services this module provides
    provides:
      - webserver
      - reverse-proxy
    
    # Services this module requires
    requires: []

# ==============================================================================
# Docker Compose Specific
# ==============================================================================
docker_compose:
  service_name: apache
  
  # Restart policy
  restart: unless-stopped
  
  # Networks
  networks:
    - webnet
  
  # Labels
  labels:
    com.ahab.module: "apache"
    com.ahab.version: "1.0.0"

# ==============================================================================
# Testing
# ==============================================================================
testing:
  # Ansible tests
  ansible:
    playbook: tests/ansible-test.yml
    inventory: tests/inventory
  
  # Docker tests
  docker:
    compose: tests/docker-test.yml
    commands:
      - "docker exec apache curl -I http://localhost"
  
  # Integration tests
  integration:
    script: tests/integration-test.sh
    dependencies: []
```

---

## Example: Apache Module

<function_calls>
<invoke name="fsWrite">
<parameter name="path">ahab/modules/apache/module.yml==============================================================================
# Apache HTTP Server Module
# ==============================================================================

module:
  name: apache
  version: "1.0.0"
  description: "Apache HTTP Server - Industry-standard web server"
  author: "Ahab Project"
  license: "MIT"
  tags: ["webserver", "http", "apache", "httpd"]
  
  deployment:
    ansible: true
    docker: true
    kubernetes: false
  
  platforms:
    - name: Fedora
      versions: ["38", "39"]
      packages: ["httpd", "mod_ssl"]
      service: httpd
    - name: Debian
      versions: ["11", "12", "13"]
      packages: ["apache2", "apache2-utils"]
      service: apache2
    - name: Ubuntu
      versions: ["20.04", "22.04"]
      packages: ["apache2", "apache2-utils"]
      service: apache2
  
  dependencies:
    modules: []
    
    system:
      fedora: ["httpd", "mod_ssl"]
      debian: ["apache2", "apache2-utils"]
    
    docker:
      base_image: "httpd:2.4-alpine"
  
  network:
    ports:
      - port: 80
        protocol: tcp
        description: "HTTP"
      - port: 443
        protocol: tcp
        description: "HTTPS (optional)"
    
    expose:
      - 80
      - 443
  
  storage:
    directories:
      - path: /var/www/html
        owner: apache
        group: apache
        mode: "0755"
      - path: /etc/httpd/conf.d
        owner: root
        group: root
        mode: "0755"
    
    volumes:
      - type: bind
        source: ./html
        target: /usr/local/apache2/htdocs
        description: "Web content"
      - type: bind
        source: ./config
        target: /usr/local/apache2/conf
        description: "Apache configuration"
  
  environment:
    variables:
      - name: APACHE_SERVER_NAME
        description: "Server name (ServerName directive)"
        required: false
        default: "localhost"
      
      - name: APACHE_PORT
        description: "HTTP port"
        required: false
        default: "80"
      
      - name: APACHE_SSL_PORT
        description: "HTTPS port"
        required: false
        default: "443"
      
      - name: APACHE_DOCUMENT_ROOT
        description: "Document root directory"
        required: false
        default: "/usr/local/apache2/htdocs"
      
      - name: APACHE_LOG_LEVEL
        description: "Log level (debug, info, warn, error)"
        required: false
        default: "warn"
  
  health:
    docker:
      test: ["CMD", "httpd", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    
    ansible:
      - command: "curl -I http://localhost"
        expected: "HTTP/1.1"
      - command: "systemctl is-active httpd || systemctl is-active apache2"
        expected: "active"
  
  resources:
    limits:
      cpus: "1.0"
      memory: "512M"
    reservations:
      cpus: "0.25"
      memory: "128M"
  
  integration:
    compatible_with:
      - php
      - python
      - nodejs
      - wordpress
    
    provides:
      - webserver
      - http-server
    
    requires: []

docker_compose:
  service_name: apache
  restart: unless-stopped
  
  networks:
    - webnet
  
  labels:
    com.ahab.module: "apache"
    com.ahab.version: "1.0.0"
    com.ahab.description: "Apache HTTP Server"

testing:
  ansible:
    playbook: tests/ansible-test.yml
    inventory: tests/inventory
  
  docker:
    compose: tests/docker-test.yml
    commands:
      - "docker exec apache httpd -t"
      - "curl -I http://localhost"
  
  integration:
    script: tests/integration-test.sh
    dependencies: []
