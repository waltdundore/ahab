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
1. **Ground-up**: vagrant gate → test → deploy; nothing physical untested.
2. **Kuma-first**: bring up uptime-kuma; every subsequent item is verified BY kuma. Dev checks prod, prod checks dev, pi voter checks both and owns the only outbound alert. A service without a monitor does not exist.
3. **AUDITED ≠ done**: only spark-auditor grants AUDITED.
4. Builder subagent receives fully-factored specs only; it must query the PM on any ambiguity. PM executes small tasks directly.

## Milestones

| # | Milestone | Status | Exit gate |
|---|-----------|--------|-----------|
| M0 | **Monitoring lattice + ground truth** (CURRENT) | IN PROGRESS | Kill-switch drill: stop sshd on dev → prod kuma RED + pi voter alert; AUDITED |
| M1 | ahab control skeleton | SPEC drafted | SPEC accepted, module registry rewritten, `origin/dev` hygiene commits merged |
| M2 | Site plug-in wiring | blocked by M0 | submodules replace symlinks; DNS flip pushed from control node; d701 `/etc/hosts` law-compliant |
| M3 | NetBox inventory SSoT | blocked by M2 | seed→netbox switch; `enable: true`; AUDITED |
| M4 | aitora.org plug-in | aitora repo local-only | repo pushed; zone in dnscontrol; L0 vagrant evidence |
| M5 | whitecountyschools + athensarea plug-ins | not started | sites compose via manifests; AUDITED |

## Live-probed facts (2026-09-09, this session)

| Item | Status | Evidence |
|---|---|---|
| d701 = prod box | LIVE-PROBED | booted 23:58Z; kuma/traefik/postgres/openbao/flame/www Up; ssh OK via tailnet key `keys/service_id` |
| prod kuma up but self-hosted (blind spot root cause) | LIVE-PROBED | docker ps + kuma logs on d701 |
| hub (asus-llm 10.200.10.20) DOWN | LIVE-PROBED | kuma #4/#7/#15 EHOSTUNREACH from inside LAN; no tailnet entry |
| dev kuma DOWN; sager unmanaged | LIVE-PROBED | #17 ECONNREFUSED .15:3001; ssh `ansible_user` denied w/ both repo keys |
| pi fleet | UNVERIFIED | no reachability from off-LAN laptop; needs control-node/console |
| inventory flip d701=prod | LIVE-PROBED, static-verified, **unaudited** | homelab `699e6bf` |
| dnsconfig flip (dev=.15/prod=.10, CNAMEs swapped) | LIVE-PROBED (check clean) **unaudited** | dnscontrol `d9c8465`; push pending |
| aitora repo (ex-hf) local git | LIVE-PROBED | `203cddf`, 42 files |

## Blockers (priority order — highest first)

| ID | Blocker | Why it stops progress | Unlock |
|---|---|---|---|
| B-001 | hub (asus-llm) DOWN | it's a kuma target + automation hub; lattice can't go green | power/network check, redeploy via M0 protocol |
| B-002 | sager (dev) unmanaged — key denied | dev leg of cross-check impossible; dev kuma unreachable | console → reinject `keys/ansible_id.pub` (note L-04 in homelab dev: historical key-path breakage already bit the fleet once) |
| B-003 | dev kuma DOWN | no dev-checks-prod leg | after B-002: bootstrap-monitoring role |
| B-004 | DNS flip unpushed | d701/sager names still resolve pre-flip; convergence unsafe | push from control node (Namecheap IP whitelist) after preview |
| B-005 | git auth dead on laptop (gh 401, no ssh-agent) | cannot push any repo incl. aitora | user re-auth at this machine or push from control node |
| B-006 | no vault password on laptop | runtime ansible verify only possible on control node | run M0/M1 verifications there |
| B-007 | pi fleet unverified | voter node for lattice unknown | ping sweep from control node |
| B-008 | homelab has 9 open stashes | hidden drift vs branches | reconcile or delete; PM decision per stash |
| B-009 | d701 /etc/hosts stale (aliases + non-canonical name) | naming law violation; LE/cname scheme depends on it | base-role hostname enforcement after DNS push |
| B-010 | spark-auditor has PASSed nothing in this program | no item can reach AUDITED | queue audits: M0 vagrant gate, inventory flip, dns flip |

## Branch archaeology (2026-09-09)

- **homelab `origin/development` +2**: `143f265` pipeline-cruft removal + L-04 key-path comment fix; `9f60777` **repo-freshness role + deploy play (O-03)** — audit-relevant tooling, review for M1. Both need cherry-pick review into production.
- **ahab `origin/dev` +2** (2025-12-12 shellcheck hygiene in setup-secrets-repo.sh) — merge into prod for M1.
- **ahab `origin/production`**: 2024-09 separate-root lineage ("testing" x5, minimal main.yml/roles/ssh.sh) — archaeological, ignore unless M1 design review wants it.
- ahab master/workstation/milestone-system-v1 == prod (no hidden code). geekend feature/epic-001-lab +8 commits = current WIP (expected). dnscontrol production branch = merged.

## Audit queue (next spark-auditor runs)
1. M0 vagrant gate + monitoring_bootstrap scaffold (once files exist)
2. Inventory flip `699e6bf` + DNS flip `d9c8465` pair-consistency vs naming law
3. homelab dev-branch commits `143f265`/`9f60777` fitness for cherry-pick
