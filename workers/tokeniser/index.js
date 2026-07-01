/**
 * Cloudflare Worker — Tokeniseur (signature Ed25519 du token anonyme)
 *
 * Le token est ÉMIS UNE FOIS et est IMMUABLE ensuite (jamais re-signé) :
 *   - POST /          → émet le token (claims démographiques + nonce + sv).
 *                       Créé au DÉBUT (petit formulaire âge/région/sexe = « se
 *                       connecter »).
 *   - POST /validate  → vérifie une PREUVE DE COMPLÉTION (enregistrements
 *                       présents dans R2 sous le compte dérivé du nonce) et
 *                       pose un marqueur serveur permanent
 *                       (`validated/<account>`). Le token N'EST PAS modifié :
 *                       le client garde et réutilise le même token émis au
 *                       départ. Idempotent (rejouer /validate est sans effet).
 *
 * Format : JWS compact EdDSA  header_b64url . payload_b64url . signature_b64url
 * Claims compactes (sv: 2) : {s, y, m, r, d, n, sv} — voir validateClaims()
 * et lib/core/services/token_issuer.dart (miroir exact côté client).
 *
 * La clé privée Ed25519 ne quitte JAMAIS ce worker (Worker Secret,
 * extractable=false). Le client ne reçoit que la signature ; la clé PUBLIQUE
 * est pinnée côté client pour vérifier hors-ligne.
 *
 * ⚠️ La signature garantit l'AUTHENTICITÉ DE L'ÉMISSION. Elle n'est un CONTRÔLE
 *    D'ACCÈS que si un serveur RE-VÉRIFIE la signature au moment de servir/écrire
 *    les données (cf. workers/_shared/token_verify.js, utilisé par r2-upload).
 *
 * Déploiement : voir README.md. Secret : wrangler secret put ED25519_PRIVATE_KEY_B64.
 *
 * ANONYMAT : stateless, AUCUN log (IP/timestamp/claims/token), aucun stockage.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const KID = 'k1';
const SCHEMA_VERSION = 2;

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

/** POST / — émet le token (immuable) depuis des claims démographiques larges. */
async function handleIssue(body, env, origin) {
  const v = validateClaims(body);
  if (v.error) return json({ error: v.error }, 400, origin);

  const nonceBytes = new Uint8Array(16); // 128 bits — identifiant de partition, pas un secret
  crypto.getRandomValues(nonceBytes);

  const payload = {
    ...v.claims,
    d: daysSinceEpoch(new Date()),
    n: b64url(nonceBytes),
    sv: SCHEMA_VERSION,
  };
  try {
    return json({ token: await signPayload(payload, env.ED25519_PRIVATE_KEY_B64) }, 200, origin);
  } catch {
    return json({ error: 'Échec de signature (clé invalide ?)' }, 500, origin);
  }
}

/**
 * POST /validate — vérifie une preuve de complétion et marque le compte
 * comme validé. Le token N'EST PAS re-signé : il ne change pas, le client
 * garde le même. Idempotent (rejouer l'appel écrase silencieusement le même
 * marqueur R2).
 */
async function handleValidate(body, env, origin) {
  const token = body && typeof body.token === 'string' ? body.token : null;
  if (!token) return json({ error: 'token requis' }, 400, origin);

  const v = await verifyToken(token, TOKEN_SIGNING_PUBLIC_KEYS);
  if (!v.valid) return json({ error: `token invalide (${v.reason})` }, 401, origin);

  // ─── Preuve de complétion : des enregistrements existent sous le compte ───
  // La validation n'est pas un appel client libre : on exige que le compte
  // (dérivé du nonce signé) contienne réellement des données de test dans R2.
  if (!env.AUDIO_BUCKET) {
    return json({ error: 'Bucket R2 non lié (preuve de test indisponible)' }, 500, origin);
  }
  const account = (await sha256hex(v.claims.n)).slice(0, 32);
  const min = parseInt(env.MIN_RECORDINGS || '1', 10);
  if (!(await hasEnoughRecordings(env.AUDIO_BUCKET, account, min))) {
    return json(
      { error: 'Test non complété : aucun enregistrement trouvé sous ce compte.' },
      400, origin,
    );
  }

  // Marqueur permanent « ce compte a été validé » (sert au cron de nettoyage
  // pour distinguer les comptes complétés des abandonnés, cf. r2-upload).
  try {
    await env.AUDIO_BUCKET.put(`validated/${account}`, new Uint8Array(0), {
      customMetadata: { validated_day: new Date().toISOString().slice(0, 10) },
    });
  } catch {
    // Bloquant : sans marqueur écrit, la complétion n'est pas confirmée —
    // le client réessaiera (cf. TokenIssuer.markCompleted côté Flutter).
    return json({ error: "Échec de l'enregistrement de la complétion" }, 500, origin);
  }
  return json({ ok: true }, 200, origin);
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
 * Valide et NORMALISE les claims d'émission (clés compactes : s/y/m/r). Le
 * jour d'inscription (`d`) n'est PAS un champ d'entrée : il est calculé côté
 * serveur (UTC, au jour) — autorité serveur, jamais client.
 */
function validateClaims(body) {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { error: 'Payload invalide' };
  }
  const allowedInputKeys = new Set(['s', 'y', 'm', 'r']);
  for (const k of Object.keys(body)) {
    if (!allowedInputKeys.has(k)) return { error: `Champ non autorisé: ${k}` };
  }
  const { s, y, m, r } = body;
  if (!ALLOWED_SEX.has(s)) return { error: 's (sexe) invalide' };
  if (!ALLOWED_REGIONS.has(r)) return { error: 'r (région) invalide' };
  if (!Number.isInteger(m) || m < 1 || m > 12) {
    return { error: 'm (mois de naissance) invalide' };
  }
  const nowYear = new Date().getUTCFullYear();
  if (!Number.isInteger(y) || y < nowYear - 100 || y > nowYear - 5) {
    return { error: 'y (année de naissance) invalide' };
  }
  return { claims: { s, y, m, r } };
}

/** Jours écoulés depuis epoch UTC (au jour, jamais l'heure). */
function daysSinceEpoch(date) {
  return Math.floor(date.getTime() / 86400000);
}

/** Signe un objet payload complet → JWS compact EdDSA. */
async function signPayload(payloadObj, privKeyB64) {
  // Pas de `typ` (inutile, ni le client ni aucun serveur ne le lit) — le
  // raccourcir fait partie de la réduction de taille du token.
  const header = { alg: 'EdDSA', kid: KID };
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
