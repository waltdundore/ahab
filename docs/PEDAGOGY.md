# PEDAGOGY — Two Students, One Ladder

**Purpose:** the learning design behind every teaching surface (START_HERE,
the curriculum modules, module READMEs, error copy, AGENTS.md). It is the
spec each M7 wave builds to and the rubric each M8 cartridge is graded on.
**Owner:** PM — layer-2 machinery design; lives in ahab because *teaching is
machinery*.
**Consumes:** law 10 (BLUEPRINT) — this doc operationalizes it, never restates it.
**Affects:** curriculum structure, doc verdicts, verifier design, alert/error copy.

## The two students

| | the human | the model |
|---|---|---|
| who | 8th-grade CS → CIS-101 → the one who wants the whole stack | the next agent/session trained on this repo — arrives cold, every time |
| skill on arrival | near-zero infra vocabulary; can run commands when guided | high raw capability, zero memory, zero context about this estate |
| what kills them | a dead-end error with no next action; unexplained jargon; no visible win | a plausible-but-false fact in prose; a command that doesn't exist; a surface where fake success exits 0; context budget blown by walls of prose |
| what they need | sequence, vocabulary at point-of-need, a win inside the first 15 minutes, honest states, permission to take the quick door | authority order, executable claims (every cited command resolves), live facts *fetched* not inlined, task-scoped context, loud failures |
| how they prove learning | the thing they stood up is alive and green | the same commands executed; verifier exit codes; nothing invented |

Same ladder, both students: they both start cold, and SRE is learned the same
way either way. Audience changes the **voice and packaging**, never the
commands — the dogfood clause guarantees both students run exactly what we run.

## Apple's rules, translated (progressive disclosure = our law)

1. **One job per screen.** Each page answers one question at the reader's
   level; depth is one deliberate click away, never inlined.
2. **The happy path is the default; choice is earned.** Every module shows
   the *tonight-it-works* door first; the deep-stack path is an explicit
   second door, never a maze the beginner stumbles into.
3. **Defaults do the hard part.** The vagrant testbed is our Setup Assistant:
   risky things happen in the sandbox first; real hardware is an *earned*
   step, never the default.
4. **Capability-gated depth.** Beginner views hide flags; experts still reach
   them (never removed). For models, AGENTS.md routing is the same mechanism:
   load the layer your task names — not the whole repo.
5. **States speak human.** Green/red is never silent, never blaming: every
   error, alert, and RED status carries a next action (hospitality law 3).
6. **The box is the product.** First contact — START_HERE, the first `make`
   run, the first monitor going green — gets more design effort than any deep
   doc. The unboxing *is* the promise.
7. **A fake success is a design defect, not a user error** (law 11). Every
   teaching surface fails loudly: no catch-alls, no aspirational commands, no
   badges without a verifier. A student — human or model — who "succeeds" at
   something that didn't happen was lied to by the surface.

## The ladder

Module 0 = bootstrap (bare metal → tools → testbed) → first service → first
monitor → … → RAFT consensus, taught by the pi-voter lattice.
Every module: one goal → commands that actually exist → a runnable proof →
what just changed and *why* → where the next door is. The human reads the
GLOSSARY when a word felt fuzzy; the model calls the MCP channels when a fact
is live. Different tools, same ladder, same proof.

## Design tests (the bar spark-auditor grades against)

1. Could an 8th grader with zero prior knowledge finish this module in one
   sitting and *see* something alive?
2. Could a model execute it without inventing a single fact — every command
   resolves to a real rule, every live fact fetched, not recalled?
3. Is the next step knowable without reading past the current one?
4. Can a fake success pass through this module? If yes, file it — the module
   is defective, not the student.
5. Does every failure a student can hit speak human and name a next action?
