# Ahab - Infrastructure Automation for Schools and Non-Profits

![Ahab Logo](../docs/images/ahab-logo.png)

**Our Commitment**: Every build produces a working `docker-compose.yml` file. This file is proof: proof that services deploy correctly, proof that tests pass, proof that we deliver what we promise.

**Our Mission**: Document what we know. Teach what we've learned. Pass it forward.

> *"We're not here forever, but what we teach can be."*

---

## 📋 Start Here

**New to technical documentation?** → [Executive Summary](../../../EXECUTIVE_SUMMARY.md) (for school leaders and decision makers)

**Ready to try it?** → Jump to [Quick Start](#quick-start)

**Want to understand it first?** → Keep reading

---

## What Is Ahab?

Ahab is infrastructure automation software designed specifically for schools and non-profits. It helps you:
- Deploy services (websites, databases, applications) with simple commands
- Manage lab computers and servers
- Control your own data instead of relying on cloud vendors
- Teach students real DevOps skills

**Three commands to get started:**
```bash
make install    # Set up infrastructure
make test       # Verify it works
make deploy     # Deploy services
```

---

## Why Ahab?

### We Use What We Document

**We test what we document.**

Every command in our documentation is tested in our homelab environment. Same repository. Same commands. We're developing this for future production use and test every change on our own network.

**Why this matters:**
- If `make install` doesn't work for us, it won't work for you
- Bugs hit us first, not you
- We test the same interface we teach
- No hidden "real" commands—what you see is what we use

**Other projects:**
```bash
# Run these commands... (but actually use our internal tool)
# Complex multi-step process with hidden dependencies
```

**Ahab:**
```bash
# This is exactly what we use. This is what we test.
make install apache
```

**When we say "it works," we mean "it's working for us right now."**

**See what we've learned**: [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) documents every issue we've found, how we fixed it, and what we learned. This is transparency in action.

### Core Principles

**Our Priorities (in order):**
1. **Student Achievement First** - Everything we do serves student learning and success
2. **Bug-Free Software** - Quality and reliability before features
3. **Marketing What We Do** - Share our work to maximize benefit for education

**Technical Principles:**
1. **Docker Compose First** - Every build produces a working `docker-compose.yml` file
2. **We Use What We Document** - Same commands, same repository, same network
3. **Never Assume Success** - Every operation is verified
4. **Container-First Architecture** - Always use containers, never install directly on hosts
5. **Safety-Critical Standards** - We follow NASA Power of 10 rules
6. **Radical Transparency** - We show you everything: what works, what doesn't, what we're fixing

**Learn More**: [DEVELOPMENT_RULES.md](../../../DEVELOPMENT_RULES.md)

---

## Quick Start

```bash
# Clone all four repositories
git clone git@github.com:waltdundore/ahab.git
git clone git@github.com:waltdundore/ansible-config.git
git clone git@github.com:waltdundore/ansible-inventory.git
cd ahab
git submodule update --init --recursive  # Clones ahab-modules

# Install and deploy
make install         # Creates workstation VM (fixes permissions automatically)
make verify-install  # Verify everything works
make test            # Run full test suite
```

That's it. Three commands: install, verify, test.

**Test Status**: Every `make test` records status in `.test-status`. Only passing versions are promotable to production.

---

## Architecture

### Four Repositories, One Purpose

We separate concerns for clarity:

| Repository | Purpose | URL |
|-----------|---------|-----|
| **ahab** | Orchestration, playbooks, scripts | git@github.com:waltdundore/ahab.git |
| **ansible-config** | Configuration variables | git@github.com:waltdundore/ansible-config.git |
| **ansible-inventory** | Environment definitions (dev/prod) | git@github.com:waltdundore/ansible-inventory.git |
| **ahab-modules** | Service definitions (Apache, PHP, etc.) | git@github.com:waltdundore/ahab-modules.git |

**How They Connect**:
- `ahab/inventory` → symlink to `ansible-inventory`
- `ahab/config.yml` → symlink to `ansible-config`
- `ahab/modules` → Git submodule to `ahab-modules`

**Why Four Repositories?**
- **Orchestration** separate from **configuration**
- **Configuration** separate from **inventory**
- **Modules** separate from all three
- Each can be versioned independently
- Each can be tested in isolation

### Docker Compose First

**Our Goal**: Every build produces a working `docker-compose.yml` file.

**How It Works**:
1. Modules define services in `module.yml` files
2. Script reads module metadata
3. Script generates `docker-compose.yml` automatically
4. You deploy with `docker-compose up -d`

**Example**:
```bash
cd ahab
make install apache
curl http://localhost  # Apache is running
```

**Why Docker Compose?**
- Reproducible deployments
- Works on any platform
- Easy to understand
- Easy to modify
- Proof that it works

---

## Commands

```bash
# Workstation
make install              # Create workstation VM
make verify-install       # Verify installation
make ssh                  # SSH into workstation
make clean                # Destroy VM

# Deployment
make deploy-apache        # Deploy Apache (Docker)
make deploy-mysql         # Deploy MySQL (Docker)

# Testing
make test                 # Run tests
make status               # Show status

# Documentation Audit (with timeout protection)
make audit-docs           # Audit documentation for command violations
make audit-docs-fix       # Audit and auto-fix violations
make audit-docs-strict    # Audit in strict mode (for CI/CD)
make audit-priorities     # Audit that docs address our 3 core priorities

# Help
make help                 # Show all commands
```

---

## Configuration

Edit `ahab.conf` to change:
- OS versions (Fedora 43, Debian 13, Ubuntu 24.04)
- VM resources (memory, CPUs)
- GitHub settings
- Network configuration

**Single Source of Truth**: All settings in one file.

### Secrets Management

**Ansible Vault encrypts all secrets.**

```bash
# Encrypt a file
ansible-vault encrypt secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Decrypt for use
ansible-vault decrypt secrets.yml
```

**Never commit unencrypted secrets.** All sensitive data (passwords, API keys, certificates) must be encrypted with Ansible Vault before committing to Git.

---

## Testing Pipeline

We don't release until tests pass. Here's our pipeline:

### 1. Workstation Bootstrap Test (Critical Milestone)
```bash
make clean
make install
make verify-install
```
**Must Pass**: If `make install` doesn't work, nothing else matters.

### 2. Raspberry Pi Testing
- Deploy to local Raspberry Pi servers
- Validate on ARM architecture
- Run all tests

### 3. Dev Server Gate (d701.dundore.net)
- Deploy to production-like environment
- Run complete test suite
- **This is our internal quality gate**
- Users don't need this server (it's configurable)
- We don't release until this passes

### 4. Release Creation
- Only after all tests pass
- Tag all four repositories with same version
- Include validated `docker-compose.yml`
- Document what was tested and where

**Transparency**: Virtual tests must be perfect because users won't have d701.dundore.net. We test rigorously so you don't have to.

---

## Current Status

### ✅ What Works
- Four-repository architecture
- Bootstrap script clones all repos
- Symlinks created automatically
- Module system designed

### 🔄 In Progress
- Workstation bootstrap test (critical milestone)
- Docker Compose generation script
- Apache module deployment
- Testing framework

### ⚠️ Not Ready Yet
- No security audit
- Limited module library
- Experimental status
- Documentation consolidation in progress

**Transparency**: We're building this openly. We document failures as well as successes. See [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md).

---

## Who This Is For

### K-12 Schools
- Manage lab computers
- Host student projects
- Control your data
- Teach real DevOps
- Free forever

### Non-Profits
- Self-host services
- Reduce cloud costs
- Maintain privacy
- No vendor lock-in

### Students
- Learn by doing
- Real-world tools
- Safe to experiment
- Build portfolio projects

---

## Documentation

### For School Leaders
- **[EXECUTIVE_SUMMARY.md](../../../EXECUTIVE_SUMMARY.md)** - Non-technical overview for decision makers 📋

### For Students
- **[README-STUDENTS.md](../../../README-STUDENTS.md)** - High school student guide 🎓
  - CS standards covered (CSTA, AP CSP)
  - Step-by-step tutorials
  - How to access the website
  - Project ideas
  - Career paths

### For Users
- **[README.md](../../../README.md)** (this file) - Start here
- **[ABOUT.md](../../../ABOUT.md)** - Mission, vision, release process
- **[CHANGELOG.md](../../../CHANGELOG.md)** - Version history
- **[TROUBLESHOOTING.md](../../../TROUBLESHOOTING.md)** - Common issues
- **[LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md)** - What we've learned from real use

### For Developers
- **[PRIORITIES.md](../../../PRIORITIES.md)** - Quick reference for what to work on ⭐
- **[QUEUE.md](../../../QUEUE.md)** - Detailed work queue (our bible) 📋
- **[DEVELOPMENT_RULES.md](../../../DEVELOPMENT_RULES.md)** - Core principles and rules
- **[SAFETY_AUDIT.md](../../../SAFETY_AUDIT.md)** - Safety compliance status
- **[docs/](docs/)** - Supplementary documentation

---

## Roadmap

### Now (Critical Milestone)
- [ ] Workstation bootstrap test must pass
- [ ] Docker Compose generation working
- [ ] Apache deployment tested
- [ ] Documentation consolidated

### Next (After Milestone)
- [ ] Raspberry Pi testing
- [ ] Dev server deployment
- [ ] Release creation process
- [ ] More modules (MySQL, Nginx, PostgreSQL)

### Future
- [ ] Menu-driven interface
- [ ] Service marketplace
- [ ] Community modules
- [ ] Monitoring and alerts

---

## How to Help

1. **Test it** - Try `make install`, report issues
2. **Contribute** - Add modules, fix bugs
3. **Feedback** - Tell us what works and what doesn't
4. **Security** - Help with security review
5. **Spread the word** - Help schools and non-profits discover this

---

## License

Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

**In Plain English:**

This software is **free for schools, non-profits, and educational institutions**. You can:
- Use it without paying
- Modify it for your needs
- Share it with others
- Build upon it

**Requirements:**
- Give credit to the Ahab project
- Share your modifications under the same license
- Don't use it for commercial purposes without permission

**For-profit entities**: Commercial use requires negotiation. Contact us to discuss terms.

**Why this license?** We want to support education and non-profits while ensuring commercial users contribute back to the project.

See [LICENSE](LICENSE) file for full legal details.

---

## Disclaimer

⚠️ **Experimental / Educational** - Not production-ready. Needs security audit before production use.

**Philosophy**: Don't trust code you don't understand. Look it up. Research it. Learn how it works. That's the point here.

---

## Contact

- **GitHub**: https://github.com/waltdundore/ahab
- **Issues**: https://github.com/waltdundore/ahab/issues

---

## Acknowledgments

**Special thanks to [Kris Lamoureux](https://github.com/krislamo)** whose brilliant mind sparked the idea for this project. This wouldn't exist without that conversation.

---

## The Bottom Line

**We promise**: Working `docker-compose.yml` files for every service.

**We test**: Workstation → Raspberry Pi → Dev Server → Release.

**We document**: Successes and failures, openly.

**We deliver**: Simple commands that just work.

**Don't trust us. Verify us. Learn from us. Build with us.**

---

*Last updated: December 8, 2025*
