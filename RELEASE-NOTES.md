# Ahab v0.0.1-alpha Release Notes

**Release Date:** December 5, 2024  
**Company:** Ahab Software, LLC  
**Website:** https://ahabsoftware.com

---

## Overview

First public alpha release of Ahab - Automated Host Administration & Build. This release provides a foundation for Ansible-based infrastructure automation across multiple Linux distributions.

## Features

### Core Functionality
- **Multi-Distribution Support** - Deploy to Fedora, Debian, Ubuntu, and more
- **Environment Management** - Separate configurations for dev, prod, and workstation
- **Vagrant Integration** - Local testing with single or multi-VM setups
- **Ansible Automation** - Pre-built playbooks and roles for common tasks

### Included Roles
- **Common** - Base system configuration, packages, users, SSH keys
- **Docker** - Docker installation and configuration
- **NFS** - NFS client setup and mounting
- **Proxy** - Reverse proxy configuration

### Repository Structure
- **ansible-control** - Core automation engine with playbooks and roles
- **ansible-inventory** - Environment-specific host definitions
- **ansible-config** - Centralized configuration management

### Developer Experience
- Consistent Makefiles across all repositories
- Example files for all gitignored configurations
- Comprehensive documentation
- Security scanning integration

## Installation

```bash
# Clone all three repositories
cd ~/git
git clone git@github.com:waltdundore/ansible-control.git
git clone git@github.com:waltdundore/ansible-inventory.git
git clone git@github.com:waltdundore/ansible-config.git

# Create symlinks
cd ansible-control
ln -s ../ansible-inventory inventory
ln -s ../ansible-config/config.yml config.yml

# View available commands
make help
```

## Quick Start

### Local Testing with Vagrant

```bash
cd ~/git/ansible-control

# Start single VM
make install

# Or start multiple VMs
make multi

# SSH into VM
make ssh
```

### Deploy to Real Hosts

```bash
# Configure inventory
cd ~/git/ansible-inventory/prod
cp hosts.yml.example hosts.yml
vim hosts.yml  # Add your servers

# Configure settings
cd ~/git/ansible-config/prod
vim config.yml  # Set your preferences

# Deploy
cd ~/git/ansible-control
make deploy
```

## Known Limitations (Alpha)

- Limited to Docker, NFS, and basic system configuration
- Vagrant testing primarily on macOS with Parallels
- Documentation still evolving
- No automated testing yet

## Requirements

- Ansible 2.9+
- Python 3.6+
- Vagrant 2.2+ (for local testing)
- SSH access to target hosts

## Breaking Changes

N/A - First release

## Upgrade Notes

N/A - First release

## Security

- All secrets must be in gitignored files
- Example files provided with placeholders
- Security scanning available via `scripts/security-scan.sh`

## Documentation

- README.md in each repository
- Branding guidelines in `.kiro/steering/branding.md`
- Makefile documentation via `make help`

## Support

- GitHub Issues: https://github.com/waltdundore/ansible-control/issues
- Website: https://ahabsoftware.com

## License

See LICENSE file in each repository.

## Copyright

© 2024 Ahab Software, LLC. All rights reserved.

---

## What's Next

### Planned for Beta (v0.1.0)
- Additional roles (web servers, databases)
- Automated testing
- Enhanced documentation
- CI/CD improvements
- Community feedback integration

### Future Releases
- Plugin system
- Web UI for management
- Cloud provider integrations
- Monitoring and alerting

---

**Thank you for trying Ahab!**

We welcome feedback and contributions. Please report issues on GitHub or contact us through our website.

Ahab Software, LLC  
https://ahabsoftware.com
