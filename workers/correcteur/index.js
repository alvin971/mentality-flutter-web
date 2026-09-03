/**
 * Worker « correcteur » — note en aval les sous-tests verbaux (Similitudes,
 * Vocabulaire) que l'app n'évalue plus elle-même depuis le 2026-08-24.
 *
 * Pourquoi ce worker existe : l'ancien comparateur de chaînes de l'app notait 0
 * des réponses justes (« Fruit » contre « Des fruits »), déclenchait la règle
 * d'arrêt et effondrait l'indice verbal. Décision du fondateur : l'algorithme
 * ne juge plus ; l'app enregistre les réponses brutes (test_items.response,
 * test_results.scoring_status = 'ai_pending') et un modèle note après coup.
 *
 * Le prompt embarqué (prompt.js) est la version FINALE éprouvée par le banc
 * d'essai tools/correction_lab/ (≈ 8 000 cas, 6 langues, holdout, déterminisme,
 * stabilité) — voir JOURNAL.md. Les banques d'items (banks.json) sont celles
 * de l'app, exportées telles quelles : le prompt a été validé sur CES exemples.
 *
 * Cycle : cron toutes les 10 min ou POST /run (secret d'admin) →
 *   1. test_results où scoring_status = 'ai_pending', sous-test verbal, terminé,
 *      ai_attempts < MAX_ATTEMPTS (lot de BATCH_ROWS lignes) ;
 *   2. test_items de la ligne, triés par item_index ;
 *   3. langue de la session déduite par vote des item_id sur les 6 banques
 *      (la base ne stocke pas la langue ; les identifiants sont propres à
 *      chaque langue à 98 %, un vote sur 20–30 items est sans ambiguïté) ;
 *   4. un appel modèle PAR RÉPONSE (Haiku 4.5, température 0, sortie JSON
 *      structurée) — sauf réponse vide ou item sauté : 0 sans appel ;
 *   5. RÈGLE D'ARRÊT POST-HOC : l'app ne peut plus l'appliquer puisqu'elle ne
 *      note plus ; on la rejoue ici dans l'ordre d'administration — après trois
 *      0 consécutifs, tous les items suivants valent 0, sans appel modèle,
 *      même si la réponse aurait été juste. C'est le barème d'origine ;
 *   6. écriture : test_items.score + ai_confidence (un seul upsert), puis
 *      test_results.raw_score / max_score / scoring_status = 'ai_scored' /
 *      ai_review / ai_scored_at.
 *
 * Fail-soft PAR LIGNE : toute erreur (API, JSON non conforme, item absent de
 * la banque, langue indécidable) laisse la ligne en 'ai_pending', incrémente
 * ai_attempts, et n'écrit AUCUN score — jamais un demi-score. À MAX_ATTEMPTS la
 * ligne passe ai_review = true (un humain regarde depuis mentality-admin).
 *
 * Idempotent : une ligne 'ai_scored' n'est jamais reprise par la requête ; un
 * même lot rejoué sur une ligne encore 'ai_pending' réécrit les mêmes valeurs.
 *
 * Journal : aucune donnée personnelle — jamais une réponse, jamais un compte.
 * Seulement des identifiants opaques (uuid de session), des comptes et des codes.
 */
import banks from './banks.json' with { type: 'json' };
import { PROMPT, INPUT_FORMAT, PROMPT_SOURCE } from './prompt.js';

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';
const SUBTESTS = { similarities: 'SI', vocabulary: 'VO' };
const LANGS = ['fr', 'en', 'en_gb', 'es', 'pt', 'de'];

const SCHEMA = {
  type: 'object', additionalProperties: false, required: ['score', 'confidence', 'reason'],
  properties: {
    score: { type: 'integer', enum: [0, 1, 2] },
    confidence: { type: 'number' },
    reason: { type: 'string' },
  },
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true, prompt: PROMPT_SOURCE, format: INPUT_FORMAT, model: modelOf(env) }, 200);
    }
    if (request.method === 'POST' && url.pathname === '/run') {
      if (!(await adminAuthorized(request, env))) return json({ error: 'non autorisé' }, 401);
      const limit = clampInt(url.searchParams.get('limit'), 1, 200, batchRows(env));
      const summary = await runBatch(env, { limit });
      return json(summary, 200);
    }
    return json({ error: 'introuvable' }, 404);
  },

  async scheduled(event, env, ctx) {
    ctx.waitUntil(runBatch(env, { limit: batchRows(env) }).then((s) => {
      console.log(JSON.stringify({ evt: 'correcteur.cron', ...s }));
    }));
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Lot
// ─────────────────────────────────────────────────────────────────────────────

/** Traite jusqu'à `limit` lignes test_results en attente. Retourne un résumé sans PII. */
export async function runBatch(env, { limit }) {
  const missing = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'ANTHROPIC_API_KEY'].filter((k) => !env[k]);
  if (missing.length) return { ok: false, error: `secrets manquants : ${missing.join(', ')}` };

  const rows = await sbGet(env, 'test_results',
    `scoring_status=eq.ai_pending&subtest=in.(similarities,vocabulary)&is_complete=eq.true` +
    `&ai_attempts=lt.${maxAttempts(env)}&select=id,session_id,subtest,ai_attempts&order=created_at.asc&limit=${limit}`);

  const summary = { ok: true, rows: rows.length, scored: 0, deferred: 0, review: 0, calls: 0, codes: {} };
  for (const row of rows) {
    const r = await scoreRow(env, row);
    summary.calls += r.calls ?? 0;
    if (r.ok) { summary.scored++; if (r.review) summary.review++; }
    else { summary.deferred++; summary.codes[r.code] = (summary.codes[r.code] ?? 0) + 1; }
    console.log(JSON.stringify({ evt: 'correcteur.row', session: row.session_id, subtest: row.subtest, ...r }));
  }
  return summary;
}

/**
 * Note UNE ligne (session × sous-test). Retourne { ok, code?, review?, calls, raw? }.
 * N'écrit rien tant que tous les items ne sont pas notés (pas de demi-score).
 */
export async function scoreRow(env, row) {
  const code = SUBTESTS[row.subtest];
  if (!code) return await defer(env, row, 'subtest_inconnu');

  const items = await sbGet(env, 'test_items',
    `session_id=eq.${enc(row.session_id)}&subtest=eq.${enc(row.subtest)}` +
    `&select=id,item_index,item_id,response,skipped&order=item_index.asc`);
  if (!items.length) return await defer(env, row, 'aucun_item');

  const lang = inferLanguage(code, items);
  if (!lang) return await defer(env, row, 'langue_indecidable');
  const bank = banks[code][lang];

  // Résolution de tous les items AVANT le premier appel : un item absent de la
  // banque rend la ligne innotable, inutile de dépenser des appels.
  const resolved = [];
  for (const it of items) {
    const entry = it.item_id != null ? bank[it.item_id] : undefined;
    if (!entry) return await defer(env, row, 'item_hors_banque');
    resolved.push({ it, entry });
  }

  const scored = [];
  let zeros = 0, stopped = false, calls = 0, minConf = 1;
  for (const { it, entry } of resolved) {
    let s;
    if (stopped) {
      // Règle d'arrêt post-hoc : au-delà de trois 0 consécutifs, 0 d'office.
      s = { score: 0, confidence: 1, rule: 'stop' };
    } else if (it.skipped || !String(it.response ?? '').trim()) {
      s = { score: 0, confidence: 1, rule: 'empty' };
    } else {
      calls++;
      let out;
      try {
        out = await callModel(env, buildInput(row.subtest, lang, entry, it.response));
      } catch (e) {
        return await defer(env, row, `api_${classifyError(e)}`, { calls });
      }
      const v = validate(out);
      if (!v.valid) return await defer(env, row, 'json_invalide', { calls });
      s = { score: v.parsed.score, confidence: v.parsed.confidence, rule: 'model' };
    }
    scored.push({ it, ...s });
    if (s.score === 0) { zeros++; if (zeros >= 3) stopped = true; } else zeros = 0;
    if (s.rule === 'model') minConf = Math.min(minConf, s.confidence);
  }

  const raw = scored.reduce((a, s) => a + s.score, 0);
  const max = scored.length * 2;
  const review = minConf < reviewThreshold(env);

  // 1) items — un seul upsert, colonnes fournies uniquement (score, ai_confidence).
  await sbUpsert(env, 'test_items', 'session_id,subtest,item_index', scored.map((s) => ({
    session_id: row.session_id, subtest: row.subtest, item_index: s.it.item_index,
    score: s.score, ai_confidence: s.rule === 'model' ? round3(s.confidence) : null,
  })));
  // 2) résultat — bascule d'état en dernier : si elle échoue, la ligne reste en
  //    attente et le prochain passage réécrit les mêmes scores (idempotent).
  await sbPatch(env, 'test_results', `id=eq.${enc(row.id)}`, {
    raw_score: raw, max_score: max, scoring_status: 'ai_scored',
    ai_review: review, ai_scored_at: new Date().toISOString(),
  });
  return { ok: true, review, calls, raw, max, stopped, lang };
}

/** Laisse la ligne en attente, compte la tentative, signale à la relecture si épuisée. */
async function defer(env, row, code, extra = {}) {
  const attempts = (row.ai_attempts ?? 0) + 1;
  const patch = { ai_attempts: attempts };
  if (attempts >= maxAttempts(env)) patch.ai_review = true;
  try { await sbPatch(env, 'test_results', `id=eq.${enc(row.id)}`, patch); }
  catch (e) { return { ok: false, code, attempts, patch_failed: true, ...extra }; }
  return { ok: false, code, attempts, ...extra };
}

// ─────────────────────────────────────────────────────────────────────────────
// Langue, entrée du modèle, validation
// ─────────────────────────────────────────────────────────────────────────────

/** Vote des item_id sur les banques du sous-test ; null si aucun vote ou égalité en tête. */
export function inferLanguage(code, items) {
  const votes = Object.fromEntries(LANGS.map((l) => [l, 0]));
  for (const it of items) {
    if (it.item_id == null) continue;
    for (const l of LANGS) if (banks[code][l]?.[it.item_id]) votes[l]++;
  }
  const ranked = LANGS.map((l) => [l, votes[l]]).sort((a, b) => b[1] - a[1]);
  if (ranked[0][1] === 0 || ranked[0][1] === ranked[1][1]) return null;
  return ranked[0][0];
}

/** Même forme que tools/correction_lab/lib.userInput, format dicté par le prompt. */
export function buildInput(subtest, lang, entry, response) {
  const base = { subtest, lang, stimulus: entry.s };
  return INPUT_FORMAT === 'credit'
    ? { ...base, full_credit_examples: entry.two, partial_credit_examples: entry.one, answer: response }
    : { ...base, examples_2_points: entry.two, examples_1_point: entry.one, answer: response };
}

/** Contrat strict, identique au banc d'essai : rien n'est réparé. */
export function validate(text) {
  let p;
  try { p = JSON.parse(text); } catch { return { valid: false, why: 'JSON non parsable' }; }
  if (!p || typeof p !== 'object' || Array.isArray(p)) return { valid: false, why: 'pas un objet' };
  if (![0, 1, 2].includes(p.score)) return { valid: false, why: 'score hors {0,1,2}' };
  if (typeof p.confidence !== 'number' || !(p.confidence >= 0 && p.confidence <= 1)) return { valid: false, why: 'confidence hors [0,1]' };
  if (typeof p.reason !== 'string' || !p.reason.trim()) return { valid: false, why: 'reason vide' };
  return { valid: true, parsed: p };
}

// ─────────────────────────────────────────────────────────────────────────────
// Anthropic — appel brut, même forme que run.mjs (température 0, JSON structuré)
// ─────────────────────────────────────────────────────────────────────────────

async function callModel(env, input) {
  const body = {
    model: modelOf(env), max_tokens: 200, temperature: 0,
    system: [{ type: 'text', text: PROMPT, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: JSON.stringify(input) }],
    output_config: { format: { type: 'json_schema', schema: SCHEMA } },
  };
  for (let attempt = 0; ; attempt++) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 30_000);
    let res;
    try {
      res = await fetch(ANTHROPIC_API_URL, {
        method: 'POST', signal: ctrl.signal,
        headers: { 'content-type': 'application/json', 'x-api-key': env.ANTHROPIC_API_KEY, 'anthropic-version': ANTHROPIC_VERSION },
        body: JSON.stringify(body),
      });
    } catch (e) {
      clearTimeout(timer);
      if (attempt >= 2) throw Object.assign(new Error('réseau'), { kind: 'network' });
      await sleep(500 * 2 ** attempt); continue;
    }
    clearTimeout(timer);
    if (res.status === 429 || res.status >= 500) {
      if (attempt >= 2) throw Object.assign(new Error(`HTTP ${res.status}`), { kind: 'http' + res.status });
      await sleep(500 * 2 ** attempt); continue;
    }
    const data = await res.json();
    if (!res.ok) throw Object.assign(new Error(`HTTP ${res.status}`), { kind: 'http' + res.status });
    if (data.stop_reason === 'refusal') throw Object.assign(new Error('refus'), { kind: 'refusal' });
    return (data.content ?? []).filter((b) => b.type === 'text').map((b) => b.text).join('');
  }
}

function classifyError(e) { return e?.kind ?? 'erreur'; }

// ─────────────────────────────────────────────────────────────────────────────
// Supabase REST (service key) — patron de workers/referral
// ─────────────────────────────────────────────────────────────────────────────

function sbHeaders(env) {
  return {
    apikey: env.SUPABASE_SERVICE_KEY,
    Authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
  };
}
async function sbGet(env, table, query) {
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}`, { headers: sbHeaders(env) });
  if (!res.ok) throw Object.assign(new Error(`supabase GET ${table} ${res.status}`), { kind: 'supabase' });
  return await res.json();
}
async function sbUpsert(env, table, onConflict, rows) {
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?on_conflict=${onConflict}`, {
    method: 'POST',
    headers: { ...sbHeaders(env), Prefer: 'resolution=merge-duplicates,return=minimal' },
    body: JSON.stringify(rows),
  });
  if (!res.ok) throw Object.assign(new Error(`supabase UPSERT ${table} ${res.status}`), { kind: 'supabase' });
}
async function sbPatch(env, table, query, patch) {
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'PATCH', headers: { ...sbHeaders(env), Prefer: 'return=minimal' }, body: JSON.stringify(patch),
  });
  if (!res.ok) throw Object.assign(new Error(`supabase PATCH ${table} ${res.status}`), { kind: 'supabase' });
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilitaires
// ─────────────────────────────────────────────────────────────────────────────

async function adminAuthorized(request, env) {
  const given = request.headers.get('X-Admin-Secret') || '';
  const expected = env.ADMIN_SECRET || '';
  if (!expected || given.length !== expected.length) return false;
  // Comparaison à temps constant.
  const a = new TextEncoder().encode(given), b = new TextEncoder().encode(expected);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}
const enc = (s) => encodeURIComponent(String(s));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const round3 = (x) => Math.round(x * 1000) / 1000;
function clampInt(v, min, max, def) { const n = parseInt(v ?? '', 10); return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : def; }
function batchRows(env) { return clampInt(env.BATCH_ROWS, 1, 200, 40); }
function maxAttempts(env) { return clampInt(env.MAX_ATTEMPTS, 1, 20, 5); }
function reviewThreshold(env) { const x = parseFloat(env.REVIEW_THRESHOLD ?? ''); return Number.isFinite(x) ? x : 0.6; }
function modelOf(env) { return env.MODEL || 'claude-haiku-4-5-20251001'; }
function json(obj, status) {
  return new Response(JSON.stringify(obj), { status, headers: { 'Content-Type': 'application/json' } });
}
