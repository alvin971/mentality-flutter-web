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

import worker from '../index.js';
import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS } from '../../_shared/token_verify.js';

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
  const { statut, corps } = await appel(env(s));
  verifie('compteur plein → 429, aucun token', statut === 429 && !('token' in corps),
    `HTTP ${statut}`);
}
{
  const presque = Object.fromEntries(tranches().map((k) => [k, String(MAX_FENETRE - 1)]));
  const s = kv(presque);
  const un = await appel(env(s));
  const deux = await appel(env(s));
  verifie('max−1 → 200 (dernière place), puis 429 (off-by-one exclu)',
    un.statut === 200 && deux.statut === 429, `${un.statut} puis ${deux.statut}`);
}
{
  const { statut } = await appel(env(null)); // pas de RATE_KV
  verifie('binding RATE_KV absent → FAIL-OPEN (200), l\'inscription n\'est jamais murée',
    statut === 200, `HTTP ${statut}`);
}
{
  const b = Math.floor(Date.now() / (FENETRE_MIN * 60000));
  const s = kv({ [`issue:${b - 1}`]: String(MAX_FENETRE) }); // tranche PASSÉE pleine
  const { statut } = await appel(env(s));
  verifie('tranche passée pleine → 200 (la fenêtre glisse, pas de plafond global)',
    statut === 200, `HTTP ${statut}`);
}
{
  const s = kv();
  const { statut } = await appel(env(s), '/', 'POST', { ...CLAIMS, s: 'Z' });
  verifie('claims invalides → 400 SANS consommer le budget',
    statut === 400 && compteur(s) === null, `HTTP ${statut}, compteur ${compteur(s)}`);
}
{
  // /validate n'est jamais plafonné : au plafond, il répond selon SA logique
  // (ici 500 « Bucket R2 non lié », le binding AUDIO_BUCKET étant désactivé).
  const s = kv(seedPlein());
  const jeton = (await appel(env(kv()))).corps.token;
  const { statut, corps } = await appel(env(s), '/validate', 'POST', { token: jeton });
  verifie('/validate au plafond → jamais 429 (500 bucket R2 non lié)',
    statut === 500 && String(corps.error).includes('R2'), `HTTP ${statut} ${JSON.stringify(corps)}`);
}
{
  const s = kv(seedPlein());
  const { statut } = await appel(env(s), '/geo', 'GET');
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

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) { console.error('Échecs : ' + echecs.join(' | ')); process.exit(1); }
