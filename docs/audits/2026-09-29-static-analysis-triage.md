# Static Analysis Alert Triage

**Date**: September 29, 2026
**Scope**: Code-scanning alerts reported against `dev`
**Outcome**: 5 alert classes triaged; safe fixes applied, false positives documented, operator follow-ups listed

---

## Provenance

The operator pasted the alert list into the session on 2026-09-29. GitHub's own
code-scanning API returns `403 Code scanning is not enabled for this repository`,
so the analyzer producing these alerts is **third-party**, not GitHub Code Scanning.
Consequence: ignore/suppression rules cannot be filed from the CLI against the
GitHub API — they must be filed in the third-party analyzer's own UI.

## Verdicts

| Alert | Sites | Disposition |
|---|---|---|
| Weak hash `md5sum` in duplicate detectors | `scripts/ci/check-duplicate-code.sh:71`, `check-duplicate-docs.sh:53` | **Substantively false positive** — the digest is an in-memory dedup key with no security property. Switched to `sha256sum` only because it is zero-risk and silences the class. Verified behaviour-preserving: the scripts keep hashes only in bash associative arrays (`declare -A code_hashes` / `section_hashes`) with all scratch files in a `mktemp -d` directory removed by an `EXIT` trap; no golden/expected/baseline/cache artifact persists the digest, so the switch changes no stored output. Duplicate counts and reported names are identical before and after. |
| "Hashing data is safe here" | `scripts/docs/components/lib/git_analyzer.py:588` | **False positive, left alone deliberately** — `hashlib.md5(repo_url.encode()).hexdigest()` builds a filename slug (`_url_to_cache_key`, consumed at lines 503–504 and 553–554 as `cache_dir/github/<slug>.json` for cached GitHub API metadata). Changing the digest renames the generated cache/doc artifacts for no security gain. |
| Path traversal via LLM-supplied CLI args | `scripts/docs/components/lib/requirements_parser.py:77`, `scripts/generate-docker-compose.py` | **False positive class** — build-time CLIs whose argument *is* a path; there is no privilege boundary between the caller and the file open. Caller grep confirms no untrusted or network-derived path: `parse_file()` is called only from `requirements_parser.py:52` (`discover_all_requirements` walking the repo via `os.walk`), `requirements_parser.py:157` (module `__main__`, operator `sys.argv`), and tests (`test_requirements_completeness.py:127,207,219`; `test_repository_accessibility.py:159` passes a `__file__`-derived project root). `generate-docker-compose.py` is invoked from `Makefile:125,127` (operator `make` line) and `tests/test-docker-compose-generation.sh:141` (hardcoded `TEST_MODULE="apache"`); its `--output` comes from the operator's argparse invocation. No workflow invokes either script with network-derived input. |
| Pip without `--only-binary :all:` / unlocked versions | `.github/workflows/test.yml:25`, `scripts/validators/Dockerfile:22`, `scripts/ci/scan-dependencies.sh:39`, `tests/test-docker-compose-generation.sh` | **Real** — `--only-binary :all:` added at all four sites (forbids executing an sdist's `setup.py` at install time). Versions pinned only where a pin already existed in-repo: `ansible-lint==25.12.2` (`.github/workflows/test.yml:27`). No other exact pin exists anywhere in the repo (`requirements.txt` has none), so no version numbers were invented. Supplying the missing pins belongs to the operator. |
| Redirects not disabled | `scripts/ci/scan-dependencies.sh:90` | **Real** — was `wget -qO - … \| sudo apt-key add -`: the deprecated apt-key mechanism (global trusted keyring injection) plus unbounded redirects on the key download. Now: `wget --max-redirect=1` piped through `gpg --dearmor` into `/usr/share/keyrings/trivy.gpg`, with the apt source line pinned via `deb [signed-by=/usr/share/keyrings/trivy.gpg] …`. |
| "Granting access to others" | 10 sites, all `mode: "0644"`/`"0755"` (`playbooks/install-prerequisites.yml:121,151,227,385`; `playbooks/provision-workstation.yml:112`; `roles/apache/tasks/main.yml:55,64`; `roles/chrony/tasks/main.yml:46`; `roles/php/tasks/main.yml:111,120`) | **False positive** — correct POSIX defaults: `0644` for regular files, `0755` for directories and executables. World-readable is the intended semantics for these installed artifacts. No change made. |

## Operator Actions Required

1. **Analyzer ignore rules** (must be filed in the third-party analyzer's UI, not
   the GitHub CLI/API — see Provenance):
   - Ansible `mode:` keys `0644`/`0755` ("granting access to others").
   - md5/sha usage where the digest is a dedup key or filename slug, not a
     security property.
2. **Missing pip pins**: `ansible-core` (test.yml), `flake8` and `pyyaml`
   (scripts/validators/Dockerfile), `pip-audit` (scan-dependencies.sh), `pyyaml`
   (tests/test-docker-compose-generation.sh). Only `ansible-lint==25.12.2` had an
   in-repo pin to preserve; exact versions for the rest are an operator decision.

## CI Status Note

ahab's CI **does execute** (the scanning pipeline claim that it doesn't is wrong):
`gh run list` shows it running on every push to `dev` and `prod`. However it has
been red for **4 consecutive runs** (prod 2026-09-28T21:36Z and 21:38Z, dev
22:28Z and 23:37Z); the last green run was **2026-09-28T14:58Z**. Root cause is
unestablished. This is tracked ahead of, and separately from, this
static-analysis cleanup.
