# Release Checklist

> **HONESTY NOTE 2026-09-13 (D-41/D-43 class):** `make checkpoint` and
> `make verify-install` were removed / never existed; the lines citing them are
> corrected below (`make status` is the real rule). `make release-check` is
> also **no such rule** — a full rewrite of this checklist is scheduled under
> M7 (doc QA program); until then trust only targets you can see in
> `make help`. A doc may assert only what a verifier can prove.

![Ahab Logo](docs/images/ahab-logo.png)

## Pre-Push Validation (MANDATORY)

Run this before every push to dev/prod:

```bash
make test-nasa && make audit
```

## Manual Checklist

### Critical (MUST PASS)
- [ ] `make test-nasa` passes (NASA Power of 10)
- [ ] `make status` passes (control-node report)
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
- Run: `make test-nasa && make audit`
- Commit message: Clear, descriptive
- Tag: Not required

### Main Branch Push (Production)
- Run: `make test-nasa && make audit` (must pass)
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
3. Run `make status`
4. Confirm no errors

## Contact

If stuck: Open issue with:
- Output of `make test-nasa` / `make audit`
- Git log: `git log --oneline -5`
- Error messages
