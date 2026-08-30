# Ahab Platform Specification (v2)

_Status: active — platform contract + milestones (overarching blockers)._
_Scope rule: this spec defines the platform and the path to completion at gate level. Implementation detail (task lists, variable schemas, script internals, compose fragment syntax) is deliberately NOT written here; it is broken out per milestone when that milestone goes in_progress._

## 1. Vision
One reusable "Automated Host Administration & Build" platform. Given a target box, ahab delivers:

1. `make install` — the box becomes a running ahab instance: automation identity, docker engine, networks, and the base monolith stack (ingress + shared database + monitoring), all tuned to each other within one compose stack.
2. `make import <module>` — configured content (a domain's services, an app stack, per-deployment config) is imported and running in the same monolith, sharing the stack's networks, database, credentials, and monitoring.
3. `make remove <module>` — the clean reverse operation.

Content is never part of the platform. The platform is content-agnostic: dundore.net, whitecountyschools.net, and geekend are separate content imports that happen to run on the same platform. Inventories and configs are stored in this repo and applied to individual boxes from `inventory/`.

## 2. Why This Exists — The Repeated Pattern (workspace scan, 2026-08-30)
Every time this workspace stood up a service box, the same framework was re-created by hand. The scan found the same five elements across `ahab` (v1), `hf`, `geekend`, `domains/`, `shared/`, and `dundore-homelab`:

| # | Framework element | File evidence |
| --- | --- | --- |
| 1 | **Ansible control plane**: `inventory/` (hosts + group_vars + host_vars) + `playbooks/site.yml` + `roles/` + Vagrant lab | `ahab/inventory{dev,prod,workstation}`, `hf/{playbooks,inventory,Vagrantfile}`, `geekend/{playbooks/inventory/Vagrantfile}`, `domains/*/site.yml`, `dundore-homelab/{playbooks,inventory}` |
| 2 | **Monolith compose stack**: postgres + uptime-kuma + netbox (+static www) on shared networks, one shared DB + password, Traefik ingress labels per host | `dundore-homelab/compose.yml`; `dundore-homelab/roles/compose_monolith` (templates `docker-compose.yml.j2`, applies via `docker_compose_v2`) |
| 3 | **Same services re-implemented as compose-based Ansible roles**: postgres:15, netbox v3.5+redis:7, traefik 3.x, zabbix 6.4, unified `sre-*` naming on `sre-backend` network, fail-fast `verify_health` gate | `shared/roles/{postgres,netbox,traefik,zabbix,verify_health,common,docker}` |
| 4 | **Per-domain content entry points**: `site.yml` + `group_vars/` + `inventory/` per domain | `domains/dundore.net` (Phase 1 wired), `domains/whitecountyschools.net` (one-line comment stub) |
| 5 | **Module metadata → compose**: `MODULE.yml` (service, ports, deps, env, health) + `MODULE_REGISTRY.yml` + generator script | v1: `ahab/roles/{apache,php,mysql}/MODULE.yml`, `ahab/MODULE_REGISTRY.yml`, `ahab/scripts/generate-docker-compose.py` |

Plus two supporting habits worth keeping: post-deploy health gates (`shared/roles/verify_health`, `dundore-homelab/playbooks/test-services.yml`, `hf/scripts/test-phase1.sh`) and the CONTEXT/SPEC/todo/state documentation discipline.

**Ahab v2 turns that framework into a product: the framework is the repo; the content is an import.**

## 3. Architecture
### 3.1 Platform / content split
- `base/` — **the framework**: everything needed to turn a bare box into a running monolith and to import modules into it. Content-agnostic; no domain names, no app specifics.
- `modules/<name>/` — **the content**: one directory per import. Each module declares its services (compose fragments), ingress hosts, dependencies, and required vars.
- `inventory/` — **the fleet**: which boxes exist, their class, and per-box vars. One entry per box; the same platform applies to any of them.

### 3.2 Monolith model
- **One docker compose project per box** (the monolith). All platform and imported services join shared compose networks (one internal data network, one ingress network); one shared PostgreSQL; one shared credential set sourced from `secrets/` (vault). Services talk to each other **by service name inside the stack**, never across box boundaries.
- **Ingress**: Traefik (docker provider) on the ingress network; every exposed service gets a router labeled with the machine's canonical FQDN (Naming Law); TLS via the existing dundore.net LE setup.
- **Monitoring**: Uptime Kuma runs in-stack and monitors every in-stack service from day one; NetBox is the inventory SSoT and reads the same shared PostgreSQL.
- Consequence: adding a module = adding services to the same project; common logins, DB, and networking are inherited, never re-created.

### 3.3 Control plane
- Ansible controller runs from the operator box (or `hub`); targets are boxes listed in `inventory/`. Automation SSH key per the Identity Law; `become` for system tasks.
- `make` is the only user-facing surface: `install`, `import <module>`, `remove <module>`, `verify`, `status`, `clean`. One Makefile, ever (SPEC.md §8.1).

### 3.4 State
- `state/` (gitignored) mirrors the fleet three-tier model: machine-readable status per box (repo / stack / services blocks) written by `verify` and CI; `CONTEXT.md` remains the human SSoT.

## 4. Canonical Layout
```
ahab/
├── CONTEXT.md              # state of record (human tier)
├── SPEC.md                 # this spec (contract + milestones, canonical)
├── todo.md                 # append-only plan (class AH-###)
├── README.md               # pointer stub only
├── .gitignore              # state/, secrets/, caches, logs
├── Makefile                # single control surface            [M1]
├── ahab.yml                # instance SSoT: box, domain, nets, ports  [M1]
├── ansible.cfg             #                                    [M1]
├── base/                   # THE FRAMEWORK — content-agnostic
│   ├── playbooks/          # install.yml, monolith.yml, import.yml,
│   │                       # remove.yml, verify.yml            [M1–M3]
│   ├── roles/              # base_host, compose_stack, verify_health  [M1–M2]
│   └── templates/          # monolith skeleton docker-compose.yml.j2  [M2]
├── modules/                # CONTENT IMPORTS — one dir per module
│   └── <name>/             # MODULE.yml + compose/ + config/ +
│                           # optional inventory/               [M3+]
├── inventory/              # FLEET — hosts, group_vars/, host_vars/  [M1]
├── secrets/                # vault only; gitignored                [M1]
├── state/                  # live machine state; gitignored        [M5]
├── tests/                  # hard-audit scripts                    [M1+]
└── .github/workflows/      # ci.yml gate chain                     [M1]
```
Rules: skeleton directories carry `.gitkeep`; files land only per the milestone tags above; **no file exists in this repo that is not named in this tree** (or listed in `todo.md`).

## 5. Module Contract (shape; detailed schema lands with M3)
A module is a directory `modules/<name>/` containing:
- `MODULE.yml` — machine-readable declaration: `id`, `version`, `description`, `depends` (other modules), `services` (name → image, ports, env, volumes, network membership), `ingress` (host → service:port), `required_vars` (what the box content must supply), `health` (how `verify` probes it).
- `compose/` — one compose fragment per service, **merged into the monolith project at import time** (fragment merge, not whole-file regeneration — the v1 generator's rewrite-everything behavior is retired).
- `config/` — optional per-service config templates, rendered with box vars + secret references.
- `inventory/` — optional per-box overrides scoped to this module only.

Import pipeline: validate `MODULE.yml` → resolve `depends` → merge fragments into the monolith project → render config → compose up → health gate. **Idempotent**: re-importing a running module converges without restart unless a fragment actually changed. `remove` reverses: drop fragments, prune service, health gate.

## 6. Milestones (canonical gate list)
A milestone passes only when its **hard audit executes green** (exit 0). No milestone passes on theoretical correctness. Status values: [TODO] / [IN PROGRESS] / [DONE date].

### M0 — Clean slate + contract — [DONE 2026-08-30]
- **Goal**: retire v1 in place; establish the v2 skeleton + this contract.
- **Scope**: new `main` branch from `prod` HEAD; v1 preserved untouched on `prod`; tree reset to §4 skeleton; `CONTEXT.md` + `SPEC.md` + `todo.md` + `README.md` + `.gitignore`.
- **Hard audit**: `git status --porcelain` empty on `main`; `test -f SPEC.md && test -f CONTEXT.md` exit 0; `git check-ignore state/probe secrets/probe` exit 0; v1 intact — `git log prod --oneline -1` still `a82d0de`.
- **Status**: [DONE 2026-08-30] — the reset commit on `main`.

### M1 — Base install loop
- **Goal**: `make install <box>` turns a bare box (lab VM or real) into a reachable, docker-ready ahab target with the automation identity and base networking.
- **Scope**: the single `Makefile`; `ahab.yml` instance SSoT; `ansible.cfg`; `base/playbooks/{install,verify}.yml`; `base/roles/base_host`; `inventory/` with the first real box entries (`hosts`, `group_vars/`, `host_vars/`); `secrets/` vault scaffold; first hard-audit scripts in `tests/`; `.github/workflows/ci.yml` (yamllint → ansible-lint → syntax-check → audit chain).
- **Hard audit**: on a clean box, `make install <box> && make verify <box>` exit 0; immediate re-run idempotent (`changed=0`); CI green on push.
- **Exit bar**: install proven on ≥2 box classes (one VM, one real x86 or ARM).
- **Status**: [TODO] — depends B1, B5.

### M2 — Monolith base stack
- **Goal**: `make install` additionally brings up the base monolith: Traefik ingress + shared PostgreSQL + Uptime Kuma + NetBox, in-stack, common vault-sourced credentials, Kuma monitoring the stack itself.
- **Scope**: `base/playbooks/monolith.yml`; `base/roles/compose_stack` (fragment-merge engine, v1); `base/templates/docker-compose.yml.j2` monolith skeleton; vault entries for DB password + common logins; `base/roles/verify_health` fail-fast gate (postgres, kuma, netbox, traefik).
- **Hard audit**: `make install <box> && make verify <box>` exit 0 with all four base services healthy; Kuma monitors report up for in-stack services; grep shows no plaintext credentials in repo or rendered compose (vault paths only); re-run idempotent.
- **Status**: [TODO] — depends M1, B2.

### M3 — Module import contract
- **Goal**: `make import <module>` works end-to-end against a reference module; `make remove <module>` reverses it.
- **Scope**: `base/playbooks/{import,remove}.yml`; fragment merge finalized per §5; module validation + dependency resolution; one reference module exercising the full contract (a service + an ingress host + a health probe).
- **Hard audit**: `make import <ref> && make verify <box>` exit 0; `make remove <ref> && make verify <box>` exit 0; re-import idempotent; a module with an unsatisfied `depends` or a missing `required_var` fails fast with a named error (negative test in `tests/`).
- **Status**: [TODO] — depends M2, B4.

### M4 — Content migration (first three imports)
- **Goal**: dundore.net, whitecountyschools.net, and geekend exist as three separate modules that import and run.
- **Scope**: `modules/dundore-net/` (today's `dundore-homelab/compose.yml` surface: static www + kuma + netbox + dundore-specific ingress); `modules/wcss-net/` (whitecountyschools surface — today a stub, so this module also defines what wcss needs); `modules/geekend/` (per geekend SPEC v0.3.0 — infra-only: its database/ingress/monitoring footprint; geekend app code does not exist yet [verified 2026-08]).
- **Hard audit**: on a test box, all three modules import; parity check passes: the monolith's resulting service set + networks + ingress hosts diff clean against a committed baseline snapshot of the current `dundore-homelab/compose.yml` stack (parity script in `tests/`).
- **Status**: [TODO] — depends M3, B3, B4.

### M5 — Fleet apply + state
- **Goal**: any box in `inventory/` is a first-class target; per-box config applies from the repo; machine state is recorded.
- **Scope**: inventory coverage for the gate fleet; per-box `host_vars/`; `state/` contract (per-box status blocks: repo / stack / services, flock-serialized); `verify` writes state; release-gate definition (box set + order).
- **Hard audit**: `make install` + imports applied to ≥2 real boxes; `state/` files present and parseable; Kuma green on both boxes; re-run idempotent.
- **Status**: [TODO] — depends M4, B1.

### M6 — Parity + cutover
- **Goal**: ahab is the SSoT for monolith builds; the legacy patterns are retired or explicitly superseded; the workspace points at v2.
- **Scope**: `dundore-homelab/compose.yml` + `roles/compose_monolith` + `shared/roles` compose roles + `domains/*/site.yml` marked superseded (or converted); template `content/ahab` attachment re-pinned to a `main` SHA; template ahab health-command row updated; v1 branches archived with a pointer note on `prod`; license + docs consistent (MIT).
- **Hard audit**: template CI green against attached v2; legacy monolith SSoT grep returns only ahab (or explicit superseded markers); no open P0 items in `todo.md`.
- **Status**: [TODO] — depends M5.

## 7. Overarching Blockers (resolve before, or in parallel with, the named milestone)
- **B1 — Target box + key distribution** (needed by M1). The fleet is 0/9 manageable: automation key absent on control nodes (dundore-homelab todos P4-01/P4-02). Ahab cannot install anything until at least one gate box carries the `ansible_user` key per the Identity Law.
- **B2 — Secrets SSoT** (needed by M2). Monolith common logins must be vault-sourced (L1–L8). v1 evidence of what NOT to do: plaintext `SECRET_KEY: change-this-secret-key` in `dundore-homelab/compose.yml`; placeholder password in `domains/dundore.net/group_vars/all.yml`; unencrypted `ops-workspace/vault/temp_key`.
- **B3 — DNS / Naming Law reconciliation** (needed by M4). Every imported service that takes ingress needs a canonical machine FQDN + record; `dundore-dnscontrol/dnsconfig.js` is the zone SSoT. Module `ingress` declarations must reconcile with it before import is allowed.
- **B4 — Content provenance decision** (needed by M3). The first three modules' content currently lives in three+ places (`dundore-homelab/compose.yml`, `domains/*`, geekend's docs-only SPEC). Decision: modules are plain directories in this repo (simple; default) vs pinned submodules (reuse; v1's uninitialized-submodule theater is the cautionary tale). Record the decision in `todo.md` at M3 entry.
- **B5 — Lab vs real strategy** (needed by M1). v1 loop: Vagrant bento-fedora-43 workstation for dev, d701 + rpi5-03 as release gates. v2 choice: keep Vagrant for M1–M3 (fast, disposable) and touch real boxes only at M5 — or go straight to real hardware. Record the decision in `todo.md` at M1 entry.

## 8. Do-Not-Repeat List (v1 lessons — binding)
1. **One Makefile.** (v1: 9 variants at root, four of them ~1,310-line dead copies.)
2. **Three root docs**: `CONTEXT.md`, `SPEC.md`, `todo.md`. (v1: 30+ root `*.md`, 42 in `docs/`, zero-byte stubs, per-task `*_SUMMARY_*.md` files.)
3. **No placeholder theater**: no uninitialized submodules, no empty structures promising future content. An empty directory is either `.gitkeep`-named in §4 or it does not exist.
4. **MIT license, stated once.** (v1: LICENSE said MIT, docs said CC BY-NC-SA 4.0.)
5. **No fake-secrets machinery**: no fake patterns to keep publishers quiet, no publish gymnastics. Secrets exist only in vault, gitignored, referenced by path.
6. **Self-contained repo**: no bootstrap that assumes sibling repos or files outside the repo. (v1: `ahab.conf` SSoT missing; bootstrap expected `ansible-inventory`/`ansible-config` siblings + symlinks.)
7. **Every gate has an executable hard audit with an exit code.** No milestone theater; `.test-status`-style artifacts only when they encode a real gate.
8. **One module format**: `MODULE.yml` (v2 contract, §5) evolves in place — never fork a parallel registry/manifest format.

## 9. Relationship to the Workspace (2026-08)
- **Template (Dundore Platform Template)**: attaches this repo at `content/ahab` pinned by SHA; its CI per-repo health command for ahab updates when M1 lands (the current row still references v1 `make test-nasa`).
- **dundore-homelab**: remains SSoT for fleet inventory, the 2-node LLM cluster, DNS glue, and the three-tier state model. Ahab does **not** duplicate fleet management — `inventory/` is the ahab-scoped projection (boxes that run a monolith) and must stay consistent with the Naming Law machine table (template CONTEXT.md §5.1).
- **shared/ + domains/ + dundore-homelab/compose.yml**: functional predecessors of `base/` + `modules/`. Untouched until M6.
- **geekend**: docs-only (zero code) [verified 2026-08]; its M4 module is infra-only until the app exists.

## 10. Change Rules
- `todo.md` is append-only; ID class `AH-###` starting AH-001 (the reset). Blockers get their own `todo.md` entries when they are resolved.
- Claims carry `[verified <date>]` / `[inferred]` tags; stale claims are re-verified, not re-copied.
- A gate is an executable hard audit; no audit, no gate pass.
- One writer per artifact; plan → build → audit → record per the workspace trust laws.
- This spec is updated at each milestone entry/exit. Milestone numbers are canonical — never renumber; extend with M7+ only.
