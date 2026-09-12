# AGENTS.md — the model-context contract

For AI agents and models operating this repo (and its sibling site repos).
Humans: you can skim this; it's mostly here so machines behave themselves.

**The one idea that makes this work:** *human docs and machine context are kept
apart on purpose.* Prose holds the **map, the why, the feeling, the judgment**.
Everything that **changes minute to minute** — fleet state, service health,
traces, file contents, library APIs — is **fetched live from the MCP channels
below, never copied into a document.** A doc that hard-codes a live fact rots
the moment it's true; a doc that points you at the live source stays true
forever. This split is why the human docs can stay calm and premium instead of
crammed with operational folklore.

## Where live truth lives (call these, don't recall them)

| Channel | Answer to | Status you must expect |
|---|---|---|
| **fleet-state** | current fleet/machine state, repo/git state, LLM + kuma status | live |
| **uptime-kuma** | "is it up?" — monitors, service health | scaffolded; **fails loudly until M0** lattice is live |
| **netbox** | IPAM + inventory/assets — the overall SSoT | scaffolded; **fails loudly until M3** |
| **sentry** | "why did it throw?" — errors, traces | org exists; DSNs on until services run |
| **filesystem** | the actual committed files (ground truth of *desired* state) | live |
| **context7** | current library/framework docs — never trust memory for API syntax | live |

A channel that errors is **telling you something** (a prerequisite isn't up),
not asking you to work around it. Report it; don't paper over it.

## Authority order (follow top to bottom)

1. **Live state** → the MCP channels above. Never guess an IP, hostname, port,
   or secret — resolve it, or say "unknown."
2. **Desired state** → the committed code (`filesystem`) + [SPEC.md](SPEC.md).
3. **Program truth** → [BLUEPRINT.md](BLUEPRINT.md): laws, milestones,
   blockers, the D/B registers. The only "what's true / what's next."
4. **Vocabulary** → [docs/GLOSSARY.md](docs/GLOSSARY.md).

**History is not authority.** `CONTEXT.md`, `todo.md`, `docs/FROZEN.md`, and any
file with a date in its name are append-only history — useful, never true.
`docs/PLATFORM.md` is the *product*, not a status.

## Standing rules for agents

- **One question, one home.** Follow the link; don't reconstruct an answer a doc
  already owns. If two docs disagree, the older one is a defect — **file a
  D-row**, don't argue with it.
- **A doc may assert only what a verifier can prove.** If you find prose that
  lies about the tree (a command with no rule, a green badge with no monitor),
  that's drift — register it, fix the doc, move on.
- **Mechanical? It's code, not prose.** If a prerequisite is a step you had to
  *do*, the fix belongs in **Ansible** so the next newcomer never reads about it
  or remembers it. The ideal teaching document is one that deletes itself into a
  role. Docs keep only what code can't carry.
- **Leave breadcrumbs.** When you rename, retire, or restructure a doc, another
  agent may be mid-read on the old page. **Add a redirect banner** pointing to
  the new home — never silently yank a path out from under a reader.
- **Pull first, push small and often.** Shared docs have concurrent writers.
  `git pull --rebase` before writing; commit focused changes with a message that
  says *what/why/evidence*. Over-communicate in the diff.
- **Secrets:** values live in the vault (OpenBao / `/nas/secrets`), only
  *references* in git. Never write a secret value into a file, a prompt, a
  commit, or a log — not even as an example.
- **Trunk is `prod`/`dev`** (probe `git branch -r`; never assume `main`).

## Working model (who does what)

The PM plans and delegates; `spark-builder` executes isolated units with a
fully-factored brief; `spark-auditor` grants `AUDITED` — nothing self-certifies.
The full delegation contract lives in
`dundore-homelab/.opencode/skills/spark-delegation/`.

*New human? Ignore this file and go to [START_HERE.md](START_HERE.md).*
