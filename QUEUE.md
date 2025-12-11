# Ahab Development Queue

![Ahab Logo](ahab/docs/images/ahab-logo.png)

**Our Bible for Development**

This is our public, transparent queue. Everything we're working on, everything we need to fix, everything we plan to do.

**Last Updated**: December 8, 2025 (✅ Critical lessons from v0.1.1 release documented)

**Quick Reference**: See [PRIORITIES.md](PRIORITIES.md) for condensed priority list and session handoff schema.

---

## How This Works

### Priority Levels
- **P0 - CRITICAL**: Blocks everything. Must fix immediately.
- **P1 - HIGH**: Blocks release. Must fix before release.
- **P2 - MEDIUM**: Important but not blocking.
- **P3 - LOW**: Nice to have.

### Status
- **🔴 BLOCKED** - Cannot proceed
- **🟡 IN PROGRESS** - Currently working on
- **🟢 READY** - Ready to start
- **⚪ QUEUED** - Waiting in queue
- **✅ DONE** - Completed

### Rules
1. **P0 items always go first** - No exceptions
2. **Critical milestone must pass** - Workstation bootstrap test
3. **Follow Core Principles** - See [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md)
4. **NASA standards mandatory** - All new code must comply
5. **Kiro reviews before refactoring** - AI reviews the plan
6. **No release until tests pass** - All quality gates must pass

---

## Current Sprint

### 🟡 IN PROGRESS

**None** - Ready to start next priority item

### 🟢 READY TO START

**P1-003: Configure ahab-modules as Git Submodule** - Ready to start (quick win)
**P1-001: Docker Compose Generation Script** - Ready to start (requires ahab-modules)

---

## Priority 0 - CRITICAL (Blocks Everything)

### P0-001: Workstation Bootstrap Test ✅ CRITICAL MILESTONE
- **Status**: ✅ DONE (December 8, 2025)
- **Description**: `make install` must create working workstation VM
- **Why Critical**: This is what users do first. If this fails, nothing else matters.
- **Solution**: Single Vagrantfile reading from ahab.conf
- **Acceptance Criteria**:
  - [x] Single Vagrantfile in ahab/
  - [x] Reads from ahab.conf (single source of truth)
  - [x] Uses bento/* boxes (multi-provider support)
  - [x] Follows NASA standards (bounded loops, error checking)
  - [x] Old Vagrantfiles archived
  - [x] `make clean` destroys VM
  - [x] `make install` creates VM
  - [x] `make verify` confirms VM is accessible
  - [x] All tools installed (Git, Ansible, Docker)
  - [x] Three repositories exist on host (ahab, ansible-config, ansible-inventory)
  - [x] Symlinks created correctly (inventory → ../ansible-inventory, config.yml → ../ansible-config/config.yml)
- **Note**: Fourth repository (ahab-modules) tracked in P1-003
- **Unblocks**: P1-000, P1-001, P1-002, P1-003, P1-004
- **Related Principles**: #2 (Modular and Simple), #3 (NASA Standards), #4 (Never Assume Success)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 1

---

## Priority 1 - HIGH (Blocks Release)

### P1-000: Security Audit and Scan Update ✅ COMPLETE
- **Status**: ✅ DONE (December 8, 2025)
- **Description**: Comprehensive security audit and update security validation scripts
- **Why High**: Security is critical before any release
- **Acceptance Criteria**:
  - [x] Run comprehensive security scan on all code
  - [x] Update `scripts/validate-nasa-standards.sh` with new rules
  - [x] Audit all shell scripts for security vulnerabilities
  - [x] Check for hardcoded secrets or credentials (PASSED - none found)
  - [x] Validate input sanitization in all scripts (PASSED)
  - [x] Review Docker container security (PASSED - no privileged containers)
  - [x] Check for command injection vulnerabilities (1 minor issue FIXED)
  - [x] Review network security (PASSED - private networks only)
  - [x] Update SAFETY_AUDIT.md with findings
  - [x] Create remediation plan (documented in SECURITY_AUDIT_2025-12-07.md)
  - [x] Add automated security checks to validation script
- **Results**:
  - Grade: A- (Excellent)
  - No critical issues found
  - 1 minor command injection risk fixed in ssh-terminal.sh
  - Enhanced validation script with security checks
  - Full report: SECURITY_AUDIT_2025-12-07.md
- **Related Principles**: #3 (Safety-Critical Standards), #4 (Never Assume Success), #7 (Radical Transparency)

### P1-001: Docker Compose Generation Script
- **Status**: ⚪ QUEUED
- **Blocked By**: P0-001
- **Description**: Script reads module.yml and generates docker-compose.yml
- **Why High**: Core of Docker Compose First Architecture
- **Acceptance Criteria**:
  - [ ] Script reads module.yml from ahab-modules
  - [ ] Generates valid docker-compose.yml
  - [ ] Resolves module dependencies
  - [ ] Includes networks, volumes, services
  - [ ] `docker-compose up -d` works
- **Related Principles**: #6 (Docker Compose First)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 3

### P1-002: Apache Module Deployment
- **Status**: ⚪ QUEUED
- **Blocked By**: P0-001, P1-001
- **Description**: Deploy Apache using generated docker-compose.yml
- **Why High**: First module, proves the system works
- **Acceptance Criteria**:
  - [ ] `make deploy-apache` generates docker-compose.yml
  - [ ] Apache container starts
  - [ ] `curl http://localhost` responds
  - [ ] Working test passes
- **Related Principles**: #5 (Container-First), #6 (Docker Compose First)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 4

### P1-003: Configure ahab-modules as Git Submodule
- **Status**: ⚪ QUEUED
- **Blocked By**: P0-001
- **Description**: Configure ahab/modules as Git submodule
- **Why High**: Part of four-repository architecture
- **Acceptance Criteria**:
  - [ ] `git submodule add git@github.com:waltdundore/ahab-modules.git modules`
  - [ ] `.gitmodules` file created
  - [ ] `git submodule update --init --recursive` works
  - [ ] Modules directory populated
- **Related Principles**: #2 (Modular and Simple)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 2

### P1-004: Update Documentation for Docker Compose First
- **Status**: ⚪ QUEUED
- **Blocked By**: P0-001, P1-001, P1-002
- **Description**: Update DEVELOPMENT_RULES.md with Docker Compose First as Core Principle #6
- **Why High**: Must document the commitment
- **Acceptance Criteria**:
  - [ ] DEVELOPMENT_RULES.md includes Docker Compose First
  - [ ] README.md states docker-compose.yml is primary deliverable
  - [ ] ABOUT.md explains Docker Compose First Architecture
- **Related Principles**: #7 (Radical Transparency)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 7

### P1-005: Unified Module Installation Interface
- **Status**: ⚪ QUEUED (Deprecation warnings added)
- **Blocked By**: P0-001, P1-001, P1-002
- **Description**: Replace individual deploy commands with unified `make install` that accepts module array
- **Why High**: Simplifies user experience, aligns with Docker Compose First architecture
- **Progress**:
  - [x] Added deprecation warnings to `make deploy-apache`
  - [x] Added deprecation warnings to `make deploy-apache-native`
  - [x] Added deprecation warnings to `make deploy-mysql`
  - [x] Updated help text to show DEPRECATED status
  - [ ] Implement `make install [modules...]` functionality
  - [ ] Remove deprecated commands
- **Current Behavior**:
  - `make deploy-apache` - Deploy Apache
  - `make deploy-mysql` - Deploy MySQL
  - Separate command for each service
- **New Behavior**:
  - `make install apache mysql` - Install array of modules: [apache, mysql]
  - `make install php mysql` - Install array of modules: [php, mysql]
  - Single command, module array as arguments
  - Generates unified docker-compose.yml with all selected services from module array
- **Technical Details**:
  - Module arguments become an array of module names
  - Array is passed to docker-compose generation script
  - Each module has its own Git repository (git@github.com:waltdundore/ahab-modules.git)
  - Modules are version controlled and can be independently updated
  - Script reads each module's module.yml from ahab-modules submodule
  - Generates single docker-compose.yml combining all modules in array
  - Resolves dependencies between modules in array
  - Modules can be installed, updated, and controlled via Git
- **Acceptance Criteria**:
  - [ ] `make install` accepts module names as array arguments
  - [ ] Multiple modules can be specified: `make install apache mysql php`
  - [ ] Module arguments are processed as array internally
  - [ ] Generates single docker-compose.yml with all services from module array
  - [ ] Validates each module name in array against ahab-modules registry
  - [ ] Shows error for invalid module names in array
  - [ ] Backward compatibility: `make install` with no args creates workstation only
  - [ ] Remove old `make deploy-*` commands
  - [ ] Update documentation and help text
- **Related Principles**: #2 (Modular and Simple), #6 (Docker Compose First)
- **Spec**: TBD - needs design document

---

## Priority 2 - MEDIUM (Important)

### P2-001: Raspberry Pi Testing Framework
- **Status**: ⚪ QUEUED
- **Blocked By**: P1-002
- **Description**: Create testing framework for Raspberry Pi deployment
- **Why Medium**: Part of testing pipeline, but not blocking initial release
- **Acceptance Criteria**:
  - [ ] Raspberry Pi inventory configured
  - [ ] Deployment playbook created
  - [ ] Working tests run on Raspberry Pi
  - [ ] ARM architecture validated
- **Related Principles**: #4 (Never Assume Success)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 8

### P2-002: Dev Server Deployment (d701.dundore.net)
- **Status**: ⚪ QUEUED
- **Blocked By**: P2-001
- **Description**: Create deployment process for dev server
- **Why Medium**: Internal quality gate, not user-facing
- **Acceptance Criteria**:
  - [ ] d701.dundore.net inventory configured
  - [ ] Deployment playbook created
  - [ ] All working tests run
  - [ ] Build marked as release-ready on success
- **Related Principles**: #4 (Never Assume Success)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 9

### P2-003: Release Creation Script
- **Status**: ⚪ QUEUED
- **Blocked By**: P2-002
- **Description**: Automate release creation process
- **Why Medium**: Makes releases consistent and repeatable
- **Acceptance Criteria**:
  - [ ] Verifies all tests passed
  - [ ] Tags all four repositories
  - [ ] Includes docker-compose.yml in release
  - [ ] Documents test results
  - [ ] Prevents release if tests failed
- **Related Principles**: #4 (Never Assume Success), #7 (Radical Transparency)
- **Spec**: `.kiro/specs/docker-compose-first/requirements.md` Requirement 10

---

## Priority 3 - LOW (Nice to Have)

### P3-001: Additional Modules (MySQL, Nginx, PostgreSQL)
- **Status**: ⚪ QUEUED
- **Blocked By**: P1-002
- **Description**: Create additional service modules
- **Why Low**: Expands functionality but not critical for initial release
- **Acceptance Criteria**: TBD per module

### P3-002: Menu-Driven Interface
- **Status**: ⚪ QUEUED
- **Blocked By**: P1-002, P3-001
- **Description**: Web interface for service selection
- **Why Low**: Future enhancement, command-line works for now
- **Acceptance Criteria**: TBD

### P3-003: VirtualBox Provider Testing
- **Status**: ⚪ QUEUED
- **Blocked By**: P0-001
- **Description**: Test workstation with VirtualBox provider for cross-platform compatibility
- **Why Low**: Parallels works for current development, VirtualBox needed for broader compatibility
- **Current State**:
  - Vagrantfile supports VirtualBox provider
  - Currently testing with Parallels on macOS
  - VirtualBox testing deferred to future release
- **Host Workstation Setup**:
  - Can use Homebrew (brew) to install VirtualBox on macOS host
  - `brew install --cask virtualbox`
  - `brew install --cask vagrant`
- **Acceptance Criteria**:
  - [ ] Install VirtualBox on host workstation via Homebrew
  - [ ] Configure ahab.conf to use VirtualBox provider
  - [ ] `make install` creates VM using VirtualBox
  - [ ] `make verify-install` passes with VirtualBox
  - [ ] All tools work correctly (Git, Ansible, Docker)
  - [ ] Document VirtualBox setup in README.md
  - [ ] Test on Linux host (VirtualBox native)
  - [ ] Test on Windows host (VirtualBox native)
- **Related Principles**: #4 (Never Assume Success)
- **Notes**: 
  - Bento boxes support VirtualBox, Parallels, and VMware
  - VirtualBox is free and cross-platform (macOS, Linux, Windows)
  - Parallels is macOS-only but faster for development

### P3-004: ~~Visual Studio Code Extension~~ and Web Interface
- **Status**: ❌ CANCELLED (VS Code Extension) / ✅ COMPLETED (Web Interface via ahab-gui)
- **Description**: ~~VS Code extension~~ Web interface for commanding Ahab
- **Why Cancelled**: VS Code extension not needed - ahab-gui provides web interface
- **Web Interface**: Completed via [ahab-gui](https://github.com/waltdundore/ahab-gui)
  - Dashboard showing deployed services and status
  - Point-and-click module selection
  - Real-time service health monitoring
  - Progressive disclosure UX
  - Educational focus for K-12
- **Notes**:
  - Web interface (ahab-gui) is available and functional
  - VS Code extension removed from roadmap
  - CLI always works as primary interface

---

## Critical Lessons Learned (v0.1.1 Release)

**Added**: December 8, 2025  
**Context**: Lessons from v0.1.1 release preparation that must inform future work

### LESSON 1: External Commands Need Timeouts Too

**What Happened**: Vagrant commands had no timeout protection. When Vagrant hung (which it often does), entire test suite hung forever, forcing manual kill.

**Why It Matters**: Violated NASA Rule 2 (all operations must have fixed upper bounds). Real bug users were experiencing.

**What We Learned**: 
- Not just loops need bounds - ANY external command that can hang needs timeout
- Vagrant, Docker, network operations, file I/O - all need protection
- Timeout wrappers must provide helpful error messages with troubleshooting steps

**Action Items**:
- [ ] P2-004: Audit all external command calls for timeout protection
- [ ] P2-005: Add timeout detection to NASA validation script
- [ ] P2-006: Document timeout wrapper pattern in DEVELOPMENT_RULES.md

**Files Changed**: `tests/lib/test-helpers.sh`, all e2e test scripts

### LESSON 2: Branching Strategy Violation Causes Data Loss

**What Happened**: Promoted prod to dev and lost 13 commits including documentation, error messages, and testing improvements.

**Why It Matters**: Violated transparency principle. Lost work. Wasted time.

**What We Learned**:
- Branching is ONE WAY ONLY: dev → prod
- NEVER promote prod to dev
- ALWAYS check `git log dev..prod` before promotion (must be EMPTY)
- If prod has commits dev doesn't, you made a mistake - cherry-pick to dev first

**Action Items**:
- [ ] P1-006: Add pre-promotion check to release script
- [ ] P1-007: Add git hook to prevent direct commits to prod
- [ ] P2-007: Add branching strategy to release checklist

**Files Created**: `BRANCHING_STRATEGY.md`

### LESSON 3: Empathy = Helpfulness, Not Keywords

**What Happened**: Empathy audit checked for sentiment keywords ("frustrating", "I know") instead of measuring actual helpfulness.

**Why It Matters**: Encouraged performative empathy. Missed the real goal: actionable guidance.

**What We Learned**:
- Real empathy = clear message + actionable guidance + context + no blame
- Check for helpful content (commands to run, links, specific steps)
- Avoid dismissive language ("just", "simply")
- Lower threshold to realistic target (50% not 80%)

**Action Items**:
- [ ] P2-008: Review all error messages for helpfulness
- [ ] P2-009: Add empathy examples to DEVELOPMENT_RULES.md
- [ ] P3-005: Create error message template/checklist

**Files Changed**: `scripts/audit-accountability.sh`

### LESSON 4: Work on Workstation, Not Virtually

**What Happened**: Development was happening in IDE/Docker instead of on actual workstation VM. Code that worked in IDE failed on workstation.

**Why It Matters**: Not eating our own dog food. Missing environment-specific issues.

**What We Learned**:
- Develop where users will run the code
- SSH into workstation, make changes there, test there
- Use rsync to sync files, not edit remotely
- If it doesn't work for us on workstation, it won't work for users

**Action Items**:
- [ ] P2-010: Add workstation development workflow to onboarding docs
- [ ] P2-011: Create make targets for common workstation workflows
- [ ] P3-006: Consider VS Code Remote SSH setup guide

**Files Changed**: `DEVELOPMENT_RULES.md` (added ABSOLUTE RULE #0), `Makefile` (added sync commands)

### LESSON 5: Verify Files Are in Git Before Referencing

**What Happened**: Code referenced `index.html` in root directory, but file wasn't in git. Sync target tried to copy non-existent file.

**Why It Matters**: Broken builds. Confusion about what's tracked vs untracked.

**What We Learned**:
- Don't assume files exist based on code references
- Check `git ls-files` to verify
- Root workspace directory is temporary - only git repos persist
- Document what's tracked and what's not

**Action Items**:
- [ ] P2-012: Audit all file references in Makefiles and scripts
- [ ] P2-013: Add file existence checks before operations
- [ ] P3-007: Create pre-commit hook to catch missing file references

**Files Changed**: Root `Makefile` (removed invalid sync), `.gitignore` (documented strategy)

### LESSON 6: Make Commands Must Handle Edge Cases

**What Happened**: `make sync` failed when uncommitted changes existed. User had to manually resolve.

**Why It Matters**: Violates "eat our own dog food" - if make doesn't work for us, won't work for users.

**What We Learned**:
- Make targets must handle common edge cases (uncommitted changes, divergent branches)
- Stash/unstash pattern for sync operations
- Provide helpful error messages, not just fail
- Test make commands in dirty state, not just clean state

**Action Items**:
- [ ] P2-014: Audit all make targets for edge case handling
- [ ] P2-015: Add tests for make targets with dirty state
- [ ] P3-008: Document make target patterns in DEVELOPMENT_RULES.md

**Files Changed**: Root `Makefile` (added sync target with stash/unstash)

---

## Bug Reports

### BUG-001: DEVELOPMENT_RULES.md was corrupted during consolidation
- **Status**: ✅ FIXED
- **Priority**: P0 - CRITICAL
- **Reported**: December 8, 2025
- **Description**: File write error caused corruption
- **Fix**: Recreated file with proper content
- **Verified**: File now has correct content
- **Related**: Documentation consolidation

### BUG-002: Multiple Vagrantfiles causing confusion
- **Status**: ✅ FIXED (Archived)
- **Priority**: P1 - HIGH
- **Reported**: December 8, 2025
- **Description**: Three different Vagrantfiles with different settings
- **Fix**: Documented in LESSONS_LEARNED.md, archived old files
- **Related**: Core Principle #2 (Single Source of Truth)

### BUG-003: 47 NASA Power of 10 violations in existing code
- **Status**: 🔴 OPEN
- **Priority**: P1 - HIGH
- **Reported**: December 8, 2025
- **Description**: Existing code violates NASA standards
- **Plan**: Refactor systematically after P0-001 passes
- **Tracked In**: SAFETY_AUDIT.md
- **Related**: Core Principle #3 (Safety-Critical Standards)

---

## Completed Items

### ✅ P0-001: Workstation Bootstrap Test (CRITICAL MILESTONE)
- **Completed**: December 8, 2025
- **Description**: Single Vagrantfile creates working workstation VM
- **Result**: `make clean && make install && make verify` works perfectly
- **Tools Verified**: Git 2.52.0, Ansible 2.18.11, Docker 29.0.4, Python 3.14.0
- **Details**: Workstation VM boots, provisions, and passes all verification checks

### ✅ P1-000: Security Audit and Scan Update
- **Completed**: December 8, 2025
- **Description**: Comprehensive security audit of entire codebase
- **Result**: Grade A- (Excellent) - No critical issues, 1 minor issue fixed
- **Findings**:
  - ✅ No hardcoded secrets
  - ✅ No privileged containers
  - ✅ Good input validation
  - ✅ Proper secrets management (Ansible Vault)
  - ⚠️ 1 command injection risk (FIXED)
- **Deliverables**:
  - SECURITY_AUDIT_2025-12-07.md (full report)
  - Enhanced validate-nasa-standards.sh with security checks
  - Fixed ssh-terminal.sh input validation
  - Updated SAFETY_AUDIT.md
- **Details**: Codebase is production-ready from security perspective

### ✅ Documentation Consolidation
- **Completed**: December 8, 2025
- **Description**: Consolidated 51 markdown files into 7 core files
- **Result**: 86% reduction in files, easier to find information
- **Details**: See CONSOLIDATION_COMPLETE.md

### ✅ Four-Repository Architecture Documented
- **Completed**: December 8, 2025
- **Description**: Documented ahab, ansible-config, ansible-inventory, ahab-modules
- **Result**: Clear separation of concerns
- **Details**: See README.md and ABOUT.md

### ✅ Docker Compose First Architecture Specified
- **Completed**: December 8, 2025
- **Description**: Created spec for Docker Compose First Architecture
- **Result**: Clear requirements and design
- **Details**: See `.kiro/specs/docker-compose-first/`

### ✅ Single Source of Truth (DRY) Enforcement
- **Completed**: December 8, 2025
- **Description**: Moved hardcoded package list from Vagrantfile to ahab.conf
- **Result**: All configuration now in one place (ahab.conf)
- **Changes**:
  - Added `WORKSTATION_PACKAGES` to ahab.conf
  - Updated Vagrantfile to read packages from config
  - Added Core Principle #9: Single Source of Truth (DRY)
  - Updated DEVELOPMENT_RULES.md with DRY guidelines
- **Why**: Eliminates duplication, ensures consistency, follows DRY principle

### ✅ .gitignore Strategy and Implementation
- **Completed**: December 8, 2025
- **Description**: Created comprehensive .gitignore files and documentation
- **Result**: Clear rules about what gets committed and what doesn't
- **Changes**:
  - Created root `.gitignore` (project-wide ignores)
  - Created `ahab/.gitignore` (Ansible-specific)
  - Created `.kiro/.gitignore` (Kiro IDE-specific)
  - Created `docs/GITIGNORE_STRATEGY.md` (comprehensive guide)
- **What We Ignore**:
  - Secrets (passwords, keys, certificates)
  - Generated files (docker-compose.yml, timelines)
  - Local environment (.vagrant, .vscode, .DS_Store)
  - Dependencies (venv, node_modules)
  - Logs and temporary files
- **Why**: Prevents security issues, reduces bloat, avoids merge conflicts

### ✅ Absolute Rule #1: Follow The Requirements
- **Completed**: December 8, 2025
- **Description**: Added "Absolute Rules" section to DEVELOPMENT_RULES.md
- **Result**: Non-negotiable law that must be followed before coding
- **Rule**: Read requirements document BEFORE writing any code
- **Process**: Requirements → Design → Code → Verify
- **Penalty**: Delete code and start over if violated
- **Why**: Prevents building the wrong thing, saves time, ensures alignment

### ✅ AI Transparency Spec Created
- **Completed**: December 8, 2025
- **Description**: Created requirements and design for AI transparency documentation
- **Result**: Clear plan for proving AI capabilities with verifiable evidence
- **Files Created**:
  - `.kiro/specs/ai-transparency/requirements.md`
  - `.kiro/specs/ai-transparency/design.md`
- **Purpose**: Make Ahab the reference case for "AI replaced senior engineers"
- **Why**: Demonstrate AI capabilities with git commits, timelines, and metrics

### ✅ PRIORITIES.md Schema Created
- **Completed**: December 8, 2025
- **Description**: Created PRIORITIES.md as session handoff schema
- **Result**: Quick reference for passing context between sessions
- **Files Created**:
  - `PRIORITIES.md` (session handoff schema)
  - `docs/SESSION_CONTEXT_TRANSFER_2025-12-07.md` (context transfer archive)
  - `docs/README.md` (documentation guide)
  - `docs/PRIORITIES_SCHEMA_CREATED.md` (this accomplishment)
- **Files Modified**:
  - `QUEUE.md` (added reference to PRIORITIES.md)
  - `README.md` (reorganized documentation: user vs developer)

### ✅ Specifications Consolidated
- **Completed**: December 8, 2025
- **Description**: Consolidated all spec files into single SPECIFICATIONS.md document
- **Result**: Single source of truth for all feature specifications
- **What Was Consolidated**:
  - Docker Compose First Architecture (requirements, design, tasks)
  - AI Transparency (requirements, design)
  - Website Redesign (requirements, design, tasks)
  - Infrastructure as Code (requirements)
- **File Created**: `SPECIFICATIONS.md` (root directory)
- **Why**: Easier to find, read, and maintain all specs in one place
- **Format**: Clear sections with requirements (WHAT/WHY), design (HOW), and tasks
- **Benefits**:
  - No need to navigate multiple directories
  - See all features at a glance
  - Understand dependencies between features
  - Single file to search
  - Follows Single Source of Truth principle

### ✅ Teaching Mission Documented
- **Completed**: December 8, 2025
- **Description**: Documented the core teaching philosophy and legacy mission
- **Result**: Clear articulation of WHY this project exists beyond the code
- **Files Updated**:
  - `ABOUT.md` - Added "Why This Matters: The Teaching Mission" section
  - `DEVELOPMENT_RULES.md` - Added Core Principle #10: Teaching Mindset
  - `README.md` - Added mission statement and quote
- **Core Philosophy**:
  - "We're not here forever, but what we teach can be"
  - Every line of code teaches someone who comes after
  - Document what we know to be true
  - Knowledge dies when it's not shared
  - Teaching mindset baked into everything
- **Why This Matters**:
  - Legacy beyond code
  - Knowledge transfer when people leave
  - Onboarding new contributors
  - Building something that outlasts us
  - Honoring those who come after
- **For Introverts**: You don't have to be loud to make an impact - document, teach, pass it forward
- **The Wake-Up Call**: Life teaches you to document now or lose it forever

### ✅ Document Linking System Created
- **Completed**: December 8, 2025
- **Description**: Created internal linking system to track document dependencies
- **Result**: Know what to update when something else changes
- **File Created**: `DOCUMENT_LINKS.md`
- **Problem Solved**: Update one document, forget to update related documents → inconsistency
- **Solution**: Dependency map showing what depends on what
- **Key Features**:
  - Document hierarchy (ABOUT.md → DEVELOPMENT_RULES.md → SPECIFICATIONS.md)
  - Update workflows (Philosophy changes, new features, coding standards)
  - Consistency checks (daily, weekly, monthly, per release)
  - Common mistakes and how to avoid them
  - Emergency procedures for out-of-sync documents
- **Core Documents Tracked**:
  - ABOUT.md (The Philosophy - foundation)
  - DEVELOPMENT_RULES.md (How We Code)
  - SPECIFICATIONS.md (What We're Building)
  - README.md (First Impression)
  - index.html (The Website)
  - QUEUE.md (What We're Doing)
  - CHANGELOG.md (What We Did)
  - ahab.conf (Configuration)
- **Rule**: Check DOCUMENT_LINKS.md BEFORE updating any document
- **Why**: Ensures consistency across all documentation, prevents orphan updates
  - `DEVELOPMENT_RULES.md` (added PRIORITIES.md to key files)
- **Why**: Long conversations lose context; need structured handoff schema
- **Benefits**: 2-3 minute read, clear current state, obvious next priority

---

## How to Use This Queue

### For Developers
1. Check **Current Sprint** for what's in progress
2. Pick next **READY** item from highest priority
3. Update status to **IN PROGRESS**
4. Follow **Acceptance Criteria**
5. Mark **DONE** when complete
6. Update **Last Updated** date

### For Users
1. See what we're working on (transparent)
2. Report bugs (add to Bug Reports section)
3. Suggest features (add to appropriate priority)
4. Track progress (check Completed Items)

### For Contributors
1. Pick an item marked **READY**
2. Follow Core Principles (see DEVELOPMENT_RULES.md)
3. Follow NASA standards (mandatory)
4. Update queue when starting/completing
5. Add bugs you find

---

## Queue Rules (Our Bible)

### Rule 1: P0 Always Goes First
If there's a P0 item, nothing else matters. Fix it.

### Rule 2: Critical Milestone Must Pass
Workstation bootstrap test (P0-001) must pass before anything else.

### Rule 3: Follow Core Principles
Every item must follow the 8 Core Principles. No exceptions.

### Rule 4: NASA Standards Mandatory
All new code must comply with NASA Power of 10 rules.

### Rule 5: Kiro Reviews Before Refactoring
Before any refactoring, Kiro reviews the plan.

### Rule 6: No Release Until Tests Pass
All quality gates must pass: Workstation → Raspberry Pi → Dev Server → Release.

### Rule 7: Update This Queue
When you start work, update status. When you finish, mark done. Keep it current.

### Rule 8: Radical Transparency
Document failures as well as successes. Add bugs when found.

---

## Adding Items to Queue

### New Feature
```markdown
### P?-???: Feature Name
- **Status**: ⚪ QUEUED
- **Blocked By**: (if any)
- **Description**: What it does
- **Why [Priority]**: Why this priority
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2
- **Related Principles**: Which core principles apply
- **Spec**: Link to spec if exists
```

### New Bug
```markdown
### BUG-???: Bug Description
- **Status**: 🔴 OPEN
- **Priority**: P? - LEVEL
- **Reported**: Date
- **Description**: What's wrong
- **Impact**: What it affects
- **Related**: Related items/principles
```

---

## Contact

Questions about the queue? Open an issue:
- **GitHub Issues**: https://github.com/waltdundore/ahab/issues

---

*This is our bible. Follow it. Update it. Keep it transparent.*

*Last updated: December 8, 2025*
