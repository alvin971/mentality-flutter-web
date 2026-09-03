#!/usr/bin/env node
/** determinism.mjs — compare les scores d'un même échantillon rejoué 3 fois (tags detA/detB/detC).
 *    node determinism.mjs --prompt prompts/v2.md
 *  Écrit results/<version>.determinism.json : taux de cas où les 3 scores coïncident. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename } from 'node:path';
const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const promptPath = args[args.indexOf('--prompt') + 1];
const version = basename(promptPath).replace(/\.md$/, '');
const runs = ['detA', 'detB', 'detC'].map((t) => {
  const f = join(here, 'results', `${version}.${t}.json`);
  if (!existsSync(f)) { console.error(`manque ${f} (lancer score.mjs --tag ${t})`); process.exit(2); }
  return new Map(JSON.parse(readFileSync(f, 'utf8')).cases.map((c) => [c.id, c.valid ? c.score : 'X']));
});
const ids = [...runs[0].keys()];
let agree = 0, allValid = 0;
const disagreements = [];
for (const id of ids) {
  const s = runs.map((r) => r.get(id));
  if (s.every((x) => x !== 'X')) allValid++;
  if (s.every((x) => x === s[0])) agree++; else disagreements.push({ id, scores: s });
}
const out = { version, n: ids.length, agreement: +(100 * agree / ids.length).toFixed(2), all_valid: allValid, disagreements };
writeFileSync(join(here, 'results', `${version}.determinism.json`), JSON.stringify(out, null, 1));
console.log(`déterminisme ${version} : ${out.agreement} % sur ${ids.length} cas × 3 (${disagreements.length} désaccords)`);
for (const d of disagreements) console.log('  ', d.id, d.scores.join(' / '));
