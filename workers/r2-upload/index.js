/**
 * Cloudflare Worker — Upload audio sécurisé vers R2
 *
 * Le client Flutter Web ne peut pas écrire dans R2 directement (les clés
 * seraient exposées dans le JS). Ce worker reçoit les octets audio + les
 * métadonnées, applique les règles RGPD côté serveur, et écrit dans R2.
 *
 * Organisation des clés (permet le tri commercial et le droit à l'oubli) :
 *   <reusable|internal>/<sessionId>/<layer>-<textId>-<timestamp>.<ext>
 *     - reusable/ : commercial_reuse = true  → fichiers cessibles à des tiers
 *     - internal/ : commercial_reuse = false → usage interne uniquement
 *   Lister/supprimer par sessionId = exécuter le droit d'effacement (art. 17).
 *
 * Règle RGPD appliquée ici : SANS preuve de consentement (X-Consent-Version),
 * l'upload est REFUSÉ (403). Le stockage sans base légale est ainsi impossible.
 *
 * Déploiement : voir wrangler.toml.
 */

const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

// Types de contenu audio acceptés et extension correspondante.
const CONTENT_TYPES = {
  'audio/webm': 'webm',
  'audio/mp4': 'm4a',
  'audio/aac': 'm4a',
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
};

// Taille max d'un enregistrement (garde-fou anti-abus) : 25 Mo.
const MAX_BYTES = 25 * 1024 * 1024;

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    const isAllowed = ALLOWED_ORIGINS.some((o) => origin.startsWith(o));
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

    // ─── Métadonnées (transmises via en-têtes, le corps étant binaire) ───────
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
      return json(
        { error: 'Consentement absent : upload refusé (RGPD).' },
        403,
        origin,
      );
    }

    if (!sessionId) {
      return json({ error: 'X-Session-Id requis' }, 400, origin);
    }

    const ext = CONTENT_TYPES[contentType.split(';')[0].trim()];
    if (!ext) {
      return json({ error: `Content-Type audio non supporté : ${contentType}` }, 415, origin);
    }

    const body = await request.arrayBuffer();
    if (body.byteLength === 0) {
      return json({ error: 'Corps vide' }, 400, origin);
    }
    if (body.byteLength > MAX_BYTES) {
      return json({ error: 'Fichier trop volumineux' }, 413, origin);
    }

    // ─── Clé R2 : tri commercial + regroupement par session ──────────────────
    const bucket = commercialReuse ? 'reusable' : 'internal';
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const key = `${bucket}/${sessionId}/${layer}-${recordType}-${textId || 'na'}-${stamp}.${ext}`;

    try {
      await env.AUDIO_BUCKET.put(key, body, {
        httpMetadata: { contentType },
        customMetadata: {
          session_id: sessionId,
          text_id: textId || '',
          layer,
          record_type: recordType,
          consent_version: consentVersion,
          commercial_reuse: String(commercialReuse),
          duration_seconds: durationSeconds,
          language,
          uploaded_at: new Date().toISOString(),
        },
      });
    } catch (error) {
      return json({ error: 'Échec écriture R2', detail: error.message }, 502, origin);
    }

    return json({ key, size: body.byteLength, reusable: commercialReuse }, 200, origin);
  },
};

// Neutralise les caractères dangereux pour une clé R2 (évite l'injection de chemin).
function sanitize(v) {
  if (!v) return '';
  return v.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 80);
}

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.find((o) => origin.startsWith(o)) || ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers':
      'Content-Type, X-Session-Id, X-Text-Id, X-Layer, X-Record-Type, X-Consent-Version, X-Commercial-Reuse, X-Duration-Seconds, X-Language',
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
