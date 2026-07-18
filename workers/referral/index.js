/**
 * Cloudflare Worker — Referral / déblocage des résultats par paliers.
 *
 * Le résultat du test complet est retenu derrière 3 paliers séquentiels :
 *   stage 1 : inviter des amis (lien /invite?ref=<code> lié au token)
 *   stage 2 : (affichage) attendre que les filleuls TERMINENT leur test
 *   stage 3 : suivre le compte Instagram (déclaratif + délai serveur)
 *   stage 4 : résultat débloqué
 *
 * Endpoints (auth = header X-Mentality-Token, signature Ed25519 re-vérifiée
 * serveur via workers/_shared/token_verify.js — cf. r2-upload) :
 *   POST /link            → lie ce token à un parrain (appelé par le site à la
 *                           CRÉATION du passe : le filleul arrive via
 *                           /inscription?ref=<code>, liaison invisible).
 *                           NE crédite PAS la complétion.
 *   POST /progress/init   → crée l'état (idempotent) ; crédite la complétion
 *                           du filleul (son test vient de FINIR) d'après le
 *                           lien /link, ou body.referrerCode (legacy app).
 *   GET  /progress        → état courant + transitions de stage (autorité
 *                           serveur, jamais le client).
 *   POST /instagram       → enregistre le pseudo (palier parrainage requis).
 *   GET  /resolve/<code>  → public : le code referral existe-t-il ? (landing)
 *
 * Stockage : Cloudflare KV (binding REFERRAL_KV) — aucun secret externe.
 * Var : INSTA_UNLOCK_DELAY_MINUTES (délai de « vérification » avant stage 4).
 *
 * Modèle de clés KV :
 *   progress:<account>        → JSON de l'état du parrain (voir emptyProgress)
 *   code:<referralCode>       → <account> propriétaire du code (unicité + resolve)
 *   referee:<account>         → <referrerCode> (écrit UNE fois : 1 filleul = 1
 *                               parrain — via /link à la création du passe, ou
 *                               /progress/init legacy)
 *   ref:<referrerCode>:<acct> → timestamp ISO (une entrée = un filleul ayant fini)
 *
 * ANONYMAT : seule la partition account = SHA256(nonce)[:32] est stockée —
 * aucune donnée personnelle hormis le pseudo Instagram fourni volontairement.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const REQUIRED_REFERRALS = 3;

const ALLOWED_ORIGINS = [
  'https://mental-et.com',
  'https://www.mental-et.com',
  'https://mental-et-web.pages.dev',
  'https://mental-et.pages.dev',
  // Historique (app web retirée, liens d'invitation déjà partagés) :
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
  'http://localhost:4321',
  'http://127.0.0.1:4321',
];

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    if (!ALLOWED_ORIGINS.includes(origin) && origin !== '') {
      return json({ error: 'Origin non autorisée' }, 403, origin);
    }
    if (!env.REFERRAL_KV) {
      return json({ error: 'KV non lié (REFERRAL_KV)' }, 500, origin);
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // ─── Public : la landing d'invitation vérifie que le code existe ───────
    if (request.method === 'GET' && path.startsWith('/resolve/')) {
      const code = path.slice('/resolve/'.length);
      if (!/^[a-z0-9]{8}$/.test(code)) return json({ valid: false }, 200, origin);
      const owner = await env.REFERRAL_KV.get(`code:${code}`);
      return json({ valid: owner !== null }, 200, origin);
    }

    // ─── Tout le reste exige un token exploitable ───────────────────────────
    const token = request.headers.get('X-Mentality-Token');
    const nonce = await resolveNonce(token);
    if (!nonce) return json({ error: 'token invalide' }, 401, origin);
    const account = (await sha256hex(nonce)).slice(0, 32);

    try {
      if (request.method === 'POST' && path === '/link') {
        let body;
        try { body = await request.json(); } catch {
          return json({ error: 'Corps JSON invalide' }, 400, origin);
        }
        return await handleLink(env, origin, account, body);
      }
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

// Versions de schéma de claims supportées (miroir de kTokenSchemaVersion).
const SUPPORTED_SV = new Set([2]);
const B64URL = /^[A-Za-z0-9\-_]+$/;

/**
 * Extrait le nonce (claim `n`) d'un token, quelle que soit sa forme :
 *   1. Token signé Ed25519 (chemin nominal si le tokeniser est déployé).
 *   2. Token DEV non signé « M2.<base64url(claims)> ».
 * L'app Mentality accepte volontairement les tokens non signés en release tant
 * que le tokeniser n'est pas déployé (AppConstants.kAllowUnsignedTokenInRelease)
 * — ce gate marketing (données non sensibles) applique le même modèle de
 * confiance pour ne bloquer aucun utilisateur réel. Renvoie null si inexploitable.
 */
async function resolveNonce(token) {
  if (typeof token !== 'string' || token.length === 0) return null;
  const v = await verifyToken(token, TOKEN_SIGNING_PUBLIC_KEYS);
  if (v.valid) return v.nonce;
  if (token.startsWith('M2.')) {
    const claims = decodeB64urlJson(token.slice(3));
    if (claims &&
        typeof claims.n === 'string' &&
        B64URL.test(claims.n) &&
        SUPPORTED_SV.has(claims.sv)) {
      return claims.n;
    }
  }
  return null;
}

function decodeB64urlJson(seg) {
  try {
    let b64 = seg.replace(/-/g, '+').replace(/_/g, '/');
    while (b64.length % 4 !== 0) b64 += '=';
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const obj = JSON.parse(new TextDecoder().decode(bytes));
    return obj && typeof obj === 'object' && !Array.isArray(obj) ? obj : null;
  } catch {
    return null;
  }
}

function emptyProgress(account, code, nowIso) {
  return {
    account,
    referralCode: code,
    stage: 1,
    instagramHandle: null,
    instagramSubmittedAt: null,
    instagramVerified: null, // true/false = contrôle manuel admin
    unlockedAt: null,
    createdAt: nowIso,
  };
}

async function getProgress(env, account) {
  const raw = await env.REFERRAL_KV.get(`progress:${account}`);
  return raw ? JSON.parse(raw) : null;
}

async function putProgress(env, row) {
  await env.REFERRAL_KV.put(`progress:${row.account}`, JSON.stringify(row));
}

/** Nombre de filleuls ayant terminé leur test pour un code donné. */
async function countCompletedReferrals(env, code) {
  const listed = await env.REFERRAL_KV.list({ prefix: `ref:${code}:` });
  return listed.keys.length;
}

/**
 * POST /link — lie DÉFINITIVEMENT ce token à un parrain (1 filleul = 1 parrain,
 * premier lien gagnant). Appelé par le site à la création du passe : le filleul
 * est arrivé via /inscription?ref=<code>, la liaison est invisible pour lui.
 * Ne crédite JAMAIS la complétion (le test n'est pas passé) — c'est
 * /progress/init, à la fin du test, qui transforme le lien en crédit.
 */
async function handleLink(env, origin, account, body) {
  const code = typeof body.referrerCode === 'string'
    ? body.referrerCode.trim().toLowerCase()
    : '';
  if (!/^[a-z0-9]{8}$/.test(code)) {
    return json({ linked: false, error: 'Code invalide' }, 400, origin);
  }
  const existing = await env.REFERRAL_KV.get(`referee:${account}`);
  if (existing) return json({ linked: existing === code }, 200, origin);
  const owner = await env.REFERRAL_KV.get(`code:${code}`);
  // Code inconnu ou auto-parrainage : réponse 200 neutre (rien à exploiter).
  if (!owner || owner === account) return json({ linked: false }, 200, origin);
  await env.REFERRAL_KV.put(`referee:${account}`, code);
  return json({ linked: true }, 200, origin);
}

/**
 * POST /progress/init — appelé à la FIN du test complet.
 * Idempotent : ne recrée jamais l'état, renvoie l'état courant.
 * C'est ici que la COMPLÉTION du filleul est créditée à son parrain : le lien
 * vient de /link (création du passe sur le site) ou, legacy, de
 * body.referrerCode (ancien champ code de l'app / landing /invite).
 */
async function handleInit(env, origin, account, body) {
  const nowIso = isoNow();
  let row = await getProgress(env, account);
  if (!row) {
    const code = await generateUniqueCode(env);
    row = emptyProgress(account, code, nowIso);
    await putProgress(env, row);
    await env.REFERRAL_KV.put(`code:${code}`, account);
  }

  // 1) Lien de parrainage : d'abord celui établi à la création du passe…
  let refCode = await env.REFERRAL_KV.get(`referee:${account}`);
  // …sinon le code fourni dans le corps (legacy) : une seule fois, jamais
  // soi-même, et le code doit exister.
  if (!refCode) {
    const bodyCode = typeof body.referrerCode === 'string'
      ? body.referrerCode.trim().toLowerCase()
      : '';
    if (/^[a-z0-9]{8}$/.test(bodyCode) && bodyCode !== row.referralCode) {
      const parentAccount = await env.REFERRAL_KV.get(`code:${bodyCode}`);
      if (parentAccount && parentAccount !== account) {
        refCode = bodyCode;
        await env.REFERRAL_KV.put(`referee:${account}`, bodyCode);
      }
    }
  }

  // 2) Crédit de la complétion (le test du filleul vient de se terminer),
  //    en préservant l'horodatage de la première complétion.
  if (refCode && refCode !== row.referralCode) {
    const done = await env.REFERRAL_KV.get(`ref:${refCode}:${account}`);
    if (!done) await env.REFERRAL_KV.put(`ref:${refCode}:${account}`, nowIso);
  }

  return buildProgressResponse(env, origin, row);
}

/** GET /progress — état courant + transitions de stage (autorité serveur). */
async function handleProgress(env, origin, account) {
  const row = await getProgress(env, account);
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
  const row = await getProgress(env, account);
  if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);

  const completed = await countCompletedReferrals(env, row.referralCode);
  if (completed < REQUIRED_REFERRALS) {
    return json({ error: 'Palier parrainage non terminé' }, 403, origin);
  }
  if (!row.instagramSubmittedAt) {
    row.instagramHandle = handle;
    row.instagramSubmittedAt = isoNow();
    row.stage = 3;
    await putProgress(env, row);
  }
  return buildProgressResponse(env, origin, row);
}

/**
 * Calcule l'état renvoyé au client ET applique les transitions de stage :
 *   →3 : ≥REQUIRED filleuls ont terminé leur test
 *   3→4 : pseudo Insta soumis depuis plus de INSTA_UNLOCK_DELAY_MINUTES et
 *         non invalidé manuellement (instagramVerified !== false).
 */
async function buildProgressResponse(env, origin, row) {
  const completedCount = await countCompletedReferrals(env, row.referralCode);
  let stage = row.stage;
  let dirty = false;

  if (stage < 3 && completedCount >= REQUIRED_REFERRALS) {
    stage = 3;
    row.stage = 3;
    dirty = true;
  }

  if (stage === 3 && row.instagramSubmittedAt && row.instagramVerified !== false) {
    const delayMin = parseInt(env.INSTA_UNLOCK_DELAY_MINUTES || '120', 10);
    const elapsedMs = Date.now() - new Date(row.instagramSubmittedAt).getTime();
    if (elapsedMs >= delayMin * 60000) {
      stage = 4;
      row.stage = 4;
      row.unlockedAt = isoNow();
      dirty = true;
    }
  }

  if (dirty) await putProgress(env, row);

  return json({
    stage,
    referralCode: row.referralCode,
    // completedReferrals = filleuls ayant réellement terminé leur test.
    completedReferrals: completedCount,
    requiredReferrals: REQUIRED_REFERRALS,
    instagramHandle: row.instagramHandle || null,
    instagramSubmitted: !!row.instagramSubmittedAt,
  }, 200, origin);
}

/** Code court a-z0-9 (8 chars, ~41 bits) unique en KV. */
async function generateUniqueCode(env) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  for (let attempt = 0; attempt < 6; attempt++) {
    const bytes = new Uint8Array(8);
    crypto.getRandomValues(bytes);
    let code = '';
    for (const b of bytes) code += alphabet[b % alphabet.length];
    const exists = await env.REFERRAL_KV.get(`code:${code}`);
    if (!exists) return code;
  }
  throw new Error('Impossible de générer un code unique');
}

function isoNow() {
  return new Date().toISOString();
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
