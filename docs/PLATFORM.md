# The one more thing — a whole ops platform, free, in a box

Everything else in this repo is the *how*. This page is the *what you actually
get*, and it's the part that was never written down. Read it even if you skim
everything else — it's the reason the method is worth learning.

**Ahab is also a curated, self-hostable operations platform**, assembled
entirely from best-of-breed open-source tools — the same tools real companies
run — wired so that **describing your machines once makes the whole platform
react.** You don't hand-configure an IPAM, then a CMDB, then a proxy, then a
monitor, then a secrets store — four times over, four times wrong. You state
your intent in one place. The rest converges.

That single idea — *one description, everywhere* — is the premium part. It's
also the easiest part to lose sight of, so it lives here, on purpose.

---

## Start small — it grows with you

**You don't have to run a fleet to use this.** One laptop, a single VM, a weekend
proof-of-concept, a club site, a two-box non-profit — ahab is built to start
*exactly* that small. It is **not a monolith** you have to buy into whole: every
layer is a readable, replaceable file, and the whole aim of these docs is that
once you see how the pieces fit, you can **refactor any of them.** This page
shows how it all *can* fit together — adopt the slice you need today, leave the
rest for later.

## The one move

Standing up a service is meant to be almost embarrassingly small:

```
1. In NetBox, add a device            “this machine exists”
2. Give it an address                 IPAM → the network is *created*
                                      (prefix, gateway, the whole addressing)
3. Tag it with a role                 that tag IS the inventory Ansible runs from
   …and the platform answers, on its own:

      NetBox      →  the single machine record (IPAM + inventory/CMDB)
      Ansible     →  converges that role onto the machine
      dnscontrol  →  publishes its canonical name (a reviewed diff, never a guess)
      Traefik     →  fronts it behind TLS at that clean name
      Uptime-Kuma →  starts watching it  (it isn't “up” until Kuma agrees)
      OpenBao     →  injects its vaulted secrets at deploy — never in a file
```

You edited **one** record. The network exists, the machine is configured, it has
a safe public name, something is watching it, and its secrets arrived without
you pasting a password anywhere. Change your mind? Edit the record; the platform
re-converges. Undo? It's a commit you revert.

That's the product. Someone who has never met IPAM or a reverse proxy can
produce a *correct, monitored, secret-managed* service — and learn, by watching
what each tool did with their one input, exactly how real infrastructure works.

> **Honest status, because we mean it.** The design is complete and coherent —
> you can read the whole arc today. The *live* stand-up is proven machine by
> machine. NetBox as the live source of truth is **milestone M3**; until it
> lands, the machine record lives in an interim Git inventory table using the
> same schema and flow (**D-37**). Uptime-Kuma's lattice is **M0**, in progress.
> Never trust "it works" over the evidence in
> **[BLUEPRINT](../BLUEPRINT.md)** — including anything on this page.

## DNS, made boring (on purpose)

Public DNS is the scariest, most irreversible part of running a site — one bad
record and the whole world can't reach you. So we made it the *least* dramatic
thing you do:

- The live zone is a code file (`dnsconfig.js`) in its own repo,
  [`dundore-dnscontrol`](https://github.com/waltdundore/dundore-dnscontrol),
  reviewed like any pull request.
- `make preview` shows the **exact** diff that will change at the registrar —
  before anything moves. You *see* it.
- One script applies it, and we confirm at the authoritative name server
  (`dig`), never against a cache that might still be lying to us.
- The naming law keeps it legible: one canonical name (A record) per machine,
  everything else a CNAME.

The endgame is that this whole loop is driven by the NetBox record itself — add
a device, its names follow — which is part of M3.

> **Honest status.** The easy-DNS path works for **`dundore.net` today**. It is
> not yet self-contained per site: the runner is wired to one domain, so other
> modules (their own zones, their own registrar credentials) don't work until the
> generic DNS machinery lifts into ahab and each module carries just its zone as
> a self-contained delta. Tracked as **D-40**. We tell you this up front rather
> than let you find it at 2 a.m.

## And the first run, too

The operator's very first contact — standing the monitoring lattice up from a
blank box — is held to the same bar: [the BOOTSTRAP
runbook](https://github.com/waltdundore/dundore-homelab/blob/prod/docs/BOOTSTRAP.md)
is written for a tired human and is meant to feel calm, honest, and nearly
effortless. Every command ends in a green light or an honest "not yet." Making
that path as premium as the platform itself is a standing goal, not a done one.

---

## Who this is for (more people than you'd think)

- **A high-school student** who wants a real project. Spin up a role, watch a
  website come alive, learn DevOps by *doing* it — safely, because a throwaway
  VM absorbs every mistake before it can hurt anything.
- **A Georgia Tech / university student** who needs honest practice. Every
  change is a commit you can read; every claim is a monitor you can check. You
  can hold the whole system in your head — which is exactly what a sprawling
  job-scheduler like **AWX** will not let you do. (AWX is supported here,
  optionally, for running things at scale — it is *not* required to learn or run
  the method. If your class is drowning in AWX config mazes, this is the legible
  alternative.)
- **A homelabber, tinkerer, or small organization** — one machine or a handful,
  a weekend PoC or a super-basic SMB deployment. You get a real platform (IPAM +
  CMDB + monitoring + secrets + GitOps) for $0 and hardware you already own: the
  professional tools, minus the enterprise tax and the lock-in. Start tiny; grow
  only if you want to.
- **An agent or model** operating the estate: one machine record, one program
  authority, every secret behind a reference. You can act correctly without
  tribal knowledge — your live context comes from the MCP channels
  ([AGENTS.md](../AGENTS.md)), your vocabulary from the [glossary](GLOSSARY.md).

## The collection (and what each piece is *for*)

Ahab assembles these; its job is the *wiring* and the *teaching*, not reinventing
any of them. A module turns on and parameterizes what it needs — never
reimplements.

| Tool | Its one job in the platform |
|---|---|
| **NetBox** | IPAM + inventory/CMDB — the single record of every machine |
| **Ansible** | the convergence engine — turns the record into a real machine |
| **dnscontrol** | DNS as code — names reviewed and verified like a PR |
| **Traefik** | the front door — TLS and clean names for every service |
| **Uptime-Kuma** | the auditor — decides out loud whether a service is up |
| **OpenBao** | secrets — the single source of secret *values* (a Vault fork) |
| **Tailscale** | the private network — reach your fleet without exposing it |
| **Gitea** *(GitHub interim)* | the forge — where changes become gated commits |
| **AWX** *(optional)* | big-fleet scheduling/execution — convenience, not a dependency |
| **Sentry** *(optional)* | the "why did it throw" channel — complements Kuma's "is it up" |

Each tool's live status is a fact, and facts live in one place:
**[BLUEPRINT](../BLUEPRINT.md)**. This table is *what a piece is for*, not
whether it's up today.

## Why it feels premium (and beats a controller maze for learning)

- **Intent in one place.** One machine record fans out to network, config, DNS,
  proxy, monitoring, secrets. No four-places-at-once editing, no drift.
- **Everything is a commit.** A student can read, line by line, exactly what the
  platform will do to a machine *before* it does it. That legibility *is* the
  teaching.
- **Every claim is a monitor.** You're never trusting a green badge that secretly
  died days ago; you watch the same dashboard everyone else does.
- **Safe to be wrong.** Prove it on a throwaway box first, in public, with
  evidence. A mistake costs a discarded VM, not someone's outage.

State hidden in a controller's database is invisible to a learner. State in git,
audited by a monitor, is a textbook that happens to also run a real fleet.

---

*Go on: [choose your door](../START_HERE.md) · [how it's built](../SPEC.md) ·
[what's true right now](../BLUEPRINT.md).*
