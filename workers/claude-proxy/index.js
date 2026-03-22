/**
 * Cloudflare Worker — Proxy sécurisé pour l'API Claude (Anthropic)
 *
 * Ce worker intercepte les requêtes du client Flutter et ajoute la clé API
 * Claude depuis les secrets Cloudflare Workers (jamais exposée au client).
 *
 * Déploiement :
 *   1. cd workers/claude-proxy
 *   2. wrangler secret put ANTHROPIC_API_KEY   ← saisir la clé ici
 *   3. wrangler deploy
 *   4. Copier l'URL du worker dans AppConstants.claudeWorkerUrl
 */

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';

// Origines autorisées (ajouter le domaine Cloudflare Pages de l'app)
const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

export default {
  async fetch(request, env, ctx) {
    // Gestion CORS preflight
    if (request.method === 'OPTIONS') {
      return handleOptions(request);
    }

    // Vérifier l'origine
    const origin = request.headers.get('Origin') || '';
    const isAllowed = ALLOWED_ORIGINS.some(o => origin.startsWith(o));
    if (!isAllowed && origin !== '') {
      return new Response(JSON.stringify({ error: 'Origin non autorisée' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Uniquement POST /chat
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Méthode non autorisée' }), {
        status: 405,
        headers: corsHeaders(origin),
      });
    }

    // Vérifier que la clé API est configurée
    if (!env.ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'Clé API non configurée côté serveur. Exécuter: wrangler secret put ANTHROPIC_API_KEY' }),
        { status: 500, headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' } },
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response(JSON.stringify({ error: 'Corps JSON invalide' }), {
        status: 400,
        headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
      });
    }

    // Valider les champs requis
    if (!body.messages || !Array.isArray(body.messages)) {
      return new Response(JSON.stringify({ error: 'Champ "messages" requis' }), {
        status: 400,
        headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
      });
    }

    // Construire la requête vers Anthropic
    const anthropicPayload = {
      model: body.model || 'claude-haiku-4-5-20251001',
      max_tokens: body.max_tokens || 1024,
      system: body.system || '',
      messages: body.messages,
    };

    try {
      const anthropicResponse = await fetch(ANTHROPIC_API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': ANTHROPIC_VERSION,
        },
        body: JSON.stringify(anthropicPayload),
      });

      const responseData = await anthropicResponse.json();

      return new Response(JSON.stringify(responseData), {
        status: anthropicResponse.status,
        headers: {
          ...corsHeaders(origin),
          'Content-Type': 'application/json',
        },
      });
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Erreur lors de la communication avec Anthropic', detail: error.message }),
        {
          status: 502,
          headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
        },
      );
    }
  },
};

function corsHeaders(origin) {
  const allowedOrigin = ALLOWED_ORIGINS.find(o => origin.startsWith(o)) || ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function handleOptions(request) {
  const origin = request.headers.get('Origin') || '';
  return new Response(null, {
    status: 204,
    headers: corsHeaders(origin),
  });
}
