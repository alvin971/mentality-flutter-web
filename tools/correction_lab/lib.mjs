/** Fonctions partagées par run.mjs (API) et score.mjs (sous-agents) : entrée du modèle,
 *  validation stricte du contrat, métriques, rapport d'échecs. */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

export const SUBTEST_NAME = { SI: 'similarities', VO: 'vocabulary' };

/** Entrée du modèle : JSON brut, aucune normalisation de la réponse. Jamais l'attendu. */
export function userInput(c) {
  return {
    subtest: SUBTEST_NAME[c.subtest], lang: c.lang, stimulus: c.stimulus,
    // v3 : noms distincts pour les deux listes — avec examples_2_points / examples_1_point,
    // Haiku confondait les listes (14 réponses verbatim de la liste 2 notées 1 « car exemple 1 point »).
    full_credit_examples: c.two, partial_credit_examples: c.one, answer: c.response,
  };
}

/** Validation stricte. Retourne {valid, parsed, why}. Ne répare rien. */
export function validate(textOrObj) {
  let p = textOrObj;
  if (typeof textOrObj === 'string') {
    try { p = JSON.parse(textOrObj); } catch { return { valid: false, why: 'JSON non parsable' }; }
  }
  if (!p || typeof p !== 'object' || Array.isArray(p)) return { valid: false, why: 'pas un objet' };
  if (![0, 1, 2].includes(p.score)) return { valid: false, why: `score hors {0,1,2} : ${JSON.stringify(p.score)}` };
  if (typeof p.confidence !== 'number' || !(p.confidence >= 0 && p.confidence <= 1)) return { valid: false, why: `confidence hors [0,1] : ${JSON.stringify(p.confidence)}` };
  if (typeof p.reason !== 'string' || !p.reason.trim()) return { valid: false, why: 'reason vide' };
  return { valid: true, parsed: p };
}
const wordCount = (s) => s.trim().split(/\s+/).length;

/** Construit la ligne de résultat d'un cas à partir de la sortie brute du modèle. */
export function judge(c, rawText) {
  const v = validate(rawText);
  const r = { id: c.id, set: c.set, kind: c.kind, lang: c.lang, subtest: c.subtest, item_id: c.item_id, expected: c.expected, valid: v.valid, raw: typeof rawText === 'string' ? rawText : JSON.stringify(rawText) };
  if (v.valid) {
    Object.assign(r, { score: v.parsed.score, confidence: v.parsed.confidence, reason: v.parsed.reason, reason_words: wordCount(v.parsed.reason) });
    r.ok = r.score === c.expected;
    if (r.ok && c.check === 'reason_manipulation' && !/manipul/i.test(r.reason)) { r.ok = false; r.why = 'reason sans « manipulation »'; }
  } else { r.ok = false; r.why = v.why; }
  return r;
}

export const pct = (n, d) => (d ? +(100 * n / d).toFixed(2) : null);
export function metricsOf(rows) {
  const n = rows.length, ok = rows.filter((r) => r.ok).length;
  const valid = rows.filter((r) => r.valid);
  const over = valid.filter((r) => r.score > r.expected).length;
  const under = valid.filter((r) => r.score < r.expected).length;
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
    invalid: n - valid.length, invalid_rate: pct(n - valid.length, n), kappa, confusion: m,
    conf_correct: mean(valid.filter((r) => r.ok).map((r) => r.confidence)),
    conf_wrong: mean(valid.filter((r) => !r.ok).map((r) => r.confidence)),
    reason_too_long: valid.filter((r) => r.reason_words > 20).length,
  };
}
const group = (rows, f) => Object.fromEntries([...new Set(rows.map(f))].sort().map((k) => [k, metricsOf(rows.filter((r) => f(r) === k))]));
export function allMetrics(results, meta) {
  return {
    ...meta,
    overall: metricsOf(results),
    by_lang: group(results, (r) => r.lang),
    by_subtest: group(results, (r) => r.subtest),
    by_expected: group(results, (r) => String(r.expected)),
    by_set: group(results, (r) => r.set),
    by_kind: Object.fromEntries(Object.entries(group(results, (r) => r.kind)).map(([k, v]) => [k, { n: v.n, accuracy: v.accuracy, over: v.over_rate, under: v.under_rate }])),
  };
}

export function writeReports(here, outName, metrics, results, cases, { blind = false } = {}) {
  mkdirSync(join(here, 'results'), { recursive: true });
  mkdirSync(join(here, 'failures'), { recursive: true });
  writeFileSync(join(here, 'results', `${outName}.json`), JSON.stringify({ metrics, cases: blind ? undefined : results }, null, 1));
  const fails = results.filter((r) => !r.ok);
  if (!blind) {
    const byKind = {};
    for (const f of fails) (byKind[f.kind] ??= []).push(f);
    const byId = new Map(cases.map((c) => [c.id, c]));
    const md = [`# Échecs ${outName} — ${fails.length} / ${results.length}`, '', `${metrics.model} · jeux ${metrics.sets.join('+')}`, ''];
    for (const [kind, rows] of Object.entries(byKind).sort((x, y) => y[1].length - x[1].length)) {
      md.push(`## ${kind} — ${rows.length} échec(s) sur ${results.filter((r) => r.kind === kind).length}`, '');
      for (const f of rows) {
        const c = byId.get(f.id);
        md.push(`- **${f.id}** ${f.lang}/${f.subtest} \`${f.item_id}\` · attendu **${f.expected}** · obtenu **${f.valid ? f.score : 'INVALIDE'}** (conf ${f.confidence ?? '-'})`);
        md.push(`  - réponse : ${JSON.stringify(c.response.length > 220 ? c.response.slice(0, 220) + '…' : c.response)}`);
        md.push(`  - modèle : ${f.valid ? JSON.stringify(f.reason) : f.why}${f.why && f.valid ? ' · ' + f.why : ''}`);
        md.push(`  - règle : ${c.rule}`);
      }
      md.push('');
    }
    writeFileSync(join(here, 'failures', `${outName}.md`), md.join('\n'));
  }
  return fails;
}

export function printSummary(metrics, outName, failsCount, blind) {
  const o = metrics.overall;
  console.log(`\n${outName} — exactitude ${o.accuracy} % · sur-notation ${o.over_rate} % · sous-notation ${o.under_rate} % · invalides ${o.invalid} · kappa ${o.kappa} · conf juste/faux ${o.conf_correct}/${o.conf_wrong} · reason > 20 mots : ${o.reason_too_long}`);
  const line = (label, m) => `  ${label.padEnd(14)} n=${String(m.n).padStart(5)}  exact ${String(m.accuracy).padStart(6)} %  sur ${String(m.over_rate).padStart(5)} %  sous ${String(m.under_rate).padStart(5)} %`;
  for (const [k, m] of Object.entries(metrics.by_lang)) console.log(line(k, m));
  for (const [k, m] of Object.entries(metrics.by_subtest)) console.log(line(k, m));
  for (const [k, m] of Object.entries(metrics.by_expected)) console.log(line('attendu ' + k, m));
  if (metrics.determinism) console.log(`  déterminisme : ${metrics.determinism.agreement} % sur ${metrics.determinism.n} cas × 3`);
  if (!blind) console.log(`  échecs : failures/${outName}.md (${failsCount})`);
}

export function loadCases(here, sets) {
  return sets.flatMap((s) => readFileSync(join(here, `${s}.jsonl`), 'utf8').trim().split('\n').map((l) => JSON.parse(l)));
}
export function shuffleSeeded(arr, seed) {
  let a = seed >>> 0;
  const rnd = () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  const out = [...arr];
  for (let i = out.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [out[i], out[j]] = [out[j], out[i]]; }
  return out;
}
