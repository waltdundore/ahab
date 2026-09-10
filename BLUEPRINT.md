# BLUEPRINT — Program Master Record

**This file is the single source of truth for direction, milestones, audited
state, and blockers.** If it is not written here with evidence, it is not true.
Updated by the project manager; only **spark-auditor** may set status `AUDITED`.
Statuses: `UNVERIFIED` → `LIVE-PROBED` (PM, evidence linked) → `AUDITED` (spark-auditor PASS).
Plan tool id: `feature_ahab-control-repo-foundation_20260909_b993` (execution detail only).

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
3. **AUDITED ≠ done**: only spark-auditor grants AUDITED.
4. Builder subagent receives fully-factored specs only; it must query the PM on any ambiguity. PM executes small tasks directly.

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
| D-02 | `/nas` on d701 is a LOCAL DIR, not the NFS share from storage.dundore.net — "same path, two trees, one stale" (audit 2026-08-21) | nfs role mounts storage.dundore.net on every fleet node; assert mountpoint fstype=nfs4 | TODO |
| D-03 | storage (ASRock NFS server) absent from ansible inventory entirely (L-17); mgmt port unknown to us | add to inventory once reachable; nfs role owns exports config | TODO (needs console/operator facts) |
| D-04 | DNS: `ap` and `storage` both A→10.200.10.35 (documented conflict) | resolve actual IPs → single A + CNAME per naming law | TODO |
| D-05 | /etc/hosts aliases on d701 (manual fossils); naming law = 1 name/IP | base-role replace+purge tasks (written today; vagrant gate pending) | CODE DONE, GATE PENDING |
| D-06 | ~~two vault variants~~ CONFIRMED same secret (operator 2026-09-09); canonical = /nas/secrets/ansible/vault_pass | resolver merged (37d6a90); move file to /nas when L5 NFS lands (D-02) | CODE DONE, WAIT L5 |
| D-07 | ansible.cfg machine-specific paths (vault fixed today; check rest per repo) | portability lint in CI: reject absolute personal paths in repo configs | CODE PARTIAL |
| D-08 | Prod kuma monitors itself; no off-box alert | monitoring_bootstrap lattice (M0) | IN PROGRESS |
| D-09 | **CORRECTED**: NAT chain fully intact (ATT Global 80→Ruckus host8080→.10:80, 443→8443→.10:443, proven via operator tables + d701 egress == root A). True cause of WAN 000: **service CNAMEs resolve to PRIVATE A records — sites are LAN-only by design**, external visitors never worked | DECISION NEEDED: (a) declare LAN+tailnet-only (add tailnet DNS, close D-09), (b) public A records for exposed services via DDNS, or (c) publish via reverse-proxy off the NAS/box. PM recommends (a) now, (b) per-service when real users need it | DECISION PENDING |
| D-10 | www homepage (tier content inside homelab) hardcodes legacy hostnames (`dundore-sager:5006`) | rewrite www links to canonical names; storage link (:8080) also depends on D-04 conflict being resolved | TODO |

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
| M0 | **Monitoring lattice + ground truth** (CURRENT) | IN PROGRESS | Kill-switch drill: stop sshd on dev → prod kuma RED + pi voter alert; AUDITED |
| M1 | ahab control skeleton | SPEC drafted | SPEC accepted, module registry rewritten, `origin/dev` hygiene commits merged |
| M2 | Site plug-in wiring | blocked by M0 | submodules replace symlinks; DNS flip pushed from control node; d701 `/etc/hosts` law-compliant |
| M3 | NetBox inventory SSoT | blocked by M2 | seed→netbox switch; `enable: true`; AUDITED |
| M4 | aitora.org plug-in | aitora repo local-only | repo pushed; zone in dnscontrol; L0 vagrant evidence |
| M5 | whitecountyschools + athensarea plug-ins | not started | sites compose via manifests; AUDITED |
| M6 | **Developer platform** (portable 3-tier, webhook CI, publish→validate→confirm) | BLOCKED BY M1+M2; far future | `make env` bootstraps ahab+infra+content workspace; content-repo push triggers webhook → lint/test/merge → Jenkins confirmation + auto kuma monitor; a developer lands a change touching ONLY their content repo; AUDITED |

## Live-probed facts (2026-09-09, this session)

| Item | Status | Evidence |
|---|---|---|
| d701 = prod box | LIVE-PROBED | booted 23:58Z; kuma/traefik/postgres/openbao/flame/www Up; ssh OK via tailnet key `keys/service_id` |
| prod kuma up but self-hosted (blind spot root cause) | LIVE-PROBED | docker ps + kuma logs on d701 |
| hub (asus-llm 10.200.10.20) | RE-POWERED; services unverified | ping OK from d701; ssh key denied (unmanaged) |
| dev kuma DOWN; **sager AND hub unmanaged** | LIVE-PROBED | both repo keys denied on both boxes (fleet key distribution failure, cf. L-04) |
| **DNS flip PUSHED & LIVE** ✅ | LIVE-PROBED | dnscontrol `d9c8465` pushed via whitelisted IP; dig verifies d701→prod(.10), sager→dev(.15) |
| d701 /etc/hosts | **FAILS naming law** | legacy hostname + `project.dundore.net` alias + 127.0.1.1 line; fix via base-role convergence, not manual |
| d701 resolver | PASS | systemd-resolved→OpenDNS+MagicDNS; public zone carries private IPs |
| pi fleet | UNVERIFIED | no reachability from off-LAN laptop; needs control-node/console |
| inventory flip d701=prod | LIVE-PROBED, static-verified, **unaudited** | homelab `699e6bf` |
| dnsconfig flip (dev=.15/prod=.10, CNAMEs swapped) | LIVE-PROBED (check clean) **unaudited** | dnscontrol `d9c8465`; push pending |
| aitora repo (ex-hf) local git | LIVE-PROBED | `203cddf`, 42 files |

## Blockers (priority order — highest first)

| ID | Blocker | Why it stops progress | Unlock |
|---|---|---|---|
| B-001 | hub re-powered but services unverified | can't claim kuma/automation healthy | verify after B-002 unlock |
| B-002 | **sager AND hub unmanaged — repo keys absent from authorized_keys on both** | dev leg of lattice, hub recovery, M0 step 1 all blocked | CONSOLE: inject `keys/service_id.pub` (+ ansible_id.pub) for ansible_user on sager and hub |
| B-003 | dev kuma DOWN | no dev-checks-prod leg | after B-002: bootstrap-monitoring role |
| B-004 | DNS flip unpushed | d701/sager names still resolve pre-flip; convergence unsafe | push from control node (Namecheap IP whitelist) after preview |
| B-005 | git auth dead on laptop (gh 401, no ssh-agent) | cannot push any repo incl. aitora | user re-auth at this machine or push from control node |
| B-006 | no vault password on laptop | runtime ansible verify only possible on control node | run M0/M1 verifications there |
| B-007 | pi fleet unverified | voter node for lattice unknown | ping sweep from control node |
| B-008 | homelab has 9 open stashes | hidden drift vs branches | reconcile or delete; PM decision per stash |
| B-009 | d701 /etc/hosts stale (aliases + non-canonical name) | naming law violation; LE/cname scheme depends on it | base-role hostname enforcement after DNS push |
| B-010 | spark-auditor has PASSed nothing in this program | no item can reach AUDITED | queue audits: M0 vagrant gate, inventory flip, dns flip |
| B-011 | ahab license CC BY-NC-SA conflicts with dogfood law's "fully open source" | blocks M1 + any public adoption | relicense MIT/Apache-2.0 (PM recommends Apache-2.0 for patent grant) before M1 merge work |

## Branch archaeology (2026-09-09)

- **homelab `origin/development` +2**: `143f265` pipeline-cruft removal + L-04 key-path comment fix; `9f60777` **repo-freshness role + deploy play (O-03)** — audit-relevant tooling, review for M1. Both need cherry-pick review into production.
- **ahab `origin/dev` +2** (2025-12-12 shellcheck hygiene in setup-secrets-repo.sh) — merge into prod for M1.
- **ahab `origin/production`**: 2024-09 separate-root lineage ("testing" x5, minimal main.yml/roles/ssh.sh) — archaeological, ignore unless M1 design review wants it.
- ahab master/workstation/milestone-system-v1 == prod (no hidden code). geekend feature/epic-001-lab +8 commits = current WIP (expected). dnscontrol production branch = merged.

## Audit queue (next spark-auditor runs)
1. M0 vagrant gate + monitoring_bootstrap scaffold (once files exist)
2. Inventory flip `699e6bf` + DNS flip `d9c8465` pair-consistency vs naming law
3. homelab dev-branch commits `143f265`/`9f60777` fitness for cherry-pick
4. Split-contract lint (M6 seed): no org-specific values in ahab; no inventory/creds in content-tier repos
