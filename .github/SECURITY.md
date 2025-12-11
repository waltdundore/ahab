# Security Policy

## Supported Versions

We actively support the following versions of Ahab:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| 0.1.x   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them responsibly:

### For Security Issues
1. **GitHub Security Advisories** (Preferred): [Report privately](https://github.com/waltdundore/ahab/security/advisories/new)
2. **Email**: Contact the maintainers directly (check repository for current contact info)

### What to Include
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Any suggested fixes (if you have them)

### Response Timeline
- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity, but we aim for:
  - Critical: Within 7 days
  - High: Within 30 days
  - Medium/Low: Next regular release

### Security Best Practices

Ahab follows security-first development:

#### Zero Trust Architecture
- Never trust user input
- Always validate and sanitize
- Assume breach scenarios
- Principle of least privilege

#### Container Security
- Non-root containers only
- Read-only filesystems where possible
- Resource limits enforced
- Regular vulnerability scanning

#### Secrets Management
- No hardcoded secrets
- Environment variables for configuration
- Encrypted secrets at rest
- Regular secret rotation

#### Infrastructure Security
- SELinux/AppArmor enforcement
- Firewall configuration
- Regular security updates
- Audit logging enabled

### Security Testing

We maintain comprehensive security testing:
- Automated secret detection
- Container security scanning
- Dependency vulnerability checks
- Static code analysis
- Property-based security testing

### Disclosure Policy

Once a security issue is resolved:
1. We will publish a security advisory
2. Credit will be given to the reporter (if desired)
3. Details will be shared after users have time to update

Thank you for helping keep Ahab secure! 🔒