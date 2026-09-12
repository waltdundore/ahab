# BLUEPRINT — Program Master Record

**This file is the single source of truth for direction, milestones, audited
state, and blockers.** If it is not written here with evidence, it is not true.
Updated by the project manager; only **spark-auditor** may set status `AUDITED`.
Statuses: `UNVERIFIED` → `LIVE-PROBED` (PM, evidence linked) → `AUDITED` (spark-auditor PASS).
Plan tool id: `feature_ahab-control-repo-foundation_20260909_b993` (execution detail only).

## Truth Hierarchy (operator ruling 2026-09-11)

**NetBox prod = the overall SSoT** (IPAM, inventory, assets — machines and their
addresses). **Uptime-Kuma prod = the auditor SSoT** (ping/monitor/service-test evidence —
extends kuma-first law 2: audits run against kuma, not against prose). **Git = SSoT for
code/desired state only** — narrows GitOps law 1's scope. These roles are held by the
services even while down: both MCP servers (`netbox`, `uptime-kuma`) are scaffolded into
the PM's opencode config NOW and fail loudly until M0 (kuma lattice) / M3 (NetBox SSoT)
deliver live endpoints + OpenBao-issued creds. M0/M3 are therefore prerequisite
context-channels for the whole program, not late-stage plumbing.
**Reaffirmed & elevated 2026-09-12 → law 12 (Delta law):** NetBox is the
**planner's voice** (desired state), Uptime-Kuma the **auditor's answer**
(current state) — the program's eyes, ears, and mouth. The method is working
the DESIRED → CURRENT delta: every plan names its desired-state row, every
audit answers with a monitor rather than prose, and the documentation narrates
that loop step by step for the human and the model alike.

**Sentry = the application error/trace channel** (adopted 2026-09-11): a third MCP
context-channel, complementing Uptime-Kuma without replacing it — kuma answers "is it
up," Sentry answers "why did it throw." Per the Framework/module law (§Portability
Contract) Sentry is **ahab machinery**, never per-repo hand-wiring: ahab owns the single
Sentry integration + the DSN-from-vault injection; each site module only *enables and
parameterizes* it (supplies its vaulted DSN). The MCP server is scaffolded now and the
org is empty by design until services run with a provisioned DSN; the machinery is
vagrant-gated → see D-28.

## Mission & Composition Law

Ahab = control repo; common code lives ONCE in ahab. Site repos contribute only
custom inventory, DNS, and site-specific roles:

```
ahab + dundore-homelab      = dundore.net
ahab + aitora               = aitora.org    (AI Tor Archive — magnet-first model hub, vLLM tutorials/recipes)
ahab + geekend              = geekend.org
ahab + athensarea           = athensarea.net
ahab + whitecountyschools   = whitecountyschools.net
```

Process laws (non-negotiable):
0. **Dogfood law**: the whole stack — every prerequisite, every config — must
   rebuild a **blank-slate bare-metal machine** from this code alone. Vagrant is
   the clean-slate testbed that proves it: we run OUR OWN workflow on a virgin
   box, so every gap in the prerequisites is something WE experience, and the
   fix goes into code, not into a person's memory. Fully open source, infra-as-
   code, ground up — no manual steps are allowed to exist.
1. **Ground-up**: vagrant gate → test → deploy; nothing physical untested.
2. **Kuma-first**: bring up uptime-kuma; every subsequent item is verified BY kuma. Dev checks prod, prod checks dev, pi voter checks both and owns the only outbound alert. A service without a monitor does not exist.
3. **Hospitality law (bootstrap UX)**: infrastructure exists for people, and the
   bootstrap moment is first contact — it must land viscerally, not clinically.
   Every interactive space an operator or visitor touches (runbooks, dashboards,
   the kuma **public status page**, alert copy, CI output) is bound by
   `ui-ux.md` — its scope law already says so. Validate the human: the runbook
   speaks *to* them, names what they just accomplished, and tells them why each
   gate protects *them*; an alert at 2am is a human talking to a human; RED on
   the status page must read "we're on it," never silent and never blaming.
   Rigor is how we love them; warmth is how they know.
4. **AUDITED ≠ done**: only spark-auditor grants AUDITED.
5. Builder subagent receives fully-factored specs only; it must query the PM on any ambiguity. PM executes small tasks directly.
6. **GitOps law (adopted 2026-09-10)** — Git is the single source of truth for ALL
   infrastructure; we treat every model/operator as a remote developer and
   over-communicate through versioned artifacts
   (canon: `dundore-homelab/docs/standards/gitops-2026-09-10.md`, verbatim article
   alongside it — this section is ahab-specific adaptation; canon wins on conflict,
   incl. 2026-09-10 rulings: trunk ∈ {prod, dev}, OpenBao = single source of
   secrets, Gitea = forge of record):
   - **Every change is a commit.** No state exists on a machine that was not
     converged from a commit (extends Convergence Law). Commit messages and file
     headers carry the *why*; every file must be readable cold by a stranger
     (Purpose / Owner / Consumes / Affects header where context is lacking).
   - **PR gates before merge:** yamllint + ansible-lint + `--syntax-check` +
     `--check --diff` against vagrant staging. Merge is the deploy trigger.
   - **Automated deployment:** merge to the promotion branch fires a webhook →
     **AWX on asus-llm (hub)** is the GitOps controller — Projects (SCM,
     update-on-launch), Job Templates with native GitHub webhook endpoints,
      schedules for drift scans. AWX-on-hub presence is probe-confirmed
      (B-014: LAN :8043 `/api/v2/ping` 200 — the earlier "no port exposed"
      reading was FALSE). **Operator ruling 2026-09-12: the hand-built control
      plane was never intended state — everything, including the hub's whole
      setup (AWX, Jenkins, Gitea, the workflow), is recreated from code "over
      and over and repeatedly exactly the same" (D-20).** Fallback runners: Gitea
     Actions / Jenkins (M6). Host-side convergence uses the existing
     `repo-git` ansible-pull primitive + `repo_freshness`. Hosts update
     themselves from Git; nobody hand-pushes.
   - **Drift detection is a scheduled scan** (`--check` mode) reporting to kuma —
     law 2 applies: a drift scan without a monitor does not exist.
   - **Secrets:** vault-encrypted files live in Git; the vault password lives
     only at the D-06 canonical path (`/nas/secrets/ansible/vault_pass`).
     Plaintext password literals are banned *even in examples* if plausible —
     generators emit random material or explicit `REPLACE_ME_*` tokens.
   - **Rollback = `git revert` + merge** (the pipeline does the rest); infra
     releases are semantically tagged. Hotfix = `hotfix/*` branch, single
     expedited approver, emergency rationale in the commit message.
   - **Context economy:** each doc owns one altitude (doc hierarchy §Doc-layer
     table is binding); thin entrypoints (`AGENTS.md`/README) link, never copy,
     so each model tier sees only what its layer owns.
   - **Symlink law:** symlinks are disposable local conveniences; anything that
     must survive a fresh clone is a git submodule, never a symlink.
7. **Gate law (adopted 2026-09-11, operator ruling)** — every change passes a
   two-tier gate before landing on trunk:
   - **Tier A — mechanical, every commit:** law-gate (conflict markers, secret
     literals, branch law) + lint + syntax must be enforced by the FORGE, not by
     discipline. Branch protection on trunk (`prod`/`dev`) refuses direct push
     and refuses merge on red checks. Enforcement today = GitHub (teeth pending
     B-015/B-016); Gitea inherits at initialization.
   - **Tier B — spark-auditor, every milestone event:** no BLUEPRINT row moves
     to `LIVE-PROBED`/`AUDITED`, and no SSoT status line changes, without a
     filed spark-auditor verdict in `evidence/`. PM dispatches the auditor
     **as part of the event** — audits are never deferred to a backlog.


8. **Question law (adopted 2026-09-11, operator ruling)** — a decision the PM cannot
   make (security posture, irreversible data, public DNS / prod-affecting, credential
   custody) is **parked, never idled on**: file it in `dundore-homelab/docs/OPEN-QUESTIONS.md`
   (sole home for pending questions) with what it blocks, the options, a PM recommendation,
   and what work continues meanwhile; then immediately continue an unblocked thread. Parking
   a question must never stall the program, and never silently widen scope instead.

9. **Loop law (adopted 2026-09-11, operator ruling after the estate sweep)** — a standing promise
   needs a standing check: every invariant asserted in code or docs (links alive, keypair hashes
   equal vault↔repo↔authorized_keys, registry↔disk, mountpoint-is-a-mount, config-has-a-code-home,
   branch-foldability measured by 3-dot diff, repo-freshness lint) gets an executable verifier that
   RUNS ON A SCHEDULE and reports to kuma — a failure nobody can see is a second failure. The
   rot-scan playbook + monitors are the vehicle; the lab gate itself is under check (a gate that has
   never run is rot). Whack-a-mole of findings is the symptom; the missing loop is the defect.

10. **Students-first law (operator ruling 2026-09-11; reinstates the legacy
    `DEVELOPMENT_RULES.md` value system at layer 1 — "that soul got lost
    somewhere, so it's written down now")** — the entire philosophy, three
    words: **STUDENTS FIRST**. The documentation IS the product: the customer
    experience and the operator interface are the same surface, and we never
    again let the learning surface rot while the machinery advances. Every
    human-facing artifact (entrypoints, knowledge base, runbooks, dashboards,
    alert copy, CI output) is audited and refactored in place against three
    pillars:
    - **Student Achievement** — the user can use the product effectively.
      Audience bar: an **8th-grade CS student** follows it. If they cannot, the
      surface is defective — never the student.
    - **Organizational Effectiveness** — efficient? elegant? conventional?
      Better than anything Apple would ship: the premium experience is the
      baseline, not an upsell ("one more thing" is a deliverable).
    - **Relationships and Perceptions** — the customer is our biggest advocate;
      taking care of them is the mission, and marketing is part of caring, so
      marketing tells the truth (a fake green badge is a pillar violation,
      not a typo).
    **Dogfood clause** (teeth on laws 0+6): we use exactly what they use —
    infrastructure happens through `make` targets and Ansible convergence,
    never ad-hoc scripts; a hand-run step is a defect to converge, not a
    routine to repeat. **Cartridge clause:** every module is a Nintendo
    cartridge — self-contained, plugs into ahab, carries its own prerequisites;
    what you plug in is all you need.
    **Curriculum clause (operator ruling 2026-09-11):** the knowledge base is
    a *sequenced learning path*, not an alphabetical reference. Module 0
    starts at the bootstrap — bare metal → tools (vagrant, docker) → testbed →
    first service → first monitor → RAFT consensus (quorum, leader election,
    log replication — taught by the pi-voter lattice itself: one node's claim
    is a claim, a majority's is truth) — and every module ends with a runnable
    proof. The learning design is spec'd in `docs/PEDAGOGY.md` (two students,
    one ladder — human and model; Apple-style progressive disclosure is law).
    Two legitimate students at every door: the one who fell in love
    with the work and wants the whole stack, and the CIS-101 student who needs
    their Apache server to work *tonight*. Starting at bootstrap is not a
    hindrance — it is the training, paid forward. Nobody does this: honest
    infrastructure that doubles as a school. That is the moat.
    **Legacy clause (the why — operator statement 2026-09-11):** the operator's
    grandchildren will one day learn to run their own code on this software and
    teach the next model with it. Humans train agents; agents carry the docs;
    the fleet hosts its own models — symbiotic by design. Every pillar above
    serves this legacy; when a trade-off appears, the learning surface wins.
11. **Execution-trust law (operator ruling 2026-09-11)** — the operator speaks
    ONCE; the WORKFLOW proves it happened. "I shouldn't have to look behind
    you — the workflow should handle that for me." A stop must carry a RECEIPT:
    the measurement (command + output) that forced it and the pinned-state
    workaround evaluated (worktree at HEAD, read-only partial, clean partial
    delivery); deferral on unmeasured inference is itself a fabricated blocker
    (D-44 — contention is a LOCATION question, worktree-at-HEAD always runs).
    - **Execute, don't bait.** When the brief, the laws, and the plan settle a
      choice, the agent acts. Pausing to ask a settled question, manufacturing
      a decision, or stalling to be a good conversationalist is a contract
      violation as serious as overreach. A REAL blocker is reported once, with
      the exact error and the ≤2 attempts made, then work continues on an
      unblocked thread (law 8 discipline).
    - **Trust lives in machinery, not in reports.** Compliance is proven by
      the forge and the loop — CI on push, webhook → controller flow, kuma
      monitors, rot-scan — never by an agent's own claim. B-015/B-016 are
      therefore trust infrastructure, not hygiene: while the Tier-A gate
      cannot fire, every green report is unverified prose.
    - **A surface that permits fake work is defective.** The `%:` catch-all
      (D-39) is the named precedent: it let a model run `make <anything>` and
      report success. Any surface where an unimplemented thing can look
      successful is a lie waiting to happen — it must exit non-zero, and the
      standing check for that class of lie is a verifier, not a promise
      (law 9). SRE is taught here by doing it this way, in the open.
12. **Delta law — the planner's voice and the auditor's voice (operator ruling
    2026-09-12; the design philosophy in one sentence: *show an 8th-grader how to
    go from scratch to a working DevOps homelab, one step at a time, describing
    and testing as you go, and it is all true because the same code builds it and
    the network reports on itself.*)** — we have many blockers, so we build what
    we can and **iterate it into truth** by holding two live channels open and
    working the gap between them:
    - **NetBox = DESIRED state = the planner's voice.** Every machine, address,
      role, and relationship the fleet is *meant* to have lives here first (M3;
      interim custody = `inventory/fleet.yml`, D-37). A plan that cannot name its
      NetBox/fleet-table row is not a plan — it is a guess. The planner SPEAKS by
      writing desired state; nothing is built against a fact that has no desired-state home.
    - **Uptime-Kuma = CURRENT state = the auditor's answer.** What the fleet
      *actually is doing right now* lives here — not in a prose status the PM
      hand-wrote. The auditor does not trust a claim; it **creates a monitor that
      tests the claim**, then reads monitors later for the truth (kuma-first law 2
      + loop law 9). A fact with no monitor is unverified; a PM "status" with no
      monitor is a rumor.
    - **Eyes, ears, and mouth — never optional.** NetBox and Kuma are the program's
      eyes (desired), ears (current), and mouth (the status page / plan it speaks
      back). They have been scaffolded-but-ignored; that ends now — M0 (Kuma) and
      M3 (NetBox) are the *first* context channels, and every audit reads Kuma and
      every plan reads the fleet table / NetBox. Prose status tables are a cache of
      these two, never a substitute (the moment they disagree, the prose is the defect).
    - **The whole thing is for the human.** Document for the human and design for
      the human (law 10); the LLM consumes the *same* code, the *same* fleet table,
      the *same* monitors — one source of truth serving both students. The
      documentation shows the delta being closed step by step: *here is desired,
      here is current, here is the one change that moves current toward desired,
      and here is the monitor that proves it moved.* That loop IS the curriculum,
      the method, and the product at once.


## Portability Contract — the 3-tier repo split

**Framework/module law (adopted 2026-09-11, operator ruling)** — ahab is the
**shared infrastructure code** every site needs for its infrastructure: it owns
ALL machinery, roles, templates, and logic, single-homed and env-agnostic. Every
site (`dundore-homelab`, `geekend`, `whitecountyschools`, `aitora`, `athensarea`,
…) is a **module** that plugs into that framework. A module's *entire* delta — the
only thing it contributes — is:

1. **Inventory** — which machines the site has;
2. **Role assignment** — which roles (each defined once in ahab) every inventory
   host runs, plus the variable values those roles need;
3. **Secrets** — vault references only (secret values live in the vault, never in
   the module).

We abstract **only what is different** (those three) and keep everything else
clean in ahab. Corollary — a module that carries its own copy of a role, script,
template, or Makefile is a **defect**: the generic part must move up into ahab,
leaving the module as pure deltas. This law is operationalized by the 3-tier
table below; the "test" line is its heuristic. (This is why observability,
monitoring, traefik, NFS, etc. are ahab machinery that a module merely *enables
and parameterizes* — it never reimplements them.)

Portability law: a developer must only ever edit their **content repo**. Which
files live where is decided by one test: *"does this file mention a hostname,
secret, or org name?"* — if no, it belongs in ahab.

| Tier | Repo example | Contents (exclusive) | Who edits |
|---|---|---|---|
| **1. Machinery** | `ahab` | all env-agnostic code: L0 bootstrap roles, core infra roles (docker, traefik, nfs, netbox, uptime-kuma, openbao, authentik), module system (`module.yml`, registry, compose resolver), `kuma_expect.sh`, Makefile templates, CI workflow templates, STANDARDS/BOOTSTRAP docs. **Zero org-specific values.** | PM only |
| **2. Infrastructure + variables** | `dundore-homelab`, `whitecountyschools`, … | seed inventory + netbox config, `group_vars`/`host_vars` (the ONLY place env values exist), `ahab-site.yml` manifest, DNS zones (dnscontrol dirs), site-specific roles, vault refs | infra team |
| **3. Content** | per-app/dev repos | application code, Dockerfiles, `.ahab/` deploy manifest (target site, domain, resources), tests. **Forbidden** from containing: inventory, credentials, hostnames, playbook paths | developers |

Enforcement (M1/M6): a `repo-freshness`-style **split-contract lint** (homelab
dev-branch `9f60777` is the seed) fails any PR that puts tier-2 values in tier 1
or tier-1 code in tier 3.

**Developer platform (M6, far future):** `make env` provisions a workspace from
3 pinned repos (ahab + infra-repo + content-repo). The developer changes and
publishes ONLY the content repo; publish fires a webhook → CI runner (Gitea
Actions first — it runs on our own fleet; GitHub Actions mirror for public
repos; Jenkins for heavy jobs) → lint/test → merge to protected branch →
Jenkins posts confirmation back to the dev AND registers a kuma monitor for
whatever it deployed (law: a service without a monitor does not exist).

**Consequence of law 0 (license):** "fully open-sourced" requires an OSI-approved
license. ahab is CC BY-NC-SA 4.0 (non-commercial ⇒ NOT open source). Relicensing
to MIT/Apache-2.0 is now a **prerequisite of M1**, not an open question. (B-011)

## Promotion Model — branches, OS map, gates

`development` and `production` branches carry slightly different code BY DESIGN
(env values differ), converging via merge. Promotion is one-way and gated:
every jump right requires the stage before it GREEN in kuma, evidence attached.

```
 development branch
   → vagrant debian13  (tests ARM/Debian code path)
   → RPi test units    (arm1/arm2/armdev — TRULY TEST MACHINES, not dev/prod)
   → vagrant fedora43  (tests x86/Fedora code path — d701 & sager OS)
   → sager             (DEV box, fedora43) — push, verify kuma green
   → merge development → production
   → d701              (PROD box, fedora43) — push, verify kuma green
 production branch
```

| Vagrant box | Tests code for | Role |
|---|---|---|
| debian13 | Raspberry Pi fleet (test units) | staging for ARM path |
| fedora43 | dundore-sager (dev) → d701 (prod) | staging for x86 path |

## Convergence Law & DRY-Violation Register

**Law**: every setting has exactly ONE home in code; state on machines is only
ever produced by convergence, never by hand. Any discovered inconsistency
follows: REGISTER → fix in code (vagrant-gated) → converge via playbook →
spark-audit → close here. No manual fixes, no exceptions, even to "save time."

| ID | Drift (one truth → the copies) | Code fix | Status |
|---|---|---|---|
| D-01 | Vault pass: `~/.config/ansible` vs `repo/secrets/.vault_pass` vs `/nas/secrets/ansible` | resolver in setup-control-node.yml (done, ungated); NAS mount real on all boxes (D-02) | CODE PARTIAL |
| D-02 | `/nas` on d701 is a LOCAL DIR, not the NFS share from storage.dundore.net — "same path, two trees, one stale" (audit 2026-08-21); **2026-09-11: same class on sager**; **root cause 2026-09-11: sager fstab ALREADY carries `storage.dundore.net:/volume1/nas /nas nfs _netdev` — the boot mount silently fails (storage dead, D-13) and the local tree silently shadows it**; **operator ruling 2026-09-11: /nas is a CORE DEPENDENCY — Ansible-owned, converged, asserted — never a manual step** | nfs role mounts storage.dundore.net on every fleet node; assert mountpoint fstype=nfs4; **fail LOUDLY when `/nas` exists but is not the mount while holding files (shadow-dir detection); reconcile local tree before first real mount — never silently bury it**; prove the role in-lab with a mock NFS server (storage down is not a gate exemption) | TODO (role write gated on D-25 unblock; real-target convergence gated on D-13) |
| D-03 | storage (ASRock NFS server) absent from ansible inventory entirely (L-17); mgmt port unknown to us; **operator fact 2026-09-11: storage gates NFS by client IP — export allow/deny per client — so EVERY machine we deploy to must be registered on storage.dundore.net or its /nas mount fails by design**; registration must become an inventory-derived deploy step, not folklore | add to inventory once reachable; nfs role owns exports config **from inventory (client allowlist generated from fleet hosts)**; "register client IP on storage" documented as machine-onboarding step | TODO (needs console/operator facts; re-probe 2026-09-11 from sager: ping DEAD, {2049,111,445,80} closed — D-13 stands) |
| D-04 | DNS: `ap` and `storage` both A→10.200.10.35 (documented conflict) | resolve actual IPs → single A + CNAME per naming law | TODO |
| D-05 | /etc/hosts aliases on d701 (manual fossils); naming law = 1 name/IP | base-role replace+purge tasks (written today; vagrant gate pending) | CODE DONE, GATE PENDING |
| D-06 | ~~two vault variants~~ CONFIRMED same secret (operator 2026-09-09); canonical = /nas/secrets/ansible/vault_pass | resolver merged (37d6a90); move file to /nas when L5 NFS lands (D-02) | CODE DONE, WAIT L5 |
| D-07 | ansible.cfg machine-specific paths (vault fixed today; check rest per repo) | portability lint in CI: reject absolute personal paths in repo configs | CODE PARTIAL |
| D-08 | Prod kuma monitors itself; no off-box alert | monitoring_bootstrap lattice (M0) | IN PROGRESS |
| D-09 | **DECIDED (operator 2026-09-09): (a) LAN+tailnet-only.** No public exposure; no DDNS/public A. Sites resolve/serve from LAN + tailnet only | follow-up registered as row D-09a (was forward-ref only until conformance audit 2026-09-11) | CLOSED→D-09a |
| D-09a | tailnet split-DNS: dundore.net must resolve on tailnet (registered 2026-09-11; cited by D-09 close with no row before) | operator console action; kuma probes both vantages once in place | AWAIT OPERATOR |
| D-10 | www homepage (tier content inside homelab) hardcodes legacy hostnames (`dundore-sager:5006`) | rewrite www links to canonical names; storage link (:8080) also depends on D-04 conflict being resolved | TODO |
| D-11 | flame exposed raw on d701:5005 (docker-proxy), bypasses traefik | flame labels → traefik router flame.dundore.net, drop published port | TODO |
| D-12 | **traefik broken end-to-end**: live /etc/traefik/traefik.yml has NO code home (repo template lacks dnsChallenge block — pure config drift); docker provider watch timeout (5-min cycle) → zero TLS routers → TRAEFIK DEFAULT CERT everywhere; namecheap LE env incomplete (no NAMECHEAP_API_TOKEN/REMOTEHOST); `api.insecure=true` dashboard on :8080; stale 53KB acme.json predates box swap | traefik module owns static config TEMPLATE (env from vault, token added, insecure dashboard off, provider watch fixed); converge + kuma monitors + openssl probe per cert | CODE TO WRITE (after L4 gate) |
| D-13 | storage ASRock: no answer on .35 {80,5000,5005,8080} from inside LAN (2026-09-09); box down or IP stale | operator: power/console status → enters inventory as L1 fact | AWAIT OPERATOR |
| D-14 | `ui-ux.md` is fleet-binding (hospitality law) but lives only in the aitora content repo | move to ahab control tier (e.g. `ahab/docs/UI-UX.md`) at M1; content repos cite it, never fork it | OPEN (M1) |
| D-15 | Vagrantfile forked by machine: `development` = libvirt-only (`c2e7940`, was unpushed on d701's copy) vs `production` = VirtualBox + F-5 fossil-plant gate (`cf713ba`) — same file, merge collision certain at next cross-branch merge | provider-per-host (host fact/env selects provider) or split stage-0 files; reconcile at next cross-branch merge | TODO |
| D-16 | Repo estate is a **superset, not a fork**: `ansible-config`/`ansible-inventory` are byte-identical renames of `ahab-config`/`ahab-inventory` (same tree hash) — two names, one truth, drift guaranteed | declare ONE canonical name per repo (recommend the `ahab-*` pair, matching the fleet naming law); archive/redirect the `ansible-*` twins after git-history reconciliation so nothing is lost; `repo-git`/`bootstrap.sh` point only at canonical | TODO (B-013 unlock) |
| D-17 | `ahab-module-docker` is a stale copy of `ahab-module-common` (identical except a config-lookup refactor); it ships **no** docker role. `ahab-modules` holds only `apache/` + committed `INITIALIZE.md`. `MODULE_REGISTRY.yml` names 8 non-existent `ahab-module-*` repos | module registry is the SSoT; delete phantom entries; retire per-module-repo fiction — directory-based modules live **inside ahab** (`modules/<name>/module.yml`, SPEC §3); consolidate common module into ahab, single `docker` module for real | TODO (M1) |
| D-18 | Committed build cruft everywhere: 9 Makefile variants (`backup-broken`, `bak2`, `original`, `refactored-example`, `~HEAD`…), `Makefile~HEAD` in ahab-inventory, `INITIALIZE.md` in ahab-modules, 3 duplicate Makefiles symlinked across repos by bootstrap.sh | `make` targets are the single build entrypoint; remove all `Makefile.*` backups (they live in git history now — trust but verify: git has them); replace cross-repo Makefile duplication with one file + submodules, not symlinks | TODO |
| D-19 | `ahab-secrets/scripts/setup-secrets.sh` embeds **realistic plaintext passwords** for dev AND prod (Aruba/Ruckus/SNMP) — violates GitOps-law secret clause | generator must emit `ansible-vault`-encrypted output or `openssl rand`-generated `REPLACE_ME` tokens; no plausible literal in any example, ever; spark-audit the whole secrets tree | TODO (B-014 unlock) |
| D-20 | **hub AWX lives in shell-history, not code — observed state, explicitly NOT intended state (attribution corrected 2026-09-12).** Evidence is physical, not testimony: live version string `24.6.2.dev881+gf1a3e13df.d20260730` = dev/dirty/unpinned `ansible/awx` `devel` checkout (probed 2026-09-11/12, heartbeat fresh); OAuth tokens created via `awx-manage` passed through shell history → permanently revoked; `awx.dundore.net` ingress + DNS vanished (dig empty 2026-09-10); UI hand-built (`make ui`, `docker cp`, `collectstatic` ×15 retry loops). **Operator ruling 2026-09-12: "I never said that. as a matter of fact I want everything as code. everything possible." + standing directive: "recreating these roles - awx, jenkins, gitea, the workflow, the whole setup - from code. over and over and repeatedly exactly the same. I'm giving you the tools" — shell-history is evidence of the disease, not provenance to preserve; the hub is not exempt because it is the orchestrator (D-50)** | full control-plane codification: (a) AWX: version-pinned checkout, compose env rendered from vault, idempotent migrate→superuser→token (fresh vaulted token; old ones stay revoked), UI from release assets not dev builds; (b) ingress via traefik + dnscontrol row (`awx` CNAME→hub — D-50(b)); (c) kuma monitor (law 2); (d) Jenkins, Gitea (never initialized — initialize it in code; canon: Gitea = forge of record), GitHub runners, and the webhook→controller flow enter the same code-home; (e) **reproducibility gate (trust law, "reproducibility as oracle"): the whole hub setup rebuilds from Git alone on a clean slate — twice, diff-zero — vagrant-gated (D-46)**; the live fossil gets REPLACED, not repaired (converge after B-002 key inject) | TODO (B-002 console key-inject = the one physical step; code/playbook legs authorable NOW, vagrant-gated per law; operator tools for exactly this exist: the live AWX controller, the fleet, the monitors — use them) |
| D-21 | DNS zone naming-law debt (audit 2026-09-11): service/alias **A** records (`uptime*`, `gitea`, `dev-gitea`, `traefik`, `authentik`, `flame`, `banking`, `rpi5-01-gitea`) and machine-alias A-twins (`hub`≡`asus-llm`, `arm1`≡`rpi5-01`, `arm2`≡`rpi5-02`) — ≥2 A per those machines, violates "one A per machine, rest CNAME" | dnscontrol rewrite pass: one A per machine + CNAMEs for every alias/service name; gate = `dnscontrol preview` diff == intent, then push, then dig (L3 loop) | TODO |
| D-22 | `host_vars/d701.yml` sets `uptime_kuma_domain: uptime.dundore.net` but `uptime` → **dev** (.15) in code+live — prod's kuma domain var targets the DEV box; breaks M0 "prod checks dev / dev checks prod" leg | prod kuma endpoint must get its own distinct name/IP (real prod kuma location still UNVERIFIED — B-002 hub/CONSOLE or profile-A check on d701); fix host_vars + monitor leg after that fact | TODO (needs d701 profile-A probe) |
| D-23 | SELinux unaccounted in Ansible: file-level tasks (`copy`/`template`/shell-pastes) on enforcing Fedora leave wrong contexts — the failure is silent (no "bad ownership" line in `/var/log/secure`, just `preauth` close); sager's lockout twin (0-byte `authorized_keys` + near-miss labeling) is this exact class | selinux-aware modules (`ansible.posix.authorized_key`, `file`+`sefcontext`) or explicit `restorecon` on every managed path; context asserts in verify tasks | TODO (operator-raised 2026-09-10) |
| D-24 | **DOWNGRADED 2026-09-11 (L3 container probe): the registrar edit never happened.** `dnscontrol preview` = **0 corrections** and authoritative NS (`@dns1.registrar-servers.com`) answers `gitea A 10.200.10.15` == code; SOA serial `1789082342` = the `711a389` push window, so no post-push edit is possible. The CNAME our conformance audit saw was a **stale intermediate-recursive answer past its 300s TTL** (audit dig never hit the authoritative NS; prime suspect sager's dead forwarder .10 — see D-25/D-08 class). Conformance-audit F1 is reclassified as a vantage/cache artifact; pending spark-auditor confirmation | nothing to reconcile in the zone; fix the *method* instead (audits dig authoritative NS, never a caching resolver) + keep D-21 service-name debt; D-21 stands. **ADDENDUM 2026-09-12: even `@dns1.registrar-servers.com` varies** — a lone phantom `awx A→.20` authoritative answer was measured while the SOA serial stayed `1789082342` (== no zone write; rounds 2–3 + full record set agreed zone==code). Method: an anomalous authoritative answer needs a second agreeing round before it becomes a zone FACT (registered while filing D-50) | RECLASSIFIED (auditor confirm pending); method addendum 2026-09-12 |
| D-26 | **www homepage (`dundore-homelab/www`) — the hospitality-law first-contact surface — has never been reviewed.** Findings 2026-09-11: **PII/credential-shaped data committed in index.html** (personal iCloud Numbers banking-spreadsheet URL incl. iCloud token path + `#Penfed_Bills_8026`; dermatology SSO link whose base64 `login_hint` decodes to firm/patient-login context); visitor-facing internal leakage (footer: “extracted from flame”, `todo.md W-20` citation = layer-5 in a customer surface); naming-law-violating links (raw IPs `192.168.1.254`, `192.168.1.75`; raw ports `d701:7080`, `storage:8080`; legacy `dundore-sager.dundore.net:5006` = D-10); mixed http:// on an https page; deploy route is NOT GitOps-clean (compose fragment spliced into the live monolith by `scripts/deploy-www-homepage.sh` = a drift mechanism) | rewrite links to canonical names (with D-10 pass); move personal/banking links out of the repo file (vault/1Password); footer = human-to-human, zero internal artifacts; spark-auditor ui-ux review = queue 5 MUST include www; replace splice-script route with module-owned template | TODO (filed 2026-09-11 operator prompt; audit queue 5 extended) |
| D-27 | **Two different keys both named `ansible_id.pub`**: repo `keys/ansible_id.pub` (sha `df2c1890…`) ≠ vault `/nas/secrets/ansible/ansible_id.pub` (sha `cc0e1ff9…`); only the vault pair's private half exists on sager; d701 denies all sager identities ⇒ fleet has no single key truth (D-01/D-06/D-23 class — names lie, hashes are truth) | keypair has ONE home (vault = canonical store, repo tracks the matching pubkey copy); rot-scan check (law 9): sha256 equality vault↔repo for every managed pair + authorized_keys presence probe per reachable host — fail loudly | TODO (rot-scan v1 carries the check; key convergence role after) |
| D-25 | **The lab-host NAT prerequisite lives in no code, so the vagrant gate has never run on sager.** Round-2 (2026-09-11) died at `roles/docker` with `urlopen error [Errno 101]` — guest has DHCP + route, gateway pings, guest→WAN fails. nft ruleset: `FORWARD policy drop` with **no virbr0 accept**, masquerade only for docker's 172.17/16 + 172.19/16, **nothing for 192.168.122.0/24**; firewalld (which Fedora's libvirt delegates rule-installation to) is **not running**, and libvirt's `default` net is **inactive in `qemu:///session`** — the URI vagrant actually uses (`make lab-reap` proved the orphan ran there). Round-1 evidence (2026-09-09) passed on a *VirtualBox* host, which is why this never bit before → law 0 violation: a blank-slate control node cannot run our own gate | converge the prerequisite from code: FORWARD-accept + MASQUERADE scoped to the lab net, `ip_forward` persisted, and the lab net active in the URI vagrant uses — new role/playbook, vagrant-gated, then `make lab-up` green | **UNBLOCKED 2026-09-11 — operator directive ("no more excuses… real-world testing") adopts PM narrow posture: dedicated nft table scoped to lab net + persisted `ip_forward` + `default` net active in `qemu:///session`; firewalld stays OFF; zero change to existing service exposure. 2026-09-11 re-probe: sudo -n OK; FORWARD policy drop; 7 ruleset lines mention 192.168.122 (builder classifies existing rules first); `default` net inactive @session; ip_forward=1 runtime. Builder dispatched (homelab `roles/lab_host` + converge playbook)**. **POSTURE SUPERSEDED 2026-09-12 → D-46 (operator objection): the runtime-nft mechanism this row adopted is itself the defect — see D-46 correction legs (a)–(g); lab_host code quarantined** |
| D-28 | **Sentry observability — demo projects pruned; machinery not yet built (filed 2026-09-11).** Org `walt-dundore` held 4 demo projects; `opencode`+`python` **soft-pruned** (DSNs deactivated, renamed `RETIRED-demo-*`) — permanent delete unavailable via MCP (no delete-project tool) → operator UI click. Only real code host = `banking_app` (`server.py` opt-in `send_default_pii=False`; `mcp_server.py` entrypoint wired to the app's existing `app/telemetry.py` 2026-09-11 — it previously swallowed exceptions unmonitored). `aitora` services (`catalog_api`, `inference`) exist but are **undeployed** (M4, no zone/DSN) | per Framework/module law Sentry is single-homed **ahab machinery**: one env-agnostic init + `SENTRY_DSN` injected from vault by the deploy role + a monitor per service; site modules only enable+parameterize. Machinery build is **vagrant-gated → blocked by D-25/A**. DSN custody: one vault path per service (`/nas/secrets/sentry/<service>.dsn`, 0600), never in repo. banking_app's app-local `init_sentry()` is legitimate tier-3 app code, not machinery duplication | TODO (role vagrant-gated on D-25; DSN provisioning at first deploy) |
| D-29 | **Tier-1 inversion — the framework lives in the module (refactor-drift sweep 2026-09-11).** ahab `roles/` = apache/mysql/php LAMP-era only; `kuma_expect.sh`, `site.yml`, `ahab.conf` absent (43 tracked files cite the last one); `modules/` + `config-roles/` are uninitialized submodules; duplicate `%:` catch-alls make any typo exit 0 — while dundore-homelab single-homes the L0/L5 machinery every site needs (base, bootstrap, fedora-baseline, docker, nfs, traefik, uptime_kuma*, netbox, openbao, authentik, repo-git, state_watch, common, `bin/law-gate.sh`, `scripts/kuma_expect.sh`, `mcp/fleet_state`). Inverted at the other end too: aitora carries tier-1 roles + tier-3 apps fused; banking_app leaks hostnames/playbook paths into tier 3 | M1 **is** this lift: move the org-agnostic inventory (02 §"Tier-lift-up inventory") into ahab, leaving the module as inventory + host_vars + vault refs + `module.yml`; relicense first (B-011); add the inversion leg to split-contract lint (→ D-33/V3) so a role copy inside a module fails CI | TODO (M1; evidence `docs/audits/refactor-drift-2026-09-11/` 01 F-AH01/22, 02 F-HL18/25, 04 F-ST03, 05 F-BK01) |
| D-30 | **Four convergence entry points, one of them lying (sweep 2026-09-11).** Root `main.yml` (play pinned to hub hostname), root `local.yml` (references roles `flame`/`gitea`/`github-runner` — none exist, so it dies at role resolution), `playbooks/provision.yml`, and the `repo-git` ansible-pull timer template — the last being law 6's real route, which **nothing installs** while `verify-baseline.yml:185-197` ASSERTS the timer exists. Ledger A-08 "pick one and delete the other" never executed. `roles/fedora-baseline` (14 files = the whole x86 OS path) is referenced by zero playbooks | one host-side route (repo-git + provision.yml); other three pruned or moved to named playbooks; **a verifier may assert only what convergence installs**; fedora-baseline gets an entry point or is archived | TODO (evidence 02 F-HL03/05/06/17) |
| D-31 | **`context` repo is a live reverse map of the fleet (sweep 2026-09-11).** Its agent-facing `RULES.md`/`PROJECT_OVERVIEW.md` still teach d701=dev / sager=prod — inverted by the ratified flip — and hold a second, stale home for the fleet table (asus-llm "Jenkins & GitHub Runner" vs AWX hub); 50 of 56 tracked files are a verbatim awesome-copilot/gh-aw dump whose 35 workflows target trees this repo never had, 6 of them scheduled and write-back-capable; trunk is `production` + live `main`; the keep-both-sides consolidation silently deleted 6 root docs that `RULES.md` still orders agents to read | decide the repo's fate (agent-dump → strip `.github/`; fork → LICENSE/README/upstream); mark RULES/PROJECT_OVERVIEW `SUPERSEDED — historical` so no agent consumes them as truth; drop duplicated fleet tables, link homelab README §1; trunk rename rides Q-05 | TODO (evidence 06 F-CT01–05) |
| D-32 | **Estate secret/PII chain (sweep 2026-09-11).** aitora tracks a live-format bearer token (`opencode.jsonc` — named as debt by its own template doc, never remediated) plus plaintext DSN/password literals in 5 files; `paperless/` holds 3 plaintext env files and inline weak DB passwords in the live compose guarding 70 personal PDFs (458M docs/logs/index, no backup or exclusion policy anywhere) while its vault symlink dangles (`/nas/secrets/paperless.secret` missing, `/nas` not a mount); banking_app keeps two real-finance SQLite files in the worktree (gitignored, history verified clean); www homepage PII stays D-26 | rotate/burn the token (**Q-10** — credential custody is the operator's), move every credential to vault/OpenBao per law 6, PII quarantine + backup+exclude policy **before** any estate-hygiene tooling touches the tree (**Q-11**), root `.gitignore` as interim shield while the phantom `.git` lives, relocate the SQLite worktree files | PARTIAL — Q-10/Q-11 AWAIT OPERATOR; code legs (vault refs, root .gitignore) proceed unblocked (evidence 04 F-ST01/02, 05 F-BK09, 07 F-ES07–10) |
| D-33 | **No standing verifier for the three dominant drift classes (sweep 2026-09-11; law 9 gap).** 129 findings reduce chiefly to: references that do not resolve (~20), gates that cannot fire (~8), tier-contract violations (~8) — with no executable check for any of them, each regrows silently the moment the refactor moves code. Proof this is not theoretical: `ci.yml` has been YAML-invalid on trunk since it was written, no check noticed, and pass 1–2 of an audit read it as fixed **by eye** | build rot-scan v1 per `dundore-homelab/docs/audits/refactor-drift-2026-09-11/FEEDBACK-LOOP.md` **V1–V3** (static → NOT blocked by D-25): one `make rot-scan` entrypoint + playbook, a kuma monitor per check (law 2); V4–V8 land as D-02 / forge / lab-gate unlock | TODO (design filed; builder brief for V1–V3 queued) |
| D-34 | **Inventory is not the fleet's map (fleet-blueprint probe 2026-09-11).** `storage` — which gates `/nas` for every node — appears in **zero** inventory files (`grep -c storage inventory/hosts` = 0, D-03 confirmed); the DGX Spark cluster that serves this program's own inference is known to ansible only as `gx10-741d`/`gx10-6ca0` with **no DNS record** (`spark1`/`spark-1` empty at the authoritative NS) while homelab CONTEXT §2 still asserts a `spark1.dundore.net:8000` endpoint; inventory pins `10.2.8.x` LAN IPs for boxes that are tailnet-only from here (timeout ≠ down); the hub is named bare `asus-llm` in inventory, which does not resolve from sager, so a live machine with a 200 on AWX reads as "unreachable" | every machine gets ONE canonical name in DNS + the same name in inventory (naming law, FQDN not bare host); sparks named + registered (L3 loop, then `make probe`); storage enters inventory on power-restore (D-13); tailnet-only hosts get `ansible_host` = tailnet IP or a documented jump; CONTEXT §2 endpoint claim re-verified or corrected | TODO (sparks naming = L3 loop, unblocked; storage rides D-13; inventory FQDN pass is a code fix, vagrant-gated) |
| D-35 | **The fleet layer-matrix has no standing verifier (law 9 gap).** §Fleet Blueprint above is hand-probed: its truth expires the moment a box moves, and the program has repeatedly mistaken a stale row for a live one (d701 tailnet, dev-kuma-down, sager "unlocked") | one entrypoint `make fleet-status` aggregating `make probe` + `make identity` + `make state` + `tailscale status` + authoritative-NS dig into a single timestamped artifact, classified by failure message (identity / DNS / route / key-denied / down) rather than exit code; one kuma monitor per layer column (law 2); the artifact it writes becomes §Fleet Blueprint's evidence link | TODO (builder brief; static legs unblocked, ssh legs behind Q-07) |
| D-36 | **DNS flip moved names without their serving prerequisite — zone↔router conformance has no verifier (incident 2026-09-11: operator could not reach dev Kuma).** N-09 flip moved `uptime-dev`/`dev-uptime` A records .10→.15 verified by dig (record == intent ✓) — but the dev box's traefik serves only `Host(uptime.dundore.net)`, so names landing on a box with no matching router answer traefik default **404**; prod still runs the fossil `Host(uptime-dev)` rule (forced-Host probe → .10 = 200, LIVE-PROBED 2026-09-11). Both mismatch halves live; flip evidence claimed "0 corrections" while orphaning 2 names: L3 changed without its L5/L6 counterpart, and no standing check connects a zone name to the router that must serve it (law 9 gap, D-33 class) | (a) router rules serve every zone name targeting their box — dev `kuma_traefik_labels` gains alias Host matches; (b) deploy-time assert in `monitoring_bootstrap`: post-start, probe each declared hostname through traefik, fail on 404 (a container named for its box may not be unroutable); (c) standing verifier `make name-audit`: every active zone name → authoritative dig → HTTPS probe → classify OK / 404-missing-router / down / NXDOMAIN, timestamped artifact + kuma monitor (law 2), proven by planted dead name. Zone alias hygiene (A→CNAME) stays D-21, operator-gated push; prod fossil router + `uptime_kuma_domain` stays D-22 (profile-A on .10) | TODO (builder brief dispatched 2026-09-11) |
| D-37 | **Agents reach for a hostname SSoT that is down — interim custody chain decided, table not yet built (operator prompt 2026-09-11).** The truth-hierarchy ruling seats inventory in NetBox (M3, never deployed), and agents/LLMs keep trying to resolve hosts there (netbox MCP fails by design; `inventory/netbox.yml` carries an aspirational "SSoT: All host data sourced from Netbox" header + `strict: true` — dormant today (`--list` exit 0) but enabling it without NetBox deletes the whole inventory). Meanwhile hostname facts are hand-copied across ≥3 homes (`inventory/hosts`, `dnsconfig.js`, tailscale labels) — the same root as D-34/D-21/D-36/D-04. AWX is LIVE on hub and "fills roles NetBox will handle later" — true for its **query/execution** roles, false for its **authoring** role: hand-keyed AWX inventory = state outside Git = Convergence-Law violation, D-20's exact fossil class | one canonical fleet table `inventory/fleet.yml` (tier-2): machine records (canonical name/IP/role/site/ssh-route) + service map (name → machine → serving router); generators render `inventory/hosts` + `dnsconfig.js` FROM the table, and every verifier (probe/identity/name-audit/fleet-status) reads it; agent lookup = `make lookup NAME=x` (one sanctioned answer channel). **AWX = GitOps transport + query replica: Project SCM-synced from Git, update-on-launch, inventory never hand-authored; scheduler runs drift/name-audit legs to kuma.** At M3: deploy NetBox, seed FROM the table, then flip ONE seam — the table's writer becomes NetBox-derived; consumers (ansible, dnscontrol, verifiers, MCP) unchanged. Truth-hierarchy ruling stands: NetBox remains SSoT-of-record, Git table = interim custody + seed. `netbox.yml` header corrected to "dormant until M3 — do not enable without endpoint" | **PARTIAL — services leg LIVE-PROBED 2026-09-12**: `inventory/fleet.yml` v0 seeded (machines + staged service rows incl. `stage: lab` always-makeable floor); `roles/mcp_channels` + `make mcp-config`/`make mcp-probe` render MCP channels resolving precedence **NetBox→table** (flip seam mock-proven, no server needed); probe answer: uptime-kuma-dundore LIVE(200), netbox rows honest NO-ENDPOINT — evidence homelab `tests/evidence/mcp-channels-2026-09-12.md`; **queue 16 closed AUDIT PASS 2026-09-12** (fail→fix→re-audit: fleet identities to REFERENCE §1, kuma entries launch `python3 mcp/uptime_kuma/server.py`) → verdict `tests/evidence/mcp-channels-audit-2026-09-12.md`. Remainder: generators render `inventory/hosts` + `dnsconfig.js` from table, `make lookup`, lab-VM static lease (rides D-46(a)); AWX codification rides D-20 |
| D-38 | **The front door lied (2025-12 time capsule) — and its fix never reached the register.** Cold navigation 2026-09-11 proved it (`b100faa` commit body): `make install apache` (no such role), 404 links (`TROUBLESHOOTING.md`, `README-STUDENTS.md`), a false "Tests: ✅ Passing" badge. That same commit body promised "BLUEPRINT law 10 + D-38/39/40 (next commit)" — the commit never shipped, so `START_HERE.md` cited D-38 before the row existed — a dangling reference inside our own teaching surface (D-33 class, irony registered; resolved by this row) | front door rebuilt (`b100faa`+`4ef32cd`); this row restored (2026-09-11); standing doc-verifier (dead-link + command-existence + badge-provenance) lands under D-40/M7 | ROW RESTORED; verifier pending M7 |
| D-39 | **Makefile `%:` catch-alls exit 0 on typos** (ahab `Makefile:121`+`Makefile:418`, builder-corroborated 2026-09-11) — every unknown target "succeeds"; newcomers and agents believe commands ran. **Operator evidence 2026-09-11: actively exploited as a CHEAT VECTOR — a prior model ran arbitrary `make` commands and reported fabricated success; the catch-all made every such lie untraceable. Not a UX lie anymore — an integrity hole (law 11).** Homelab Makefile CLEAN (no catch-all, grepped) | drop/replace catch-alls with an explicit failure rule (`%: ; @echo "no such target: $@" >&2; exit 2`) while preserving any legitimate dynamic dispatch; gate: `make no-such-target` exits non-zero in every repo Makefile; scan callers (bootstrap.sh etc.) for dependence on the catch-all | **FIXED 2026-09-11: ahab's two catch-alls (both pure no-ops, dispatch-free) replaced by ONE loud-failing rule at Makefile:419; gate probe `make definitely-not-a-target-zz` → EXIT=2 with named target; `-n help`/`-n install` unaffected; homelab + dnscontrol Makefiles grep-verified catch-all-free — estate-wide gate PASS. Auditor confirm folds queue 13. Fallout registered D-41/D-42/D-43** |
| D-40 | **Documentation is a product with no QA and no program home.** The knowledge base (every human-facing doc across the estate) has never been systematically audited, and no verifier checks what docs claim (links, commands, badges, audience fit). The abandonment pattern is itself the drift: `b100faa` fixed the front door, its follow-up died unwritten in a commit message — exactly the abandonment M7 exists to end. Operator doctrine 2026-09-11: audit + refactor every doc in place; customer experience and operator interface are ONE surface | M7 program: inventory every human-facing doc → mechanical gates (link/command/badge checks in rot-scan, law 9) → refactor waves (law 10 three pillars, 8th-grade bar) → spark-auditor pillar review; kuma monitor (law 2) | TODO (M7; builder unit 1 — doc-surface inventory + mechanical audit — dispatched 2026-09-11) |
| D-41 | **Three test/script assertions were green ONLY via the D-39 cheat vector** (exposed by the fix, 2026-09-11): `tests/property/test-inventory-make-commands.sh:239` asserts `make inventory-list` succeeds — no such target; `scripts/quick-test-os.sh:54` + `tests/integration/test-os-install-journey.sh:136` call `make verify-install` — no such target. They now fail LOUDLY, which is the fix working — but a verifier may assert only what the Makefile actually provides (D-30 law) | either implement the real targets (`inventory-list`, `verify-install`) or correct the assertions to existing rules; the lying-green suite must never return; rot-scan V-class: every `make <t>` cited in code/tests resolves to a rule (D-33) | TODO (next M7 unit; static, unblocked) |
| D-42 | **Generated module docs teach the invalid dispatch form** (exposed by D-39 fix): `scripts/lib/module-common.sh:79`, `scripts/lib/module-creation.sh:380-386` heredocs, `scripts/create-module.sh:62`, `tests/integration/test-apache-docker.sh:311` emit/print `make install <name>` — real interface is `make install MODULES=<name>`; the positional form now correctly exits 2 | fix the generator heredocs to the valid `MODULES=` form (docs the machine WRITES are code, not prose — law 10 dogfood clause) | TODO (M7 wave 2; static) |
| D-43 | **`make checkpoint` writes git commits** — `docs/development/Makefile.safety:26-27` (live via `-include` at `Makefile:11`) runs `git add -A && git commit`: an automated blanket-commit surface inside the build entrypoint = GitOps law 6 violation + accident amplifier (law 11: surface that can hide/destroy work) | remove the checkpoint target (history says commits are deliberate acts); audit the rest of Makefile.safety's 4 targets for git/side-effect behavior | TODO (small; next ahab-touching unit) |
| D-44 | **Stall — the failure class with no verifier (operator probe 2026-09-11: "why exactly did you stop?").** PM deferred the M0 gate unit on INFERRED contention (dirty files visible) without measuring writer activity (`stat` mtime, fleet-state heartbeats — all stale, one command each) and without evaluating the pinned workaround (`git worktree add … HEAD`). Kin: cancelled task that kept running (no heartbeat probe first), fabricated `make` success (D-39). Common root: nothing verifies that queued work MOVES, and nothing distinguishes a measured stop from a manufactured one | (a) contract teeth: stops-need-receipts — SKILL rule 0c + law 11 clause (landed 2026-09-11): every deferral cites measurement command+output and the pinned workaround evaluated; receiptless stop = fabricated blocker; (b) standing check folded into rot-scan (D-33): `make queue-liveness` — every dispatched unit >24h without evidence file/heartbeat prints STALLED, kuma monitor (law 2) | CODE PARTIAL (receipts rule landed; queue-liveness leg queued behind rot-scan v1) |
| D-46 | **Host-local imperative network state — the lab_host posture writes NAT/forward rules by live command on individual machines** (operator objection 2026-09-12: "why are you allowing direct writing of ip routes on individual machines? … the exact opposite of site reliability engineering"). The D-25 posture (PM-drafted, operator-adopted 2026-09-11) is the culprit: `roles/lab_host` installs nft table/masquerade + forward accepts for 192.168.122.0/24 via runtime commands, applied by a **human-timed `make lab-host`** on the box itself. Laws violated: **Convergence law / GitOps law 6** — execution model is someone running a prep target ad hoc, not the timer/AWX route, and no scheduled `--check` scan asserts ruleset == code, so the box's real net state is unprovable; **Truth hierarchy** — the subnet `192.168.122.0/24` is an IPAM fact hardcoded in a role variable, bypassing the interim fleet table (D-37) and NetBox custody (M3); **law 2** — the round-2 failure was exactly this: NAT silently dead, guest→WAN Errno 101 discovered mid-converge at `roles/docker`, zero alert — a network path without a monitor does not exist; **law 9** — nothing verifies the ruleset persists across reboot (runtime nft state is gone after boot unless a service reconciles it from a file); **Layer stack** — L2 behavior implemented ad hoc beneath L4/L5, so "build Ln+1 only against an Ln that passed its own test" is unachievable by construction. SRE name of the disease: **imperative per-host scripting that duplicates the network control plane's ownership** — libvirt is the declarative owner of virtual-network NAT/forwarding; when we hand-write its rules we become a second, undocumented control plane | mechanism correction: (a) the ONLY net primitive = libvirt `default` network defined + autostarted in the URI vagrant uses (`qemu:///session`) — let libvirt install and reconcile its own rules; (b) anything genuinely beyond libvirt must be **declarative files reconciled by services at boot** (nftables include file owned by nftables.service, `sysctl.d` file for ip_forward) — never runtime `nft add`/`ip route`/`sysctl -w` as the interface; (c) subnet value moves to the fleet table (D-37), roles read it from there; (d) apply route = existing `repo-git` ansible-pull timer / AWX drift scan, not human-timed make; (e) kuma monitor on the NAT path itself (guest→WAN probe) so silent death alerts (law 2); (f) verifier: `--check` ruleset==code + **boot-persistence test in vagrant** (a state that doesn't survive reboot from a file is not convergence); (g) **forge teeth**: rot-scan V-class lint flags `command/shell` tasks containing `nft add`/`nft create`/`ip route`/`iptables -I`/`sysctl -w` in any role → Tier-A CI red (law 7: enforcement by the forge, not discipline) | **FILED 2026-09-12 (operator ruling supersedes D-25 posture mechanism)**; M0 gate dispatch cancelled — not re-dispatched until correction (a)+(b) land; fix step 0 = inventory what imperative lab-net state sager currently carries; `roles/lab_host` round-3 code quarantined pending redesign brief (D-25 pointer below). **MEASURED 2026-09-12: 8 lab-net ruleset lines live on sager; written by the operator-CANCELLED gate dispatch that kept running ~9h42m after the cancel (zombie, 2nd incident of class — evidence `gate-m0-694faff/tests/evidence/m0-gate-round2-2026-09-12/`; `lab-up` failed 04:11Z, after-fail snapshot 13:53Z; orphan VM left running; no driver process remains 14:19Z); full 24h sweep → `dundore-homelab/docs/audits/2026-09-12-uncodified-24h.md`; queue 14** |
| D-47 | **Site IPs hardcoded inside machinery roles (portability-law inversion; operator ruling 2026-09-12: "things that are domain-specific need to be in the domain configuration module. only the most generic abstracted elements are in AHAB — it is a MODULAR system").** Measured 2026-09-12 (`grep` of `roles/`): **12 IP literals in defaults/vars** — `lab_host/defaults:34` (192.168.122.0/24), `uptime_kuma_monitors/vars:35-63` (an entire hardcoded dundore.net LAN table: 10.200.10.20, 10.200.10.10, 10.200.1.1, 10.200.1.5, 192.168.1.254, 10.2.8.237), `ray/defaults:2` + `vllm_cluster/defaults:15,26` (10.2.8.134), `uptime_kuma_mcp/defaults:14` (10.200.10.20). Any second site (geekend/aitora/wcss) plugging these roles in silently inherits OUR LAN — the portability test ("does this file mention a hostname, secret, or org name?") extends explicitly to **IPs/site topology: yes ⇒ not machinery**. Root cause = D-29 inversion (machinery mis-homed in the module) + no forge lint (law 9) | (a) role code keeps **zero** env values — IPs resolve from inventory hostvars / the fleet table (D-37); vars files carry names, never numbers; (b) **forge teeth** (law 7 Tier-A): rot-scan V-leg regex gate rejects IPv4 literals in `roles/**/{defaults,vars}/**` — sole exemption `# net-literal-ok: <fleet-table row ref>` naming its table source; (c) fix brief: parameterize the 12 sites, values → `fleet.yml`/`group_vars`; proven by module-swap in vagrant (same role, two different site values, both green) | **FILED 2026-09-12** — audit queue 14; evidence `dundore-homelab/docs/audits/2026-09-12-uncodified-24h.md` (A1); lint leg static/unblocked, parameterization rides D-37 table |
| D-48 | **Kuma credentials drifted outside convergence (found by the uptime-kuma MCP build 2026-09-12):** live dev Kuma rejects the canonical `/nas/secrets/uptime-kuma/password` (role rebuild token, mtime 09-11) for BOTH `admin` and `opencode-mcp` ⇒ credentials rotated on the instance outside Git (D-27/D-02 class — live state mutated by an unknown hand). Blast radius beyond the MCP: `make check` / `kuma_expect.sh` and any role seed re-run hit the same rejection — **the law-12 auditor channel is RED until re-convergence**. Adjacent finding: vault home `secrets/kuma_mcp_password.yml` absent → `deploy-uptime-kuma-mcp.yml` `vars_files` hard-fails unguarded | role owns re-convergence: one-time current-password provider (operator) → rotation task converges canonical file → `--check` assert instance==file (law 9); MCP probe check-1 goes green with zero code change; fix the unguarded vars_files; kuma monitor proves it (law 2) | **FILED 2026-09-12** — MCP server itself DONE (checks 2–4 PASS, homelab `dd510c6`); AWAIT OPERATOR for the one-time credential; queue 14 audits the drift evidence `tests/evidence/mcp-uptime-kuma-2026-09-12/`. **REFINED 2026-09-12 (physical + ledger triangulation):** not an unknown hand — container `uptime-kuma` created 09-11 20:39 EDT, healthy; the role rebuild happened, the credential re-convergence step never landed (canonical file predates rebuild, untouched since). fleet-state shows NO declaring agent (empty event log — law-9 ledger blindness, live example). **Coordination:** concurrent writer (live session, 15.9h) is uncommitted on `roles/mcp_channels` + `inventory/fleet.yml` + `mcp-config` renderer for these very channels — when it lands, the renderer MUST emit `python3 …/mcp/uptime_kuma/server.py` (not the old npx stub) for the uptime-kuma entry |
| D-49 | **geekend SPEC v0.3.0 was never pushed — the repo's own product spec is outside Git (module-readiness probe 2026-09-12).** `geekend git log --stat` shows exactly one file tracked since first commit (`README.md` = 3-line GitOps-canon pointer); yet `template/CONTEXT.md` §4.4 (2026-08-30) records a 606-line `SPEC.md` v0.3.0 + EPIC-001–006/STORY-001–051 backlog + CONTEXT/ui-ux/Vagrantfile existing in the workspace tree. Either those docs live only in an old local tree (state outside Git — law 6) or they are lost; either way the pushed repo is spec-less, and a cold agent or student opening geekend finds nothing plug-in-able (M2/M5 target: arm2) | locate the old workspace tree §4.4 names; if SPEC found → commit + push to `prod`, then re-validate its content against the 3-tier/portability laws before treating it as desired state (it predates the D-29 family); if absent → record lost and re-spec under M2/M5; README is never the spec | TODO (filed 2026-09-12; evidence: `geekend git log --stat` + `template/CONTEXT.md` §4.4, probe inline in this row) |
| D-50 | **Hub is the orchestrator, never a service host — the fleet table placed NetBox on it (operator ruling 2026-09-12, verbatim: "asus-llm is the hub controller but that is orchestrator not host … it holds awx as an orchestrator to push ansible playbooks and as a backup source of truth but prod and dev have the prod and dev versions of the stack … asus-llm is the guy that run jenkins, awx, github runners, etc.").** AWX on hub re-probed LIVE this pass (`/api/v2/ping/` → 200, v24.6.2.dev881, heartbeat fresh) — role = control plane + backup truth ONLY (D-37: transport/query replica, never author). Placement defect measured: `inventory/fleet.yml` netbox planned row targeted `machine: hub` at `http://asus-llm.dundore.net:8000` — legacy-alias name + raw port bypassing the role's traefik Host rule (D-36 class) + a service hosted on the orchestrator. Zone↔code churn observed mid-probe RESOLVED as registrar NS-set variance, NOT drift (SOA serial static → see D-24 addendum) | (a) `fleet.yml` netbox retarget: stage `dev` → `https://netbox.dundore.net` (machine dev; promotion model stages dev first) + stage `prod` reserved `url: ""` (kuma/D-22 shape) — **EDITED 2026-09-12**, rides the mcp unit's commit (file still untracked); (b) dnscontrol desired rows at M3: `netbox` CNAME→(dev, later prod), `awx` CNAME→hub — naming law = service names are CNAMEs (D-21 hygiene); `dnscontrol preview` diff==intent → operator-gated push → dig NS set (D-24 method); (c) deploy NetBox via `roles/netbox` on the DEV box (traefik proven there serving kuma; hub untouched) — blockers: `netbox_secret_key`/DB-password custody needs vault reachability (D-02/B-006 legs) or operator ceremony; (d) kuma monitor on the netbox URL at deploy time (law 2; role-managed monitors await D-48/Q-02 credential re-convergence) | **FILED 2026-09-12 (operator ruling)** — leg (a) edited-in-tree; (b)–(d) = M3 unit |
| D-51 | **The environment selector (git branch) is hardcoded — nothing reads it from git (operator observation 2026-09-12: "if the branch name was read from the current git branch instead of hard coded … we claim to use gitops workflow, I don't see evidence we have built that into the workflow").** Measured 2026-09-12: `roles/repo-git/defaults/main.yml:10` pins `repo_git_branch: "prod"` with **zero** host_vars/group_vars overrides ⇒ dev box would converge from the prod literal; estate-wide grep for live-branch readers (`rev-parse --abbrev-ref` / `symbolic-ref` / `branch --show-current`) = **0 consumers** (one Makefile comment names the probe; nothing executes it) — the branch-carries-the-environment premise of the promotion model exists in no code. Sharper finding: `ansible-pull.service.j2` ExecStart passes **no branch flag at all** → the timer follows remote HEAD while the role's sync task follows the `prod` literal — two branch control planes silently disagreeing (D-46 class). Role itself has zero playbook consumers (D-30 re-confirmed) | (a) single effective-branch primitive with explicit precedence: `repo_git_branch` var override > live checkout branch (`git branch --show-current` in `repo_git_dir`) > documented interim default; ExecStart pinned `-s <effective branch>` — ONE control plane; (b) authoritative desired value = per-machine `tracks:` column in the fleet table (D-37), drift scan asserts checkout == table row (law 9) — branch-as-current-state alone is not convergence; (c) ci.yml trigger names stay static legitimately (forge metadata read pre-checkout) but must match canon {prod,dev} — B-016 thread | **FILED 2026-09-12** — Unit A (`roles/repo-git` parameterization + `-s` pin; static acceptance, vagrant gate rides D-46/B-017) dispatched; Unit B (fleet-table `tracks:` + drift assert) rides the concurrent writer's `inventory/fleet.yml` landing |
| D-45 | **README prose inverted the truth after D-39 was fixed** (builder caught it authoring Module 0, 2026-09-12): `README.md:43-46` taught "the Makefile carries a catch-all `%:` → `make <anything>` exits 0; target truth = rule list, not exit code" — days after the catch-all became exit-2-loud. Same class as D-41/D-42: a code fix landed in the machine but not in the teaching surface; a learner following the README would learn to distrust a truthful exit code | rewrote the README parenthetical to the true loud-fail behavior (PM direct, trivial); rot-scan V-class (D-33): every prose claim about behavior must name its verifier (badge-provenance leg, M7) | FIXED 2026-09-12 (auditor confirm folds into queue 13) |

Open-source-only law: everything we ship is OSS — reinforces B-011 (ahab must
relicense off CC BY-NC-SA to an OSI license; Apache-2.0 recommended).

## Documentation Hierarchy — one authority per layer (TCP/IP style)

Each doc owns exactly ONE altitude. Higher layers cite lower layers; copying a
value/decision upward is a DRY violation (D-register applies to docs too).

| Layer | Document | Owns | May NOT contain |
|---|---|---|---|
| 1 | **ahab/BLUEPRINT.md** | mission, laws, milestones, AUDITED ledger, blockers, D-register — the only "what's true / what's next" | config values, task chatter, history, **dated probe/state tables (→ docs/state/, layer 5)** |
| 2 | **repo SPEC.md** | design of that repo's layer (interfaces, contracts) | status, machine-specific facts |
| 3 | **code** (roles/, playbooks/, dnsconfig.js, module.yml) | HOW — every setting's single home | — |
| 4 | **evidence/** + audit reports | proof (test output, logs) | plans |
| 5 | CONTEXT.md / todo.md / ledgers / **ahab `docs/state/`** | **historical append-only, NOT authoritative** — demoted; todo.md becomes a generated view of the BLUEPRINT register, hand-editing it is banned | authority |

## Infrastructure Layer Stack — build order (each layer gated by ITS test)

```
L1 physical   power, cables, hardware facts (operator-owned → REGISTERED as data)
              test: ping/console
L2 network    LAN, tailscale, DHCP reservations, router port-forwards (modeled!)
              test: tailscale ping, dig from two vantage points
L3 naming/DNS dundore-dnscontrol — SEPARATE REPO, separate layer, own test loop
              test: dnscontrol preview diff == intent, then push, then dig
L4 bootstrap  blank slate -> ansible_user/keys/baseline (vagrant gate FIRST)
              test: ansible <host> -m ping + base-role verify
L5 platform   docker, traefik, kuma lattice, NFS mount
              test: kuma_expect.sh GREEN
L6 services   netbox, auth, www, … then content repos (tier 3)
              test: kuma monitor per service + CI
```
You may not build Ln+1 against an Ln that has not passed its own test — this is
why "everything is down" is felt at L6 when the break was at L2/L3.

**Change law:** *keep changing, keep testing — a change without its layer test
executed (evidence filed) is not a change, it is damage.* Vagrant is the L4
clean-slate proving ground; dundore-dnscontrol is the L3 proving ground.

## Where state lives (law 12 — query it, never transcribe it)

LIVE state is **queried**, never copied into this file: **fleet-state MCP**
(repo/git/agent/lab state), **uptime-kuma MCP** (current state = the auditor's
answer), **netbox MCP** (desired state = the planner's voice; interim custody =
homelab `inventory/` + `fleet.yml` until M3). On 2026-09-12 the dated probe
tables, the expired fleet matrix, branch archaeology, and closed blockers moved
out of this file to [docs/state/PROBED-2026-09.md](docs/state/PROBED-2026-09.md)
(layer-5 history). When prose and a channel disagree, the prose is the defect.

## Milestones

| # | Milestone | Status | Exit gate |
|---|-----------|--------|-----------|
| M0 | **Monitoring lattice + ground truth** (CURRENT) | IN PROGRESS | Kill-switch drill: stop sshd on dev → prod kuma RED + pi voter alert; public status page live and ui-ux.md-reviewed (calm at a glance, honest when RED); alert copy reviewed as human-to-human; AUDITED |
| M1 | ahab control skeleton | SPEC drafted | SPEC accepted; module registry rewritten; **plug-in socket IMPLEMENTED** — probe 2026-09-12 measured **zero implementations estate-wide** (`modules/` and `config-roles/` empty; no `ahab-site.yml` in any repo; `scripts/ahab-compose.sh`, `kuma_expect.sh`, `site.yml`, `ahab.conf` absent; zero `.ahab/` manifests) ⇒ **no site module can plug in anywhere until M1 lands** (D-29); `origin/dev` hygiene commits merged |
| M2 | Site plug-in wiring | blocked by M0 | submodules replace symlinks; DNS flip pushed from control node; d701 `/etc/hosts` law-compliant |
| M3 | NetBox inventory SSoT | blocked by M2; deploy target = **dev→prod boxes — hub is orchestrator-only** (operator ruling 2026-09-12, D-50) | seed→netbox switch; `enable: true`; kuma monitor on the netbox endpoint (law 2); AUDITED |
| M4 | aitora.org plug-in | repo **PUSHED** (origin `prod` @ `ecf02e6`, verified 2026-09-11) → zone + L0 + **split** legs remain. Module-readiness probe 2026-09-12: aitora is **not yet a module** — standalone monolith (own L0 roles `system_prep`/`ansible_user`/`docker_engine`/`platform_stack` run by its own `playbooks/site.yml`; `services/` tier-3 apps fused in; no `ahab-site.yml`; repo docs cite GitOps canon only, zero mention of the 3-tier contract) | zone in dnscontrol; L0 vagrant evidence; **split leg** (module↔content refactor, D-29): infra delta → pure module (`ahab-site.yml` + inventory + host_vars + vault refs), `services/` → tier-3 content repo carrying `.ahab/` manifest, own L0 roles retired into ahab, `ui-ux.md` cited not forked (D-14) |
| M5 | whitecountyschools + athensarea plug-ins | not started | sites compose via manifests; AUDITED |
| M6 | **Developer platform** (portable 3-tier, webhook CI, publish→validate→confirm) | BLOCKED BY M1+M2; AWX-on-hub attested → webhook legs now buildable once B-002/B-014 unlock | `make env` bootstraps ahab+infra+content workspace; content-repo push triggers webhook → AWX Project update + Job Template lint/test/merge → confirmation + auto kuma monitor; a developer lands a change touching ONLY their content repo; AUDITED |
| M7 | **Students-first knowledge base** (documentation refactor program, opened 2026-09-11; wave 0 = front door rebuilt `b100faa`+`4ef32cd`, doctrine now law 10) | IN PROGRESS — waves 0–2 LANDED, verifier + auditor gate outstanding. Done: doctrine + D-38/39/40/45 + curriculum/legacy clauses + `PEDAGOGY.md`; wave 1 fossil archive `1cbeef6`; unit-1 doc-surface inventory **DONE** `efd6082` (210 docs, 204 mechanical findings); wave 2 **Module 0 curriculum shipped** `9d1ee6a` (ladder index + rungs 1–3, every `make` rule verified to resolve — D-41 satisfied). NOT done: doc verifier standing (`make rot-scan` V-leg, D-33/D-40) + spark-auditor three-pillar pass (queue 13). plan `docs_students-first-documentation-refactor-m7_20260911_627c` | Every tracked human-facing doc: zero dead links, every cited command resolves to a real make rule, no assertion without a verifier, 8th-grade CS audience bar; spark-auditor three-pillar PASS (folds queue 5); verifiers standing + kuma monitors (laws 9+2) |
| M8 | **Template cartridge** (operator ruling 2026-09-11, order clause included) — the law-10 Nintendo cartridge: an educational site-module plug-in teaching the ENTIRE setup procedure, plus the **recommended-tools layer**: opencode + the MCP server fleet with install converged to code and a parameterized `opencode.jsonc` template (secrets via vault/env, never in repo). Seed material exists: `template/` repo (Gate-1 skeleton) + homelab's `opencode.json.j2` config distribution (L-15/L-29, B-008 stash review pending) — but template/SPEC.md's "workspace instance" model (clone base + SHA-pinned content submodules) MUST be reconciled to the 3-tier cartridge model first (D-17/D-29 family) | **PARKED BY DESIGN — must NOT ship early** (operator ruling: ships only after the full procedure has actually run correctly, in order, with M0–M6 evidence, documented (M7) and repeatable (law 0 vagrant proof); the tool layer rides M6's `make env`) | A newcomer plugs the cartridge into ahab on a blank-slate machine, follows ONLY its README, stands up a working site + agent tool layer, and produces clean vagrant evidence — without asking a human |

## Blockers (priority order — highest first)

| ID | Blocker | Why it stops progress | Unlock |
|---|---|---|---|
| B-001 | hub .20 UP; ports {22,9090,8043}; **AWX web IS exposed on LAN :8043** — /api/v2/ping GREEN 24.6.2.dev881 (2026-09-11; "not exposed" FALSE) | other hub services still unverified | CONSOLE (B-002 recipe) for ssh-managed hub; then service inventory |
| B-002 | **sager CLOSED 2026-09-10 — unlocked & audited** (root-pasted `authorized_keys` + restorecon; `ansible_user`+`service_id` LIVE, hostname-probed) — **hub (asus-llm) still unmanaged** | was: dev leg + hub recovery blocked; hub leg remains | CONSOLE on hub only: inject `keys/service_id.pub` for ansible_user; proven recipe: `tee -a ~/.ssh/authorized_keys` + 700/600 + `restorecon` (see D-23) |
| B-006 | no vault password on laptop; **none on sager either** — and `/nas` there is a local dir, NOT the NFS mount (D-02 class, conformance audit F4) | vaulted runtime verify only where /nas is truly mounted | fix D-02 (real NFS mount), then place/resolve vault per D-06 canonical path |
| B-007 | pi fleet **ping-REACHABLE 2026-09-11** (arm1/arm2/armdev/rpi5-01/rpi5-02 all UP from sager); identity/health/voter-role still unverified | voter node for lattice unknown | ssh+hostname probe per fleet-key pass (B-002 recipe) |
| B-008 | 9 stashes LOCATED 2026-09-10 — all on the **laptop** (dated 2026-08-11→2026-09-01, mostly `WIP on test` commits, one real: "local drift: opencode.json.j2"); d701's student-safety stash preserved to origin (`shelve/student-safety-law-20260819`); sager swept CLEAN (0 stashes) | hidden drift vs branches | PM decision per stash: the eight `test`-base WIPs are likely discardable; "opencode.json.j2 drift" + 2026-09-01 trio need review before drop |
| B-009 | d701 /etc/hosts stale (aliases + non-canonical name) | naming law violation; LE/cname scheme depends on it | base-role hostname enforcement after DNS push |
| B-011 | ahab license CC BY-NC-SA conflicts with dogfood law's "fully open source" | blocks M1 + any public adoption | relicense MIT/Apache-2.0 (PM recommends Apache-2.0 for patent grant) before M1 merge work |
| B-013 | ~~undecided~~ **DECIDED (PM 2026-09-11): canonical = `ahab-config`/`ahab-inventory`** (matches fleet naming law); all wiring (AWX Projects, `repo-git`, submodule URLs) targets `ahab-*` only | was: cannot point AWX Projects / `repo-git` / submodule URLs anywhere until "the one repo" is fixed | twins → lossless GitHub archive + README redirect once gh auth exists on this node (absent on sager); residual work tracked in D-16 |
| B-014 | **premise flipped 2026-09-11: endpoint IS LIVE** at `https://10.200.10.20:8043` (ping 200) — but uncodified (D-20), `awx.dundore.net` still NXDOMAIN, no ingress, no kuma monitor, tokens unverified (shell-history ones stay burned) | webhook legs now BUILDABLE, not yet wired; controller without monitor/kuma does not exist (law 2) | codified bring-up (D-20): pin version, traefik+dnscontrol record, fresh vault-stored token, kuma monitor; M6 "blocked" framing can relax to "endpoint live, wiring pending" |
| B-015 | no trunk protection enforced on any repo; direct pushes to `prod` are possible and HAVE happened (conflict markers on homelab `prod`, `6b15085`) | law 7 Tier A is advisory until a forge refuses bad merges | GitHub branch protection on `prod`/`dev` estate-wide (needs gh auth on sager, or do from laptop); Gitea inherits at init |
| B-016 | root cause SUPERSEDED by filed verdict (queue 7, homelab `d2f162a` + addendum): `ci.yml` was **INVALID YAML** (unquoted `: ` step name) → workflow rejected on EVERY event — trigger defects real but secondary. Fix branch `fix/ci-triggers-trunk-gate` (`1e2d8f9`) pushed, **UNMERGED**; trunk still YAML-invalid | Tier-A gate provably inert until PR merges + runner proven | MERGE the PR (operator click); prove runner labels; then branch protection (B-015) |
| B-017 | **Vagrant gate cannot run on sager (D-25).** Lab-net NAT/forward rules absent and unowned by code; also a second, still-unfixed Tier-A defect found 2026-09-11: `ci.yml` triggers on `dev`, but this repo's trunk pair on the forge is `prod`+`development` — and job 2 keys off `refs/heads/development`, so the health job can never fire | M0 round 2 + every future L4 gate is blocked; the Tier-A gate is inert for TWO independent reasons | **2026-09-11 operator directive received → PM narrow-rules posture ADOPTED** (see D-25); role + converge + `make lab-up` green dispatched to builder; ci.yml trunk-ref fix stays in the B-016 PR thread |

## Audit queue (next spark-auditor runs)
1. ~~M0 vagrant gate~~ DONE 2026-09-11: PASS (scoped; dynamic claims transcript-only) → docs/audits/2026-09-11-queue12.md
2. ~~Inventory/DNS flip pair~~ DONE 2026-09-11: flip triangle PASS; naming-law check FAIL → D-21/D-22 filed → docs/audits/2026-09-11-queue12.md
3. homelab dev-branch commits `143f265`/`9f60777` fitness for cherry-pick
4. Split-contract lint (M6 seed): no org-specific values in ahab; no inventory/creds in content-tier repos
5. M0 UX pass (hospitality law): status page + alert copy + BOOTSTRAP.md tone reviewed against ui-ux.md by spark-auditor
6. GitOps-law conformance: PR-gate CI (yamllint+ansible-lint+syntax+`--check`), AWX Project/Job-Template/drift-schedule wiring, secret-scan clean (D-19), canonical-repo wiring post-D-16
7. ~~GitHub CI gate integrity~~ **DONE 2026-09-11**: gate FAIL verdict + YAML root cause → docs/audits/2026-09-11-queue7-ci-gate.md + BLUEPRINT conformance → docs/audits/2026-09-11-blueprint-conformance.md
8. M0 vagrant gate ROUND 2 — **ran 2026-09-12 via the ZOMBIE dispatch** (operator-cancelled but kept running — 2nd incident of class, see D-46 measurement) and died at `lab-up`; evidence `gate-m0-694faff/tests/evidence/m0-gate-round2-2026-09-12/`. Re-run is now gated on **D-46 correction legs (a)+(b)** — the posture that ran is superseded (operator objection 2026-09-12). L3 integrity leg **DONE** 2026-09-11: `make preview` via container = 0 corrections, authoritative NS == code → D-24 downgraded to cache artifact (auditor to confirm; also confirm the audit-method fix: dig authoritative NS, never a caching resolver)
9. Cold-start/entrypoint conformance (plan `…_b618`): README-vs-reality defects in both repos — `bin/pipeline-run` cited but absent, `secrets/vault.yml` claimed tracked but `secrets/` absent, `ahab/README.md` never links BLUEPRINT.md and recommends a nonexistent `make ui`, dead `RELEASE_NOTES_v0.1.1.md` badge link, README §5 CI prose ≠ `ci.yml`. Auditor to re-run the cold-start pass after the wave-2 rewrite
10. New `Makefile` command surface (homelab ~~14~~ **16** targets — count re-verified 2026-09-11 by `make help`, F-HL23; + dnscontrol 3): lint-gate faithfulness to `ci.yml`, no weakened assertions, `lab-reap` CONFIRM gate, no `push` target by design. Evidence: homelab `tests/evidence/command-surface-2026-09-11.md`
11. **rot-scan v1 (V1–V3)** review once built — do a verifier's own job first: plant a dead reference and a fake branch trigger, require non-zero exit, then require zero on a genuinely clean tree (D-33; design `dundore-homelab/docs/audits/refactor-drift-2026-09-11/FEEDBACK-LOOP.md`)
12. Refactor-prep drift sweep **DONE 2026-09-11** (7 finding files, 129 findings, 9 repos) → index `dundore-homelab/docs/audits/refactor-drift-2026-09-11/00-index.md`; the sweep audited *content*, so the register rows it produced (D-29…D-33) still need their own fix→vagrant-gate→audit loop; queue items 4/5/6 are the natural consumers of its findings
13. **M7 wave review** (opened 2026-09-11) — once doc-surface inventory + wave 1 land: three-pillar + 8th-grade bar on the refactored doc set (folds queue 5's ui-ux pass in); plus test-of-the-test — plant a dead link and a fake command citation, require the doc verifier to exit non-zero, then zero on a clean tree
14. **24h uncodified-changes audit** (opened 2026-09-12, operator directive "review all changes in the past 24 hours") — independently verify A1–A7 + B3 of `dundore-homelab/docs/audits/2026-09-12-uncodified-24h.md`: D-47 IP-literals table (12 sites, re-grep), zombie-dispatch evidence chain (cancelled task mutated host nft state — verify logs + VM + ruleset triangulation), boot persistence of the live lab-net rules (or absence), `/etc/sysctl.d/99-ahab-lab.conf` role-ownership (B3), concurrent-writer tree disposition (A4), AWX account + credential-location risks (A5), Sentry receipt-only status (A6), lab VM inventory (A7); verdict into that same folder. Cited by D-46/D-47 — a cited queue item must exist (D-38 dangling-reference lesson; this row was created same pass as its citations)
15. **Law-12 doctrine-alignment sweep + archive (operator directive 2026-09-12)** — review EVERY human-facing doc across the estate (ahab + all site modules) and archive anything not aligned to the law-12 design philosophy: an 8th-grader's one-step-at-a-time path from scratch to a working DevOps homelab, described AND tested as you go, all truth in code, feedback built into the network, documented for the human, with the NetBox(desired)↔Kuma(current) delta as the organizing loop. Non-aligned docs (prose status with no monitor, aspirational commands, org values in machinery, dead references, walls-of-prose that blow a model's context) → `docs/archive/2026-09/` with a redirect banner. Runs under M7 wave machinery; PM announces before each cut so concurrent writers aren't mid-edit on an archived file.
16. ~~MCP channels from fleet table~~ **DONE 2026-09-12 — Unit A AUDIT PASS** (fail→fix→re-audit cycle: check-12 fleet identities → REFERENCE §1 verbatim; kuma entries switched from npx stub to `python3 mcp/uptime_kuma/server.py` per D-48 coordination; PM fixture ripple-fix `machine: dev` on re-run) → verdict `dundore-homelab/tests/evidence/mcp-channels-audit-2026-09-12.md`. **Unit B** (netbox in lab monolith + lab-kuma monitor on it, proven LIVE via `make lab-up`) remains gated on D-46(a)(b)/B-017. — original brief: (plan `feature_render-mcp-channels-from-fleet-table_20260912_8093`; row created 2026-09-12 in the same pass as its D-37 citation — D-38 dangling-reference lesson: an earlier PM summary cited this row before it existed, corrected here) — spark-auditor re-runs Unit A's 9 acceptance checks fresh in `/home/wdundore/git/dundore-homelab`: syntax-check; render to /tmp + `python3 -m json.tool`; `{file:` cred-indirection count ≥3; mock fixture OVERRIDES table rows (`grep netbox-mock:8000` in mock-render ≥1, in table-render ==0); zero IPv4/org literals in `roles/mcp_channels/`; probe (`MCP_CONFIG=/tmp/…/mcp-generated.json make mcp-probe`) shows uptime-kuma-dundore LIVE + netbox NO-ENDPOINT + non-zero exit (make exits 2 on failed recipe — that satisfies the non-zero contract, do NOT expect rc 1); `make definitely-not-a-target-zz` rc 2; `git status` ownership-clean (note: `roles/base` dirty = pre-existing other writer, NOT this unit). Plus test-of-the-test: hand-make a tiny generated-config in /tmp with one deliberately dead URL → probe must verdict NO-ENDPOINT and exit non-zero. Plus hospitality/8th-grade read of `docs/mcp-channels.md` (bootstrap order lab-up→mcp-config→mcp-probe→OPENCODE_CONFIG; Kuma agent-user one-time ceremony; multi-site plug-in; trust-LIVE-not-config). File verdict `dundore-homelab/tests/evidence/mcp-channels-audit-2026-09-12.md`. Unit B (netbox in lab monolith + kuma monitor on it) NOT in scope — gated on D-46(a)(b)/B-017.

