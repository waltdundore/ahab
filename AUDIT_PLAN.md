# AUDIT_PLAN — Program Audit: SHOULD vs Provable Reality

> **PURPOSE:** Determine what the project SHOULD look like (per its own laws and docs)
> vs what can currently be tested, proven, audited, and verified — and pick the next
> focus area that shows real progress.
> **OWNER:** PM (operator) + audit session. Findings land in `ahab/BLUEPRINT.md`
> registers (D/B/N) and per-repo evidence; this file is the plan, not the record.
> **CONSUMES:** BLUEPRINT.md (laws, registers), dundore-homelab docs (README,
> CONTEXT, ONBOARDING, gitops canon), recon evidence 2026-09-16 (inline below).
> **AFFECTS:** ahab, dundore-homelab, dundore-dnscontrol, aitora, geekend, dgx-spark,
> banking, template — every doc claim, every milestone, every deprecated integration.
> **STATUS:** DRAFT pending operator rulings (§7). Supersedes no law; canon wins.
> **DATE:** 2026-09-16

---

## 0. Verification classes (what CAN be proven from where)

Per `dundore-homelab/docs/ONBOARDING.md` machine profiles, every audit item gets a
class. An item is **proven** only at the class its claim requires:

| Class | Vantage | Can prove |
|---|---|---|
| **B** — Box (this Mac, profile B) | Git + Vagrant + GitHub only. No fleet SSH, no vault password, no /nas, no LAN. | Repo state, branch law, doc-vs-code consistency, lint/law-gate, **Vagrant-fedora43 gates** (M4 Max runs VirtualBox/libvirt fine) |
| **A** — Fleet (sager/d701, profile A) | Control node with `keys/service_id`, vault pass, /nas, LAN. | Live probes: kuma via SSH tunnel, dig, docker ps, `ansible --check`, AWX/Gitea state |
| **O** — Operator only | Console, registrar, 1Password, remote-ref deletion. | Hub console access, Namecheap, `git push --delete` on stale remote trunks |

**Evidence ladder (unchanged):** `UNVERIFIED → LIVE-PROBED → AUDITED`.
**Ruling needed (R-1):** `spark-auditor` was an opencode subagent. Post-opencode,
AUDITED must mean: a documented audit run (agent or human) with evidence file, auditor
named in the evidence header, findings reconciled in the register. The *role* is
tool-agnostic; only the *tooling* is deprecated.

**Pre-seeded findings (recon 2026-09-16, class B, all verified on disk):**

| ID | Finding | Evidence |
|---|---|---|
| F-01 | `dundore-homelab/README.md` has **5 unresolved merge-conflict blocks** (lines 128, 134, 271, 273, 389) — the entrypoint doc is self-contradictory | `grep -n '<<<<<<<' README.md` |
| F-02 | `ahab/modules/` **empty**, `ahab/sites/` **absent**, `ahab/config-roles/` **empty** — SPEC §2–§4 design exists only on paper | `ls` |
| F-03 | `ahab/MODULE_REGISTRY.yml` is 2024-vintage, points at 8 phantom `ahab-module-*` repos (SPEC §3.0 already proves them fiction) | `head MODULE_REGISTRY.yml` |
| F-04 | `dundore-homelab/dns/` = tracked **symlink** while `.gitmodules` declares it a submodule — fresh clone is broken (violates symlink law) | `ls -la dns; cat .gitmodules` |
| F-05 | `dundore-homelab/todo.md` **does not exist** yet README §1/§12/§13 and CONTEXT §5 name it the canonical work-item store | `ls` |
| F-06 | `dgx-spark` repo sits on retired trunk `production` (branch law 2026-09-10: trunk ∈ {prod, dev}); `geekend` on a feature branch; `aitora`/`ahab`/`homelab` on `prod` clean | `git status -sb` × 4 |
| F-07 | `state/agents.json`: 7 agent sessions, **all stale**, all opencode-era | `cat state/agents.json` |
| F-08 | `.opencode/plans/pending/refactor_…_f897/implementation.md` = **live resume-truth** (Phases 0–1 done, 2–5 pending) stored inside the deprecated tool's dir | `head implementation.md` |
| F-09 | `bin/law-gate.sh` exists, runs in CI, first run caught real misses — the one law with teeth today | `bin/law-gate.sh` |
| F-10 | `ahab` HEAD is docs-only (canon pointers); no M1 code has landed since the SPEC draft | `git log --oneline -3` |

---

## 1. Phase 1 — Doc-truth audit (SHOULD vs CAN, per repo)

**Method.** For each doc: extract every *claim* (machine, service, status, command,
path, branch, version) → classify (law / design / status / evidence) → verify at the
lowest class that can falsify it (B first; A/O queued) → record result.
**Output:** one findings table per repo, each row: `ID | doc:line | claim | SHOULD |
actual | class | evidence | status`. Files: `dundore-homelab/docs/audits/doc-truth-2026-09-16.md`,
`ahab/docs/audits/doc-truth-2026-09-16.md`.

| ID | Work item | Class | Notes |
|---|---|---|---|
| P1-1 | **Resolve F-01** — pick the conflict side that matches code (`playbooks/`, `roles/`, `ci.yml` as authority), delete the other, re-read §4/§13 for coherence | B | Highest-urgency hygiene; blocks trusting the README at all |
| P1-2 | `CONTEXT.md` §1–§6 vs reality: §6 "current block" predates the 2026-09-11 enforcement commit (dfdaaab) — regenerate | B | |
| P1-3 | **Ruling R-5:** resurrect `todo.md` or formally retire it (BLUEPRINT demotes it to generated view; if retired, strip the references from README/CONTEXT/ONBOARDING) | B | F-05 |
| P1-4 | ahab two-era split: 2024–25 K-12-era docs (README.md K-12 sections, GEORGIA_STANDARDS_VERIFICATION, GITHUB_PAGES_STATUS, ahab-gui refs, per-module-repo fiction) vs 2026 control-repo era (SPEC, BLUEPRINT). Per file: **keep / archive to `docs/archive/` / rewrite**. `MODULE_REGISTRY.yml` → delete phantom entries (SPEC §3.1 already decided) | B | F-02, F-03 |
| P1-5 | `BLUEPRINT.md` ledger hygiene: duplicate **D-16** IDs (repo-estate *and* SELinux both numbered D-16 — register integrity bug); B-002 sager-half closed but table still reads as open; live-probed facts vs 2026-09-16 recon | B | Master record must be cold-trustworthy |
| P1-6 | Run `bin/law-gate.sh --workspace` from Mac; capture output as evidence; diff gate checks vs canon §1–§4 — which laws are unenforced and why (register the gap, don't silently skip) | B | F-09 |
| P1-7 | Cross-repo claim sweep: every doc in both repos that names a branch, host, IP, service, or version → match against F-table + git state. Includes `docs/ONBOARDING.md`, `docs/BOOTSTRAP.md`, `docs/standards/*`, ahab `docs/architecture/*`, `docs/audits/*` (stale audits get "superseded-by" headers, not deletion) | B | |
| P1-8 | Estate snapshot: all 8 local repos — trunk name, origin sync, dirty state, stale remote branches. Baseline evidence file `docs/evidence/estate-2026-09-16.md` in each affected repo | B | F-06 |
| P1-9 | Fleet-side doc claims (kuma hosts, AWX, Gitea init, vLLM model served, NetBox state) → **queue for profile A** with exact probe commands written now so the fleet session executes a script, not an investigation | A | |

**Exit:** every doc claim in scope is either (a) verified at class B, (b) queued class
A/O with commands ready, or (c) struck from the doc. No claim left `UNVERIFIED`
silently.

---

## 2. Phase 2 — Deprecated agent-workflow retirement (opencode → whatever-is-now)

**Principle:** the *tool* is deprecated; the *content* may not be. Every artifact gets
a disposition: **MIGRATE** (content lives on, new home), **RETIRE** (dead, delete,
git-history is backup), **QUEUE** (needs fleet fact or operator ruling).

**Ruling needed (R-2):** name the current tool of record (agent harness + MCP
posture) so docs reference *it*, not opencode, and so "agent-native workflow" claims
in docs are either true or deleted.

| ID | Artifact (recon-verified) | Disposition | Class |
|---|---|---|---|
| P2-1 | **`.opencode/plans/pending/refactor_…_f897/`** — live resume-truth (F-08) | **MIGRATE first, before any other deletion** → `dundore-homelab/plans/` (tool-neutral, tracked). Update CONTEXT §6 + ONBOARDING to point there | B |
| P2-2 | `.opencode/skills/` × 8 (ansible-baseline, deploy-qwen-dgx, kuma-monitor, netbox-sync, openbao-secrets, postgres-state, vagrant-lab, yaml-lint) | Per skill: does a role/doc already own the knowledge? Yes → **RETIRE** the skill (knowledge is in `roles/`/docs; skill was a cache). No → **MIGRATE** the unique content to `docs/runbooks/`. Decision table in the audit file | B |
| P2-3 | `.opencode/node_modules/`, `package.json`, `package-lock.json`, `.gitignore` | **RETIRE** (tool scaffolding; check .gitignore entries survive in a repo-level .gitignore) | B |
| P2-4 | `mcp/fleet_state/server.py` + README §7 MCP section | **RETIRE** if O-05 deps never land (README says `enabled: false` since declaration — verify no consumer) — *but see P2-6 for its data producer* | B |
| P2-5 | `state/agents.json` (F-07: all stale, writer extinct) | **RETIRE** + drop from docs; `state/` keeps only live schemas (status.json per O-02) | B |
| P2-6 | `roles/state_watch` + `scripts/state-watcher` + `setup-state-watch.yml` | Consumer check: only fleet_state MCP consumed the output? If yes → **QUEUE** (retire) *or* operator repurposes events.jsonl for the flame pane-of-glass — ruling R-6 | B/A |
| P2-7 | **P4-01 opencode fleet key** (`distribute-key.yml` default list, `verify-opencode-key.yml`, 0/9 verified) | If rollout never completed → remove key from role defaults + **RETIRE** both plays. If partially deployed (keys in some `authorized_keys`) → write removal play, **QUEUE** fleet execution. Audit doc `docs/audits/opencode-key-rollout-2026-08-24.md` says how far it got — read first | B→A |
| P2-8 | `roles/opencode_config` + template (README: DRIFTED, O-06) | **Ruling R-4:** LLM fleet's current client. If opencode was the sole consumer → role is dead → **RETIRE** (DGX vLLM stack stays if R-4 says it still serves a live client — e.g., this harness, LM Studio, or a new app) | B |
| P2-9 | `deploy-uptime-kuma-mcp.yml` + `roles/uptime_kuma_mcp` + `roles/dnscontrol/tasks/kuma_audit.yml` opencode refs + `scripts/kuma_monitor.py` consumer chain | Kuma *monitoring* stays (law 2); the *MCP* leg dies with P2-4. Split them in the docs/roles | B |
| P2-10 | Doc sweep: `grep -rn 'opencode\|fleet_state\|fleet-state\|mcp'` across both repos (28+ files hit at recon) → every hit: delete section, replace with current-tool wording (R-2), or mark archived. `pre_audit.md`, ledgers, ONBOARDING, BOOTSTRAP, BLUEPRINT, ahab docs included | B | Gate: grep returns only `docs/archive/` hits |
| P2-11 | `ahab/docs/developer/*`, `ahab/docs/cybersecurity/*` — any agent-tool-specific instructions | Same sweep | B |

**Exit:** `grep` gate passes (P2-10); f897 plan lives in `plans/` and is cited by
CONTEXT/ONBOARDING; zero references to a tool that is no longer the workflow; fleet
side (P2-7 removal play, P2-6) queued with exact commands for profile A.

---

## 3. Phase 3 — Roadmap verification & next-focus decision

**Method.** For each milestone M0–M6 (BLUEPRINT) and SPEC phase P1–P7: re-derive
status from *evidence only* (F-table + Phase 1/2 outputs + cited evidence files),
mark `BLOCKED` with the blocking ID, and compute the **minimum evidence set** to
close it. Then score candidate focus areas on: (1) progress visible in ≤ 1 week,
(2) unblocking value (how many downstream milestones it releases), (3) provability
from class B (this Mac), (4) dependency on operator unlocks.

**Pre-scored candidates (verify in Phase 3, don't assume):**

| Candidate | Progress visible | Unblocks | Class-B provable? | Blocked by |
|---|---|---|---|---|
| **A. M1/P4: ahab control skeleton — directory modules + L0 bootstrap extraction, Vagrant-gated** (SPEC §2–§3; `ahab/modules/bootstrap/` from homelab `bootstrap`+`base`+`fedora-baseline`; registry rewrite; D-18 Makefile purge) | High — "blank fedora43 box → full L0 from Git alone" is the flagship dogfood proof, and the 2026-09-09 Vagrant gate evidence shows it works on this machine class | M2 (submodules/fresh-clone), M3 (NetBox SSoT), M4/M5 (site plug-ins), P5, P7 | **Yes** — Vagrant runs here (F: both Vagrantfiles exist; M4 Max) | **R-3 (license)** per BLUEPRINT B-011: M1 merge work is gated on relicense to OSI (Apache-2.0 recommended) |
| B. P7/§5.5: GitOps deploy path (AWX webhook → converge blank host) | Very high when done | Everything operational | **No** — B-001/B-014 (AWX down, port unexposed, hub unmanaged) + Gitea uninitialized | O-class (console) |
| C. M0: monitoring lattice completion (kuma legs, pi voter, public status page + hospitality-law UX review) | Medium | Law 2 compliance | **No** — fleet-side | B-003 unblocked but fleet-executed |
| D. Doc cleanup + opencode retirement (Phases 1–2 of THIS plan) | Medium (hygiene, not capability) | Trust in every other artifact | **Yes** | Rulings R-1…R-6 |

**Working recommendation (confirm in Phase 3):**
**Sequence D → A → then fleet (B/C).** Do the cleanup first (1–2 days, class B,
makes the docs true and frees the registers), then spend the visible-progress budget
on **Candidate A**: extract `modules/bootstrap` with Vagrant evidence, rewrite the
registry, purge Makefile forks, close the SPEC draft (operator review = this
audit's rulings). That is the one milestone that (a) is the dogfood law itself,
(b) is fully provable from this Mac, and (c) is the root of the M2→M6 dependency
tree. Fleet candidates B/C line up behind the operator unlocking the hub (B-001)
and initializing Gitea — both O-class, both independent of Mac work.

**Output:** updated milestone table (status/evidence/blocked-by) committed as a
BLUEPTR diff; this file's §3 replaced by the verified table.

---

## 4. Program-level exit criteria (when the audit is "done")

1. Every doc claim: verified (B), queued (A/O with commands), or struck. No silent UNVERIFIED.
2. `grep` gate for deprecated tooling passes (P2-10).
3. f897 plan migrated; CONTEXT §6 regenerated; todo.md ruling executed (R-5).
4. BLUEPTR registers: duplicate IDs fixed; statuses match evidence; every open
   blocker has an unlock owner (B/A/O).
5. `bin/law-gate.sh --workspace` green from class B, output committed as evidence.
6. Estate snapshot: all 8 repos on legal trunks (`dgx-spark production→prod`,
   `geekend` feature-branch disposition) or formally parked with a note (F-06).
7. Fresh-clone test queued for class A: `git clone --recursive` → law-gate +
   Vagrant gate green (the GitOps canonical test; currently impossible due to F-04).
8. Next-focus decision recorded in BLUEPTR as the CURRENT milestone with exit gates.

## 5. Sequencing & effort (class-tagged)

| Step | Content | Class | Effort |
|---|---|---|---|
| 1 | §7 rulings from operator (R-1…R-8) | O | 30 min |
| 2 | Phase 1 (P1-1…P1-8) doc-truth audit + estate snapshot | B | 1 session |
| 3 | Phase 2 (P2-1 first! then sweep) | B | 1 session |
| 4 | Phase 3 roadmap verification + BLUEPTR diff | B | half session |
| 5 | Candidate A (M1 bootstrap extraction + Vagrant gate) | B | 1–2 sessions — the progress showpiece |
| 6 | Class-A batch: P1-9 probes, P2-6/P2-7 fleet legs, fresh-clone test | A | 1 fleet session (script pre-written in step 2–3) |
| 7 | O-class batch: stale remote trunks, hub console, Gitea init, Namecheap | O | operator |

## 6. Audit hygiene (how this audit avoids becoming the next stale doc)

- Findings write to `docs/audits/doc-truth-2026-09-16.md` (per repo) **as evidence**,
  not as new authority — the registers (BLUEPTR D/B/N) absorb the durable parts.
- This file gets a `SUPERSEDED-BY` header when Phase 3's verified table lands.
- Every Phase exit is a commit with evidence pointer; no phase "done" in chat only
  (law 1: Git is the SSoT — applies to this audit itself).
- The class-B session writes the class-A script *during* the audit, so the fleet
  session is execution, not investigation.

## 7. Operator rulings required (the audit cannot close without these)

| ID | Ruling | Options | Blocking |
|---|---|---|---|
| R-1 | Post-opencode auditor definition | Documented-run-with-evidence (tool-agnostic) — recommended | AUDITED ladder, B-010 |
| R-2 | Current tool of record for agent workflows | Name it (harness + MCP posture) so docs can be true | P2-10 |
| R-3 | ahab license (B-011) | Apache-2.0 (recommended, patent grant) / MIT / keep CC BY-NC-SA (contradicts dogfood law) | **M1 merge work** |
| R-4 | LLM fleet purpose post-opencode | vLLM/Qwen still serves X (name the client) → keep DGX roles / retire | P2-8, README §7 |
| R-5 | `todo.md` | Resurrect as work-item store / retire + strip refs (BLUEPTR demotes to generated view) | P1-3 |
| R-6 | `state/` data (events.jsonl, git-status.json) | Keep for flame pane-of-glass / retire with state_watch | P2-6 |
| R-7 | Opencode fleet key (P4-01) | Stop rollout + removal play / complete it (why?) | P2-7 |
| R-8 | Skills content | Archive-as-runbook vs migrate-to-current-tool format (depends R-2) | P2-2 |
