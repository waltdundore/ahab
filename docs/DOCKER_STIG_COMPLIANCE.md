# Docker STIG Compliance Documentation

**Status**: MANDATORY  
**Last Updated**: December 9, 2025  
**Reference**: [Docker Hardened Images (DHI) STIG](https://docs.docker.com/dhi/core-concepts/stig/)

---

## Overview

This document provides comprehensive guidance for implementing Docker Security Technical Implementation Guide (STIG) requirements in the Ahab project. Docker STIG compliance is mandatory for all containers and enforces Defense in Depth security principles.

## Table of Contents

1. [STIG Requirements](#stig-requirements)
2. [Implementation Guide](#implementation-guide)
3. [Testing and Validation](#testing-and-validation)
4. [CI/CD Integration](#cicd-integration)
5. [Exception Management](#exception-management)
6. [Troubleshooting](#troubleshooting)

---

## STIG Requirements

### V-235783: Non-Root User

**Requirement**: Containers MUST NOT run as root.

**Rationale**: Running as root provides unnecessary privileges and increases attack surface. If a container is compromised, the attacker gains root access to the container and potentially the host.

**Implementation**:
```dockerfile
FROM python:3.11-slim

# Create non-root user with specific UID/GID
RUN groupadd -r appuser -g 1000 && \
    useradd -r -u 1000 -g appuser appuser

# Install dependencies as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Switch to non-root user
USER appuser

# Application code (owned by appuser)
WORKDIR /app
COPY --chown=appuser:appuser . /app

CMD ["python", "app.py"]
```

**Validation**:
```bash
# Check Dockerfile
grep "^USER " Dockerfile

# Verify running container
docker run --rm myapp:latest whoami
# Should output: appuser (not root)
```

---

### V-235784: Read-Only Root Filesystem

**Requirement**: Container root filesystem SHOULD be read-only.

**Rationale**: Read-only filesystems prevent attackers from modifying binaries, installing malware, or persisting changes. This limits the blast radius of a compromise.

**Implementation**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=100m
      - /var/run:rw,noexec,nosuid,size=10m
    volumes:
      - ./config:/app/config:ro
      - app-logs:/app/logs:rw

volumes:
  app-logs:
    driver: local
```

**Exceptions**: Databases, log collectors, and applications that require writable filesystems must document exceptions in `.docker-stig-exceptions.yml`.

**Validation**:
```bash
# Test read-only filesystem
docker run --rm --read-only myapp:latest touch /test.txt
# Should fail with: Read-only file system
```

---

### V-235785: Drop Capabilities

**Requirement**: Drop all capabilities, add only what's needed.

**Rationale**: Linux capabilities provide fine-grained privilege control. Dropping all capabilities and adding only necessary ones follows the principle of least privilege.

**Implementation**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:latest
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only for binding to ports < 1024
    security_opt:
      - no-new-privileges:true
```

**Common Capabilities**:
- `NET_BIND_SERVICE` - Bind to privileged ports (< 1024)
- `CHOWN` - Change file ownership
- `DAC_OVERRIDE` - Bypass file permission checks
- `SETUID/SETGID` - Change user/group ID

**Validation**:
```bash
# Check capabilities
docker run --rm --cap-drop=ALL myapp:latest capsh --print
```

---

### V-235786: Security Options

**Requirement**: Enable security hardening options.

**Rationale**: Security options like seccomp, AppArmor, and SELinux provide additional layers of defense by restricting system calls and enforcing mandatory access control.

**Implementation**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation
      - seccomp:default         # Enable syscall filtering
      - apparmor:docker-default # AppArmor profile (Debian/Ubuntu)
      # OR for Fedora/RHEL:
      # - label:type:container_runtime_t  # SELinux label
```

**Validation**:
```bash
# Check security options
docker inspect myapp:latest | jq '.[0].HostConfig.SecurityOpt'
```

---

### V-235787: Resource Limits

**Requirement**: Set memory and CPU limits.

**Rationale**: Resource limits prevent containers from exhausting host resources (DoS attacks) and ensure fair resource allocation.

**Implementation**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    pids_limit: 100
```

**Validation**:
```bash
# Check resource limits
docker inspect myapp:latest | jq '.[0].HostConfig.Memory'
docker inspect myapp:latest | jq '.[0].HostConfig.NanoCpus'
```

---

### V-235788: Network Isolation

**Requirement**: Isolate container networks.

**Rationale**: Network segmentation limits lateral movement in case of compromise. Services should only communicate with necessary peers.

**Implementation**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:latest
    networks:
      - frontend
  
  app:
    image: myapp:latest
    networks:
      - frontend
      - backend
  
  db:
    image: postgres:latest
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

**Validation**:
```bash
# Check network configuration
docker network inspect myapp_backend | jq '.[0].Internal'
# Should output: true
```

---

### V-235789: Image Scanning

**Requirement**: Scan images for vulnerabilities.

**Rationale**: Known vulnerabilities in base images and dependencies can be exploited. Regular scanning identifies and remediates vulnerabilities before deployment.

**Implementation**:
```bash
# Scan with Docker Scout (preferred)
docker scout cves --exit-code --only-severity high,critical myapp:latest

# Alternative: Trivy
trivy image --exit-code 1 --severity HIGH,CRITICAL myapp:latest

# Alternative: Grype
grype myapp:latest --fail-on high
```

**CI/CD Integration**:
```bash
# In CI pipeline
./scripts/ci/scan-docker-images.sh
```

---

### V-235790: Minimal Base Images

**Requirement**: Use minimal base images.

**Rationale**: Smaller images have fewer packages, reducing attack surface and vulnerability exposure. They also build and deploy faster.

**Implementation**:
```dockerfile
# ✅ Preferred: Minimal images
FROM python:3.11-slim  # Debian-based, minimal
FROM alpine:3.19       # Alpine Linux, very minimal
FROM scratch           # Empty image (for static binaries)

# ✅ Multi-stage builds
FROM python:3.11 AS builder
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
USER 1000
CMD ["python", "app.py"]
```

**Avoid**:
```dockerfile
# ❌ Avoid: Full images
FROM ubuntu:latest
FROM python:3.11  # Use python:3.11-slim instead
```

---

### V-235791: Secrets Management

**Requirement**: Never embed secrets in images.

**Rationale**: Secrets in images are visible in image layers, registries, and can be extracted by anyone with access to the image.

**Implementation**:
```dockerfile
# ✅ Use build secrets (not embedded)
# syntax=docker/dockerfile:1
FROM python:3.11-slim

RUN --mount=type=secret,id=pip_token \
    pip install --index-url https://$(cat /run/secrets/pip_token)@pypi.org/simple mypackage
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    secrets:
      - db_password
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Validation**:
```bash
# Scan for secrets
./scripts/ci/scan-secrets.sh
```

---

### V-235792: Health Checks

**Requirement**: Define health checks for containers.

**Rationale**: Health checks enable orchestrators to detect and restart unhealthy containers, improving availability and reliability.

**Implementation**:
```dockerfile
FROM python:3.11-slim

USER 1000
WORKDIR /app
COPY --chown=1000:1000 . /app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

CMD ["python", "app.py"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
```

**Validation**:
```bash
# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## Implementation Guide

### Step 1: Audit Current Configurations

```bash
cd ahab
./scripts/ci/validate-docker-stig.sh
```

This will identify all STIG violations in your current Docker configurations.

### Step 2: Fix Violations

For each violation, refer to the requirement section above and implement the compliant pattern.

### Step 3: Test Compliance

```bash
# Run property tests
./tests/property/test-docker-stig-compliance.sh

# Validate all configurations
./scripts/ci/validate-docker-stig.sh
```

### Step 4: Document Exceptions

If a requirement cannot be met, document it:

```yaml
# .docker-stig-exceptions.yml
exceptions:
  - container: postgres
    requirement: V-235784
    reason: "Database requires writable filesystem"
    approved_by: "Security Team"
    date: "2025-12-09"
    mitigation: "Volume mounted with noexec,nosuid"
```

---

## Testing and Validation

### Automated Testing

```bash
# Run all STIG compliance tests
cd ahab
make test-docker-stig

# Or run individual tests
./tests/property/test-docker-stig-compliance.sh
./scripts/ci/validate-docker-stig.sh
./scripts/ci/scan-docker-images.sh
```

### Manual Validation

```bash
# Test 1: Non-root user
docker run --rm myapp:latest whoami

# Test 2: Read-only filesystem
docker run --rm --read-only myapp:latest touch /test.txt

# Test 3: Capabilities
docker run --rm --cap-drop=ALL myapp:latest capsh --print

# Test 4: Security options
docker inspect myapp:latest | jq '.[0].HostConfig.SecurityOpt'

# Test 5: Resource limits
docker inspect myapp:latest | jq '.[0].HostConfig.Memory'

# Test 6: Health check
docker inspect myapp:latest | jq '.[0].Config.Healthcheck'
```

---

## CI/CD Integration

### Pre-Commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running Docker STIG compliance checks..."
./scripts/ci/validate-docker-stig.sh
./scripts/ci/scan-secrets.sh

echo "All checks passed!"
```

### CI Pipeline

```yaml
# .github/workflows/security.yml
name: Security Checks

on: [push, pull_request]

jobs:
  docker-stig:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate Docker STIG Compliance
        run: |
          cd ahab
          ./scripts/ci/validate-docker-stig.sh
      
      - name: Scan Docker Images
        run: |
          cd ahab
          ./scripts/ci/scan-docker-images.sh
      
      - name: Scan for Secrets
        run: |
          cd ahab
          ./scripts/ci/scan-secrets.sh
```

---

## Exception Management

### When to Request an Exception

Exceptions should be rare and only granted when:
1. Technical requirement prevents compliance
2. Mitigation controls are in place
3. Business justification exists
4. Security team approves

### Exception Process

1. **Document** the exception in `.docker-stig-exceptions.yml`
2. **Justify** why compliance is not possible
3. **Mitigate** with alternative controls
4. **Approve** by security team
5. **Review** exceptions quarterly

### Exception Template

```yaml
exceptions:
  - container: <container-name>
    requirement: <STIG-ID>
    reason: "<why compliance is not possible>"
    approved_by: "<approver-name>"
    date: "<approval-date>"
    mitigation: "<alternative controls>"
    review_date: "<next-review-date>"
```

---

## Troubleshooting

### Issue: Container fails to start after adding USER directive

**Cause**: Application files not owned by non-root user.

**Solution**:
```dockerfile
# Ensure files are owned by non-root user
COPY --chown=appuser:appuser . /app
```

### Issue: Application can't write logs with read-only filesystem

**Cause**: No writable tmpfs or volume for logs.

**Solution**:
```yaml
services:
  app:
    read_only: true
    volumes:
      - app-logs:/app/logs:rw
```

### Issue: Container needs to bind to port 80

**Cause**: Non-root user can't bind to privileged ports.

**Solution**:
```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### Issue: Health check fails immediately

**Cause**: Application needs time to start.

**Solution**:
```dockerfile
HEALTHCHECK --start-period=30s --interval=30s \
    CMD curl -f http://localhost/health || exit 1
```

---

## References

- [Docker STIG Documentation](https://docs.docker.com/dhi/core-concepts/stig/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

---

## Summary

Docker STIG compliance is mandatory for all containers in the Ahab project. The 10 requirements provide Defense in Depth security:

1. **V-235783**: Non-root users
2. **V-235784**: Read-only filesystems
3. **V-235785**: Capability dropping
4. **V-235786**: Security options
5. **V-235787**: Resource limits
6. **V-235788**: Network isolation
7. **V-235789**: Image scanning
8. **V-235790**: Minimal base images
9. **V-235791**: Secrets management
10. **V-235792**: Health checks

All requirements are enforced through automated testing and CI/CD pipelines. Exceptions must be documented and approved.

---

**Last Updated**: December 9, 2025  
**Maintained By**: Ahab Security Team  
**Review Frequency**: Quarterly
