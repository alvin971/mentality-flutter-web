#!/usr/bin/env node
/**
 * export_worker_assets.mjs — produit les deux fichiers EMBARQUÉS par le worker
 * `workers/correcteur/` :
 *   - banks.json : banques compactes { SI|VO → lang → item_id → {s, two, one} }
 *   - prompt.js  : `export const PROMPT = "…"` depuis prompts/FINAL.md (ou --from)
 *
 *   node export_worker_assets.mjs [--from prompts/FINAL.md]
 *
 * Choix d'hébergement des banques : EMBARQUÉES dans le bundle, pas en KV.
 *   - 990 items ≈ 500 Ko, sous la limite de bundle (3 Mo) ; zéro latence, zéro
 *     dépendance, versionnées avec le code du worker (une banque et un prompt
 *     vont ensemble : le prompt a été validé sur CES exemples) ;
 *   - un KV ajouterait un aller-retour par session et un état hors git.
 * Le format d'entrée du modèle reste celui du prompt final (cf. lib.inputFormatOf).
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { inputFormatOf } from './lib.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const from = args.includes('--from') ? args[args.indexOf('--from') + 1] : 'prompts/FINAL.md';
const promptText = readFileSync(join(here, from), 'utf8');
const out = join(here, '..', '..', 'workers', 'correcteur');

const banks = {};
for (const l of readFileSync(join(here, 'banks.jsonl'), 'utf8').trim().split('\n')) {
  const it = JSON.parse(l);
  ((banks[it.subtest] ??= {})[it.lang] ??= {})[it.id] = { s: it.stimulus, two: it.two, one: it.one };
}
writeFileSync(join(out, 'banks.json'), JSON.stringify(banks));
writeFileSync(join(out, 'prompt.js'),
  `// GÉNÉRÉ par tools/correction_lab/export_worker_assets.mjs depuis ${from} — ne pas éditer.\n` +
  `export const PROMPT_SOURCE = ${JSON.stringify(from)};\n` +
  `export const INPUT_FORMAT = ${JSON.stringify(inputFormatOf(promptText))};\n` +
  `export const PROMPT = ${JSON.stringify(promptText)};\n`);
const n = Object.values(banks).reduce((a, langs) => a + Object.values(langs).reduce((b, m) => b + Object.keys(m).length, 0), 0);
console.log(`banks.json : ${n} items · prompt.js depuis ${from} (format ${inputFormatOf(promptText)})`);
