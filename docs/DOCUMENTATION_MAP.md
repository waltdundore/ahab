# Documentation Map

![Ahab Logo](docs/images/ahab-logo.png)

**Purpose**: Know which file is authoritative for what content  
**Last Updated**: December 8, 2025

---

## The Problem

When you need to update content, which file do you update? If you update the wrong file, you create inconsistency. This map tells you which file is the **single source of truth** for each type of content.

---

## Authoritative Sources

### Core Content

| Content Type | Authoritative Source | Who Links To It |
|-------------|---------------------|-----------------|
| **Core Principles** | DEVELOPMENT_RULES.md | README.md, ABOUT.md, PRIORITIES.md |
| **Quick Start Commands** | README.md | START_HERE.md, README-STUDENTS.md, DEVELOPMENT_RULES.md |
| **Repository Structure** | README.md | START_HERE.md, ABOUT.md |
| **Module Architecture** | docs/MODULE_ARCHITECTURE.md | README.md, DEVELOPMENT_RULES.md |
| **Mission & Vision** | ABOUT.md | README.md, EXECUTIVE_SUMMARY.md |
| **Release Process** | ABOUT.md | DEVELOPMENT_RULES.md, QUEUE.md |
| **Testing Guidelines** | TESTING.md | DEVELOPMENT_RULES.md, README.md |
| **NASA Standards** | DEVELOPMENT_RULES.md | All code files (comments) |
| **Configuration** | ahab.conf | Vagrantfile, Makefile, scripts |

### Development Content

| Content Type | Authoritative Source | Who Links To It |
|-------------|---------------------|-----------------|
| **Development Rules** | DEVELOPMENT_RULES.md | README.md, ABOUT.md, QUEUE.md |
| **Work Queue** | QUEUE.md | PRIORITIES.md, DEVELOPMENT_RULES.md |
| **Priorities** | PRIORITIES.md | QUEUE.md, README.md |
| **Improvements** | IMPROVEMENTS.md | WORKFLOW_IMPROVEMENT.md |
| **Changelog** | CHANGELOG.md | README.md, release notes |

### User Content

| Content Type | Authoritative Source | Who Links To It |
|-------------|---------------------|-----------------|
| **Getting Started** | START_HERE.md | README.md (for new users) |
| **Technical Overview** | README.md | All other docs |
| **Executive Summary** | EXECUTIVE_SUMMARY.md | README.md, ABOUT.md |
| **Student Guide** | README-STUDENTS.md | README.md |
| **Troubleshooting** | TROUBLESHOOTING.md | README.md, error messages |

---

## When to Duplicate vs Link

### ✅ When Duplication is OK

1. **Different Audiences**
   - Technical vs non-technical
   - Beginner vs advanced
   - Different language/tone needed
   - **Example**: EXECUTIVE_SUMMARY.md vs README.md

2. **Different Entry Points**
   - START_HERE.md for absolute beginners
   - README.md for users
   - DEVELOPMENT_RULES.md for developers
   - **Example**: Simplified Quick Start in START_HERE.md

3. **Historical Archives**
   - docs/archive/* should not be updated
   - Snapshots of past state
   - **Example**: Old README versions in archive

4. **Context-Specific Examples**
   - Role-specific examples in role README
   - Module-specific examples in module docs
   - **Example**: Apache role README with Apache-specific commands

### ❌ When to Link (Required)

1. **Same Audience**
   - Technical content for developers
   - Should link, not duplicate
   - **Example**: Core Principles in README.md → link to DEVELOPMENT_RULES.md

2. **Detailed Explanations**
   - Brief summary OK
   - Full explanation = link
   - **Example**: Quick Start summary → link to full Quick Start

3. **Lists/Tables**
   - Core Principles
   - Commands
   - File structures
   - **Example**: Repository Structure → link to README.md

4. **Configuration Values**
   - NEVER duplicate config
   - Always read from ahab.conf
   - **Example**: Package lists, versions, settings

---

## Linking Template

When linking to authoritative content, use this pattern:

```markdown
## [Topic]

See [Topic](path/to/file.md#section) for complete details.

**Quick Summary**: [1-2 sentences]

**Key Points**:
- Point 1
- Point 2
- Point 3

For full details, see [Authoritative Source](link).
```

**Example**:

```markdown
## Core Principles

See [Core Principles](DEVELOPMENT_RULES.md#core-principles) for complete details.

**Quick Summary**: We follow 11 core principles from "Eat Your Own Dog Food" to "Documentation as Education".

**Key Highlights**:
- Use make commands (not direct tools)
- NASA Power of 10 standards (mandatory)
- Single Source of Truth (DRY)

For full explanations and examples, see [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md#core-principles).
```

---

## Update Workflows

### When Philosophy Changes (ABOUT.md)

**Flow**: ABOUT.md → DEVELOPMENT_RULES.md → SPECIFICATIONS.md → Code

**Steps**:
1. Update ABOUT.md (mission, vision, principles)
2. Update DEVELOPMENT_RULES.md (align Core Principles)
3. Update SPECIFICATIONS.md (requirements serve mission)
4. Update code (implement new principles)
5. Update CHANGELOG.md

**Rule**: Philosophy changes flow DOWN. Never let code changes drive philosophy.

### When Adding New Feature

**Flow**: SPECIFICATIONS.md → Code → QUEUE.md → CHANGELOG.md

**Steps**:
1. Update SPECIFICATIONS.md (requirements and design)
2. Write code (implement feature)
3. Update QUEUE.md (mark task complete)
4. Update CHANGELOG.md (document change)
5. Update README.md if user-facing

### When Changing Commands

**Flow**: Makefile → README.md → All docs that link

**Steps**:
1. Update Makefile (change command)
2. Update README.md Quick Start (authoritative)
3. All other docs automatically current (they link to README.md)
4. Update CHANGELOG.md

**This is why linking matters**: Change once, applies everywhere.

### When Updating Configuration

**Flow**: ahab.conf → All files that read it

**Steps**:
1. Update ahab.conf (single source of truth)
2. All files automatically current (they read from ahab.conf)
3. Update CHANGELOG.md

**Never**: Hardcode values that should be in ahab.conf

---

## Consistency Checks

### Daily (Before Committing)

- [ ] Run `make test` (catches broken links, syntax errors)
- [ ] Check CHANGELOG.md updated
- [ ] Verify no hardcoded values (should be in ahab.conf)

### Weekly (Monday Morning)

- [ ] Review QUEUE.md vs actual work
- [ ] Update PRIORITIES.md if priorities changed
- [ ] Check for documentation drift (grep for duplicates)

### Monthly (First of Month)

- [ ] Full documentation audit (`make audit-docs`)
- [ ] Check all links work
- [ ] Verify authoritative sources still correct
- [ ] Update this map if structure changed

### Per Release

- [ ] Verify CHANGELOG.md complete
- [ ] Check README.md reflects current state
- [ ] Verify all commands tested and work
- [ ] Update version numbers in all docs

---

## Common Mistakes

### ❌ Mistake 1: Updating Non-Authoritative File

**Wrong**:
```
Update Core Principles in README.md
→ DEVELOPMENT_RULES.md now out of sync
→ Inconsistency
```

**Right**:
```
Update Core Principles in DEVELOPMENT_RULES.md
→ README.md links to it
→ Automatically consistent
```

### ❌ Mistake 2: Duplicating Instead of Linking

**Wrong**:
```markdown
## Quick Start

```bash
make install
make install apache
make test
```
```

**Right**:
```markdown
## Quick Start

See [Quick Start](README.md#quick-start) for complete commands.

**Most Common**: `make install`, `make install apache`, `make test`
```

### ❌ Mistake 3: Hardcoding Configuration

**Wrong**:
```bash
FEDORA_VERSION="40"  # Hardcoded in script
```

**Right**:
```bash
source ahab.conf
# FEDORA_VERSION now from config
```

### ❌ Mistake 4: Forgetting to Update CHANGELOG

**Wrong**:
```
Make changes → Commit → Push
→ No record of what changed
```

**Right**:
```
Make changes → Update CHANGELOG.md → Commit → Push
→ Clear record of changes
```

---

## Emergency: Documents Out of Sync

### Symptoms

- Same content in multiple files with different values
- Links broken
- Commands don't match Makefile
- Configuration duplicated

### Fix Process

1. **Identify authoritative source** (use this map)
2. **Update authoritative source** (make it correct)
3. **Update all links** (point to authoritative source)
4. **Remove duplicates** (replace with links)
5. **Test** (`make test`)
6. **Document** (CHANGELOG.md)

### Prevention

- Check this map before updating
- Use links instead of duplicates
- Run `make test` before committing
- Weekly consistency checks

---

## File Hierarchy

**Foundation** (changes rarely, affects everything):
```
ABOUT.md (Philosophy)
  ↓
DEVELOPMENT_RULES.md (How we code)
  ↓
SPECIFICATIONS.md (What we build)
  ↓
Code (Implementation)
```

**User-Facing** (changes frequently):
```
README.md (Main entry point)
  ↓
START_HERE.md (Beginner entry)
EXECUTIVE_SUMMARY.md (Leader entry)
README-STUDENTS.md (Student entry)
```

**Development** (changes constantly):
```
QUEUE.md (What we're doing)
  ↓
PRIORITIES.md (What's important)
  ↓
IMPROVEMENTS.md (What could be better)
  ↓
CHANGELOG.md (What we did)
```

---

## Quick Reference

**Before updating any file, ask**:

1. Is this file the authoritative source? (Check this map)
2. If yes → Update it
3. If no → Update the authoritative source instead
4. Update CHANGELOG.md
5. Run `make test`

**Golden Rule**: One source of truth per content type. Everything else links to it.

---

*This map prevents documentation drift and ensures consistency.*
