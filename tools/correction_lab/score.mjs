#!/usr/bin/env node
/**
 * score.mjs — agrège les sorties des sous-agents (batches/<version>[.tag]/*.out.jsonl)
 * et produit results/ + failures/ exactement comme run.mjs.
 *
 *   node score.mjs --prompt prompts/v1.md --set gold --set adversarial [--tag smoke] [--blind]
 *
 * Un cas sans sortie = échec « sans réponse » (compté invalide). Un id inconnu est ignoré et signalé.
 */
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename } from 'node:path';
import { judge, allMetrics, writeReports, printSummary, loadCases } from './lib.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const sets = args.flatMap((a, i) => (a === '--set' ? [args[i + 1]] : []));
const promptPath = opt('--prompt');
const version = basename(promptPath).replace(/\.md$/, '');
const TAG = opt('--tag', '');
const BLIND = args.includes('--blind');
const dir = join(here, 'batches', `${version}${TAG ? '.' + TAG : ''}`);
const manifest = JSON.parse(readFileSync(join(dir, 'manifest.json'), 'utf8'));

const byId = new Map(loadCases(here, sets).map((c) => [c.id, c]));
const outputs = new Map();
let unknown = 0, dup = 0, badLines = 0, repaired = 0;
for (const f of readdirSync(dir).filter((f) => f.endsWith('.out.jsonl')).sort()) {
  for (const l of readFileSync(join(dir, f), 'utf8').split('\n')) {
    if (!l.trim()) continue;
    let o; try { o = JSON.parse(l); } catch { badLines++; continue; }
    if (!byId.has(o.id)) {
      // Les sous-agents recopient parfois mal le préfixe (gold-/adversarial-) : le numéro
      // de séquence est unique sur les trois jeux, on retrouve le cas par son suffixe.
      const suf = String(o.id).match(/-(\d{5})$/)?.[1];
      const cand = suf ? manifest.ids.find((k) => k.endsWith('-' + suf)) : null; // seulement parmi les cas du lot
      if (!cand) { unknown++; continue; }
      repaired++; o.id = cand;
    }
    if (outputs.has(o.id)) dup++;
    outputs.set(o.id, o); // la dernière gagne (relances)
  }
}
const cases = manifest.ids.map((id) => byId.get(id)).filter(Boolean);
const results = cases.map((c) => (outputs.has(c.id) ? judge(c, outputs.get(c.id)) : { ...judge(c, ''), why: 'aucune sortie du sous-agent' }));
const missing = results.filter((r) => r.why === 'aucune sortie du sous-agent').length;
const meta = { version, model: 'haiku (sous-agent Claude Code, abonnement)', sets, seed: manifest.seed, date: new Date().toISOString(), tag: TAG, missing, unknown_ids: unknown, ids_repaired: repaired, duplicate_ids: dup, bad_lines: badLines };
const metrics = allMetrics(results, meta);
const outName = `${version}${TAG ? '.' + TAG : ''}${BLIND ? '.blind' : ''}`;
const fails = writeReports(here, outName, metrics, results, cases, { blind: BLIND });
printSummary(metrics, outName, fails.length, BLIND);
if (missing || unknown || badLines || repaired) console.log(`  sans sortie ${missing} · ids inconnus ${unknown} · ids réparés ${repaired} · lignes illisibles ${badLines}`);
