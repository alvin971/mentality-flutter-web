#!/usr/bin/env node
/**
 * Auto-test du worker tokeniser : émission signée Ed25519, plafond d'émission
 * agrégé (LOT 0 anti-faux-test), politique d'Origin, exigence de signature
 * sur /validate.
 *
 *   node workers/tokeniser/scripts/selftest.mjs
 *
 * Aucune dépendance, aucun réseau, aucun compte Cloudflare : le worker est
 * importé tel quel, branché sur un KV en mémoire, et signe avec un couple de
 * clés FORGÉ ICI — la clé privée de test part dans env.ED25519_PRIVATE_KEY_B64
 * (base64 du DER PKCS#8, comme le vrai secret), la clé publique écrase le kid
 * `k1` de la map partagée TOKEN_SIGNING_PUBLIC_KEYS (propriétés mutables,
 * même procédé que workers/event/scripts/selftest.mjs). La vérification
 * exercée est donc la VRAIE chaîne signature → vérification de production.
 *
 * À lancer avant chaque `wrangler deploy`.
 */

import { readFileSync } from 'node:fs';

import worker from '../index.js';
import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../../_shared/token_verify.js';

const b64u = (bytes) => Buffer.from(bytes).toString('base64url');
const segment = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');

// ─── Couple de clés de test : privée → env, publique → kid 'k1' (celui que
//     signPayload met en dur dans l'en-tête des tokens émis). ─────────────────
const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
const PRIV_B64 = Buffer.from(await crypto.subtle.exportKey('pkcs8', kp.privateKey))
  .toString('base64');
TOKEN_SIGNING_PUBLIC_KEYS.k1 =
  b64u(new Uint8Array(await crypto.subtle.exportKey('raw', kp.publicKey)));

const CLAIMS = { s: 'M', y: 1990, m: 5, r: 'IDF' };
const FENETRE_MIN = 60;
const MAX_FENETRE = 300;

// Version des textes légaux utilisée par les scénarios de plan (miroir de la
// var wrangler LEGAL_VERSIONS).
const CV = '2026-09-02.v1';

/** Payload JWS décodé sans vérification (assertions de FORME du token). */
const payloadDe = (token) =>
  JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8'));

/** Clés `consent:` écrites dans un KV en mémoire. */
const clesConsent = (store) => [...store._m.keys()].filter((k) => k.startsWith('consent:'));

/**
 * Année de naissance donnant exactement [age] ans aujourd'hui avec le MOIS
 * COURANT comme mois de naissance (mois en cours non révolu, formule §3 du
 * plan : age = Y − y − (m ≥ M ? 1 : 0)). Indépendant de la date du run.
 */
function naissancePourAge(age) {
  const now = new Date();
  return { y: now.getUTCFullYear() - age - 1, m: now.getUTCMonth() + 1 };
}

/** KV en mémoire qui ENREGISTRE les options de put (assertion du TTL). */
function kv(seed = {}) {
  const m = new Map(Object.entries(seed));
  const options = new Map();
  return {
    _m: m,
    _options: options,
    get: async (k) => (m.has(k) ? m.get(k) : null),
    put: async (k, v, opts) => { m.set(k, v); options.set(k, opts); },
  };
}

/**
 * Les deux tranches candidates au moment du test : la courante et la suivante.
 * Seeder LES DEUX rend les scénarios de plafond insensibles à un changement
 * d'heure pendant le run (même précaution que les ancres du selftest referral).
 */
function tranches() {
  const b = Math.floor(Date.now() / (FENETRE_MIN * 60000));
  return [`issue:${b}`, `issue:${b + 1}`];
}
const seedPlein = () => Object.fromEntries(tranches().map((k) => [k, String(MAX_FENETRE)]));
const compteur = (store) =>
  tranches().map((k) => store._m.get(k)).find((v) => v !== undefined) ?? null;

function env(store, extra = {}) {
  return {
    ED25519_PRIVATE_KEY_B64: PRIV_B64,
    ISSUE_WINDOW_MINUTES: String(FENETRE_MIN),
    ISSUE_MAX_PER_WINDOW: String(MAX_FENETRE),
    ...(store ? { RATE_KV: store } : {}),
    ...extra,
  };
}

/**
 * Env des scénarios de plan : LEGAL_VERSIONS configurée, interrupteur payant
 * FERMÉ (l'état de production d'aujourd'hui). Les scénarios « jour de Stripe »
 * passent { PAID_PLAN_ENABLED: 'true' } en extra.
 */
function envPlan(store, extra = {}) {
  return env(store, { LEGAL_VERSIONS: CV, PAID_PLAN_ENABLED: 'false', ...extra });
}

/**
 * Env dont le PLAFOND est explicitement ALLUMÉ.
 *
 * Depuis 2026-09-02, lier RATE_KV ne suffit plus à refuser au-delà du seuil :
 * il faut ISSUE_CAP_ENABLED === 'true' (deux gestes séparés, cf. le
 * doc-comment de checkIssueCap). Tous les scénarios qui exercent le REFUS
 * passent donc par ici — ils testent exactement ce qu'ils testaient avant, en
 * nommant désormais l'état dans lequel ce refus a lieu. L'état LIVRÉ, lui
 * (plafond éteint), a sa propre section plus bas.
 */
function envCap(store, extra = {}) {
  return env(store, { ISSUE_CAP_ENABLED: 'true', ...extra });
}

async function appel(environnement, path = '/', method = 'POST', body = CLAIMS, opts = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (opts.origin) headers['Origin'] = opts.origin;
  const resp = await worker.fetch(new Request(`https://selftest${path}`, {
    method,
    headers,
    body: method === 'GET' ? undefined : JSON.stringify(body),
  }), environnement);
  return { statut: resp.status, corps: await resp.json() };
}

let ok = 0;
const echecs = [];
function verifie(nom, condition, detail = '') {
  if (condition) { ok++; console.log(`  ✓ ${nom}`); }
  else { echecs.push(nom); console.log(`  ✗ ${nom}  ${detail}`); }
}

console.log('\n─── Tokeniser — workers/tokeniser/index.js ───\n');

console.log('Émission signée (POST /)');
{
  const s = kv();
  const { statut, corps } = await appel(env(s));
  const v = corps.token ? await verifyToken(corps.token, TOKEN_SIGNING_PUBLIC_KEYS) : { valid: false };
  verifie('claims valides → 200 et JWS à 3 segments', statut === 200 &&
    typeof corps.token === 'string' && corps.token.split('.').length === 3, `HTTP ${statut}`);
  verifie('le token émis passe la VRAIE vérification de signature', v.valid === true,
    JSON.stringify(v));
  verifie('nonce base64url présent, claims resignées serveur (d, sv=2)',
    v.valid && /^[A-Za-z0-9\-_]+$/.test(v.claims.n) && v.claims.sv === 2 &&
    Number.isInteger(v.claims.d) && v.claims.s === 'M' && v.claims.y === 1990);
  verifie('une émission = compteur à 1 en KV', compteur(s) === '1', String(compteur(s)));
  const ttl = [...s._options.values()][0];
  verifie('TTL posé ≥ 2 fenêtres', !!ttl && ttl.expirationTtl >= 2 * FENETRE_MIN * 60,
    JSON.stringify(ttl));
}

console.log("\nPlafond d'émission (compteur agrégé)");
{
  const s = kv(seedPlein());
  const { statut, corps } = await appel(envCap(s));
  verifie('compteur plein → 429, aucun token', statut === 429 && !('token' in corps),
    `HTTP ${statut}`);
}
{
  const presque = Object.fromEntries(tranches().map((k) => [k, String(MAX_FENETRE - 1)]));
  const s = kv(presque);
  const un = await appel(envCap(s));
  const deux = await appel(envCap(s));
  verifie('max−1 → 200 (dernière place), puis 429 (off-by-one exclu)',
    un.statut === 200 && deux.statut === 429, `${un.statut} puis ${deux.statut}`);
}
{
  const { statut } = await appel(envCap(null)); // pas de RATE_KV, plafond pourtant allumé
  verifie('binding RATE_KV absent → FAIL-OPEN (200), l\'inscription n\'est jamais murée',
    statut === 200, `HTTP ${statut}`);
}
{
  // FAIL-OPEN aussi quand KV JETTE : panne, ou limite Cloudflare « 1 écriture
  // par seconde et par clé » dépassée en rafale (toutes les émissions d'une
  // fenêtre écrivent la MÊME clé). Le worker n'a pas de try/catch global :
  // sans le filet de checkIssueCap, un pic d'inscriptions deviendrait un 500.
  const casseGet = {
    get: async () => { throw new Error('KV get down'); },
    put: async () => {},
  };
  const cassePut = {
    get: async () => null,
    put: async () => { throw new Error('KV put rate-limited'); },
  };
  const surGet = await appel(envCap(casseGet));
  const surPut = await appel(envCap(cassePut));
  verifie('KV en panne (get ou put qui jette) → FAIL-OPEN (200), jamais 500',
    surGet.statut === 200 && surPut.statut === 200,
    `get=${surGet.statut}, put=${surPut.statut}`);
}
{
  const b = Math.floor(Date.now() / (FENETRE_MIN * 60000));
  const s = kv({ [`issue:${b - 1}`]: String(MAX_FENETRE) }); // tranche PASSÉE pleine
  const { statut } = await appel(envCap(s));
  verifie('tranche passée pleine → 200 (la fenêtre glisse, pas de plafond global)',
    statut === 200, `HTTP ${statut}`);
}
{
  const s = kv();
  const { statut } = await appel(envCap(s), '/', 'POST', { ...CLAIMS, s: 'Z' });
  verifie('claims invalides → 400 SANS consommer le budget',
    statut === 400 && compteur(s) === null, `HTTP ${statut}, compteur ${compteur(s)}`);
}
{
  // /validate n'est jamais plafonné : au plafond, il répond selon SA logique
  // (ici 500 « Bucket R2 non lié », le binding AUDIO_BUCKET étant désactivé).
  const s = kv(seedPlein());
  const jeton = (await appel(env(kv()))).corps.token;
  const { statut, corps } = await appel(envCap(s), '/validate', 'POST', { token: jeton });
  verifie('/validate au plafond → jamais 429 (500 bucket R2 non lié)',
    statut === 500 && String(corps.error).includes('R2'), `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const s = kv(seedPlein());
  const { statut } = await appel(envCap(s), '/geo', 'GET');
  verifie('GET /geo au plafond → 200, compteur inchangé',
    statut === 200 && compteur(s) === String(MAX_FENETRE), `HTTP ${statut}`);
}

console.log('\nExigence de signature sur /validate');
{
  const devToken = 'M2.' + segment({ n: 'selftest', sv: 2 });
  const { statut } = await appel(env(kv()), '/validate', 'POST', { token: devToken });
  verifie('token DEV non signé (M2.) → 401 (le tokeniser n\'a pas le repli du referral)',
    statut === 401, `HTTP ${statut}`);
}

console.log("\nPolitique d'Origin");
{
  const { statut } = await appel(env(kv()), '/', 'POST', CLAIMS,
    { origin: 'https://evil.example' });
  verifie('Origin non listée → 403', statut === 403, `HTTP ${statut}`);
}
{
  const avec = await appel(env(kv()), '/', 'POST', CLAIMS,
    { origin: 'https://mentality-flutter-web.pages.dev' });
  const sans = await appel(env(kv()));
  verifie('Origin listée → 200 ; Origin absente (app native) → 200',
    avec.statut === 200 && sans.statut === 200, `${avec.statut} / ${sans.statut}`);
}
{
  // PARITÉ AVEC LA PRODUCTION — le dépôt a déjà été en retard sur le worker
  // déployé une fois (cf. commentaire d'ALLOWED_ORIGINS) : retirer l'une de
  // ces origines éteindrait l'inscription en production au prochain deploy.
  const domaines = ['https://mental-et.com', 'https://www.mental-et.com'];
  const statuts = [];
  for (const d of domaines) {
    statuts.push((await appel(env(kv()), '/', 'POST', CLAIMS, { origin: d })).statut);
  }
  verifie("les domaines de la page d'inscription en PRODUCTION émettent (200)",
    statuts.every((s) => s === 200), `${domaines.join(', ')} → ${statuts.join(', ')}`);
}

console.log('\nÉmission sv 3 (plan Gratuit / Payant)');
{
  // ⚠️ INVARIANT DE PRODUCTION — le corps historique {s,y,m,r} doit continuer
  // à produire EXACTEMENT le même token sv 2 qu'aujourd'hui : mêmes clés, même
  // ordre, aucune claim de plan. C'est ce qui garde l'inscription live de
  // mental-et.com en vie pendant toute la transition vers sv 3.
  const { statut, corps } = await appel(envPlan(kv()));
  const p = corps.token ? payloadDe(corps.token) : {};
  verifie('corps sans `p` → payload sv 2 EXACT (s,y,m,r,d,n,sv), aucun p/cc/cv',
    statut === 200 && Object.keys(p).join(',') === 's,y,m,r,d,n,sv' && p.sv === 2 &&
    p.s === 'M' && p.y === 1990 && p.m === 5 && p.r === 'IDF',
    `HTTP ${statut} ${JSON.stringify(Object.keys(p))}`);
}
{
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST', { ...CLAIMS, cc: true, cv: CV });
  verifie('cc/cv sans `p` → 400 PLAN_REQUIRED (on ne devine jamais le plan)',
    statut === 400 && corps.code === 'PLAN_REQUIRED', `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: CV });
  const v = corps.token ? await verifyToken(corps.token, TOKEN_SIGNING_PUBLIC_KEYS) : { valid: false };
  verifie('free + cc:true → 200 sv 3 signé, qui passe la VRAIE verifyToken',
    statut === 200 && v.valid === true && v.claims.sv === 3 && v.claims.p === 'free' &&
    v.claims.cc === true && v.claims.cv === CV,
    `HTTP ${statut} ${JSON.stringify(v.claims || corps)}`);
}
{
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: false, cv: CV });
  const p = corps.token ? payloadDe(corps.token) : {};
  verifie('free + cc:false, Payant fermé, CORPUS_CONSENT_REQUIRED absente → 200 sv 3 (comportement antérieur conservé)',
    statut === 200 && p.sv === 3 && p.cc === false, `HTTP ${statut} ${JSON.stringify(corps)}`);
}

console.log('\nInterrupteur CORPUS_CONSENT_REQUIRED = "true" (Payant fermé) — décision produit 2026-09-02');
{
  // Le site exige la case pour tout passe Gratuit, indépendamment du Payant :
  // le serveur doit pouvoir dire la même chose SANS ouvrir la vente.
  const e = (s) => envPlan(s, { PAID_PLAN_ENABLED: 'false', CORPUS_CONSENT_REQUIRED: 'true' });
  const sans = await appel(e(kv()), '/', 'POST', { ...CLAIMS, p: 'free', cc: false, cv: CV });
  verifie('CORPUS_CONSENT_REQUIRED="true", Payant fermé, free + cc:false → 400 CONSENT_REQUIRED',
    sans.statut === 400 && sans.corps.code === 'CONSENT_REQUIRED' && !('token' in sans.corps),
    `HTTP ${sans.statut} ${JSON.stringify(sans.corps)}`);

  const avec = await appel(e(kv()), '/', 'POST', { ...CLAIMS, p: 'free', cc: true, cv: CV });
  const pa = avec.corps.token ? payloadDe(avec.corps.token) : {};
  verifie('CORPUS_CONSENT_REQUIRED="true", Payant fermé, free + cc:true → 200 sv 3',
    avec.statut === 200 && pa.sv === 3 && pa.p === 'free' && pa.cc === true,
    `HTTP ${avec.statut} ${JSON.stringify(avec.corps)}`);

  // L'exigence est un interrupteur EXPLICITE : var absente + Payant fermé →
  // comportement antérieur (facultatif), jamais un défaut implicite.
  const absente = await appel(envPlan(kv()), '/', 'POST', { ...CLAIMS, p: 'free', cc: false, cv: CV });
  const pb = absente.corps.token ? payloadDe(absente.corps.token) : {};
  verifie('CORPUS_CONSENT_REQUIRED absente, Payant fermé, free + cc:false → 200 (interrupteur explicite)',
    absente.statut === 200 && pb.sv === 3 && pb.cc === false,
    `HTTP ${absente.statut} ${JSON.stringify(absente.corps)}`);
}
{
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'paid', cc: false, cv: CV });
  verifie('paid, interrupteur fermé → 403 PAID_PLAN_DISABLED (code, pas juste le statut)',
    statut === 403 && corps.code === 'PAID_PLAN_DISABLED' && !('token' in corps),
    `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const { statut } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'gold', cc: false, cv: CV });
  verifie('p hors allow-list ("gold") → 400 (jamais de repli sur free)',
    statut === 400, `HTTP ${statut}`);
}
{
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: '0000-00-00.v0' });
  verifie('cv absente de LEGAL_VERSIONS → 400 LEGAL_VERSION_UNKNOWN',
    statut === 400 && corps.code === 'LEGAL_VERSION_UNKNOWN',
    `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  // Fail-closed : sans liste de versions, on ignore SUR QUOI la personne a
  // consenti → erreur serveur, jamais un passe signé au hasard.
  const { statut, corps } = await appel(env(kv()), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: CV });
  verifie('LEGAL_VERSIONS non configurée → 500 SERVER_MISCONFIGURED',
    statut === 500 && corps.code === 'SERVER_MISCONFIGURED',
    `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  // Défaut FERMÉ : une var oubliée ne doit pas ouvrir la vente.
  const { statut, corps } = await appel(env(kv(), { LEGAL_VERSIONS: CV }), '/', 'POST',
    { ...CLAIMS, p: 'paid', cc: false, cv: CV });
  verifie('PAID_PLAN_ENABLED absente → paid refusé (403, défaut fermé)',
    statut === 403 && corps.code === 'PAID_PLAN_DISABLED', `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const { statut, corps } = await appel(env(kv(), { LEGAL_VERSIONS: CV, PAID_PLAN_ENABLED: 'TRUE' }),
    '/', 'POST', { ...CLAIMS, p: 'paid', cc: false, cv: CV });
  verifie('PAID_PLAN_ENABLED = "TRUE" ≠ "true" → paid toujours refusé (403)',
    statut === 403 && corps.code === 'PAID_PLAN_DISABLED', `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const jeune = naissancePourAge(14);
  const { statut, corps } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, ...jeune, p: 'free', cc: true, cv: CV });
  verifie('14 ans (mois de naissance en cours) + cc:true → 400 AGE_CONSENT',
    statut === 400 && corps.code === 'AGE_CONSENT',
    `y=${jeune.y} m=${jeune.m} → HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const pile = naissancePourAge(15);
  const { statut } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, ...pile, p: 'free', cc: true, cv: CV });
  verifie('15 ans pile + cc:true → 200 (la borne n\'exclut pas les 15 ans)',
    statut === 200, `y=${pile.y} m=${pile.m} → HTTP ${statut}`);
}
{
  const jeune = naissancePourAge(14);
  const { statut } = await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, ...jeune, p: 'free', cc: false, cv: CV });
  verifie('14 ans SANS consentement corpus → 200 (le bilan reste accessible)',
    statut === 200, `HTTP ${statut}`);
}

console.log('\nInterrupteur PAID_PLAN_ENABLED = "true" (jour de Stripe)');
{
  const e = (s) => envPlan(s, { PAID_PLAN_ENABLED: 'true' });
  const libre = await appel(e(kv()), '/', 'POST', { ...CLAIMS, p: 'free', cc: false, cv: CV });
  verifie('free + cc:false → 400 CONSENT_REQUIRED (l\'alternative payante existe)',
    libre.statut === 400 && libre.corps.code === 'CONSENT_REQUIRED',
    `HTTP ${libre.statut} ${JSON.stringify(libre.corps)}`);

  const paye = await appel(e(kv()), '/', 'POST', { ...CLAIMS, p: 'paid', cc: false, cv: CV });
  const pp = paye.corps.token ? payloadDe(paye.corps.token) : {};
  verifie('paid + cc:false → 200 sv 3 avec p:"paid", cc:false',
    paye.statut === 200 && pp.sv === 3 && pp.p === 'paid' && pp.cc === false,
    `HTTP ${paye.statut} ${JSON.stringify(paye.corps)}`);

  const incoherent = await appel(e(kv()), '/', 'POST', { ...CLAIMS, p: 'paid', cc: true, cv: CV });
  verifie('paid + cc:true → 400 PLAN_INCONSISTENT (un passe payant ne consent pas)',
    incoherent.statut === 400 && incoherent.corps.code === 'PLAN_INCONSISTENT',
    `HTTP ${incoherent.statut} ${JSON.stringify(incoherent.corps)}`);
}

console.log('\nCompteur de consentement agrégé (preuve art. 7(1))');
{
  const s = kv();
  const { statut } = await appel(envPlan(s), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: CV });
  const cles = clesConsent(s);
  const attendu = new RegExp(`^consent:${CV}:free:true:\\d{4}-\\d{2}-\\d{2}:(1[0-5]|[0-9])$`);
  verifie('une émission avec plan → 1 seule clé consent:<cv>:<p>:<cc>:<jour>:<shard>',
    statut === 200 && cles.length === 1 && attendu.test(cles[0]), JSON.stringify(cles));
  verifie('la clé vaut "1" et n\'a AUCUN expirationTtl (une preuve ne s\'auto-détruit pas)',
    s._m.get(cles[0]) === '1' && s._options.get(cles[0]) === undefined,
    `${s._m.get(cles[0])} / ${JSON.stringify(s._options.get(cles[0]))}`);
}
{
  const s = kv();
  await appel(envPlan(s)); // corps historique, sans plan
  verifie('émission sv 2 → AUCUNE clé consent: (rien de nouveau n\'est écrit)',
    clesConsent(s).length === 0, JSON.stringify(clesConsent(s)));
}
{
  // FAIL-OPEN : le token est déjà signé quand le compteur s'écrit. Un KV en
  // panne ne doit jamais transformer une émission réussie en 500.
  const casse = {
    get: async (k) => { if (k.startsWith('consent:')) throw new Error('KV consent down'); return null; },
    put: async (k) => { if (k.startsWith('consent:')) throw new Error('KV consent down'); },
  };
  const { statut, corps } = await appel(envPlan(casse), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: CV });
  verifie('KV qui jette sur consent: → 200 quand même, token remis (FAIL-OPEN)',
    statut === 200 && typeof corps.token === 'string', `HTTP ${statut}`);
}
{
  const refuse = kv();
  await appel(envPlan(refuse), '/', 'POST', { ...CLAIMS, p: 'paid', cc: false, cv: CV }); // 403
  const invalide = kv();
  await appel(envPlan(invalide), '/', 'POST', { ...CLAIMS, p: 'free', cc: true, cv: 'x' }); // 400
  verifie('un refus (400/403) n\'écrit NI consent: NI issue: (pas de trace, pas de budget)',
    clesConsent(refuse).length === 0 && clesConsent(invalide).length === 0 &&
    refuse._m.size === 0 && invalide._m.size === 0,
    `${JSON.stringify([...refuse._m.keys()])} / ${JSON.stringify([...invalide._m.keys()])}`);
}

console.log('\n/validate accepte les tokens sv 3');
{
  const jeton = (await appel(envPlan(kv()), '/', 'POST',
    { ...CLAIMS, p: 'free', cc: true, cv: CV })).corps.token;
  const { statut, corps } = await appel(envPlan(kv()), '/validate', 'POST', { token: jeton });
  verifie('token sv 3 sur /validate → plus de 401 schema_version (500 bucket R2 non lié)',
    statut !== 401 && statut === 500 && String(corps.error).includes('R2'),
    `HTTP ${statut} ${JSON.stringify(corps)}`);
}

console.log("\nÉtat DÉPLOYÉ : ni RATE_KV ni AUDIO_BUCKET (les deux bindings sont commentés)");
{
  // C'est l'état RÉEL du worker en production : R2 est désactivé sur le compte
  // (erreur API 10042) et le namespace RATE_KV n'existe pas encore. Le worker
  // doit rester PLEINEMENT fonctionnel dedans, sinon le recommenter des
  // bindings — le geste qui le rend déployable — casserait l'inscription.
  const deploye = {
    ED25519_PRIVATE_KEY_B64: PRIV_B64,
    LEGAL_VERSIONS: CV,
    PAID_PLAN_ENABLED: 'false',
    CORPUS_CONSENT_REQUIRED: 'true', // miroir des [vars] livrées (wrangler.toml)
  };
  verifie('le scénario n\'expose AUCUN binding (garde-fou : ne pas en réintroduire un ici)',
    !('RATE_KV' in deploye) && !('AUDIO_BUCKET' in deploye), JSON.stringify(Object.keys(deploye)));

  const legacy = await appel(deploye);
  const pl = legacy.corps.token ? payloadDe(legacy.corps.token) : {};
  verifie('sans RATE_KV ni AUDIO_BUCKET → émission sv 2 OK (l\'inscription live tient)',
    legacy.statut === 200 && pl.sv === 2 && Object.keys(pl).join(',') === 's,y,m,r,d,n,sv',
    `HTTP ${legacy.statut} ${JSON.stringify(Object.keys(pl))}`);

  const sv3 = await appel(deploye, '/', 'POST', { ...CLAIMS, p: 'free', cc: true, cv: CV });
  const v3 = sv3.corps.token ? await verifyToken(sv3.corps.token, TOKEN_SIGNING_PUBLIC_KEYS)
    : { valid: false };
  verifie('sans RATE_KV ni AUDIO_BUCKET → émission sv 3 OK et SIGNÉE (fail-open du compteur)',
    sv3.statut === 200 && v3.valid === true && v3.claims.sv === 3 && v3.claims.p === 'free' &&
    v3.claims.cc === true && v3.claims.cv === CV,
    `HTTP ${sv3.statut} ${JSON.stringify(v3.claims || sv3.corps)}`);

  const val = await appel(deploye, '/validate', 'POST', { token: sv3.corps.token });
  verifie('sans AUDIO_BUCKET → /validate répond un 500 EXPLICITE, jamais un crash',
    val.statut === 500 && String(val.corps.error).includes('Bucket R2 non lié'),
    `HTTP ${val.statut} ${JSON.stringify(val.corps)}`);
}

console.log("\nInterrupteur ISSUE_CAP_ENABLED (lier le KV ≠ allumer le plafond)");
{
  // Le jour où RATE_KV sera lié, un seuil JAMAIS éprouvé (300/heure, valeur
  // devinée) ne doit pas s'appliquer d'un coup au trafic live. La 301e émission
  // dans la fenêtre doit donc encore passer tant que l'interrupteur est fermé.
  const s = kv(seedPlein()); // 300 déjà comptées dans la fenêtre
  const { statut, corps } = await appel(env(s)); // RATE_KV lié, ISSUE_CAP_ENABLED absente
  verifie('RATE_KV lié + ISSUE_CAP_ENABLED absente → la 301e émission PASSE (200, token remis)',
    statut === 200 && typeof corps.token === 'string', `HTTP ${statut}`);
  verifie('… et le compteur monte quand même à 301 (sans mesure, rien à observer avant d\'allumer)',
    compteur(s) === String(MAX_FENETRE + 1), String(compteur(s)));
}
{
  const s = kv(seedPlein()); // exactement le même état de départ
  const { statut, corps } = await appel(envCap(s));
  verifie('mêmes 300 dans la fenêtre + ISSUE_CAP_ENABLED="true" → 429, aucun token',
    statut === 429 && !('token' in corps), `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  // Même convention stricte que PAID_PLAN_ENABLED : seule la chaîne exacte
  // 'true' allume. Une valeur approchante laisse le plafond ÉTEINT (défaut
  // ouvert assumé ici : une var mal orthographiée ne doit pas murer l'inscription).
  const variantes = ['TRUE', '1', 'yes', ''];
  const statuts = [];
  for (const val of variantes) {
    statuts.push((await appel(env(kv(seedPlein()), { ISSUE_CAP_ENABLED: val }))).statut);
  }
  verifie('ISSUE_CAP_ENABLED "TRUE"/"1"/"yes"/"" ≠ "true" → plafond inactif (200)',
    statuts.every((c) => c === 200), `${variantes.map((v) => `"${v}"`).join(', ')} → ${statuts.join(', ')}`);
}
{
  // Le plafond reste inopérant sans KV, quel que soit l'interrupteur : il n'y a
  // pas de compteur à lire. Aucun 429 ne peut donc sortir dans l'état déployé.
  const { statut } = await appel(envCap(null), '/', 'POST', CLAIMS);
  verifie('ISSUE_CAP_ENABLED="true" mais RATE_KV absent → 200 (aucun 429 possible aujourd\'hui)',
    statut === 200, `HTTP ${statut}`);
}

console.log('\n/validate : la preuve de complétion est un VERDICT de lecture, pas un objet');
/**
 * Bucket R2 en mémoire pour /validate : `list` honore `prefix`, `limit` et
 * `include` (customMetadata renvoyées SEULEMENT si demandées, comme R2),
 * `put`/`head`/`get` comme le binding. [ignoreInclude] simule un listing sans
 * métadonnées, pour exercer le repli sur l'analyse de la clé.
 */
function bucketR2({ ignoreInclude = false } = {}) {
  const m = new Map();
  return {
    _m: m,
    put: async (k, v, opts) => { m.set(k, { value: v, customMetadata: (opts && opts.customMetadata) || {} }); },
    head: async (k) => (m.has(k) ? {} : null),
    get: async (k) => (m.has(k)
      ? { json: async () => JSON.parse(String(m.get(k).value)), text: async () => String(m.get(k).value) }
      : null),
    list: async ({ prefix = '', limit = 1000, include } = {}) => {
      const avecMd = !ignoreInclude && Array.isArray(include) && include.includes('customMetadata');
      const objects = [...m.entries()]
        .filter(([k]) => k.startsWith(prefix))
        .slice(0, limit)
        .map(([k, e]) => ({ key: k, ...(avecMd ? { customMetadata: e.customMetadata } : {}) }));
      return { objects, truncated: false };
    },
  };
}
const jetonValide = (await appel(envPlan(kv()), '/', 'POST',
  { ...CLAIMS, p: 'free', cc: true, cv: CV })).corps.token;
const COMPTE = (await sha256hex(payloadDe(jetonValide).n)).slice(0, 32);
let uuidN = 0;
const uuid = () => `00000000-0000-4000-8000-${String(++uuidN).padStart(12, '0')}`;
/** Un enregistrement tel que l'écrit r2-upload (clé + customMetadata). */
async function semerAudio(store, { session, type = 'reading', textId, sansMd = false }) {
  await store.put(`internal/${COMPTE}/${session}/C-${type}-${textId}-${uuid()}.webm`, new Uint8Array(1),
    sansMd ? {} : { customMetadata: { account: COMPTE, session_id: session, record_type: type, text_id: textId } });
}
/** Un verdict tel que l'écrit r2-upload (corps JSON + customMetadata.ok). */
async function semerVerdict(store, { session, type = 'reading', textId, ok, sansMd = false }) {
  await store.put(`verified/${COMPTE}/${session}/${type}-${textId}.json`,
    JSON.stringify({ ok, reason: ok ? null : 'low_overlap', overlap: ok ? 0.5 : 0.1 }),
    sansMd ? {} : { customMetadata: { ok: String(ok), record_type: type, session_id: session, text_id: textId } });
}
const envValidate = (store, extra = {}) =>
  envPlan(kv(), { AUDIO_BUCKET: store, MIN_RECORDINGS: '1', MIN_VERIFIED_READINGS: '3', ...extra });
const valider = (store, extra) => appel(envValidate(store, extra), '/validate', 'POST', { token: jetonValide });
const marque = (store) => store._m.has(`validated/${COMPTE}`);
{
  // ─── Aucun objet → 400 comme avant (garde-fou MIN_RECORDINGS) ──────────────
  const vide = bucketR2();
  const r0 = await valider(vide);
  verifie('aucun objet sous le compte → 400 « aucun enregistrement », pas de code de vérification',
    r0.statut === 400 && String(r0.corps.error).includes('aucun enregistrement') && r0.corps.code === undefined,
    `HTTP ${r0.statut} ${JSON.stringify(r0.corps)}`);
  verifie('aucun objet → aucun marqueur posé', !marque(vide));

  // ─── 3 lectures, 3 verdicts ok → 200 + marqueur ────────────────────────────
  const trois = bucketR2();
  for (const t of ['fr_00001', 'fr_00002', 'fr_00003']) {
    await semerAudio(trois, { session: 'sessA', textId: t });
    await semerVerdict(trois, { session: 'sessA', textId: t, ok: true });
  }
  const r1 = await valider(trois);
  verifie('3 lectures au verdict ok → 200 { ok:true }',
    r1.statut === 200 && r1.corps.ok === true, `HTTP ${r1.statut} ${JSON.stringify(r1.corps)}`);
  verifie('3 verdicts ok → marqueur validated/<account> posé', marque(trois), [...trois._m.keys()].join(','));
  const r1bis = await valider(trois);
  verifie('rejouer /validate → 200 encore (idempotent)', r1bis.statut === 200, `HTTP ${r1bis.statut}`);

  // ─── 3 lectures, 2 verdicts ok, 1 sans verdict → 409 PENDING ──────────────
  const attente = bucketR2();
  for (const t of ['fr_00001', 'fr_00002', 'fr_00003']) await semerAudio(attente, { session: 'sessB', textId: t });
  await semerVerdict(attente, { session: 'sessB', textId: 'fr_00001', ok: true });
  await semerVerdict(attente, { session: 'sessB', textId: 'fr_00002', ok: true });
  const r2 = await valider(attente);
  verifie('2 ok + 1 lecture sans verdict → 409 VERIFICATION_PENDING { verified:2, pending:1 }',
    r2.statut === 409 && r2.corps.ok === false && r2.corps.code === 'VERIFICATION_PENDING'
    && r2.corps.verified === 2 && r2.corps.pending === 1,
    `HTTP ${r2.statut} ${JSON.stringify(r2.corps)}`);
  verifie('en attente → aucun marqueur posé', !marque(attente));

  // ─── 2 ok + 3 ok:false, tous tombés → 400 FAILED ───────────────────────────
  const rate = bucketR2();
  const textes = ['fr_00001', 'fr_00002', 'fr_00003', 'fr_00004', 'fr_00005'];
  for (const [i, t] of textes.entries()) {
    await semerAudio(rate, { session: 'sessC', textId: t });
    await semerVerdict(rate, { session: 'sessC', textId: t, ok: i < 2 });
  }
  const r3 = await valider(rate);
  verifie('2 ok + 3 ok:false → 400 VERIFICATION_FAILED { verified:2, failed:3 }',
    r3.statut === 400 && r3.corps.ok === false && r3.corps.code === 'VERIFICATION_FAILED'
    && r3.corps.verified === 2 && r3.corps.failed === 3 && r3.corps.pending === undefined,
    `HTTP ${r3.statut} ${JSON.stringify(r3.corps)}`);
  verifie('échec définitif → aucun marqueur posé', !marque(rate));

  // ─── Un fichier de silence : objet présent, verdict ok:false → refusé ──────
  const silence = bucketR2();
  await semerAudio(silence, { session: 'sessD', textId: 'fr_00001' });
  await semerVerdict(silence, { session: 'sessD', textId: 'fr_00001', ok: false });
  const r4 = await valider(silence);
  verifie('UN objet au verdict ok:false (silence) → 400 VERIFICATION_FAILED [la faille d\'origine est fermée]',
    r4.statut === 400 && r4.corps.code === 'VERIFICATION_FAILED' && r4.corps.verified === 0 && !marque(silence),
    `HTTP ${r4.statut} ${JSON.stringify(r4.corps)}`);

  // ─── Seuls des résumés : rien en attente, rien de vérifié → FAILED ─────────
  const resumes = bucketR2();
  await semerAudio(resumes, { session: 'sessE', type: 'summary', textId: 'fr_00001' });
  await semerVerdict(resumes, { session: 'sessE', type: 'summary', textId: 'fr_00001', ok: true });
  const r5 = await valider(resumes);
  verifie('seuls des résumés (même ok) → 400 VERIFICATION_FAILED { verified:0, failed:0 } : les résumés ne comptent pas',
    r5.statut === 400 && r5.corps.code === 'VERIFICATION_FAILED' && r5.corps.verified === 0 && r5.corps.failed === 0,
    `HTTP ${r5.statut} ${JSON.stringify(r5.corps)}`);

  // ─── Doublons : deux uploads du même texte n'attendent qu'UN verdict ───────
  const doublon = bucketR2();
  await semerAudio(doublon, { session: 'sessF', textId: 'fr_00001' });
  await semerAudio(doublon, { session: 'sessF', textId: 'fr_00001' });
  await semerVerdict(doublon, { session: 'sessF', textId: 'fr_00001', ok: true });
  const r6 = await valider(doublon, { MIN_VERIFIED_READINGS: '1' });
  verifie('2 uploads du même (session, texte) + 1 verdict ok + seuil 1 → 200, rien en attente',
    r6.statut === 200 && r6.corps.ok === true, `HTTP ${r6.statut} ${JSON.stringify(r6.corps)}`);

  // ─── MIN_VERIFIED_READINGS honorée, défaut 3 ───────────────────────────────
  const deux = bucketR2();
  for (const t of ['fr_00001', 'fr_00002']) {
    await semerAudio(deux, { session: 'sessG', textId: t });
    await semerVerdict(deux, { session: 'sessG', textId: t, ok: true });
  }
  const r7 = await valider(deux, { MIN_VERIFIED_READINGS: undefined });
  const r7b = await valider(deux, { MIN_VERIFIED_READINGS: '2' });
  verifie('2 ok : var absente → défaut 3 → 400 FAILED ; var "2" → 200',
    r7.statut === 400 && r7.corps.code === 'VERIFICATION_FAILED' && r7b.statut === 200,
    `HTTP ${r7.statut} / ${r7b.statut}`);

  // ─── Repli sans customMetadata : la clé et le corps JSON suffisent ─────────
  const nu = bucketR2({ ignoreInclude: true });
  for (const t of ['fr_00001', 'fr_00002', 'fr_00003']) {
    await semerAudio(nu, { session: 'sessH', textId: t, sansMd: true });
    await semerVerdict(nu, { session: 'sessH', textId: t, ok: true, sansMd: true });
  }
  await semerAudio(nu, { session: 'sessH', textId: 'fr_00004', sansMd: true }); // sans verdict
  const r8 = await valider(nu);
  verifie('listing sans métadonnées → analyse de la clé + lecture du corps : 3 ok, 1 en attente → 200 (seuil atteint)',
    r8.statut === 200, `HTTP ${r8.statut} ${JSON.stringify(r8.corps)}`);
  await nu.put(`verified/${COMPTE}/sessH/reading-fr_00003.json`, JSON.stringify({ ok: false }), {});
  const r8b = await valider(nu);
  verifie('… et un corps JSON ok:false relu sans métadonnées compte comme échec → 409 (2 ok, 1 en attente)',
    r8b.statut === 409 && r8b.corps.verified === 2 && r8b.corps.pending === 1,
    `HTTP ${r8b.statut} ${JSON.stringify(r8b.corps)}`);

  // ─── Compte étranger : les verdicts d'un autre compte ne comptent pas ──────
  const autre = bucketR2();
  await semerAudio(autre, { session: 'sessI', textId: 'fr_00001' });
  for (const t of ['fr_00001', 'fr_00002', 'fr_00003']) {
    await autre.put(`verified/ffffffffffffffffffffffffffffffff/sessI/reading-${t}.json`,
      JSON.stringify({ ok: true }), { customMetadata: { ok: 'true' } });
  }
  const r9 = await valider(autre);
  verifie('verdicts ok sous un AUTRE compte → ignorés (409, la lecture propre attend son verdict)',
    r9.statut === 409 && r9.corps.verified === 0 && r9.corps.pending === 1,
    `HTTP ${r9.statut} ${JSON.stringify(r9.corps)}`);
}

console.log('\nConfiguration déployable (wrangler.toml)');
{
  // ⚠️ CETTE SECTION EST LA GARDE ANTI-RÉGRESSION DU DÉPLOIEMENT.
  // `wrangler deploy` refuse de publier si un binding pointe vers une ressource
  // absente ; `wrangler deploy --dry-run`, lui, ne bundle que le code et ne
  // vérifie AUCUNE ressource — un dry-run vert ne prouve donc rien. Ces
  // assertions relisent le toml et sont la seule vérification hors-ligne
  // possible que le worker reste publiable.
  const toml = readFileSync(new URL('../wrangler.toml', import.meta.url), 'utf8');
  // Lignes ACTIVES uniquement : tout ce qui commence par '#' est un commentaire.
  const actif = toml.split('\n').filter((l) => !l.trimStart().startsWith('#')).join('\n');

  // Le bucket mentality-audio existe (EU) depuis le 2026-09-03 : le binding est
  // ACTIF et doit viser ce bucket en juridiction eu, sans quoi /validate et le
  // nettoyage liraient un bucket standard du même nom (hors UE).
  const blocR2 = (actif.match(/\[\[r2_buckets\]\][\s\S]*?(?=\n\[|$)/) || [''])[0];
  verifie('[[r2_buckets]] AUDIO_BUCKET ACTIF sur mentality-audio en juridiction eu',
    /bucket_name\s*=\s*"mentality-audio"/.test(blocR2) && /jurisdiction\s*=\s*"eu"/.test(blocR2),
    `bloc R2 lu : « ${blocR2.slice(0,120)} »`);
  // Le namespace RATE_KV existe depuis le 2026-09-03 : le binding est ACTIF, et
  // il doit porter un id hexadécimal réel (32 caractères) — jamais le placeholder,
  // jamais celui d'un autre worker (garde REFERRAL_KV plus bas).
  const idKv = (actif.match(/\[\[kv_namespaces\]\][\s\S]*?id\s*=\s*"([^"]+)"/) || [])[1] || '';
  verifie('[[kv_namespaces]] RATE_KV ACTIF avec un id hexadécimal de 32 caractères',
    /^[0-9a-f]{32}$/.test(idKv), `id KV lu : « ${idKv} »`);
  verifie('aucun `id` PLACEHOLDER actif (une chaîne littérale ferait échouer le deploy)',
    !actif.includes('REMPLACER_PAR_LA_SORTIE_DE'), 'placeholder actif dans le toml');
  verifie('l\'id de REFERRAL_KV n\'est collé nulle part (namespace d\'un AUTRE worker)',
    !actif.includes('6c70f3aab78c4aeb92d1255f62edbafd'), 'id REFERRAL_KV présent');
  verifie('les [vars] restent ACTIVES (chaînes pures, aucune ressource requise)',
    actif.includes('PAID_PLAN_ENABLED') && actif.includes('LEGAL_VERSIONS') &&
    actif.includes('ISSUE_CAP_ENABLED') && actif.includes('ISSUE_MAX_PER_WINDOW') &&
    actif.includes('CORPUS_CONSENT_REQUIRED') && actif.includes('MIN_RECORDINGS'),
    'une [vars] a disparu');
  verifie('MIN_VERIFIED_READINGS livrée à "3" (seuil de lectures vérifiées de /validate)',
    /MIN_VERIFIED_READINGS\s*=\s*"3"/.test(actif),
    'MIN_VERIFIED_READINGS absente ou ≠ "3" dans le toml livré');
  verifie('CORPUS_CONSENT_REQUIRED livrée à "true" (pas de passe Gratuit sans consentement corpus)',
    /CORPUS_CONSENT_REQUIRED\s*=\s*"true"/.test(actif),
    'CORPUS_CONSENT_REQUIRED absente ou ≠ "true" dans le toml livré');
  verifie('ISSUE_CAP_ENABLED livrée à une valeur INACTIVE (le plafond ne s\'allume pas tout seul)',
    /ISSUE_CAP_ENABLED\s*=\s*"(?!true")/.test(actif),
    'ISSUE_CAP_ENABLED est à "true" dans le toml livré');
  verifie('procédure d\'activation présente et copiable pour les DEUX bindings commentés',
    /r2 bucket create mentality-audio --jurisdiction eu/.test(toml) &&
    /kv namespace create RATE_KV/.test(toml),
    'procédure d\'activation absente du toml');
}

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) { console.error('Échecs : ' + echecs.join(' | ')); process.exit(1); }
