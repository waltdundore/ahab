# Evidence — ahab estate hygiene (Makefile variants + MODULE_REGISTRY truth-rewrite)

Date: 2026-09-11. Builder pass per BLUEPRINT D-16/D-17/D-18 + "git estate full
probe" + "ahab working-tree hygiene FAIL" rows; design authority SPEC.md §3.0/§3.1.
File edits only; zero git write operations (read-only git used for proof).

## 1. Makefile variant deletions (D-18)

Enumerated via `git -C ahab ls-files 'Makefile*'` (root-level only; 9 tracked,
1 primary). Per-file history proof (`git log --oneline -1 -- <file>`) — all
non-empty, so git history keeps every deletion ("trust but verify"):

| Deleted file | git log proof line |
|---|---|
| Makefile.backup-before-test-unit-fix | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.backup-broken | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.bak2 | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.common | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.config | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.network-switches-refactored | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.original | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |
| Makefile.refactored-example | `a82d0de Clean branch: Remove all fake secret patterns for GitHub publishing` |

Method: plain `rm` (never `git rm`).
Final `ls ahab/Makefile*` → exactly one line: `Makefile`.

Primary-Makefile minimal edit: `include Makefile.common` (line 9) referenced a
deleted variant → replaced by one comment line citing D-18. Its macros
(HELP_HEADER/HELP_FOOTER/SHOW_SECTION) expand empty; `make -n help` exits 0.

Known collateral (reported, untouched — out of ownership): `config/Makefile`
and `inventory/Makefile` each `include ../Makefile.config` +
`../Makefile.common` (lines 14–15) — now dangling. Docs still citing variant
names: docs/MAKEFILE_CONFIG_DRY_FIX.md, docs/REPOSITORY_CLEANUP_2025-12-08.md,
docs/architecture/SAFETY_AUDIT.md, scripts/ci/check-shared-libraries.sh
(advise-only echo text), tests/property/test-shared-library-usage.sh.

## 2. MODULE_REGISTRY.yml truth-rewrite (D-17, SPEC §3.0/§3.1)

- Registry v1.0 named 9 per-module repos; estate probe: 8 never existed
  (`ahab-module-{apache,php,mysql,postgresql,nginx,redis,wordpress,nextcloud}`
  — estate row "DO NOT EXIST … fiction → delete from MODULE_REGISTRY.yml").
  All repository/documentation URLs to these repos removed.
- `docker` entry dropped entirely; retirement recorded in a YAML comment
  citing D-17 (`ahab-module-docker` = stale copy of `ahab-module-common`,
  ships no docker role). Real `modules/docker/` to be authored per SPEC §3.1.
- Design header rewritten to directory-based modules
  (`modules/<name>/module.yml`, SPEC §3.1); repo-per-module retired.
- 8 surviving catalog entries keyed `status: planned` (none has
  `modules/<name>/module.yml` on disk — `ahab/modules/` is empty, verified
  `ls`). `apache`/`php` downgraded stable→planned: their "stable" status
  pointed at repos that never existed; real apache module.yml lives in the
  uncloned `ahab-modules` repo pending absorption per SPEC §3.0.
- No entry references any per-module repo. Remaining `ahab-module-docker` /
  `ahab-module-common` strings exist ONLY inside the D-17 removal-note comment.
- Verification: `python3 yaml.safe_load` → `<class 'dict'> 1`; entries =
  apache, mysql, nextcloud, nginx, php, postgresql, redis, wordpress; all
  status==planned; regex scan for repo refs in entries = none.

## 3. Check outputs (each run once)

1. `git ls-files 'Makefile*'` → 9 tracked; 8 deletions each preceded by
   non-empty `git log --oneline -1`; `ls Makefile*` → `Makefile` (1 line). PASS
2. `make -n -C ahab help` → exit 0 (help target defined in primary Makefile). PASS
3. `python3 -c "import yaml; …"` → exit 0, `<class 'dict'> 1`. PASS
4. `git status --porcelain` → see builder report; contains only in-scope
   deletions + ` M MODULE_REGISTRY.yml` + ` M Makefile` + `?? evidence/` +
   PRE-EXISTING `M  .test-status` and ` M BLUEPRINT.md` (both untouched here —
   BLUEPRINT.md was already modified before this pass began). PASS-with-note
