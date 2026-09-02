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
 * Claims compactes — voir validateClaims() / validatePlan() et
 * lib/core/services/token_issuer.dart (miroir exact côté client) :
 *   sv 2 : {s, y, m, r, d, n, sv}             passe historique. TOUJOURS émis
 *          quand le corps de la requête n'a AUCUN champ de plan : c'est le
 *          comportement de l'inscription EN PRODUCTION, il ne bouge pas.
 *   sv 3 : {s, y, m, r, p, cc, cv, d, n, sv}  passe porteur du plan choisi sur
 *          le site et de la preuve de consentement au corpus vocal :
 *            p  : 'free' | 'paid'  (plan du passe)
 *            cc : booléen          (consentement au corpus vocal)
 *            cv : version des textes légaux acceptés (∈ LEGAL_VERSIONS)
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
 * ANONYMAT : aucun log par requête (IP/timestamp/claims/token), aucun stockage
 * PAR UTILISATEUR. Tout l'état serveur tient dans TROIS familles de clés KV
 * (namespace RATE_KV), toutes AGRÉGÉES ou publiques — rien de rattachable à
 * quiconque, l'engagement d'anonymat est intact :
 *
 *   1. `issue:<n° de tranche>`
 *      Compteur d'émissions par tranche de temps (LOT 0 anti-faux-test) : un
 *      entier, TTL court. Ni IP, ni claims, ni token. Voir checkIssueCap().
 *      Toujours incrémenté quand RATE_KV est lié ; le REFUS au-delà du seuil,
 *      lui, dépend de la var ISSUE_CAP_ENABLED (deux gestes séparés).
 *
 *   2. `consent:<cv>:<p>:<cc>:<jour UTC>:<shard 0-15>`
 *      Compteur d'émissions par version de textes légaux × plan × consentement.
 *      C'est la PREUVE AGRÉGÉE que le consentement a bien été recueilli (RGPD
 *      art. 7(1)) : combien de passes ont été émis sous telle version des
 *      textes, avec ou sans consentement au corpus. Un entier, SANS TTL (une
 *      preuve ne s'auto-détruit pas), sans IP, sans token, sans aucune claim
 *      individuelle — deux personnes du même jour sont indiscernables dedans.
 *      Le shard (1 octet aléatoire & 15) contourne la limite Cloudflare d'une
 *      écriture par seconde et par clé. Voir bumpConsentCounter().
 *
 *   3. `legal:<cv>:{cgu,confidentialite,consent-corpus,sha256}`
 *      Archive des TEXTES acceptés, poussée par scripts/publish-legal.mjs.
 *      Contenu strictement PUBLIC (les pages du site), aucune donnée
 *      personnelle : c'est la contrepartie du `cv` signé dans le token — sans
 *      elle, « la version 2026-09-02.v1 » ne prouverait rien.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';
import { checkOrigin } from '../_shared/origin_policy.js';

const KID = 'k1';

// Version de schéma du passe HISTORIQUE. Émise à l'identique dès que le corps
// n'a aucun champ de plan — c'est l'invariant qui garde l'inscription live en
// vie pendant toute la transition (épinglé par scripts/selftest.mjs).
const SCHEMA_VERSION_LEGACY = 2;

// Première version de schéma qui porte les claims de plan (p, cc, cv). Miroir
// de SCHEMA_VERSION_PLAN dans workers/_shared/token_verify.js.
const SCHEMA_VERSION_PLAN = 3;

// Plans admis pour la claim `p`. Allow-list FERMÉE : toute autre valeur est
// refusée (jamais de repli sur « free », qui vaudrait consentement implicite).
const ALLOWED_PLANS = new Set(['free', 'paid']);

// Âge minimal pour consentir seul au corpus vocal (art. 45 de la loi
// Informatique et Libertés, plancher français de l'art. 8 RGPD).
const CONSENT_MIN_AGE = 15;

// ⚠️ RÉCONCILIATION AVEC LA PRODUCTION (2026-08-07) — cette liste était EN
// RETARD sur le worker déployé, qui accepte déjà les 4 origines ajoutées
// ci-dessous (vérifié origine par origine : GET /geo avec en-tête Origin →
// 200 pour chacune, 403 pour une origine tierce). La dérive vient de ce que
// les workers se déploient À LA MAIN, sans CI : le jour où le site
// mental-et.com a été mis en ligne, l'allow-list a été élargie côté
// Cloudflare sans que le dépôt suive.
//
// NE PAS RETIRER `mental-et.com` : la page d'inscription EN PRODUCTION
// (site Astro, /inscription) POSTe sur ce worker depuis ce domaine. Déployer
// une liste sans elle éteindrait l'inscription — 403 sur toutes les créations
// de passe. Un selftest épingle désormais cette origine (scripts/selftest.mjs).
const ALLOWED_ORIGINS = [
  'https://mental-et.com',
  'https://www.mental-et.com',
  'https://mental-et.pages.dev',
  // Historique (app web retirée, liens déjà partagés) :
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
  'http://localhost:4321',
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

    // Politique d'Origin explicite (workers/_shared/origin_policy.js) : égalité
    // stricte, absent = app native (compensation : plafond d'émission agrégé).
    // CORS ≠ contrôle d'accès (cf. README).
    const o = checkOrigin(request, ALLOWED_ORIGINS);
    const origin = o.origin;
    if (!o.allowed) {
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

/**
 * Plafond d'émission — LOT 0 anti-faux-test.
 *
 * Compteur AGRÉGÉ par tranche de temps : une clé `issue:<n°>`, une valeur
 * entière, un TTL court. Ni IP, ni claims, ni token, ni horodatage individuel
 * — rien de rattachable à quiconque (engagement d'anonymat en tête de fichier).
 *
 * DEUX INTERRUPTEURS DISTINCTS, et c'est volontaire :
 *
 *   1. le binding RATE_KV (wrangler.toml) → COMPTER ou non ;
 *   2. la var ISSUE_CAP_ENABLED === 'true' → REFUSER ou non au-delà du max.
 *
 * Les séparer évite un piège précis : ce plafond n'a JAMAIS tourné en
 * production (RATE_KV est resté commenté depuis toujours, donc le
 * court-circuit `if (!env.RATE_KV) return true` avalait tout). Lier le
 * namespace allumerait sinon d'un coup un seuil jamais éprouvé — 300/heure,
 * une valeur devinée — sur TOUT le trafic, chemin sv 2 historique compris,
 * avec des 429 sur l'inscription live à la clé. On compte donc d'abord, on
 * observe le volume réel, on ajuste ISSUE_MAX_PER_WINDOW, et on ferme
 * seulement ensuite. D'où l'incrément qui a lieu MÊME quand le plafond est
 * inactif : sans compteur, il n'y a rien à observer.
 *
 * FAIL-OPEN si RATE_KV n'est pas lié : le plafond est un frein anti-abus, pas
 * un invariant de sécurité — un binding manquant ne doit pas murer l'inscription.
 *
 * DÉFAUT OUVERT ASSUMÉ, à l'inverse de PAID_PLAN_ENABLED (défaut fermé) : là,
 * une var oubliée ouvrirait la vente ; ici, elle ne ferait que laisser passer
 * du trafic déjà accepté depuis toujours.
 *
 * APPROXIMATIF et assumé : KV n'a pas d'incrément atomique (courses d'écriture
 * concurrentes, propagation inter-colo ~60 s → sous-comptage léger possible).
 * Suffisant comme frein grossier ; l'exactitude demanderait un Durable Object.
 */
async function checkIssueCap(env) {
  if (!env.RATE_KV) return true;
  // Comparaison stricte à 'true', même convention que PAID_PLAN_ENABLED :
  // 'TRUE', '1', '' ou la var absente laissent le plafond INACTIF.
  const plafondActif = env.ISSUE_CAP_ENABLED === 'true';
  const winMin = parsePositiveInt(env.ISSUE_WINDOW_MINUTES, 60);
  const max = parsePositiveInt(env.ISSUE_MAX_PER_WINDOW, 300);
  const bucket = Math.floor(Date.now() / (winMin * 60000));
  const key = `issue:${bucket}`;
  try {
    const cur = parseInt(await env.RATE_KV.get(key), 10) || 0;
    if (plafondActif && cur >= max) return false;
    // Incrément même au-delà du max quand le plafond est inactif : c'est la
    // mesure du dépassement qui dira si le seuil est bien calibré.
    await env.RATE_KV.put(key, String(cur + 1), {
      // ≥ 2 fenêtres pour couvrir la tranche courante entière (minimum KV : 60 s).
      expirationTtl: Math.max(2 * winMin * 60, 120),
    });
  } catch {
    // FAIL-OPEN aussi quand KV JETTE — panne, ou limite Cloudflare
    // « 1 écriture/seconde par clé » dépassée en rafale (toutes les émissions
    // d'une fenêtre écrivent la MÊME clé). Sans ce filet, le worker n'ayant
    // aucun try/catch global, un pic d'inscriptions ou un incident KV
    // transformerait le frein en 500 sur l'émission — l'inverse exact de la
    // politique « un frein anti-abus ne mure jamais l'inscription ».
    // L'émission ratée du compteur = sous-comptage léger, déjà assumé.
  }
  return true;
}

function parsePositiveInt(raw, fallback) {
  const n = parseInt(raw ?? '', 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/**
 * POST / — émet le token (immuable) depuis des claims démographiques larges.
 *
 * Ordre STRICT : validateClaims → validatePlan → checkIssueCap → payload →
 * signature → bumpConsentCounter.
 *   - les deux validations passent avant le plafond : un corps invalide ne
 *     consomme pas le budget d'émission ;
 *   - le compteur de consentement n'est incrémenté qu'APRÈS une signature
 *     réussie : il compte des passes réellement remis, jamais des tentatives.
 */
async function handleIssue(body, env, origin) {
  const v = validateClaims(body);
  if (v.error) return json({ error: v.error }, 400, origin);

  // Plan / consentement (sv 3). Sans champ de plan → { plan: null } → sv 2 à
  // l'identique. Les erreurs portent un `code` MACHINE : le site discrimine
  // dessus, le statut seul ne suffit pas (403 y signifie déjà « Origin non
  // autorisée », cf. checkOrigin plus haut).
  const pl = validatePlan(body, env);
  if (pl.error) return json({ error: pl.error, code: pl.code }, pl.status, origin);

  // Plafond d'émission, APRÈS la validation des claims (un corps grossièrement
  // invalide ne consomme pas le budget) et AVANT toute signature. Le 429 est
  // géré explicitement par le client (tokeniser_service.dart) : contexte
  // interactif d'inscription, l'utilisateur réessaie.
  if (!(await checkIssueCap(env))) {
    return json({ error: 'Trop de requêtes — réessaie dans un instant' }, 429, origin);
  }

  const nonceBytes = new Uint8Array(16); // 128 bits — identifiant de partition, pas un secret
  crypto.getRandomValues(nonceBytes);
  const d = daysSinceEpoch(new Date());
  const n = b64url(nonceBytes);

  // ⚠️ INVARIANT DE PRODUCTION : sans plan, le payload est construit
  // EXACTEMENT comme avant (mêmes clés, même ordre, sv 2). Toute autre forme
  // casserait l'inscription live de mental-et.com.
  const payload = pl.plan
    ? { ...v.claims, p: pl.plan.p, cc: pl.plan.cc, cv: pl.plan.cv, d, n, sv: SCHEMA_VERSION_PLAN }
    : { ...v.claims, d, n, sv: SCHEMA_VERSION_LEGACY };

  let token;
  try {
    token = await signPayload(payload, env.ED25519_PRIVATE_KEY_B64);
  } catch {
    return json({ error: 'Échec de signature (clé invalide ?)' }, 500, origin);
  }
  if (pl.plan) await bumpConsentCounter(env, pl.plan);
  return json({ token }, 200, origin);
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
 * Valide et NORMALISE les claims démographiques d'émission (clés compactes :
 * s/y/m/r). Le jour d'inscription (`d`) n'est PAS un champ d'entrée : il est
 * calculé côté serveur (UTC, au jour) — autorité serveur, jamais client.
 *
 * L'allow-list d'ENTRÉE accepte en plus p/cc/cv, dont la cohérence est jugée
 * par validatePlan() : ici on se contente de ne plus les refuser en bloc
 * (avant, `p` déclenchait « Champ non autorisé: p »). Tout autre champ reste
 * refusé — allow-list fermée, anti-injection de quasi-identifiants.
 */
function validateClaims(body) {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { error: 'Payload invalide' };
  }
  const allowedInputKeys = new Set(['s', 'y', 'm', 'r', 'p', 'cc', 'cv']);
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

/**
 * Valide le TRIPLET de plan {p, cc, cv} et décide de la version de schéma.
 *
 * Renvoie exactement l'une des trois formes :
 *   { plan: null }                → aucun champ de plan : émettre un sv 2 À
 *                                   L'IDENTIQUE (inscription live inchangée).
 *   { plan: { p, cc, cv } }       → émettre un sv 3 avec ces claims.
 *   { error, code, status }       → refus, avec un CODE MACHINE pour le site.
 *
 * Interrupteur `PAID_PLAN_ENABLED` (var wrangler) : « true » (et rien d'autre)
 * active le plan payant. Absent, vide, « TRUE », « 1 » → désactivé. Défaut
 * FERMÉ assumé : tant que Stripe n'est pas branché, on ne veut surtout pas
 * qu'une var oubliée ouvre la vente.
 *
 * Matrice (plan §3), colonne gauche = interrupteur false (aujourd'hui) :
 *   pas de p (ni cc/cv)      → sv 2                      | sv 2
 *   cc ou cv sans p          → 400 PLAN_REQUIRED         | idem
 *   p=free, cc=true          → 200 sv 3                  | 200 sv 3
 *   p=free, cc=false         → 200 sv 3 (facultatif)     | 400 CONSENT_REQUIRED
 *   p=paid, cc=false         → 403 PAID_PLAN_DISABLED    | 200 sv 3
 *   p=paid, cc=true          → 400 PLAN_INCONSISTENT     | idem
 *   cv absent / ∉ LEGAL_VERSIONS → 400 LEGAL_VERSION_UNKNOWN | idem
 *   LEGAL_VERSIONS non configuré → 500 SERVER_MISCONFIGURED  | idem
 *   p=free, cc=true, âge < 15    → 400 AGE_CONSENT           | idem
 *
 * Le consentement au corpus est FACULTATIF tant que le plan payant est fermé :
 * sans alternative réelle, il ne serait pas « libre » au sens de l'art. 7(4)
 * RGPD, donc il ne peut pas être exigé.
 *
 * ⚠️ APPELER APRÈS validateClaims() : la garde d'âge lit body.y / body.m, dont
 * le type et les bornes ont déjà été vérifiés là-bas.
 */
function validatePlan(body, env) {
  const has = (k) => Object.prototype.hasOwnProperty.call(body, k);
  const hasP = has('p');
  const hasCc = has('cc');
  const hasCv = has('cv');

  // Aucun champ de plan → passe historique, chemin de production intact.
  if (!hasP && !hasCc && !hasCv) return { plan: null };

  // Une preuve de consentement sans plan n'a pas de sens : on ne devine pas le
  // plan (deviner « free » reviendrait à inventer un consentement).
  if (!hasP) {
    return refus('PLAN_REQUIRED', 400, 'p (plan) requis dès que cc ou cv est fourni');
  }
  const p = body.p;
  if (!ALLOWED_PLANS.has(p)) {
    return refus('PLAN_REQUIRED', 400, 'p (plan) invalide : "free" ou "paid" attendu');
  }
  if (!hasCc || typeof body.cc !== 'boolean') {
    return refus('PLAN_REQUIRED', 400, 'cc (consentement corpus) booléen requis');
  }
  const cc = body.cc;

  // Version des textes légaux : fail-closed des deux côtés. Sans liste
  // configurée on ne peut PAS savoir sur quoi la personne a consenti → 500
  // (erreur serveur assumée, pas un rejet de l'utilisateur).
  const versions = parseLegalVersions(env);
  if (versions.length === 0) {
    return refus(
      'SERVER_MISCONFIGURED', 500,
      'LEGAL_VERSIONS non configuré : émission de passe avec plan impossible',
    );
  }
  if (typeof body.cv !== 'string' || !versions.includes(body.cv)) {
    return refus('LEGAL_VERSION_UNKNOWN', 400, 'cv (version des textes légaux) inconnue');
  }
  const cv = body.cv;

  const paidEnabled = env.PAID_PLAN_ENABLED === 'true';

  if (p === 'paid') {
    // Incohérence AVANT l'interrupteur : un passe payant ne porte jamais de
    // consentement au corpus (il existe précisément pour ne pas consentir).
    if (cc) {
      return refus(
        'PLAN_INCONSISTENT', 400,
        'plan payant et consentement au corpus sont incompatibles',
      );
    }
    if (!paidEnabled) {
      return refus('PAID_PLAN_DISABLED', 403, "Le passe Payant n'est pas encore disponible");
    }
    // ── Point d'accroche Stripe (hors périmètre aujourd'hui) ──────────────
    // Quand la vente ouvrira, la preuve de paiement sera exigée ICI, avant de
    // rendre le plan — jamais après, un passe payant ne doit pas être signé
    // sans paiement constaté :
    //   const preuve = await checkPaidProof(body, env);
    //   if (!preuve.ok) return refus('PAYMENT_REQUIRED', 402, preuve.error);
    // `checkPaidProof` interrogera Stripe avec une référence opaque de session
    // et ne rapportera QUE { ok } — ni nom, ni carte, ni identité (cf.
    // politique de confidentialité §5). validatePlan deviendra alors `async`
    // et handleIssue devra l'attendre.
    return { plan: { p, cc, cv } };
  }

  // p === 'free'
  if (!cc && paidEnabled) {
    return refus(
      'CONSENT_REQUIRED', 400,
      'Le passe Gratuit exige le consentement au corpus vocal (ou choisis le passe Payant)',
    );
  }
  if (cc && ageAtIssue(body.y, body.m) < CONSENT_MIN_AGE) {
    return refus(
      'AGE_CONSENT', 400,
      `Consentement au corpus impossible avant ${CONSENT_MIN_AGE} ans`,
    );
  }
  return { plan: { p, cc, cv } };
}

function refus(code, status, error) {
  return { error, code, status };
}

/** Versions de textes légaux admises : CSV de la var wrangler LEGAL_VERSIONS. */
function parseLegalVersions(env) {
  const raw = typeof env.LEGAL_VERSIONS === 'string' ? env.LEGAL_VERSIONS : '';
  return raw.split(',').map((s) => s.trim()).filter((s) => s.length > 0);
}

/**
 * Âge au jour de l'émission, en UTC, depuis l'année et le mois de naissance.
 *
 *     age = Y − y − (m ≥ M ? 1 : 0)
 *
 * Y/M = année et mois courants UTC (M ∈ 1..12), y/m = naissance. Le MOIS DE
 * NAISSANCE EN COURS compte comme NON RÉVOLU (on ne connaît pas le jour) :
 * y=2011, m=9 en septembre 2026 → 14 ans, pas 15.
 *
 * ⚠️ Cette formule doit rester IDENTIQUE côté site (`ageAt(y, m)` de
 * signup.js) : un écart ferait afficher « tu peux cocher » à quelqu'un que le
 * serveur refusera ensuite, ou l'inverse.
 */
function ageAtIssue(y, m) {
  const now = new Date();
  const Y = now.getUTCFullYear();
  const M = now.getUTCMonth() + 1;
  return Y - y - (m >= M ? 1 : 0);
}

/**
 * Compteur AGRÉGÉ de consentements — preuve du recueil (RGPD art. 7(1)).
 *
 * Clé : `consent:<cv>:<p>:<cc>:<jour UTC>:<shard 0-15>`, valeur = un entier.
 * Ce qui est écrit : « le 2026-09-02, sous la version 2026-09-02.v1, N passes
 * gratuits ont été émis avec consentement au corpus ». Rien d'autre — ni IP,
 * ni token, ni nonce, ni aucune claim individuelle. Deux personnes du même
 * jour, même plan, même version sont strictement indiscernables dedans.
 *
 * SANS `expirationTtl`, contrairement à `issue:` : une preuve de consentement
 * qui s'auto-détruit ne prouve plus rien. C'est un agrégat, pas un frein.
 *
 * Le SHARD (1 octet aléatoire & 15) répartit les écritures sur 16 clés pour
 * contourner la limite Cloudflare d'« une écriture par seconde et par clé » :
 * sans lui, une rafale d'inscriptions perdrait la plupart des incréments. La
 * lecture se fait en sommant le préfixe (`kv key list --prefix consent:<cv>:`).
 *
 * FAIL-OPEN intégral (try/catch vide, même doctrine que checkIssueCap) : un KV
 * absent ou en panne ne doit JAMAIS transformer une émission réussie — token
 * déjà signé — en erreur. Le prix assumé est un sous-comptage.
 */
async function bumpConsentCounter(env, { p, cc, cv }) {
  if (!env.RATE_KV) return;
  try {
    const shardByte = new Uint8Array(1);
    crypto.getRandomValues(shardByte);
    const shard = shardByte[0] & 15;
    const day = new Date().toISOString().slice(0, 10); // AAAA-MM-JJ UTC
    const key = `consent:${cv}:${p}:${cc}:${day}:${shard}`;
    const cur = parseInt(await env.RATE_KV.get(key), 10) || 0;
    await env.RATE_KV.put(key, String(cur + 1));
  } catch {
    // Fail-open volontaire : voir le doc-comment ci-dessus.
  }
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
