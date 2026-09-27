#!/usr/bin/env node
// Journalise le démarrage/l'arrêt des sous-agents dans ~/.copilot/logs/agents.jsonl
// (pour mesurer le coût d'une orchestration et alimenter evals/).
import { readFileSync, appendFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';

const event = process.argv[2] ?? 'unknown';
let input = {};
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch {}
const dir = join(homedir(), '.copilot', 'logs');
try {
  mkdirSync(dir, { recursive: true });
  const pick = (...keys) => keys.map((k) => input[k]).find((v) => v !== undefined);
  appendFileSync(join(dir, 'agents.jsonl'), JSON.stringify({
    ts: new Date().toISOString(),
    event,
    session: pick('session_id', 'sessionId'),
    agent: pick('agent_name', 'agentName', 'subagent_type', 'agent', 'name'),
    cwd: pick('cwd'),
    raw: input,
  }) + '\n');
} catch {}
process.exit(0);
