# Context Consumption Audit

`scripts/ctx-audit.mjs` reads the local pi session logs (`~/.pi/agent/sessions/**/*.jsonl`) and
reports where recent agent sessions spend context: per-session peak ctx, ctx percentiles per
model call, weighted cost by category and tool, largest tool results, dead turns. Read-only,
stdlib-only Node 22, no network. Previews cap at 110 chars; full bodies are never printed.

## Metric definitions

- `ctx` = `usage.input + usage.cacheRead + usage.cacheWrite` — the real context of one
  assistant model call.
- `weighted chars` = `chars` x model calls at or after that entry — history is re-sent
  on every turn, so a block written early is paid for on every later call.
- `dead turn` = max one per assistant message where `stopReason` is `error`/`aborted`
  or `usage` is missing/zero.
- `cache_bust` = input > 20000.
- `big_prefill` = input > 60000.
- `~tok` = `chars / 4`, an estimate only; never mixed with real `usage` values.

## Run

```bash
make ctx-audit          # node scripts/ctx-audit.mjs summary --sessions 10
make ctx-audit-check    # summary --sessions 10 --fail-over 150000 (exit 1 if a session peaks above it)
# other views, direct:
node scripts/ctx-audit.mjs cost|blocks|growth|json [--sessions N] [--cwd <substr>] [--root <dir>] [--top N] [--out <file>] [--fail-over <tokens>]
```

The window is the N most recently modified sessions and includes any session running now, so
numbers move between runs on an active machine.

## Snapshot 2026-10-10 (run make ctx-audit for current numbers)

`summary --sessions 10`: model calls 199; ctx p50 40.0k, p90 86.7k, max 111.0k; worst session
peak 111.0k; avg output/call 868; compactions 0; turn-1 baseline ctx median 31.4k. Thinking 187
blocks / 336KB (avg 1840B); assistant text 27KB; intercom 4 messages / 26KB. `cache_bust` 4,
`big_prefill` 2, dead turns 17 (by stopReason 17, no-usage/zero-ctx 17: same messages, counted
once).
