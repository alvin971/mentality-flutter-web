/**
 * Cloudflare Worker — Referral / déblocage des résultats par paliers.
 *
 * Le résultat du test complet est retenu derrière 3 paliers séquentiels :
 *   stage 1 : inviter 3 amis (lien /invite?ref=<code> lié au token)
 *   stage 2 : attendre que les 3 filleuls TERMINENT leur test complet
 *   stage 3 : suivre le compte Instagram (déclaratif + délai serveur)
 *   stage 4 : résultat débloqué
 *
 * Endpoints (auth = header X-Mentality-Token, signature Ed25519 re-vérifiée
 * serveur via workers/_shared/token_verify.js — cf. r2-upload) :
 *   POST /progress/init   → crée la ligne unlock_progress (idempotent) ;
 *                           si body.referrerCode présent, valide le parrainage
 *                           (le filleul vient de FINIR son test → completed).
 *   GET  /progress        → état courant + avancement des paliers ; c'est ICI
 *                           que les transitions de stage sont calculées
 *                           (autorité serveur, jamais le client).
 *   POST /instagram       → enregistre le pseudo (stage 2→3 requis).
 *   GET  /resolve/<code>  → public : le code referral existe-t-il ? (landing)
 *
 * Stockage : Supabase via PostgREST. Secrets worker (wrangler secret put) :
 *   SUPABASE_URL           https://<projet>.supabase.co
 *   SUPABASE_SERVICE_KEY   clé service_role (JAMAIS côté client)
 * Var : INSTA_UNLOCK_DELAY_MINUTES (délai de « vérification » avant stage 4).
 *
 * ANONYMAT : seule la partition account = SHA256(nonce)[:32] est stockée —
 * aucune donnée personnelle hormis le pseudo Instagram fourni volontairement.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const REQUIRED_REFERRALS = 3;

const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    if (!ALLOWED_ORIGINS.includes(origin) && origin !== '') {
      return json({ error: 'Origin non autorisée' }, 403, origin);
    }
    if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_KEY) {
      return json({ error: 'Supabase non configuré (secrets manquants)' }, 500, origin);
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // ─── Public : la landing d'invitation vérifie que le code existe ───────
    if (request.method === 'GET' && path.startsWith('/resolve/')) {
      const code = path.slice('/resolve/'.length);
      if (!/^[a-z0-9]{8}$/.test(code)) return json({ valid: false }, 200, origin);
      const rows = await sbSelect(env, 'unlock_progress', `referral_code=eq.${code}&select=referral_code`);
      return json({ valid: Array.isArray(rows) && rows.length > 0 }, 200, origin);
    }

    // ─── Tout le reste exige un token signé valide ──────────────────────────
    const token = request.headers.get('X-Mentality-Token');
    const v = await verifyToken(token, TOKEN_SIGNING_PUBLIC_KEYS);
    if (!v.valid) return json({ error: `token invalide (${v.reason})` }, 401, origin);
    const account = (await sha256hex(v.nonce)).slice(0, 32);

    try {
      if (request.method === 'POST' && path === '/progress/init') {
        let body = {};
        try { body = await request.json(); } catch { /* corps vide toléré */ }
        return await handleInit(env, origin, account, body);
      }
      if (request.method === 'GET' && path === '/progress') {
        return await handleProgress(env, origin, account);
      }
      if (request.method === 'POST' && path === '/instagram') {
        let body;
        try { body = await request.json(); } catch {
          return json({ error: 'Corps JSON invalide' }, 400, origin);
        }
        return await handleInstagram(env, origin, account, body);
      }
    } catch (e) {
      return json({ error: 'Erreur interne' }, 500, origin);
    }
    return json({ error: 'Route inconnue' }, 404, origin);
  },
};

/**
 * POST /progress/init — appelé à la FIN du test complet.
 * Idempotent : recrée jamais la ligne, renvoie l'état courant.
 * Si referrerCode est fourni (l'utilisateur est arrivé via un lien d'invite),
 * c'est le moment où le filleul VALIDE son parrain : son test vient d'être
 * terminé, on écrit referrals(referee_account, test_completed_at=now()).
 */
async function handleInit(env, origin, account, body) {
  let row = await getProgressRow(env, account);
  if (!row) {
    const code = await generateUniqueCode(env);
    const inserted = await sbInsert(env, 'unlock_progress', {
      account,
      referral_code: code,
      stage: 1,
    });
    row = inserted && inserted[0] ? inserted[0] : await getProgressRow(env, account);
    if (!row) return json({ error: 'Création du suivi impossible' }, 500, origin);
  }

  // Validation du parrainage (une seule fois, jamais soi-même).
  const refCode = typeof body.referrerCode === 'string' ? body.referrerCode.trim().toLowerCase() : '';
  if (/^[a-z0-9]{8}$/.test(refCode) && refCode !== row.referral_code) {
    const parent = await sbSelect(env, 'unlock_progress',
      `referral_code=eq.${refCode}&select=referral_code,account`);
    if (parent.length > 0 && parent[0].account !== account) {
      // Insert unique : si le filleul a déjà validé un parrain, PostgREST
      // renvoie un conflit (409) qu'on ignore silencieusement.
      await sbInsert(env, 'referrals', {
        referrer_code: refCode,
        referee_account: account,
        test_completed_at: new Date().toISOString(),
      }, /*onConflict=*/'referee_account');
    }
  }

  return buildProgressResponse(env, origin, row);
}

/** GET /progress — état courant + transitions de stage (autorité serveur). */
async function handleProgress(env, origin, account) {
  const row = await getProgressRow(env, account);
  if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);
  return buildProgressResponse(env, origin, row);
}

/** POST /instagram — enregistre le pseudo, démarre le délai de vérification. */
async function handleInstagram(env, origin, account, body) {
  const handleRaw = typeof body.handle === 'string' ? body.handle.trim() : '';
  const handle = handleRaw.replace(/^@/, '');
  if (!/^[A-Za-z0-9._]{1,30}$/.test(handle)) {
    return json({ error: 'Pseudo Instagram invalide' }, 400, origin);
  }
  const row = await getProgressRow(env, account);
  if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);

  // Le pseudo n'est accepté qu'une fois le palier parrainage franchi.
  const completed = await countCompletedReferrals(env, row.referral_code);
  if (completed < REQUIRED_REFERRALS) {
    return json({ error: 'Palier parrainage non terminé' }, 403, origin);
  }
  if (!row.instagram_submitted_at) {
    await sbPatch(env, 'unlock_progress', `account=eq.${row.account}`, {
      instagram_handle: handle,
      instagram_submitted_at: new Date().toISOString(),
      stage: 3,
    });
  }
  return buildProgressResponse(env, origin, await getProgressRow(env, account));
}

/**
 * Calcule l'état renvoyé au client ET applique les transitions de stage :
 *   1→3 : ≥3 filleuls ont terminé leur test (le stage 2 « attente » est un
 *         état d'AFFICHAGE : filleuls invités mais pas tous terminés)
 *   3→4 : pseudo Insta soumis depuis plus de INSTA_UNLOCK_DELAY_MINUTES et
 *         pas invalidé manuellement (instagram_verified !== false).
 */
async function buildProgressResponse(env, origin, row) {
  const referees = await sbSelect(env, 'referrals',
    `referrer_code=eq.${row.referral_code}&select=clicked_at,test_completed_at&order=clicked_at.asc`);
  const completedCount = referees.filter((r) => r.test_completed_at).length;

  let stage = row.stage;

  if (stage < 3 && completedCount >= REQUIRED_REFERRALS) {
    stage = 3;
    await sbPatch(env, 'unlock_progress', `account=eq.${row.account}`, { stage });
  }

  if (stage === 3 && row.instagram_submitted_at && row.instagram_verified !== false) {
    const delayMin = parseInt(env.INSTA_UNLOCK_DELAY_MINUTES || '120', 10);
    const elapsedMs = Date.now() - new Date(row.instagram_submitted_at).getTime();
    if (elapsedMs >= delayMin * 60000) {
      stage = 4;
      await sbPatch(env, 'unlock_progress', `account=eq.${row.account}`, {
        stage,
        unlocked_at: new Date().toISOString(),
      });
    }
  }

  return json({
    stage,
    referralCode: row.referral_code,
    referees: referees.map((r) => ({ completed: !!r.test_completed_at })),
    completedReferrals: completedCount,
    requiredReferrals: REQUIRED_REFERRALS,
    instagramHandle: row.instagram_handle || null,
    instagramSubmitted: !!row.instagram_submitted_at,
  }, 200, origin);
}

async function getProgressRow(env, account) {
  const rows = await sbSelect(env, 'unlock_progress', `account=eq.${account}&select=*`);
  return rows.length > 0 ? rows[0] : null;
}

async function countCompletedReferrals(env, code) {
  const rows = await sbSelect(env, 'referrals',
    `referrer_code=eq.${code}&test_completed_at=not.is.null&select=id`);
  return rows.length;
}

/** Code court a-z0-9 (8 chars, ~41 bits) unique en base. */
async function generateUniqueCode(env) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  for (let attempt = 0; attempt < 5; attempt++) {
    const bytes = new Uint8Array(8);
    crypto.getRandomValues(bytes);
    let code = '';
    for (const b of bytes) code += alphabet[b % alphabet.length];
    const dup = await sbSelect(env, 'unlock_progress', `referral_code=eq.${code}&select=referral_code`);
    if (dup.length === 0) return code;
  }
  throw new Error('Impossible de générer un code unique');
}

// ─── Client PostgREST minimal (service_role, jamais exposé) ──────────────────

function sbHeaders(env, extra = {}) {
  return {
    apikey: env.SUPABASE_SERVICE_KEY,
    Authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
    ...extra,
  };
}

async function sbSelect(env, table, query) {
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}`, {
    headers: sbHeaders(env),
  });
  if (!resp.ok) throw new Error(`select ${table}: ${resp.status}`);
  return resp.json();
}

async function sbInsert(env, table, row, onConflict = null) {
  const headers = sbHeaders(env, {
    Prefer: onConflict
      ? 'resolution=ignore-duplicates,return=representation'
      : 'return=representation',
  });
  const qs = onConflict ? `?on_conflict=${onConflict}` : '';
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}${qs}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(row),
  });
  if (resp.status === 409 && onConflict) return [];
  if (!resp.ok) throw new Error(`insert ${table}: ${resp.status}`);
  return resp.json();
}

async function sbPatch(env, table, query, patch) {
  const resp = await fetch(`${env.SUPABASE_URL}/rest/v1/${table}?${query}`, {
    method: 'PATCH',
    headers: sbHeaders(env),
    body: JSON.stringify(patch),
  });
  if (!resp.ok) throw new Error(`patch ${table}: ${resp.status}`);
}

// ─── CORS / réponses (même pattern que workers/tokeniser) ─────────────────────

function corsHeaders(origin) {
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Mentality-Token',
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
