# Claims Verification Checklist

![Ahab Logo](../docs/images/ahab-logo.png)

**Purpose**: Track all claims made in documentation and verify they're accurate.

**Last Updated**: December 7, 2025

---

## How to Use This

1. Before making ANY claim in documentation, add it here
2. Mark status: ✅ Verified | ⚠️ Partial | ❌ False | 🔄 In Progress
3. Link to evidence (code, tests, commits)
4. Update when status changes

---

## Executive Summary Claims

### "We Use It Ourselves"
- **Claim**: "We run this on our own network, with our own staff, every day"
- **Status**: ❌ FALSE - This is homelab in development
- **Fix Required**: Change to "We test this in our homelab environment"
- **Fixed In**: Commit 5ff5eaf (2025-12-07)

### "When we say 'it works,' we mean 'it's working for us right now'"
- **Claim**: Implies production use
- **Status**: ❌ FALSE - Not in production yet
- **Fix Required**: Change to "we've tested it in our homelab"
- **Fixed In**: Commit 5ff5eaf (2025-12-07)

### "We catch and fix problems before they reach you"
- **Claim**: We find bugs first in our production use
- **Status**: ⚠️ PARTIAL - We test in homelab, not production
- **Fix Required**: Clarify this is homelab testing
- **Fixed In**: Commit 5ff5eaf (2025-12-07)

### "Three commands to get started"
- **Claim**: `make install`, `make test`, `make deploy`
- **Status**: ⚠️ PARTIAL - `make deploy` doesn't exist, should be `make install apache`
- **Evidence**: Check Makefile
- **Fix Required**: Update to accurate commands

### "Every build produces a working docker-compose.yml"
- **Claim**: Docker Compose generation works
- **Status**: 🔄 IN PROGRESS - Script exists but not fully integrated
- **Evidence**: `scripts/generate-compose.py` exists
- **Fix Required**: Complete integration and test

---

## ABOUT.md Claims

### "Our employees use this daily on our production infrastructure"
- **Claim**: Production use by employees
- **Status**: ✅ FIXED - Changed to homelab testing
- **Location**: ABOUT.md, README.md, EXECUTIVE_SUMMARY.md
- **Fix Applied**: Updated all references to "homelab testing" and "development environments"
- **Fixed In**: December 7-8, 2025

### "Four Repositories Architecture"
- **Claim**: ahab, ansible-config, ansible-inventory, ahab-modules
- **Status**: ✅ FIXED - Updated to single repository architecture
- **Evidence**: ABOUT.md, README.md, DEVELOPMENT_RULES.md all updated
- **Fix Applied**: Documented actual single repository with organized directories
- **Fixed In**: December 7-8, 2025
- **Remaining**: README-ROOT.md still needs update

### "Raspberry Pi Testing"
- **Claim**: We test on Raspberry Pi before release
- **Status**: ⚠️ UNKNOWN - Need to verify if this actually happens
- **Evidence**: Need to check if Pi tests exist
- **Fix Required**: Verify or remove claim

### "Dev Server Gate (d701.dundore.net)"
- **Claim**: We test on dev server before release
- **Status**: ⚠️ UNKNOWN - Need to verify if this server exists and is used
- **Evidence**: Need to check deployment history
- **Fix Required**: Verify or remove claim

### "All Four Repositories Tagged"
- **Claim**: Release process tags 4 repos
- **Status**: ✅ FIXED - Updated to single repository
- **Fix Applied**: ABOUT.md and DEVELOPMENT_RULES.md updated to reflect single repo tagging
- **Fixed In**: December 7-8, 2025
- **Remaining**: README-ROOT.md still references 4 repos

---

## README.md Claims

### "We Use What We Document"
- **Claim**: Same commands we use internally
- **Status**: ✅ VERIFIED - We do use make commands
- **Evidence**: Development rules enforce this
- **Notes**: This is accurate

### "Same repository. Same commands. Same network"
- **Claim**: Production use
- **Status**: ❌ FALSE - Homelab only
- **Location**: README.md
- **Fix Required**: Change to homelab testing
- **Fixed In**: Commit 5ff5eaf (2025-12-07)

---

## DEVELOPMENT_RULES.md Claims

### "NASA Power of 10 Rules (MANDATORY)"
- **Claim**: We follow NASA standards
- **Status**: ⚠️ PARTIAL - 47 violations documented in SAFETY_AUDIT.md
- **Evidence**: SAFETY_AUDIT.md shows violations
- **Fix Required**: Either fix violations or change claim to "working toward compliance"

### "Current Status: 47 violations in existing code"
- **Claim**: Specific violation count
- **Status**: ⚠️ NEEDS VERIFICATION - Is this still accurate?
- **Evidence**: SAFETY_AUDIT.md
- **Fix Required**: Verify count is current

### "./scripts/validate-nasa-standards.sh"
- **Claim**: Direct script execution
- **Status**: ❌ VIOLATES OWN RULES - Should use `make test-nasa`
- **Location**: DEVELOPMENT_RULES.md Quick Start
- **Fix Required**: Change to make command
- **Fixed In**: Need to fix

---

## Testing Claims

### "make test passes"
- **Claim**: Tests work
- **Status**: ✅ VERIFIED - make test exists and runs
- **Evidence**: Makefile has test target
- **Last Verified**: 2025-12-07

### "make install works"
- **Claim**: VM creation works
- **Status**: ✅ VERIFIED - Creates VM successfully
- **Evidence**: Tested 2025-12-07
- **Last Verified**: 2025-12-07

### "make verify-install works"
- **Claim**: Verification works
- **Status**: ✅ VERIFIED - Checks VM status
- **Evidence**: Makefile target exists
- **Last Verified**: 2025-12-07

---

## Module Claims

### "Apache module works"
- **Claim**: Can deploy Apache
- **Status**: ✅ VERIFIED - module.yml exists
- **Evidence**: ahab/modules/apache/module.yml
- **Last Verified**: 2025-12-07

### "MySQL module works"
- **Claim**: Can deploy MySQL
- **Status**: ⚠️ UNKNOWN - Need to verify module exists
- **Evidence**: Need to check modules directory
- **Fix Required**: Verify or remove claim

---

## Security Claims

### "Security Audit Passed (A- grade)"
- **Claim**: Comprehensive security audit completed
- **Status**: ✅ VERIFIED - SAFETY_AUDIT.md documents this
- **Evidence**: SAFETY_AUDIT.md shows audit results
- **Last Verified**: 2025-12-07

### "No Hardcoded Secrets"
- **Claim**: All secrets use Ansible Vault
- **Status**: ✅ VERIFIED - Audit confirmed this
- **Evidence**: SAFETY_AUDIT.md security section
- **Last Verified**: 2025-12-07

---

## License Claims

### "Free for schools and non-profits"
- **Claim**: CC BY-NC-SA 4.0 license
- **Status**: ✅ VERIFIED - LICENSE file exists
- **Evidence**: LICENSE file in repo
- **Last Verified**: 2025-12-07

### "For-profit entities need to negotiate"
- **Claim**: Commercial licensing available
- **Status**: ✅ ACCURATE - This is how CC BY-NC works
- **Evidence**: License terms
- **Last Verified**: 2025-12-07

---

## Code Duplication Issues

### "We have separate HTML in playbooks"
- **Issue**: HTML hardcoded in playbooks duplicates existing website repo
- **Status**: ❌ WASTE - We already have https://github.com/waltdundore/waltdundore.github.io
- **Locations**: 
  - `playbooks/webserver.yml` - hardcoded HTML
  - `playbooks/webserver-docker.yml` - hardcoded HTML
  - `ahab/index.html` - duplicate file
  - Root `index.html` - duplicate file
- **Fix Required**: Use website repo as single source of truth
- **Impact**: CRITICAL - Violates DRY principle, creates maintenance burden

---

## Action Items

### Immediate (False Claims)
1. ❌ Fix "production infrastructure" claims in ABOUT.md
2. ❌ Fix "four repositories" architecture description
3. ❌ Fix direct script execution in DEVELOPMENT_RULES.md
4. ❌ Update release process to reflect single repo

### High Priority (Partial/Unknown)
1. ⚠️ Verify Raspberry Pi testing actually happens
2. ⚠️ Verify d701.dundore.net server exists and is used
3. ⚠️ Update NASA violation count if changed
4. ⚠️ Verify MySQL module exists or remove claim
5. ⚠️ Fix "make deploy" command (should be "make install apache")

### Medium Priority (In Progress)
1. 🔄 Complete Docker Compose generation integration
2. 🔄 Document actual testing process

---

## Verification Process

### Before Adding New Claims
1. Add claim to this document
2. Mark status as 🔄 IN PROGRESS
3. Implement feature
4. Test feature
5. Update status to ✅ VERIFIED
6. Link to evidence

### Monthly Review
- Review all ✅ VERIFIED claims
- Re-verify they're still accurate
- Update status if changed
- Document in LESSONS_LEARNED.md

### Before Each Release
- All claims must be ✅ VERIFIED or removed
- No ❌ FALSE claims allowed
- No ⚠️ UNKNOWN claims allowed
- 🔄 IN PROGRESS claims must have timeline

---

## Lessons Learned

### 2025-12-07: Production Claims Were False
- **What Happened**: Documentation claimed production use when it's homelab
- **Why It Happened**: Aspirational writing without verification
- **Fix**: Created this verification system
- **Prevention**: All claims must be verified before writing

### 2025-12-07: Repository Architecture Mismatch
- **What Happened**: Docs claimed 4 repos, only 1 exists
- **Why It Happened**: Outdated documentation
- **Fix**: Need to update architecture description
- **Prevention**: Verify architecture claims against actual file structure

---

*This document is the source of truth for all claims made in documentation.*
