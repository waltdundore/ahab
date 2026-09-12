# Start here

You didn't stumble onto a pile of scripts. You found a **method** — a way to run
infrastructure like a promise you can hand to someone else. This page is the
front door. Take it slowly; each section is a little deeper than the last, and
you can stop at any of them. There is no wrong door.

> If you're reading this on a hard night, with a fleet that went quiet and never
> told you why: you didn't break it. By the end of this method, that silence is
> the thing that stops happening. Rigor is how we take care of people here.

---

## Choose your door

Pick the line that sounds like you. Each tells you what to read first and —
more usefully — how you'll *feel* when you've finished it.

| You are… | Start with | When you're done, you'll feel |
|---|---|---|
| **Curious** — deciding whether to trust this | this page, then [README](README.md) | clear-eyed about what it is, what it isn't, and whether it's alive |
| **A new operator** — you'll run a fleet with it | [BOOTSTRAP runbook](../dundore-homelab/docs/BOOTSTRAP.md) | watched-over, not just monitored — proof in your own hands |
| **A contributor** — you'll send a change | [ONBOARDING](../dundore-homelab/docs/ONBOARDING.md) → [DEVELOPMENT_RULES](DEVELOPMENT_RULES.md) | like a teammate, not a stranger guessing at tribal rules |
| **A site owner** — you'll plug your org in | [Portability Contract](BLUEPRINT.md#portability-contract--the-3-tier-repo-split) → your module repo | that your whole job is just *inventory + roles + secret refs* |
| **An agent / model** — you operate from context | the [model ladder](#for-models-and-agents) below | grounded: one authoritative answer per question, history clearly marked as history |

Lost on a word — *lattice, gate, tier-1, kuma-first, convergence, D-register*?
That's not your fault. Every term is defined in the
[**GLOSSARY**](docs/GLOSSARY.md). It's there so you never have to nod along.

---

## What this is, in ninety seconds

**Ahab** (**A**utomated **H**ost **A**dministration & **B**uild) is the control
repo for a small fleet of real machines that run a few real sites. It encodes
one stubborn belief: *if it isn't written down and proven, it isn't true.*

Three habits carry that belief all the way down:

- **Prove it on a throwaway box first.** Nothing touches a real machine until
  the *same* code rebuilt an empty virtual one. Vagrant is the box that absorbs
  our mistakes so your users never meet them.
- **Nothing is "up" until a monitor says so.** A service without a health
  check doesn't exist. Dev watches prod, prod watches dev, and one small
  always-honest machine owns the single outbound alert — so the box that fails
  is never the one holding the phone.
- **Git is the only place state is written.** A setting that lives on a machine
  but not in a commit is a lie waiting to happen. You roll back by reverting a
  commit, not by remembering what you typed.

### The one diagram you need

The whole system is three layers, and each layer changes only what is *its*
business:

```
  ahab  (tier 1 — the machinery)            all the code, written once
   +                                            zero org-specific values
  your-site  (tier 2 — the module)          inventory + role choices + secret refs
   =                                         ← this is ALL a site contributes
  = a working site   (dundore.net, geekend.org, …)

  change flows:  vagrant → test units → dev box → prod box   (each gate GREEN first)
```

A site is a **module** that plugs into ahab. Its *entire* contribution is which
machines it has, which roles they run, and where its secrets are vaulted.
Everything generic lives once, up here, in ahab. That single rule is why a
change to your site never means copying infrastructure around.

---

## What's real right now (the honest status)

A premium product doesn't hide its seams — it shows you them and tells you
which ones are load-bearing. The live truth lives in one place, always:
**[BLUEPRINT.md](BLUEPRINT.md)**. If a fact isn't there with evidence, treat it
as a rumor — including anything a README once claimed. As of this writing:

- The **method, laws, and layer model are solid and in active use.**
- **Milestone M0** — the self-watching monitoring lattice — is **mid-build**.
  The clean-slate vagrant gate that certifies it hasn't gone green on the
  current host yet (**D-25 / B-017**).
- **The license is not open source yet** — CC BY-NC-SA 4.0, and relicensing
  (Apache-2.0 recommended) is a prerequisite of M1 (**B-011**). This is flagged
  the moment you open the repo, not buried.

We would rather tell you a thing isn't ready than let you find out at 2 a.m.

---

## When you're stuck (a ladder, not a wall)

Needing help is the design working, not you failing. Climb from the bottom:

1. **This page + the [GLOSSARY](docs/GLOSSARY.md).** Most "I'm lost" moments are
   one undefined word. Self-serve first; it's quick.
2. **The layer that owns your question.** [BLUEPRINT § Documentation
   Hierarchy](BLUEPRINT.md) says exactly which document answers which kind of
   question — one home per answer, always.
3. **Ask the machine.** Run the gate (`make gate` in the homelab module) and
   let it fail on the repo instead of on you. A gate that fails is proof; a
   README that promises is just a claim. Docs here are checked like code.
4. **Read the known unknowns.** Open questions and blockers are *filed on
   purpose* with owners in the D-register / B-register
   ([BLUEPRINT](BLUEPRINT.md)) and [OPEN-QUESTIONS](../dundore-homelab/docs/OPEN-QUESTIONS.md).
   If you're stuck on something hard, someone has probably already written down
   exactly where the frontier is.
5. **Open an issue or discussion.** A human talking to a human, with the error
   message. You'll get a person, not a ticket number.

Nothing in this method requires knowing the right person to ask. That is the
whole point of writing it down.

---

## For models and agents

The same docs are your runtime context, so they're written for you on purpose.
To stay grounded:

- **Read order:** this page → [GLOSSARY](docs/GLOSSARY.md) → the
  **Truth Hierarchy** + **Documentation Hierarchy** in
  [BLUEPRINT](BLUEPRINT.md) → [SPEC](SPEC.md) for design → your module repo.
- **Authority vs history.** BLUEPRINT = truth. `CONTEXT.md`, `todo.md`, and any
  file stamped with a date are *append-only history* — valuable, never
  authoritative. Never promote a history file to fact.
- **Never guess an address, name, or secret value.** Resolve it from the named
  authority, or stop and say so. A confident wrong IP is worse than an honest
  "unknown."
- **One question, one home.** Follow the link; don't reconstruct the answer. If
  two docs disagree, the older one is a defect — file it, don't argue with it.

---

## One more thing

This repository is a **teaching repo** — a teaching hospital for
site-reliability work. That means the *documentation is a product*, held to the
same bar as the code: it must meet you where you are, over-explain without
overwhelming, and prove its claims.

So it's tested like code. When this front door was re-checked by navigating it
cold — exactly as you just did — it failed, and every cut was filed in the
BLUEPRINT drift register (**D-38**), not quietly patched. There's a standing law
that a document may only assert what a verifier can prove, and a gate intended
to fail *us* the moment a page starts lying about the tree.

The gap between "it works on my machine" and "we'll prove it, in public, for
you" — **that gap is the entire product.** Welcome aboard.

*Next: [README](README.md) for the map, or the [GLOSSARY](docs/GLOSSARY.md) if a
single word above felt fuzzy.*
