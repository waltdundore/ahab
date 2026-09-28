# PROMOTIONS — append-only ledger of dev → prod promotions

One line per promotion, appended by `bin/promote-to-prod.sh` (in `ahab`:
`scripts/promote-to-prod.sh`) when it runs with `--push`. This is the record of
who moved what onto `prod`. **Agents never write here** — only the operator
promotes, and the script is the sole mechanism
(`docs/standards/gitops-2026-09-10.md`, rule 11).

Line format:

```
UTC | repo | source-ref source-sha → prod-sha | actor-email (whoami) | tag | rollback: git -C <repo> restore --source=<prod-before> --staged --worktree -- :/ && git commit -m "rollback prod to <prod-before>"
```

- **Append-only.** Never edit, reorder, or delete an existing line; correct a mistake with a new line.
- The line is committed (`promote: <repo> <tag>`) and pushed with the promotion, so the ledger and
  the code it records travel together and the worktree ends clean.
- Rollback is a **tree restore**: one new commit making prod's tree equal the pre-promotion tree.
  It needs no force and makes no assumption about what the promoted range contained.
  Why not a revert: `git revert -m 1 <tag>` undoes only the tag's own commit — measured 2026-09-28, a
  3-commit promotion left 2 of 3 commits in place and exited 0; and `git revert <before>..<after>`
  aborts outright when the range contains a merge commit — auditor A-21, 2026-09-28, on ahab's real
  `41edb51..c03adb6`. The tag names the promotion; it is not the rollback mechanism. Revert-to-tag
  remains correct for tag-deployed releases (law 9).
