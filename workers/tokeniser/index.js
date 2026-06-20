/**
 * Cloudflare Worker — Tokeniseur (signature Ed25519 du token anonyme)
 *
 * Cycle de vie du token (deux états) :
 *   - POST /          → émet un token PROVISOIRE (status:'provisional').
 *                       Créé au DÉBUT (petit formulaire âge/région/sexe = « se
 *                       connecter »). Tant que le test n'est pas soumis, le token
 *                       est dans un entre-deux et peut être supprimé/abandonné.
 *   - POST /validate  → prend un token provisoire VALIDE et le re-signe en
 *                       status:'validated' (même nonce + mêmes démographiques +
 *                       même signup_day conservés). Appelé à la SOUMISSION d'un
 *                       test → le token devient permanent (validé à vie, jamais
 *                       d'expiration).
 *
 * Format : JWS compact EdDSA  header_b64url . payload_b64url . signature_b64url
 *
 * La clé privée Ed25519 ne quitte JAMAIS ce worker (Worker Secret,
 * extractable=false). Le client ne reçoit que la signature ; la clé PUBLIQUE
 * est pinnée côté client pour vérifier hors-ligne.
 *
 * ⚠️ La signature garantit l'AUTHENTICITÉ DE L'ÉMISSION. Elle n'est un CONTRÔLE
 *    D'ACCÈS que si un serveur RE-VÉRIFIE la signature au moment de servir/écrire
 *    les données (cf. workers/_shared/token_verify.js, utilisé par r2-upload).
 *
 * ⚠️ /validate re-signe tout token provisoire valide. En production, l'appel à
 *    /validate DOIT être déclenché par la vraie soumission d'un test (preuve de
 *    complétion), pas librement par le client. TODO(prod) : gater /validate
 *    derrière la soumission de résultats.
 *
 * Déploiement : voir README.md. Secret : wrangler secret put ED25519_PRIVATE_KEY_B64.
 *
 * ANONYMAT : stateless, AUCUN log (IP/timestamp/claims/token), aucun stockage.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const KID = 'k1';
const SCHEMA_VERSION = 1;

const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

// Allow-lists FERMÉES (anti-injection de quasi-identifiants / canal caché).
const ALLOWED_SEX = new Set(['M', 'F', 'X']);
const ALLOWED_REGIONS = new Set([
  'IDF', 'ARA', 'BFC', 'BRE', 'CVL', 'COR', 'GES', 'HDF',
  'NOR', 'NAQ', 'OCC', 'PDL', 'PAC', 'DOM', 'OTHER',
]);

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    // Égalité STRICTE (pas startsWith). CORS ≠ contrôle d'accès (cf. README).
    if (!ALLOWED_ORIGINS.includes(origin) && origin !== '') {
      return json({ error: 'Origin non autorisée' }, 403, origin);
    }
    const path = new URL(request.url).pathname;

    // GET /geo — suggestion de région large depuis la géo-IP Cloudflare.
    // Aucune auth, aucune donnée stockée/loggée : un simple indice corrigeable
    // côté client (pas de coordonnées, pas d'IP — juste une région large).
    if (request.method === 'GET' && path === '/geo') {
      return handleGeo(request, origin);
    }

    if (request.method !== 'POST') {
      return json({ error: 'Méthode non autorisée' }, 405, origin);
    }
    if (!env.ED25519_PRIVATE_KEY_B64) {
      return json(
        { error: 'Clé de signature non configurée (wrangler secret put ED25519_PRIVATE_KEY_B64)' },
        500, origin,
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Corps JSON invalide' }, 400, origin);
    }

    if (path === '/validate') {
      return handleValidate(body, env, origin);
    }
    return handleIssue(body, env, origin);
  },
};

/**
 * GET /geo — déduit une région large depuis la géo-IP Cloudflare (request.cf).
 * Renvoie { region: <code|null>, country }. L'IP n'est ni stockée ni loggée ;
 * on n'expose qu'une région large (jamais ville/coordonnées). Indice corrigeable.
 */
function handleGeo(request, origin) {
  const cf = request.cf || null;
  return json(
    { region: regionFromCf(cf), country: (cf && cf.country) || null },
    200, origin,
  );
}

// Noms ISO/Cloudflare des régions FR → codes de l'allow-list (clés normalisées).
const REGION_NAME_TO_CODE = {
  'ile-de-france': 'IDF',
  'auvergne-rhone-alpes': 'ARA',
  'bourgogne-franche-comte': 'BFC',
  'bretagne': 'BRE',
  'centre-val de loire': 'CVL',
  'corse': 'COR',
  'grand est': 'GES',
  'hauts-de-france': 'HDF',
  'normandie': 'NOR',
  'nouvelle-aquitaine': 'NAQ',
  'occitanie': 'OCC',
  'pays de la loire': 'PDL',
  "provence-alpes-cote d'azur": 'PAC',
};

function stripAccentsLower(s) {
  return (s || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

/** Mappe request.cf → code région de l'allow-list. null si géo inconnue. */
function regionFromCf(cf) {
  if (!cf || !cf.country) return null;        // géo indisponible → pas de pré-remplissage
  if (cf.country !== 'FR') return 'OTHER';     // hors France → « Hors France / Autre »
  // cf.regionCode : ISO 3166-2 (ex. 'IDF' ou 'FR-IDF') selon la donnée Cloudflare.
  const code = stripAccentsLower(cf.regionCode).replace(/^fr-/, '').toUpperCase();
  if (ALLOWED_REGIONS.has(code)) return code;
  // Repli par nom (cf.region, ex. 'Île-de-France').
  const byName = REGION_NAME_TO_CODE[stripAccentsLower(cf.region)];
  return byName || 'OTHER';
}

/** POST / — émet un token PROVISOIRE depuis des claims démographiques larges. */
async function handleIssue(body, env, origin) {
  const v = validateClaims(body);
  if (v.error) return json({ error: v.error }, 400, origin);

  const nonceBytes = new Uint8Array(32); // 256 bits
  crypto.getRandomValues(nonceBytes);

  const payload = {
    ...v.claims,
    nonce: b64url(nonceBytes),
    status: 'provisional',
    sv: SCHEMA_VERSION,
  };
  try {
    return json({ token: await signPayload(payload, env.ED25519_PRIVATE_KEY_B64) }, 200, origin);
  } catch {
    return json({ error: 'Échec de signature (clé invalide ?)' }, 500, origin);
  }
}

/** POST /validate — re-signe un token provisoire valide en VALIDÉ (permanent). */
async function handleValidate(body, env, origin) {
  const token = body && typeof body.token === 'string' ? body.token : null;
  if (!token) return json({ error: 'token requis' }, 400, origin);

  const v = await verifyToken(token, TOKEN_SIGNING_PUBLIC_KEYS);
  if (!v.valid) return json({ error: `token invalide (${v.reason})` }, 401, origin);

  // Idempotent : un token déjà validé est renvoyé tel quel.
  if (v.claims.status === 'validated') {
    return json({ token, alreadyValidated: true }, 200, origin);
  }
  if (v.claims.status !== 'provisional') {
    return json({ error: 'statut inattendu' }, 400, origin);
  }

  // ─── Preuve de complétion : des enregistrements existent sous le compte ───
  // La validation n'est pas un appel client libre : on exige que le compte
  // (dérivé du nonce signé) contienne réellement des données de test dans R2.
  if (!env.AUDIO_BUCKET) {
    return json({ error: 'Bucket R2 non lié (preuve de test indisponible)' }, 500, origin);
  }
  const account = (await sha256hex(v.claims.nonce)).slice(0, 32);
  const min = parseInt(env.MIN_RECORDINGS || '1', 10);
  if (!(await hasEnoughRecordings(env.AUDIO_BUCKET, account, min))) {
    return json(
      { error: 'Test non complété : aucun enregistrement trouvé sous ce compte.' },
      400, origin,
    );
  }

  // Re-signe en conservant nonce + démographiques + signup_day d'origine.
  const c = v.claims;
  const payload = {
    sex: c.sex,
    birth_year: c.birth_year,
    birth_month: c.birth_month,
    region: c.region,
    signup_day: c.signup_day,
    nonce: c.nonce,
    status: 'validated',
    sv: SCHEMA_VERSION,
  };
  let token2;
  try {
    token2 = await signPayload(payload, env.ED25519_PRIVATE_KEY_B64);
  } catch {
    return json({ error: 'Échec de signature (clé invalide ?)' }, 500, origin);
  }
  // Marqueur permanent « ce compte a été validé » (sert au cron de nettoyage
  // pour distinguer les comptes complétés des provisoires abandonnés).
  try {
    await env.AUDIO_BUCKET.put(`validated/${account}`, new Uint8Array(0), {
      customMetadata: { validated_day: new Date().toISOString().slice(0, 10) },
    });
  } catch {
    // non bloquant : la validation du token reste effective.
  }
  return json({ token: token2 }, 200, origin);
}

/** True si ≥ [min] objets existent sous reusable/<account>/ ou internal/<account>/. */
async function hasEnoughRecordings(bucket, account, min) {
  let count = 0;
  for (const prefix of [`reusable/${account}/`, `internal/${account}/`]) {
    const listed = await bucket.list({ prefix, limit: min });
    count += listed.objects.length;
    if (count >= min) return true;
  }
  return count >= min;
}

/**
 * Valide et NORMALISE les claims d'émission. signup_day est IGNORÉ s'il est
 * fourni et recalculé côté serveur (UTC, au jour) : autorité serveur, jamais client.
 */
function validateClaims(body) {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { error: 'Payload invalide' };
  }
  const allowedInputKeys = new Set(['sex', 'birth_year', 'birth_month', 'region', 'signup_day']);
  for (const k of Object.keys(body)) {
    if (!allowedInputKeys.has(k)) return { error: `Champ non autorisé: ${k}` };
  }
  const { sex, birth_year, birth_month, region } = body;
  if (!ALLOWED_SEX.has(sex)) return { error: 'sex invalide' };
  if (!ALLOWED_REGIONS.has(region)) return { error: 'region invalide' };
  if (!Number.isInteger(birth_month) || birth_month < 1 || birth_month > 12) {
    return { error: 'birth_month invalide' };
  }
  const nowYear = new Date().getUTCFullYear();
  if (!Number.isInteger(birth_year) || birth_year < nowYear - 100 || birth_year > nowYear - 5) {
    return { error: 'birth_year invalide' };
  }
  const signupDay = new Date().toISOString().slice(0, 10); // YYYY-MM-DD, UTC, au jour
  return { claims: { sex, birth_year, birth_month, region, signup_day: signupDay } };
}

/** Signe un objet payload complet → JWS compact EdDSA. */
async function signPayload(payloadObj, privKeyB64) {
  const header = { alg: 'EdDSA', typ: 'JWT', kid: KID };
  const headerB64 = b64url(utf8(JSON.stringify(header)));
  const payloadB64 = b64url(utf8(JSON.stringify(payloadObj)));
  const signingInput = utf8(`${headerB64}.${payloadB64}`);

  const keyBytes = b64ToBytes(privKeyB64);
  if (keyBytes.length !== 48) throw new Error('Clé privée de taille invalide');
  const key = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes.buffer.slice(keyBytes.byteOffset, keyBytes.byteOffset + keyBytes.byteLength),
    { name: 'Ed25519' },
    false,
    ['sign'],
  );
  const sig = new Uint8Array(await crypto.subtle.sign({ name: 'Ed25519' }, key, signingInput));
  return `${headerB64}.${payloadB64}.${b64url(sig)}`;
}

// ─── Helpers encodage (base64url SANS padding, sûrs sur octets bruts) ──────────

function utf8(str) {
  return new TextEncoder().encode(str);
}

function b64url(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64ToBytes(b64) {
  const clean = b64.replace(/\s+/g, '').replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(clean);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

// ─── CORS / réponses ───────────────────────────────────────────────────────────

function corsHeaders(origin) {
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function handleOptions(request) {
  const origin = request.headers.get('Origin') || '';
  return new Response(null, { status: 204, headers: corsHeaders(origin) });
}

function json(obj, status, origin) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
  });
}
