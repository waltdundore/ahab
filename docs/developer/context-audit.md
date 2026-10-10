# Context Consumption Audit

`scripts/ctx-audit.mjs` reads the local pi agent session logs (`*.jsonl`) and reports
where context is being consumed in recent agent sessions: which content categories
cost the most, which individual tool results are the biggest, how context grows turn
to turn, and which turns were wasted. It is a diagnostic tool for keeping sessions
inside the model's context window; it changes nothing and touches no network.

Stdlib only (Node 22), no npm dependencies.

## Metric definitions

- **`ctx`** — `usage.input + usage.cacheRead + usage.cacheWrite`, the real context
  size reported by the API for one assistant model call.
- **`weighted chars`** — `chars x (number of assistant model calls at or after that
  entry)`. History is re-sent on every turn, so a block written early is paid for on
  every later call; weighting by remaining calls is what the block actually cost.
- **`dead turn`** — one increment **max** per assistant message where
  `stopReason` is `error` or `aborted`, **or** `usage` is missing, **or** `ctx === 0`.
  Reported alongside `deadByStop` (stop-reason driven) and `deadNoUsage`
  (missing usage / zero ctx). The two sub-counts can sum above `dead` because a single
  message can satisfy both conditions — that overlap is exactly the double-count an
  earlier prototype had, and it is deliberately not reproduced here.
- **`cache_bust`** — a turn with `usage.input > 20000`.
- **`big_prefill`** — a turn with `usage.input > 60000`.
  These are two separate fields and are never merged: a cache bust re-sends context
  uncached; a big prefill is a large uncached payload in one turn.
- **`~tok`** — an estimate, `chars / 4`. Estimates are always labelled `~tok` and are
  never mixed with real `usage` values.
- **Tool-result previews** — collapsed to one line and capped at 110 characters. Full
  result bodies are never printed, because session logs contain hostnames and secrets.

## Usage

```bash
make ctx-audit          # summary of the 10 most recent sessions
make ctx-audit-check    # same, but fails if any session peaks above 150k ctx
```

Direct invocation, including the other views:

```bash
node scripts/ctx-audit.mjs summary [--sessions N]    # per-session table, ctx percentiles, dead turns
node scripts/ctx-audit.mjs cost    [--sessions N]    # weighted cost by category and by tool
node scripts/ctx-audit.mjs blocks  [--sessions N]    # largest single tool results (preview only)
node scripts/ctx-audit.mjs growth  [--sessions N]    # transcript composition and per-turn ctx jumps
node scripts/ctx-audit.mjs json    [--sessions N]    # machine-readable report
```

Flags: `--sessions N` (default 10), `--cwd <substr>` (filter to a project),
`--root <dir>` (default `~/.pi/agent/sessions`), `--top N` (default 15),
`--out <file>`, `--fail-over <tokens>` (exit 1 if any session peak ctx exceeds it).

Sessions are the N most recently modified `.jsonl` files found recursively under
`--root`. Session paths can begin with `--`, so they are always handled as resolved
paths through the filesystem APIs and never shell-globbed.

Note: the newest sessions include any session running right now, so numbers move
between runs on an active machine.

## Snapshot 2026-10-10 (re-run 'make ctx-audit' for current numbers)

10 most recent sessions, `make ctx-audit` (full run captured in
`/tmp/ctx-final-summary.txt`; category table from `/tmp/ctx-final-cost.txt`).

- Model calls: 246. Per-call `ctx` p50 56.5k, p90 96.7k, max 121.5k.
- Worst session peak ctx: 121.5k. Compactions: 1. Avg output/call: 954.
- Turn-1 (harness baseline) ctx per session: 3.8k, 5.9k, 6.8k, 7.7k, 30.9k, 31.4k,
  31.4k, 31.5k, 31.6k — median 30.9k.
- Weighted cost by category: `toolResult` 40.5% (13.66M chars), `assistant thinking`
  32.8% (11.05M), `toolCall args:task_start` 12.0% (4.04M), `toolCall args:write`
  3.1%, `assistant text` 2.7%.
- Thinking: 241 blocks, 439KB total, avg 1865B. Assistant text: 47KB.
- Intercom custom messages: 2, 12KB total.
- `cache_bust` turns (input > 20000): 7. `big_prefill` turns (input > 60000): 3.
- Dead turns: 14 (`deadByStop` 14, `deadNoUsage` 14 — same 14 messages, counted once).
