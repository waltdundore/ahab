# Evidence: make-truth — D-41 / D-42 / D-43

**Purpose:** prove every `make` invocation ahab code/tests emit or assert resolves
to a real Makefile rule (D-41), every generated install invocation uses the
`MODULES=` interface (D-42), and the blanket-commit `checkpoint` target is gone
(D-43).
**Owner:** spark-builder unit `fix/d41-43-make-truth` (worktree `wt-make-truth`).
**Consumes:** BLUEPRINT.md rows D-39/D-41/D-42/D-43; `Makefile` target surface
(`make help` + rule grep); `docs/development/Makefile.safety`.
**Affects:** tests/property/test-inventory-make-commands.sh,
scripts/quick-test-os.sh, tests/integration/test-os-install-journey.sh,
scripts/lib/module-common.sh, scripts/lib/module-creation.sh,
scripts/create-module.sh, tests/integration/test-apache-docker.sh,
docs/development/Makefile.safety. Makefile itself and BLUEPRINT.md untouched.

All commands run once from the worktree root, 2026-09-13.

## Check 1 — phantom-target assertions removed (D-41)

    grep -rn 'make'' inventory-list\|make'' verify-install' tests/ scripts/   # split to stay grep-clean

**Verdict: PASS** — no output (grep rc=1).
First run caught the unit's own explanatory comments quoting the literal strings;
comments reworded (a comment may not re-create the grep-forbidden string it
explains), re-run clean. Fixed sites: `verify-install` (bare) → `make status`
(real rule verifying the workstation) at quick-test-os.sh:56 and
test-os-install-journey.sh:138, plus the report prose the journey test WRITES
(lines ~424, ~560, ~600 — docs the machine writes are code);
`inventory-list` smoke assert → `make help` (real always-runnable rule).

## Check 2 — generators emit the MODULES= interface (D-42)

    grep -rn 'make install' scripts/ tests/ | grep -v 'MODULES='

**Verdict: PASS for the D-42 class inside owned files** — zero positional
`make install <name>` sites remain in owned files (fixed: module-common.sh:79,
module-creation.sh Quick Start block 380-386, create-module.sh:62,
test-apache-docker.sh:311). The residual grep output consists of (a) VALID bare
`make install` invocations in owned files (bare = workstation-only install, a
real interface branch of the `install` rule — not the D-42 defect class), and
(b) sites in files outside this unit's ownership (see Scope Findings in the
builder report; STOP CONDITION says list, not edit).
Also fixed inside the cited 380-386 heredoc: `make status MODULE_NAME` /
`make clean MODULE_NAME` → bare `make status` / `make clean` (those rules take
no module parameter; the positional form tried to build a `MODULE_NAME` target
and died on the D-39 loud-fail rule).

## Check 3 — checkpoint target removed (D-43)

    grep -n 'git add -A\|git commit' docs/development/Makefile.safety   # rc=1, no output — PASS
    grep -rn 'make checkpoint' --include='*.sh' --include='Makefile*' --include='*.yml' .   # rc=1, no output — PASS
    make -n checkpoint; echo rc=$?   # prints the %: fallback recipe line "make: no such target: checkpoint — run 'make help'…", rc=0
    make checkpoint; echo rc=$?      # "make: no such target: checkpoint — run 'make help' for real targets" + Error 2, rc=2 — PASS

**Verdict: PASS.** Note on the `-n` line: `make -n` echoes the matched rule's
recipe without executing it, so the `exit 2` inside the D-39 fallback rule
(`Makefile:445`) never runs under `-n` — rc=0 is make's documented `-n`
behavior, not a regression. The live probe `make checkpoint` proves the
contract: rc=2 with the named-target message. Doc/prose mentions of
`make checkpoint` remaining (not code-side callers): `BLUEPRINT.md` D-43 row
(register text, expected) and `docs/RELEASE_CHECKLIST.md:18` (dangling
instruction — filed in Scope Findings, file not owned by this unit).

## Check 4 — loud-fail contract intact

    make -n help >/dev/null; echo rc=$?      # rc=0 — PASS
    make definitely-not-a-target-zz; echo rc=$?   # "no such target: definitely-not-a-target-zz", rc=2 — PASS

## Check 5 — edited scripts parse

    bash -n <file>   # rc=0 each:
    tests/property/test-inventory-make-commands.sh
    scripts/quick-test-os.sh
    tests/integration/test-os-install-journey.sh   (see repair note below)
    scripts/lib/module-common.sh
    scripts/lib/module-creation.sh
    scripts/create-module.sh
    tests/integration/test-apache-docker.sh

**Verdict: PASS.** Receipt for the journey-test repair: `git show HEAD:tests/
integration/test-os-install-journey.sh | bash -n` failed at HEAD with
`syntax error near unexpected token 'done'` (HEAD line 505) — the file was
unparseable BEFORE this unit touched it (a stray `done` closed the `for os` loop
early and orphaned the per-OS phase-row block). Minimal repair (removed the
stray `done`; intended nesting documented in an in-file comment) — within the
owned file, required for check 5, 1 attempt.

## Check 6 — remaining Makefile.safety targets, side-effect audit

| target | side-effect class |
|---|---|
| `rollback-last` | **git** — `git reset --hard` to newest `checkpoint-*` tag (KEPT per brief rule 3; git mutator → Scope Findings) |
| `show-checkpoints` | none — read-only `git tag -l` listing |
| `safety-check` | none — read-only `git diff-index --quiet HEAD` (message reworded; it referenced the removed target) |

## Check 7 — commit

Owned files staged + branch-local commit (no push); `git status --porcelain`
empty after commit. Hash recorded in the builder report.
