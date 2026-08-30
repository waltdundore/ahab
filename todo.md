# Ahab v2 — todo (append-only)

ID class: `AH-###`. Dated, tagged, evidence-bearing. NEVER overwrite, reformat, or delete entries; mark done with `[DONE]` + date. Blocker resolutions (B1–B5, SPEC.md §7) are recorded here when resolved.

- AH-001 [2026-08-30] [DONE] v1 → v2 reset: new `main` branch from `prod` @ a82d0de; tree wiped to SPEC.md §4 skeleton; `CONTEXT.md` + `SPEC.md` + this file + `README.md` + `.gitignore` landed. Evidence: `git log main --oneline -1` (reset commit); `git log prod --oneline -1` = a82d0de.
- AH-002 [2026-08-30] [TODO] M1 entry decision (blocker B5): record lab-vs-real strategy (Vagrant bento-fedora-43 for M1–M3 dev loop vs real hardware) here before any M1 code.
- AH-003 [2026-08-30] [TODO] B1: identify the first gate box(es) and distribute the `ansible_user` automation key per Identity Law (dundore-homelab P4-01/P4-02 class).
- AH-004 [2026-08-30] [TODO] M1: implement the base install loop per SPEC.md §6 M1 (Makefile, ahab.yml, install/verify playbooks, base_host role, inventory, secrets scaffold, CI).
- AH-005 [2026-08-30] [TODO] M3 entry decision (blocker B4): record module content provenance choice (plain module dirs in this repo vs pinned submodules) here.
