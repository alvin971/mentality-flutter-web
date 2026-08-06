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
 *   POST /progress/init   → crée l'état (idempotent). Ouvrir un écran ne
 *                           VALIDE jamais un parrainage de lui-même.
 *   POST /complete        → déclare le test terminé (charge utile vérifiée
 *                           pour plausibilité À CHAQUE appel + cohérence
 *                           temporelle avec l'historique serveur). Idempotent.
 *
 *   CRÉDIT-JONCTION : le crédit du parrain est posé par maybeCredit(), appelé
 *   par les TROIS endpoints ci-dessus — dès que (lien ∧ complétion plausible)
 *   existent tous deux côté serveur, quel que soit l'ordre d'arrivée. Aucun
 *   endpoint ne crédite sans cette double preuve.
 *   GET  /progress        → état courant + transitions de stage (autorité
 *                           serveur, jamais le client).
 *   POST /instagram       → PIERRE TOMBALE (cf. plus bas) : accepté, ignoré.
 *   GET  /resolve/<code>  → public : le code referral existe-t-il ? (landing)
 *
 * Stockage : Cloudflare KV (binding REFERRAL_KV) — aucun secret externe.
 * Var : UNLOCK_DELAY_MINUTES (durée du palier 3, en minutes).
 *
 * Modèle de clés KV :
 *   progress:<account>        → JSON de l'état du parrain (voir emptyProgress ;
 *                               `firstSeenVia` depuis le LOT 0 anti-faux-test)
 *   code:<referralCode>       → <account> propriétaire du code (unicité + resolve)
 *   referee:<account>         → lien filleul→parrain, écrit UNE fois (1 filleul
 *                               = 1 parrain). Format neuf : JSON {code, at} ;
 *                               legacy : <referrerCode> brut (cf. parseRefereeLink)
 *   ref:<referrerCode>:<acct> → timestamp ISO (une entrée = un filleul ayant fini)
 *   completed:<account>       → JSON de la preuve de complétion (1re fois gagne)
 *
 * ANONYMAT : seule la partition account = SHA256(nonce)[:32] est stockée —
 * plus AUCUNE donnée personnelle. Le pseudo Instagram, seule donnée nominative
 * qu'ait connue ce worker, a été supprimé du code ET des lignes déjà en
 * production (cf. scripts/purge-instagram.js).
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';
import { checkOrigin } from '../_shared/origin_policy.js';

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

    // Politique d'Origin explicite (workers/_shared/origin_policy.js) :
    // absent = app native (compensation : token exigé derrière) ; non listé = 403.
    const o = checkOrigin(request, ALLOWED_ORIGINS);
    const origin = o.origin;
    if (!o.allowed) {
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

function emptyProgress(account, code, nowIso, firstSeenVia) {
  return {
    account,
    referralCode: code,
    stage: 1,
    stage3StartedAt: null, // posé UNE SEULE FOIS au passage en stage 3
    unlockedAt: null,
    createdAt: nowIso,
    // Endpoint qui a matérialisé la ligne ('init' | 'complete'). PAS une base
    // de rejet (l'app peut créer la ligne après la fin du test, en course avec
    // un /complete rejoué — cf. handleComplete) : c'est un matériau
    // d'observation pour le barème du LOT 4. Lignes legacy : champ absent.
    firstSeenVia,
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
 * Le lien est HORODATÉ (JSON {code, at}) : la date sert au contrôle de
 * cohérence temporelle de /complete. Le lien seul ne crédite rien — le crédit
 * n'existe que par la jonction (maybeCredit) avec une complétion plausible.
 */
async function handleLink(env, origin, account, body) {
  const code = typeof body.referrerCode === 'string'
    ? body.referrerCode.trim().toLowerCase()
    : '';
  if (!/^[a-z0-9]{8}$/.test(code)) {
    return json({ linked: false, error: 'Code invalide' }, 400, origin);
  }
  const existing = parseRefereeLink(await env.REFERRAL_KV.get(`referee:${account}`));
  if (existing) {
    // Rattrapage : si la complétion plausible est arrivée depuis, la jonction
    // matérialise le crédit — le lien, lui, ne bouge pas (first-write-wins).
    await maybeCredit(env, account);
    return json({ linked: existing.code === code }, 200, origin);
  }
  const owner = await env.REFERRAL_KV.get(`code:${code}`);
  // Code inconnu ou auto-parrainage : réponse 200 neutre (rien à exploiter).
  if (!owner || owner === account) return json({ linked: false }, 200, origin);
  await env.REFERRAL_KV.put(
    `referee:${account}`,
    JSON.stringify({ code, at: isoNow(), via: 'link' }),
  );
  await maybeCredit(env, account); // jonction : complete-puis-link
  return json({ linked: true }, 200, origin);
}

/**
 * POST /progress/init — crée l'état de suivi (idempotent) et enregistre, le cas
 * échéant, le lien de parrainage (`body.referrerCode` — c'est le chemin RÉEL
 * des builds actuelles, posé par l'écran des missions APRÈS le /complete du
 * dernier sous-test). Init ne VALIDE jamais une complétion de lui-même :
 * ouvrir un écran sans preuve `completed:` plausible ne crédite toujours rien.
 * Il ne peut que MATÉRIALISER, via la jonction, un crédit dont la double
 * preuve (lien ∧ complétion plausible) existe déjà côté serveur — c'est ce qui
 * répare le flux nominal de l'app et rattrape les crédits perdus.
 */
async function handleInit(env, origin, account, body) {
  const nowIso = isoNow();
  let row = await getProgress(env, account);
  if (!row) {
    const code = await generateUniqueCode(env);
    row = emptyProgress(account, code, nowIso, 'init');
    await putProgress(env, row);
    await env.REFERRAL_KV.put(`code:${code}`, account);
  }

  // Lien (build sans /link) : on LIE, avec horodatage. First-write-wins.
  const existing = await env.REFERRAL_KV.get(`referee:${account}`);
  if (!existing) {
    const bodyCode = typeof body.referrerCode === 'string'
      ? body.referrerCode.trim().toLowerCase()
      : '';
    if (/^[a-z0-9]{8}$/.test(bodyCode) && bodyCode !== row.referralCode) {
      const parentAccount = await env.REFERRAL_KV.get(`code:${bodyCode}`);
      if (parentAccount && parentAccount !== account) {
        await env.REFERRAL_KV.put(
          `referee:${account}`,
          JSON.stringify({ code: bodyCode, at: nowIso, via: 'init' }),
        );
      }
    }
  }

  // Jonction : matérialise le crédit si (lien ∧ complétion plausible) existent.
  await maybeCredit(env, account);

  return buildProgressResponse(env, origin, row);
}

// Plausibilité d'une session de test complète. Un vrai passage dure ~60-90 min
// et couvre les 12 sous-tests ; ces seuils écartent les déclarations grossières
// (un écran ouvert, une session vide) sans pénaliser un passage rapide légitime.
const MIN_SUBTESTS_COMPLETED = 10;
// 5 min. L'ancien plancher de 10 min rejetait des passations RÉELLES mais
// rapides — d'autant plus depuis la suppression des récapitulatifs de fin de
// sous-test, qui a raccourci le parcours. Le refus étant alors avalé en
// silence par le client, le parrain n'était jamais crédité et personne ne le
// savait. 5 min reste très en dessous d'un passage sincère (12 sous-tests,
// dont plusieurs chronométrés) tout en écartant les déclarations grossières.
const MIN_TEST_DURATION_S = 300;

// Marge du contrôle de cohérence temporelle : dérive d'horloge entre instances
// + latence réseau. Le contrôle ne rejette que l'IMPOSSIBLE au-delà de cette
// marge (durée déclarée > âge réel du compte), jamais le cas limite.
const TEMPORAL_MARGIN_S = 120;

/** Seuils de plausibilité d'une session — appliqués à CHAQUE évaluation. */
function isPlausibleSession(subtests, durationS) {
  return Number.isFinite(subtests) && subtests >= MIN_SUBTESTS_COMPLETED &&
         Number.isFinite(durationS) && durationS >= MIN_TEST_DURATION_S;
}

/**
 * Lit une valeur `referee:<account>` sous ses DEUX formats :
 *   - JSON `{code, at, via}` — écrit depuis le LOT 0 anti-faux-test.
 *     `via` = l'endpoint qui a posé le lien : 'link' (site, à la CRÉATION du
 *     passe — donc forcément AVANT tout test) ou 'init' (app — peut arriver
 *     APRÈS la fin du test, voire en course avec un /complete rejoué) ;
 *   - string legacy `<code>` (8 chars) — écrite avant → `at`/`via` null.
 * Discrimination sûre : un code est [a-z0-9]{8}, jamais `{`.
 * Renvoie { code, at, via } ou null si la valeur est absente/illisible.
 */
function parseRefereeLink(raw) {
  if (!raw) return null;
  if (raw[0] === '{') {
    try {
      const o = JSON.parse(raw);
      if (o && typeof o.code === 'string' && /^[a-z0-9]{8}$/.test(o.code)) {
        return {
          code: o.code,
          at: isValidIso(o.at) ? o.at : null,
          via: o.via === 'link' || o.via === 'init' ? o.via : null,
        };
      }
    } catch { /* illisible → null */ }
    return null;
  }
  return /^[a-z0-9]{8}$/.test(raw) ? { code: raw, at: null, via: null } : null;
}

/**
 * CRÉDIT-JONCTION — LE seul point du worker où un parrain est crédité.
 *
 * Le crédit est posé dès que les DEUX preuves existent côté serveur, quel que
 * soit l'ordre d'arrivée :
 *   lien filleul→parrain (`referee:`) ∧ complétion PLAUSIBLE (`completed:`,
 *   revalidée ici à CHAQUE passage — un enregistrement implausible, quel qu'en
 *   soit le chemin d'écriture, ne crédite jamais).
 *
 * Pourquoi une jonction : le crédit ne vivait que dans /complete, or le flux
 * nominal de l'app pose le lien APRÈS la déclaration de fin (l'écran des
 * missions envoie /progress/init après le /complete du dernier sous-test) —
 * le crédit n'était donc JAMAIS posé pour un filleul app. La jonction répare
 * ce flux et rattrape rétroactivement les filleuls existants à leur prochain
 * passage sur n'importe lequel des trois endpoints.
 *
 * Write-once : `ref:<code>:<account>` n'est jamais réécrit — pas de double
 * crédit, et le premier horodatage fait foi.
 */
async function maybeCredit(env, account) {
  const link = parseRefereeLink(await env.REFERRAL_KV.get(`referee:${account}`));
  if (!link) return;
  const rawDone = await env.REFERRAL_KV.get(`completed:${account}`);
  if (!rawDone) return;
  let rec;
  try { rec = JSON.parse(rawDone); } catch { return; }
  if (!isPlausibleSession(Number(rec.subtests), Number(rec.durationS))) return;
  const owner = await env.REFERRAL_KV.get(`code:${link.code}`);
  if (!owner || owner === account) return; // code orphelin / auto-parrainage
  const key = `ref:${link.code}:${account}`;
  if ((await env.REFERRAL_KV.get(key)) !== null) return; // write-once
  await env.REFERRAL_KV.put(key, isoNow());
}

/**
 * POST /complete — déclare le test terminé.
 *
 * La plausibilité est évaluée À CHAQUE appel : sur le CORPS en première
 * déclaration (avec, en plus, la cohérence temporelle contre l'historique
 * serveur), sur la preuve STOCKÉE en rejeu (dans maybeCredit — un rejeu au
 * corps vide ne saute plus aucun seuil, il ne peut que matérialiser un crédit
 * dont la double preuve existe déjà).
 *
 * CONTRAT CLIENT DÉPLOYÉ (unlock_service.dart) : tout 4xx est mémorisé comme
 * refus DÉFINITIF. Le 400 est donc réservé aux déclarations mathématiquement
 * fausses en PREMIÈRE déclaration ; un rejeu ne renvoie jamais 400 ; toute
 * erreur transitoire doit rester un 5xx (try/catch global).
 *
 * ⚠️ LIMITE ASSUMÉE : cette preuve reste DÉCLARÉE PAR LE CLIENT. Elle écarte la
 * fraude opportuniste (ouvrir un écran, enchaîner des passes vides) mais pas un
 * attaquant qui forge la requête. La preuve infalsifiable arrive avec la
 * télémétrie serveur (LOT 2-3) : le crédit sera alors conditionné à
 * l'EXISTENCE d'un résultat côté serveur. Cet endpoint est le point d'ancrage
 * prévu pour ce durcissement.
 */
async function handleComplete(env, origin, account, body) {
  let row = await getProgress(env, account);
  const already = await env.REFERRAL_KV.get(`completed:${account}`);

  if (!already) {
    // ── Première déclaration : validation sur le CORPS ──────────────────────
    const subtests = Number(body.subtestsCompleted);
    const durationS = Number(body.durationSeconds);
    if (!isPlausibleSession(subtests, durationS)) {
      // AVANT toute écriture : un /complete refusé ne laisse derrière lui NI
      // ligne de suivi NI code d'invitation (préparation de comptes-mules).
      return json({ error: 'Session non plausible', credited: false }, 400, origin);
    }

    // ── Cohérence temporelle : l'âge du lien posé PAR LE SITE (/link) ───────
    // Un lien `via:'link'` est posé à la CRÉATION du passe : le badge précède
    // nécessairement le test, donc une durée déclarée supérieure à l'âge de ce
    // lien est mathématiquement fausse (attaque n°2 : link → complete éclair).
    //
    // POURQUOI SEULEMENT `via:'link'` — un 400 est un refus DÉFINITIF côté
    // client, donc AUCUNE base ambiguë n'est acceptable :
    //   · les lignes de suivi et les liens `via:'init'` sont posés par l'APP,
    //     parfois APRÈS la fin du test — et complete_test_results_page lance
    //     retryPending(), isLocked() et getProgress() EN CONCURRENCE (initState
    //     sans await) : si le /complete initial a échoué, un init peut créer
    //     ligne + lien quelques secondes AVANT le /complete rejoué. Rejeter sur
    //     cet âge condamnerait définitivement un utilisateur honnête ;
    //   · liens/lignes legacy sans date ni marqueur : origine inconnue.
    // Le signal ambigu (durée > âge côté app) reviendra au LOT 4 comme points
    // de suspicion (« marqué », silencieux) — jamais comme refus.
    const link = parseRefereeLink(await env.REFERRAL_KV.get(`referee:${account}`));
    if (link && link.at && link.via === 'link') {
      const linkAgeS = (Date.now() - Date.parse(link.at)) / 1000;
      if (durationS > linkAgeS + TEMPORAL_MARGIN_S) {
        return json(
          { error: 'Durée déclarée incompatible avec la date de création du passe', credited: false },
          400, origin,
        );
      }
    }

    // ── Écritures, APRÈS validation seulement ───────────────────────────────
    // Le suivi est créé à la volée si besoin : l'app déclare la fin de test
    // dès le dernier sous-test, AVANT tout écran de missions — renvoyer 404
    // ici perdrait le parrainage d'un tout premier test.
    if (!row) {
      const code = await generateUniqueCode(env);
      row = emptyProgress(account, code, isoNow(), 'complete');
      await putProgress(env, row);
      await env.REFERRAL_KV.put(`code:${code}`, account);
    }
    await env.REFERRAL_KV.put(`completed:${account}`, JSON.stringify({
      at: isoNow(),
      subtests,
      durationS,
    }));
  } else if (!row) {
    // Rejeu d'un compte complété dont la ligne a disparu (théorique) : la
    // preuve stockée fait foi, on recrée le suivi sans re-contrôler le corps.
    const code = await generateUniqueCode(env);
    row = emptyProgress(account, code, isoNow(), 'complete');
    await putProgress(env, row);
    await env.REFERRAL_KV.put(`code:${code}`, account);
  }
  // En rejeu (`already`), le corps est IGNORÉ : la revalidation « à chaque
  // appel » porte sur la preuve STOCKÉE, dans maybeCredit. Jamais de 400 ici.

  // Jonction : crédite si (lien ∧ complétion plausible) existent tous deux.
  await maybeCredit(env, account);

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
  // FAILLE 11 (compte-mule) : un code ne compte ses filleuls que si son
  // PROPRIÉTAIRE a lui-même une preuve de complétion. Les `ref:` s'accumulent
  // quand même (rien n'est perdu) ; comptage et transitions reprennent dès que
  // `completed:<owner>` existe. Un stage 4 acquis n'est JAMAIS rétrogradé.
  const ownerCompleted =
    (await env.REFERRAL_KV.get(`completed:${row.account}`)) !== null;
  const rawCount = await countCompletedReferrals(env, row.referralCode);
  const completedCount = ownerCompleted ? rawCount : 0;
  const cfg = delayConfig(env);
  const delayMin = cfg.minutes;
  const now = Date.now();
  let dirty = false;

  // (a) Le stage 4 est DÉFINITIF : ni relecture, ni recalcul, ni
  //     re-verrouillage. Un déblocage acquis l'est pour de bon.
  // (b) Aucune transition tant que le propriétaire n'a pas terminé son propre
  //     test (gate faille 11 ci-dessus) — gèle <3→3 ET 3→4.
  if (row.stage < 4 && ownerCompleted) {
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
  // Le garde isValidIso protège le seul cas où une ligne stage 3 peut arriver
  // ici SANS ancre : gate propriétaire actif (bloc d'ancrage court-circuité).
  // Elle répond alors comme « attente pas commencée » — on ne pose PAS d'ancre
  // pendant le gel, sinon le délai de 8 jours s'écoulerait gratuitement.
  if (row.stage === 3 && isValidIso(row.stage3StartedAt)) {
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
    // completedReferrals = filleuls ayant réellement terminé leur test —
    // comptés seulement si le propriétaire a terminé le sien (gate faille 11).
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
