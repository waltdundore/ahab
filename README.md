<div align="center">

# Ahab

![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ahab/prod/docs/images/ahab-logo.png)

**Automated Host Administration & Build**

*Simple infrastructure automation for K-12 schools and non-profits.*  
*One command to set up workstations, deploy services, and manage your network.*

[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](TESTING.md)
[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey)](LICENSE)
[![Status](https://img.shields.io/badge/status-alpha-orange)](RELEASE_NOTES_v0.1.1.md)

**📊 [Live Project Status](https://waltdundore.github.io/status.html) | 🎓 [Learn More](https://waltdundore.github.io)**

</div>

---

## ⚠️ Important Disclaimer

**This project is AI-assisted and actively developed.** If you deploy this to production without reading and understanding the code, that's on you. We're building this to be production-ready, but we're not there yet.

**What you should know:**
- This code is built using AI assistance and follows industry best practices
- It's vetted and backed by the creator of /r/k12sysadmin on Reddit
- We use it in our own environment and test everything we document
- We're gaining confidence in it, but it needs security review before production use
- This is another tool built specifically for K-12 school systems

**Our philosophy**: If this works great for our team, we hope your team can benefit too. But don't trust code you don't understand—read it, test it, learn from it. That's the whole point.

**Bottom line**: Experimental status. Educational focus. Production aspirations. Your responsibility to verify.

---

## Quick Start

### Option 1: Web Interface (Recommended)

**[Ahab GUI](https://github.com/waltdundore/ahab-gui)** - Simple web interface for managing Ahab

```bash
# Start the GUI
make ui

# Open browser to http://localhost:5001
```

The GUI provides:
- ✅ One-click workstation creation
- ✅ Visual service deployment
- ✅ Real-time status monitoring
- ✅ Built-in help and documentation

**Perfect for:** Students, educators, and anyone who prefers a visual interface.

### Option 2: Command Line

```bash
# Install and start workstation VM
make install

# Install workstation + deploy Apache
make install apache

# Install workstation + deploy multiple services
make install apache mysql

# Run tests
make test

# SSH into workstation
make ssh

# Clean up
make clean
```

**Perfect for:** Automation, scripting, and advanced users.

## What This Does

Ahab creates a fully-configured Fedora workstation VM with:
- Git, Ansible, Docker pre-installed
- Ready to deploy services via Docker Compose
- Module system for easy service deployment
- Security standards compliance

**Prerequisites:** Vagrant and VirtualBox (Docker runs inside the VM, not on your host)

## Available Commands

```bash
make help                 # Show all commands
make install              # Create workstation VM
make install apache       # Workstation + Apache
make verify-install       # Verify installation
make test                 # Run test suite
make ssh                  # SSH into workstation
make clean                # Destroy VM
make audit                # Run accountability audit
```

## Educational Standards Alignment

**Ahab is aligned with Georgia Computer Science Standards.**

Ahab teaches real-world infrastructure automation skills that align with state educational requirements, making it suitable for K-12 classroom use.

### Standards Coverage

Ahab addresses standards across multiple Georgia CS courses:

- **IT-CSP** (Computer Science Principles): Algorithm development, abstraction, Internet operation
- **IT-NSS** (Network Systems and Services): Network installation, security, administration
- **IT-ITS** (IT Support Specialist): System configuration, security implementation, troubleshooting
- **IT-PGAS** (Programming, Games, Apps, and Society): Software lifecycle, design standards

### Key Alignments

| Ahab Feature | Georgia Standards | What Students Learn |
|--------------|-------------------|---------------------|
| Make Commands & Ansible | IT-NSS-10, IT-NSS-11, IT-ITS-3 | Network operation, system administration, automation |
| Docker Compose | IT-CSP-3, IT-CSP-6, IT-PGAS-2 | Abstraction, software lifecycle, system design |
| Apache Deployment | IT-NSS-2, IT-NSS-7, IT-ITS-4, IT-ITS-5 | Network services, security principles, configuration |
| Testing & Validation | IT-NSS-8, IT-NSS-10, IT-ITS-1.3 | Troubleshooting, diagnostics, critical thinking |

### Documentation

- **[standards-registry.yml](standards-registry.yml)** - Complete Georgia CS standards reference
- **[feature-standards-map.yml](feature-standards-map.yml)** - Detailed feature-to-standards mappings with learning objectives and classroom activities
- **[GEORGIA_STANDARDS_VERIFICATION.md](GEORGIA_STANDARDS_VERIFICATION.md)** - Standards verification and proof-of-concept mappings

**Official Source**: [Georgia Standards of Excellence - Computer Science](https://case.georgiastandards.org/00fcf0e2-b9c3-11e7-a4ad-47f36833e889/a4aeca3a-1532-11eb-b674-0242ac150004/591)

### For Educators

Ahab provides:
- Standards-aligned learning objectives for each feature
- Suggested classroom activities with assessment criteria
- Prerequisite knowledge requirements
- Grade-level recommendations (typically 10-12)

See [feature-standards-map.yml](feature-standards-map.yml) for complete educational context.

---

## Module System

Deploy services by name:

```bash
make install apache       # Web server
make install mysql        # Database
make install php          # PHP runtime
```

Modules are self-documenting with `module.yml` files that define:
- Multi-platform support (Fedora, Debian, Ubuntu)
- Dual deployment (Ansible + Docker)
- Dependencies and configuration
- Version tracking

**Important:** Modules live in separate repositories, not in this project. See [MODULE_ARCHITECTURE.md](docs/MODULE_ARCHITECTURE.md) for details.

## Architecture

```
Host Machine (Mac/Linux/Windows)
  └─ Vagrant
      └─ Fedora Workstation VM
          ├─ Git, Ansible, Docker
          └─ Docker Compose
              └─ Services (Apache, MySQL, etc.)
```

## Repository Structure

**What you need to know:**

```
ahab/
├── 📄 README.md              ← You are here (start here!)
├── 📄 ABOUT.md               ← Project mission and philosophy
├── 📄 DEVELOPMENT_RULES.md   ← For developers
├── 📄 EXECUTIVE_SUMMARY.md   ← For school leaders
├── 📄 TESTING.md             ← Testing guide
│
├── 🔧 Makefile               ← All commands (make help)
├── 🔧 Vagrantfile            ← VM configuration
├── 📋 MODULE_REGISTRY.yml    ← Module registry (external repos)
├── 📋 standards-registry.yml ← Educational standards alignment
├── 📋 feature-standards-map.yml ← Feature-to-standards mappings
│
├── 📁 playbooks/             ← Ansible playbooks
├── 📁 roles/                 ← Ansible roles
├── 📁 scripts/               ← Helper scripts
├── 📁 tests/                 ← Test suite
├── 📁 inventory/             ← Environment definitions
├── 📁 config/                ← Configuration files
│
└── 📁 docs/                  ← Additional documentation
    ├── MODULE_ARCHITECTURE.md  ← Module system explained
    └── development/          ← Developer docs
```

**Note:** Modules live in separate repositories (see [MODULE_ARCHITECTURE.md](docs/MODULE_ARCHITECTURE.md))

**New users:** Read README.md (this file), then try `make install`  
**School leaders:** Read EXECUTIVE_SUMMARY.md first  
**Developers:** Read DEVELOPMENT_RULES.md before contributing

## Testing

```bash
make test                    # Run all tests (no VM required)
make test-integration        # Full integration tests (requires VM)
make test-e2e                # End-to-end tests
make validate-tests          # Validate test scripts
```

## Documentation Generation

Ahab includes an automated system for documenting all open-source components used in the project.

### Installing Documentation Dependencies

```bash
# Install Python dependencies for documentation generation
pip install -r requirements-docs.txt
```

The documentation system requires:
- **requests** - For fetching metadata from PyPI and GitHub APIs
- **packaging** - For parsing requirements.txt files
- **Jinja2** - For generating markdown and HTML documentation
- **PyYAML** - For reading component metadata files

### Generating Component Documentation

```bash
make docs-components-discover   # Discover all components from requirements files
make docs-components-generate   # Generate documentation
make docs-components-validate   # Validate completeness
make docs-components-update     # Full update cycle (discover + generate + validate)
```

See the generated `OPEN_SOURCE_COMPONENTS.md` for a complete list of all open-source components used in Ahab.

## Core Principles

See [Core Principles](DEVELOPMENT_RULES.md#core-principles) for our complete guiding principles.

**Quick Summary**:
1. Eat Your Own Dog Food - Use `make` commands
2. Modular and Simple - `make install` just works
3. Safety-Critical Standards - Security standards compliance
4. Never Assume Success - Verify every operation
5. Container-First - Always use containers
6. Docker Compose First - Every build produces docker-compose.yml
7. Radical Transparency - Document failures and successes
8. Kiro Reviews Everything - AI reviews before refactoring
9. Single Source of Truth (DRY) - Data lives in ONE place only
10. Teaching Mindset - Code teaches those who come after
11. Documentation as Education - We use what we document

For full explanations and examples, see [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md#core-principles).

## Development

See [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md) for:
- Security standards compliance
- Development workflow
- Testing requirements
- Contribution guidelines

## Documentation

### 📚 Start Here

**New to Ahab?** Read these in order:

1. **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** - For school leaders and decision makers
   - Written in plain English, no technical jargon
   - What is Ahab? Why does it matter? Is it right for your school?
   - Cost savings, data ownership, student learning benefits

2. **[README.md](README.md)** - You are here
   - Quick start guide
   - Basic commands and concepts
   - What Ahab does and how it works

3. **[ABOUT.md](ABOUT.md)** - Project mission and philosophy
   - Why we built this
   - Our core principles and values
   - Release process and accountability

### 🔧 Using Ahab

4. **[docs/MODULE_ARCHITECTURE.md](docs/MODULE_ARCHITECTURE.md)** - Module system architecture
   - Where modules live (separate repositories, NOT in ahab)
   - How to create and update modules
   - Common mistakes to avoid
   - **READ THIS if working with modules**

5. **[TESTING.md](TESTING.md)** - How to run tests
   - Test philosophy (empathy first, self-healing, idempotent)
   - Running tests: `make test`, `make test-integration`, `make test-e2e`
   - Writing new tests

6. **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** - When things go wrong
   - Common issues and solutions
   - VM won't start? Docker issues? Port conflicts?
   - Helpful error messages with next steps

### 👨‍💻 Developing Ahab

7. **[DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)** - MANDATORY reading for developers
   - ABSOLUTE RULE #0: Develop on workstation, not virtually
   - Security standards compliance
   - Make commands only (eat your own dog food)
   - Testing requirements

8. **[docs/development/PARNAS_PRINCIPLE_GUIDE.md](docs/development/PARNAS_PRINCIPLE_GUIDE.md)** - Parnas's Information Hiding Principle
   - What is Parnas's principle and why it matters
   - How Ahab implements it (MODULE_REGISTRY.yml, ahab.conf)
   - Understanding the property test
   - How to fix violations with step-by-step examples
   - **READ THIS if the Parnas test fails**

9. **[BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md)** - Git workflow
   - dev → prod (one direction only, never backwards)
   - How to avoid losing commits
   - Pre-promotion checklist

10. **[LESSONS_LEARNED.md](LESSONS_LEARNED.md)** - What we've learned
    - Mistakes we made and how we fixed them
    - Transparency in action
    - Learn from our experience

### 📋 Reference

11. **[CHANGELOG.md](CHANGELOG.md)** - Version history
    - What changed in each release
    - Bug fixes, new features, breaking changes

12. **[RELEASE_NOTES_v0.1.1.md](docs/RELEASE_NOTES_v0.1.1.md)** - Current release details
    - Critical bug fixes (vagrant timeout protection)
    - What we fixed and why
    - Known issues and alpha status

13. **[SPECIFICATIONS.md](../SPECIFICATIONS.md)** - Technical specifications
    - Requirements and design decisions
    - Architecture details
    - Module system specifications

### 🎯 For Students

13. **[README-STUDENTS.md](../README-STUDENTS.md)** - Student-focused guide
    - Learn real-world infrastructure skills
    - Same tools used by Netflix, Spotify, and thousands of companies
    - Hands-on learning with actual production tools

### 📊 Project Management

14. **[PRIORITIES.md](../PRIORITIES.md)** - Our guiding priorities
    - Student Achievement First
    - Bug-Free Software
    - Marketing What We Do

15. **[QUEUE.md](QUEUE.md)** - What we're working on
    - Current tasks and priorities
    - Roadmap and future plans

## License

MIT License - See LICENSE file for details

## Related Projects

### [Ahab GUI](https://github.com/waltdundore/ahab-gui)

**Simple web interface for Ahab infrastructure automation.**

Perfect for students and educators who prefer a visual interface over command-line tools. Features:
- One-click workstation creation
- Visual service deployment
- Real-time status monitoring
- Progressive disclosure UX (shows only what's relevant)
- Built-in help and documentation

```bash
# Start the GUI from ahab directory
make ui
```

See the [Ahab GUI repository](https://github.com/waltdundore/ahab-gui) for details.

## Support

- Issues: https://github.com/waltdundore/ahab/issues
- Discussions: https://github.com/waltdundore/ahab/discussions
- GUI Issues: https://github.com/waltdundore/ahab-gui/issues
