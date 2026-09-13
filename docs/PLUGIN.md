# Plug into ahab — the whole idea in five commands

You found the machine room. Here's the friendly version of what it is, where
it lives, and how to make it build *your* site. No prior ahab knowledge
needed — if you can edit a text file and type a command, you can plug in.

## What is ahab?

Ahab is the **toolbox repo**. It holds every piece of infrastructure
machinery — the operating-system setup, Docker, service installers — exactly
**once**, and holds *zero* details about any particular site. No passwords,
no addresses, no site names. Those live in **your** site repo, because your
site is yours.

The whole program is one equation:

```
ahab  +  your site repo  =  your site, running
```

Think of ahab as the Nintendo cartridge slot and your site repo as the
cartridge (that metaphor is literally the house style). The slot is the same
for everyone; the game you insert is what makes it yours.

## Where does it live?

Right here. You are looking at it: this repo is **ahab** (tier 1, the
machinery). Your site repo is a *separate* repository that contains only
three things — which machines you have, which modules they run, and
references to your vaulted secrets. That's the entire contract, and it's why
the machinery never rots: one toolbox, many sites.

- Program authority (laws, milestones): [BLUEPRINT.md](../BLUEPRINT.md)
- This repo's design (the socket's blueprint): [SPEC.md](../SPEC.md) §3–§4

## What's a module?

A **module** is one capability, kept in a folder under `modules/`, with a
`module.yml` card that says what roles it owns and what it needs first.
Today's shelf:

| Module | What it gives a machine | Needs first |
|---|---|---|
| `bootstrap` | a manageable OS: baseline setup + the `ansible_user` service account | nothing — start here |
| `docker` | Docker engine + the `compose` plugin | `bootstrap` |
| `platform` | your compose-defined service stack, with health gates | `docker` |

The full shelf (including planned-but-unbuilt ones, honestly labeled) is
[MODULE_REGISTRY.yml](../MODULE_REGISTRY.yml).

## How do I plug in? Five steps.

**1. See what exists.**

```bash
ls modules/
```

Every folder there is a module you can use, and its `module.yml` is its
label.

**2. Write your site's manifest** — one small file named `ahab-site.yml` in
your site repo, saying who you are and what you want enabled:

```yaml
site: example.org            # your site's name
modules:                     # what ahab should install for you
  - bootstrap
  - docker
local_roles: roles/          # (optional) your own service roles
```

**3. Resolve it.** From this repo:

```bash
make resolve MANIFEST=/path/to/your/ahab-site.yml
```

Ahab reads the registry, checks your choices, and prints the generated
`ansible.cfg` path — the file that points Ansible at exactly your modules'
roles. (Developing? `make socket-test` runs the socket's own proof against
the test fixtures.)

**4. Read the answer — success *and* refusals.** A good run says, in words:

> resolved site 'example.org' — the socket fits. enabled modules (dependency
> order): bootstrap, docker …

A refusal says things like:

> module 'platform' requires 'docker', but site 'example.org' did not enable
> 'docker'.

**That refusal is a friend, not a gatekeeping robot.** Every "no" ahab gives
protects you from a specific bad night: enabling `platform` without `docker`
means a stack that builds against an engine that isn't there and fails at
3 a.m. with a confusing error — so the resolver refuses *now*, in plain
words, when fixing it costs one line. An unknown module name means a typo
that would otherwise quietly install nothing while everything "succeeded."
Ahab never fakes success: every refusal exits loudly (code 2), so no script
and no model can mistake a "no" for a "yes."

**5. What happens next (and what doesn't yet).** The generated `ansible.cfg`
is the seam: from here, playbooks run with `ANSIBLE_CONFIG=<generated.cfg>`
and find every role your modules promise. Being honest with you, newcomer:
the full converge-on-a-blank-machine loop is still gated behind the lab
gate (blockers B-017/D-46 in the BLUEPRINT) — the socket, the modules, and
their tests are real and proven today; the bare-metal proof loop lands when
the gate does. When you're ready to go further, that's the row to watch.

## One thing to remember

Your fingerprints never touch the toolbox. Anything that smells like *your*
site — a name, an address, a secret — belongs in your repo, never here.
That's the entire law, and it's why the toolbox stays true for everybody.
Questions in words, answers in code, health in monitors — welcome aboard.
