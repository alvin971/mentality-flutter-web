#!/usr/bin/env node
/**
 * prepare_batches.mjs — découpe un jeu de cas en lots pour des sous-agents Haiku
 * (chemin « abonnement » : aucun appel API direct, les lots sont soumis à des
 * agents lancés depuis Claude Code, cf. README).
 *
 *   node prepare_batches.mjs --prompt prompts/v1.md --set gold --set adversarial [--sample N] [--size 50] [--tag smoke]
 *   node prepare_batches.mjs --prompt prompts/v1.md --set gold --set adversarial --missing   # relance des cas sans sortie
 *
 * Écrit batches/<version>[.tag]/NNN.jsonl : une ligne par cas {id, input} — JAMAIS l'attendu.
 * L'agent écrit NNN.out.jsonl : une ligne par cas {id, score, confidence, reason}.
 * Le manifeste batches/<version>[.tag]/manifest.json garde l'ordre (mélangé) et la graine.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename } from 'node:path';
import { userInput, inputFormatOf, loadCases, shuffleSeeded } from './lib.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const sets = args.flatMap((a, i) => (a === '--set' ? [args[i + 1]] : []));
const promptPath = opt('--prompt');
if (!promptPath || !sets.length) { console.error('usage : node prepare_batches.mjs --prompt prompts/vN.md --set gold [--set adversarial] [--sample N] [--size 50] [--tag x] [--missing]'); process.exit(2); }
const version = basename(promptPath).replace(/\.md$/, '');
const FORMAT = inputFormatOf(readFileSync(join(here, promptPath), 'utf8'));
const TAG = opt('--tag', '');
const SIZE = Number(opt('--size', 50));
const SAMPLE = Number(opt('--sample', 0));
const MISSING = args.includes('--missing');
const dir = join(here, 'batches', `${version}${TAG ? '.' + TAG : ''}`);
mkdirSync(dir, { recursive: true });

let cases = loadCases(here, sets);
const seed = Date.now() % 2147483647;
cases = shuffleSeeded(cases, seed);
if (SAMPLE) cases = cases.slice(0, SAMPLE);

let start = 0;
if (MISSING) {
  const answered = new Set();
  for (const f of readdirSync(dir).filter((f) => f.endsWith('.out.jsonl'))) {
    for (const l of readFileSync(join(dir, f), 'utf8').split('\n')) { try { answered.add(JSON.parse(l).id); } catch {} }
  }
  const manifest = JSON.parse(readFileSync(join(dir, 'manifest.json'), 'utf8'));
  const wanted = new Set(manifest.ids);
  cases = cases.filter((c) => wanted.has(c.id) && !answered.has(c.id));
  start = readdirSync(dir).filter((f) => /^\d+\.jsonl$/.test(f)).length;
  console.error(`relance : ${cases.length} cas sans sortie`);
} else {
  writeFileSync(join(dir, 'manifest.json'), JSON.stringify({ version, format: FORMAT, sets, seed, sample: SAMPLE, size: SIZE, ids: cases.map((c) => c.id) }));
}

const files = [];
for (let i = 0; i < cases.length; i += SIZE) {
  const name = String(start + files.length + 1).padStart(3, '0');
  const lines = cases.slice(i, i + SIZE).map((c) => JSON.stringify({ id: c.id, input: userInput(c, FORMAT) }));
  writeFileSync(join(dir, `${name}.jsonl`), lines.join('\n') + '\n');
  files.push({ file: `${name}.jsonl`, n: lines.length });
}
console.log(JSON.stringify({ dir: dir.replace(here + '/', ''), prompt: promptPath, batches: files, total: cases.length }));
