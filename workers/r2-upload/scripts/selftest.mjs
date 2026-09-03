#!/usr/bin/env node
/**
 * Auto-test du worker r2-upload (stockage des enregistrements vocaux).
 *
 *   node workers/r2-upload/scripts/selftest.mjs
 *
 * Aucune dépendance, aucun réseau, aucun compte Cloudflare : le worker de
 * production est importé tel quel et branché sur un bucket R2 en mémoire.
 *
 * POURQUOI CE FICHIER. C'est le worker le plus exposé juridiquement du dépôt :
 * il décide si un enregistrement vocal part dans `reusable/` (cessible à des
 * tiers) ou dans `internal/`. Une erreur ici ne casse pas une fonctionnalité,
 * elle fabrique un consentement qui n'existe pas. Les assertions ci-dessous
 * verrouillent donc quatre choses, dans cet ordre d'importance :
 *
 *   1. AUCUN passe non signé n'entre. Contrairement au worker referral, il n'y
 *      a ici AUCUN repli « M2.<claims> » : le repli DEV est vérifié comme un
 *      refus, pas comme une commodité.
 *   2. LE SCHÉMA 2 N'ATTEINT PLUS `reusable/`, JAMAIS. C'est LA régression à
 *      verrouiller à jamais. Un passe sv 2 SIGNÉ — que n'importe qui obtient en
 *      POSTant {s,y,m,r} au tokeniser public, ce qui est l'invariant de
 *      production — suffisait à écrire un fichier classé « cessible à des
 *      tiers » dont la seule preuve de consentement était une chaîne choisie
 *      par l'appelant (`X-Consent-Version: JE-NAI-RIEN-SIGNE`, HTTP 200 obtenu
 *      par un auditeur le 2026-09-02). Le sv 2 continue d'uploader — sinon
 *      l'app live cesse d'envoyer — mais en `internal/` et rien d'autre.
 *   3. En schéma 3, les CLAIMS SIGNÉES font autorité et les en-têtes client
 *      sont ignorés : on envoie exprès des en-têtes qui MENTENT (X-Commercial-
 *      Reuse contraire à `cc`) et on vérifie que le passe gagne.
 *   4. La `cv` d'un sv 3 doit appartenir à LEGAL_VERSIONS. La preuve archivée
 *      avec le fichier doit renvoyer à un texte que CE worker connaît ; sans
 *      liste configurée il ne peut rien écrire (500, fail-closed).
 *   5. La VÉRIFICATION des enregistrements (transcription Workers AI en tâche
 *      de fond, verdict `verified/…`) ne bloque jamais l'upload, n'écrit
 *      jamais un mot transcrit, et rend le verdict attendu pour chaque cas
 *      (recouvrement suffisant / insuffisant, référence absente, IA absente
 *      ou en panne, résumé trop court). `env.AI` est un binding factice
 *      pilotable ; `ctx` collecte les promesses de `waitUntil` et les attend.
 *
 * Comme dans `workers/event/scripts/selftest.mjs`, on forge un vrai couple de
 * clés Ed25519 et on enregistre la publique dans `TOKEN_SIGNING_PUBLIC_KEYS`
 * (propriétés mutables) : la vérification exercée est la VRAIE, sans ouvrir de
 * couture d'injection dans le code de production.
 *
 * À lancer avant chaque `wrangler deploy` du worker r2-upload.
 */

import worker from '../index.js';
import { TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../../_shared/token_verify.js';
import { motsDistincts, recouvrement } from '../../_shared/text_norm.js';

const b64u = (bytes) => Buffer.from(bytes).toString('base64url');
const segment = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');

/** Forge un couple de clés Ed25519 et enregistre la publique sous [kid]. */
async function keypair(kid) {
  const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
  const raw = new Uint8Array(await crypto.subtle.exportKey('raw', kp.publicKey));
  TOKEN_SIGNING_PUBLIC_KEYS[kid] = b64u(raw);
  return { kid, privee: kp.privateKey };
}

/** Token signé (JWS compact EdDSA) portant [claims] — la forme de production. */
async function signe({ kid, privee }, claims) {
  const input = `${segment({ alg: 'EdDSA', kid })}.${segment(claims)}`;
  const sig = await crypto.subtle.sign(
    { name: 'Ed25519' },
    privee,
    new TextEncoder().encode(input),
  );
  return `${input}.${b64u(new Uint8Array(sig))}`;
}

const cle = await keypair('ktest');

const NONCE = 'nonce-r2-a';
const CV = '2026-09-02.v1';

/** Claims démographiques communes (sv 2 comme sv 3 les portent). */
const base = { s: 'M', y: 1998, m: 7, r: 'IDF', d: 20700, n: NONCE };

const TOKEN_SV2 = await signe(cle, { ...base, sv: 2 });
const TOKEN_FREE_CC = await signe(cle, { ...base, p: 'free', cc: true, cv: CV, sv: 3 });
const TOKEN_FREE_SANS_CC = await signe(cle, { ...base, p: 'free', cc: false, cv: CV, sv: 3 });
const TOKEN_PAID = await signe(cle, { ...base, p: 'paid', cc: false, cv: CV, sv: 3 });
// Schéma inconnu : refusé en amont par `verifyToken` (`schema_version`).
const TOKEN_SV4 = await signe(cle, { ...base, p: 'free', cc: true, cv: CV, sv: 4 });
// Plan hors liste : la forme stricte de `verifyToken` le refuse (`claims`),
// AVANT même que `readPlan` n'ait à en décider.
const TOKEN_PLAN_INCONNU = await signe(cle, { ...base, p: 'gold', cc: true, cv: CV, sv: 3 });
// Passe DEV non signé, celui qu'accepte le worker referral. Doit être REFUSÉ ici.
const TOKEN_DEV = 'M2.' + segment({ ...base, p: 'free', cc: true, cv: CV, sv: 3 });
// Signature abîmée (4 derniers caractères remplacés) : octets signés intacts,
// signature fausse.
const TOKEN_ALTERE = TOKEN_FREE_CC.slice(0, -4) + 'AAAA';
// Passe sv 3 PARFAITEMENT SIGNÉ mais dont la `cv` a été retirée de
// LEGAL_VERSIONS (version révoquée, ou passe d'un autre déploiement). Sa forme
// satisfait `verifyToken` : seul ce worker peut le refuser.
const TOKEN_FREE_CV_INCONNUE =
  await signe(cle, { ...base, p: 'free', cc: true, cv: '1999-01-01.v0', sv: 3 });

const ACCOUNT = (await sha256hex(NONCE)).slice(0, 32);

const SESSION = 'sess1234';
const MAX_BYTES = 25 * 1024 * 1024;

/** Bucket R2 en mémoire, même contrat que le binding Cloudflare. */
function bucket({ echoue = false } = {}) {
  const m = new Map();
  return {
    _m: m,
    put: async (key, value, options) => {
      if (echoue) throw new Error('R2 indisponible');
      m.set(key, { value, options });
      return {};
    },
    head: async (key) => (m.has(key) ? {} : null),
    get: async (key) => {
      if (!m.has(key)) return null;
      const texte = String(m.get(key).value);
      return { text: async () => texte, json: async () => JSON.parse(texte) };
    },
    list: async () => ({ objects: [], truncated: false }),
    delete: async (key) => { m.delete(key); },
  };
}

/** Clés AUDIO écrites (hors verdicts `verified/` et références `corpus/` semées). */
const clesAudio = (store) =>
  [...store._m.keys()].filter((k) => k.startsWith('reusable/') || k.startsWith('internal/'));

/** La seule clé AUDIO écrite par un appel (les cas nominaux n'en écrivent qu'une). */
function seuleCle(store) {
  return clesAudio(store)[0] || '';
}

/** Les `customMetadata` de la seule clé AUDIO écrite. */
function metas(store) {
  const cle = seuleCle(store);
  const entree = cle ? store._m.get(cle) : null;
  return entree ? entree.options.customMetadata : {};
}

/** Première clé de verdict écrite, et son contenu JSON. */
const cleVerdict = (store) => [...store._m.keys()].find((k) => k.startsWith('verified/')) || '';
function verdict(store) {
  const cle = cleVerdict(store);
  return cle ? JSON.parse(String(store._m.get(cle).value)) : null;
}

/** Sème la référence `corpus/<id>.json` telle que la publie publish-corpus.mjs. */
async function semerReference(store, id, texte) {
  await store.put(`corpus/${id}.json`, JSON.stringify({ id, lang: 'fr', words: motsDistincts(texte) }));
}

/**
 * `ctx` d'exécution factice : collecte les promesses passées à `waitUntil`
 * pour que le test puisse les ATTENDRE (en production, c'est le runtime qui
 * garde le worker vivant jusqu'à leur fin).
 */
function contexte() {
  const promesses = [];
  return {
    _promesses: promesses,
    waitUntil: (p) => { promesses.push(p); },
    attendre: () => Promise.all(promesses),
  };
}

/**
 * Binding Workers AI factice, pilotable :
 *   - texte         : transcription renvoyée (forme { text }) ;
 *   - reponse       : objet renvoyé tel quel (prend le pas sur `texte`) ;
 *   - jette         : toute invocation échoue ;
 *   - rejetteLangue : refuse une entrée qui porte `language` (comme un modèle
 *                     dont le schéma ne connaît pas ce champ) ;
 *   - differee      : ne répond qu'après `liberer()` (prouve que la réponse
 *                     HTTP n'attend pas la transcription).
 * Journalise chaque appel dans `_appels` ({ modele, input }).
 */
function iaFactice({ texte = '', reponse, jette = false, rejetteLangue = false, differee = false } = {}) {
  const appels = [];
  let liberer = () => {};
  const barriere = new Promise((resolve) => { liberer = resolve; });
  return {
    _appels: appels,
    liberer: () => liberer(),
    run: async (modele, input) => {
      appels.push({ modele, input });
      if (jette) throw new Error('AI indisponible');
      if (rejetteLangue && input && input.language !== undefined) {
        throw new Error('input does not match schema: unknown property language');
      }
      if (differee) await barriere;
      return reponse !== undefined ? reponse : { text: texte };
    },
  };
}

/**
 * Un appel au worker. [entetes] écrase les en-têtes par défaut ; une valeur
 * `null` supprime l'en-tête (pour tester son absence).
 */
async function appel(store, {
  method = 'POST',
  token = TOKEN_FREE_CC,
  corps = new Uint8Array(1024),
  sansCorps = false,
  entetes = {},
  env,
  ai,
} = {}) {
  const headers = {
    'Content-Type': 'audio/webm',
    'X-Mentality-Token': token,
    'X-Session-Id': SESSION,
    'X-Text-Id': 'txt1',
    'X-Layer': 'C',
    'X-Record-Type': 'reading',
    'X-Duration-Seconds': '42',
    'X-Language': 'fr',
    ...entetes,
  };
  if (token === null) delete headers['X-Mentality-Token'];
  for (const [k, v] of Object.entries(headers)) if (v === null) delete headers[k];

  const ctx = contexte();
  const resp = await worker.fetch(
    new Request('https://selftest/', {
      method,
      headers,
      body: sansCorps ? undefined : corps,
    }),
    // Env par défaut = la configuration de PRODUCTION (wrangler.toml) : bucket
    // lié ET LEGAL_VERSIONS renseignée. Les scénarios de mauvaise configuration
    // passent leur propre `env` explicitement. `AI` n'est lié que si le
    // scénario fournit un binding factice (sinon : verdict `ai_unavailable`).
    env !== undefined ? env : { AUDIO_BUCKET: store, LEGAL_VERSIONS: CV, ...(ai ? { AI: ai } : {}) },
    ctx,
  );
  const texte = await resp.text();
  let json = null;
  try { json = JSON.parse(texte); } catch { /* réponse sans corps (204) */ }
  // On attend la vérification de fond AVANT de rendre la main : les assertions
  // sur le bucket sont ainsi déterministes.
  await ctx.attendre();
  return { statut: resp.status, corps: json, entetes: resp.headers, ctx };
}

let ok = 0;
const echecs = [];
function verifie(nom, condition, detail = '') {
  if (condition) { ok++; console.log(`  ✓ ${nom}`); }
  else { echecs.push(nom); console.log(`  ✗ ${nom}  ${detail}`); }
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nGarde de signature : aucun passe non signé n\'écrit d\'audio');
{
  const s = bucket();

  const sans = await appel(s, { token: null });
  verifie('sans passe → 401', sans.statut === 401, `= ${sans.statut}`);

  const dev = await appel(s, { token: TOKEN_DEV });
  verifie('passe DEV « M2. » sv 3 free → 401 (aucun repli M2 ici : garantie juridique)',
    dev.statut === 401, `= ${dev.statut} ${JSON.stringify(dev.corps)}`);

  const altere = await appel(s, { token: TOKEN_ALTERE });
  verifie('signature altérée → 401', altere.statut === 401, `= ${altere.statut}`);

  const sv4 = await appel(s, { token: TOKEN_SV4 });
  verifie('schéma sv 4 signé → 401 (version inconnue)',
    sv4.statut === 401, `= ${sv4.statut}`);

  const gold = await appel(s, { token: TOKEN_PLAN_INCONNU });
  verifie('sv 3 signé avec p:\'gold\' → 401 (forme stricte des claims)',
    gold.statut === 401, `= ${gold.statut}`);

  verifie('aucun objet écrit par un passe refusé', s._m.size === 0, `${s._m.size} objets`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nSchéma 2 (passes historiques) : uploads conservés, couche cessible FERMÉE');
{
  const sansConsent = bucket();
  const r0 = await appel(sansConsent, {
    token: TOKEN_SV2,
    entetes: { 'X-Consent-Version': null, 'X-Commercial-Reuse': 'true' },
  });
  verifie('sv 2 sans X-Consent-Version → 403', r0.statut === 403, `= ${r0.statut}`);
  verifie('sv 2 refusé : rien écrit', sansConsent._m.size === 0, `${sansConsent._m.size} objets`);

  // ─── (a) L'EXPLOIT PROUVÉ, REJOUÉ TEL QUEL ─────────────────────────────────
  // Passe sv 2 signé (obtenable par quiconque via le tokeniser public), aucun
  // Origin (la garde d'origine ne s'applique qu'à un Origin NON VIDE), et deux
  // en-têtes menteurs. Avant correctif : HTTP 200, objet sous `reusable/`,
  // consent_version = 'JE-NAI-RIEN-SIGNE'. NE JAMAIS ASSOUPLIR CES LIGNES.
  const cessible = bucket();
  const r1 = await appel(cessible, {
    token: TOKEN_SV2,
    entetes: {
      Origin: null,
      'X-Consent-Version': 'JE-NAI-RIEN-SIGNE',
      'X-Commercial-Reuse': 'true',
    },
  });
  verifie('sv 2 + en-têtes menteurs → 200 (l\'upload historique marche encore)',
    r1.statut === 200, `= ${r1.statut}`);
  verifie('(a) sv 2 + X-Commercial-Reuse:true → clé préfixée « internal/ »',
    seuleCle(cessible).startsWith('internal/'), seuleCle(cessible));
  verifie('(a) sv 2 + X-Commercial-Reuse:true → JAMAIS « reusable/ » [exploit fermé]',
    !seuleCle(cessible).startsWith('reusable/'), seuleCle(cessible));
  verifie('(a) sv 2 → réponse reusable:false, quoi qu\'ait demandé l\'appelant',
    (r1.corps || {}).reusable === false, JSON.stringify(r1.corps));
  verifie('(a) sv 2 → customMetadata.commercial_reuse = « false » (miroir du préfixe)',
    metas(cessible).commercial_reuse === 'false', metas(cessible).commercial_reuse);
  verifie('(a) sv 2 → aucun objet cessible, tous préfixes confondus',
    [...cessible._m.keys()].every((k) => !k.startsWith('reusable/')),
    [...cessible._m.keys()].join(','));

  // Variantes de casse et de graphie : rien ne doit rouvrir la couche cessible.
  for (const valeur of ['TRUE', 'True', ' true', '1', 'yes', 'true,true']) {
    const s = bucket();
    await appel(s, {
      token: TOKEN_SV2,
      entetes: { 'X-Consent-Version': '2026-03-01.v1', 'X-Commercial-Reuse': valeur },
    });
    verifie(`(a) sv 2 + X-Commercial-Reuse:${JSON.stringify(valeur)} → « internal/ »`,
      seuleCle(s).startsWith('internal/'), seuleCle(s));
  }

  const interne = bucket();
  await appel(interne, {
    token: TOKEN_SV2,
    entetes: { 'X-Consent-Version': '2026-03-01.v1', 'X-Commercial-Reuse': 'false' },
  });
  verifie('sv 2 X-Commercial-Reuse:false → clé préfixée « internal/ »',
    seuleCle(interne).startsWith('internal/'), seuleCle(interne));

  const m = metas(interne);
  verifie('sv 2 → consent_source = « header »', m.consent_source === 'header', m.consent_source);
  verifie('sv 2 → plan = « legacy »', m.plan === 'legacy', m.plan);
  verifie('sv 2 → consent_version repris de l\'en-tête',
    m.consent_version === '2026-03-01.v1', m.consent_version);

  // Le durcissement ne dépend pas de LEGAL_VERSIONS : le sv 2 n'y est pas
  // soumis (sinon les passes en circulation cesseraient d'envoyer).
  const sansListe = bucket();
  const r2 = await appel(sansListe, {
    token: TOKEN_SV2,
    entetes: { 'X-Consent-Version': '2026-03-01.v1', 'X-Commercial-Reuse': 'true' },
    env: { AUDIO_BUCKET: sansListe },
  });
  verifie('sv 2 sans LEGAL_VERSIONS → 200 en « internal/ » (passes déjà distribués)',
    r2.statut === 200 && seuleCle(sansListe).startsWith('internal/'),
    `${r2.statut} ${seuleCle(sansListe)}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nSchéma 3 : les claims signées font autorité, les en-têtes mentent');
{
  const paye = bucket();
  const rPaid = await appel(paye, {
    token: TOKEN_PAID,
    entetes: { 'X-Consent-Version': CV, 'X-Commercial-Reuse': 'true' },
  });
  verifie('plan payant → 403 malgré un en-tête de réutilisation à true',
    rPaid.statut === 403, `= ${rPaid.statut}`);
  verifie('plan payant → message explicite',
    (rPaid.corps || {}).error === 'Plan payant : aucun enregistrement vocal',
    JSON.stringify(rPaid.corps));
  verifie('plan payant → RIEN écrit dans R2', paye._m.size === 0, `${paye._m.size} objets`);

  const cessible = bucket();
  const rFree = await appel(cessible, {
    token: TOKEN_FREE_CC,
    entetes: { 'X-Consent-Version': 'version-mensongere', 'X-Commercial-Reuse': 'false' },
  });
  verifie('free cc:true + en-tête « false » → 200', rFree.statut === 200, `= ${rFree.statut}`);
  verifie('free cc:true + en-tête « false » → « reusable/ » (le passe gagne)',
    seuleCle(cessible).startsWith('reusable/'), seuleCle(cessible));
  verifie('free cc:true → réponse reusable:true',
    (rFree.corps || {}).reusable === true, JSON.stringify(rFree.corps));

  const interne = bucket();
  await appel(interne, {
    token: TOKEN_FREE_SANS_CC,
    entetes: { 'X-Consent-Version': CV, 'X-Commercial-Reuse': 'true' },
  });
  verifie('free cc:false + en-tête « true » → « internal/ » (le passe gagne)',
    seuleCle(interne).startsWith('internal/'), seuleCle(interne));

  const sansEntete = bucket();
  const rNu = await appel(sansEntete, {
    token: TOKEN_FREE_CC,
    entetes: { 'X-Consent-Version': null, 'X-Commercial-Reuse': null },
  });
  verifie('free sans X-Consent-Version → 200 (l\'en-tête n\'est plus requis)',
    rNu.statut === 200, `= ${rNu.statut}`);

  const m = metas(sansEntete);
  verifie('sv 3 → consent_version = cv du passe', m.consent_version === CV, m.consent_version);
  verifie('sv 3 → plan = « free »', m.plan === 'free', m.plan);
  verifie('sv 3 → consent_source = « token »', m.consent_source === 'token', m.consent_source);
  verifie('sv 3 → account = sha256(nonce) tronqué à 32',
    m.account === ACCOUNT && m.account.length === 32, `${m.account} ≠ ${ACCOUNT}`);
  verifie('sv 3 → la clé est bien rangée sous l\'account dérivé du nonce',
    seuleCle(sansEntete).startsWith(`reusable/${ACCOUNT}/${SESSION}/`), seuleCle(sansEntete));

  // ─── (b) LE CHEMIN LÉGITIME RESTE OUVERT ───────────────────────────────────
  // Durcir le sv 2 n'a de sens que si le sv 3 consenti continue d'alimenter le
  // corpus : sans cette assertion, « tout en internal/ » passerait aussi.
  const legitime = bucket();
  const rOk = await appel(legitime, { token: TOKEN_FREE_CC });
  verifie('(b) sv 3 free/cc:true + cv allow-listée → 200 sous « reusable/ »',
    rOk.statut === 200 && seuleCle(legitime).startsWith('reusable/'),
    `${rOk.statut} ${seuleCle(legitime)}`);
  verifie('(b) … et sa preuve est la cv SIGNÉE, pas un en-tête',
    metas(legitime).consent_version === CV && metas(legitime).consent_source === 'token',
    JSON.stringify(metas(legitime)));
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nLEGAL_VERSIONS : la preuve archivée doit renvoyer à un texte connu');
{
  // ─── (c) VERSION HORS LISTE → 403, RIEN ÉCRIT ──────────────────────────────
  // C'est le levier de RÉVOCATION : retirer une version de LEGAL_VERSIONS
  // bloque les nouveaux uploads qui s'en réclament, sans ré-émettre un passe.
  const revoque = bucket();
  const rKo = await appel(revoque, { token: TOKEN_FREE_CV_INCONNUE });
  verifie('(c) sv 3 avec cv hors LEGAL_VERSIONS → 403', rKo.statut === 403, `= ${rKo.statut}`);
  verifie('(c) sv 3 cv inconnue → code LEGAL_VERSION_UNKNOWN',
    (rKo.corps || {}).code === 'LEGAL_VERSION_UNKNOWN', JSON.stringify(rKo.corps));
  verifie('(c) sv 3 cv inconnue → RIEN écrit dans R2',
    revoque._m.size === 0, `${revoque._m.size} objets`);

  // Une cv révoquée ne doit pas non plus retomber discrètement en `internal/`.
  verifie('(c) sv 3 cv inconnue → aucune clé, ni cessible ni interne',
    [...revoque._m.keys()].length === 0, [...revoque._m.keys()].join(','));

  // La liste accepte plusieurs versions (transition entre deux textes).
  const transition = bucket();
  const rTrans = await appel(transition, {
    token: TOKEN_FREE_CV_INCONNUE,
    env: { AUDIO_BUCKET: transition, LEGAL_VERSIONS: ` ${CV} , 1999-01-01.v0 ` },
  });
  verifie('CSV multi-versions (espaces compris) → la cv listée est acceptée',
    rTrans.statut === 200 && seuleCle(transition).startsWith('reusable/'),
    `${rTrans.statut} ${seuleCle(transition)}`);

  // ─── (d) LISTE ABSENTE OU VIDE → 500, FAIL-CLOSED ──────────────────────────
  for (const [nom, vars] of [
    ['absente', {}],
    ['vide', { LEGAL_VERSIONS: '' }],
    ['blanche', { LEGAL_VERSIONS: '   ,  ' }],
    ['non-chaîne', { LEGAL_VERSIONS: 42 }],
  ]) {
    const s = bucket();
    const r = await appel(s, {
      token: TOKEN_FREE_CC,
      env: { AUDIO_BUCKET: s, ...vars },
    });
    verifie(`(d) LEGAL_VERSIONS ${nom} → 500 SERVER_MISCONFIGURED`,
      r.statut === 500 && (r.corps || {}).code === 'SERVER_MISCONFIGURED',
      `${r.statut} ${JSON.stringify(r.corps)}`);
    verifie(`(d) LEGAL_VERSIONS ${nom} → RIEN écrit (fail-closed)`,
      s._m.size === 0, `${s._m.size} objets`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nCorps, en-têtes de requête et pannes');
{
  const s = bucket();

  const sansSession = await appel(s, { entetes: { 'X-Session-Id': null } });
  verifie('sans X-Session-Id → 400', sansSession.statut === 400, `= ${sansSession.statut}`);

  const typeInterdit = await appel(s, { entetes: { 'Content-Type': 'application/json' } });
  verifie('Content-Type non audio → 415', typeInterdit.statut === 415, `= ${typeInterdit.statut}`);

  const vide = await appel(s, { corps: new Uint8Array(0) });
  verifie('corps vide → 400', vide.statut === 400, `= ${vide.statut}`);

  const trop = await appel(s, { corps: new Uint8Array(MAX_BYTES + 1) });
  verifie('corps > 25 Mo → 413', trop.statut === 413, `= ${trop.statut}`);

  verifie('aucun objet écrit par une requête malformée', s._m.size === 0, `${s._m.size} objets`);

  const casse = bucket({ echoue: true });
  const panne = await appel(casse);
  verifie('écriture R2 qui jette → 502 (le client rejouera)',
    panne.statut === 502, `= ${panne.statut}`);

  const sansBinding = await appel(null, { env: {} });
  verifie('bucket non lié → 500', sansBinding.statut === 500, `= ${sansBinding.statut}`);

  const s2 = bucket();
  const etrangere = await appel(s2, { entetes: { Origin: 'https://pirate.example' } });
  verifie('Origin non autorisée → 403', etrangere.statut === 403, `= ${etrangere.statut}`);
  verifie('rien écrit après un refus d\'origine', s2._m.size === 0, `${s2._m.size} objets`);

  const sansOrigine = await appel(s2);
  verifie('Origin absente (client mobile natif) → 200',
    sansOrigine.statut === 200, `= ${sansOrigine.statut}`);

  const autorisee = await appel(bucket(), {
    entetes: { Origin: 'https://mentality-flutter-web.pages.dev' },
  });
  verifie('Origin autorisée → 200', autorisee.statut === 200, `= ${autorisee.statut}`);

  const options = await appel(bucket(), { method: 'OPTIONS', sansCorps: true });
  verifie('OPTIONS → 204 préflight', options.statut === 204, `= ${options.statut}`);

  const mauvaiseMethode = await appel(bucket(), { method: 'GET', sansCorps: true });
  verifie('GET → 405 (aucune lecture cliente)',
    mauvaiseMethode.statut === 405, `= ${mauvaiseMethode.statut}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nFragments de clé : on REFUSE le hors-format, on ne le nettoie plus');
{
  // POURQUOI. L'ancienne `sanitize()` supprimait les caractères interdits :
  // 'sess/1' et 'sess?1' se repliaient tous deux sur 'sess1'. Deux sessions
  // distinctes atterrissaient dans le MÊME dossier R2, et un effacement art. 17
  // ciblé sur l'une emportait l'autre — ou la manquait. La granularité de
  // l'effacement suppose une clé INJECTIVE : un nom qu'on ne peut pas écrire
  // fidèlement doit être refusé, pas déformé.
  const collisions = [
    ['X-Session-Id', 'sess/1'],
    ['X-Session-Id', 'sess?1'],
    ['X-Session-Id', '../autrui'],
    ['X-Session-Id', 'a'.repeat(81)],
    ['X-Session-Id', 'sess 1'],
    ['X-Text-Id', 'fr/0042'],
    ['X-Layer', 'C/../..'],
    ['X-Record-Type', 'reading;rm'],
    // Un point suffit : c'est le caractere qui fabrique '..' dans une cle R2.
    ['X-Language', 'fr.FR'],
  ];
  for (const [entete, valeur] of collisions) {
    const s = bucket();
    const r = await appel(s, { entetes: { [entete]: valeur } });
    verifie(`${entete}: ${JSON.stringify(valeur)} → 400, aucun repli silencieux`,
      r.statut === 400 && (r.corps || {}).code === 'FIELD_FORMAT',
      `${r.statut} ${JSON.stringify(r.corps)}`);
    verifie(`${entete}: ${JSON.stringify(valeur)} → rien écrit`,
      s._m.size === 0, `${s._m.size} objets`);
  }

  // Deux sessions qui NE diffèrent que par un caractère interdit ne peuvent
  // plus se replier sur le même dossier : la seconde est refusée.
  const a = bucket();
  await appel(a, { entetes: { 'X-Session-Id': 'sess1' } });
  const b = await appel(a, { entetes: { 'X-Session-Id': 'sess.1' } });
  verifie('deux sessions ne peuvent plus fusionner par nettoyage (art. 17)',
    b.statut === 400 && clesAudio(a).length === 1
    && clesAudio(a)[0].includes('/sess1/'), `${b.statut} ${clesAudio(a)}`);

  // Les valeurs réelles de l'app restent acceptées, en-têtes absents compris.
  const vrai = bucket();
  const rVrai = await appel(vrai, {
    entetes: {
      'X-Session-Id': '3f2504e0-4f89-11d3-9a0c-0305e82c3301', // UUID v4
      'X-Text-Id': 'fr_0042',
      'X-Layer': 'C',
      'X-Record-Type': 'summary',
      'X-Language': 'en-GB',
    },
  });
  verifie('les valeurs réellement émises par l\'app passent (UUID, fr_0042, en-GB)',
    rVrai.statut === 200, `${rVrai.statut} ${JSON.stringify(rVrai.corps)}`);

  const defauts = bucket();
  await appel(defauts, {
    entetes: { 'X-Text-Id': null, 'X-Layer': null, 'X-Record-Type': null, 'X-Language': null },
  });
  const md = metas(defauts);
  verifie('en-têtes facultatifs absents → défauts appliqués, pas de refus',
    md.layer === 'C' && md.record_type === 'audio' && md.language === 'fr' && md.text_id === '',
    JSON.stringify(md));
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nNormalisation partagée (text_norm.js) : accents, ponctuation, mots courts');
{
  const memes = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const m1 = motsDistincts("L'École, c'est l'Été ! Peut-être qu'à Noël… ça ira.");
  verifie('minuscules, accents retirés, ponctuation/apostrophes séparatrices, mots < 4 exclus',
    memes(m1, ['ecole', 'peut', 'etre', 'noel']), JSON.stringify(m1));
  const m2 = motsDistincts('Le cœur de la Straße, à Übung.');
  verifie('ligatures et ß rabattus (cœur → coeur, Straße → strasse, Übung → ubung)',
    memes(m2, ['coeur', 'strasse', 'ubung']), JSON.stringify(m2));
  const m3 = motsDistincts('Rouge rouge ROUGE, rougé ; rouge.');
  verifie('mots DISTINCTS : les répétitions et variantes accentuées ne comptent qu\'une fois',
    memes(m3, ['rouge']), JSON.stringify(m3));
  const m4 = motsDistincts('« Vingt-deux » — 2024 : résumé/lecture\ttabulé\nligne');
  verifie('guillemets, tirets, barres, tabulations et retours = séparateurs ; chiffres gardés',
    memes(m4, ['vingt', 'deux', '2024', 'resume', 'lecture', 'tabule', 'ligne']), JSON.stringify(m4));
  verifie('entrée non textuelle → aucun mot, aucune exception',
    motsDistincts(null).length === 0 && motsDistincts(42).length === 0 && motsDistincts('').length === 0);
  const r = recouvrement(['ecole', 'peut', 'etre', 'noel'], ['noel', 'ecole', 'autre', 'autre']);
  verifie('recouvrement = mots de la référence retrouvés / taille de la référence',
    r.overlap === 0.5 && r.hit === 2 && r.ref === 4 && r.transcribed === 3, JSON.stringify(r));
  verifie('référence vide → recouvrement 0, jamais NaN',
    recouvrement([], ['mot']).overlap === 0 && recouvrement(null, null).overlap === 0);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nVérification des enregistrements : transcription de fond, verdict sans texte');
// Référence : 20 mots distincts de 4+ caractères, accentués pour exercer la
// normalisation des deux côtés (référence ET transcription).
const TEXTE_REF = 'La montagne, la rivière, la forêt, le village, le soleil, le nuage, le chemin, '
  + 'la maison, le jardin, la fenêtre, le bateau, le marché, l\'école, la musique, la lecture, '
  + 'l\'histoire, le voyage, la cuisine, la saison, la lumière.';
const MOTS_REF = motsDistincts(TEXTE_REF);
verifie('texte de référence du scénario : 20 mots distincts', MOTS_REF.length === 20, String(MOTS_REF.length));
// Transcriptions : 10 mots sur 20 (50 %), 2 sur 20 (10 %), avec du bruit.
const TRANSCRIPTION_50 = 'Euh la montagne la rivière et puis la forêt le village le soleil… '
  + 'nuage, chemin, maison, jardin, fenêtre. Voilà.';
const TRANSCRIPTION_10 = 'Bonjour bonjour, la montagne et la rivière, merci beaucoup.';
const ATTENDU_VERDICT = ['ok', 'reason', 'overlap', 'words_hit', 'words_ref', 'words_transcribed', 'model', 'day'];
{
  // ─── Lecture, 50 % des mots retrouvés → ok ─────────────────────────────────
  const s = bucket();
  await semerReference(s, 'txt1', TEXTE_REF);
  const ia = iaFactice({ texte: TRANSCRIPTION_50 });
  const r = await appel(s, { ai: ia });
  verifie('lecture : upload 200 et ctx.waitUntil appelé une fois',
    r.statut === 200 && r.ctx._promesses.length === 1, `${r.statut} ${r.ctx._promesses.length} promesse(s)`);
  verifie('lecture : verdict écrit sous verified/<account>/<session>/reading-<textId>.json',
    cleVerdict(s) === `verified/${ACCOUNT}/${SESSION}/reading-txt1.json`, cleVerdict(s));
  const v = verdict(s) || {};
  verifie('lecture 50 % → ok:true, overlap 0.5, 10 mots sur 20',
    v.ok === true && v.reason === null && v.overlap === 0.5 && v.words_hit === 10 && v.words_ref === 20,
    JSON.stringify(v));
  verifie('lecture : words_transcribed = mots distincts ≥ 4 de la transcription',
    v.words_transcribed === motsDistincts(TRANSCRIPTION_50).length, `${v.words_transcribed}`);
  verifie('verdict : exactement les champs prévus, rien d\'autre',
    JSON.stringify(Object.keys(v).sort()) === JSON.stringify([...ATTENDU_VERDICT].sort()),
    JSON.stringify(Object.keys(v)));
  verifie('verdict : jour seul (AAAA-MM-JJ), jamais l\'heure',
    /^\d{4}-\d{2}-\d{2}$/.test(v.day), String(v.day));
  verifie('verdict : modèle nommé', v.model === '@cf/openai/whisper', String(v.model));
  const brut = String(s._m.get(cleVerdict(s)).value)
    + JSON.stringify(s._m.get(cleVerdict(s)).options.customMetadata);
  verifie('verdict et ses métadonnées : AUCUN mot transcrit conservé',
    !motsDistincts(TRANSCRIPTION_50).some((mot) => brut.toLowerCase().includes(mot))
    && !brut.includes('montagne') && !brut.includes('Bonjour'), brut);
  verifie('modèle appelé avec les octets du fichier et la langue (X-Language)',
    ia._appels.length === 1 && ia._appels[0].modele === '@cf/openai/whisper'
    && Array.isArray(ia._appels[0].input.audio) && ia._appels[0].input.audio.length === 1024
    && ia._appels[0].input.language === 'fr',
    JSON.stringify(ia._appels.map((a) => ({ modele: a.modele, language: a.input.language, n: a.input.audio.length }))));
  verifie('la réponse HTTP ne dit rien du verdict (clé, taille, reusable seulement)',
    JSON.stringify(Object.keys(r.corps).sort()) === JSON.stringify(['key', 'reusable', 'size']),
    JSON.stringify(r.corps));

  // ─── Lecture, 10 % → ok:false ──────────────────────────────────────────────
  const s2 = bucket();
  await semerReference(s2, 'txt1', TEXTE_REF);
  await appel(s2, { ai: iaFactice({ texte: TRANSCRIPTION_10 }) });
  const v2 = verdict(s2) || {};
  verifie('lecture 10 % → ok:false, reason low_overlap, overlap 0.1',
    v2.ok === false && v2.reason === 'low_overlap' && v2.overlap === 0.1 && v2.words_hit === 2,
    JSON.stringify(v2));

  // ─── Seuil surchargé par la var ────────────────────────────────────────────
  const s3 = bucket();
  await semerReference(s3, 'txt1', TEXTE_REF);
  await appel(s3, {
    ai: iaFactice({ texte: TRANSCRIPTION_50 }),
    env: { AUDIO_BUCKET: s3, LEGAL_VERSIONS: CV, AI: iaFactice({ texte: TRANSCRIPTION_50 }), VERIFY_MIN_OVERLAP: '0.60' },
  });
  verifie('VERIFY_MIN_OVERLAP="0.60" : 50 % ne suffit plus → ok:false',
    (verdict(s3) || {}).ok === false && (verdict(s3) || {}).overlap === 0.5, JSON.stringify(verdict(s3)));
  const s3b = bucket();
  await semerReference(s3b, 'txt1', TEXTE_REF);
  await appel(s3b, {
    env: { AUDIO_BUCKET: s3b, LEGAL_VERSIONS: CV, AI: iaFactice({ texte: TRANSCRIPTION_10 }), VERIFY_MIN_OVERLAP: 'n\'importe quoi' },
  });
  verifie('VERIFY_MIN_OVERLAP illisible → défaut 0.30 (10 % refusé)',
    (verdict(s3b) || {}).ok === false, JSON.stringify(verdict(s3b)));

  // ─── Référence absente → no_reference, sans appeler l'IA ───────────────────
  const s4 = bucket();
  const ia4 = iaFactice({ texte: TRANSCRIPTION_50 });
  const r4 = await appel(s4, { ai: ia4, entetes: { 'X-Text-Id': 'txt-inconnu' } });
  const v4 = verdict(s4) || {};
  verifie('référence absente → upload 200, verdict ok:false no_reference',
    r4.statut === 200 && v4.ok === false && v4.reason === 'no_reference', `${r4.statut} ${JSON.stringify(v4)}`);
  verifie('référence absente → l\'IA n\'est PAS appelée (rien à comparer, rien à payer)',
    ia4._appels.length === 0, `${ia4._appels.length} appel(s)`);
  verifie('référence absente → verdict rangé sous le textId demandé',
    cleVerdict(s4).endsWith('/reading-txt-inconnu.json'), cleVerdict(s4));

  // ─── env.AI absent → ai_unavailable, upload intact ─────────────────────────
  const s5 = bucket();
  await semerReference(s5, 'txt1', TEXTE_REF);
  const r5 = await appel(s5); // aucun `ai` : l'env par défaut ne lie pas AI
  const v5 = verdict(s5) || {};
  verifie('env.AI absent → upload 200 quand même', r5.statut === 200 && seuleCle(s5).startsWith('reusable/'), `${r5.statut}`);
  verifie('env.AI absent → verdict ok:false ai_unavailable',
    v5.ok === false && v5.reason === 'ai_unavailable' && v5.overlap === null, JSON.stringify(v5));

  // ─── IA en panne → ai_error, upload intact ─────────────────────────────────
  const s6 = bucket();
  await semerReference(s6, 'txt1', TEXTE_REF);
  const r6 = await appel(s6, { ai: iaFactice({ jette: true }) });
  const v6 = verdict(s6) || {};
  verifie('IA qui jette → upload 200, verdict ok:false ai_error',
    r6.statut === 200 && v6.ok === false && v6.reason === 'ai_error', `${r6.statut} ${JSON.stringify(v6)}`);

  // ─── Le modèle refuse `language` → second essai sans, verdict quand même ───
  const s7 = bucket();
  await semerReference(s7, 'txt1', TEXTE_REF);
  const ia7 = iaFactice({ texte: TRANSCRIPTION_50, rejetteLangue: true });
  await appel(s7, { ai: ia7 });
  verifie('modèle refusant `language` → retenté sans le champ, verdict ok',
    ia7._appels.length === 2 && ia7._appels[0].input.language === 'fr'
    && ia7._appels[1].input.language === undefined && (verdict(s7) || {}).ok === true,
    `${ia7._appels.length} appel(s) ${JSON.stringify(verdict(s7))}`);

  // ─── Formes de réponse acceptées / refusées ────────────────────────────────
  const s8 = bucket();
  await semerReference(s8, 'txt1', TEXTE_REF);
  await appel(s8, { ai: iaFactice({ reponse: { transcription_info: { language: 'fr' }, text: TRANSCRIPTION_50 } }) });
  verifie('réponse { transcription_info, text } acceptée', (verdict(s8) || {}).ok === true, JSON.stringify(verdict(s8)));
  const s9 = bucket();
  await semerReference(s9, 'txt1', TEXTE_REF);
  await appel(s9, { ai: iaFactice({ reponse: { autre: 1 } }) });
  verifie('réponse sans texte → ok:false ai_response_format',
    (verdict(s9) || {}).reason === 'ai_response_format', JSON.stringify(verdict(s9)));

  // ─── Résumé : pas de référence, seuil de mots distincts ────────────────────
  const RESUME_20 = 'Cette histoire raconte comment plusieurs personnages traversent une longue période '
    + 'vraiment difficile avant de retrouver ensemble leur maison familiale près des collines ensoleillées.';
  const RESUME_5 = 'Alors voilà, histoire, maison, chose.';
  verifie('résumés du scénario : 20 et 5 mots distincts',
    motsDistincts(RESUME_20).length === 20 && motsDistincts(RESUME_5).length === 5,
    `${motsDistincts(RESUME_20).length} / ${motsDistincts(RESUME_5).length}`);
  const s10 = bucket();
  const r10 = await appel(s10, { ai: iaFactice({ texte: RESUME_20 }), entetes: { 'X-Record-Type': 'summary' } });
  const v10 = verdict(s10) || {};
  verifie('résumé 20 mots → ok:true, sans référence',
    r10.statut === 200 && v10.ok === true && v10.words_transcribed === 20 && v10.words_ref === 0 && v10.overlap === null,
    JSON.stringify(v10));
  verifie('résumé : verdict sous summary-<textId>.json',
    cleVerdict(s10) === `verified/${ACCOUNT}/${SESSION}/summary-txt1.json`, cleVerdict(s10));
  const s11 = bucket();
  await appel(s11, { ai: iaFactice({ texte: RESUME_5 }), entetes: { 'X-Record-Type': 'summary' } });
  const v11 = verdict(s11) || {};
  verifie('résumé 5 mots → ok:false too_few_words',
    v11.ok === false && v11.reason === 'too_few_words' && v11.words_transcribed === 5, JSON.stringify(v11));
  const s12 = bucket();
  await appel(s12, {
    entetes: { 'X-Record-Type': 'summary' },
    env: { AUDIO_BUCKET: s12, LEGAL_VERSIONS: CV, AI: iaFactice({ texte: RESUME_5 }), VERIFY_MIN_SUMMARY_WORDS: '3' },
  });
  verifie('VERIFY_MIN_SUMMARY_WORDS="3" : 5 mots suffisent', (verdict(s12) || {}).ok === true, JSON.stringify(verdict(s12)));

  // ─── Type inconnu : stocké, mais aucun verdict ─────────────────────────────
  const s13 = bucket();
  const r13 = await appel(s13, { ai: iaFactice({ texte: RESUME_20 }), entetes: { 'X-Record-Type': null } });
  verifie('type par défaut « audio » → stocké, aucun verdict, IA non appelée',
    r13.statut === 200 && clesAudio(s13).length === 1 && cleVerdict(s13) === '', `${r13.statut} ${[...s13._m.keys()]}`);

  // ─── Refus → pas de vérification lancée ────────────────────────────────────
  const s14 = bucket();
  const r14 = await appel(s14, { token: TOKEN_PAID, ai: iaFactice({ texte: TRANSCRIPTION_50 }) });
  verifie('upload refusé (403) → ctx.waitUntil jamais appelé, aucun verdict',
    r14.statut === 403 && r14.ctx._promesses.length === 0 && s14._m.size === 0, `${r14.statut} ${r14.ctx._promesses.length}`);

  // ─── La réponse n'attend PAS la transcription ──────────────────────────────
  const s15 = bucket();
  await semerReference(s15, 'txt1', TEXTE_REF);
  const ia15 = iaFactice({ texte: TRANSCRIPTION_50, differee: true });
  const ctx15 = contexte();
  const resp15 = await worker.fetch(new Request('https://selftest/', {
    method: 'POST',
    headers: {
      'Content-Type': 'audio/webm', 'X-Mentality-Token': TOKEN_FREE_CC, 'X-Session-Id': SESSION,
      'X-Text-Id': 'txt1', 'X-Layer': 'C', 'X-Record-Type': 'reading', 'X-Language': 'fr',
    },
    body: new Uint8Array(1024),
  }), { AUDIO_BUCKET: s15, LEGAL_VERSIONS: CV, AI: ia15 }, ctx15);
  verifie('réponse 200 rendue AVANT tout verdict (la transcription n\'a pas encore commencé)',
    resp15.status === 200 && cleVerdict(s15) === '', `${resp15.status} ${cleVerdict(s15)}`);
  // On laisse la tâche de fond avancer jusqu'au modèle : il est appelé et
  // bloque (barrière), la réponse HTTP est pourtant déjà rendue.
  await new Promise((resolve) => setTimeout(resolve, 0));
  verifie('… le modèle est appelé en tâche de fond et bloque, sans verdict ni attente côté HTTP',
    ia15._appels.length === 1 && cleVerdict(s15) === '', `${ia15._appels.length} appel(s) ${cleVerdict(s15)}`);
  ia15.liberer();
  await ctx15.attendre();
  verifie('… puis le verdict tombe une fois la transcription rendue',
    (verdict(s15) || {}).ok === true, JSON.stringify(verdict(s15)));

  // ─── Fichier trop gros pour la transcription → verdict, upload intact ──────
  const s16 = bucket();
  await semerReference(s16, 'txt1', TEXTE_REF);
  const ia16 = iaFactice({ texte: TRANSCRIPTION_50 });
  const r16 = await appel(s16, { ai: ia16, corps: new Uint8Array(8 * 1024 * 1024 + 1) });
  verifie('> 8 Mo → upload 200, verdict audio_too_large, IA non appelée',
    r16.statut === 200 && (verdict(s16) || {}).reason === 'audio_too_large' && ia16._appels.length === 0,
    `${r16.statut} ${JSON.stringify(verdict(s16))}`);
}

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) {
  console.error('Échecs : ' + echecs.join(' | '));
  process.exit(1);
}
