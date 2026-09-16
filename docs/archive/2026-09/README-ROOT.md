<div align="center">

# Ahab

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

![Ahab Logo](https://raw.githubusercontent.com/waltdundore/ahab/prod/docs/images/ahab-logo.png)

**Infrastructure Automation for Schools and Non-Profits**

*Simple infrastructure automation for K-12 schools and non-profits.*  
*One command to set up workstations, deploy services, and manage your network.*

[![Tests](https://img.shields.io/badge/tests-failing-red)](ahab/TESTING.md)
[![License](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey)](LICENSE)
[![Status](https://img.shields.io/badge/status-critical--work--needed-red)](CHANGELOG.md)
[![GUI Available](https://img.shields.io/badge/GUI-available-blue)](https://github.com/waltdundore/ahab-gui)

</div>

---

**Our Commitment**: Every build produces a working `docker-compose.yml` file. This file is proof: proof that services deploy correctly, proof that tests pass, proof that we deliver what we promise.

**Our Mission**: Document what we know. Teach what we've learned. Pass it forward.

> *"We're not here forever, but what we teach can be."*

---

## ⚠️ Important Disclaimer

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

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

## 📋 Start Here

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**New to technical documentation?** → [Executive Summary](EXECUTIVE_SUMMARY.md) (for school leaders and decision makers)

**Ready to try it?** → Jump to [Quick Start](#quick-start)

**Want to understand it first?** → Keep reading

---

## What Is Ahab?

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

Ahab is infrastructure automation software designed specifically for schools and non-profits. It helps you:
- Deploy services (websites, databases, applications) with simple commands
- Manage lab computers and servers
- Control your own data instead of relying on cloud vendors
- Teach students real DevOps skills

### Two Ways to Use Ahab

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**1. [Ahab GUI](https://github.com/waltdundore/ahab-gui)** - Web Interface (Recommended for Students & Educators)
```bash
make ui    # Start the GUI

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
# Open http://localhost:5001 and click buttons

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```
- ✅ No command line required
- ✅ Visual feedback and progress
- ✅ Perfect for classroom teaching
- ✅ Built-in help and documentation

**2. Command Line Interface** - For Automation & Advanced Users
```bash
make install    # Set up infrastructure

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make test       # Verify it works

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make deploy     # Deploy services

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```
- ✅ Scriptable and automatable
- ✅ Full control and flexibility
- ✅ Perfect for production use

---

## 📁 Project Structure

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**What you need to know:**

```
ahab/
├── README.md              # ← Start here

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
├── Makefile               # ← All commands (make help)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
├── ahab.conf              # ← All configuration in one place

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│
├── ahab/       # Main working directory

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│   ├── playbooks/         # Automation scripts

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│   ├── roles/             # Reusable components

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│   ├── scripts/           # Helper utilities

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│   └── tests/             # All tests

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│
├── config/                # Configuration (consolidated from ansible-config)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
├── inventory/             # Server definitions (consolidated from ansible-inventory)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
│
└── docs/                  # All documentation

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
    ├── user/              # For users (installation, guides)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
    ├── developer/         # For developers (contributing, architecture)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
    └── architecture/      # Design decisions and deep dives

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```

**Quick Guide:**
- **New user?** Read this README, then run `make install`
- **School leader?** See [Executive Summary](docs/user/EXECUTIVE_SUMMARY.md)
- **Student?** Check out [Student Guide](docs/user/README-STUDENTS.md)
- **Developer?** Start with [Development Rules](docs/developer/DEVELOPMENT_RULES.md)
- **Need help?** Check [Troubleshooting](docs/user/TROUBLESHOOTING.md)
- **Configuring?** Edit `ahab.conf` (single source of truth)

---

## Why Ahab?

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### We Use What We Document

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

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

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
# Complex multi-step process with hidden dependencies

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```

**Ahab:**
```bash
# This is exactly what we use. This is what we test.

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make install apache
```

**When we say "it works," we mean "it's working for us right now."**

**See what we've learned**: [LESSONS_LEARNED.md](LESSONS_LEARNED.md) documents every issue we've found, how we fixed it, and what we learned. This is transparency in action.

### Core Principles

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

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

**Learn More**: [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)

### Your Data Stays Yours

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**Everything runs on your own local machine. Nothing is in the cloud.**

The software is particularly powerful because:
- ✅ **No cloud dependencies** - Your data never leaves your network
- ✅ **Complete privacy** - Nothing goes to us or any other company
- ✅ **100% open source** - Inspect every line of code
- ✅ **Standard Docker images** - You depend on official Docker repositories, not our servers
- ✅ **Full control** - You own the infrastructure, you control the data

**This isn't just about privacy—it's about sovereignty.** Schools and non-profits shouldn't have to send student data or organizational information to third-party clouds. With Ahab, your infrastructure is truly yours.

---

## Quick Start

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### Choose Your Interface

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**New to infrastructure automation?** → Use the GUI (recommended for students and educators)  
**Comfortable with command line?** → Use the CLI (recommended for automation and scripting)

---

### Option 1: Web Interface (Recommended for Beginners)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**[Ahab GUI](https://github.com/waltdundore/ahab-gui)** - Point-and-click infrastructure management

```bash
# Clone both repositories

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
git clone https://github.com/waltdundore/ahab.git
git clone https://github.com/waltdundore/ahab-gui.git

# Start the GUI

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
cd ahab
make ui

# Open your browser to http://localhost:5001

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```

**What you get:**
- ✅ Visual interface - no command line required
- ✅ One-click workstation creation
- ✅ Real-time progress and status
- ✅ Built-in help and documentation
- ✅ Perfect for classroom demonstrations

**See the [Ahab GUI Demo](https://github.com/waltdundore/ahab-gui/blob/main/DEMO.md)** for screenshots, walkthroughs, and classroom scenarios.

---

### Option 2: Command Line Interface

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**For automation, scripting, and advanced users**

```bash
# Clone the repository

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
git clone https://github.com/waltdundore/ahab.git
cd ahab
git submodule update --init --recursive  # Clones ahab-modules

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

# Configuration and inventory are now inside ahab/

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
# No need to clone separate repositories!

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

# Install and deploy

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make install         # Creates workstation VM (fixes permissions automatically)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make verify-install  # Verify everything works

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make test            # Run full test suite

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```

That's it. Three commands: install, verify, test.

**Test Status**: Every `make test` records status in `.test-status`. Only passing versions are promotable to production.

---

### Which Should I Use?

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

| Use GUI If... | Use CLI If... |
|---------------|---------------|
| You're new to infrastructure automation | You're comfortable with command line |
| You're teaching students | You're writing automation scripts |
| You want visual feedback | You want maximum control |
| You prefer point-and-click | You prefer typing commands |
| You're doing classroom demos | You're doing production deployments |

**Good news**: You can use both! The GUI executes the same `make` commands as the CLI. Learn with the GUI, automate with the CLI.

---

## Architecture

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

Ahab is a family of related projects:

### Core Infrastructure

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- **ahab** (this repo): Core automation engine with configuration and inventory
- **ahab-modules**: Reusable service modules (Apache, MySQL, etc.)

### User Interfaces

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- **[ahab-gui](https://github.com/waltdundore/ahab-gui)**: Web interface - executes `make` commands visually
- **alpha-gui** (planned): Next-level interface built on ahab

### Documentation

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- **[waltdundore.github.io](https://github.com/waltdundore/waltdundore.github.io)**: Project website

**How They Connect**: All interfaces execute the same `make` commands. The GUI doesn't replace the CLI - it wraps it with a visual layer.

**Docker Compose First**: Every build produces a working `docker-compose.yml` file as proof that services deploy correctly.

**Learn more**: See [ABOUT.md](ABOUT.md) for complete architecture details.

---

## Essential Commands

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

```bash
# Getting Started

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make install              # Create workstation VM

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make verify-install       # Verify installation

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make test                 # Run test suite

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

# Common Tasks

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make ssh                  # SSH into workstation

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make status               # Show system status

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make clean                # Destroy VM

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

# Help

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
make help                 # Show all available commands

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
```

**See all commands**: Run `make help` for the complete list including deployment, testing, and audit commands.

---

## Configuration

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**Single Source of Truth**: Edit `ahab.conf` to configure OS versions, VM resources, network settings, and more.

**Secrets Management**: All sensitive data must be encrypted with Ansible Vault before committing to Git.

**Learn more**: See [Development Rules](docs/developer/DEVELOPMENT_RULES.md) for configuration details and security practices.

---

## Testing

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

We don't release until tests pass. Our pipeline: Workstation → Raspberry Pi → Dev Server → Release.

**Test Status**: Every `make test` records status in `.test-status`. Only passing versions are promotable to production.

**Learn more**: See [Testing Guide](docs/user/TESTING.md) for our complete testing pipeline and quality gates.

---

## Current Status

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### ✅ What Works

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- Four-repository architecture
- Bootstrap script clones all repos
- Symlinks created automatically
- Module system designed

### 🔄 In Progress

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- Workstation bootstrap test (critical milestone)
- Docker Compose generation script
- Apache module deployment
- Testing framework

### ⚠️ Not Ready Yet

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- No security audit
- Limited module library
- Experimental status
- Documentation consolidation in progress

**Transparency**: We're building this openly. We document failures as well as successes. See [LESSONS_LEARNED.md](LESSONS_LEARNED.md).

---

## Who This Is For

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### K-12 Schools

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- Manage lab computers
- Host student projects
- Control your data
- Teach real DevOps
- Free forever
- **Use [Ahab GUI](https://github.com/waltdundore/ahab-gui)** for classroom teaching

### Non-Profits

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- Self-host services
- Reduce cloud costs
- Maintain privacy
- No vendor lock-in
- **Use CLI** for production automation

### Students

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- Learn by doing
- Real-world tools
- Safe to experiment
- Build portfolio projects
- **Start with [Ahab GUI](https://github.com/waltdundore/ahab-gui)** for visual learning

---

## Documentation

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### 📚 Three Teaching Tools, Three Purposes

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

Ahab includes three distinct teaching tools, each designed for different learning contexts:

**🌐 [Project Website](https://waltdundore.github.io)** - *Discovery & Conceptual Learning*
- Learn infrastructure automation concepts
- Explore educational resources and tutorials  
- Teacher guides and curriculum alignment
- **Perfect for**: First-time visitors, educators planning curriculum, conceptual learning

**📖 This README** - *Technical Implementation*
- Installation and setup instructions
- Command reference and architecture
- Development guidelines and contribution guide
- **Perfect for**: Developers, system administrators, technical implementation

**🖥️ [Ahab GUI](https://github.com/waltdundore/ahab-gui)** - *Interactive Learning*
- Point-and-click interface with visual feedback
- Built-in help and contextual guidance
- Safe environment for hands-on experimentation
- **Perfect for**: Students, educators, classroom demonstrations, visual learners

**📋 [Complete Teaching Tools Guide](TEACHING_TOOLS_OVERVIEW.md)** - Detailed comparison and usage guide

---

### Main Project Documentation (Technical)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

All technical documentation is organized in the `docs/` directory by audience:

- **School Leaders**: [Executive Summary](docs/user/EXECUTIVE_SUMMARY.md) - Non-technical overview
- **Students**: [Student Guide](docs/user/README-STUDENTS.md) - CS standards, tutorials, projects
- **Users**: [Start Here](docs/user/START_HERE.md) - Installation and common tasks
- **Developers**: [Development Rules](docs/developer/DEVELOPMENT_RULES.md) - Contributing guide

**Additional Resources**:
- [ABOUT.md](ABOUT.md) - Mission, vision, and release process
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [LESSONS_LEARNED.md](LESSONS_LEARNED.md) - What we've learned from real use
- [docs/INDEX.md](docs/INDEX.md) - Complete documentation index

### Web Interface Documentation (Interactive)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**Repository**: https://github.com/waltdundore/ahab-gui

- **[Demo Guide](https://github.com/waltdundore/ahab-gui/blob/main/DEMO.md)** - Complete walkthrough with screenshots and classroom scenarios
- **[README](https://github.com/waltdundore/ahab-gui/blob/main/README.md)** - Quick start and features
- **[Branding Guidelines](https://github.com/waltdundore/ahab-gui/blob/main/BRANDING.md)** - Design system and accessibility
- **[Security Model](https://github.com/waltdundore/ahab-gui/blob/main/SECURITY.md)** - How the GUI stays secure

---

## Roadmap

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

### Now (Critical Milestone)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- [ ] Workstation bootstrap test must pass
- [ ] Docker Compose generation working
- [ ] Apache deployment tested
- [ ] Documentation consolidated

### Next (After Milestone)

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- [ ] Raspberry Pi testing
- [ ] Dev server deployment
- [ ] Release creation process
- [ ] More modules (MySQL, Nginx, PostgreSQL)

### Future

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)
- [ ] Menu-driven interface
- [ ] Service marketplace
- [ ] Community modules
- [ ] Monitoring and alerts

---

## How to Help

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

1. **Test it** - Try `make install`, report issues
2. **Contribute** - Add modules, fix bugs
3. **Feedback** - Tell us what works and what doesn't
4. **Security** - Help with security review
5. **Spread the word** - Help schools and non-profits discover this

---

## License

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

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

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

⚠️ **Experimental / Educational** - Not production-ready. Needs security audit before production use.

**Philosophy**: Don't trust code you don't understand. Look it up. Research it. Learn how it works. That's the point here.

---

## Contact

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

- **GitHub**: https://github.com/waltdundore/ahab
- **Issues**: https://github.com/waltdundore/ahab/issues

---

## Acknowledgments

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**Special thanks to [Kris Lamoureux](https://github.com/krislamo)** whose brilliant mind sparked the idea for this project. This wouldn't exist without that conversation.

---

## The Bottom Line

[![Sprint](https://img.shields.io/badge/sprint-3%20active-blue)](QUEUE.md#current-sprint)

[![Issues](https://img.shields.io/badge/issues-23%20open-red)](https://github.com/waltdundore/ahab/issues)

[![Milestones](https://img.shields.io/badge/milestones-0%2F20%20(0%25)-red)](PRIORITIES.md)

**We promise**: Working `docker-compose.yml` files for every service.

**We test**: Workstation → Raspberry Pi → Dev Server → Release.

**We document**: Successes and failures, openly.

**We deliver**: Simple commands that just work.

**Don't trust us. Verify us. Learn from us. Build with us.**

---

*Last updated: December 8, 2025*
