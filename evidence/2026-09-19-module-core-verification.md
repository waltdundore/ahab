# Module + Core Verification (AWX + local gates) — 2026-09-19

Purpose: operator-directed verification — "test every ahab module is working;
use AWX to verify each and every module and the core all work correctly."
Owner: pi PM session (gx10-741d), operator wdundore.
Consumes: ahab @ `bba0421` (prod), dundore-homelab working tree (prod,
unpushed ahead of origin per pre-verification state), waltdundore/ahab-modules
(shallow clone, read-only, `/tmp/ahab-modules-check`), AWX 24.6.2.dev881 at
`hub.dundore.net:8043` (REST, `ahab-pm`).
Affects: nothing mutating — check-mode only; no AWX apply-template was run;
no ahab files changed by this verification except this document. Note:
`make test` updated `.test-status` via its designed `record-test-pass.sh`
bookkeeping (not committed).
Method note: AWX via REST basic-auth (`ahab-pm`; password from
`/nas/secrets/awx/ahab-pm.password`, 0600, never printed). Job 131 = launch
of template #10 (`l4-baseline-converge`, `job_type=check`, `limit=d701`) —
the template's own DRY-RUN path, identical to the human command per
dundore-homelab `Makefile` baseline target. Local gates run in ahab:
`check-prerequisites`, `test`, `audit`; property tests run directly.
Verdict cells ∈ {OK, FINDING, N/A}.

## Verdict table

| Area | Verdict | Evidence |
|---|---|---|
| apache module (only module that exists) | OK | `make test` integration leg: HTTP 200 on :8080, clean teardown |
| php/mysql/postgresql/nginx/redis/wordpress/nextcloud | N/A — planned | registry `status: planned` ×8; ahab-modules holds only `apache/module.yml` |
| `make check-prerequisites` | OK | all required tools (curl 8.15.0, vagrant-libvirt 0.11.2, docker group) |
| `make test` (NASA Po10 + security + integration) | OK | "All Tests Passed"; record-test-pass @ `bba0421` |
| `make audit` | FINDING | self-audit: `audit-accountability.sh: Missing empathetic language` → Error 1 |
| property suite (12 tests; not in `make test`) | FINDING | 12/12 fail when run directly (detail below) |
| AWX #10 l4-baseline-converge (check-mode) | FINDING — controller-side | job 131 never started (forensics below) |
| identical-command human path (`make baseline BASELINE_HOST=d701`) | OK | PLAY RECAP ok=28 changed=3 failed=0 unreachable=0 |
| AWX inventory #2 / project #7 | OK | 13 hosts (12 enabled); homelab @ branch `prod`, sync status successful |

## Module inventory

- ahab `MODULE_REGISTRY.yml` (v2.0, 2026-09-11): 9 entries, **all
  `status: planned`**; `modules/` empty — submodule
  `waltdundore/ahab-modules` never initialized locally.
- ahab-modules (shallow clone, read-only): **exactly one module** —
  `apache/module.yml` (docker `httpd:2.4`, `8080:80`, `./html` ro volume,
  `dependencies: []`).
- Bottom line: **1 of 9 modules exists; apache is behaviorally verified**
  (serves a test page, asserts HTTP 200, tears down clean). The other 8 are
  catalog intent per the registry's own key definition (`planned` = no
  module.yml on disk yet).

## AWX forensics — job 131 (launched 2026-09-19)

- Template #10 config: `job_type=check`, `limit=d701`,
  `playbook=playbooks/provision.yml`, inventory 2, project 7,
  `execution_environment=None` (runs 120/124 on 2026-09-14 used EE 1).
- Job 131 result: `status=failed`, `started=None`, `elapsed=0.0`,
  `scm_revision=''`, `execution_environment=None`, **job_events count = 0**,
  stdout empty (`{"range":{"start":0,"end":0,"absolute_end":0},"content":""}`).
- History on #10: 71/78 failed (09-12), 113/120 successful (09-14),
  124 failed (09-14), 131 failed (09-19).
- AWX instance: 1, enabled, heartbeat fresh at probe time.
- Interpretation: job sat pending ~17 min then failed **without ever
  starting** — the dispatcher/task layer failed, not the playbook. The
  playbook path itself is green via the identical human command (below).
  Operator action on asus-llm (awx_task / EE image pull) or re-bind EE 1 on
  template #10 and relaunch.

## Identical-command human path (control)

`cd dundore-homelab && make baseline BASELINE_HOST=d701` — check-mode
hard-coded (`--check --diff`, "L4 DRY RUN (never applies)"):

```
PLAY RECAP
d701 : ok=28  changed=3  unreachable=0  failed=0  skipped=7
```

The 3 changes are expected identity drift: hostname
`dev.dundore.net → prod.dundore.net`, the matching `/etc/hosts` line
(10.200.10.15 → 10.200.10.10), +1 — see run output. Converge logic and
`roles/base` execute cleanly end-to-end in check mode. **The AWX failure is a
controller defect, not an ahab/homelab code defect.**

## Local gate findings (detail)

1. `make audit` — SELF-AUDIT FAIL: `audit-accountability.sh: Missing
   empathetic language` (Makefile:322, Error 1). The accountability gate
   fails on its own script's marker text; no report file was generated
   (failure precedes report write).
2. Property suite (`tests/property/`, 12 tests; **not** in the `make test`
   chain): 12/12 fail when run directly:
   - `test-credential-file-naming`: `print_header: command not found` (helper
     import drift — defined in `scripts/lib/common.sh` / `audit-common.sh`,
     not sourced)
   - `test-parnas-principle`: `ahab.conf not found at
     tests/lib/../../../ahab.conf` (ahab.conf exists nowhere in the repo)
   - `test-root-container-detection`: `line 582: $1: unbound variable`
     (`set -u`)
   - remaining 9: fail on their own Test 1 self-case
   ⇒ suite is stale/broken but sits outside the official gate — either fix
     the harness or wire it into `make test`.

## Open items (recommendations — nothing changed by this verification)

1. AWX (operator, asus-llm): inspect task dispatch (job 131: 0 events,
   `started=None`); alternative — re-bind EE 1 on template #10 and relaunch.
2. Unit: `make audit` self-audit failure (empathetic-language marker missing
   from `audit-accountability.sh`).
3. Unit: property suite harness (helper import, ahab.conf path, `set -u`) —
   or wire the suite into `make test`.
4. Unit: `git submodule update --init` for `modules` (ahab-modules) and
   `config-roles` (ahab-config); registry note already anticipates absorbing
   apache from ahab-modules into `modules/apache/`.
5. Fleet note: gx10-6ca0 measured 24.8 prefill / 3.84 gen tok/s vs
   gx10-741d 729.3 / 7.7 and admins-macbook-pro 204.9 / 13.2 (same
   Qwen3.8-27B Q8, 4061-token prompt, 2026-09-19) — inspect llama.cpp
   startup flags on 6ca0 (suspected CPU fallback); 6ca0 currently carries no
   agent work.

## Reproduce

```bash
# AWX (password file is 0600, never print it)
AUTH="ahab-pm:$(cat /nas/secrets/awx/ahab-pm.password)"
curl -sk -u "$AUTH" https://hub.dundore.net:8043/api/v2/me/
curl -sk -u "$AUTH" -X POST -d '{}' https://hub.dundore.net:8043/api/v2/job_templates/10/launch/
curl -sk -u "$AUTH" https://hub.dundore.net:8043/api/v2/jobs/<id>/
curl -sk -u "$AUTH" -H 'Accept: application/json' https://hub.dundore.net:8043/api/v2/jobs/<id>/stdout/

# local gates
cd /home/wdundore/git/ahab
make check-prerequisites && make test && make audit
bash tests/property/test-*.sh   # currently red (see findings)

# identical-command control (check-mode, never applies)
cd /home/wdundore/git/dundore-homelab
make baseline BASELINE_HOST=d701
```
