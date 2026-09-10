# Ahab — Control Repository Specification

> Laws: GitOps canon = `dundore-homelab@prod:docs/standards/gitops-2026-09-10.md`; ahab adaptation = BLUEPRINT process law 6. Canon wins; never restate (DRY). Enforced by `bin/law-gate.sh` (in homelab).

**STATUS: DRAFT (pending user review)** · 2026-09-09 · Plan: `feature_ahab-control-repo-foundation_20260909_b993`
**Doc layer 2 of the hierarchy in BLUEPRINT.md — design only; status/truth lives there, values live in code.**

## 1. Purpose

Ahab (**A**utomated **H**ost **A**dministration & **B**uild) is the control repository for
all Dundore infrastructure. A host runs one command and gets: OS baseline, service
account, Docker, and the assembled stack declared by its site repo.

The composition law:

```
ahab + dundore-homelab  = dundore.net   (fleet + services)
ahab + aitora           = aitora.org    (AI Tor Archive — magnet-first model/dataset platform, vLLM tutorials + recipes)
ahab + geekend          = geekend.org   (school/community tech lab)
```

Ahab provides the machinery; site repos provide inventory, service roles, and DNS.

## 2. Layer Model & Contracts

### Layer 0 — Bootstrap (Vagrant-tested, then bare metal)
Universal project workflow (every org, every machine, no exceptions):

1. **Test**: `vagrant up` a Fedora cloud-image VM; run L0 roles against it.
2. **Bare metal**: run the *same roles* against the physical host (vagrant user used
   only for first-touch, then removed).
3. **Only then** install the site's ansible repo (Layer 1/2 content).

Deliverables of L0 (the *bootstrap contract*):
- `ansible_user` service account + `~/.ssh/id_ansible_user` + agent forwarding (`svc_deploy`/`wdundore`/`waltdundore`/`root` direct use prohibited — per fleet naming law)
- dnf baseline, firewalld, SELinux policy, timezone/hostname (`base` enforces `node_fqdn` + `/etc/hosts`)
- python interpreter, Docker + compose plugin, git
- control-node extras (ansible-core, collections from `collections/requirements.yml`) when `role: control`

**Rule: L0 lives only in ahab.** Duplicates in dundore-homelab (`bootstrap`, `base`,
`fedora-baseline`), aitora (`system_prep`, `ansible_user`), geekend, and ahab's inline
`provision-workstation.yml` tasks are consolidated into `ahab/modules/bootstrap/`
(P4). Each extraction is proven in Vagrant first; evidence committed to
`tests/evidence/`.

### Layer 1 — Ahab core (this repo)
- Module system (§3), site manifest (§4), runner entrypoints (`site.yml`, per-module playbooks)
- Inventory staging (§5)
- Audit/test scaffolding (existing Makefile + audit scripts, retained)

### Layer 2 — Site repos (git submodules under `sites/`)
Each site repo contributes: `inventory/`, `roles/` (service layer), `dns/` (DNSControl),
and a `site.yml` manifest. Site repos contain **no** L0 logic.

### Layer 3 — Content repos (developer tier)
Per BLUEPRINT.md "Portability Contract": applications never touch layers 0–2.
Developers edit and publish only their content repo (`make env` composes the
workspace); publish triggers the webhook CI chain (M6). The "mentions a hostname,
secret, or org name?" test decides file ownership across all layers.

Submodules replace symlinks (`dundore-homelab/dns -> ../dundore-dnscontrol/` works
locally but breaks on fresh clone). `git clone --recursive` must yield a fully working
tree.

## 3. Module System (rewrite)

### 3.0 Repo estate — verified map & disposition (probed 2026-09-10; evidence BLUEPRINT)

All repos below EXIST (an earlier revision of this SPEC wrongly called them
fiction — they were never imported, not absent). Dispositions:

| Repo | What it actually contains | Verdict | Disposition |
|---|---|---|---|
| `ahab` | this repo — machinery (tier 1) | canonical | evolve per this SPEC |
| `ahab-modules` | only `apache/module.yml` (docker-compose style) + `INITIALIZE.md` cruft | superseded | absorb `apache` def, then GitHub-archive |
| `ahab-module-common` | one `common` role + config.yml (pre-L0-consolidation baseline) | superseded by bootstrap (§2) | fold role into `modules/bootstrap/`, archive |
| `ahab-module-docker` | copy of module-common (2-file diff) — **no docker role** | fiction by name | archive |
| `ahab-module-{apache,php,mysql,postgresql,nginx,redis,wordpress,nextcloud}` | DO NOT EXIST (8 of 9 registry targets) | fiction | delete from `MODULE_REGISTRY.yml` |
| `ansible-config` ≡ `ahab-config` | byte-identical twins (tree `d9e9a6f`); thin `dev/prod/config.yml` | tier-2 values → belong in site repos | canonical: `ahab-config`; archive twin; content migrates to `sites/*/` then even ahab-config retires |
| `ansible-inventory` ≡ `ahab-inventory` | byte-identical twins (tree `a4ee60f`); `*.example` hosts only | superseded by §5 seed staging | canonical: `ahab-inventory` (seed staging home); archive twin |
| `ahab-secrets` | examples (correct `REPLACE_*` tokens) + scripts; **one script embeds plaintext pwds (D-19)** | canonical secrets *reference* repo (real vault stays on /nas, D-06) | fix D-19, keep private, submodule on control nodes only |
| `scripts` | 2023 personal scripts (chrony dup, ssh/rsync wrappers) | dead | archive |
| `context` | GitHub agentic-workflow platform (marketplace, ~50 CI workflows) — model-as-developer reference | separate concern | keep; harvest workflow-gate patterns for §8 |
| `aitora` | pushed (origin/production) | site repo (submodule later, §4) | M4 |
| `athensarea-content` | content tier | content repo | M5 |

**Naming law (decision 2026-09-10, PM):** `ahab-*` names are canonical;
`ansible-*` twins are archived (GitHub archive = read-only, lossless) after a
redirect README commit — no repo is ever deleted, git history is the backup.

### 3.1 Modules are directories, not repos

The 2024 design (one GitHub repo per module, `MODULE_REGISTRY.yml` pointing at
`ahab-module-*`) is **retired**: verified above — 8 of 9 per-module repos never
existed and the 9th is a mislabeled copy. Repo-per-module was repo sprawl.

New design — directory-based modules inside ahab:

```
ahab/
  modules/
    bootstrap/        # L0 (module.yml, roles/, playbooks/)
    docker/
    traefik/
    nfs/
    netbox/
    uptime-kuma/
    postgres/         # fresh shared role when needed (not the stale 2024 one)
    ...
    <name>/module.yml # manifest
```

`module.yml` manifest:
```yaml
name: netbox
version: 1
roles: [netbox]            # roles/ dirs owned by this module
playbooks: [provision-netbox.yml]
requires: [docker, traefik]  # dependency order; ahab refuses to enable if missing
status: experimental|stable
```

Enablement is per-site (§4), never global. Modules may originate in a site repo and be
*promoted* to ahab when a second site needs them (netbox stays in dundore-homelab until
then; `docker`/`traefik`/`bootstrap` promote immediately — every site needs them).

## 4. Site Manifest

Each site repo root carries `ahab-site.yml`:

```yaml
site: dundore.net
repo: https://github.com/waltdundore/dundore-homelab.git
dns: dns/                      # DNSControl dir relative to site root
modules:                       # ahab modules enabled for this site
  - bootstrap
  - docker
  - traefik
  - nfs
local_roles: roles/            # site-specific service roles (kuma, authentik, ...)
```

`scripts/ahab-compose.sh` resolves registry + manifests → generates `ansible.cfg`
`roles_path`, group layout, and tags. Nothing runs without a manifest.

## 5. Inventory Staging (NetBox SSoT)

- **Stage A — seed**: `sites/<site>/inventory/seed/` static files. Used only for L0/L1
  and to provision NetBox itself (chicken-and-egg).
- **Stage B — SSoT**: `netbox.netbox.nb_inventory` plugin (`enable: true`, token from
  NAS/vault path, `strict: true`) generates all inventory. Seed files are then frozen
  with a header: `# SEED ONLY — host data lives in NetBox`.
- NetBox record hygiene precedes the switch: tags/roles drive plugin groups
  (`env:prod`, `arch:x86`), never hostname guessing.
- Prereq: d701/sager dev↔prod truth must be correct in seed inventory before any NetBox
  import (P1).

## 5.5 GitOps Deployment Contract (the "update-after-push" path — law 6)

This is the contract that answers *"we push, then what? how does the host get the
new code, and are its prerequisites guaranteed?"* — the path never tested to
sager. It is the reason a host (sager) can be missing the whole ahab tree: today
there is **no codified path** that lays ahab + site repo + secrets + L0
prerequisites onto a box. This section defines the single such path; law 0 says
it must rebuild a blank box from Git alone.

**Controller:** AWX on the hub (see BLUEPRINT law 6 + B-014/D-20). Fallback:
Gitea Actions. The controller, not a human, runs convergence.

**Deploy sequence (every target: sager, d701, rpi):**
1. **Webhook** — GitHub push to the promotion branch fires the Job Template's
   webhook endpoint (`awx_webhook_payload.after` = commit SHA, carried into
   `git_ref`). No SHA is ever typed by hand.
2. **L0 gate (idempotent)** — bootstrap module (§2) asserts `ansible_user`,
   keys, dnf/apt baseline, python, Docker+compose, git, `/nas` mount (D-02/D-06).
   A box with no ahab tree here gets one cloned fresh; there is no "manual clone."
3. **Lay the tree** — ahab clone + `git submodule update --init --recursive`
   (site repos are submodules under `sites/`, §2 layer 2), pinned to `git_ref`.
   No symlinks (§ law 6); fresh clone must be complete.
4. **Manifest resolve** — `ahab-site.yml` (§4) → `ahab-compose.sh` generates
   `roles_path`/groups/tags. Nothing runs without a manifest.
5. **Converge** — `site.yml` + module playbooks, `--check --diff` first in dev,
   then apply in prod (promotion gates in BLUEPRINT).
6. **Prove** — kuma monitor registered/refreshed (law 2); drift scan scheduled.

**Prerequisites are code, discovered not remembered** (law 0): every software
package, DB, directory, secret, and file a role consumes must be created by an
upstream role/module or the run fails LOUDLY (no silent manual prep). The
Vagrant fedora43 box is the proving ground: a blank box → full stack from Git
alone is the acceptance test for this section. Every gap we hit in Vagrant is a
bug **in code**, fixed in code, not in a human's memory.

**Drift detection:** scheduled `--check` scan → kuma alert; a drift scan without
a monitor does not exist (law 2).

**Secrets:** vault-encrypted in Git; vault password only at the D-06 canonical
`/nas` path; generators emit `REPLACE_ME_*`/`openssl rand`, never plausible
literals (D-19). AWX credential + vault token live in the AWX credential store
backed by that vault — never in shell history (D-20).

## 6. Current Facts & Corrections

- **d701 = production, dundore-sager = development** (user law, 2026-08-18). Inventory
  flip `699e6bf` + DNS flip `d9c8465` **PUSHED & LIVE** (dig-verified, BLUEPRINT
  2026-09-09) — d701→prod(.10), sager→dev(.15). P1 now = netbox record hygiene, not
  the flip itself.
- **sager is UNMANAGED + has NO ahab tree** (BLUEPRINT B-002, LIVE-PROBED 2026-09-10):
  repo keys absent from `authorized_keys`, and §5.5's deploy path does not yet exist.
  Both must land before any "update after push" claim. sager's repo working state is
  UNKNOWN — audit on unlock.
- **AWX on the hub is the intended GitOps controller** (operator attested) but is
  currently DOWN, version-unpinned (`devel`), and lives in shell-history not code
  (D-20). Until D-20/B-014 land, §5.5's controller leg is untestable.
- `dundore-homelab/.gitmodules` declares an uninitialized `dns` submodule while `dns/`
  is a symlink — reconcile in P5.
- ahab is CC BY-NC-**SA** 4.0: code promoted from sites into ahab becomes share-alike
  non-commercial. Acceptable for personal + K-12/nonprofit use.
  **⚠ DECISION PENDING (user):** keep CC BY-NC-SA for ahab, or relicense MIT/Apache for
  the parts consumed as libraries?
- NetBox runs dev on sager (netbox-dev) and prod on d701; ahab consumes only the prod
  NetBox for inventory; `token_path` must move from `/nas/secrets/...` hardcode to a
  vault lookup (P5).

## 7. Roadmap

| Phase | Deliverable | Status |
|---|---|---|
| P1 | d701/sager inventory + DNS flip | ✅ DONE (pushed, live; unaudited → B-010) |
| P2 | This SPEC.md accepted + license decision (B-011) | draft below |
| P3 | `waltdundore/aitora` pushed | ✅ DONE (origin/production live-probed) |
| P4 | Directory modules + unified bootstrap extraction (Vagrant evidence) | pending SPEC |
| P5 | Submodule wiring (`sites/`, dns), `enable: true` NetBox inventory | pending SPEC |
| P6 | aitora.org zone in dundore-dnscontrol | pending registrar |
| **P7** | **GitOps deploy path (§5.5): PR-gate CI → AWX webhook → converge blank host from Git → kuma** | **NOT STARTED; gated by B-002 (sager), B-014/D-20 (AWX), B-013 (canonical repos)** |

## 8. Out of Scope

Building the aitora.org app (catalog/swarm/web), NetBox data migration itself,
geekend.org domain until the lab graduates, GUI (`ahab-gui`) integration.
