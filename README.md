# Ahab — tier-1 machinery

Ahab is the **control repo** of a homelab program: tier 1 of a 3-tier split.
It holds all environment-agnostic infrastructure code once — bootstrap roles,
core infra roles, the module system, gate scripts, Makefile/CI templates.
**Zero org-specific values live here**; site repos (tier 2, e.g.
`dundore-homelab`) carry inventory, DNS, and site-specific roles; application
repos (tier 3) carry only code. The placement test and the full contract are
owned by [BLUEPRINT.md § Portability Contract](BLUEPRINT.md) — read them
there, not here.

## Start here

**Newcomer?** The guided front door is **[START_HERE.md](START_HERE.md)** — pick
your path (curious · operator · contributor · site owner · agent) and see the
feeling each one gives you. Want the surprise of what this thing actually *does*?
That's **[docs/PLATFORM.md](docs/PLATFORM.md)**. Hit an unfamiliar word? It's
defined in **[docs/GLOSSARY.md](docs/GLOSSARY.md)**. An agent getting live
context? **[AGENTS.md](AGENTS.md)**.

Learning it step by step? The **[learning ladder](docs/learn/README.md)** walks
Module 0 from an empty box to a rebuild you can prove.

## Read this next: BLUEPRINT.md

**[BLUEPRINT.md](BLUEPRINT.md) is the layer-1 program authority**: mission,
process laws, milestone ledger, live-probed facts, blockers (`B-###`), and the
drift register (`D-##`). If something is not written there with evidence, it
is not true. This README is a thin entrance that links and never copies
(context-economy law, BLUEPRINT § GitOps / § Documentation Hierarchy).

- [SPEC.md](SPEC.md) — design of this repo's layer (interfaces, contracts)

## License — read before adopting any code

[LICENSE](LICENSE) is **CC BY-NC-SA 4.0**: non-commercial, therefore *not*
open source by OSI definition. That contradicts this project's own dogfood
law; relicensing (Apache-2.0 recommended) is a prerequisite of milestone M1 —
tracked as blocker **B-011** in [BLUEPRINT.md](BLUEPRINT.md).

## What actually runs

The `make` surface is the entrypoint, and the [Makefile](Makefile) is the
only home of the target list — **`make help`** prints it. This README does
not copy the list: a copy rots the moment the code moves (D-45 precedent).
Unknown targets **fail loudly**: `make no-such-target` exits 2, so a typo
can never fake success (a catch-all once let it — see **D-39**):

```bash
make help                  # every real target, read from the Makefile itself
make check-prerequisites   # verify required tools
```

These drive Vagrant/Ansible at runtime; whether they currently *work* is a
BLUEPRINT fact, not a README claim — see its M0 milestone row and the
vagrant-gate defect **D-25 / B-017**. This Makefile has **no `ui` target**
(older revisions of this README recommended one; they were wrong).

## Where each question is answered

| Question | Authority (read there) |
|---|---|
| I'm new — where do I start? | [START_HERE.md](START_HERE.md) |
| What does this actually *do* (the platform)? | [docs/PLATFORM.md](docs/PLATFORM.md) |
| What does this word mean? | [docs/GLOSSARY.md](docs/GLOSSARY.md) |
| Is something up **right now**? | the site's public Uptime-Kuma status page — live monitors, not prose (law 12) |
| I'm an agent — how do I get live context? | [AGENTS.md](AGENTS.md); how the channels are wired: `docs/mcp-channels.md` in your site repo |
| Mission, laws, milestones, blockers, drift | [BLUEPRINT.md](BLUEPRINT.md) |
| This repo's design | [SPEC.md](SPEC.md) |
| Which doc owns which altitude | [BLUEPRINT.md § Documentation Hierarchy](BLUEPRINT.md) |
| Testing | [TESTING.md](TESTING.md) |
| Module system | [docs/MODULE_ARCHITECTURE.md](docs/MODULE_ARCHITECTURE.md) |
| Dev rules, git workflow | [DEVELOPMENT_RULES.md](DEVELOPMENT_RULES.md), [BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md) |
| Educational-standards material (archived 2026-09: teaches the retired doc set) | [docs/archive/2026-09/GEORGIA_STANDARDS_VERIFICATION.md](docs/archive/2026-09/GEORGIA_STANDARDS_VERIFICATION.md), [standards-registry.yml](standards-registry.yml), [feature-standards-map.yml](feature-standards-map.yml) |
| The previous README (everything removed) | [docs/FROZEN.md](docs/FROZEN.md) |

## State of this repo (acknowledged debt, not fixed here)

Look these up in the BLUEPRINT D-register instead of tripping over them:

- `Makefile*` variants: the top level was cleaned in the 2026-09-11 hygiene
  pass (one root Makefile remains — `evidence/2026-09-11-estate-hygiene.md`);
  nested variants under `config/`, `inventory/`, `docs/development/` plus
  dangling includes remain — **D-18**
- [MODULE_REGISTRY.yml](MODULE_REGISTRY.yml) names 8 module repos that do not
  exist — **D-17**; the decided design keeps directory modules inside ahab
  (`modules/<name>/module.yml`), and `modules/` is empty today
- 12 top-level `.md` files of mixed vintage; BLUEPRINT's doc-hierarchy table
  is the filter
- byte-identical twin repos `ansible-config`/`ansible-inventory` ≡
  `ahab-config`/`ahab-inventory`; canonical name **decided**: `ahab-*`
  (**B-013**); lossless archiving of the twins awaits `gh` auth — **D-16**

## History note

A 2026-09-11 cold audit found this entrypoint linked BLUEPRINT.md zero times,
recommended the nonexistent `make ui`, and badge-linked a release-notes file
absent from the path it named. The full previous content moved verbatim to
[docs/FROZEN.md](docs/FROZEN.md) with a non-verification notice rather than
silently deleted.
