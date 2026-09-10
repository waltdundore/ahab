# Ahab — Control Repository Specification

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

The 2024 design (one GitHub repo per module, `MODULE_REGISTRY.yml` pointing at
`ahab-module-*`) is **retired** — those repos are fiction; it is repo sprawl.

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

## 6. Current Facts & Corrections

- **d701 = production, dundore-sager = development** (user law, 2026-08-18). Homelab
  groups *and* host_vars still say the reverse; `dnsconfig.js` CNAMEs `d701→dev.`,
  `dundore-sager→prod.` are likewise stale. P1 fixes inventory; DNS flip lands as a
  reviewed dnscontrol PR (preview first, never blind push).
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
| P1 | d701/sager inventory truth flip + DNS fact-gathering | ▶ in flight |
| P2 | This SPEC.md accepted + license decision | draft below |
| P3 | `waltdundore/aitora` pushed (auth blocker: gh token/ssh-agent in build shell) | blocked |
| P4 | Directory modules + unified bootstrap extraction (Vagrant evidence) | pending SPEC |
| P5 | Submodule wiring (`sites/`, dns), `enable: true` NetBox inventory | pending SPEC |
| P6 | aitora.org zone in dundore-dnscontrol | pending registrar |

## 8. Out of Scope

Building the aitora.org app (catalog/swarm/web), NetBox data migration itself,
geekend.org domain until the lab graduates, GUI (`ahab-gui`) integration.
