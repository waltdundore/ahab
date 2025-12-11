# 👋 Welcome to Ahab!

![Ahab Logo](docs/images/ahab-logo.png)

**New here? You're in the right place.**

---

## 🚀 Quick Start (3 Commands)

```bash
make install         # Create workstation VM
make test            # Verify everything works
make install apache  # Deploy Apache web server
```

That's it! Three commands to get started.

---

## 📚 What Should I Read?

### I'm a School Leader / Decision Maker
→ Read **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** first  
Plain English explanation of what Ahab is and why it matters for schools.

### I'm a Teacher / IT Coordinator
→ Read **[README.md](README.md)** first  
Technical overview with examples and commands.

### I'm a Student
→ Read **[README.md](README.md)** first  
Learn real DevOps tools used by companies like Netflix and Spotify.

### I'm a Developer / Contributor
→ Read **[DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)** first  
Core principles, NASA standards, and contribution guidelines.

---

## 📁 What's in This Directory?

See [Repository Structure](README.md#repository-structure) in README.md for complete details.

**Key Files**:
```
📄 START_HERE.md          ← You are here!
📄 README.md              ← Main documentation
📄 EXECUTIVE_SUMMARY.md   ← For school leaders
📄 ABOUT.md               ← Project mission

🔧 Makefile               ← All commands (make help)
📁 playbooks/             ← Ansible automation
📁 modules/               ← Service definitions
📁 tests/                 ← Test suite
```

For complete structure with all directories, see [README.md](README.md#repository-structure).

---

## 🎯 Quick Start

See [Quick Start](README.md#quick-start) in README.md for complete commands.

**Most Common**:
```bash
make install              # Create workstation
make install apache       # Workstation + web server
make test                 # Run tests
make install php         # PHP runtime
```

### Run Tests
```bash
make test                # Quick tests (no VM needed)
make test-integration    # Full tests (requires VM)
```

### Get Help
```bash
make help                # Show all commands
```

### SSH into Workstation
```bash
make ssh
```

### Clean Up
```bash
make clean               # Destroy VM
```

---

## ❓ Common Questions

### Is this production-ready?
No, this is **alpha software** for homelab and testing. We're building toward production use in schools, but we're not there yet. We're transparent about this.

### Do I need to know Linux?
Basic Linux knowledge helps, but our documentation teaches as it goes. If you can follow instructions and aren't afraid to learn, you'll be fine.

### What if something breaks?
1. Check **[TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** for common issues
2. Run `make test` to see what's wrong
3. Open an issue on GitHub with the error message

### Can I use this for my school?
Yes! It's free for schools and non-profits (CC BY-NC-SA 4.0 license). Commercial use requires negotiation.

### How do I contribute?
1. Read **[DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)**
2. Pick an issue from **[QUEUE.md](QUEUE.md)**
3. Follow the rules (NASA standards, make commands, test immediately)
4. Submit a pull request

---

## 🎓 Learning Resources

### For Students
- Learn Ansible: https://docs.ansible.com/
- Learn Docker: https://docs.docker.com/
- Learn Linux: https://linuxjourney.com/
- Learn Git: https://git-scm.com/book/en/v2

### For Teachers
- CS Standards covered: CSTA, AP Computer Science Principles
- Real-world tools: Same as Netflix, Spotify, NASA
- Project ideas: See **[QUEUE.md](QUEUE.md)** for contribution opportunities

---

## 🤝 Our Principles

1. **Student Achievement First** - Everything serves student learning
2. **Bug-Free Software** - Quality before features
3. **Radical Transparency** - We document failures and successes
4. **We Use What We Document** - Same commands, same tools
5. **Teaching Mindset** - Every line of code teaches

Read more: **[ABOUT.md](ABOUT.md)**

---

## 🚦 Project Status

**Current Version:** 0.1.1 (Alpha)  
**Tests:** ✅ Passing  
**Ready for:** Homelab testing, learning, experimentation  
**Not ready for:** Production use in schools (yet)

See **[CHANGELOG.md](CHANGELOG.md)** for version history.

---

## 📞 Get Help

- **Documentation:** You're reading it!
- **Issues:** https://github.com/waltdundore/ahab/issues
- **Discussions:** https://github.com/waltdundore/ahab/discussions

---

## 🎉 Ready to Start?

```bash
# Clone the repository
git clone git@github.com:waltdundore/ahab.git
cd ahab

# Install and test
make install
make test

# Deploy something
make install apache

# Visit http://localhost in your browser
# You should see the Ahab welcome page!
```

**Welcome aboard! 🚢**

---

*Questions? Read [README.md](README.md) for detailed documentation.*
