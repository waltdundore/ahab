# The ladder — learn the method, one rung at a time

This is the sequenced path, not an alphabetical reference. You start at the
bootstrap and climb. Every rung is a *skill you can do when you finish it*, not a
section you read. The design behind it — why it's ordered this way, and how the
same ladder serves a human and a model at once — lives in
[PEDAGOGY.md](../PEDAGOGY.md); this page is just the rungs.

If any word below felt fuzzy (*lattice, gate, tier-1, convergence*), it's
defined in the [GLOSSARY](../GLOSSARY.md). Never nod along.

## Two ways up the same ladder

You are one of two students, and both start cold:

- **A human** grows rung by rung across sessions — your next lesson is the next
  line down this page. You go deeper by *scrolling / clicking*.
- **A model** never arrives as a beginner and never as an expert — it's a capable
  stranger with no memory. It goes deeper by *loading only the one rung its task
  names*, never the whole page. Open one rung, do it, close it.

Same commands either way — the [dogfood clause](../../BLUEPRINT.md) guarantees
both students run exactly what we run.

## Module 0 — bootstrap → consensus

This is the spine. **Run 1–3 are live now** (this wave). **Rungs 4–6 are the rest
of the spine and are still in build** — listed honestly so you can see the whole
mountain, never as if they ship today.

| Rung | When you finish, you can… | Rough time | Prerequisite / status |
|---|---|---|---|
| **1 · Why** | say what this *method* is, and know you're allowed to take the quick door instead of the deep one | ~10 min | none — start here ([open it](module-0-bootstrap.md#rung-1--what-this-method-is)) |
| **2 · Tools** | get git, vagrant and docker on your machine, and tell which ones *our code* sets up for you vs. which you install yourself | ~20–40 min (depends on your machine) | rung 1 ([open it](module-0-bootstrap.md#rung-2--the-tools)) |
| **3 · Testbed** | run the `lab-*` sequence that proves a blank, empty box rebuilds from *this code alone*, and read what "green" actually means | ~30–60 min per VM build | rung 2 · **gate in build: D-46 / B-017** ([open it](module-0-bootstrap.md#rung-3--the-testbed)) |
| **4 · First service** | stand up a real service and prove it's up | — | **in build — gate M0** (not shipped yet) |
| **5 · First monitor** | get a monitor to go green, and know why a service without one "doesn't exist" | — | **in build — gate M0** (not shipped yet) |
| **6 · RAFT consensus** | explain quorum, leader election and log replication — *taught by the pi-voter lattice itself*: one node's claim is a claim, a majority's is truth | — | **in build — gate M0** (not shipped yet) |

### After Module 0 (forward rungs, one line each)

These point up the mountain. They are real program milestones, not lessons yet —
their status is whatever [BLUEPRINT.md](../../BLUEPRINT.md) says the day you read
this, not what's written here.

- **A site of your own** — plug a module in (inventory + role choices + secret
  refs) and get a working site. *(milestone M2 · gated on M0)*
- **The platform** — what the whole thing actually *does* when assembled:
  one role assigned → network, config, monitoring and secrets all react.
  Read it now, no prerequisites → [docs/PLATFORM.md](../PLATFORM.md).

## How every rung in this curriculum is built

So you always know what you're getting: **one goal → commands that actually exist
→ a runnable proof → what just changed and *why* → where the next door is.** No
command here is aspirational — every `make` rule this page names is in a Makefile
right now. A page may only promise what a verifier can prove (that's a
standing law, [BLUEPRINT](../../BLUEPRINT.md) law 9). When a rung isn't ready, it
says so with its gate ID instead of pretending — exactly like
[START_HERE](../../START_HERE.md) does.

*Ready? Rung 1 is one click down: [Module 0 — the bootstrap](module-0-bootstrap.md).*
