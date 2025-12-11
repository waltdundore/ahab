# Release Notes - v0.1.1

![Ahab Logo](docs/images/ahab-logo.png)

**Release Date**: December 8, 2025  
**Status**: Development Release (Pre-1.0)

## Critical Bug Fixes

### 1. Vagrant Timeout Protection (NASA Rule 2 Compliance)

**Problem**: Vagrant commands (`vagrant up`, `vagrant ssh`) had no timeout. If Vagrant hung (which it often does), the entire script would hang forever, forcing users to manually kill the process.

**Impact**: 
- Users running `make test` or `make install` could experience infinite hangs
- Violated NASA Power of 10 Rule 2 (all operations must have fixed upper bounds)
- Poor user experience, violated our empathy principle

**Fix**:
- Added `vagrant_with_timeout()` wrapper function in `tests/lib/test-helpers.sh`
- All vagrant commands now have 600-second (10-minute) timeout
- Provides helpful error messages on timeout with troubleshooting steps
- Applied to all test scripts: `test-workstation.sh`, `test-apache-e2e.sh`, `test-workstation-apache.sh`

**Files Changed**:
- `tests/lib/test-helpers.sh` - Added timeout wrapper
- `tests/e2e/test-workstation.sh` - Applied timeout
- `tests/e2e/test-apache-e2e.sh` - Applied timeout  
- `tests/e2e/test-workstation-apache.sh` - Applied timeout

### 2. Empathy Audit Rewrite

**Problem**: The accountability audit was measuring "empathy" by checking for keywords like "frustrating" and "I know" instead of measuring whether error messages were actually helpful.

**Impact**:
- Encouraged performative empathy (adding "I know this is frustrating" to pass audit)
- Missed the real goal: providing actionable guidance
- False positives/negatives based on word choice

**Fix**:
- Rewrote `audit_empathy()` function to measure helpfulness:
  1. Clear message - What went wrong?
  2. Actionable guidance - What can I do about it?
  3. Context - Why did this happen?
  4. No blame - Avoid dismissive language
- Now checks for actual helpful content (commands to run, links, specific steps)
- Removed dismissive language ("just", "simply") from code

**Files Changed**:
- `scripts/audit-accountability.sh` - Rewrote empathy audit
- `scripts/audit-self.sh` - Removed "just"
- `tests/integration/test-apache-docker.sh` - Removed "just"

## Documentation Improvements

### 3. Development Workflow Documentation

**Problem**: Development was happening in IDE/virtual environments instead of on the actual workstation VM. This meant we weren't testing in the real environment users would use.

**Impact**:
- Code that worked in IDE might fail on workstation
- Not eating our own dog food
- Missing environment-specific issues

**Fix**:
- Added ABSOLUTE RULE #0 to DEVELOPMENT_RULES.md: "Develop on the Workstation, Not Virtually"
- Added `make sync-to-workstation` and `make sync-from-workstation` commands
- Documented correct workflow: SSH into workstation, make changes, test there
- Enforces using the tools we're building

**Files Changed**:
- `DEVELOPMENT_RULES.md` - Added Rule #0 and workflow
- `Makefile` - Added sync commands

### 4. Fixed Broken Documentation Sync

**Problem**: Root Makefile was copying `index.html` from untracked root directory to git repo. This was backwards and fragile.

**Fix**:
- Removed `index.html` from sync-docs target
- `index.html` already exists in ahab git repo
- No need to copy from workspace

**Files Changed**:
- Root `Makefile` - Removed index.html sync

## Test Results

All tests passing:
- ✅ `make test` - PASSED
- ✅ `make test-nasa` - PASSED (NASA Power of 10 compliance)
- ✅ `make release-check` - PASSED
- ✅ No uncommitted changes
- ✅ No audit reports in repo

## Lessons Learned

1. **External commands need timeouts** - Not just loops. Any command that can hang indefinitely violates NASA Rule 2.

2. **Empathy = helpfulness** - Real empathy means providing actionable guidance, not using sentiment keywords.

3. **Work in the real environment** - Develop on the workstation VM, not in IDE. Test where users will actually run the code.

4. **Verify what's in git** - Don't assume files exist based on code references. Check `git ls-files`.

5. **Transparency requires publishing process** - Document our release process, bugs found, and fixes applied.

## Upgrade Instructions

For existing users:

```bash
cd ahab
git pull origin dev
make test  # Verify everything works
```

No breaking changes. All existing workflows continue to work.

## Alpha Software Notice

**This is alpha software for homelab/testing use.**

We're not using this in production yet. We're:
- Testing in homelabs
- Documenting the process  
- Building toward production use
- Learning what works

**Use at your own risk.** Expect bugs. Report issues. Help us make it better.

## Known Issues

None blocking alpha release.

Warnings (non-blocking):
- Some scripts >500 lines (consider refactoring)
- Potential unquoted variable in ssh-terminal.sh (manual review recommended)
- This is alpha - expect rough edges

## Contributors

- Development and testing done following NASA Power of 10 standards
- All changes reviewed through accountability audit system
- Self-auditing system validated compliance before release

## Next Steps

After release:
1. Monitor for timeout issues in production
2. Gather feedback on error message helpfulness
3. Continue improving test coverage
4. Document more workflows on workstation

---

**Transparency Note**: This release process is documented to show our commitment to quality, accountability, and continuous improvement. We believe in showing our work, including bugs found and how we fixed them.
