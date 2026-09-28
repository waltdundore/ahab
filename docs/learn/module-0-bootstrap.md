# Module 0 — the bootstrap

**Goal:** take a machine from empty to *provably* rebuildable, and understand why
we insist on proving it at all. This wave covers rungs **1–3**. When you finish,
you'll be able to explain the method, set up your tools, and run the one command
sequence that rebuilds a blank box from this code alone.

Run these commands in the repo each one says. There are two Makefiles in this
project — **ahab** (the machinery) and **dundore-homelab** (a site module) — and a
`make` command only works in the one whose folder you're standing in. Each screen
tells you which. If you ever type `make <something>` and get
`no such target`, that's not you breaking — that's the Makefile refusing to lie
to you. Run `make help` to see the real targets.

---

## Rung 1 — What this method is

**The one question here:** what am I actually learning, and do I have to do *all*
of it?

Ahab is not a pile of scripts. It's a **method** for running infrastructure so it
survives being handed to someone else. Three habits carry the whole thing
([START_HERE](../../START_HERE.md) says it in ninety seconds):

- **Prove it on a throwaway box first.** Nothing touches a real machine until the
  *same* code rebuilt an empty virtual one. That virtual box is called the
  **testbed** — it's rung 3, and it's the point of this module.
- **Nothing is "up" until a monitor says so.** (Rung 5, still in build.)
- **Git is the only place state is written.** A setting on a machine that isn't in
  a commit is a lie waiting to happen.

The word that ties these together is
[**convergence**](../GLOSSARY.md#changing-things-safely-the-change-path): a
machine is brought to match its committed description, never hand-configured. If
you only remember one sentence from rung 1, remember that — *state is produced by
convergence, never typed by hand.*

### You are allowed to take the quick door

Not every night is a learning night. If you came to *use* the thing tonight rather
than master the stack, that's a legitimate door, not a shortcut you should feel
guilty about — [START_HERE](../../START_HERE.md)'s "Choose your door" table is
built for exactly that. This ladder is for the night you want the whole mountain.
Both students are welcome; the
[curriculum clause](../../BLUEPRINT.md) is written for both.

**✅ You've finished rung 1 when** you can say, out loud: *"Ahab proves changes on
a throwaway box before trusting a real one, and never hand-edits a machine."*
That's the belief everything below is in service of.

*Next: the tools you need, and the honest split between what you install and what
our code installs for you.*

---

## Rung 2 — The tools

**The one question here:** what do I have to install myself, and what does the
code handle?

Three tools matter to start: **git** (where all state lives), **vagrant** (the
button that builds a throwaway box), and **docker** (how services actually run).
Vagrant also needs a hypervisor behind it (VirtualBox or libvirt).

The honest split, so you're never surprised:

| | who installs it |
|---|---|
| git, vagrant, a hypervisor | **you**, on your host machine — the code can't install the thing that runs the code |
| docker + ansible *inside* the throwaway VM | **our code** — `make install` builds a Fedora VM with both already in it |

**Happy path** (run these in the **ahab** folder):

```bash
make help               # the real targets, in plain English — always safe
make check-prerequisites # tells you which host tools you're still missing
make install            # builds a Fedora VM with Docker + Ansible inside
make status             # confirms the VM is up and what's running in it
```

`make check-prerequisites` only *checks* — it points at what's missing and then
hands control back to you; installing those host tools is your one manual step.
That's by design: the code refuses to pretend it installed something it can't.

If you want modules (real services) inside that VM too, the valid form is
`make install MODULES=<name>` — the `MODULES=` part matters. Bare
`make install <name>` is not the interface and will exit non-zero; that's the
Makefile protecting you from a command that only *looks* like it worked.

### When a tool step fails (every failure has a next action)

- **`make check-prerequisites` names a tool you don't have** → that's the check
  doing its job. Install that one tool (vagrant from vagrantup.com, git from your
  package manager), then run it again. The list goes down as you install.
- **`make install` can't start a VM** → almost always the hypervisor. On Linux
  with libvirt, `vagrant plugin install vagrant-libvirt`; with VirtualBox, confirm
  it's installed and you're in its user group. Fix the hypervisor, re-run
  `make install`.
- **It just hangs on first run** → it's downloading a base box; that's normal the
  first time. Give it a few minutes before you call it stuck.

**✅ You've finished rung 2 when** `make check-prerequisites` is green and
`make status` shows your VM running. You now have a sandbox that can't hurt
anything real.

---

## Rung 3 — The testbed

**The one question here:** how do I *know* a brand-new machine can be rebuilt
from this code, and not just "works on my machine"?

Rung 2 gave you a sandbox. The **testbed** (our
[Vagrant gate](../GLOSSARY.md#changing-things-safely-the-change-path)) is the
discipline that makes that sandbox *proof*: an empty box, brought up by nothing
but this repo's code, that watches itself. If it comes up green, the instructions
are complete — because the code, not a person's memory, did the work. This is
rung 3 of the ladder and the exit gate of milestone **M0**.

**The sequence** (run these in the **dundore-homelab** folder — this is a
different Makefile than rung 2's):

```bash
make lab-host      # ready this host so the test VMs can reach the internet
make lab-up        # build the blank test box and converge it from code
make lab-status    # what's actually in the lab right now (VM states + containers)
make lab-verify    # THE GATE: prove the box's own health monitor is GREEN
```

`make lab-verify` going green is the whole point: it tunnels into the box and
confirms the service it just built is *watching itself*. That green is a monitor
saying "alive," not a human saying "looks fine." The full set also includes
`make lab-provision` (re-run the converge on an existing box),
`make lab-negative` (a *test of the test* — a deliberately wrong check must NOT
pass, so a green can't be fake), and teardown with `make lab-destroy` /
`make lab-reap` (both refuse to delete anything unless you add `CONFIRM=yes`,
because this lab box *is* the evidence machine).

### Be honest about where this gate stands right now

The method is real and the commands above are real. **The current status is not
fully green on every host, and you should expect that — it's a known gate, not
your mistake.**

- The clean-slate gate **passed and was audited** on a VirtualBox host on
  2026-09-09 — 18 tasks converged idempotent, self-monitor GREEN, and it caught
  eight real bugs that were fixed *in code, not on the box*. Read that evidence
  (it's short): [bootstrap-vagrant-2026-09-09.md](https://github.com/waltdundore/dundore-homelab/blob/prod/tests/evidence/bootstrap-vagrant-2026-09-09.md).
- On the **current libvirt host, the gate has not gone green yet.** The reason is
  tracked openly as **D-25** (the lab-network NAT the test box needs to reach the
  internet wasn't owned by any code) and **B-017** (so the M0 gate can't run on
  this host). `make lab-host` is the code written to close D-25. Until that's
  proven, treat a first `make lab-up` as *expected to need that prep*, not as a
  failure of yours. Run the BOOTSTRAP runbook alongside it:
  [docs/BOOTSTRAP.md](https://github.com/waltdundore/dundore-homelab/blob/prod/docs/BOOTSTRAP.md).

### When the gate doesn't go green (every failure has a next action)

- **`make lab-up` starts but the VM can't reach the internet** → this is the
  D-25 class, not you. Run `make lab-host` first (it sets up the lab network),
  then `make lab-up` again.
- **A stale VM is in the way** → `make lab-status` to see it; if it's a stranded
  box vagrant stopped tracking, `make lab-reap` finds it (it removes nothing
  without `CONFIRM=yes`).
- **`make lab-verify` is red** → don't assume the box is broken; run
  `make lab-status` and read what's actually there. A red gate with a reason is
  worth more than a green with a shrug. If it stays red, that's a finding to file
  in the D-register — not something to talk yourself past.

**✅ You've finished rung 3 when** you've run the sequence, and — green or red —
you can say *which* step it reached and *why* in your own words. Naming the state
honestly is the skill; the green is just its echo.

---

## What just changed, and why

You started with a machine and left with **proof you can make** that an empty box
rebuilds from code alone — plus the judgment to tell a real green from a fake one
(that's exactly what `make lab-negative` exists to protect). The shift that
matters isn't the commands; it's the reflex: *a change isn't a change until its
test has run and left evidence.* That reflex is the whole method in one sentence,
and it's the difference between "works on my machine" and "we'll prove it, in
public, for you."

## The next door (rung 4)

**Rung 4 — stand up your first real service.** It's the natural next step: you've
proven you can rebuild a box, so now you put something worth keeping on it.

> **This door is in build — gate M0.** Rung 4 isn't a lesson yet, and there's no
> command to run today. It, and rungs 5–6, land when the monitoring lattice (M0)
> clears; check [BLUEPRINT.md](../../BLUEPRINT.md) for its live status rather
> than trusting this page. When they're ready they show up in the
> [ladder index](README.md) — same place you found this one.
