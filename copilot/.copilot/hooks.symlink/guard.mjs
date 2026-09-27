#!/usr/bin/env node
// Garde-fous déterministes pour les agents (hook PreToolUse, VS Code / format Claude compatible).
// - refuse `nx` en direct (npx/pnpm/yarn/bin inclus)
// - refuse `--no-verify`, `push --force`, tout `Co-authored-by`
// - valide le message de `git commit -m "<sujet>" -m "<body>"` ou `-F <fichier>` (Conventional Commits + body + pas de co-auteur), puis demande confirmation
// - demande confirmation pour commit/push/rebase/reset --hard/merge/amend/clean/branch -D et scripts npm de déploiement
// - base de données : client direct en lecture seule (confirmation), écriture/DDL refusées, CLI TypeORM directe refusée, scripts de migration/seed/reset avec confirmation
// - Jira/Confluence (outils MCP) : lecture libre, écriture avec confirmation
// - refuse tout déploiement/suppression AWS direct (serverless, sam, cdk, terraform, aws cli modifiant) et la lecture de secrets
// Aucune sortie = autorisé.
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const raw = readFileSync(0, 'utf8');
let input = {};
try { input = JSON.parse(raw || '{}'); } catch { process.exit(0); }

const toolName = String(input.tool_name ?? input.toolName ?? '');
const ti = input.tool_input ?? input.toolInput ?? {};
const command = typeof ti === 'string' ? ti : (ti.command ?? ti.commandLine ?? ti.cmd ?? ti.script ?? '');
// Jira / Confluence (MCP) : lecture libre, toute écriture demande confirmation
if (/atlassian|jira|confluence/i.test(toolName)) {
  const op = toolName.split(/\/|__|\.|:/).pop();
  if (/^(mcp_\w+?_)?(get|search|list|lookup|fetch|read|query|atlassianUserInfo|getAccessible)/i.test(op)) process.exit(0);
  if (/create|update|edit|delete|transition|add|comment|move|link|assign|upload|worklog|set|remove|archive/i.test(op)) {
    process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'ask', permissionDecisionReason: `Écriture Jira/Confluence (${op}) : validation utilisateur requise.` } }));
    process.exit(0);
  }
  process.exit(0);
}
const isTerminal = /terminal|bash|shell|command|execute|run_in/i.test(toolName) || (typeof command === 'string' && command.length > 0);
if (!isTerminal || typeof command !== 'string' || !command.trim()) process.exit(0);

const cwd = ti.cwd ?? ti.workingDirectory ?? input.cwd ?? process.cwd();

const deny = (reason) => {
  process.stderr.write(`[guard] ${reason}\n`);
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason } }));
  process.exit(2);
};
const ask = (reason) => {
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'ask', permissionDecisionReason: reason } }));
  process.exit(0);
};

if (/co-authored-by/i.test(command)) deny('Co-authored-by interdit dans les commits.');

// Découpe en sous-commandes et retire les affectations d'env en tête (FOO=bar cmd)
const segments = command.split(/&&|\|\||;|\||\r?\n/).map((s) => s.trim().replace(/^(\w+=\S*\s+)+/, '')).filter(Boolean);

const asks = [];

// --- git commit : validation du message (-m, --message, -F) sur la commande complète
const tokenize = (str) => {
  const out = []; let cur = null, i = 0;
  const push = () => { if (cur !== null) { out.push(cur); cur = null; } };
  while (i < str.length) {
    const c = str[i];
    if (c === "'") { const j = str.indexOf("'", i + 1); cur = (cur ?? '') + str.slice(i + 1, j < 0 ? str.length : j); i = j < 0 ? str.length : j + 1; continue; }
    if (c === '"') {
      let j = i + 1, buf = '';
      while (j < str.length && str[j] !== '"') { if (str[j] === '\\' && j + 1 < str.length) { buf += str[j + 1]; j += 2; } else buf += str[j++]; }
      cur = (cur ?? '') + buf; i = j + 1; continue;
    }
    if (/\s/.test(c) && c !== '\n') { push(); i++; continue; }
    if (c === '\n' || c === ';' || c === '|' || c === '&') { push(); out.push({ sep: c }); i++; continue; }
    if (c === '\\' && i + 1 < str.length) { cur = (cur ?? '') + str[i + 1]; i += 2; continue; }
    cur = (cur ?? '') + c; i++;
  }
  push(); return out;
};
const validateMessage = (msg, source) => {
  msg = msg.replace(/\r\n/g, '\n').replace(/^#.*\n/gm, '').trim();
  const [header = '', blank, ...rest] = msg.split('\n');
  const body = rest.join('\n').trim();
  if (!/^(feat|fix|refactor|perf|test|docs|chore|ci|build|style|revert)(\([\w.\/-]+\))?!?: \S.{0,70}$/.test(header))
    deny(`En-tête non conforme Conventional Commits (type(scope): sujet, ≤ 72 car.) : « ${header} » (${source})`);
  if (/\.$/.test(header)) deny('Le sujet du commit ne doit pas finir par un point.');
  if (blank !== '' || body.length < 20) deny('Body obligatoire : sujet, ligne vide, puis explication problème → solution (ex. git commit -m "<sujet>" -m "<body>").');
  if (/co-authored-by|signed-off-by/i.test(body)) deny('Trailer Co-authored-by / Signed-off-by interdit.');
};
{
  const toks = tokenize(command);
  for (let i = 0; i < toks.length; i++) {
    if (toks[i] !== 'git') continue;
    let j = i + 1;
    while (j < toks.length && typeof toks[j] === 'string' && /^-(C|c)$/.test(toks[j])) j += 2;
    if (toks[j] !== 'commit') continue;
    const args = [];
    for (let k = j + 1; k < toks.length && typeof toks[k] === 'string'; k++) args.push(toks[k]);
    if (args.some((a) => a === '--no-verify' || a === '-n' || /^-[a-zA-Z]*n[a-zA-Z]*$/.test(a) && !a.startsWith('--')))
      deny('git commit --no-verify interdit.');
    const msgs = []; let file = null, unverifiable = false;
    for (let k = 0; k < args.length; k++) {
      const a = args[k];
      if (a === '-m' || a === '--message') msgs.push(args[++k] ?? '');
      else if (a.startsWith('--message=')) msgs.push(a.slice(10));
      else if (/^-[a-zA-Z]*m$/.test(a) && !a.startsWith('--')) msgs.push(args[++k] ?? '');
      else if (/^-m./.test(a)) msgs.push(a.slice(2));
      else if (a === '-F' || a === '--file') file = args[++k];
      else if (a.startsWith('--file=')) file = a.slice(7);
    }
    if (msgs.some((m) => /\$\(|`/.test(m))) unverifiable = true;
    if (file) {
      const fp = resolve(cwd, file);
      if (!existsSync(fp)) deny(`Fichier de message introuvable : ${fp}`);
      validateMessage(readFileSync(fp, 'utf8'), '-F');
    } else if (msgs.length && !unverifiable) {
      // -m "sujet" -m "body" : paragraphes séparés par une ligne vide (comportement git)
      validateMessage(msgs.join('\n\n'), '-m');
    } else if (!msgs.length && !args.includes('--no-edit') && !args.includes('--amend')) {
      deny('Message de commit requis dans la commande (-m "<sujet>" -m "<body>" ou -F <fichier>) : pas d\'éditeur interactif.');
    }
    if (unverifiable) asks.push('git commit (message généré par le shell, non vérifiable automatiquement)');
  }
}


// Bases de données : client direct en lecture seule, jamais d'écriture/DDL ; migrations via scripts npm
const DB_CLIENT = /^(psql|pgcli|mysql|mariadb|mongosh|mongo|sqlcmd|sqlite3|cqlsh|redis-cli)(\s|$)/;
const TYPEORM_CLI = /^(npx\s+)?(typeorm|typeorm-ts-node-(commonjs|esm))\s+(migration|schema|query)/;
if (segments.some((seg) => TYPEORM_CLI.test(seg)))
  deny('CLI TypeORM directe interdite : utilise le script npm du projet (migration:generate, migration:run…).');
if (segments.some((seg) => DB_CLIENT.test(seg))) {
  let sql = command;
  const file = command.match(/(?:\s-f\s+|\s--file[= ]|<\s*)("([^"]+)"|'([^']+)'|(\S+))/);
  if (file) {
    const fp = resolve(cwd, file[2] ?? file[3] ?? file[4]);
    sql += existsSync(fp) ? '\n' + readFileSync(fp, 'utf8') : '';
    if (!existsSync(fp)) deny(`Script SQL introuvable pour vérification : ${fp}`);
  }
  const noComments = sql; // volontairement conservateur : un mot-clé d'écriture même en commentaire est refusé
  if (/\b(insert|update|delete|merge|upsert|drop|truncate|alter|create|grant|revoke|reindex|cluster|comment\s+on|refresh\s+materialized|call|do|copy\s+[\w."]+\s+from|vacuum\s+full|lock\s+table|set\s+role)\b/i.test(noComments))
    deny('Écriture ou DDL via un client de base interdite aux agents : passe par une migration versionnée (script npm).');
  if (/\b(insertOne|insertMany|updateOne|updateMany|replaceOne|deleteOne|deleteMany|remove|drop|dropDatabase|dropIndex|dropIndexes|createIndex|createIndexes|createCollection|renameCollection|bulkWrite|findOneAndUpdate|findOneAndReplace|findOneAndDelete|findAndModify|\$out|\$merge|flushall|flushdb|del|set|expire)\b/.test(noComments))
    deny('Écriture NoSQL via un client direct interdite aux agents : passe par une migration ou le code applicatif.');
  if (/(^|\s)redis-cli\b/.test(sql) && /\b(del|unlink|set|setex|mset|hset|hdel|lpush|rpush|lpop|rpop|sadd|srem|zadd|zrem|incr|incrby|decr|expire|persist|rename|flushall|flushdb|config|eval)\b/i.test(sql))
    deny('Écriture Redis via redis-cli interdite aux agents.');
  asks.push('connexion base de données (lecture seule, base locale/dev uniquement)');
}
for (const seg of segments) {
  // nx en direct
  if (/^(npx\s+(--\S+\s+)*|pnpm\s+(exec\s+|dlx\s+)?|yarn\s+(dlx\s+)?|bunx\s+)?(\S*node_modules[\\/]\.bin[\\/])?nx(\s|$)/.test(seg))
    deny(`Appel direct à nx interdit (« ${seg} »). Utilise un script npm (npm run <script>) ; s'il n'existe pas, propose-le dans package.json.`);

  // AWS : jamais de déploiement ni de modification du compte par un agent
  const aws = seg.replace(/^npx\s+(--\S+\s+)*/, '');
  if (/^(serverless|sls)\s+(deploy|remove|rollback|invoke(?!\s+local))\b/.test(aws))
    deny(`Déploiement/suppression Serverless interdit aux agents (« ${seg} »). Propose la commande à l'utilisateur.`);
  if (/^(sam\s+(deploy|delete|sync)|cdk\s+(deploy|destroy|bootstrap)|terraform\s+(apply|destroy|import))\b/.test(aws))
    deny(`Déploiement d'infrastructure interdit aux agents (« ${seg} »).`);
  if (/^aws\s/.test(aws)) {
    if (/^aws\s+cloudformation\s+(validate-template|describe-|list-|get-|detect-stack-drift|estimate-template-cost)/.test(aws)) continue;
    if (/^aws\s+\S+\s+(describe-|list-|get-)/.test(aws) && !/get-secret-value|get-parameters?\b.*--with-decryption|get-object\b/.test(aws)) continue;
    deny(`Commande AWS modifiante ou sensible interdite aux agents (« ${seg} »). Seules les lectures describe/list/get (hors secrets) sont permises.`);
  }
  // Scripts npm de déploiement : confirmation obligatoire
  const npmRun = seg.match(/^(npm|pnpm|yarn)\s+(run\s+)?([\w:.-]+)/);
  if (npmRun && /deploy|remove|destroy|teardown|rollback|release|publish|migrat\w*:(run|revert|up|down)|db:(reset|drop|seed|migrate)|schema:(drop|sync)|seed/i.test(npmRun[3])) { asks.push(`script ${npmRun[3]}`); continue; }

  if (!/^git(\s|$)/.test(seg)) continue;
  const g = seg.replace(/^git\s+(-C\s+\S+\s+|-c\s+\S+\s+)*/, '');

  if (/^commit\b/.test(g)) {
    // Validation faite sur la commande complète (le message peut contenir ; | ou des retours à la ligne)
    asks.push(/--amend/.test(g) ? 'git commit --amend' : 'git commit');
    continue;
  }
  if (/^push\b/.test(g)) {
    if (/--force(?!-with-lease)|(^|\s)-f(\s|$)/.test(g)) deny('git push --force interdit (utilise --force-with-lease après accord explicite).');
    asks.push('git push');
    continue;
  }
  if (/^(rebase|merge|cherry-pick|revert)\b/.test(g)) { asks.push(`git ${g.split(/\s/)[0]}`); continue; }
  if (/^reset\b.*--hard/.test(g)) { asks.push('git reset --hard'); continue; }
  if (/^clean\b.*-\w*f/.test(g)) { asks.push('git clean -f'); continue; }
  if (/^branch\b.*\s-D\b/.test(g)) { asks.push('git branch -D'); continue; }
  if (/^stash\s+(drop|clear)\b/.test(g)) { asks.push('git stash drop/clear'); continue; }
  if (/^tag\b.*\s-d\b/.test(g)) { asks.push('git tag -d'); continue; }
}

if (asks.length) ask(`Action sensible (${[...new Set(asks)].join(', ')}) : validation utilisateur requise.`);
process.exit(0);
