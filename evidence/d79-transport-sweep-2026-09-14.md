# D-79 Transport & Prerequisite Sweep — estate verdict (2026-09-14)

Purpose: mechanical estate-wide sweep verdict for violation class D-79 ("prerequisites
and file-transport live in tooling/folklore instead of converged code") per ahab
BLUEPRINT audit-queue item 18 (S1–S4 + test-of-the-test). Owner: spark-auditor.
Consumes: trunk trees of the six repos (HEADs below), `/tmp/opencode/d79-sweep/sweep.sh`.
Affects: D-79 remediation units; nothing is fixed or committed here.
Method note: S1/S2/S3 mechanical floor = `sweep.sh` (scratch tree, uncommitted);
S2 triage + S4 = auditor judgment, each cited. Verdict cells ∈ {OK, FINDING, N/A}.

HEADs verified before and after the sweep (unchanged):
`ahab c56ec29 (prod) · dundore-homelab 05b58b9 (prod) · aitora 7d58bff (prod) ·
geekend 1faadcc (prod) · template aaaf1b2 (prod) · dndore-dnscontrol c09124e (dev)`
(the repo dir is `dundore-dnscontrol`; queue-18's spelling `dndore-dnscontrol` is a
typo — Scope Findings #1). No repo has `main`/`master`; trunk probed via `git branch -r`.

## Verdict table

| Repo | S1 transport | S2 host-prereq | S3 dirty-tree | S4 blank-slate |
|---|---|---|---|---|
| ahab | OK | OK | FINDING `Vagrantfile:82-83` | FINDING (low) — itemized below |
| dundore-homelab | FINDING `Vagrantfile:26` | OK | FINDING `Vagrantfile:53,78,98` | FINDING (med) — itemized below |
| aitora | FINDING `Vagrantfile:57` | FINDING `Vagrantfile:27-35`, `playbooks/health.yml:31` | FINDING `Vagrantfile:81,92,104` | FINDING (high) — itemized below |
| geekend | FINDING `Vagrantfile:28` | OK | FINDING `Vagrantfile:50-51` | FINDING (low) — itemized below |
| template | N/A (no gate surface) | OK | N/A | OK (empty) |
| dndore-dnscontrol | N/A (no Vagrantfile; container gate) | OK | FINDING `push.sh:2` (judgment, see below) | FINDING (med) — itemized below |

### S1 evidence (synced_folder transport)

- ahab **OK**: `Vagrantfile:60` `disabled: true` (default /vagrant off);
  `Vagrantfile:63` explicit `type: "rsync"` (note, not NFS).
- homelab **FINDING**: zero `synced_folder` lines in `Vagrantfile` (107 lines) ⇒
  implicit default sync at provider-default type; lab runs libvirt (`qemu:///session`,
  D-46) ⇒ NFS host prereq (exports write + firewall + kernel nfsd) silently required —
  the exact aitora death (`mount -o vers=3,udp … not supported`) waiting on the same wire.
- aitora **FINDING**: `Vagrantfile:57-58` `fed.vm.synced_folder ".", "/vagrant",
  mount_options: […]` — no `type:`, not disabled ⇒ provider-default NFS. Matches the
  live mount-death receipt (`aitora/audit.md` RUN LOG, D-79 receipt #1).
- geekend **FINDING**: zero `synced_folder` lines in `Vagrantfile` (56 lines) ⇒ implicit
  default; provider block is virtualbox-only (`Vagrantfile:44`), so on this estate's
  libvirt hosts the same NFS class applies.
- template / dnscontrol **N/A**: no Vagrantfile (`ls` receipts in sweep output).

### S2 evidence (host mutation / asserted host env)

- ahab **OK**: `make check-prerequisites` (`Makefile:77,81`) runs
  `scripts/check-prerequisites.sh` → `scripts/lib/prerequisite-checks.sh:39-49,54-62,73-84,119`
  checks docker/vagrant/plugins and *names the fix* for each miss — the estate's positive
  control for fix-contract (b). Remaining sweep candidates triage OK: guest-side
  (`Vagrantfile:88`, `Makefile:101`), ephemeral CI-runner apt (`scripts/ci/*`,
  `.github/*`), fix-named diagnostics. Legacy installer scripts → Scope Findings #5.
- homelab **OK**: `make lab-host` (`Makefile:66-67`) converges
  `playbooks/converge-lab-host.yml` → `roles/lab_host` renders declarative files
  (`/etc/nftables/ahab-lab.nft`, systemd unit, `sysctl.d` — playbook:13-15), i.e. the
  D-46(a)(b) shape, not runtime mutation; `bootstrap.sh:222-246` prints MISSING +
  named `sudo -n …` fix per absent prereq (loud check pattern); `bin/lint-net-state.sh`
  is the D-46(g) verifier quoting its own patterns. Human-timed `make lab-host` step → S4.
- aitora **FINDING**: `Vagrantfile:27-35` raises unless `~/.ssh/id_ansible_user`
  keypair pre-exists — loud, names `ssh-keygen` (line 33), but the step is manual,
  per-machine, and has no code home (D-79 receipt #2; loudness ≠ convergence);
  `playbooks/health.yml:31` asserts `'SSH_AUTH_SOCK' in env_out.stdout` ⇒ host
  ssh-agent running with keys loaded is an undeclared gate prereq (receipt #3);
  `scripts/host-setup.sh:11-12` auto-starts an ssh-agent but has zero callers
  (grep: no reference from Vagrantfile/playbooks/Makefile/.github) — folklore helper.
  Guest-side `sudo dnf`/`ansible-galaxy` inline shells (`Vagrantfile:73,76`) triage
  OK (in-guest convergence from committed code).
- geekend **OK**: zero enumerated hits outside roles/playbooks (sweep rc: S2 section empty).
- template **OK**: only tooling file is `.github/workflows/ci.yml`; zero enumerated hits.
- dnscontrol **OK**: gate is `docker run ghcr.io/stackexchange/dnscontrol`
  (`Makefile:33`, `preview.sh:2`, `push.sh:2`); zero enumerated hits. Docker +
  creds are host prereqs not in the S2 pattern list → counted in S4.

### S3 evidence (gate provisions the UNCOMMITTED working tree)

- ahab **FINDING**: `Vagrantfile:82-83` `ansible_local` + `provisioning_path
  "/home/vagrant/ahab"` fed by the `:63` rsync auto-sync of the host working tree;
  no HEAD-clean pin anywhere (no `git status --porcelain`/`rev-parse` in gate path).
- homelab **FINDING**: host-transport `provision "ansible"` blocks `Vagrantfile:53,78,98`
  run `playbooks/…` straight from the host working tree. Sweep NOTE override: the
  script's pin heuristic matched `status --porcelain` in `Makefile` — but that is
  `make state`'s *observational* git report (`Makefile:251-259`, "GIT (read-only…)"),
  not a gate pin; D-74 confirms the 2026-09-14 gate provisioned unproven tree state.
- aitora **FINDING**: `Vagrantfile:81,92,104` `provisioning_path = '/vagrant'` ×
  ansible_local — the whole gate (bootstrap→site→verify) provisions the mounted
  working tree (D-79 receipt #4); `scripts/test-phase1.sh:43,47,57` runs playbooks
  `cd /vagrant` likewise. No pin.
- geekend **FINDING**: `Vagrantfile:50-51` host `provision "ansible"` runs
  `playbooks/site.yml` from the host working tree; no pin.
- dnscontrol **FINDING** (judgment; mechanical grep set finds nothing — no vagrant
  primitives): `push.sh:2` binds `-v "$(pwd):/dns"` so `make push` ships whatever
  `dnsconfig.js` the *working tree* holds — uncommitted zone edits reach the registrar
  with no HEAD-clean pin (`preview.sh`/`push.sh` assert nothing). Law-6 hole, same
  class as receipts #4.
- template **N/A**: no provisioner of any kind.

### S4 — host commands a human must hand-run before the gate passes (must be EMPTY)

- ahab — S4 FINDING (low): ① `sudo dnf install git ansible vagrant docker make python3`
  (named by `prerequisite-checks.sh:73`, human-run); ② `sudo systemctl start docker`
  (named, `:45,119`); ③ create `../ahab.conf` — outside the repo, absent on disk
  (`ls /home/wdundore/git/ahab.conf` → no such file), `Vagrantfile:10-13` silently
  defaults when missing (unnamed, LOW); ④ `make install-prerequisites` printed at
  `prerequisite-checks.sh:94` does not exist as a Makefile rule (Scope #2).
- dundore-homelab — S4 FINDING (med): ① install vagrant + vagrant-libvirt
  (unconverged, unchecked by any gate here); ② `make lab-host` human-timed before
  `lab-up` (`Makefile:39` "Lab prerequisite" — itself the D-46(d) defect: apply route
  should be the timer, not a hand-run step); ③ `vagrant up <box>`.
- aitora — S4 FINDING (high): ① `ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ansible_user`
  (`Vagrantfile:32-33` raise text); ② host ssh-agent running + key added
  (implied by `Vagrantfile:40` forward_agent + `health.yml:31`; nothing starts it —
  the uncalled `host-setup.sh` is the folklore memory); ③ host NFS server/export for
  the S1 default mount (silent — zero docs warn, D-79 receipt #1); ④ `vagrant up`.
- geekend — S4 FINDING (low): ① install vagrant + VirtualBox (virtualbox-only
  providers `Vagrantfile:44`; no check-prerequisites target exists); ② free host
  ports 8080/8081 by hand (CONTEXT Current State: orphan-VM port collision cleared
  manually by operator 2026-09-10 — folklore cure); ③ `vagrant up`.
- template — S4 OK (empty): no runnable gate; docs + empty `content/` + `state/` only.
- dndore-dnscontrol — S4 FINDING (med): ① install docker + daemon running
  (zero mentions in README — unconverged, unchecked); ② hand-create `creds.json`
  with Namecheap API key (README:27-28 says `cp creds.json.example creds.json` —
  `creds.json.example` does not exist: `ls` → no such file, Scope #8).

## Test-of-the-test (queue-11 rule)

- PLANT: `git clone /home/wdundore/git/template /tmp/opencode/d79-sweep/scratch`; added
  `Vagrantfile` with `config.vm.synced_folder ".", "/vagrant", type: "nfs"` →
  `bash sweep.sh …/scratch` rc=1, named
  `FINDING S1: …/scratch/Vagrantfile:3 — synced_folder type nfs`. PASS.
- CONVERSION: same line → `disabled: true` → rc=0. PASS.
  (One script defect found and fixed *in the scratch tool, between* the two legs:
  the S3 `/vagrant` grep also counted disabled mounts; corrected so a
  `synced_folder … disabled: true` line no longer raises S3. Regression-checked:
  geekend still rc=1, aitora still emits its 11 S3 candidates.)

## Remediation units per repo (mapped to D-79 fix contract a–d)

Transport unifies via D-15/D-57 (Vagrantfile fork estate-wide): ONE transport
primitive — `synced_folder … disabled: true` + Ansible-owned distribution
(git-clone-from-forge or host-run synchronize) — authored once in ahab, consumed
by all four Vagrantfiles; each unit below plugs into it rather than inventing one.

- ahab: S3 leg — replace rsync-of-dirty-tree with commit-pinned transport (contract a,c:
  gate evidence names its commit); fold legacy installer scripts (Scope #5) into roles (b).
- dundore-homelab: named D-79 unit "homelab lab surface" — transport swap (a) +
  HEAD-clean pin (c); move `make lab-host` apply route to the repo-git/AWX timer (D-46 d).
- aitora: named D-79 unit — transport swap (a), converge the control-keypair prereq
  into a role/ceremony with code home (b), re-verify `health.yml` agent chain (d).
- geekend: transport swap (a, kills the implicit default) + add loud check-prerequisites
  naming vagrant/provider/port fixes (b).
- template: none today (no gate); cartridge (M8) must inherit the unified primitive, not fork it.
- dndore-dnscontrol: assert `git status --porcelain` empty before `push.sh` (c);
  converge creds.json provisioning or a named setup step (b); docker presence check (b).

## Scope Findings (observed, NOT fixed)

1. BLUEPRINT queue-18 (and the dispatch brief) cite repo `dndore-dnscontrol`; the actual
   directory is `dundore-dnscontrol` — dead-reference class (D-38 kin).
2. `scripts/lib/prerequisite-checks.sh:94` emits `make install-prerequisites`; no such
   rule in ahab `Makefile` (.PHONY line 13) — D-41 family (docs-the-machine-writes lie).
3. ahab `Vagrantfile:11` reads `../ahab.conf` — a config file OUTSIDE the repo, absent
   on disk; `read_config` defaults silently (no named failure) — state outside git.
4. aitora `audit.md` — the D-79 receipt file BLUEPRINT cites — is UNTRACKED
   (`git status` → `?? audit.md`): the class's own proof lives outside Git (law 6).
5. ahab legacy shell installers mutate host state interactively:
   `scripts/lib/production-setup-common.sh:60` writes a NOPASSWD sudoers file via
   `sudo tee`; `scripts/lib/nested-test-common.sh:119,196` `systemctl enable --now docker`
   — fix-named and interactive-confirm, so mechanically S2-OK, but shell duplicates of
   what Ansible should converge (D-29 tier-1 graveyard family).
6. geekend `CONTEXT.md` contradicts ratified facts: "dev.dundore.net (d701, CI runner) ·
   prod.dundore.net (dundore-sager)" (pre-flip inversion) and Strict-GitFlow
   "main/develop" trunk pair vs GitOps canon {prod,dev} — D-31/D-55 family.
7. dnscontrol `README.md:27` `cp creds.json.example creds.json` — example file absent
   (dead reference inside the credential-provisioning instruction itself).
8. Pre-existing tree dirt (not created by this sweep, quoted untouched): ahab
   ` M BLUEPRINT.md`; dundore-homelab `?? requirements.yml`; aitora `?? audit.md`.
9. homelab `Vagrantfile:102` `kuma_bootstrap_password: "vagrant-bootstrap-only"` —
   placeholder-shaped literal in a committed Vagrantfile; not plausible-secret-shaped,
   noted for D-19 watch only.

Guardrails kept: zero commits/adds/stashes/checkout; zero tracked-file edits (six
`git status --porcelain` re-checked after sweep — only this new untracked evidence
file in ahab); no vagrant/virsh/docker/sudo executed; ~/.ssh untouched; HEADs equal
the CONTEXT shas above at finish.
