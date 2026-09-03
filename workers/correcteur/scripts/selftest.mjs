#!/usr/bin/env node
/**
 * Auto-test du worker correcteur — zéro réseau, zéro compte : `fetch` est
 * intercepté ; Supabase est une base en mémoire, Anthropic un script de
 * réponses. Le JS de production s'exécute tel quel.
 *
 *   node workers/correcteur/scripts/selftest.mjs
 *
 * Couvre (§7.3 du protocole) : règle d'arrêt post-hoc, idempotence, lot
 * partiel, JSON invalide du modèle → ligne laissée en attente, confiance basse
 * → ai_review, une langue par session (vote), ordre des items respecté,
 * réponse vide sans appel, erreur API sans demi-score, plafond de tentatives,
 * item hors banque, auth admin, cron, secrets manquants, aucune PII en journal.
 *
 * À lancer avant chaque `wrangler deploy`.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

// Le worker importe banks.json et prompt.js : Node 22 accepte `import json` avec
// un attribut — on passe par un chargeur minimal pour rester sans dépendance.
const here = dirname(fileURLToPath(import.meta.url));
const banks = JSON.parse(readFileSync(join(here, '..', 'banks.json'), 'utf8'));
globalThis.__banks = banks;

let passed = 0, failed = 0;
function ok(cond, label) { if (cond) passed++; else { failed++; console.error('  ✗', label); } }
function eq(a, b, label) { ok(JSON.stringify(a) === JSON.stringify(b), `${label} : ${JSON.stringify(a)} ≠ ${JSON.stringify(b)}`); }

// ─── Supabase en mémoire ─────────────────────────────────────────────────────
const db = { test_results: [], test_items: [] };
const SB = 'https://sb.test';
function parseFilters(qs) {
  const f = [];
  for (const [k, v] of qs) {
    if (['select', 'order', 'limit', 'on_conflict'].includes(k)) continue;
    const m = /^(eq|lt|in)\.(.*)$/.exec(v);
    if (!m) throw new Error(`filtre inconnu ${k}=${v}`);
    f.push({ k, op: m[1], v: m[2] });
  }
  return f;
}
function matches(row, filters) {
  return filters.every(({ k, op, v }) => {
    const x = row[k];
    if (op === 'eq') return String(x) === v || (v === 'true' && x === true) || (v === 'false' && x === false);
    if (op === 'lt') return Number(x) < Number(v);
    if (op === 'in') return v.replace(/^\(|\)$/g, '').split(',').includes(String(x));
    return false;
  });
}
const calls = { sb: [], api: [] };
let apiScript = [];   // file de réponses Anthropic : {text} | {status} | {throw}
let apiInputs = [];
async function fakeFetch(url, init = {}) {
  const u = new URL(url);
  if (u.origin === SB) {
    const table = u.pathname.split('/').pop();
    const filters = parseFilters(u.searchParams);
    calls.sb.push({ method: init.method || 'GET', table, filters });
    if (!init.method || init.method === 'GET') {
      let rows = db[table].filter((r) => matches(r, filters));
      const order = u.searchParams.get('order');
      if (order) { const [col, dir] = order.split('.'); rows = [...rows].sort((a, b) => (a[col] > b[col] ? 1 : -1) * (dir === 'desc' ? -1 : 1)); }
      const limit = Number(u.searchParams.get('limit') || 0);
      if (limit) rows = rows.slice(0, limit);
      return new Response(JSON.stringify(rows), { status: 200 });
    }
    if (init.method === 'PATCH') {
      if (db.__failPatch) { db.__failPatch = false; return new Response('boom', { status: 500 }); }
      const patch = JSON.parse(init.body);
      for (const r of db[table]) if (matches(r, filters)) Object.assign(r, patch);
      return new Response(null, { status: 204 });
    }
    if (init.method === 'POST') {
      const keys = u.searchParams.get('on_conflict').split(',');
      for (const row of JSON.parse(init.body)) {
        const ex = db[table].find((r) => keys.every((k) => String(r[k]) === String(row[k])));
        if (ex) Object.assign(ex, row); else db[table].push({ ...row });
      }
      return new Response(null, { status: 201 });
    }
  }
  if (u.hostname === 'api.anthropic.com') {
    const body = JSON.parse(init.body);
    apiInputs.push(JSON.parse(body.messages[0].content));
    calls.api.push(body);
    const next = apiScript.shift() ?? { text: '{"score":2,"confidence":0.95,"reason":"ok"}' };
    if (next.throw) throw new TypeError('network down');
    if (next.status) return new Response(JSON.stringify({ error: 'x' }), { status: next.status });
    return new Response(JSON.stringify({ content: [{ type: 'text', text: next.text }], stop_reason: 'end_turn' }), { status: 200 });
  }
  throw new Error(`fetch inattendu ${url}`);
}
globalThis.fetch = fakeFetch;

const worker = (await import('../index.js')).default;
const { inferLanguage, buildInput, validate, scoreRow, runBatch } = await import('../index.js');

const env = { SUPABASE_URL: SB, SUPABASE_SERVICE_KEY: 'k', ANTHROPIC_API_KEY: 'a', ADMIN_SECRET: 'secret-admin', MAX_ATTEMPTS: '3', REVIEW_THRESHOLD: '0.6', BATCH_ROWS: '40' };

// Fabrique une session : items SI fr (Orange/Banane, …) avec réponses.
let seq = 0;
// Items propres à UNE langue : 18 identifiants sur 972 existent dans deux banques
// (« Orange/Banane » est aussi allemand) — une session d'un seul item ambigu est
// indécidable par construction, ce que le test 11 vérifie séparément.
function bankItems(code, lang, n) {
  return Object.keys(banks[code][lang])
    .filter((id) => Object.keys(banks[code]).filter((l) => banks[code][l][id]).length === 1)
    .slice(0, n);
}
function addSession({ subtest = 'similarities', lang = 'fr', responses, status = 'ai_pending', complete = true, attempts = 0, itemIds }) {
  const sid = `s${++seq}`;
  const code = subtest === 'similarities' ? 'SI' : 'VO';
  const ids = itemIds ?? bankItems(code, lang, responses.length);
  db.test_results.push({ id: `r${seq}`, session_id: sid, subtest, scoring_status: status, is_complete: complete, ai_attempts: attempts, created_at: `2026-09-03T00:00:${String(seq).padStart(2, '0')}Z`, raw_score: null });
  responses.forEach((resp, i) => db.test_items.push({ id: `i${seq}-${i}`, session_id: sid, subtest, item_index: i, item_id: ids[i], response: resp, skipped: resp === null, score: null }));
  return { sid, rid: `r${seq}` };
}
const result = (rid) => db.test_results.find((r) => r.id === rid);
const items = (sid) => db.test_items.filter((r) => r.session_id === sid).sort((a, b) => a.item_index - b.item_index);
const reset = () => { db.test_results = []; db.test_items = []; calls.sb = []; calls.api = []; apiScript = []; apiInputs = []; };
const out = (s, c = 0.9) => ({ text: JSON.stringify({ score: s, confidence: c, reason: 'r' }) });

// ─── 1. Validation du contrat ────────────────────────────────────────────────
console.log('1. contrat de sortie');
ok(validate('{"score":1,"confidence":0.5,"reason":"x"}').valid, 'JSON valide accepté');
ok(!validate('pas du json').valid, 'texte libre refusé');
ok(!validate('{"score":3,"confidence":0.5,"reason":"x"}').valid, 'score 3 refusé');
ok(!validate('{"score":"1","confidence":0.5,"reason":"x"}').valid, 'score chaîne refusé');
ok(!validate('{"score":1,"confidence":1.5,"reason":"x"}').valid, 'confiance > 1 refusée');
ok(!validate('{"score":1,"confidence":0.5,"reason":""}').valid, 'reason vide refusée');
ok(!validate('[1,2]').valid, 'tableau refusé');

// ─── 2. Langue par vote ──────────────────────────────────────────────────────
console.log('2. langue');
eq(inferLanguage('SI', bankItems('SI', 'fr', 5).map((id) => ({ item_id: id }))), 'fr', 'vote fr');
eq(inferLanguage('SI', bankItems('SI', 'en', 5).map((id) => ({ item_id: id }))), 'en', 'vote en');
eq(inferLanguage('VO', bankItems('VO', 'de', 5).map((id) => ({ item_id: id }))), 'de', 'vote de');
eq(inferLanguage('SI', [{ item_id: 'zzz/yyy' }]), null, 'inconnu → null');
eq(inferLanguage('SI', []), null, 'vide → null');
eq(inferLanguage('SI', [{ item_id: null }]), null, 'item_id nul → null');

// ─── 3. Entrée du modèle ─────────────────────────────────────────────────────
console.log('3. entrée du modèle');
const entry = banks.SI.fr['Orange/Banane'];
const inp = buildInput('similarities', 'fr', entry, 'Fruit');
eq(inp.answer, 'Fruit', 'réponse brute transmise');
eq(inp.stimulus, { word1: 'Orange', word2: 'Banane' }, 'stimulus');
ok(Array.isArray(inp.examples_2_points) && inp.examples_2_points.includes('Des fruits'), 'exemples 2 points (format points)');
ok(Array.isArray(inp.examples_1_point), 'exemples 1 point');

// ─── 4. Notation nominale ────────────────────────────────────────────────────
console.log('4. nominal');
reset();
let s = addSession({ responses: ['Fruit', 'On les mange', 'des meubles'] });
apiScript = [out(2), out(1), out(2)];
let r = await scoreRow(env, result(s.rid));
ok(r.ok, 'ligne notée');
eq(r.calls, 3, '3 appels modèle');
eq(items(s.sid).map((i) => i.score), [2, 1, 2], 'scores écrits dans l’ordre des items');
eq(result(s.rid).raw_score, 5, 'raw_score = somme');
eq(result(s.rid).max_score, 6, 'max_score = 2 × items');
eq(result(s.rid).scoring_status, 'ai_scored', 'statut ai_scored');
eq(result(s.rid).ai_review, false, 'pas de relecture');
ok(typeof result(s.rid).ai_scored_at === 'string', 'ai_scored_at posé');
ok(items(s.sid).every((i) => typeof i.ai_confidence === 'number'), 'ai_confidence écrite');
eq(apiInputs.map((x) => x.answer), ['Fruit', 'On les mange', 'des meubles'], 'appels dans l’ordre d’administration');
ok(calls.api.every((b) => b.temperature === 0 && b.model === 'claude-haiku-4-5-20251001'), 'température 0, Haiku 4.5');
ok(calls.api.every((b) => b.output_config?.format?.type === 'json_schema'), 'sortie structurée demandée');

// ─── 5. Règle d'arrêt post-hoc ───────────────────────────────────────────────
console.log('5. règle d’arrêt');
reset();
s = addSession({ responses: ['a', 'b', 'c', 'Fruit', 'Fruit', 'x'] });
apiScript = [out(1), out(0), out(0), out(0), out(2), out(2)]; // 3 zéros aux rangs 1-3 → 4 et 5 valent 0
r = await scoreRow(env, result(s.rid));
eq(items(s.sid).map((i) => i.score), [1, 0, 0, 0, 0, 0], 'après trois 0 consécutifs, tout vaut 0');
eq(r.calls, 4, 'plus aucun appel modèle après l’arrêt');
eq(result(s.rid).raw_score, 1, 'raw_score respecte l’arrêt');
ok(r.stopped, 'arrêt signalé');
reset();
s = addSession({ responses: ['a', 'b', 'c', 'd', 'e'] });
apiScript = [out(0), out(0), out(1), out(0), out(0)]; // jamais 3 consécutifs
r = await scoreRow(env, result(s.rid));
eq(items(s.sid).map((i) => i.score), [0, 0, 1, 0, 0], 'zéros non consécutifs : pas d’arrêt');
eq(r.calls, 5, 'tous les items appelés');

// ─── 6. Réponse vide / item sauté : 0 sans appel ─────────────────────────────
console.log('6. vide');
reset();
s = addSession({ responses: ['Fruit', '', '   ', null, 'ok'] });
apiScript = [out(2), out(1)];
r = await scoreRow(env, result(s.rid));
eq(r.calls, 1, 'vide et sauté ne coûtent pas d’appel, et trois vides déclenchent l’arrêt');
eq(items(s.sid).map((i) => i.score), [2, 0, 0, 0, 0], 'vide=0, blanc=0, sauté=0 puis arrêt');
ok(items(s.sid)[1].ai_confidence === null, 'pas de confiance modèle sur un 0 déterministe');

// ─── 7. Confiance basse → relecture ──────────────────────────────────────────
console.log('7. confiance');
reset();
s = addSession({ responses: ['a', 'b'] });
apiScript = [out(2, 0.95), out(1, 0.4)];
r = await scoreRow(env, result(s.rid));
ok(r.ok && result(s.rid).scoring_status === 'ai_scored', 'notée quand même');
eq(result(s.rid).ai_review, true, 'ai_review = true sous 0,6');
reset();
s = addSession({ responses: ['a'] }); apiScript = [out(2, 0.6)];
await scoreRow(env, result(s.rid));
eq(result(s.rid).ai_review, false, '0,6 exactement n’est pas sous le seuil');

// ─── 8. JSON invalide → rien d'écrit, tentative comptée ──────────────────────
console.log('8. JSON invalide');
reset();
s = addSession({ responses: ['a', 'b', 'c'] });
apiScript = [out(2), { text: 'je pense que 2' }, out(2)];
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'json_invalide', 'ligne différée pour JSON invalide');
eq(items(s.sid).map((i) => i.score), [null, null, null], 'AUCUN score écrit (pas de demi-score)');
eq(result(s.rid).scoring_status, 'ai_pending', 'reste en attente');
eq(result(s.rid).ai_attempts, 1, 'tentative comptée');
eq(result(s.rid).raw_score, null, 'raw_score intact');

// ─── 9. Erreur API (réseau, 5xx, 429 puis succès) ────────────────────────────
console.log('9. erreurs API');
reset();
s = addSession({ responses: ['a', 'b'] });
apiScript = [out(2), { throw: true }, { throw: true }, { throw: true }];
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'api_network', 'réseau : différée');
eq(items(s.sid).map((i) => i.score), [null, null], 'rien d’écrit malgré un premier item réussi');
reset();
s = addSession({ responses: ['a'] });
apiScript = [{ status: 500 }, { status: 500 }, { status: 500 }];
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'api_http500', '5xx persistant : différée');
reset();
s = addSession({ responses: ['a'] });
apiScript = [{ status: 429 }, out(2)];
r = await scoreRow(env, result(s.rid));
ok(r.ok && items(s.sid)[0].score === 2, '429 puis succès : notée');
reset();
s = addSession({ responses: ['a'] });
apiScript = [{ status: 400 }];
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'api_http400', '400 : pas de retry, différée');

// ─── 10. Plafond de tentatives → ai_review ──────────────────────────────────
console.log('10. tentatives');
reset();
s = addSession({ responses: ['a'], attempts: 2 }); // MAX_ATTEMPTS = 3
apiScript = [{ text: 'nope' }];
r = await scoreRow(env, result(s.rid));
eq(result(s.rid).ai_attempts, 3, '3e tentative');
eq(result(s.rid).ai_review, true, 'au plafond : relecture humaine');
eq(result(s.rid).scoring_status, 'ai_pending', 'toujours en attente (jamais un faux ai_scored)');

// ─── 11. Item hors banque / langue indécidable / sous-test inconnu ──────────
console.log('11. résolution');
reset();
s = addSession({ responses: ['a', 'b'], itemIds: ['Table/Chaise', 'Inconnu/Item'] });
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'item_hors_banque', 'item inconnu : différée avant tout appel');
eq(calls.api.length, 0, 'aucun appel dépensé');
reset();
s = addSession({ responses: ['a'], itemIds: ['Orange/Banane'] }); // existe en fr ET en de
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'langue_indecidable', 'item présent dans deux banques, seul : différée');
reset();
s = addSession({ responses: ['a', 'b'], itemIds: ['Orange/Banane', 'Table/Chaise'] });
apiScript = [out(2), out(2)];
r = await scoreRow(env, result(s.rid));
ok(r.ok && r.lang === 'fr', 'le second item départage : fr');
reset();
s = addSession({ subtest: 'matrix', responses: ['a'], itemIds: ['x'] });
r = await scoreRow(env, result(s.rid));
ok(!r.ok && r.code === 'subtest_inconnu', 'sous-test non verbal refusé');

// ─── 12. Une langue par session, 6 langues ───────────────────────────────────
console.log('12. langues');
for (const [subtest, code, lang] of [['similarities', 'SI', 'en'], ['vocabulary', 'VO', 'es'], ['vocabulary', 'VO', 'pt'], ['similarities', 'SI', 'de'], ['vocabulary', 'VO', 'en_gb']]) {
  reset();
  s = addSession({ subtest, lang, responses: ['a', 'b', 'c'] });
  apiScript = [out(2), out(2), out(2)];
  r = await scoreRow(env, result(s.rid));
  ok(r.ok && r.lang === lang, `${subtest}/${lang} : langue ${lang} déduite`);
  ok(apiInputs.every((x) => x.lang === lang && x.subtest === subtest), `${subtest}/${lang} : entrée cohérente`);
}

// ─── 13. runBatch : filtre, lot partiel, idempotence ────────────────────────
console.log('13. lot');
reset();
const a = addSession({ responses: ['a'] });
const b = addSession({ responses: ['b'], status: 'ai_scored' });      // déjà notée : ignorée
const c = addSession({ responses: ['c'], complete: false });          // interrompue : ignorée
const d = addSession({ responses: ['d'], attempts: 3 });              // plafond : ignorée
const e = addSession({ subtest: 'matrix', responses: ['e'], itemIds: ['x'] }); // non verbal : ignorée par la requête
const f = addSession({ responses: ['f'] });
apiScript = [out(2), out(1)];
let sum = await runBatch(env, { limit: 40 });
eq(sum.rows, 2, 'seules les lignes éligibles sont lues');
eq(sum.scored, 2, 'deux notées');
eq([result(a.rid).scoring_status, result(f.rid).scoring_status], ['ai_scored', 'ai_scored'], 'a et f notées');
eq([result(b.rid).raw_score, result(c.rid).raw_score, result(d.rid).raw_score, result(e.rid).raw_score], [null, null, null, null], 'les autres intactes');
const before = JSON.stringify(db);
sum = await runBatch(env, { limit: 40 });
eq(sum.rows, 0, 'rejeu : plus rien à noter');
eq(JSON.stringify(db), before, 'rejeu : base inchangée (idempotence)');
reset();
for (let i = 0; i < 5; i++) addSession({ responses: ['x'] });
apiScript = Array(5).fill(out(2));
sum = await runBatch(env, { limit: 2 });
eq(sum.rows, 2, 'limit respectée (lot partiel)');
eq(db.test_results.filter((r) => r.scoring_status === 'ai_scored').length, 2, '2 notées, 3 en attente');
sum = await runBatch(env, { limit: 10 });
eq(sum.scored, 3, 'le passage suivant finit le reste');
reset();
s = addSession({ responses: ['a', 'b'] });
apiScript = [out(2), out(1)];
db.__failPatch = true; // l'écriture du résultat échoue après les items
let threw = false;
try { await scoreRow(env, result(s.rid)); } catch { threw = true; }
ok(threw, 'échec de la bascule d’état : erreur remontée');
eq(result(s.rid).scoring_status, 'ai_pending', 'ligne toujours en attente');
apiScript = [out(2), out(1)];
r = await scoreRow(env, result(s.rid));
ok(r.ok && result(s.rid).raw_score === 3, 'rejeu : mêmes scores, ligne notée');

// ─── 14. HTTP : auth admin, santé, 404, secrets manquants ───────────────────
console.log('14. HTTP');
const req = (path, init) => worker.fetch(new Request(`https://w.test${path}`, init), env, { waitUntil() {} });
let res = await req('/run', { method: 'POST' });
eq(res.status, 401, 'POST /run sans secret → 401');
res = await req('/run', { method: 'POST', headers: { 'X-Admin-Secret': 'faux' } });
eq(res.status, 401, 'mauvais secret → 401');
res = await req('/run', { method: 'POST', headers: { 'X-Admin-Secret': 'secret-admi' } });
eq(res.status, 401, 'secret tronqué → 401');
reset(); addSession({ responses: ['a'] }); apiScript = [out(2)];
res = await req('/run?limit=5', { method: 'POST', headers: { 'X-Admin-Secret': 'secret-admin' } });
eq(res.status, 200, 'bon secret → 200');
eq((await res.json()).scored, 1, 'résumé renvoyé');
res = await req('/health');
eq(res.status, 200, 'santé');
ok((await res.json()).format === 'points', 'format d’entrée exposé');
res = await req('/autre');
eq(res.status, 404, 'route inconnue');
res = await req('/run', { method: 'POST', headers: { 'X-Admin-Secret': 'secret-admin' } });
ok(res.status === 200, 'run sans lot ok');
sum = await runBatch({ ...env, ANTHROPIC_API_KEY: '' }, { limit: 1 });
ok(!sum.ok && /ANTHROPIC_API_KEY/.test(sum.error), 'secret manquant signalé, rien tenté');
// cron
reset(); addSession({ responses: ['a'] }); apiScript = [out(2)];
const logs = [];
const origLog = console.log; console.log = (m) => logs.push(String(m));
let waited;
await worker.scheduled({}, env, { waitUntil(p) { waited = p; } });
await waited;
console.log = origLog;
ok(db.test_results[0].scoring_status === 'ai_scored', 'cron note la session');
ok(logs.some((l) => l.includes('correcteur.cron')), 'cron journalisé');
ok(!logs.some((l) => /"response"|Fruit/.test(l)), 'aucune réponse de personne dans le journal');

// ─── Bilan ───────────────────────────────────────────────────────────────────
console.log(`\n${passed} assertions passées, ${failed} échouées`);
process.exit(failed ? 1 : 0);
