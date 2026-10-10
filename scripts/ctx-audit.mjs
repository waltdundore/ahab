#!/usr/bin/env node
// =============================================================================
// Context-consumption audit over pi agent session JSONL logs.
// Stdlib only, no network. Subcommands: summary | cost | blocks | growth | json
//
// Metric definitions (bound exactly):
//   ctx            = usage.input + usage.cacheRead + usage.cacheWrite
//   weighted chars = chars x (number of assistant model calls at or after that
//                    entry): history is re-sent every turn, so an early block is
//                    paid for on every later call.
//   dead turn      = ONE increment max per assistant message where stopReason is
//                    'error' or 'aborted', OR usage is missing, OR ctx === 0.
//                    deadByStop / deadNoUsage are reported separately and may sum
//                    to more than `dead` (a message can hit both conditions; the
//                    earlier prototype counted those twice).
//   cache_bust     = usage.input > 20000   (its own field, never merged)
//   big_prefill    = usage.input > 60000   (its own field, never merged)
//   ~tok           = chars / 4 estimate, always labelled ~tok; real usage values
//                    are never mixed with estimates.
// Tool-result previews are capped and whitespace-collapsed; full result bodies
// are never dumped because session logs carry hostnames and secrets.
// =============================================================================
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

// ---------------------------------------------------------------- helpers ----

const CACHE_BUST_INPUT = 20000;
const BIG_PREFILL_INPUT = 60000;
const PREVIEW_CHARS = 110;

const STOP_DEAD = new Set(['error', 'aborted']);

/** Human-readable count: 1234 -> 1.2k, 1500000 -> 1.50M. */
const W = (n) => (n >= 1e6 ? (n / 1e6).toFixed(2) + 'M' : n >= 1e3 ? (n / 1e3).toFixed(1) + 'k' : String(n));

/** chars -> estimated tokens; always presented as ~tok, never as real usage. */
const estTok = (chars) => Math.round(chars / 4);

/** Collapse whitespace and cap so secrets/hostnames in logs are not dumped. */
const preview = (s) => String(s).replace(/\s+/g, ' ').slice(0, PREVIEW_CHARS);

const textOf = (content) => {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  let s = '';
  for (const b of content) {
    if (!b || typeof b !== 'object') continue;
    if (typeof b.text === 'string') s += b.text;
    else if (typeof b.content === 'string') s += b.content;
    else if (b.content) s += textOf(b.content);
  }
  return s;
};

/** Recursive .jsonl discovery; session paths can start with `--`, so they are
 *  always handled as resolved paths by fs APIs, never shell-globbed. */
const walk = (dir) => {
  let out = [];
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out = out.concat(walk(p));
    else if (e.name.endsWith('.jsonl')) out.push(p);
  }
  return out;
};

const readEntries = (p) => {
  const out = [];
  for (const l of fs.readFileSync(p, 'utf8').split('\n')) {
    if (!l) continue;
    try { out.push(JSON.parse(l)); } catch { /* tolerate truncated last line */ }
  }
  return out;
};

const ctxOf = (msg) => {
  const u = msg.usage || {};
  return (u.input || 0) + (u.cacheRead || 0) + (u.cacheWrite || 0);
};

/** Dead-turn predicate: single increment per message. */
const isDeadTurn = (msg) => STOP_DEAD.has(msg.stopReason) || !msg.usage || ctxOf(msg) === 0;

/** Percentile over an already-sorted ascending array (same estimator the
 *  prototype used: floor(n*q) clamped to the last index). */
const pct = (sorted, q) => (sorted.length ? sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * q))] : 0);

/** Encoded session directory -> readable cwd-ish label. */
const dirLabel = (p) => path.basename(path.dirname(p)).replace(/^-+|-+$/g, '');

const matchesCwd = (p, substr) => {
  const dir = path.dirname(p);
  const encoded = dirLabel(dir);
  return dir.includes(substr) || encoded.includes(substr.replace(/[/\s]+/g, '-')) || encoded.includes(substr);
};

/** Per-session metrics from one pass over the entries (script 3 semantics). */
const analyzeSession = (entries) => {
  const s = {
    modelTurns: 0, peak: 0, sumInput: 0, sumCacheRead: 0, sumOutput: 0,
    firstCtx: 0, lastCtx: 0, compactions: 0, dead: 0, deadByStop: 0, deadNoUsage: 0,
    cacheBust: 0, bigPrefill: 0, thinkingBlocks: 0, thinkingBytes: 0, textBytes: 0,
    intercomMsgs: 0, intercomBytes: 0, perCall: [], outputs: [],
  };
  for (const e of entries) {
    if (e.type === 'compaction' || e.customType === 'compaction') s.compactions++;
    if (e.type === 'custom_message' && /intercom/.test(e.customType || '')) {
      s.intercomMsgs++;
      s.intercomBytes += textOf(e.content).length + JSON.stringify(e.details || '').length;
    }
    const msg = e.message;
    if (!msg || msg.role !== 'assistant') continue;
    s.modelTurns++;
    const u = msg.usage || {};
    const ctx = ctxOf(msg);
    if (!s.firstCtx && ctx) s.firstCtx = ctx;
    s.peak = Math.max(s.peak, ctx);
    s.lastCtx = ctx || s.lastCtx;
    s.sumInput += u.input || 0;
    s.sumCacheRead += u.cacheRead || 0;
    s.sumOutput += u.output || 0;
    if (ctx) s.perCall.push(ctx);
    if (u.output) s.outputs.push(u.output);
    if (isDeadTurn(msg)) s.dead++;
    if (STOP_DEAD.has(msg.stopReason)) s.deadByStop++;
    if (!msg.usage || ctx === 0) s.deadNoUsage++;
    if ((u.input || 0) > CACHE_BUST_INPUT) s.cacheBust++;
    if ((u.input || 0) > BIG_PREFILL_INPUT) s.bigPrefill++;
    for (const b of msg.content || []) {
      if (b.type === 'thinking') { s.thinkingBlocks++; s.thinkingBytes += (b.thinking || b.text || '').length; }
      else if (b.type === 'text') s.textBytes += (b.text || '').length;
    }
  }
  return s;
};

/** N most recent .jsonl sessions under root, newest first, already analyzed. */
const loadSessions = (opts) => {
  const root = path.resolve(opts.root.startsWith('~') ? path.join(os.homedir(), opts.root.slice(1)) : opts.root);
  let files = walk(root).map((p) => ({ p, mtime: fs.statSync(p).mtimeMs }));
  if (opts.cwd) files = files.filter((f) => matchesCwd(f.p, opts.cwd));
  files.sort((a, b) => b.mtime - a.mtime);
  return files.slice(0, opts.sessions).map((f) => {
    const entries = readEntries(f.p);
    return {
      file: path.basename(f.p),
      dir: dirLabel(f.p),
      path: f.p,
      mtime: new Date(f.mtime).toISOString().slice(0, 16),
      sizeMB: +(fs.statSync(f.p).size / 1048576).toFixed(2),
      entries,
      ...analyzeSession(entries),
    };
  });
};

const parseArgs = (argv) => {
  const opts = {
    cmd: argv[0] && !argv[0].startsWith('--') ? argv[0] : 'summary',
    sessions: 10, top: 15, root: '~/.pi/agent/sessions', cwd: '', out: '', failOver: 0,
  };
  const rest = argv.slice(opts.cmd === argv[0] ? 1 : 0);
  const num = (v, flag) => {
    const n = Number(v);
    if (!Number.isFinite(n)) { console.error(`${flag} needs a number, got "${v}"`); process.exit(2); }
    return n;
  };
  for (let i = 0; i < rest.length; i++) {
    const a = rest[i];
    if (a === '--sessions') opts.sessions = num(rest[++i], a);
    else if (a === '--top') opts.top = num(rest[++i], a);
    else if (a === '--root') opts.root = rest[++i];
    else if (a === '--cwd') opts.cwd = rest[++i];
    else if (a === '--out') opts.out = rest[++i];
    else if (a === '--fail-over') opts.failOver = num(rest[++i], a);
    else { console.error(`unknown argument: ${a}`); process.exit(2); }
  }
  return opts;
};

// --------------------------------------------------------------- summary -----

const cmdSummary = ({ sessions }, log) => {
  const allCtx = [];
  const firstCtx = [];
  const tot = { modelTurns: 0, dead: 0, deadByStop: 0, deadNoUsage: 0, cacheBust: 0, bigPrefill: 0, compactions: 0, thinkingBytes: 0, thinkingBlocks: 0, textBytes: 0, intercomMsgs: 0, intercomBytes: 0, outputs: [], peak: 0 };
  log(`=== SESSIONS (${sessions.length} most recent) ===`);
  for (const s of sessions) {
    allCtx.push(...s.perCall);
    if (s.firstCtx) firstCtx.push(s.firstCtx);
    tot.modelTurns += s.modelTurns;
    tot.dead += s.dead; tot.deadByStop += s.deadByStop; tot.deadNoUsage += s.deadNoUsage;
    tot.cacheBust += s.cacheBust; tot.bigPrefill += s.bigPrefill; tot.compactions += s.compactions;
    tot.thinkingBytes += s.thinkingBytes; tot.thinkingBlocks += s.thinkingBlocks; tot.textBytes += s.textBytes;
    tot.intercomMsgs += s.intercomMsgs; tot.intercomBytes += s.intercomBytes;
    tot.outputs.push(...s.outputs);
    tot.peak = Math.max(tot.peak, s.peak);
    log([s.mtime, s.file.slice(0, 16), s.dir.slice(-22).padStart(22), `${s.sizeMB}MB`,
      'turns=' + s.modelTurns, 'peakCtx=' + W(s.peak), 'in=' + W(s.sumInput),
      'cache=' + W(s.sumCacheRead), 'out=' + W(s.sumOutput), 'cmpct=' + s.compactions].join('  '));
  }
  const sorted = allCtx.slice().sort((a, b) => a - b);
  const sortedFirst = firstCtx.slice().sort((a, b) => a - b);
  log('');
  log(`turn-1 (harness baseline) ctx: ${sortedFirst.length ? sortedFirst.map(W).join(' ') : 'n/a'}` +
    (sortedFirst.length ? `  | median ${W(pct(sortedFirst, 0.5))}` : ''));
  log(`model calls=${tot.modelTurns}  ctx p50=${W(pct(sorted, 0.5))} p90=${W(pct(sorted, 0.9))} max=${W(pct(sorted, 1))}`);
  log(`worst session peak ctx=${W(tot.peak)}`);
  const avgOut = tot.outputs.length ? Math.round(tot.outputs.reduce((a, b) => a + b, 0) / tot.outputs.length) : 0;
  log(`avg output/call=${W(avgOut)}  compactions=${tot.compactions}`);
  log(`thinking blocks=${tot.thinkingBlocks} total=${(tot.thinkingBytes / 1024).toFixed(0)}KB` +
    ` avg=${tot.thinkingBlocks ? Math.round(tot.thinkingBytes / tot.thinkingBlocks) : 0}B` +
    ` | assistant text total=${(tot.textBytes / 1024).toFixed(0)}KB`);
  log(`intercom custom_messages=${tot.intercomMsgs} total=${(tot.intercomBytes / 1024).toFixed(0)}KB` +
    ` avg=${tot.intercomMsgs ? Math.round(tot.intercomBytes / tot.intercomMsgs) : 0}B`);
  log(`cache_bust turns (input>${CACHE_BUST_INPUT})=${tot.cacheBust}` +
    ` | big_prefill turns (input>${BIG_PREFILL_INPUT})=${tot.bigPrefill}`);
  log(`dead turns=${tot.dead} (one increment per message; by stopReason=${tot.deadByStop}, no-usage/zero-ctx=${tot.deadNoUsage})`);
};

// -------------------------------------------------------------- dispatch -----

const COMMANDS = { summary: cmdSummary };

const main = () => {
  const opts = parseArgs(process.argv.slice(2));
  const cmd = COMMANDS[opts.cmd];
  if (!cmd) {
    console.error(`usage: ctx-audit <${Object.keys(COMMANDS).join('|')}> [--sessions N] [--cwd substr] [--root dir] [--top N] [--out file] [--fail-over tokens]`);
    process.exit(2);
  }
  const data = { sessions: loadSessions(opts), opts };
  const lines = [];
  const log = (s) => { lines.push(s); if (!opts.out || opts.cmd === 'json') console.log(s); };
  cmd(data, log);
  const report = lines.join('\n') + '\n';
  if (opts.out) fs.writeFileSync(opts.out, report);
  if (opts.failOver) {
    const over = data.sessions.filter((s) => s.peak > opts.failOver);
    if (over.length) {
      console.log(`FAIL: ${over.length} session(s) exceed peak ctx ${opts.failOver} (${over.map((s) => `${s.file.slice(0, 16)}=${W(s.peak)}`).join(', ')})`);
      process.exit(1);
    }
    console.log(`OK: no session peak ctx above ${opts.failOver}`);
  }
};

// ------------------------------------------------------------ cost / blocks --

/** One faithful weighted pass (script 1 semantics): weight = chars x model calls
 *  that still carry the block, i.e. total assistant calls minus calls already
 *  emitted at that point in the transcript. */
const collectCost = (sessions) => {
  const catAgg = {};
  const toolAgg = {};
  const bigBlocks = [];
  for (const s of sessions) {
    let calls = 0;
    for (const e of s.entries) if (e.type === 'message' && e.message?.role === 'assistant') calls++;
    let seen = 0;
    const add = (cat, chars) => {
      if (!chars) return;
      const a = (catAgg[cat] ||= { chars: 0, weighted: 0, n: 0 });
      a.chars += chars;
      a.weighted += chars * Math.max(0, calls - seen);
      a.n++;
    };
    for (const e of s.entries) {
      if (e.type === 'custom' || e.type === 'custom_message') {
        add(`custom(${e.customType || '?'})`, textOf(e.content).length || JSON.stringify(e.details || '').length);
      }
      if (e.type !== 'message') continue;
      const msg = e.message;
      if (msg.role === 'system') add('system prompt', textOf(msg.content).length);
      else if (msg.role === 'user') add('user message', textOf(msg.content).length);
      else if (msg.role === 'assistant') {
        seen++;
        let th = 0; let tx = 0;
        for (const b of msg.content || []) {
          if (b.type === 'thinking') th += (b.thinking || b.text || '').length;
          else if (b.type === 'text') tx += (b.text || '').length;
          else if (b.type === 'toolCall' || b.type === 'tool_use') {
            add(`toolCall args:${b.name || '?'}`, JSON.stringify(b.arguments ?? b.input ?? '').length);
          }
        }
        add('assistant thinking', th);
        add('assistant text', tx);
      } else if (msg.role === 'toolResult') {
        const chars = textOf(msg.content).length;
        const name = msg.toolName || '?';
        const t = (toolAgg[name] ||= { calls: 0, resultChars: 0, weighted: 0, maxChars: 0, maxFile: '' });
        t.calls++;
        t.resultChars += chars;
        t.weighted += chars * Math.max(0, calls - seen);
        if (chars > t.maxChars) { t.maxChars = chars; t.maxFile = s.file; }
        add('toolResult', chars);
        if (chars > 8000) {
          bigBlocks.push({
            chars, weight: chars * Math.max(0, calls - seen), tool: name, err: !!msg.isError,
            file: s.file, preview: preview(textOf(msg.content)),
          });
        }
      }
    }
  }
  return { catAgg, toolAgg, bigBlocks };
};

const cmdCost = ({ sessions, opts }, log) => {
  const { catAgg, toolAgg } = collectCost(sessions);
  const totWeighted = Object.values(catAgg).reduce((a, b) => a + b.weighted, 0);
  log('=== CONTEXT COST BY CATEGORY (weighted chars = chars x model-calls-that-carry-it) ===');
  for (const [k, v] of Object.entries(catAgg).sort((a, b) => b[1].weighted - a[1].weighted).slice(0, opts.top)) {
    log(`${((100 * v.weighted) / totWeighted).toFixed(1).padStart(5)}%  ${W(v.weighted).padStart(8)}  ~tok=${W(estTok(v.weighted))}  n=${String(v.n).padStart(4)}  avg=${W(Math.round(v.chars / v.n)).padStart(7)}  ${k}`);
  }
  const totTW = Object.values(toolAgg).reduce((a, b) => a + b.weighted, 0);
  log('');
  log('=== TOOL RESULTS BY WEIGHTED COST ===');
  for (const [k, v] of Object.entries(toolAgg).sort((a, b) => b[1].weighted - a[1].weighted).slice(0, opts.top)) {
    log(`${((100 * v.weighted) / totTW).toFixed(1).padStart(5)}%  weighted=${W(v.weighted).padStart(8)}  calls=${String(v.calls).padStart(4)}  avg=${W(Math.round(v.resultChars / v.calls)).padStart(7)}  max=${W(v.maxChars).padStart(7)}  ${k}`);
  }
  log('');
  log(`TOTAL weighted chars ${W(totWeighted)} (~tok ${W(estTok(totWeighted))}) | raw toolResult chars ${W(Object.values(toolAgg).reduce((a, b) => a + b.resultChars, 0))} | model turns ${sessions.reduce((a, b) => a + b.modelTurns, 0)}`);
};

const cmdBlocks = ({ sessions, opts }, log) => {
  const { bigBlocks } = collectCost(sessions);
  log(`=== TOP ${opts.top} LARGEST SINGLE TOOL RESULTS (>=8000 chars) ===`);
  for (const b of bigBlocks.sort((a, b2) => b2.chars - a.chars).slice(0, opts.top)) {
    log(`${String(b.chars).padStart(7)} w=${W(b.weight).padStart(7)} ${b.err ? 'ERR ' : '    '}${b.tool.padEnd(14)}${b.preview}`);
  }
  log(`\n${bigBlocks.length} blocks over 8000 chars across ${sessions.length} sessions (previews capped at ${PREVIEW_CHARS} chars; full bodies intentionally not printed)`);
};

COMMANDS.cost = cmdCost;
COMMANDS.blocks = cmdBlocks;

// ------------------------------------------------------------- growth / json --

const JUMP_THRESHOLD = 3000;

const cmdGrowth = ({ sessions, opts }, log) => {
  const jumps = [];
  const busts = [];
  for (const s of sessions) {
    const raw = {};
    const add = (k, v) => { if (v) raw[k] = (raw[k] || 0) + v; };
    const sysCount = s.entries.filter((e) => e.message?.role === 'system').length;
    let prevCtx = 0; let turnIdx = 0; let lastCtx = 0;
    for (const e of s.entries) {
      const msg = e.message;
      if (!msg) { add(`harness/custom (${e.type})`, JSON.stringify(e.details || '').length + textOf(e.content || '').length); continue; }
      if (msg.role === 'system') add(`system prompt x${sysCount}`, textOf(msg.content).length);
      else if (msg.role === 'user') add('user', textOf(msg.content).length);
      else if (msg.role === 'toolResult') add(`toolResult:${msg.toolName}`, textOf(msg.content).length);
      else if (msg.role === 'assistant') {
        let th = 0; let tx = 0; let tc = 0;
        for (const b of msg.content || []) {
          if (b.type === 'thinking') th += (b.thinking || b.text || '').length;
          else if (b.type === 'text') tx += (b.text || '').length;
          else if (b.type === 'toolCall') tc += JSON.stringify(b.arguments ?? '').length;
        }
        add('assistant thinking', th); add('assistant text', tx); add('toolCall args', tc);
        const u = msg.usage || {};
        const ctx = ctxOf(msg);
        turnIdx++;
        if (prevCtx && ctx > prevCtx + JUMP_THRESHOLD) {
          jumps.push({ file: s.file, turn: turnIdx, delta: ctx - prevCtx, ctx, input: u.input || 0 });
        }
        prevCtx = ctx; lastCtx = ctx || lastCtx;
        if ((u.input || 0) > CACHE_BUST_INPUT) busts.push({ file: s.file, turn: turnIdx, ctx, input: u.input, big: (u.input || 0) > BIG_PREFILL_INPUT });
      }
    }
    const totalRaw = Object.values(raw).reduce((a, b) => a + b, 0);
    const est = estTok(totalRaw);
    log(`\n### ${s.file.slice(0, 16)}  ${s.mtime}  turns=${turnIdx}  finalCtx=${W(lastCtx)}  transcriptRaw=${(totalRaw / 1024).toFixed(0)}KB  ~tok=${W(est)}  ratio(ctx/~tok)=${(lastCtx / Math.max(1, est)).toFixed(2)}`);
    for (const [k, v] of Object.entries(raw).sort((a, b) => b[1] - a[1]).slice(0, Math.min(opts.top, 10))) {
      log(`    ${((100 * v) / totalRaw).toFixed(1).padStart(5)}%  ${(v / 1024).toFixed(1).padStart(8)}KB  ${k}`);
    }
  }
  log(`\n=== BIGGEST SINGLE-TURN CTX JUMPS (> +${JUMP_THRESHOLD}, top ${opts.top}) ===`);
  for (const g of jumps.sort((a, b) => b.delta - a.delta).slice(0, opts.top)) {
    log(`+${W(g.delta).padStart(7)} -> ctx ${W(g.ctx).padStart(7)}  uncached_in=${W(g.input).padStart(7)}  turn=${String(g.turn).padStart(3)}  ${g.file.slice(0, 16)}`);
  }
  const big = busts.filter((b) => b.big);
  log(`\n=== UNCACHED INPUT: cache_bust (>${CACHE_BUST_INPUT}) turns=${busts.length}, big_prefill (>${BIG_PREFILL_INPUT}) turns=${big.length}, uncached tokens burned=${W(busts.reduce((a, b) => a + b.input, 0))} ===`);
  for (const o of busts.sort((a, b) => b.input - a.input).slice(0, opts.top)) {
    log(`uncached=${W(o.input).padStart(7)} ctx=${W(o.ctx).padStart(7)} ${o.big ? 'BIG_PREFILL' : 'cache_bust '} turn=${String(o.turn).padStart(3)}  ${o.file.slice(0, 16)}`);
  }
};

const cmdJson = ({ sessions, opts }, log) => {
  const { catAgg, toolAgg, bigBlocks } = collectCost(sessions);
  const allCtx = sessions.flatMap((s) => s.perCall).sort((a, b) => a - b);
  const firstCtx = sessions.map((s) => s.firstCtx).filter(Boolean).sort((a, b) => a - b);
  const sum = (k) => sessions.reduce((a, s) => a + s[k], 0);
  const report = {
    generatedAt: new Date().toISOString(),
    opts: { sessions: opts.sessions, top: opts.top, root: opts.root, cwd: opts.cwd, failOver: opts.failOver },
    totals: {
      sessionCount: sessions.length,
      modelCalls: sum('modelTurns'),
      ctxP50: pct(allCtx, 0.5), ctxP90: pct(allCtx, 0.9), ctxMax: pct(allCtx, 1),
      worstSessionPeakCtx: Math.max(0, ...sessions.map((s) => s.peak)),
      turn1BaselineMedian: pct(firstCtx, 0.5), turn1Baselines: firstCtx,
      deadTurns: sum('dead'), deadByStop: sum('deadByStop'), deadNoUsage: sum('deadNoUsage'),
      cacheBustTurns: sum('cacheBust'), bigPrefillTurns: sum('bigPrefill'),
      compactions: sum('compactions'),
      thinkingBytes: sum('thinkingBytes'), textBytes: sum('textBytes'),
      intercomMsgs: sum('intercomMsgs'), intercomBytes: sum('intercomBytes'),
      weightedChars: Object.values(catAgg).reduce((a, b) => a + b.weighted, 0),
      estimatedTokensFromChars: estTok(Object.values(catAgg).reduce((a, b) => a + b.weighted, 0)),
      thresholds: { cacheBustInput: CACHE_BUST_INPUT, bigPrefillInput: BIG_PREFILL_INPUT, previewChars: PREVIEW_CHARS },
    },
    sessions: sessions.map((s) => ({
      file: s.file, dir: s.dir, mtime: s.mtime, sizeMB: s.sizeMB, modelTurns: s.modelTurns,
      peakCtx: s.peak, firstCtx: s.firstCtx, lastCtx: s.lastCtx, sumInput: s.sumInput,
      sumCacheRead: s.sumCacheRead, sumOutput: s.sumOutput, compactions: s.compactions,
      dead: s.dead, deadByStop: s.deadByStop, deadNoUsage: s.deadNoUsage,
      cacheBust: s.cacheBust, bigPrefill: s.bigPrefill,
      thinkingBytes: s.thinkingBytes, textBytes: s.textBytes,
      intercomMsgs: s.intercomMsgs, intercomBytes: s.intercomBytes,
    })),
    categories: catAgg, tools: toolAgg,
    bigBlocks: bigBlocks.sort((a, b) => b.chars - a.chars).slice(0, opts.top),
  };
  log(JSON.stringify(report, null, 2));
};

COMMANDS.growth = cmdGrowth;
COMMANDS.json = cmdJson;

// Deferred so the command implementations appended below this line get a chance
// to register before dispatch happens.
process.nextTick(main);
