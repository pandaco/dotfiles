#!/usr/bin/env node
// Applique model-tiers.json aux fichiers *.agent.md.
// Chaque agent déclare son niveau dans son frontmatter par un commentaire YAML : "# tier: high|medium|low|inherit"
// (commentaire => ignoré par VS Code). Le script réécrit les lignes "model:" et "reasoning-effort:".
// Usage : node sync-model-tiers.mjs [--dir <dossier agents>] [--dry-run]
import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';

const args = process.argv.slice(2);
const dry = args.includes('--dry-run');
const here = dirname(fileURLToPath(import.meta.url));
const dirArg = args.indexOf('--dir');
const agentsDir = dirArg >= 0 ? resolve(args[dirArg + 1]) : here;
const tiersFile = [join(here, 'model-tiers.json'), join(homedir(), '.copilot', 'model-tiers.json')].find(existsSync);
if (!tiersFile) { console.error('model-tiers.json introuvable'); process.exit(1); }
const { tiers } = JSON.parse(readFileSync(tiersFile, 'utf8'));

const q = (s) => `'${s.replace(/'/g, "''")}'`;
let changed = 0, errors = 0;

for (const file of readdirSync(agentsDir).filter((f) => f.endsWith('.agent.md'))) {
  const path = join(agentsDir, file);
  const src = readFileSync(path, 'utf8');
  const fm = src.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!fm) continue;
  const tierMatch = fm[1].match(/^#\s*tier:\s*(\S+)/m);
  if (!tierMatch) { console.log(`-  ${file} : pas de "# tier:", ignoré`); continue; }
  const tierName = tierMatch[1];
  if (!(tierName in tiers)) { console.error(`✗  ${file} : tier "${tierName}" inconnu`); errors++; continue; }
  const tier = tiers[tierName];

  let lines = fm[1].split(/\r?\n/).filter((l) => !/^(model|reasoning-effort):/.test(l));
  const idx = lines.findIndex((l) => /^#\s*tier:/.test(l));
  const add = tier ? [`model: [${tier.models.map(q).join(', ')}]`, ...(tier.effort ? [`reasoning-effort: ${tier.effort}`] : [])] : [];
  lines.splice(idx + 1, 0, ...add);
  const out = src.replace(fm[0], `---\n${lines.join('\n')}\n---`);
  if (out !== src) {
    changed++;
    console.log(`✓  ${file} → ${tierName}${tier ? ' : ' + tier.models[0] : ' (modèle du chat)'}`);
    if (!dry) writeFileSync(path, out);
  } else console.log(`=  ${file} → ${tierName} (inchangé)`);
}
console.log(`\n${changed} fichier(s) ${dry ? 'à modifier' : 'modifié(s)'}${errors ? `, ${errors} erreur(s)` : ''}.`);
process.exit(errors ? 1 : 0);
