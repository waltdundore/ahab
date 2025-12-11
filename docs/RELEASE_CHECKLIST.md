# Release Checklist

![Ahab Logo](docs/images/ahab-logo.png)

## Pre-Push Validation (MANDATORY)

Run this before every push to dev/main:

```bash
make release-check
```

## Manual Checklist

### Critical (MUST PASS)
- [ ] `make test-nasa` passes (NASA Power of 10)
- [ ] `make verify-install` passes (VM works)
- [ ] `make checkpoint MSG="pre-release"` succeeds
- [ ] No uncommitted changes (`git status`)
- [ ] All audit reports deleted
- [ ] No temp/test files in repo

### Important (SHOULD PASS)
- [ ] `make audit` passes (accountability)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped if needed

### Nice to Have
- [ ] Tests pass (if Docker available)
- [ ] README reflects changes
- [ ] Examples work

## Release Types

### Dev Branch Push
- Run: `make release-check`
- Commit message: Clear, descriptive
- Tag: Not required

### Main Branch Push (Production)
- Run: `make release-check`
- Run: `make audit` (must pass)
- Tag: Required (v0.x.x)
- CHANGELOG: Required
- Documentation: Required

## Emergency Push

If you must push without full validation:

```bash
# Document why in commit message
git commit -m "EMERGENCY: [reason]

Skipped: [what was skipped]
Risk: [what could break]
Plan: [how to fix]"
```

## Rollback Plan

If push breaks something:

```bash
# Local rollback
make rollback-last

# Remote rollback (if pushed)
git revert HEAD
git push origin dev
```

## Post-Push Verification

After pushing:
1. Pull on another machine
2. Run `make install`
3. Run `make verify-install`
4. Confirm no errors

## Contact

If stuck: Open issue with:
- Output of `make release-check`
- Git log: `git log --oneline -5`
- Error messages
