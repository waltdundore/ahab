# Branching Strategy - CRITICAL RULES

**Last Updated**: December 8, 2025  
**Status**: Alpha Software (Homelab/Testing)  
**Reason for This Document**: We lost documentation when promoting from prod to dev. This must never happen again.

## Current Reality

**This is alpha software.** We're not using it in production yet. We're:
- Testing in homelabs
- Documenting the process
- Building toward production use
- Learning what works and what doesn't

**But we document as if it's production** because when we DO go to production, the habits will already be there.

## The Problem We Had

On December 8, 2025, we promoted from prod to dev and **lost commits**. Prod had 13 commits that dev didn't have, including:
- Setup verification improvements
- Helpful error messages
- Testing suite enhancements
- Repository cleanup
- Professional release preparation

**This violated our core value of transparency and documentation.**

## The Correct Branching Strategy

### Branch Hierarchy (One Direction Only)

```
dev → prod
```

**NEVER go backwards. NEVER promote prod to dev.**

### What "prod" Means Right Now

**Current**: "prod" = stable alpha for homelab testing  
**Future**: "prod" = actual production use in schools/non-profits

We use production-grade processes NOW so they're habits when we actually go to production.

### Rules (NO EXCEPTIONS)

1. **All development happens on `dev`**
   - New features → dev
   - Bug fixes → dev
   - Documentation → dev
   - Everything → dev

2. **Promotion is ONE WAY ONLY: dev → prod**
   ```bash
   # CORRECT
   git checkout prod
   git merge dev
   git push origin prod
   
   # WRONG - NEVER DO THIS
   git checkout dev
   git merge prod  # ❌ FORBIDDEN
   ```

3. **If prod has commits dev doesn't have, YOU MADE A MISTAKE**
   - Stop immediately
   - Figure out what went wrong
   - Cherry-pick those commits to dev first
   - Then promote dev to prod

4. **Before ANY promotion, verify:**
   ```bash
   # Check what's in prod that's not in dev
   git log dev..prod
   
   # If this shows ANY commits, STOP
   # Those commits will be lost if you promote dev to prod
   ```

## Why This Matters

### Our Core Values
1. **Transparency** - We document everything
2. **Bug-Free Software** - We test everything
3. **Student Achievement First** - We don't waste time redoing work

**Losing commits violates all three values.**

### What We Lost (December 8, 2025)
- Setup verification and error messages (user experience)
- Testing suite improvements (quality)
- Repository cleanup (professionalism)
- Documentation (transparency)

**This is unacceptable.**

## Emergency Recovery Procedure

If you realize prod has commits dev doesn't have:

```bash
# 1. List what's in prod but not dev
git log dev..prod --oneline

# 2. Cherry-pick each commit to dev
git checkout dev
git cherry-pick <commit-hash>
git cherry-pick <commit-hash>
# ... for each commit

# 3. Test everything
make test

# 4. Push to dev
git push origin dev

# 5. NOW you can promote dev to prod
git checkout prod
git merge dev
git push origin prod
```

## Pre-Promotion Checklist

Before promoting dev to prod:

- [ ] Run: `git log dev..prod`
- [ ] Verify output is EMPTY (no commits)
- [ ] If not empty, STOP and cherry-pick those commits to dev first
- [ ] Run: `make test` on dev
- [ ] Run: `make release-check` on dev
- [ ] Verify all tests pass
- [ ] Update CHANGELOG.md
- [ ] Tag the release
- [ ] THEN promote to prod

## Why We Have This Problem

**Root cause**: Someone committed directly to prod instead of dev.

**Prevention**:
1. NEVER commit directly to prod
2. NEVER push directly to prod
3. ALL work happens on dev
4. Prod is ONLY updated via merge from dev

## Enforcement

This is not a suggestion. This is a **MANDATORY** rule.

**Penalty for violation**: 
1. Stop all work
2. Document what was lost
3. Recover the lost commits
4. Add this incident to LESSONS_LEARNED.md
5. Update this document with what went wrong

## Testing This Strategy

To verify you understand:

```bash
# 1. Check current branch
git branch

# 2. Check if prod has commits dev doesn't
git log dev..prod

# 3. If output is NOT EMPTY, you have a problem
# 4. Fix it before promoting
```

## Summary

**Simple rule**: 
- Development → dev
- Release → prod (via merge from dev)
- NEVER go backwards

**If prod has commits dev doesn't have, you broke the rule.**

---

**Transparency Note**: This document exists because we made a mistake. We document our mistakes so we don't repeat them. This is how we maintain quality and trust.
