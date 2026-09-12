# Glossary — the words we refuse to leave undefined

Every unusual word used anywhere in this repo is defined here, in plain
language, so you never have to nod along and hope. New here? Skim the **Big
ideas**, then look a term up when it appears. An agent/model: this is your
grounding set — if a term isn't here and isn't defined at its linked home,
treat it as a defect and file it.

*How to read an entry:* **Term** — the plain-English meaning — then *(owning
doc)* where the full, authoritative definition lives if you want the detail.

> **Live facts are not kept here, on purpose.** Fleet state, service health,
> traces, and file contents change minute to minute, so an agent fetches them
> from the MCP context channels (`fleet-state`, `uptime-kuma`, `netbox`,
> `sentry`, `filesystem`, `context7`) instead of from a page that would go
> stale. See [AGENTS.md](../AGENTS.md). This page holds *vocabulary*, which is
> meant to last.

---

## Big ideas

**Ahab** — the control repo: the shared *machinery* every site reuses, so that
infra logic is written once. The acronym is **A**utomated **H**ost
**A**dministration & **B**uild. *(SPEC §1)*

**The platform / "the one more thing"** — ahab assembled into a free,
self-hostable ops platform (NetBox + Ansible + Traefik + Kuma + OpenBao + …)
where describing a machine once makes network, config, monitoring, and secrets
all react. *(docs/PLATFORM.md)*

**Teaching repo** — a codebase whose documentation is itself a product, written
to mentor newcomers (human or model) rather than assume they already know. Every
doc meets the reader at their level and links deeper instead of dumping.
*(BLUEPRINT law 10)*

**Method, not scripts** — the through-line: prove it on a throwaway box first;
nothing is "up" until a monitor says so; git is the only place state is written.

## The 3-tier split (where things live)

**Tier 1 · machinery** — ahab itself: all env-agnostic code (roles, templates,
gate scripts, CI/Makefile templates). Zero org-specific values ever live here.

**Tier 2 · module / site** — a site repo (e.g. `dundore-homelab`). Its *entire*
job is three things: **inventory**, **role assignment + values**, and **secret
references** (pointers into the vault — never the values).
*(BLUEPRINT § Portability Contract)*

**Tier 3 · content** — an application repo: only code and its deploy manifest.
Forbidden from naming hosts, secrets, or playbook paths.

**Module** — a site that plugs into the ahab framework. A module carrying its own
copy of a role ahab already owns is a **defect**, not convenience.

**Portability test** — the one question that decides a file's home: *"does this
file mention a hostname, secret, or org name?"* No → ahab. Yes → the module.

## The layers you build in (L1–L6)

Each layer is proven with *its own* test before the next is trusted — which is
why "everything is down" is felt at the top but usually broken near the bottom.

- **L1 physical** — power, cables, hardware. *Test:* ping / console.
- **L2 network** — LAN, tailnet, DHCP, router forwards. *Test:* tailscale ping,
  resolve from two vantage points.
- **L3 naming/DNS** — the zone lives in its own repo, `dundore-dnscontrol`.
  *Test:* `make preview` diff == intent → push → `dig` the authoritative NS.
- **L4 bootstrap** — blank slate → a machine ansible can reach. *Test:*
  `ansible <host> -m ping`.
- **L5 platform** — docker, traefik, monitoring, the `/nas` mount. *Test:* the
  monitoring expectation script goes GREEN.
- **L6 services** — the actual services, then content repos. *Test:* one monitor
  per service + CI.

## Keeping things alive (the loop)

**Kuma-first** — the first law: a service without a health monitor doesn't exist.

**Kuma / uptime-kuma** — the open-source monitoring dashboard that decides, out
loud, whether a service is up. It is the *auditor's* source of truth.

**Lattice** — dev watches prod, prod watches dev, and one small always-honest
machine (the **voter**) owns the only outbound alert. The box that fails is
never the one holding the phone.

**Voter** — the small machine whose single job is to tell the truth and be the
one voice that pages a human.

**Status page** — Kuma's public page; the human face of the fleet. Governed by
the hospitality law: calm at a glance, honest when red, never silent, never
blaming.

## Changing things safely (the change path)

**GitOps** — git is the single source of truth for infrastructure. No state on a
machine that wasn't converged from a commit; roll back with `git revert`.
*(canon: homelab `docs/standards/gitops-2026-09-10.md`)*

**Convergence** — bringing a machine to match its committed desired state.
State is only *produced* by convergence, never hand-typed.

**Gate** — a check that must pass before a change moves forward: mechanical
(lint, syntax, law-gate) every commit, and an **audit** every milestone.

**law-gate** — `bin/law-gate.sh`: turns the process laws into executable checks
(no conflict markers, no secret literals, branch rules, doc budget).

**Vagrant gate** — the clean-slate proving ground: a throwaway VM rebuilt from
*this code alone*, so every gap in the instructions is something *we* hit in
code, not in someone's memory.

**Promotion chain** — vagrant → test units → dev box → prod box, each stage
green in monitoring before the next.

**Trunk** — the main branch. This estate uses `prod` and `dev` (never
`main`/`master`). Probe `git branch -r`; never assume.

**AUDITED / LIVE-PROBED / UNVERIFIED** — status verbs. *LIVE-PROBED* = measured
with evidence this pass. *AUDITED* = an independent auditor granted it.
*UNVERIFIED* = not yet measured — the honest default, never a synonym for "fine."

## DNS, specifically

**dnscontrol / `dundore-dnscontrol`** — DNS-as-code: the live zone is a
JavaScript file (`dnsconfig.js`) reviewed and pushed like code. `make preview`
shows the *exact* diff that will change at the registrar before anything moves;
one script applies it; we then confirm at the authoritative name server.

**Naming law** — one canonical name (an **A** record) per machine; every alias
or service name is a **CNAME** to it. Fully-qualified names, not bare hosts.

**Registrar / authoritative NS** — where the world actually looks up your names.
Verify a change there, never against a caching resolver that may still hold a
stale answer.

## The registers (where truth and unknowns are kept)

**BLUEPRINT** — the single program authority: mission, laws, milestones, audited
facts, blockers, drift register. The only "what's true / what's next."

**M0…M6 (milestones)** — named program stages (M0 monitoring lattice; M1 ahab
skeleton; M3 NetBox SSoT; M6 developer platform). Each has an evidence-based
exit gate.

**D-register (D-01, D-38, …)** — the **drift register**: every known
inconsistency between two places that claim the same truth, with the fix and its
status. Docs get D-rows too — a page that lies about the tree is drift.

**B-register (B-001, B-017, …)** — **blockers**: what physically stops progress,
in priority order, with what unlocks each.

**OPEN-QUESTIONS** — the single home for decisions parked for a human (security,
irreversible data, public DNS, credential custody). A parked question never
idles the whole program.

## Secrets & places

**OpenBao / vault** — the single source of secret *values*. Repos carry only
*references*; a secret value never enters a commit, a prompt, or a log.

**`/nas`** — the shared network mount, intended canonical home for vaulted
secrets. A core dependency that must be Ansible-owned and *asserted*, never
assumed (a local folder silently shadowing it is a known failure class, D-02).

**DSN / Sentry** — the application error/trace channel ("why did it throw,"
complementing Kuma's "is it up"). Ahab *machinery* a module only enables and
parameterizes; the DSN is vaulted per service.

## Operating profiles (who a session is)

**Profile A · fleet node** — LAN + `/nas` + fleet keys: can do fleet-side work.
**Profile B · workstation** — GitHub + tailnet, no `/nas`/keys: docs, audits,
restructuring.
**Profile C · runner/CI** — repo + tokens: runs gates only.
*(defining doc: homelab `docs/ONBOARDING.md §1`)*
