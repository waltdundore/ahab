# Project: Ahab — Automated Host Administration & Build (v2 Platform)

_Last updated: 2026-08-30 — v2 reset: working tree reset to platform skeleton on new `main` branch (v1 history preserved on `prod`, last commit a82d0de). Skeleton materialized and committed; no code yet by design. Canonical gate list: SPEC.md §6. Milestone status: §6 below. Independent M0 drift re-audit (spark-auditor) 2026-08-30: M0 re-verified green; drift items in SPEC.md §11; multi-model concurrency: §8._

## 1. Purpose
Ahab v2 is a reusable Ansible host-automation + build platform ("ahab"). Given a target box (real machine or lab VM), ahab delivers:
1. `make install` — the box becomes a running ahab instance: automation identity, docker engine, networks, and the base monolith stack (ingress + shared database + monitoring), all tuned to each other within one docker compose stack.
2. `make import <module>` — configured content (a domain's services, an app stack, per-deployment config) is imported and running inside the same monolith, inheriting its networks, database, credentials, and monitoring.

Content is abstracted out of the framework. dundore.net, whitecountyschools.net, and geekend are separate content imports — the platform is content-agnostic. Inventories and box configs live in this repo and are applied to individual boxes from `inventory/`.

## 2. Binding Laws (inherited from the Dundore Platform Template)
- **Identity Law**: `wdundore` = operator human account; `ansible_user` = automation service account (fleet key distributed by playbook, gitignored). CI must never see a service-account law violation.
- **Secrets Law (L1–L8)**: one vaulted secret store (`secrets/`, gitignored, Ansible Vault AES256) is the only secret store; per-node vault pass 0600 and gitignored; no secret value on a command line or in a log line — reference secrets by path only; rotate, never scrub; known workspace debts (ops-workspace `vault/temp_key`, hf embedded bearer token, `domains/dundore.net` placeholder password) are remediated, never replicated.
- **Naming Law (2026-08-18)**: one canonical name per machine — hostname, DNS label, and Tailscale name are the same name; services CNAME to the machine; ingress routes by machine FQDN (Traefik labels).
- **Evidence Discipline**: every state claim is tagged `[verified <date>]` (executed and observed) or `[inferred]`; undated claims are stale and get re-verified, not re-copied.
- **Append-Only todo.md**: dated, ID'd (class AH-###), evidence-bearing items; never overwrite, reformat, or delete entries; mark done with `[DONE]` + date.
- **AI Context File-Header Standard**: every file an LLM touches begins with a `# AI CONTEXT` block (Purpose / Dependencies / Referenced By / Critical Constraints).

## 3. v1 → v2 Reset Record (2026-08-30)
- v1 (branch `prod`, HEAD a82d0de "Clean branch: Remove all fake secret patterns for GitHub publishing") is preserved in git history as the source of lessons and reference patterns — not of code.
- **Removed by the reset** [verified 2026-08-30, `git rm` on `main`]: 9 Makefile variants (four of them ~1,310-line dead copies: Makefile.original, Makefile.bak2, Makefile.backup-broken, Makefile.backup-before-test-unit-fix); 30+ root `*.md` docs plus 42 in `docs/` (including zero-byte stubs and per-task `*_SUMMARY_*.md` files); uninitialized submodule declarations (`modules/` → ahab-modules, `config-roles/` → ahab-config, both empty in v1); the fake-secrets git-publish machinery (`.clean-publish-backup/`, publish Makefile targets); the stale bootstrap that expected sibling repos (ansible-inventory/ansible-config) and a missing `ahab.conf`.
- **Kept as design input** for v2: the `MODULE.yml` metadata shape (evolved into the v2 module contract, SPEC.md §5); the compose-generation idea, corrected to fragment-merge instead of whole-file regeneration; the `.milestones` machine-state idea (reappears as `state/` in M5).
- **License resolved**: MIT (v1 conflict — LICENSE said MIT, docs said CC BY-NC-SA — closed in favor of MIT; see SPEC.md §8.4).

## 4. Current State [verified 2026-08-30]
- Skeleton committed on `main`: SPEC.md §4 layout directories (with `.gitkeep`), `CONTEXT.md`, `SPEC.md`, `todo.md`, `README.md`, `.gitignore`. No code, no Makefile, no playbooks — by design; M1 lands the first code.
- No box is provisioned by v2 yet. v1's release gates were dundore + rpi5-03 per the dundore-homelab fleet table [verified 2026-08 via template CONTEXT.md §5.1]; the v2 gate strategy is open (blocker B5, SPEC.md §7).
- Workspace attachment: the Dundore Platform Template will pin this repo at `content/ahab` by SHA (template SPEC §Content Attachment Map). The template's ahab health-command row (`make test-nasa && make test-security-standards`) is v1-stale and updates when M1 lands its CI.

## 5. Layout
Canonical tree in SPEC.md §4. Skeleton exists; files land per milestone as listed there. No file exists that is not named in SPEC.md §4.

## 6. Milestone Status (canonical gate list: SPEC.md §6)
| Milestone | Name | Status |
| --- | --- | --- |
| M0 | Clean slate + contract | [DONE] 2026-08-30 (this reset commit on `main`) |
| M1 | Base install loop | [TODO] — depends B1, B5 |
| M2 | Monolith base stack | [TODO] — depends M1, B2 |
| M3 | Module import contract | [TODO] — depends M2, B4 |
| M4 | Content migration (3 imports) | [TODO] — depends M3, B3, B4 |
| M5 | Fleet apply + state | [TODO] — depends M4, B1 |
| M6 | Parity + cutover | [TODO] — depends M5 |

Gate numbering is canonical — never renumber; append M7+ only.

## 7. Relationships
- **Template (Dundore Platform Template)**: attaches this repo at `content/ahab` pinned by SHA; laws in §2 are inherited from it.
- **Predecessors** (superseded at M6, untouched before): `dundore-homelab/compose.yml` (the monolith itself), `dundore-homelab/roles/compose_monolith` (stack deployment), `shared/roles/{postgres,netbox,traefik,zabbix,verify_health,common,docker}` (compose-based role re-implementations), `domains/{dundore.net,whitecountyschools.net}/site.yml` (per-domain content entry points).
- **dundore-homelab**: remains SSoT for fleet inventory, LLM cluster, DNS, and the three-tier state model. Ahab's `inventory/` is an ahab-scoped projection (boxes that run the monolith) and must stay consistent with the Naming Law machine table (template CONTEXT.md §5.1).
- **geekend**: docs-only project (zero code, SPEC v0.3.0); its M4 module is infra-only until geekend application code exists.

## 8. Multi-Model Concurrency (added 2026-08-30, spark-auditor)
**Standing operating assumption**: more than one model/agent may be working in this tree at any moment — same machine, same branch (`main`), same working copy.

How agents know who is changing what — three mechanisms:

1. **Shared context files — in place** [verified 2026-08-30]. `CONTEXT.md` is the state of record (human tier); `todo.md` is the append-only, ID'd plan (plan tier). Both are committed, so every session re-reads the last recorded state at start.
2. **fleet-state MCP agent protocol — exists and is live; NOT yet wired for this repo** [verified 2026-08-30]. `dundore-homelab/mcp/fleet_state/server.py` is a stdlib-only NDJSON-RPC stdio MCP server; 10 tools including the coordination set `agent_register`, `agent_heartbeat`, `agent_deregister`, `agent_status`, `declare_edit`, `release_edit`, `file_events`. Agents register, heartbeat (stale after 10 min), and DECLARE the paths they will touch; `declare_edit` reports conflicts against other active agents' declarations; `file_events` attributes recent edits to the declaring agent or 'undeclared'. Coordination state lives in `state/agents.json`, flock-serialized via `state/.lock`; a live registry probe on 2026-08-30 returned `[]` (no active agents).
3. **One-writer-per-artifact trust law — normative** [verified 2026-08-30]. Template CONTEXT.md §6: Planner/Architect → Build (spark-builder) → Audit (spark-auditor) → Report; trust laws: (1) evidence for every claim, (2) three-file contract per change (plan, build record, audit record), (3) one writer per artifact, (4) reproducibility as oracle, (5) audit gates merge.

**Answer to "are they using context to know who is changing what?"** — partially. The context-file tier and the trust laws are fully in place and normative [verified 2026-08-30], and the machine-tier agent protocol exists and is live for this workspace [verified 2026-08-30] — but it is **not yet pointed at this repo**: ahab has no `state/agents.json` and no MCP config wiring fleet-state here, the server's live coordination state sits in `dundore-homelab/state/`, and its repo-root autodetection (`todo.md` + `roles/`) does not match this layout (`base/roles/`) [verified 2026-08-30; gap recorded as SPEC.md §11 DRIFT-3, todo AH-008, owner M5]. Until it is wired, agents in this tree coordinate via the context files + one-writer law and must treat un-declared concurrent edits as a risk to check before editing.

**Rules for agents working here**:
- Read `CONTEXT.md` + `todo.md` before editing anything.
- When the fleet-state MCP is available for this repo: `agent_register` at session start, `declare_edit` the paths you will touch before touching them, `release_edit` on completion, `agent_deregister` on exit.
- Never rewrite, reformat, or delete append-only `todo.md` entries — append the next free `AH-###`.
- One writer per artifact: never edit an artifact declared by another active agent; surface the conflict instead.
