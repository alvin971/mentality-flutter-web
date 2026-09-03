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
const SUBTEST_NAME = { SI: 'similarities', VO: 'vocabulary' };

/** Entrée du modèle : JSON brut, aucune normalisation de la réponse (c'est au prompt de gérer). */
function userInput(c) {
  return JSON.stringify({
    subtest: SUBTEST_NAME[c.subtest], lang: c.lang, stimulus: c.stimulus,
    examples_2_points: c.two, examples_1_point: c.one, answer: c.response,
  });
}
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

/** Validation stricte du contrat. Retourne {valid, parsed, why}. */
function validate(text) {
  let p;
  try { p = JSON.parse(text); } catch { return { valid: false, why: 'JSON non parsable' }; }
  if (!p || typeof p !== 'object' || Array.isArray(p)) return { valid: false, why: 'pas un objet' };
  if (![0, 1, 2].includes(p.score)) return { valid: false, why: `score hors {0,1,2} : ${JSON.stringify(p.score)}` };
  if (typeof p.confidence !== 'number' || !(p.confidence >= 0 && p.confidence <= 1)) return { valid: false, why: `confidence hors [0,1] : ${JSON.stringify(p.confidence)}` };
  if (typeof p.reason !== 'string' || !p.reason.trim()) return { valid: false, why: 'reason vide' };
  return { valid: true, parsed: p };
}
const wordCount = (s) => s.trim().split(/\s+/).length;

async function evaluate(c, { bypassCache = false } = {}) {
  const input = userInput(c);
  const h = sha(`${MODEL}\n${prompt}\n${input}`);
  const cf = join(cacheDir, `${h}.json`);
  let raw;
  if (!bypassCache && !NO_CACHE && existsSync(cf)) raw = JSON.parse(readFileSync(cf, 'utf8'));
  else if (DRY) return null;
  else { raw = await callModel(input); if (!bypassCache) writeFileSync(cf, JSON.stringify(raw)); }
  const v = validate(raw.text);
  const r = { id: c.id, set: c.set, kind: c.kind, lang: c.lang, subtest: c.subtest, item_id: c.item_id, expected: c.expected, valid: v.valid, raw: raw.text, cached: !!raw.cachedFlag };
  if (v.valid) {
    Object.assign(r, { score: v.parsed.score, confidence: v.parsed.confidence, reason: v.parsed.reason, reason_words: wordCount(v.parsed.reason) });
    r.ok = r.score === c.expected;
    if (r.ok && c.check === 'reason_manipulation' && !/manipul/i.test(r.reason)) { r.ok = false; r.why = 'reason sans « manipulation »'; }
  } else { r.ok = false; r.why = v.why; }
  return r;
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
let cases = sets.flatMap((s) => readFileSync(join(here, `${s}.jsonl`), 'utf8').trim().split('\n').map((l) => JSON.parse(l)));
const seed = Date.now() % 2147483647;
let a = seed >>> 0;
const rnd = () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
for (let i = cases.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [cases[i], cases[j]] = [cases[j], cases[i]]; }
if (SAMPLE) cases = cases.slice(0, SAMPLE);
if (LIMIT) cases = cases.slice(0, LIMIT);
console.error(`${version} · ${MODEL} · jeux ${sets.join('+')} · ${cases.length} cas · graine ${seed}${DRY ? ' · DRY' : ''}`);

const results = (await pool(cases, (c) => evaluate(c))).filter(Boolean);
if (DRY) { console.log(`cache : ${results.length}/${cases.length} cas déjà évalués`); process.exit(0); }

// ─── Métriques ────────────────────────────────────────────────────────────
const pct = (n, d) => (d ? +(100 * n / d).toFixed(2) : null);
function metricsOf(rows) {
  const n = rows.length, ok = rows.filter((r) => r.ok).length;
  const valid = rows.filter((r) => r.valid);
  const over = valid.filter((r) => r.score > r.expected).length;
  const under = valid.filter((r) => r.score < r.expected).length;
  // kappa de Cohen (3 classes) sur les sorties valides
  const K = 3, m = Array.from({ length: K }, () => Array(K).fill(0));
  for (const r of valid) m[r.expected][r.score]++;
  const N = valid.length || 1;
  const po = (m[0][0] + m[1][1] + m[2][2]) / N;
  let pe = 0;
  for (let k = 0; k < K; k++) pe += (m[k].reduce((x, y) => x + y, 0) / N) * (m.map((row) => row[k]).reduce((x, y) => x + y, 0) / N);
  const kappa = pe === 1 ? 1 : +((po - pe) / (1 - pe)).toFixed(4);
  const mean = (xs) => (xs.length ? +(xs.reduce((x, y) => x + y, 0) / xs.length).toFixed(3) : null);
  return {
    n, accuracy: pct(ok, n), over_rate: pct(over, n), under_rate: pct(under, n),
    invalid: n - valid.length, invalid_rate: pct(n - valid.length, n), kappa,
    confusion: m,
    conf_correct: mean(valid.filter((r) => r.ok).map((r) => r.confidence)),
    conf_wrong: mean(valid.filter((r) => !r.ok).map((r) => r.confidence)),
    reason_too_long: valid.filter((r) => r.reason_words > 20).length,
  };
}
const group = (rows, f) => Object.fromEntries([...new Set(rows.map(f))].sort().map((k) => [k, metricsOf(rows.filter((r) => f(r) === k))]));
const metrics = {
  version, model: MODEL, sets, seed, date: new Date().toISOString(),
  overall: metricsOf(results),
  by_lang: group(results, (r) => r.lang),
  by_subtest: group(results, (r) => r.subtest),
  by_expected: group(results, (r) => String(r.expected)),
  by_set: group(results, (r) => r.set),
  by_kind: Object.fromEntries(Object.entries(group(results, (r) => r.kind)).map(([k, v]) => [k, { n: v.n, accuracy: v.accuracy }])),
};

// ─── Déterminisme : N cas rejoués 3 fois sans cache ───────────────────────
if (DETERMINISM) {
  const sub = cases.slice(0, DETERMINISM);
  const runs = [];
  for (let k = 0; k < 3; k++) runs.push(await pool(sub, (c) => evaluate(c, { bypassCache: true })));
  let agree = 0;
  for (let i = 0; i < sub.length; i++) { const s = runs.map((r) => r[i].valid ? r[i].score : 'X'); if (s.every((x) => x === s[0])) agree++; }
  metrics.determinism = { n: sub.length, agreement: pct(agree, sub.length) };
}

// ─── Écriture ─────────────────────────────────────────────────────────────
mkdirSync(join(here, 'results'), { recursive: true });
mkdirSync(join(here, 'failures'), { recursive: true });
const outName = `${version}${TAG ? '.' + TAG : ''}${BLIND ? '.blind' : ''}`;
writeFileSync(join(here, 'results', `${outName}.json`), JSON.stringify({ metrics, cases: BLIND ? undefined : results }, null, 1));

const fails = results.filter((r) => !r.ok);
if (!BLIND) {
  const byKind = {};
  for (const f of fails) (byKind[f.kind] ??= []).push(f);
  const md = [`# Échecs ${outName} — ${fails.length} / ${results.length}`, '', `Modèle ${MODEL} · jeux ${sets.join('+')} · graine ${seed}`, ''];
  for (const [kind, rows] of Object.entries(byKind).sort((x, y) => y[1].length - x[1].length)) {
    md.push(`## ${kind} — ${rows.length} échec(s) sur ${results.filter((r) => r.kind === kind).length}`, '');
    for (const f of rows) {
      const c = cases.find((x) => x.id === f.id);
      md.push(`- **${f.id}** ${f.lang}/${f.subtest} \`${f.item_id}\` · attendu **${f.expected}** · obtenu **${f.valid ? f.score : 'INVALIDE'}** (conf ${f.confidence ?? '-'})`);
      md.push(`  - réponse : ${JSON.stringify(c.response.length > 220 ? c.response.slice(0, 220) + '…' : c.response)}`);
      md.push(`  - modèle : ${f.valid ? JSON.stringify(f.reason) : f.why}${f.why && f.valid ? ' · ' + f.why : ''}`);
      md.push(`  - règle : ${c.rule}`);
    }
    md.push('');
  }
  writeFileSync(join(here, 'failures', `${outName}.md`), md.join('\n'));
}

// ─── Bilan console ────────────────────────────────────────────────────────
const o = metrics.overall;
console.log(`\n${outName} — exactitude ${o.accuracy} % · sur-notation ${o.over_rate} % · sous-notation ${o.under_rate} % · invalides ${o.invalid} · kappa ${o.kappa} · conf juste/faux ${o.conf_correct}/${o.conf_wrong} · reason > 20 mots : ${o.reason_too_long}`);
const line = (label, m) => `  ${label.padEnd(14)} n=${String(m.n).padStart(5)}  exact ${String(m.accuracy).padStart(6)} %  sur ${String(m.over_rate).padStart(5)} %  sous ${String(m.under_rate).padStart(5)} %`;
for (const [k, m] of Object.entries(metrics.by_lang)) console.log(line(k, m));
for (const [k, m] of Object.entries(metrics.by_subtest)) console.log(line(k, m));
for (const [k, m] of Object.entries(metrics.by_expected)) console.log(line('attendu ' + k, m));
if (metrics.determinism) console.log(`  déterminisme : ${metrics.determinism.agreement} % sur ${metrics.determinism.n} cas × 3`);
if (!BLIND) console.log(`  échecs : failures/${outName}.md (${fails.length})`);
