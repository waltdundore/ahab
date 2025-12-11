# Ahab Development Rules

**Everything developers need in one place.**

For user documentation, see [README.md](../../README.md).  
For project mission and release process, see [ABOUT.md](../../ABOUT.md).

---

## Guiding Priorities

**Everything we do follows this order:**

1. **Student Achievement First** - Every decision, every feature, every line of code serves student learning and success
2. **Bug-Free Software** - Quality and reliability before features. No release until tests pass.
3. **Marketing What We Do** - Share our work, document our lessons, maximize benefit for education

**Why this order matters:**
- Students can't learn from broken software
- Bug-free software that nobody knows about helps nobody
- Marketing without quality damages trust

**Test every decision**: Does this serve students? Is it reliable? Will others learn from it?

**Automated Audit**: Run `make audit-priorities` to verify documentation addresses all three priorities. This runs automatically before every build.

---

## Absolute Rules (NO EXCEPTIONS - EVER)

These are not suggestions. These are laws. Break them and your work gets deleted.

### ABSOLUTE RULE #1: Execute Tasks in Priority Order

**CRITICAL**: When working from a task list, ALWAYS execute the highest priority task first.

**Why**: Critical tasks block other work. Doing low-priority tasks first wastes time if critical tasks fail.

**Process**:
1. Read the ENTIRE task list
2. Identify which task is marked CRITICAL or highest priority
3. Execute that task FIRST
4. Only move to next task after completing highest priority
5. Never skip ahead to "easier" tasks

**Test**: Can you explain why this task must be done before others? If no, re-read priorities.

**Penalty for violation**: Stop work, return to highest priority task.

**Example**:
- ❌ BAD: "I'll skip the standards verification and start coding the registry"
- ✅ GOOD: "Task 1 is CRITICAL and blocks everything, so I'll do that first"

---

### ABSOLUTE RULE #2: Follow The Requirements

**CRITICAL**: Before writing ANY code, read the requirements document.

**Why**: If you don't know what you're building, you'll build the wrong thing.

**Process**:
1. Read `.kiro/specs/{feature}/requirements.md` FIRST
2. Understand WHAT and WHY
3. Then read `design.md` for HOW
4. Then write code
5. Then verify code matches requirements

**Test**: Can you explain WHY this feature exists? If no, go back to requirements.

**Penalty for violation**: Delete the code and start over.

**Example**:
- ❌ BAD: "I'll just start coding the timeline generator"
- ✅ GOOD: "Read requirements, understand we need proof of AI work, then code"

---

## Quick Start for Developers

```bash
# Before ANY commit
./scripts/validate-nasa-standards.sh
make clean && make install && make verify-install

# If tests fail, STOP and fix
```

---

## Core Principles

1. **Eat Your Own Dog Food** - Use `make` commands, not direct tools
2. **Modular and Simple** - `make install` just works
3. **Safety-Critical Standards** - NASA Power of 10 rules (MANDATORY)
4. **Never Assume Success** - Verify every operation
5. **Container-First** - Always use containers
6. **Docker Compose First** - Every build produces working docker-compose.yml
7. **Radical Transparency** - Document failures and successes
8. **Kiro Reviews Everything** - AI reviews before refactoring
9. **Single Source of Truth (DRY)** - Data lives in ONE place only (ahab.conf)
10. **Teaching Mindset** - Every line of code teaches someone who comes after you
11. **Documentation as Education** - Every command example teaches the right way. We use what we document. Same repository. Same network. Our employees use this daily on our production infrastructure.

---

## The Teaching Mindset (Core Principle #10)

**Why this matters**: We're not here forever. Knowledge dies when it's not shared.

**What it means**:
- Every function has a comment explaining WHY, not just WHAT
- Every decision is documented
- Every failure is recorded (not hidden)
- Every success explains how we got there
- Code is written for humans first, computers second

**Examples**:
- ❌ BAD: `# Fix bug` (what bug? why? how?)
- ✅ GOOD: `# Fix SELinux permission issue - Docker needs :z flag on Fedora volumes`

- ❌ BAD: `if x > 0:` (why this check?)
- ✅ GOOD: `if x > 0:  # NASA Rule 2: Bounded loops - prevent infinite iteration`

**Test**: Can someone who's never seen this code understand WHY it exists? If no, add comments.

**Why we do this**:
- Knowledge transfer when people leave
- Onboarding new contributors
- Future you will forget why you did this
- Teaching others who learn from this code
- Building something that outlasts us

**This isn't optional. This is how we honor those who come after us.**

---

## Documentation as Education (Core Principle #11)

**Why this matters**: Every command example is a teaching moment.

**What it means**:
- Every command in our documentation is a command we actually use
- Same repository we publish is the one we use internally
- Our employees test every change on our actual network
- We show the tested, maintained interface, not internal implementation
- Direct tool usage (vagrant, scripts) is internal—users see `make` commands

**Examples**:
- ❌ BAD: Show `vagrant up` in user docs (teaches wrong abstraction)
- ✅ GOOD: Show `make install` in user docs (teaches correct interface)

- ❌ BAD: Show `./scripts/deploy-apache.sh` (bypasses tested interface)
- ✅ GOOD: Show `make install apache` (uses what we test)

**Test**: Can a new user learn the correct interface from our examples? If no, fix the docs.

**Why we do this**:
- Builds trust through consistency
- Respects users' learning journey
- Prevents confusion about "real" vs "demo" commands
- Proves we use what we document

**This is advertised, not hidden. It's a competitive differentiator.**

**Timeout Protection for Long-Running Operations**:

All long-running operations (like documentation audits) MUST be wrapped with timeout protection in Makefile targets:

```bash
# ✅ GOOD: Makefile target with timeout
make audit-docs           # 30s timeout, kills hung processes
make audit-docs-fix       # 60s timeout for fixes
make audit-docs-strict    # 30s timeout for CI/CD
```

**Why timeout protection matters**:
- Catches hung processes (regex backtracking, file I/O blocks, infinite loops)
- Provides diagnostic information (`.audit-state` file shows last known state)
- Fails fast instead of hanging indefinitely
- Makes operations safe for CI/CD pipelines

**Implementation**:
- Use `perl -e 'alarm N; exec @ARGV'` for cross-platform timeout (works on macOS and Linux)
- Write state to `.audit-state` before processing each file
- Exit code 142 or 124 indicates timeout
- Display diagnostic information on timeout

**Example from Makefile**:
```makefile
audit-docs:
	@perl -e 'alarm 30; exec @ARGV' ./scripts/audit-documentation.sh || \
		(if [ $$? -eq 142 ]; then \
			echo "ERROR: Script hung"; \
			cat .audit-state; \
		fi)
```

**This is dogfooding**: We use `make audit-docs`, not the raw script. If it hangs for us, we fix it before you see it.

---

## Document Dependencies

**Before updating this file**: Check DOCUMENT_LINKS.md

This file depends on:
- **ABOUT.md** - Core Principles must align with philosophy

When you update this file, also update:
1. SPECIFICATIONS.md - Verify requirements follow new rules
2. QUEUE.md - Add refactoring tasks if needed
3. All code - Refactor to comply with new rules

**Rule**: Coding standards flow from philosophy. Check ABOUT.md first.

---

## NASA Power of 10 Rules (MANDATORY)

**NO EXCEPTIONS. NO COMPROMISES. NO EXCUSES.**

1. **Simple Control Flow** - No goto, setjmp, longjmp, recursion
2. **Bounded Loops** - Fixed upper bounds provable by static analysis
3. **No Dynamic Memory After Init** - No malloc/free after initialization
4. **Short Functions** - Max 60 lines per function
5. **High Assertion Density** - Min 2 assertions per function
6. **Minimal Scope** - Declare at smallest scope
7. **Check All Returns** - Validate all returns and parameters
8. **Limited Preprocessor** - Simple macros only
9. **Restricted Pointers** - Max one level of dereference
10. **Zero Warnings** - Zero tolerance

**Current Status**: 47 violations in existing code. Being fixed.

---

## Development Rules

### #1: Use Makefile Commands
Use `make install`, not `vagrant up`.

**Why**: We eat our own dog food. If `make install` doesn't work for us, it won't work for users.

### #2: Single Source of Truth (DRY - Don't Repeat Yourself)
**CRITICAL**: Data lives in ONE place only.

**Rules**:
- All configuration in `ahab.conf` (versions, packages, settings)
- Vagrantfile reads from `ahab.conf` (never hardcodes)
- Makefile reads from `ahab.conf` (never hardcodes)
- Scripts read from `ahab.conf` (never hardcodes)
- NO duplication of data across files
- NO hardcoded values that should be configurable

**Examples**:
- ✅ GOOD: `WORKSTATION_PACKAGES` in ahab.conf, read by Vagrantfile
- ❌ BAD: Package list hardcoded in Vagrantfile
- ✅ GOOD: `FEDORA_VERSION` in ahab.conf, read everywhere
- ❌ BAD: Version number repeated in multiple files

**Why**: Changing a value in one place changes it everywhere. No inconsistencies.

### #3: Verify Every Operation
Check exit codes. Verify files exist. No silent failures.

**Why**: Silent failures waste hours of debugging time.

### #4: Clean State Between Tests
`make clean` before every test.

**Why**: Dirty state causes false positives and false negatives.

### #5: Zero Tolerance for Warnings
All warnings are errors. Fix immediately.

**Why**: Warnings become errors in production. Fix them now.

### #6: Commit Often
Small commits with clear messages.

**Why**: Small commits are easy to review and easy to revert.

---

## Testing Checklist

### Critical Milestone (MUST PASS FIRST)
- [ ] `make clean && make install && make verify-install`
- [ ] If this fails, STOP

### NASA Standards
- [ ] All NEW code follows NASA Power of 10
- [ ] Shellcheck passes with zero warnings
- [ ] If violations exist, REJECT commit

### Core Requirements
- [ ] Used `make` commands
- [ ] Tested with clean state
- [ ] Verified all operations
- [ ] Clear commit message

---

## Lessons Learned

### What Worked
- Git workflow with small commits
- Cross-platform scripts with helper functions
- Comprehensive documentation
- Module system design
- Reading requirements before coding

### What Failed
- Multiple configuration files (use ONE: ahab.conf)
- Assuming operations succeeded (always verify)
- Vagrant box compatibility (use bento/* boxes)
- Hardcoded versions (read from ahab.conf)
- Hardcoded package lists (read from ahab.conf)
- Duplicating data across files (violates DRY/Single Source of Truth)
- Non-portable sed commands (use helper function)
- Ignoring return values (check every command)
- Relative paths in Docker volumes (use absolute paths: `/home/vagrant/ahab/file.html`)
- Assuming rsync syncs immediately (run `vagrant rsync` explicitly after file changes)
- **Coding without reading requirements** (wasted time building wrong thing)

---

## Safety Audit Status

**Current**: 47 violations in existing code  
**Plan**: Refactoring to 100% compliance  
**Validation**: `./scripts/validate-nasa-standards.sh`

**Common Violations**:
- Unbounded loops
- Functions too long
- Low assertion density
- Unchecked returns

---

## Evidence We Follow Our Principles

### Eat Your Own Dog Food / Documentation as Education
- All documentation shows `make` commands
- Same repository we use internally
- Our employees use this on our production network daily
- CI/CD uses same workflow
- When we say "it works," we mean "it's working for us right now"

### Modular and Simple
- Single command: `make install`
- Single config: `ahab.conf`
- Auto-setup in Makefile

### Safety-Critical Standards
- Comprehensive safety audit
- Bounded loops in new code
- Return value checking
- Refactoring in progress

### Never Assume Success
- File verification in scripts
- Exit code checking
- VM status verification
- Error queue pattern

### Container-First
- `make deploy-apache` uses Docker
- Native requires confirmation
- Targeting Fedora Silverblue

### Docker Compose First
- Module metadata generates docker-compose.yml
- generate-docker-compose.py script
- Primary deliverable

---

## Quick Reference

### Commands
```bash
make install              # Create workstation
make verify-install       # Verify installation
make deploy-apache        # Deploy Apache (Docker)
make test                 # Run tests
make clean                # Destroy VM
make help                 # Show all commands
```

### Files
- `ahab.conf` - Configuration (single source of truth)
- `PRIORITIES.md` - Quick reference for what to work on (session handoff schema)
- `QUEUE.md` - Detailed work queue (our bible)
- `README.md` - User documentation
- `ABOUT.md` - Mission, vision, release process
- `DEVELOPMENT_RULES.md` - This file
- `.kiro/specs/` - Requirements and design documents

### Repositories
- `ahab` - Orchestration (git@github.com:waltdundore/ahab.git)
- `ansible-config` - Configuration (git@github.com:waltdundore/ansible-config.git)
- `ansible-inventory` - Inventory (git@github.com:waltdundore/ansible-inventory.git)
- `ahab-modules` - Modules (git@github.com:waltdundore/ahab-modules.git)

---

## Release Requirements

See [ABOUT.md](ABOUT.md#release-requirements) for complete release process.

**Summary**:
1. Workstation bootstrap test passes
2. Docker Compose generation works
3. All working tests pass
4. Raspberry Pi tests pass
5. Dev server tests pass (d701.dundore.net)
6. Documentation updated
7. All four repositories tagged
8. Release notes written

**No exceptions**: If any test fails, no release.

---

*Last updated: December 8, 2025*
