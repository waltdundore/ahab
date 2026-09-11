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
     schedules for drift scans. Operator attested AWX is installed (docker)
     2026-09-10; API probe from d701 found hub ALIVE but no AWX port exposed
     → container startup/bind fix is part of B-001. Fallback runners: Gitea
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

## Portability Contract — the 3-tier repo split

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
| D-02 | `/nas` on d701 is a LOCAL DIR, not the NFS share from storage.dundore.net — "same path, two trees, one stale" (audit 2026-08-21); **2026-09-11: same class on sager** (findmnt empty, local secrets tree) — at least two boxes, maybe fleet-wide | nfs role mounts storage.dundore.net on every fleet node; assert mountpoint fstype=nfs4 | TODO |
| D-03 | storage (ASRock NFS server) absent from ansible inventory entirely (L-17); mgmt port unknown to us | add to inventory once reachable; nfs role owns exports config | TODO (needs console/operator facts) |
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
| D-20 | **hub AWX lives in shell-history, not code** (operator history 2026-09-10): source install of `ansible/awx` **`devel` branch** (unpinned — prior 24.3.1 broke on migrations and was rm'd), manual superuser/token creation via `awx-manage` (OAuth tokens passed through shell history = burned), UI hand-built (`make ui`, `docker cp`, `collectstatic` ×15 retry loops), `awx.dundore.net` ingress + DNS since vanished (dig empty from d701 2026-09-10) | codify bring-up as an ahab module/role on the hub: version-pinned checkout, compose env rendered from vault, idempotent migrate→superuser→token, UI from release assets not dev builds, ingress via traefik + dnscontrol record, kuma monitor (a controller without a monitor does not exist); old tokens treated as revoked | TODO (hub unlock B-002; playbook FIRST, vagrant-gated) |
| D-21 | DNS zone naming-law debt (audit 2026-09-11): service/alias **A** records (`uptime*`, `gitea`, `dev-gitea`, `traefik`, `authentik`, `flame`, `banking`, `rpi5-01-gitea`) and machine-alias A-twins (`hub`≡`asus-llm`, `arm1`≡`rpi5-01`, `arm2`≡`rpi5-02`) — ≥2 A per those machines, violates "one A per machine, rest CNAME" | dnscontrol rewrite pass: one A per machine + CNAMEs for every alias/service name; gate = `dnscontrol preview` diff == intent, then push, then dig (L3 loop) | TODO |
| D-22 | `host_vars/d701.yml` sets `uptime_kuma_domain: uptime.dundore.net` but `uptime` → **dev** (.15) in code+live — prod's kuma domain var targets the DEV box; breaks M0 "prod checks dev / dev checks prod" leg | prod kuma endpoint must get its own distinct name/IP (real prod kuma location still UNVERIFIED — B-002 hub/CONSOLE or profile-A check on d701); fix host_vars + monitor leg after that fact | TODO (needs d701 profile-A probe) |
| D-23 | SELinux unaccounted in Ansible: file-level tasks (`copy`/`template`/shell-pastes) on enforcing Fedora leave wrong contexts — the failure is silent (no "bad ownership" line in `/var/log/secure`, just `preauth` close); sager's lockout twin (0-byte `authorized_keys` + near-miss labeling) is this exact class | selinux-aware modules (`ansible.posix.authorized_key`, `file`+`sefcontext`) or explicit `restorecon` on every managed path; context asserts in verify tasks | TODO (operator-raised 2026-09-10) |
| D-24 | **gitea Git≠live (L3 break, conformance audit F1 2026-09-11):** live zone serves `gitea CNAME→dundore-sager`, `dnsconfig.js:49` says `A("gitea","10.200.10.15")` — registrar edited OUTSIDE Git after `711a389`; falsifies "Git == live zone for the first time" | decide intended placement (N-08), reconcile code↔live, re-run preview from a node WITH the binary; fold into D-21 pass | TODO (L3 loop) |

Open-source-only law: everything we ship is OSS — reinforces B-011 (ahab must
relicense off CC BY-NC-SA to an OSI license; Apache-2.0 recommended).

## Documentation Hierarchy — one authority per layer (TCP/IP style)

Each doc owns exactly ONE altitude. Higher layers cite lower layers; copying a
value/decision upward is a DRY violation (D-register applies to docs too).

| Layer | Document | Owns | May NOT contain |
|---|---|---|---|
| 1 | **ahab/BLUEPRINT.md** | mission, laws, milestones, AUDITED ledger, blockers, D-register — the only "what's true / what's next" | config values, task chatter, history |
| 2 | **repo SPEC.md** | design of that repo's layer (interfaces, contracts) | status, machine-specific facts |
| 3 | **code** (roles/, playbooks/, dnsconfig.js, module.yml) | HOW — every setting's single home | — |
| 4 | **evidence/** + audit reports | proof (test output, logs) | plans |
| 5 | CONTEXT.md / todo.md / ledgers | **historical append-only, NOT authoritative** — demoted; todo.md becomes a generated view of the BLUEPRINT register, hand-editing it is banned | authority |

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

## Milestones

| # | Milestone | Status | Exit gate |
|---|-----------|--------|-----------|
| M0 | **Monitoring lattice + ground truth** (CURRENT) | IN PROGRESS | Kill-switch drill: stop sshd on dev → prod kuma RED + pi voter alert; public status page live and ui-ux.md-reviewed (calm at a glance, honest when RED); alert copy reviewed as human-to-human; AUDITED |
| M1 | ahab control skeleton | SPEC drafted | SPEC accepted, module registry rewritten, `origin/dev` hygiene commits merged |
| M2 | Site plug-in wiring | blocked by M0 | submodules replace symlinks; DNS flip pushed from control node; d701 `/etc/hosts` law-compliant |
| M3 | NetBox inventory SSoT | blocked by M2 | seed→netbox switch; `enable: true`; AUDITED |
| M4 | aitora.org plug-in | repo **PUSHED** (origin `prod` @ `ecf02e6`, verified 2026-09-11) → zone + L0 legs remain | zone in dnscontrol; L0 vagrant evidence |
| M5 | whitecountyschools + athensarea plug-ins | not started | sites compose via manifests; AUDITED |
| M6 | **Developer platform** (portable 3-tier, webhook CI, publish→validate→confirm) | BLOCKED BY M1+M2; AWX-on-hub attested → webhook legs now buildable once B-002/B-014 unlock | `make env` bootstraps ahab+infra+content workspace; content-repo push triggers webhook → AWX Project update + Job Template lint/test/merge → confirmation + auto kuma monitor; a developer lands a change touching ONLY their content repo; AUDITED |

## Live-probed facts (2026-09-09, this session)

| Item | Status | Evidence |
|---|---|---|
| d701 = prod box | LIVE-PROBED (2026-09-09); tailnet leg REGRESSED (2026-09-11: ping-UP, absent from tailscale status, ssh key-denied from sager) | booted 23:58Z; kuma/traefik/postgres/openbao/flame/www Up; ssh via tailnet key `keys/service_id` (stale leg — see 2026-09-11 table) |
| prod kuma up but self-hosted (blind spot root cause) | LIVE-PROBED | docker ps + kuma logs on d701 |
| hub (asus-llm 10.200.10.20) | RE-POWERED; services unverified | ping OK from d701; ssh key denied (unmanaged) |
| dev kuma DOWN; sager AND hub unmanaged | **SUPERSEDED 2026-09-11** (conformance audit: FALSE) | sager managed (audits execute on it); dev Kuma **UP**: uptime.dundore.net/dashboard = 200 via traefik. Hub leg remains: unmanaged |
| **DNS flip PUSHED & LIVE** ✅ | LIVE-PROBED | dnscontrol `d9c8465` pushed via whitelisted IP; dig verifies d701→prod(.10), sager→dev(.15) |
| d701 /etc/hosts | **FAILS naming law** | legacy hostname + `project.dundore.net` alias + 127.0.1.1 line; fix via base-role convergence, not manual |
| d701 resolver | PASS | systemd-resolved→OpenDNS+MagicDNS; public zone carries private IPs |
| **M0 vagrant gate** | **AUDITED** (spark-auditor PASS 2026-09-11, scoped: evidence genuineness + law-gate + syntax on current tree; dynamic guest-box claims and full M0 exit gate out of scope) | homelab tests/evidence/bootstrap-vagrant-2026-09-09.md + verdict docs/audits/2026-09-11-queue12.md |
| pi fleet | **REACHABLE** (2026-09-11 control-node sweep from sager) | arm1/arm2/armdev/rpi5-01/rpi5-02 all ping-UP; identity/health/voter-role UNVERIFIED (next: ssh+hostname probe per fleet-key pass) |
| inventory flip d701=prod | **AUDITED (flip pair)** 2026-09-11: inventory↔DNS↔live triangle PASS; single-vantage (sager); zone naming-law debt → D-21 | homelab `699e6bf` + verdict docs/audits/2026-09-11-queue12.md |
| dnsconfig flip (dev=.15/prod=.10) | **AUDITED (flip pair)** 2026-09-11: live dig PASS, code triangle PASS, pushed & live (`711a389`); naming-law debt → D-21; `dnscontrol preview` leg NOT-TESTABLE on sager (binary absent) | dnscontrol `d9c8465`+`711a389` + verdict docs/audits/2026-09-11-queue12.md |
| aitora repo (ex-hf) | LIVE-PROBED | also PUSHED — branch `prod` @ `ecf02e6` (local==origin HEAD; trunk renamed production→prod per branch law, origin/production gone) |

## Live-probed facts (2026-09-10, git-estate reconciliation)

| Item | Status | Evidence |
|---|---|---|
| git three-way sync Mac ↔ origin ↔ d701 | LIVE-PROBED | homelab `production 7412033` / `development c2e7940` == origin == d701 repo; all prior stranded work pushed (`a445b19`, `c2e7940`) |
| d701 repo can fetch GitHub | LIVE-PROBED | read-only deploy key (GitHub key id 162907344) on d701 `/etc/dundore-git/` (0700, root); fetch+prune GREEN. Push path stays via control node |
| **sager UNLOCKED + repo audited** | LIVE-PROBED (2026-09-10) | `ansible_user`+`keys/service_id` GREEN, `hostname`=dundore-sager. Root cause of lockout: 0-byte `authorized_keys` — the fleet key push NEVER landed (L-04 residue), fixed by root paste + `restorecon`. Repo held 2 only-copy commits (banking sprint W-22/W-24/W-03) → saved to origin `rescue/sager-production-banking` (`0ee9a96`); stashes EMPTY; wdundore has working GitHub SSH push from sager. Follow-up D-16 |
| d701 was holding the only copies of two dev-branch commits + the 2026-08-19 student-safety stash | RESCUED | all now on origin; stash snapshot = branch `shelve/student-safety-law-20260819` (`dcb586b`); d701 `stash@{0}` safe to drop after review |
| process note (name-law teeth) | — | tailscale device labels ≠ machine identity: `dundore-sager-1`/`d701` mapping misled this session's first pass; a `hostname` probe before any fleet write is the L1 fact — tailscale names are not authority |
| **git estate full probe** (13 repos: `ls-remote` + shallow clones) | LIVE-PROBED | all 9 user-cited repos EXIST (SPEC §3 "fiction" claim was WRONG — corrected). Twins byte-identical: `ansible-config`≡`ahab-config` (tree `d9e9a6f`), `ansible-inventory`≡`ahab-inventory` (tree `a4ee60f`); `ahab-module-docker` = copy of `ahab-module-common` (2-file diff, contains no docker role); `ahab-modules` holds only `apache/module.yml` + committed `INITIALIZE.md` build-cruft; `MODULE_REGISTRY.yml` → 8 of 9 `ahab-module-*` repos MISSING (only `-docker` exists); `scripts` repo = 2023 fossil (own chrony.yml duplicates module-common) |
| **aitora repo is PUSHED** | LIVE-PROBED | `waltdundore/aitora` HEAD=`refs/heads/prod` @ `ecf02e6`; ref `production` no longer exists (branch-law rename) |
| **ahab working-tree hygiene FAIL** | LIVE-PROBED | 9 Makefile variants committed (incl. `backup-broken`, `bak2`, `original`, `~HEAD` fossil in ahab-inventory); two divergent `ABOUT.md` copies; `.gitmodules` (modules→ahab-modules, config-roles→ahab-config) never initialized locally; `bootstrap.sh` clones superseded twin names; zero symlinks exist though bootstrap claims to make them; local `roles/` = 3 legacy roles vs homelab's 24 live |
| hub AWX (GitOps controller candidate) | **LIVE (was FALSE)** | 2026-09-11: `https://10.200.10.20:8043/api/v2/ping/` → 200 `{"version":"24.6.2.dev881+gf1a3e13df","active_node":"awx-1","heartbeat":"2026-09-11T02:50Z"}` — web IS exposed on LAN; D-20 unpinned devel-build confirmed. Remainder: uncodified, no DNS/ingress/monitor, ssh unmanaged |

## Blockers (priority order — highest first)

| ID | Blocker | Why it stops progress | Unlock |
|---|---|---|---|
| B-001 | hub .20 UP; ports {22,9090,8043}; **AWX web IS exposed on LAN :8043** — /api/v2/ping GREEN 24.6.2.dev881 (2026-09-11; "not exposed" FALSE) | other hub services still unverified | CONSOLE (B-002 recipe) for ssh-managed hub; then service inventory |
| B-002 | **sager CLOSED 2026-09-10 — unlocked & audited** (root-pasted `authorized_keys` + restorecon; `ansible_user`+`service_id` LIVE, hostname-probed) — **hub (asus-llm) still unmanaged** | was: dev leg + hub recovery blocked; hub leg remains | CONSOLE on hub only: inject `keys/service_id.pub` for ansible_user; proven recipe: `tee -a ~/.ssh/authorized_keys` + 700/600 + `restorecon` (see D-23) |
| B-003 | ~~dev kuma DOWN~~ **CLOSED 2026-09-11** — dev Kuma UP via traefik, uptime.dundore.net/dashboard = 200 (probed from sager); M0 dev leg reachable. Playbook-produced state still pending the vagrant gate (law 1) — see queue 8 / kuma1 testbed | — |
| B-004 | ~~DNS flip unpushed~~ **CLOSED 2026-09-11** — dnscontrol `711a389` LIVE; dig re-verified from sager: dev→.15, prod→.10, d701→.10, www→dev (preview leg NOT-TESTABLE on sager: binary absent) | — |
| B-005 | ~~git auth dead on laptop~~ CLOSED 2026-09-10: gh authed as waltdundore (repo+workflow scopes); 5 pushes GREEN from laptop incl. homelab `production`/`development` | was: cannot push any repo incl. aitora | — (if it re-dies: `gh auth status` is the probe) |
| B-006 | no vault password on laptop; **none on sager either** — and `/nas` there is a local dir, NOT the NFS mount (D-02 class, conformance audit F4) | vaulted runtime verify only where /nas is truly mounted | fix D-02 (real NFS mount), then place/resolve vault per D-06 canonical path |
| B-007 | pi fleet **ping-REACHABLE 2026-09-11** (arm1/arm2/armdev/rpi5-01/rpi5-02 all UP from sager); identity/health/voter-role still unverified | voter node for lattice unknown | ssh+hostname probe per fleet-key pass (B-002 recipe) |
| B-008 | 9 stashes LOCATED 2026-09-10 — all on the **laptop** (dated 2026-08-11→2026-09-01, mostly `WIP on test` commits, one real: "local drift: opencode.json.j2"); d701's student-safety stash preserved to origin (`shelve/student-safety-law-20260819`); sager swept CLEAN (0 stashes) | hidden drift vs branches | PM decision per stash: the eight `test`-base WIPs are likely discardable; "opencode.json.j2 drift" + 2026-09-01 trio need review before drop |
| B-009 | d701 /etc/hosts stale (aliases + non-canonical name) | naming law violation; LE/cname scheme depends on it | base-role hostname enforcement after DNS push |
| B-010 | ~~spark-auditor has PASSed nothing~~ **CLOSED 2026-09-11**: queue items 1–2 audited — vagrant gate PASS (scoped), flip pair PASS; verdicts in homelab docs/audits/2026-09-11-queue12.md | was: nothing could ever be AUDITED | — |
| B-011 | ahab license CC BY-NC-SA conflicts with dogfood law's "fully open source" | blocks M1 + any public adoption | relicense MIT/Apache-2.0 (PM recommends Apache-2.0 for patent grant) before M1 merge work |
| B-012 | (ID retired — never issued; tombstone for register integrity, conformance audit 2026-09-11) | — | — |
| B-013 | repo-estate canonical name undecided (D-16): `ahab-config`/`ahab-inventory` vs their byte-identical `ansible-*` twins | cannot point AWX Projects / `repo-git` / submodule URLs anywhere until "the one repo" is fixed; wrong choice = two SSoTs (GitOps-law violation at the repo layer) | PM decision (recommend `ahab-*`); then GitHub archive-of-lossless + README redirect on the twins; record decision HERE |
| B-014 | **premise flipped 2026-09-11: endpoint IS LIVE** at `https://10.200.10.20:8043` (ping 200) — but uncodified (D-20), `awx.dundore.net` still NXDOMAIN, no ingress, no kuma monitor, tokens unverified (shell-history ones stay burned) | webhook legs now BUILDABLE, not yet wired; controller without monitor/kuma does not exist (law 2) | codified bring-up (D-20): pin version, traefik+dnscontrol record, fresh vault-stored token, kuma monitor; M6 "blocked" framing can relax to "endpoint live, wiring pending" |
| B-015 | no trunk protection enforced on any repo; direct pushes to `prod` are possible and HAVE happened (conflict markers on homelab `prod`, `6b15085`) | law 7 Tier A is advisory until a forge refuses bad merges | GitHub branch protection on `prod`/`dev` estate-wide (needs gh auth on sager, or do from laptop); Gitea inherits at init |
| B-016 | root cause SUPERSEDED by filed verdict (queue 7, homelab `d2f162a` + addendum): `ci.yml` was **INVALID YAML** (unquoted `: ` step name) → workflow rejected on EVERY event — trigger defects real but secondary. Fix branch `fix/ci-triggers-trunk-gate` (`1e2d8f9`) pushed, **UNMERGED**; trunk still YAML-invalid | Tier-A gate provably inert until PR merges + runner proven | MERGE the PR (operator click); prove runner labels; then branch protection (B-015) |

## Branch archaeology (2026-09-09)

- **homelab `origin/development` +2**: `143f265` pipeline-cruft removal + L-04 key-path comment fix; `9f60777` **repo-freshness role + deploy play (O-03)** — audit-relevant tooling, review for M1. Both need cherry-pick review into production.
- **ahab `origin/dev` +2** (2025-12-12 shellcheck hygiene in setup-secrets-repo.sh) — merge into prod for M1.
- **ahab `origin/production`**: 2024-09 separate-root lineage ("testing" x5, minimal main.yml/roles/ssh.sh) — archaeological, ignore unless M1 design review wants it.
- ahab master/workstation/milestone-system-v1 == prod (no hidden code). geekend feature/epic-001-lab +8 commits = current WIP (expected). dnscontrol production branch = merged.

## Audit queue (next spark-auditor runs)
1. ~~M0 vagrant gate~~ DONE 2026-09-11: PASS (scoped; dynamic claims transcript-only) → docs/audits/2026-09-11-queue12.md
2. ~~Inventory/DNS flip pair~~ DONE 2026-09-11: flip triangle PASS; naming-law check FAIL → D-21/D-22 filed → docs/audits/2026-09-11-queue12.md
3. homelab dev-branch commits `143f265`/`9f60777` fitness for cherry-pick
4. Split-contract lint (M6 seed): no org-specific values in ahab; no inventory/creds in content-tier repos
5. M0 UX pass (hospitality law): status page + alert copy + BOOTSTRAP.md tone reviewed against ui-ux.md by spark-auditor
6. GitOps-law conformance: PR-gate CI (yamllint+ansible-lint+syntax+`--check`), AWX Project/Job-Template/drift-schedule wiring, secret-scan clean (D-19), canonical-repo wiring post-D-16
7. ~~GitHub CI gate integrity~~ **DONE 2026-09-11**: gate FAIL verdict + YAML root cause → docs/audits/2026-09-11-queue7-ci-gate.md + BLUEPRINT conformance → docs/audits/2026-09-11-blueprint-conformance.md
8. M0 vagrant gate ROUND 2 (kuma1 blank-slate, libvirt, monitoring chain per law 1 — the dispatch cancelled 2026-09-11); L3 integrity: `dnscontrol preview` from a node with the binary + D-24 root cause (who/what edited the registrar zone)

## Live-probed facts (2026-09-11, BLUEPRINT conformance audit)

| Item | Status | Evidence |
|---|---|---|
| BLUEPRINT conformance | audited | 23 CONFIRMED / 10 STALE / 3 FALSE / 7 NOT-TESTABLE @ `1c52850`; all AUDITED rows re-verified → docs/audits/2026-09-11-blueprint-conformance.md |
| hub AWX :8043 | LIVE-PROBED | `/api/v2/ping` 200, 24.6.2.dev881, heartbeat 2026-09-11T02:50Z (see B-001/B-014) |
| dev Kuma | LIVE-PROBED | 200 via traefik (B-003 closed); playbook-produced state NOT yet — vagrant gate pending |
| pi fleet ping | LIVE-PROBED | 5/5 UP from sager (B-007) |
| gitea DNS | **Git≠live** | CNAME live vs A in code → D-24 |
| /nas on sager | NOT a mountpoint | findmnt empty, local tree → D-02 class (B-006) |
| Tier-A gate | PROVABLY INERT | trunk ci.yml YAML-invalid; today's 5 prod commits all direct pushes; fix PR unmerged → B-016/B-015 |
| d701 tailnet | REGRESSED | ping-UP but ABSENT from `tailscale status` (was "ssh OK via tailnet" 09-09); ssh key-denied from sager |
