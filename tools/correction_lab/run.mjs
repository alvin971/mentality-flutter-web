#!/usr/bin/env node
/**
 * run.mjs — évalue une version de prompt sur un ou plusieurs jeux de cas.
 *
 *   node run.mjs --prompt prompts/v1.md --set gold --set adversarial
 *   node run.mjs --prompt prompts/v1.md --set holdout --blind      # score seul, pas de failures/
 *   node run.mjs --prompt prompts/v1.md --set gold --sample 300    # sous-échantillon (fumée)
 *   node run.mjs --prompt prompts/v1.md --set gold --determinism 200
 *
 * Options : --model <id> (défaut claude-haiku-4-5-20251001) · --concurrency 8 ·
 *           --limit N · --sample N · --no-cache · --dry (aucun appel : couverture du cache)
 *           --tag <nom> (suffixe des fichiers de sortie)
 *
 * Clé : ~/.secrets/mentality/anthropic_key (une ligne) ou ANTHROPIC_API_KEY.
 * Appel : POST /v1/messages en HTTP brut (même forme que le futur worker
 * Cloudflare, qui n'embarque pas de SDK), température 0, sortie structurée
 * (output_config.format json_schema) pour que la réponse soit du JSON pur.
 * Le harnais valide quand même tout (types, bornes, clés) et NE RÉPARE RIEN.
 *
 * Cache : cache/<sha256(model + prompt + entrée)>.json — un cas inchangé sous
 * un prompt inchangé n'est jamais repayé. --determinism contourne le cache.
 *
 * Sorties : results/<version>[tag].json (brut + métriques),
 *           failures/<version>[tag].md (tous les échecs, groupés par famille).
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename } from 'node:path';
import { homedir } from 'node:os';
import { userInput as inputObj, inputFormatOf, judge, allMetrics, writeReports, printSummary, loadCases, shuffleSeeded, pct } from './lib.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (name, def) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : def; };
const flag = (name) => args.includes(name);
const sets = args.flatMap((a, i) => (a === '--set' ? [args[i + 1]] : []));
const promptPath = opt('--prompt');
if (!promptPath || !sets.length) { console.error('usage : node run.mjs --prompt prompts/vN.md --set gold [--set adversarial]'); process.exit(2); }

const MODEL = opt('--model', 'claude-haiku-4-5-20251001');
const CONCURRENCY = Number(opt('--concurrency', 8));
const LIMIT = Number(opt('--limit', 0));
const SAMPLE = Number(opt('--sample', 0));
const DETERMINISM = Number(opt('--determinism', 0));
const NO_CACHE = flag('--no-cache');
const DRY = flag('--dry');
const BLIND = flag('--blind');
const TAG = opt('--tag', '');
const version = basename(promptPath).replace(/\.md$/, '');
const prompt = readFileSync(join(here, promptPath), 'utf8');

const keyFile = join(homedir(), '.secrets', 'mentality', 'anthropic_key');
const API_KEY = process.env.ANTHROPIC_API_KEY || (existsSync(keyFile) ? readFileSync(keyFile, 'utf8').trim() : '');
if (!API_KEY && !DRY) { console.error(`BLOQUÉ : clé absente (${keyFile})`); process.exit(3); }

const SCHEMA = {
  type: 'object', additionalProperties: false, required: ['score', 'confidence', 'reason'],
  properties: {
    score: { type: 'integer', enum: [0, 1, 2] },
    confidence: { type: 'number' },
    reason: { type: 'string' },
  },
};
function userInput(c) { return JSON.stringify(inputObj(c, inputFormatOf(prompt))); }
const sha = (s) => createHash('sha256').update(s).digest('hex');
const cacheDir = join(here, 'cache');
mkdirSync(cacheDir, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function callModel(input) {
  const body = {
    model: MODEL, max_tokens: 200, temperature: 0,
    system: [{ type: 'text', text: prompt, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: input }],
    output_config: { format: { type: 'json_schema', schema: SCHEMA } },
  };
  for (let attempt = 0; ; attempt++) {
    let res;
    try {
      res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-api-key': API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify(body),
      });
    } catch (e) {
      if (attempt >= 6) throw e;
      await sleep(1000 * 2 ** attempt); continue;
    }
    if (res.status === 429 || res.status >= 500) {
      if (attempt >= 6) throw new Error(`HTTP ${res.status} après ${attempt} essais : ${await res.text()}`);
      const ra = Number(res.headers.get('retry-after')) || 2 ** attempt;
      await sleep(ra * 1000); continue;
    }
    const json = await res.json();
    if (!res.ok) throw new Error(`HTTP ${res.status} : ${JSON.stringify(json).slice(0, 400)}`);
    const text = (json.content ?? []).filter((b) => b.type === 'text').map((b) => b.text).join('');
    return { text, stop: json.stop_reason, usage: json.usage };
  }
}


async function evaluate(c, { bypassCache = false } = {}) {
  const input = userInput(c);
  const h = sha(`${MODEL}\n${prompt}\n${input}`);
  const cf = join(cacheDir, `${h}.json`);
  let raw;
  if (!bypassCache && !NO_CACHE && existsSync(cf)) raw = JSON.parse(readFileSync(cf, 'utf8'));
  else if (DRY) return null;
  else { raw = await callModel(input); if (!bypassCache) writeFileSync(cf, JSON.stringify(raw)); }
  return judge(c, raw.text);
}

async function pool(items, fn) {
  const out = new Array(items.length);
  let next = 0, done = 0;
  const t0 = Date.now();
  const worker = async () => {
    for (;;) {
      const i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i]);
      done++;
      if (done % 250 === 0) process.stderr.write(`  ${done}/${items.length} (${((Date.now() - t0) / 1000).toFixed(0)} s)\n`);
    }
  };
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  return out;
}

// ─── Chargement + mélange (ordre différent à chaque run : graine = horloge) ──
let cases = shuffleSeeded(loadCases(here, sets), Date.now() % 2147483647);
const seed = 0;
if (SAMPLE) cases = cases.slice(0, SAMPLE);
if (LIMIT) cases = cases.slice(0, LIMIT);
console.error(`${version} · ${MODEL} · jeux ${sets.join('+')} · ${cases.length} cas · graine ${seed}${DRY ? ' · DRY' : ''}`);

const results = (await pool(cases, (c) => evaluate(c))).filter(Boolean);
if (DRY) { console.log(`cache : ${results.length}/${cases.length} cas déjà évalués`); process.exit(0); }

let metrics = allMetrics(results, { version, model: MODEL, sets, seed, date: new Date().toISOString() });

// ─── Déterminisme : N cas rejoués 3 fois sans cache ───────────────────────
if (DETERMINISM) {
  const sub = cases.slice(0, DETERMINISM);
  const runs = [];
  for (let k = 0; k < 3; k++) runs.push(await pool(sub, (c) => evaluate(c, { bypassCache: true })));
  let agree = 0;
  for (let i = 0; i < sub.length; i++) { const s = runs.map((r) => r[i].valid ? r[i].score : 'X'); if (s.every((x) => x === s[0])) agree++; }
  metrics.determinism = { n: sub.length, agreement: pct(agree, sub.length) };
}

const outName = `${version}${TAG ? '.' + TAG : ''}${BLIND ? '.blind' : ''}`;
const fails = writeReports(here, outName, metrics, results, cases, { blind: BLIND });
printSummary(metrics, outName, fails.length, BLIND);
