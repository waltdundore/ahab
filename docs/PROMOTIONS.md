# PROMOTIONS — append-only ledger of dev → prod promotions

One line per promotion, appended by `bin/promote-to-prod.sh` (in `ahab`:
`scripts/promote-to-prod.sh`) when it runs with `--push`. This is the record of
who moved what onto `prod`. **Agents never write here** — only the operator
promotes, and the script is the sole mechanism
(`docs/standards/gitops-2026-09-10.md`, rule 11).

Line format:

```
UTC | repo | source-ref source-sha → prod-sha | actor-email (whoami) | tag | rollback: git revert --no-commit <prod-before>..<prod-after> && git commit -m "revert <tag>"
```

- **Append-only.** Never edit, reorder, or delete an existing line; correct a mistake with a new line.
- The line is committed (`promote: <repo> <tag>`) and pushed with the promotion, so the ledger and
  the code it records travel together and the worktree ends clean.
- Rollback is the **range** revert. A fast-forward promotion creates no merge commit, so
  `git revert -m 1 <tag>` undoes only the tag's own commit — measured 2026-09-28, a 3-commit
  promotion left 2 of 3 commits in place and exited 0. The tag names the promotion; it is not the
  rollback mechanism. Revert-to-tag remains correct for tag-deployed releases (law 9).
