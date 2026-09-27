#!/usr/bin/env node
// Résume ~/.copilot/logs/agents.jsonl : sous-agents lancés par session et par agent.
//   node ~/.copilot/agents/agent-stats.mjs [--since 2026-09-01] [--last 5]
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
const f = join(homedir(), '.copilot', 'logs', 'agents.jsonl');
if (!existsSync(f)) { console.log('Aucun log (les hooks SubagentStart/Stop ne se sont pas encore déclenchés).'); process.exit(0); }
const a = process.argv; const since = a.includes('--since') ? a[a.indexOf('--since') + 1] : '';
const last = a.includes('--last') ? +a[a.indexOf('--last') + 1] : 10;
const rows = readFileSync(f, 'utf8').trim().split('\n').map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter((r) => r && r.event === 'SubagentStart' && r.ts >= since);
const sessions = new Map();
for (const r of rows) { const k = r.session ?? 'unknown'; const s = sessions.get(k) ?? { first: r.ts, agents: {} }; s.agents[r.agent ?? '?'] = (s.agents[r.agent ?? '?'] ?? 0) + 1; sessions.set(k, s); }
const list = [...sessions.entries()].sort((x, y) => y[1].first.localeCompare(x[1].first)).slice(0, last);
for (const [id, s] of list) {
  const total = Object.values(s.agents).reduce((a, b) => a + b, 0);
  console.log(`${s.first.slice(0, 16)}  ${String(id).slice(0, 12)}  ${total} sous-agent(s)  ${Object.entries(s.agents).map(([k, v]) => `${k}×${v}`).join(' ')}`);
}
const tot = {}; for (const r of rows) tot[r.agent ?? '?'] = (tot[r.agent ?? '?'] ?? 0) + 1;
console.log('\nTotal par agent :', Object.entries(tot).sort((x, y) => y[1] - x[1]).map(([k, v]) => `${k}×${v}`).join(' '));
