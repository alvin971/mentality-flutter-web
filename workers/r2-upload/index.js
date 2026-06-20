/**
 * Cloudflare Worker — Upload audio sécurisé vers R2
 *
 * Le client Flutter Web ne peut pas écrire dans R2 directement (les clés
 * seraient exposées). Ce worker reçoit les octets audio + métadonnées, applique
 * les règles RGPD + l'AUTHENTIFICATION PAR TOKEN, et écrit dans R2.
 *
 * AUTHENTIFICATION (étape E) : chaque upload DOIT porter un token anonyme signé
 * (X-Mentality-Token). Le worker RE-VÉRIFIE la signature Ed25519 côté serveur
 * (workers/_shared/token_verify.js) — c'est ici que la signature a une valeur de
 * sécurité (la vérif client est contournable). Sans token valide → 401.
 *
 * LIAISON DONNÉES↔TOKEN : la partition de stockage est dérivée du NONCE signé
 * (account = SHA-256(nonce)), JAMAIS d'un identifiant choisi par le client.
 * Personne ne peut écrire dans le compartiment d'autrui sans son token signé.
 *
 * Organisation des clés :
 *   <reusable|internal>/<account=H(nonce)>/<sessionId>/<layer>-<recordType>-<textId>-<uuid>.<ext>
 *     - reusable/ : commercial_reuse = true  → cessibles à des tiers
 *     - internal/ : commercial_reuse = false → usage interne
 *   account = SHA-256(nonce) lie les données au token (anonyme). sessionId =
 *   sous-regroupement d'une session de test. uuid (pas un timestamp) → anti
 *   ré-identification temporelle. Effacement = lister/supprimer par account.
 *
 * RGPD : SANS preuve de consentement (X-Consent-Version), upload REFUSÉ (403).
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

const CONTENT_TYPES = {
  'audio/webm': 'webm',
  'audio/mp4': 'm4a',
  'audio/aac': 'm4a',
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
};

const MAX_BYTES = 25 * 1024 * 1024; // 25 Mo

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    const isAllowed = ALLOWED_ORIGINS.includes(origin);
    if (!isAllowed && origin !== '') {
      return json({ error: 'Origin non autorisée' }, 403, origin);
    }

    if (request.method !== 'POST') {
      return json({ error: 'Méthode non autorisée' }, 405, origin);
    }

    if (!env.AUDIO_BUCKET) {
      return json(
        { error: 'Bucket R2 non lié. Vérifier le binding AUDIO_BUCKET dans wrangler.toml.' },
        500,
        origin,
      );
    }

    // ─── Authentification : token signé OBLIGATOIRE, vérifié côté serveur ────
    const tokenStr = request.headers.get('X-Mentality-Token') || '';
    const auth = await verifyToken(tokenStr, TOKEN_SIGNING_PUBLIC_KEYS);
    if (!auth.valid) {
      return json({ error: `Token requis/invalide (${auth.reason})` }, 401, origin);
    }
    // Partition de données dérivée du nonce signé (anonyme, non falsifiable).
    const account = (await sha256hex(auth.nonce)).slice(0, 32);

    // ─── Métadonnées (en-têtes, le corps étant binaire) ──────────────────────
    const sessionId = sanitize(request.headers.get('X-Session-Id'));
    const textId = sanitize(request.headers.get('X-Text-Id'));
    const layer = sanitize(request.headers.get('X-Layer')) || 'C';
    const recordType = sanitize(request.headers.get('X-Record-Type')) || 'audio';
    const consentVersion = request.headers.get('X-Consent-Version') || '';
    const commercialReuse = request.headers.get('X-Commercial-Reuse') === 'true';
    const durationSeconds = request.headers.get('X-Duration-Seconds') || '';
    const language = sanitize(request.headers.get('X-Language')) || 'fr';
    const contentType = request.headers.get('Content-Type') || '';

    // ─── Garde-fou RGPD : pas de consentement → pas de stockage ──────────────
    if (!consentVersion) {
      return json({ error: 'Consentement absent : upload refusé (RGPD).' }, 403, origin);
    }
    if (!sessionId) {
      return json({ error: 'X-Session-Id requis' }, 400, origin);
    }

    const ext = CONTENT_TYPES[contentType.split(';')[0].trim()];
    if (!ext) {
      return json({ error: `Content-Type audio non supporté : ${contentType}` }, 415, origin);
    }

    const body = await request.arrayBuffer();
    if (body.byteLength === 0) return json({ error: 'Corps vide' }, 400, origin);
    if (body.byteLength > MAX_BYTES) return json({ error: 'Fichier trop volumineux' }, 413, origin);

    // ─── Clé R2 : compartiment lié au token (H(nonce)) + uuid (pas de timestamp) ─
    const bucket = commercialReuse ? 'reusable' : 'internal';
    const uid = crypto.randomUUID();
    const key = `${bucket}/${account}/${sessionId}/${layer}-${recordType}-${textId || 'na'}-${uid}.${ext}`;

    try {
      await env.AUDIO_BUCKET.put(key, body, {
        httpMetadata: { contentType },
        customMetadata: {
          account, // = SHA-256(nonce) tronqué : lien anonyme au token
          session_id: sessionId,
          text_id: textId || '',
          layer,
          record_type: recordType,
          consent_version: consentVersion,
          commercial_reuse: String(commercialReuse),
          duration_seconds: durationSeconds,
          language,
          uploaded_day: new Date().toISOString().slice(0, 10), // DATE, jamais l'heure
        },
      });
    } catch (error) {
      return json({ error: 'Échec écriture R2', detail: error.message }, 502, origin);
    }

    return json({ key, size: body.byteLength, reusable: commercialReuse }, 200, origin);
  },

  // Cron : supprime les données des comptes PROVISOIRES abandonnés — ceux sans
  // marqueur `validated/<account>` (écrit par tokeniser /validate) et dont les
  // objets dépassent RETENTION_DAYS. Les comptes validés (test soumis) sont
  // conservés. Voir wrangler.toml [triggers].
  async scheduled(event, env, ctx) {
    await cleanupAbandoned(env);
  },
};

/** Supprime les objets des comptes non validés plus vieux que RETENTION_DAYS. */
async function cleanupAbandoned(env) {
  if (!env.AUDIO_BUCKET) return;
  const retentionDays = parseInt(env.RETENTION_DAYS || '30', 10);
  const cutoff = Date.now() - retentionDays * 86400 * 1000;
  const maxObjects = parseInt(env.CLEANUP_MAX_OBJECTS || '20000', 10);
  const validatedCache = new Map(); // account -> bool (évite des head() répétés)
  let processed = 0;

  for (const prefix of ['reusable/', 'internal/']) {
    let cursor;
    do {
      const listed = await env.AUDIO_BUCKET.list({ prefix, cursor, limit: 1000 });
      for (const obj of listed.objects) {
        processed++;
        // obj.uploaded = horodatage système R2 (interne, hors clé applicative).
        if (!obj.uploaded || obj.uploaded.getTime() >= cutoff) continue;
        const account = obj.key.split('/')[1];
        if (!account) continue;
        let validated = validatedCache.get(account);
        if (validated === undefined) {
          validated = (await env.AUDIO_BUCKET.head(`validated/${account}`)) !== null;
          validatedCache.set(account, validated);
        }
        if (!validated) await env.AUDIO_BUCKET.delete(obj.key);
      }
      cursor = listed.truncated ? listed.cursor : undefined;
    } while (cursor && processed < maxObjects);
  }
}

// Neutralise les caractères dangereux pour une clé R2 (évite l'injection de chemin).
function sanitize(v) {
  if (!v) return '';
  return v.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 80);
}

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers':
      'Content-Type, X-Mentality-Token, X-Session-Id, X-Text-Id, X-Layer, X-Record-Type, X-Consent-Version, X-Commercial-Reuse, X-Duration-Seconds, X-Language',
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
