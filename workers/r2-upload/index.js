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
 * ⚠️ LA COUCHE CESSIBLE EST DÉSORMAIS INATTEIGNABLE SANS CLAIMS SIGNÉES.
 * Un objet ne peut atterrir sous `reusable/` QUE si le passe est un sv ≥ 3
 * SIGNÉ portant p='free' ET cc=true ET une `cv` appartenant à LEGAL_VERSIONS.
 * Aucun en-tête, aucune combinaison d'en-têtes, aucun passe sv 2 ne peut plus y
 * conduire. C'est une règle de fond, pas une commodité : la seule preuve de
 * consentement d'un fichier cessible à des tiers doit être une chaîne SIGNÉE
 * par le tokeniser, jamais une chaîne choisie par l'appelant.
 *
 * RGPD — D'OÙ VIENT LA PREUVE DE CONSENTEMENT (deux régimes selon `sv`) :
 *
 *   sv ≥ 3 : les CLAIMS SIGNÉES DU PASSE FONT AUTORITÉ, lues par `readPlan()`
 *            (workers/_shared/token_plan.js). Les en-têtes X-Consent-Version et
 *            X-Commercial-Reuse sont IGNORÉS : ils sont déclaratifs, donc
 *            forgeables, et un enregistrement classé « cessible » par un
 *            en-tête menti serait un consentement fabriqué. Concrètement :
 *              - plan 'paid'  → 403, RIEN n'est écrit (le passe Payant est
 *                l'alternative sans enregistrement : c'est elle qui rend libre
 *                le consentement du plan Gratuit, RGPD art. 7(4)) ;
 *              - plan absent/inconnu, ou version légale (`cv`) manquante → 403 ;
 *              - LEGAL_VERSIONS absente/vide → 500 (fail-closed : on n'écrit
 *                PAS un consentement dont on ne peut pas prouver le texte) ;
 *              - `cv` ∉ LEGAL_VERSIONS → 403 LEGAL_VERSION_UNKNOWN. Retirer une
 *                version de cette liste RÉVOQUE les nouveaux uploads qui s'en
 *                réclament : c'est le levier de révocation côté écriture, le
 *                pendant de la même liste côté tokeniser (à l'émission) ;
 *              - plan 'free'  → consent_version = cv, commercial_reuse = cc.
 *
 *   sv 2   : régime historique CONSERVÉ pour les uploads, mais DURCI sur un
 *            point : la destination est TOUJOURS `internal/`, quoi que dise
 *            X-Commercial-Reuse. Un passe sv 2 ne porte aucune claim de
 *            consentement au corpus ; sa seule « preuve » serait une chaîne
 *            X-Consent-Version choisie par l'appelant — c'est-à-dire un
 *            consentement fabriqué. Les passes déjà distribués continuent donc
 *            d'envoyer (sans X-Consent-Version, 403 comme avant), mais leur
 *            audio reste en usage interne. Le durcissement ne coûte rien : R2
 *            est désactivé sur le compte, le bucket n'existe pas, il n'y a
 *            aucun corpus historique sous `reusable/` à préserver.
 *
 * Chaque objet garde la trace du régime appliqué : `customMetadata.plan`
 * ('free' | 'legacy') et `customMetadata.consent_source` ('token' | 'header').
 *
 * VÉRIFICATION DES ENREGISTREMENTS (décision produit 2026-09-03) : un fichier
 * de silence ne doit pas donner droit aux résultats du passe Gratuit. Après
 * chaque `put` réussi, le worker lance en tâche de fond (`ctx.waitUntil`, la
 * réponse à l'app n'attend pas) une transcription bon marché par Workers AI
 * (`@cf/openai/whisper`, binding `AI`) et écrit un VERDICT sous
 *   verified/<account>/<sessionId>/<recordType>-<textId>.json
 *     { ok, reason, overlap, words_hit, words_ref, words_transcribed, model, day }
 *   - reading : on connaît le texte à lire (référence `corpus/<textId>.json`,
 *     publiée par scripts/publish-corpus.mjs) ; ok si la part des mots de la
 *     référence retrouvés dans la transcription ≥ VERIFY_MIN_OVERLAP ;
 *   - summary : pas de référence ; ok si la transcription compte au moins
 *     VERIFY_MIN_SUMMARY_WORDS mots distincts.
 * Le verdict ne contient QUE des comptes : aucun mot transcrit n'est conservé,
 * et rien n'est loggé (doctrine d'anonymat des workers). Un binding AI absent
 * ou un modèle en panne donne un verdict ok:false (`ai_unavailable` /
 * `ai_error`) et ne fait JAMAIS échouer l'upload. C'est POST /validate du
 * tokeniser qui lit ces verdicts et exige MIN_VERIFIED_READINGS lectures ok.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../_shared/token_verify.js';
import { readPlan } from '../_shared/token_plan.js';
import { motsDistincts, recouvrement } from '../_shared/text_norm.js';

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

// Première version de schéma où le passe porte lui-même le plan et le
// consentement. À partir d'elle, les en-têtes client ne décident plus de rien.
const SCHEMA_VERSION_PLAN = 3;

// ─── Vérification des enregistrements ────────────────────────────────────────
// Modèle Workers AI de transcription. Bon marché et approximatif : il suffit,
// on ne cherche pas une transcription exacte mais une preuve que le texte
// attendu a bien été lu (cf. en-tête de fichier).
const MODELE_TRANSCRIPTION = '@cf/openai/whisper';
// Au-delà, on ne transcrit pas : les octets sont recopiés dans un tableau JS
// pour le modèle, et un fichier de 25 Mo ferait déborder la mémoire du worker.
// À 32 kbps (Opus forcé par l'app), 8 Mo ≈ 33 minutes : très au-dessus d'une
// lecture ou d'un résumé réels.
const VERIFY_MAX_BYTES = 8 * 1024 * 1024;
// Seuils par défaut, surchargeables par [vars] (chaînes, comme toute var wrangler).
const VERIFY_MIN_OVERLAP_DEFAUT = 0.30;
const VERIFY_MIN_SUMMARY_WORDS_DEFAUT = 15;
// Types d'enregistrement vérifiés. Tout autre type (défaut 'audio' d'un client
// qui n'envoie pas X-Record-Type) est stocké sans verdict : /validate ne
// compte que les lectures, un verdict sur un type inconnu ne servirait à rien.
/**
 * Raisons d'échec qui ne JUGENT RIEN : la vérification n'a pas pu avoir lieu
 * (binding absent, modèle en panne, allocation de neurones épuisée, réponse
 * illisible, bug). Elles ne doivent jamais s'écrire comme un verdict, sinon
 * `/validate` compte l'enregistrement comme « tombé » et refuse DÉFINITIVEMENT
 * les résultats à quelqu'un qui a parfaitement lu (bug trouvé au banc, réveil 4 :
 * au-delà de ~99 bilans dans la journée, `env.AI.run` renvoie 4006 et TOUTES
 * les lectures du jour deviennent des échecs définitifs). Sans verdict écrit,
 * l'enregistrement reste « en attente » et le cron le reprend.
 *
 * `low_overlap`, `too_few_words`, `no_reference` et `audio_too_large`, eux,
 * sont des jugements ou des faits stables : ils s'écrivent.
 */
const RAISONS_INFRASTRUCTURE = new Set(['ai_unavailable', 'ai_error', 'ai_response_format', 'verify_error']);

const RECORD_TYPE_READING = 'reading';
const RECORD_TYPE_SUMMARY = 'summary';

export default {
  async fetch(request, env, ctx) {
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
    // Ces valeurs composent la clé R2 : on REFUSE ce qui sort du format, on ne
    // le nettoie plus (cf. `lisChamps`, granularité de l'effacement art. 17).
    const champs = lisChamps(request);
    if (champs.erreur) {
      return json(
        { error: `En-tête ${champs.erreur} de format invalide`, code: 'FIELD_FORMAT' },
        400,
        origin,
      );
    }
    const { sessionId, textId, layer, recordType, language } = champs;
    const durationSeconds = request.headers.get('X-Duration-Seconds') || '';
    const contentType = request.headers.get('Content-Type') || '';

    // ─── Garde-fou RGPD : pas de consentement prouvé → pas de stockage ───────
    // Le passe décide, pas le client : voir l'en-tête de fichier (deux régimes).
    const porteur = readPlan(auth.claims);
    let consentVersion;
    let commercialReuse;
    let planLabel;
    let consentSource;

    if (porteur.sv >= SCHEMA_VERSION_PLAN) {
      // Régime autoritaire : tout vient des octets signés.
      if (porteur.plan === 'paid') {
        return json({ error: 'Plan payant : aucun enregistrement vocal' }, 403, origin);
      }
      if (porteur.plan !== 'free' || !porteur.legalVersion) {
        // Défense en profondeur : `verifyToken()` refuse déjà cette forme (401).
        // Si elle arrivait ici, elle ne vaut pas consentement.
        return json({ error: 'Consentement absent : upload refusé (RGPD).' }, 403, origin);
      }
      // `cv` EST LA PREUVE recopiée dans customMetadata.consent_version. Le
      // worker qui ÉCRIT doit donc savoir à quel texte elle renvoie, sans quoi
      // il conserve un consentement dont il ne peut pas produire le contenu.
      // La vérification à l'émission (tokeniser) ne suffit pas : ce worker doit
      // pouvoir révoquer une version SANS ré-émettre les passes déjà signés.
      const versions = versionsLegales(env);
      if (versions.length === 0) {
        // Fail-closed assumé : une liste absente est une erreur de config, pas
        // un motif de refuser l'utilisateur — d'où 500 et non 403.
        return json(
          {
            error: 'LEGAL_VERSIONS non configuré : stockage d\'un consentement impossible',
            code: 'SERVER_MISCONFIGURED',
          },
          500,
          origin,
        );
      }
      if (!versions.includes(porteur.legalVersion)) {
        return json(
          {
            error: 'Version des textes légaux inconnue de ce worker : upload refusé',
            code: 'LEGAL_VERSION_UNKNOWN',
          },
          403,
          origin,
        );
      }
      consentVersion = porteur.legalVersion;
      commercialReuse = porteur.corpusConsent;
      planLabel = porteur.plan;
      consentSource = 'token';
    } else {
      // Régime historique (sv 2) : consentement recueilli in-app, porté par les
      // en-têtes. Les passes déjà émis continuent d'envoyer…
      consentVersion = request.headers.get('X-Consent-Version') || '';
      planLabel = 'legacy';
      consentSource = 'header';
      if (!consentVersion) {
        return json({ error: 'Consentement absent : upload refusé (RGPD).' }, 403, origin);
      }
      // … MAIS JAMAIS VERS LA COUCHE CESSIBLE. X-Commercial-Reuse est ignoré
      // ici, exactement comme en sv 3 : un passe sv 2 ne porte aucune claim de
      // consentement au corpus, donc rien de signé ne peut soutenir une
      // cession à des tiers. Écrire sous `reusable/` sur la seule foi de deux
      // en-têtes reviendrait à fabriquer le consentement qu'on prétend prouver.
      // NE JAMAIS remettre `=== 'true'` ici : c'était la faille (libre-service
      // permanent de la couche cessible via un passe sv 2 signé).
      commercialReuse = false;
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
    // DERNIER VERROU, volontairement redondant avec les deux branches ci-dessus :
    // `reusable/` exige une preuve SIGNÉE. Si un futur remaniement rendait
    // `commercialReuse` vrai sur un chemin déclaratif, la couche cessible
    // resterait fermée plutôt que de s'ouvrir en silence.
    const cessible = commercialReuse === true && consentSource === 'token';
    const bucket = cessible ? 'reusable' : 'internal';
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
          // Miroir EXACT du préfixe de clé : la base et le bucket ne peuvent
          // pas se contredire sur la cessibilité d'un enregistrement.
          commercial_reuse: String(cessible),
          plan: planLabel, // 'free' (passe sv 3) | 'legacy' (passe sv 2)
          consent_source: consentSource, // 'token' = signé | 'header' = déclaré
          duration_seconds: durationSeconds,
          language,
          uploaded_day: new Date().toISOString().slice(0, 10), // DATE, jamais l'heure
        },
      });
    } catch (error) {
      return json({ error: 'Échec écriture R2', detail: error.message }, 502, origin);
    }

    // ─── Vérification en tâche de fond : la réponse à l'app n'attend pas ─────
    // `ctx.waitUntil` garde le worker vivant le temps de la transcription. La
    // fonction ne rejette jamais (tout est capturé dedans) : un verdict qui ne
    // peut pas s'écrire ne remonte nulle part, il manque simplement — et
    // /validate répondra VERIFICATION_PENDING pour cet enregistrement.
    const verification = verifierEnregistrement(env, {
      account, sessionId, recordType, textId, language, audio: body,
    });
    if (ctx && typeof ctx.waitUntil === 'function') ctx.waitUntil(verification);

    return json({ key, size: body.byteLength, reusable: cessible }, 200, origin);
  },

  // Cron : supprime les données des comptes PROVISOIRES abandonnés — ceux sans
  // marqueur `validated/<account>` (écrit par tokeniser /validate) et dont les
  // objets dépassent RETENTION_DAYS. Les comptes validés (test soumis) sont
  // conservés. Voir wrangler.toml [triggers].
  async scheduled(event, env, ctx) {
    await cleanupAbandoned(env);
    // Après le ménage (inutile de transcrire ce qu'on vient de supprimer) et
    // après le reset quotidien de l'allocation Workers AI, à 00:00 UTC.
    await reprendreVerifications(env);
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Vérification des enregistrements (transcription + recouvrement)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Calcule et écrit le verdict d'un enregistrement fraîchement stocké.
 *
 * NE REJETTE JAMAIS et n'écrit AUCUN texte : le verdict ne porte que des
 * comptes (mots de la référence, mots retrouvés, mots transcrits), le jour
 * (jamais l'heure) et le nom du modèle. Les types autres que reading/summary
 * ne donnent lieu à aucun verdict.
 */
async function verifierEnregistrement(env, champs) {
  const { account, sessionId, recordType, textId } = champs;
  if (recordType !== RECORD_TYPE_READING && recordType !== RECORD_TYPE_SUMMARY) return;
  if (!env.AUDIO_BUCKET) return;

  let resultat;
  try {
    resultat = await calculerVerdict(env, champs);
  } catch {
    resultat = { ok: false, reason: 'verify_error' };
  }
  const ok = resultat.ok === true;
  // Panne d'infrastructure : on n'écrit RIEN. L'enregistrement reste « en
  // attente » (409 côté /validate, l'app réessaie) et le cron le reprendra
  // quand le modèle répondra de nouveau. Écrire ici transformerait une panne
  // de notre côté en échec définitif du côté de la personne.
  if (!ok && RAISONS_INFRASTRUCTURE.has(resultat.reason)) return;
  const verdict = {
    ok,
    reason: ok ? null : (resultat.reason || 'unknown'),
    overlap: typeof resultat.overlap === 'number' ? resultat.overlap : null,
    words_hit: resultat.words_hit || 0,
    words_ref: resultat.words_ref || 0,
    words_transcribed: resultat.words_transcribed || 0,
    model: MODELE_TRANSCRIPTION,
    day: new Date().toISOString().slice(0, 10), // DATE, jamais l'heure
  };
  const cle = `verified/${account}/${sessionId}/${recordType}-${textId || 'na'}.json`;
  try {
    await env.AUDIO_BUCKET.put(cle, JSON.stringify(verdict), {
      httpMetadata: { contentType: 'application/json' },
      // Miroir du corps, lisible par un simple `list({ include })` côté
      // tokeniser, sans télécharger chaque verdict.
      customMetadata: {
        account,
        session_id: sessionId,
        record_type: recordType,
        text_id: textId || '',
        ok: String(ok),
        reason: verdict.reason || '',
        day: verdict.day,
      },
    });
  } catch {
    // Silencieux, voulu : pas de log par requête. Sans verdict, /validate
    // classe l'enregistrement « en attente ».
  }
}

/**
 * Le verdict brut : { ok, reason?, overlap?, words_hit?, words_ref?,
 * words_transcribed? }. Peut jeter : l'appelant capture.
 *
 * Ordre volontaire : la référence est cherchée AVANT d'appeler le modèle —
 * une transcription qu'on ne pourrait comparer à rien serait payée pour rien.
 */
async function calculerVerdict(env, { recordType, textId, language, audio }) {
  let reference = null;
  if (recordType === RECORD_TYPE_READING) {
    reference = await chargerReference(env.AUDIO_BUCKET, textId);
    if (!reference) return { ok: false, reason: 'no_reference' };
  }
  if (!env.AI || typeof env.AI.run !== 'function') {
    return { ok: false, reason: 'ai_unavailable' };
  }
  if (audio.byteLength > VERIFY_MAX_BYTES) return { ok: false, reason: 'audio_too_large' };

  let texte;
  try {
    texte = await transcrire(env.AI, audio, language);
  } catch {
    return { ok: false, reason: 'ai_error' };
  }
  if (texte === null) return { ok: false, reason: 'ai_response_format' };

  const transcrits = motsDistincts(texte);
  if (recordType === RECORD_TYPE_SUMMARY) {
    const min = entierPositif(env.VERIFY_MIN_SUMMARY_WORDS, VERIFY_MIN_SUMMARY_WORDS_DEFAUT);
    return {
      ok: transcrits.length >= min,
      reason: 'too_few_words',
      words_transcribed: transcrits.length,
    };
  }
  const r = recouvrement(reference, transcrits);
  const seuil = tauxEntreZeroEtUn(env.VERIFY_MIN_OVERLAP, VERIFY_MIN_OVERLAP_DEFAUT);
  return {
    ok: r.overlap >= seuil,
    reason: 'low_overlap',
    overlap: r.overlap,
    words_hit: r.hit,
    words_ref: r.ref,
    words_transcribed: r.transcribed,
  };
}

/**
 * Mots de référence du texte [textId] (`corpus/<textId>.json`, publié par
 * scripts/publish-corpus.mjs), ou null s'il n'y en a pas.
 */
async function chargerReference(bucket, textId) {
  if (!textId) return null;
  const objet = await bucket.get(`corpus/${textId}.json`);
  if (!objet) return null;
  let data;
  try {
    data = await objet.json();
  } catch {
    return null;
  }
  if (!data || !Array.isArray(data.words)) return null;
  return data.words.filter((mot) => typeof mot === 'string');
}

/**
 * Transcription par Workers AI. Écrit DÉFENSIVEMENT : la forme exacte de
 * l'entrée et de la sortie de `@cf/openai/whisper` ne se confirme qu'au
 * premier déploiement.
 *   - entrée : { audio: [...octets] } ; on tente d'abord AVEC `language`
 *     (X-Language) et, si le modèle refuse ce champ, une seconde fois sans ;
 *   - sortie : { text } ou { transcription_info, text } (ou une chaîne nue) ;
 *     toute autre forme → null (verdict `ai_response_format`).
 * Jette si le modèle échoue les deux fois.
 */
async function transcrire(ai, audio, language) {
  const octets = [...new Uint8Array(audio)];
  let reponse;
  try {
    reponse = await ai.run(MODELE_TRANSCRIPTION, { audio: octets, language });
  } catch {
    reponse = await ai.run(MODELE_TRANSCRIPTION, { audio: octets });
  }
  return extraireTexte(reponse);
}

function extraireTexte(reponse) {
  if (typeof reponse === 'string') return reponse;
  if (!reponse || typeof reponse !== 'object') return null;
  if (typeof reponse.text === 'string') return reponse.text;
  if (reponse.result && typeof reponse.result.text === 'string') return reponse.result.text;
  if (typeof reponse.transcription === 'string') return reponse.transcription;
  return null;
}

/** Var wrangler → taux dans [0, 1], sinon [defaut]. */
function tauxEntreZeroEtUn(raw, defaut) {
  const n = parseFloat(raw);
  return Number.isFinite(n) && n >= 0 && n <= 1 ? n : defaut;
}

/** Var wrangler → entier ≥ 0, sinon [defaut]. */
function entierPositif(raw, defaut) {
  const n = parseInt(raw, 10);
  return Number.isInteger(n) && n >= 0 ? n : defaut;
}

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

/**
 * Reprend les enregistrements restés SANS VERDICT — ceux dont la transcription
 * n'a pas pu avoir lieu au dépôt (modèle en panne, allocation de neurones du
 * jour épuisée, worker redémarré au mauvais moment).
 *
 * POURQUOI UN CRON. La transcription n'a lieu qu'une fois, dans le `waitUntil`
 * du dépôt. Sans reprise, un enregistrement sans verdict reste « en attente »
 * POUR TOUJOURS : `/validate` répond 409 indéfiniment et la personne n'obtient
 * jamais ses résultats. Ne pas écrire de verdict en cas de panne (voir
 * RAISONS_INFRASTRUCTURE) n'a donc de sens qu'avec cette reprise.
 *
 * Bornes, parce que chaque reprise coûte des neurones :
 *   - `VERIFY_RETRY_MAX` fichiers repris au plus par exécution (défaut 200) ;
 *   - `VERIFY_RETRY_GIVE_UP` échecs d'infrastructure CONSÉCUTIFS et on arrête
 *     (défaut 5) : si l'allocation est de nouveau épuisée, inutile de brûler
 *     le temps du cron pour rien — le lendemain reprendra la suite ;
 *   - les enregistrements trop vieux pour être encore utiles (au-delà de
 *     `RETENTION_DAYS`) ne sont pas repris.
 */
async function reprendreVerifications(env) {
  if (!env.AUDIO_BUCKET || !env.AI) return { repris: 0, ecrits: 0 };
  const maxReprises = entierPositif(env.VERIFY_RETRY_MAX, 200);
  const abandonApres = entierPositif(env.VERIFY_RETRY_GIVE_UP, 5);
  const retentionDays = parseInt(env.RETENTION_DAYS || '30', 10);
  const cutoff = Date.now() - retentionDays * 86400 * 1000;
  let repris = 0;
  let ecrits = 0;
  let echecsConsecutifs = 0;

  for (const prefix of ['reusable/', 'internal/']) {
    let cursor;
    do {
      const listed = await env.AUDIO_BUCKET.list({ prefix, cursor, limit: 1000, include: ['customMetadata'] });
      for (const obj of listed.objects) {
        if (repris >= maxReprises || echecsConsecutifs >= abandonApres) return { repris, ecrits };
        const meta = obj.customMetadata || {};
        const recordType = meta.record_type;
        if (recordType !== RECORD_TYPE_READING && recordType !== RECORD_TYPE_SUMMARY) continue;
        if (obj.uploaded && obj.uploaded.getTime() < cutoff) continue;
        const account = meta.account;
        const sessionId = meta.session_id;
        if (!account || !sessionId) continue;
        const cleVerdict = `verified/${account}/${sessionId}/${recordType}-${meta.text_id || 'na'}.json`;
        if (await env.AUDIO_BUCKET.head(cleVerdict)) continue; // déjà jugé

        const objet = await env.AUDIO_BUCKET.get(obj.key);
        if (!objet) continue; // supprimé entre le list et le get
        repris++;
        await verifierEnregistrement(env, {
          account,
          sessionId,
          recordType,
          textId: meta.text_id || '',
          language: meta.language || 'fr',
          audio: await objet.arrayBuffer(),
        });
        // Un verdict écrit = la reprise a abouti (jugement rendu, quel qu'il soit).
        if (await env.AUDIO_BUCKET.head(cleVerdict)) { ecrits++; echecsConsecutifs = 0; }
        else echecsConsecutifs++;
      }
      cursor = listed.truncated ? listed.cursor : undefined;
    } while (cursor);
  }
  return { repris, ecrits };
}

/**
 * Format admis pour tout fragment de clé R2 : lettres, chiffres, tiret,
 * souligné, 80 caractères au plus. Les valeurs réelles de l'app le respectent
 * toutes : UUID v4 (session), `fr_0042` (texte), `C`/`D` (couche),
 * `reading`/`summary` (type), `fr`/`en-GB` (langue).
 */
const FORMAT_CHAMP = /^[A-Za-z0-9_-]{1,80}$/;

/**
 * Lit les fragments de clé portés par les en-têtes et REFUSE ceux qui sortent
 * du format, au lieu de les nettoyer.
 *
 * POURQUOI REFUSER PLUTÔT QUE NETTOYER. L'ancienne `sanitize()` supprimait les
 * caractères interdits : `sess/1` et `sess?1` se repliaient tous deux sur
 * `sess1`. Deux sessions distinctes finissaient donc dans le MÊME dossier R2,
 * et un effacement art. 17 ciblé sur l'une emportait l'autre — ou la manquait.
 * La granularité de l'effacement dépend de l'injectivité de la clé : un nom
 * qu'on ne peut pas écrire fidèlement doit être refusé, pas déformé.
 *
 * Renvoie {sessionId, textId, layer, recordType, language} ou {erreur: <en-tête>}.
 * Un en-tête absent ou vide retombe sur son défaut (aucune régression pour les
 * clients qui ne les envoient pas) ; seule une valeur PRÉSENTE et hors format
 * est refusée.
 */
function lisChamps(request) {
  const attendus = [
    ['sessionId', 'X-Session-Id', ''],
    ['textId', 'X-Text-Id', ''],
    ['layer', 'X-Layer', 'C'],
    ['recordType', 'X-Record-Type', 'audio'],
    ['language', 'X-Language', 'fr'],
  ];
  const lus = {};
  for (const [nom, entete, defaut] of attendus) {
    const brut = request.headers.get(entete);
    if (brut === null || brut === '') {
      lus[nom] = defaut;
      continue;
    }
    if (!FORMAT_CHAMP.test(brut)) return { erreur: entete };
    lus[nom] = brut;
  }
  return lus;
}

/**
 * Versions de textes légaux admises : CSV de la var wrangler LEGAL_VERSIONS.
 * MÊME CONVENTION que `parseLegalVersions()` du tokeniser — la liste vit des
 * deux côtés (émission ET écriture) pour que retirer une version suffise à
 * bloquer les nouveaux uploads qui s'en réclament, sans ré-émettre de passe.
 */
function versionsLegales(env) {
  const raw = typeof env.LEGAL_VERSIONS === 'string' ? env.LEGAL_VERSIONS : '';
  return raw.split(',').map((s) => s.trim()).filter((s) => s.length > 0);
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
