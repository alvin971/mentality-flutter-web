/**
 * Cloudflare Worker — Referral / déblocage des résultats par paliers.
 *
 * Le résultat du test complet est retenu derrière 3 paliers séquentiels :
 *   stage 1 : inviter des amis (lien /invite?ref=<code> lié au token)
 *   stage 2 : (affichage) attendre que les filleuls TERMINENT leur test
 *   stage 3 : délai d'attente serveur (UNLOCK_DELAY_MINUTES) avant publication
 *   stage 4 : résultat débloqué
 *
 * Endpoints (auth = header X-Mentality-Token, signature Ed25519 re-vérifiée
 * serveur via workers/_shared/token_verify.js — cf. r2-upload) :
 *   POST /link            → lie ce token à un parrain (appelé par le site à la
 *                           CRÉATION du passe : le filleul arrive via
 *                           /inscription?ref=<code>, liaison invisible).
 *                           NE crédite PAS la complétion.
 *   POST /progress/init   → crée l'état (idempotent). NE CRÉDITE RIEN : ouvrir
 *                           un écran ne doit jamais valider un parrainage.
 *   POST /complete        → SEULE porte de crédit : déclare le test terminé
 *                           (charge utile de session vérifiée pour plausibilité)
 *                           → crédite le parrain issu de /link. Idempotent.
 *   GET  /progress        → état courant + transitions de stage (autorité
 *                           serveur, jamais le client).
 *   POST /instagram       → PIERRE TOMBALE (cf. plus bas) : accepté, ignoré.
 *   GET  /resolve/<code>  → public : le code referral existe-t-il ? (landing)
 *
 * Stockage : Cloudflare KV (binding REFERRAL_KV) — aucun secret externe.
 * Var : UNLOCK_DELAY_MINUTES (durée du palier 3, en minutes).
 *
 * Modèle de clés KV :
 *   progress:<account>        → JSON de l'état du parrain (voir emptyProgress)
 *   code:<referralCode>       → <account> propriétaire du code (unicité + resolve)
 *   referee:<account>         → <referrerCode> (écrit UNE fois : 1 filleul = 1
 *                               parrain — via /link à la création du passe, ou
 *                               /progress/init legacy)
 *   ref:<referrerCode>:<acct> → timestamp ISO (une entrée = un filleul ayant fini)
 *   completed:<account>       → JSON de la preuve de complétion (1re fois gagne)
 *
 * ANONYMAT : seule la partition account = SHA256(nonce)[:32] est stockée —
 * plus AUCUNE donnée personnelle. Le pseudo Instagram, seule donnée nominative
 * qu'ait connue ce worker, a été supprimé du code ET des lignes déjà en
 * production (cf. scripts/purge-instagram.js).
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
      if (request.method === 'POST' && path === '/complete') {
        let body;
        try { body = await request.json(); } catch {
          return json({ error: 'Corps JSON invalide' }, 400, origin);
        }
        return await handleComplete(env, origin, account, body);
      }
      if (request.method === 'GET' && path === '/progress') {
        return await handleProgress(env, origin, account);
      }
      // ─── PIERRE TOMBALE — à supprimer après la release d'août 2026 ────────
      // Les builds déjà installées (TestFlight) postent encore ce endpoint.
      // Sans cette route elles recevraient un 404, que leur client traduit en
      // « erreur réseau » PERMANENTE sur la dernière porte du parcours.
      // On accepte donc la requête, on IGNORE le pseudo — rien n'est stocké,
      // c'est tout l'objet de ce changement — et on renvoie l'état courant.
      if (request.method === 'POST' && path === '/instagram') {
        try { await request.json(); } catch { /* corps ignoré, quel qu'il soit */ }
        const row = await getProgress(env, account);
        if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);
        return await buildProgressResponse(env, origin, row);
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
    stage3StartedAt: null, // posé UNE SEULE FOIS au passage en stage 3
    unlockedAt: null,
    createdAt: nowIso,
  };
}

// Champs Instagram hérités. Conservés ici pour être SUPPRIMÉS à chaque écriture.
const REMOVED_FIELDS = ['instagramHandle', 'instagramSubmittedAt', 'instagramVerified'];

async function getProgress(env, account) {
  const raw = await env.REFERRAL_KV.get(`progress:${account}`);
  return raw ? JSON.parse(raw) : null;
}

async function putProgress(env, row) {
  // Filet RGPD : toute écriture purge les champs Instagram hérités, y compris
  // sur une ligne relue telle quelle depuis KV. Aucun chemin de code oublié ne
  // peut les faire survivre. La migration de stage3StartedAt lit
  // instagramSubmittedAt AVANT cet appel (cf. buildProgressResponse).
  for (const f of REMOVED_FIELDS) delete row[f];
  await env.REFERRAL_KV.put(`progress:${row.account}`, JSON.stringify(row));
}

/** Un horodatage ISO exploitable ? (miroir exact de scripts/purge-instagram.js) */
function isValidIso(s) {
  return typeof s === 'string' && Number.isFinite(Date.parse(s));
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
 * POST /progress/init — crée l'état de suivi (idempotent) et enregistre, le cas
 * échéant, le lien de parrainage legacy (`body.referrerCode`, anciennes builds
 * sans /link). NE CRÉDITE JAMAIS : cet endpoint est appelé par le simple
 * AFFICHAGE de l'écran des missions, et ouvrir un écran ne doit pas valider un
 * parrainage. Le crédit passe exclusivement par /complete.
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

  // Lien legacy (build sans /link) : on LIE, on ne crédite pas.
  const existing = await env.REFERRAL_KV.get(`referee:${account}`);
  if (!existing) {
    const bodyCode = typeof body.referrerCode === 'string'
      ? body.referrerCode.trim().toLowerCase()
      : '';
    if (/^[a-z0-9]{8}$/.test(bodyCode) && bodyCode !== row.referralCode) {
      const parentAccount = await env.REFERRAL_KV.get(`code:${bodyCode}`);
      if (parentAccount && parentAccount !== account) {
        await env.REFERRAL_KV.put(`referee:${account}`, bodyCode);
      }
    }
  }

  return buildProgressResponse(env, origin, row);
}

// Plausibilité d'une session de test complète. Un vrai passage dure ~60-90 min
// et couvre les 12 sous-tests ; ces seuils écartent les déclarations grossières
// (un écran ouvert, une session vide) sans pénaliser un passage rapide légitime.
const MIN_SUBTESTS_COMPLETED = 10;
const MIN_TEST_DURATION_S = 600; // 10 min plancher, très en dessous du réel

/**
 * POST /complete — SEULE porte par laquelle un parrainage est crédité.
 *
 * Le filleul déclare son test terminé avec un résumé de session, vérifié pour
 * plausibilité. La preuve est stockée (`completed:<account>`, première fois
 * gagnante) puis le parrain issu de /link est crédité — une seule fois.
 *
 * ⚠️ LIMITE ASSUMÉE : cette preuve reste DÉCLARÉE PAR LE CLIENT. Elle écarte la
 * fraude opportuniste (ouvrir un écran, enchaîner des passes vides) mais pas un
 * attaquant qui forge la requête. La preuve infalsifiable arrive avec le
 * stockage serveur des résultats (R2/D1) : le crédit sera alors conditionné à
 * l'EXISTENCE d'un résultat côté serveur. Cet endpoint est le point d'ancrage
 * prévu pour ce durcissement.
 */
async function handleComplete(env, origin, account, body) {
  const row = await getProgress(env, account);
  if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);

  const already = await env.REFERRAL_KV.get(`completed:${account}`);
  if (!already) {
    const subtests = Number(body.subtestsCompleted);
    const durationS = Number(body.durationSeconds);
    if (!Number.isFinite(subtests) || subtests < MIN_SUBTESTS_COMPLETED ||
        !Number.isFinite(durationS) || durationS < MIN_TEST_DURATION_S) {
      return json({ error: 'Session non plausible', credited: false }, 400, origin);
    }
    await env.REFERRAL_KV.put(`completed:${account}`, JSON.stringify({
      at: isoNow(),
      subtests,
      durationS,
    }));
  }

  // Crédit du parrain — uniquement d'après le lien serveur, jamais le client.
  const refCode = await env.REFERRAL_KV.get(`referee:${account}`);
  if (refCode && refCode !== row.referralCode) {
    const done = await env.REFERRAL_KV.get(`ref:${refCode}:${account}`);
    if (!done) await env.REFERRAL_KV.put(`ref:${refCode}:${account}`, isoNow());
  }

  return buildProgressResponse(env, origin, row);
}

/** GET /progress — état courant + transitions de stage (autorité serveur). */
async function handleProgress(env, origin, account) {
  const row = await getProgress(env, account);
  if (!row) return json({ error: 'Aucun suivi — appeler /progress/init' }, 404, origin);
  return buildProgressResponse(env, origin, row);
}

/**
 * Calcule l'état renvoyé au client ET applique les transitions de stage :
 *   →3  : ≥REQUIRED filleuls ont terminé leur test
 *   3→4 : le délai UNLOCK_DELAY_MINUTES s'est écoulé depuis stage3StartedAt.
 *
 * AUTORITÉ SERVEUR : ces transitions n'existent qu'ici. Le client ne débloque
 * jamais de lui-même, quelle que soit l'heure de son téléphone.
 */
async function buildProgressResponse(env, origin, row) {
  const completedCount = await countCompletedReferrals(env, row.referralCode);
  const cfg = delayConfig(env);
  const delayMin = cfg.minutes;
  const now = Date.now();
  let dirty = false;

  // (a) Le stage 4 est DÉFINITIF : ni relecture, ni recalcul, ni
  //     re-verrouillage. Un déblocage acquis l'est pour de bon.
  if (row.stage < 4) {
    if (row.stage < 3 && completedCount >= REQUIRED_REFERRALS) {
      row.stage = 3;
      dirty = true;
    }

    // POINT D'ANCRAGE UNIQUE du délai. Les trois situations y convergent, et le
    // garde `!isValidIso` garantit qu'il n'est posé QU'UNE FOIS :
    //   · promotion fraîche ci-dessus            → maintenant
    //   · (b) ligne héritée avec instagramSubmittedAt → cette date, pour que
    //         l'attente DÉJÀ ÉCOULÉE ne soit pas perdue (filet si la purge KV
    //         n'a pas encore tourné — cf. scripts/purge-instagram.js)
    //   · (c) ligne héritée sans rien            → maintenant
    if (row.stage === 3 && !isValidIso(row.stage3StartedAt)) {
      row.stage3StartedAt = isValidIso(row.instagramSubmittedAt)
        ? row.instagramSubmittedAt
        : isoNow();
      dirty = true;
    }

    if (row.stage === 3 && now - Date.parse(row.stage3StartedAt) >= delayMin * 60000) {
      row.stage = 4;
      row.unlockedAt = isoNow();
      dirty = true;
    }
  }

  // AUTORITÉ SERVEUR sur le temps : secondsRemaining est calculé ICI, sur
  // l'horloge du worker. Le client ne le recalcule jamais depuis sa propre
  // date — sinon avancer l'horloge du téléphone débloquerait le résultat.
  let unlockAt = null;
  let secondsRemaining = 0;
  let dayIndex = null;
  if (row.stage === 3) {
    const startMs = Date.parse(row.stage3StartedAt);
    const endMs = startMs + delayMin * 60000;
    unlockAt = new Date(endMs).toISOString();
    secondsRemaining = Math.max(0, Math.ceil((endMs - now) / 1000));
    // Jour courant de l'événement d'attente, MÊME AUTORITÉ que
    // secondsRemaining : dérivé de l'ancre sur l'horloge du worker.
    //
    // Un « jour » vaut 1/8 du délai réel : en production (11520 min) c'est
    // exactement 24 h, et en recette (délai raccourci) les 8 jours restent
    // traversables au lieu de rester figés au jour 1.
    //
    // Le clamp absorbe les deux bords : une ancre légèrement dans le futur
    // (dérive d'horloge entre instances) comme un délai déjà dépassé alors
    // que la promotion en stage 4 n'a pas encore été écrite.
    const dayMs = Math.max(1, Math.round((delayMin * 60000) / 8));
    dayIndex = Math.min(9, Math.max(1, Math.floor((now - startMs) / dayMs) + 1));
  } else if (row.stage >= 4) {
    unlockAt = row.unlockedAt || null;
    // Débloqué : l'événement est derrière, tout est ouvert. INCONDITIONNEL —
    // une ligne héritée en stage 4 n'a pas forcément d'ancre (le bloc
    // d'ancrage est court-circuité par `row.stage < 4`), et Date.parse(null)
    // vaudrait NaN, sérialisé silencieusement en null.
    dayIndex = 9;
  }

  if (dirty) await putProgress(env, row);

  return json({
    stage: row.stage,
    referralCode: row.referralCode,
    // completedReferrals = filleuls ayant réellement terminé leur test.
    completedReferrals: completedCount,
    requiredReferrals: REQUIRED_REFERRALS,
    // `null` tant que stage < 3 : c'est CE champ, et non secondsRemaining == 0
    // (qui vaut aussi bien « pas commencé » que « terminé »), qui dit au client
    // si un compte à rebours s'applique.
    unlockAt,
    secondsRemaining,
    // Jour courant de l'événement des 8 jours : 1..8 pendant l'attente, 9 une
    // fois débloqué, `null` tant qu'elle n'a pas commencé — même sémantique de
    // discriminant qu'unlockAt. Le client ne le dérive JAMAIS de son horloge :
    // c'est ici, et nulle part ailleurs, que le jour est décidé.
    dayIndex,
    displayDelayDays: cfg.displayDelayDays,
    // Alimente la bannière « MODE TEST — délai réel : N min ». Constante de
    // déploiement, identique pour tout le monde : rien de sensible.
    delayMinutes: delayMin,
    debugDelayOverride: cfg.debugDelayOverride,
    // COMPAT — à retirer avec la pierre tombale /instagram : les builds déjà
    // installées basculent ainsi sur leur carte « en cours », sémantiquement
    // équivalente à la nouvelle attente, au lieu d'un formulaire mort.
    instagramSubmitted: row.stage >= 3,
  }, 200, origin);
}

/** Délai par défaut si la variable est absente ou illisible : 8 jours. */
const DEFAULT_UNLOCK_DELAY_MINUTES = 11520;

/**
 * Délai RÉEL (minutes) et délai AFFICHÉ (jours).
 *
 * Les deux ne peuvent diverger que par DEBUG_DISPLAY_DELAY_DAYS, qui sert à
 * recetter le rendu « 8 jours » en attendant une minute. Dans ce cas le worker
 * le SIGNALE (debugDelayOverride), et le client affiche une bannière
 * incontournable : un délai de test ne doit jamais passer inaperçu en prod.
 */
function delayConfig(env) {
  const parsed = parseInt(env.UNLOCK_DELAY_MINUTES ?? '', 10);
  const minutes = Number.isFinite(parsed) && parsed >= 0
    ? parsed
    : DEFAULT_UNLOCK_DELAY_MINUTES;

  const rawDbg = env.DEBUG_DISPLAY_DELAY_DAYS;
  const dbg = (rawDbg === undefined || rawDbg === null || rawDbg === '')
    ? NaN
    : parseInt(rawDbg, 10);
  if (Number.isFinite(dbg) && dbg >= 0) {
    return { minutes, displayDelayDays: dbg, debugDelayOverride: true };
  }

  // ARRONDI AU SUPÉRIEUR, jamais au plus proche : le nombre de jours annoncé
  // doit toujours être ≥ au délai réel. Au plus proche, un délai de 8 j 10 h
  // annoncerait « 8 jours » alors que le compte à rebours tournerait encore le
  // 8e jour — l'annonce contredirait le compteur affiché juste en dessous.
  return {
    minutes,
    displayDelayDays: Math.max(0, Math.ceil(minutes / 1440)),
    debugDelayOverride: false,
  };
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
