# Low-Hanging Fruit for New Users

![Ahab Logo](../docs/images/ahab-logo.png)

**Purpose**: Identify quick wins that would significantly improve the new user experience.

**Last Updated**: December 8, 2025

---

## Executive Summary

Based on analysis of our documentation, queue, and troubleshooting guides, here are the highest-impact improvements we can make for new users, organized by effort vs. impact.

---

## High Impact, Low Effort (Do These First)

### 1. Better Error Messages with Actionable Guidance

**Current State**: Error messages exist but could be more helpful  
**Impact**: Reduces frustration, speeds up problem resolution  
**Effort**: Low - improve existing error messages  
**Priority**: P2 (Medium)

**What to do**:
- Add "What to try next" to every error message
- Include relevant documentation links
- Show example commands that might fix the issue
- Add context about what the system was trying to do

**Example**:
```bash
# Current
Error: VM failed to start

# Better
Error: VM failed to start
This usually means virtualization is not enabled in your BIOS.

What to try:
1. Check if virtualization is enabled: sysctl -a | grep VMX
2. Enable VT-x in BIOS if disabled
3. See troubleshooting guide: https://...

Need help? Open an issue: https://github.com/waltdundore/ahab/issues
```

### 2. Interactive Setup Wizard

**Current State**: Users must know commands  
**Impact**: Dramatically lowers barrier to entry  
**Effort**: Medium - create menu-driven interface  
**Priority**: P3-002 (Low, but should be higher)

**What to do**:
- Create `make setup` command that launches interactive wizard
- Ask questions: "What services do you want to deploy?"
- Show checkboxes for modules
- Generate and explain the command that will run
- Confirm before executing

**Example**:
```bash
$ make setup

Welcome to Ahab Setup!

What would you like to deploy?
[ ] Apache Web Server
[ ] MySQL Database
[ ] PostgreSQL Database
[ ] Nginx Web Server
[ ] PHP Runtime

Use arrow keys to navigate, space to select, enter to continue.

You selected: Apache, MySQL

This will run: make install apache mysql

Continue? (y/n)
```

### 3. Pre-flight Checks

**Current State**: Installation fails if prerequisites missing  
**Impact**: Catches problems before they cause failures  
**Effort**: Low - add validation script  
**Priority**: P2 (Medium)

**What to do**:
- Create `make check` command
- Verify all prerequisites installed
- Check versions are compatible
- Test virtualization is enabled
- Report what's missing with installation instructions

**Example**:
```bash
$ make check

Checking prerequisites...
✓ Git installed (2.52.0)
✓ Vagrant installed (2.4.0)
✗ VirtualBox not found

To install VirtualBox:
  macOS: brew install --cask virtualbox
  Linux: sudo apt install virtualbox

Run 'make check' again after installing.
```

---

## High Impact, Medium Effort (Do These Next)

### 4. Web-Based Configuration Interface

**Current State**: Command-line only  
**Impact**: Opens Ahab to non-technical users  
**Effort**: High - full web application  
**Priority**: P3-004 (Low, but highest user demand)

**What to do**:
- Build web dashboard for service management
- Point-and-click module selection
- Visual service status monitoring
- Real-time log streaming
- Configuration editor with validation

**Why this matters**:
- School IT staff may not be comfortable with CLI
- Visual interface reduces learning curve
- Dashboard shows system health at a glance
- Makes Ahab accessible to more users

**Tracked in**: QUEUE.md P3-004

### 5. VS Code Extension

**Current State**: No IDE integration  
**Impact**: Improves developer experience  
**Effort**: Medium - VS Code extension development  
**Priority**: P3-004 (Low, but high developer demand)

**What to do**:
- Create VS Code extension for Ahab
- Module browser in sidebar
- One-click deployment
- Service status in status bar
- Integrated log viewer
- Docker Compose preview

**Why this matters**:
- Developers live in their IDE
- Reduces context switching
- Makes Ahab feel native to development workflow
- Lowers barrier for developer adoption

**Tracked in**: QUEUE.md P3-004

### 6. Video Tutorials

**Current State**: Text documentation only  
**Impact**: Helps visual learners  
**Effort**: Medium - record and edit videos  
**Priority**: P3 (Low)

**What to do**:
- Record 5-minute "Getting Started" video
- Show actual installation process
- Demonstrate deploying first service
- Troubleshoot common issues on camera
- Host on YouTube, embed on website

**Why this matters**:
- Some people learn better by watching
- Shows real-world usage
- Builds trust (transparency in action)
- Easy to share with teachers/students

---

## Medium Impact, Low Effort (Quick Wins)

### 7. More Example Modules

**Current State**: Apache is primary example  
**Impact**: Shows versatility of system  
**Effort**: Low - create module definitions  
**Priority**: P3-001 (Low)

**What to do**:
- Add MySQL module
- Add PostgreSQL module
- Add Nginx module
- Add PHP module
- Add Redis module

**Why this matters**:
- Demonstrates module system works for various services
- Gives users more options
- Shows Ahab isn't just for web servers
- Each module is a teaching opportunity

**Tracked in**: QUEUE.md P3-001

### 8. Classroom Lesson Plans

**Current State**: Educational alignment documented  
**Impact**: Makes Ahab classroom-ready  
**Effort**: Medium - create lesson plans  
**Priority**: P3 (Low, but aligns with mission)

**What to do**:
- Create 5 lesson plans for different skill levels
- Include learning objectives
- Provide assessment rubrics
- Add student project ideas
- Align with Georgia CS standards

**Example lessons**:
1. "Your First Web Server" (Beginner)
2. "Database-Backed Applications" (Intermediate)
3. "Multi-Service Architecture" (Advanced)
4. "Infrastructure as Code" (Advanced)
5. "DevOps Principles" (Advanced)

---

## Low Impact, High Effort (Defer These)

### 9. Raspberry Pi Support

**Current State**: Not tested on ARM  
**Impact**: Enables low-cost hardware  
**Effort**: Medium - testing and optimization  
**Priority**: P3 (Low)

**Why defer**: 
- Works on x86 already
- Raspberry Pi is nice-to-have
- Focus on core experience first
- Can add later without breaking changes

**Tracked in**: QUEUE.md P2-001

### 10. Multi-Language Support

**Current State**: English only  
**Impact**: Expands international reach  
**Effort**: High - translation and maintenance  
**Priority**: Not tracked

**Why defer**:
- English works for initial target market (US schools)
- Translation is expensive to maintain
- Focus on core functionality first
- Can add later with community help

---

## Recommendations

### Immediate Actions (Next Sprint)

1. **Improve error messages** - Low effort, high impact
2. **Add pre-flight checks** - Low effort, prevents frustration
3. **Create interactive setup wizard** - Medium effort, huge UX improvement

### Next Quarter

4. **Start web interface** - High effort, but highest user demand
5. **Create VS Code extension** - Medium effort, high developer demand
6. **Record video tutorials** - Medium effort, helps visual learners

### Ongoing

7. **Add more modules** - Low effort per module, shows versatility
8. **Develop lesson plans** - Aligns with educational mission

---

## How to Prioritize

Use this formula: **Impact × Ease / Effort = Priority Score**

| Feature | Impact (1-10) | Ease (1-10) | Effort (1-10) | Score |
|---------|---------------|-------------|---------------|-------|
| Better error messages | 9 | 9 | 2 | 40.5 |
| Pre-flight checks | 8 | 8 | 3 | 21.3 |
| Interactive wizard | 9 | 7 | 5 | 12.6 |
| Web interface | 10 | 5 | 9 | 5.6 |
| VS Code extension | 7 | 6 | 6 | 7.0 |
| Video tutorials | 6 | 7 | 5 | 8.4 |
| More modules | 5 | 8 | 2 | 20.0 |
| Lesson plans | 6 | 6 | 6 | 6.0 |
| Raspberry Pi | 4 | 4 | 7 | 2.3 |
| Multi-language | 3 | 3 | 9 | 1.0 |

**Top 5 by score**:
1. Better error messages (40.5)
2. Pre-flight checks (21.3)
3. More modules (20.0)
4. Interactive wizard (12.6)
5. Video tutorials (8.4)

---

## Success Metrics

How do we know these improvements are working?

### Quantitative
- Time to first successful deployment (target: < 15 minutes)
- Error rate during installation (target: < 10%)
- Support requests per user (target: < 0.5)
- GitHub issues opened (target: decreasing trend)

### Qualitative
- User feedback: "This was easy!"
- Teachers report successful classroom use
- Students complete projects independently
- Community contributions increase

---

## Related Documentation

- [QUEUE.md](../QUEUE.md) - Full development queue
- [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md) - Current troubleshooting guide
- [PRIORITIES.md](../../PRIORITIES.md) - Project priorities
- [ABOUT.md](../ABOUT.md) - Project mission and values

---

**Questions or suggestions?** Open an issue: https://github.com/waltdundore/ahab/issues
