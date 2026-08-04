/**
 * Cloudflare Worker — Réponses de l'événement des 8 jours → R2 (UE)
 *
 * Reçoit les réponses des questionnaires de l'événement d'attente
 * (questionnaires annoncés, questions candidates, bloc diagnostic) et les écrit
 * dans un bucket R2 en juridiction EU. Le client n'a AUCUNE clé R2 : tout passe
 * par ici. Le worker n'expose AUCUNE lecture — c'est une boîte aux lettres.
 *
 * POURQUOI UN WORKER SÉPARÉ DE `r2-upload`. Ce ne sont pas les mêmes données
 * ni la même base légale : l'audio relève du consentement d'enregistrement,
 * ces réponses-ci sont des DONNÉES DE SANTÉ (art. 9 RGPD). Un bucket distinct
 * rend l'effacement et l'export séparables, et la garde de consentement
 * ci-dessous peut exiger la finalité exacte au lieu d'un consentement
 * quelconque.
 *
 * AUTHENTIFICATION — SIGNATURE EXIGÉE, SANS FILET.
 * Le token DOIT être signé (Ed25519, re-vérifié ici par
 * `_shared/token_verify.js`). C'est le patron de `r2-upload`, PAS celui de
 * `referral` : ce dernier accepte volontairement les tokens DEV non signés
 * « M2.<claims> » parce qu'il ne garde qu'un compteur de parrainage (donnée
 * anodine). Ici, accepter un nonce non signé laisserait n'importe qui écrire
 * des réponses de santé dans le compartiment d'autrui, ou polluer le jeu de
 * données servant à construire nos échelles. Un passe non signé est donc
 * refusé (401) — et le client GARDE ses réponses en local, chiffrées, jusqu'à
 * disposer d'un passe signé (voir event_upload_service.dart).
 *
 * CONSENTEMENT (art. 9) — DEUX EN-TÊTES, PAS UN.
 *   · `X-Consent-Version` : quelle version du texte a été acceptée (preuve).
 *   · `X-Consent-Purpose` : POUR QUOI. Doit valoir exactement
 *     `event-health-research`. Sans cette seconde garde, un consentement
 *     recueilli pour l'audio suffirait à autoriser un envoi de santé — la
 *     preuve serait archivée, mais elle ne prouverait pas la bonne finalité.
 * Sans les deux → 403, rien n'est écrit.
 *
 * ORGANISATION DES CLÉS (miroir des conventions anti-ré-identification) :
 *   responses/<account>/<moduleId>/<uuid>.json
 *     · account = SHA-256(nonce signé)[:32] — partition dérivée du token,
 *       JAMAIS d'un identifiant choisi par le client. Effacement art. 17 =
 *       supprimer le préfixe `responses/<account>/`.
 *     · uuid, jamais un horodatage : l'instant précis d'un envoi de santé
 *       serait un quasi-identifiant.
 *     · metadata `received_day` : la DATE seule, jamais l'heure.
 *
 * PAS DE DÉDOUBLONNAGE CÔTÉ SERVEUR, ET C'EST VOULU. Le client rejoue jusqu'à
 * confirmation ; une confirmation perdue en route produit donc un second objet
 * au contenu identique. Écraser une clé déterministe éviterait ce doublon mais
 * ferait perdre l'historique partiel→complet. On préfère deux objets
 * identiques (dédoublonnables à l'analyse) à une donnée écrasée. Le jeu final
 * d'un module est celui dont `partial` vaut `false` ; à défaut, celui dont
 * `item_count` est le plus grand.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';

const ALLOWED_ORIGINS = [
  'https://mentality-flutter-web.pages.dev',
  'http://localhost:7357',
  'http://localhost:8080',
];

/** Finalité art. 9 attendue — doit correspondre à `kEventDataPurpose` (Dart). */
const EXPECTED_PURPOSE = 'event-health-research';

/** Version de schéma de la charge utile acceptée (miroir de `kEventPayloadSchema`). */
const SUPPORTED_SCHEMA = 1;

/** Cadrages RGPD possibles d'un module (miroir de `DayActivityKind`). */
const KINDS = new Set(['announced', 'contribution']);

const MAX_BYTES = 256 * 1024; // 256 Ko : un module fait ~50 réponses entières
const MAX_ITEMS = 500;
const MAX_ITEM_ID = 64;

// Bornes de SÉCURITÉ, pas un barème. Le worker ne connaît pas l'échelle de
// chaque item (0-3 pour un GAD-7, 1-7 pour un CAT-Q) : la validation exacte est
// `QScale.accepts()` côté client. Ces bornes n'écartent que ce qu'aucun
// instrument publié ne peut produire et qui empoisonnerait l'analyse —
// `Number.isInteger(1e308)` vaut `true`, et une seule valeur pareille rend
// Infinie la moyenne de tout un corpus. Volontairement LARGES : un 400 est un
// refus DÉFINITIF côté client, donc une donnée perdue.
const VALEUR_MIN = -1000;
const VALEUR_MAX = 1000;

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return handleOptions(request);

    const origin = request.headers.get('Origin') || '';
    if (origin !== '' && !ALLOWED_ORIGINS.includes(origin)) {
      return json({ error: 'Origin non autorisée' }, 403, origin);
    }

    const path = new URL(request.url).pathname;
    if (path !== '/responses') {
      return json({ error: 'Route inconnue' }, 404, origin);
    }
    if (request.method !== 'POST') {
      return json({ error: 'Méthode non autorisée' }, 405, origin);
    }

    if (!env.EVENT_BUCKET) {
      return json(
        { error: 'Bucket R2 non lié. Vérifier le binding EVENT_BUCKET dans wrangler.toml.' },
        500,
        origin,
      );
    }

    // ─── Authentification : signature Ed25519 OBLIGATOIRE ────────────────────
    const auth = await verifyToken(request.headers.get('X-Mentality-Token') || '',
                                   TOKEN_SIGNING_PUBLIC_KEYS);
    if (!auth.valid) {
      return json({ error: `Passe signé requis (${auth.reason})` }, 401, origin);
    }
    const account = (await sha256hex(auth.nonce)).slice(0, 32);

    // ─── Garde-fou RGPD art. 9 : preuve ET finalité ──────────────────────────
    const consentVersion = (request.headers.get('X-Consent-Version') || '').trim();
    const consentPurpose = (request.headers.get('X-Consent-Purpose') || '').trim();
    if (!consentVersion) {
      return json({ error: 'Consentement absent : envoi refusé (RGPD).' }, 403, origin);
    }
    if (consentPurpose !== EXPECTED_PURPOSE) {
      return json(
        { error: `Finalité de consentement absente ou inadéquate (attendu ${EXPECTED_PURPOSE}).` },
        403,
        origin,
      );
    }

    // ─── Charge utile ────────────────────────────────────────────────────────
    const raw = await request.arrayBuffer();
    if (raw.byteLength === 0) return json({ error: 'Corps vide' }, 400, origin);
    if (raw.byteLength > MAX_BYTES) return json({ error: 'Charge utile trop volumineuse' }, 413, origin);

    let body;
    try {
      body = JSON.parse(new TextDecoder().decode(raw));
    } catch {
      return json({ error: 'JSON illisible' }, 400, origin);
    }
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      return json({ error: 'Objet JSON attendu' }, 400, origin);
    }

    if (body.schema !== SUPPORTED_SCHEMA) {
      return json({ error: `Schéma non supporté : ${body.schema}` }, 400, origin);
    }
    // REFUSÉ plutôt qu'assaini : assainir « ../../etc » en « etc » écrirait une
    // clé sûre mais sous un module qui n'existe pas, et le corps stocké
    // porterait un identifiant que personne n'a demandé. Un identifiant qui
    // n'est pas déjà propre est un bug client, pas une valeur à corriger.
    const moduleId = body.moduleId;
    if (!estIdentifiant(moduleId, 80)) {
      return json({ error: 'moduleId absent ou mal formé' }, 400, origin);
    }

    const day = body.day;
    if (!Number.isInteger(day) || day < 1 || day > 8) {
      return json({ error: 'day hors de 1..8' }, 400, origin);
    }
    if (!KINDS.has(body.kind)) {
      return json({ error: `kind inconnu : ${body.kind}` }, 400, origin);
    }
    if (typeof body.partial !== 'boolean') {
      return json({ error: 'partial (booléen) requis' }, 400, origin);
    }

    const answers = body.answers;
    if (!answers || typeof answers !== 'object' || Array.isArray(answers)) {
      return json({ error: 'answers doit être un objet' }, 400, origin);
    }
    const itemIds = Object.keys(answers);
    if (itemIds.length === 0) return json({ error: 'answers vide' }, 400, origin);
    if (itemIds.length > MAX_ITEMS) return json({ error: 'Trop de réponses' }, 400, origin);
    for (const id of itemIds) {
      if (id.length === 0 || id.length > MAX_ITEM_ID) {
        return json({ error: `Identifiant d'item invalide : ${id.slice(0, MAX_ITEM_ID)}` }, 400, origin);
      }
      // La valeur BRUTE de la cotation publiée — un entier, jamais un indice de
      // bouton renuméroté (renuméroter casserait les seuils).
      const valeur = answers[id];
      if (!Number.isInteger(valeur)) {
        return json({ error: `Réponse non entière pour ${id}` }, 400, origin);
      }
      if (valeur < VALEUR_MIN || valeur > VALEUR_MAX) {
        return json({ error: `Réponse hors bornes pour ${id}` }, 400, origin);
      }
    }

    const locale = body.locale === undefined ? 'fr' : body.locale;
    if (!estIdentifiant(locale, 10)) {
      return json({ error: 'locale mal formée' }, 400, origin);
    }

    // ─── Écriture : clé uuid, metadata au JOUR ───────────────────────────────
    const key = `responses/${account}/${moduleId}/${crypto.randomUUID()}.json`;
    const stored = JSON.stringify({
      schema: SUPPORTED_SCHEMA,
      account,
      moduleId,
      day,
      kind: body.kind,
      partial: body.partial,
      locale,
      answers,
    });

    try {
      await env.EVENT_BUCKET.put(key, stored, {
        httpMetadata: { contentType: 'application/json' },
        customMetadata: {
          account, // = SHA-256(nonce)[:32] : lien anonyme au passe signé
          module_id: moduleId,
          day: String(day),
          kind: body.kind,
          partial: String(body.partial),
          item_count: String(itemIds.length),
          locale,
          consent_version: consentVersion,
          consent_purpose: consentPurpose,
          received_day: new Date().toISOString().slice(0, 10), // DATE, jamais l'heure
        },
      });
    } catch (error) {
      return json({ error: 'Échec écriture R2', detail: error.message }, 502, origin);
    }

    return json({ stored: true, key, itemCount: itemIds.length }, 200, origin);
  },
};

/**
 * Un identifiant déjà propre : lettres, chiffres, `_` et `-` uniquement.
 * Aucun `/` ni `.` ne peut donc entrer dans une clé R2 (anti-traversée de
 * chemin), et aucune valeur n'est réécrite en douce.
 */
function estIdentifiant(v, maxLen) {
  return typeof v === 'string' && v.length > 0 && v.length <= maxLen &&
    /^[a-zA-Z0-9_-]+$/.test(v);
}

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers':
      'Content-Type, X-Mentality-Token, X-Consent-Version, X-Consent-Purpose',
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
