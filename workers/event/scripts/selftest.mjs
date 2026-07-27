#!/usr/bin/env node
/**
 * Auto-test du worker event (réponses de l'événement des 8 jours).
 *
 *   node workers/event/scripts/selftest.mjs
 *
 * Aucune dépendance, aucun réseau, aucun compte Cloudflare : le worker est
 * importé tel quel et branché sur un bucket R2 en mémoire.
 *
 * POURQUOI CE FICHIER. Comme pour `workers/referral/scripts/selftest.mjs` : les
 * tests Dart disent ce que la règle DOIT être, celui-ci vérifie ce qu'elle EST,
 * en exécutant le JS de production avec son vrai module de vérification de
 * token.
 *
 * DIFFÉRENCE ESSENTIELLE AVEC LE SELFTEST REFERRAL. Celui-ci ne peut PAS se
 * contenter d'un token DEV « M2.<claims> » : le worker event exige une vraie
 * signature Ed25519 (données de santé). On forge donc ici un vrai couple de
 * clés, on signe un vrai token, et on enregistre la clé publique de test dans
 * la map partagée `TOKEN_SIGNING_PUBLIC_KEYS` — dont les propriétés sont
 * mutables, ce qui évite d'ouvrir une couture d'injection dans le code de
 * production. La vérification exercée est donc la VRAIE, et le refus du token
 * non signé est lui-même une vérification (« garde de signature » ci-dessous).
 *
 * À lancer avant chaque `wrangler deploy`.
 */

import worker from '../index.js';
import { TOKEN_SIGNING_PUBLIC_KEYS, sha256hex } from '../../_shared/token_verify.js';

const b64u = (bytes) => Buffer.from(bytes).toString('base64url');
const segment = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');

/** Forge un couple de clés Ed25519 et enregistre la publique sous [kid]. */
async function keypair(kid) {
  const kp = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
  const raw = new Uint8Array(await crypto.subtle.exportKey('raw', kp.publicKey));
  TOKEN_SIGNING_PUBLIC_KEYS[kid] = b64u(raw);
  return { kid, privee: kp.privateKey };
}

/** Token signé (JWS compact EdDSA) portant [nonce] — la forme de production. */
async function signe({ kid, privee }, nonce) {
  const input = `${segment({ alg: 'EdDSA', kid })}.${segment({ n: nonce, sv: 2 })}`;
  const sig = await crypto.subtle.sign(
    { name: 'Ed25519' },
    privee,
    new TextEncoder().encode(input),
  );
  return `${input}.${b64u(new Uint8Array(sig))}`;
}

const cleValide = await keypair('ktest');
// Clé d'un AUTRE émetteur. Elle est enregistrée sous son propre kid
// (`ktest_intrus`), qu'aucun token n'utilise ; le token forgé ci-dessous
// annonce au contraire `kid: 'ktest'`. La vérification charge donc la clé
// publique VALIDE et l'échec vient de la SIGNATURE, pas d'un kid inconnu.
const cleIntruse = await keypair('ktest_intrus');
const TOKEN_INTRUS = await signe({ ...cleIntruse, kid: 'ktest' }, 'nonce-a');

const NONCE = 'nonce-a';
const TOKEN = await signe(cleValide, NONCE);
const TOKEN_AUTRUI = await signe(cleValide, 'nonce-b');
// Token DEV non signé, celui qu'accepte le worker referral. Doit être REFUSÉ ici.
const TOKEN_DEV = 'M2.' + segment({ n: NONCE, sv: 2 });

const account = (await sha256hex(NONCE)).slice(0, 32);
const accountAutrui = (await sha256hex('nonce-b')).slice(0, 32);

const PURPOSE = 'event-health-research';
const VERSION = '2026-07-27.v2';

/** Charge utile nominale — 3 réponses d'un module annoncé. */
const charge = (extra = {}) => ({
  schema: 1,
  moduleId: 'j1_personality',
  day: 1,
  kind: 'announced',
  partial: false,
  locale: 'fr',
  answers: { ipip1: 3, ipip2: 1, ipip3: 5 },
  ...extra,
});

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
  };
}

/**
 * Un appel au worker. [entetes] écrase les en-têtes par défaut ; une valeur
 * `null` supprime l'en-tête (pour tester son absence).
 */
async function appel(store, {
  path = '/responses',
  method = 'POST',
  body = charge(),
  sansCorps = false,
  entetes = {},
  env = {},
  brut,
} = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'X-Mentality-Token': TOKEN,
    'X-Consent-Version': VERSION,
    'X-Consent-Purpose': PURPOSE,
    ...entetes,
  };
  for (const [k, v] of Object.entries(headers)) if (v === null) delete headers[k];

  // `sansCorps` plutôt que `body: undefined` : passer `undefined` à un
  // paramètre destructuré RÉACTIVE sa valeur par défaut, et undici refuse un
  // GET porteur d'un corps.
  const corpsEnvoye = sansCorps ? undefined : (brut !== undefined ? brut : JSON.stringify(body));

  const resp = await worker.fetch(
    new Request('https://selftest' + path, { method, headers, body: corpsEnvoye }),
    { EVENT_BUCKET: store, ...env },
  );
  const texte = await resp.text();
  let corps = null;
  try { corps = JSON.parse(texte); } catch { /* réponse sans corps (204) */ }
  return { statut: resp.status, corps, entetes: resp.headers };
}

let ok = 0;
const echecs = [];
function verifie(nom, condition, detail = '') {
  if (condition) { ok++; console.log(`  ✓ ${nom}`); }
  else { echecs.push(nom); console.log(`  ✗ ${nom}  ${detail}`); }
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nRoutage et CORS');
{
  const s = bucket();
  const inconnue = await appel(s, { path: '/autre' });
  verifie('route inconnue → 404', inconnue.statut === 404, `= ${inconnue.statut}`);

  const lecture = await appel(s, { method: 'GET', sansCorps: true });
  verifie('GET /responses → 405 (aucune lecture cliente)',
    lecture.statut === 405, `= ${lecture.statut}`);

  const options = await appel(s, { method: 'OPTIONS', sansCorps: true });
  verifie('OPTIONS → 204 préflight', options.statut === 204, `= ${options.statut}`);
  verifie('préflight annonce les en-têtes de consentement',
    (options.entetes.get('Access-Control-Allow-Headers') || '').includes('X-Consent-Purpose'),
    options.entetes.get('Access-Control-Allow-Headers') || '');

  const etranger = await appel(s, { entetes: { Origin: 'https://pirate.example' } });
  verifie('Origin non autorisée → 403', etranger.statut === 403, `= ${etranger.statut}`);
  verifie('rien écrit après un refus d\'origine', s._m.size === 0, `${s._m.size} objets`);

  const autorisee = await appel(s, {
    entetes: { Origin: 'https://mentality-flutter-web.pages.dev' },
  });
  verifie('Origin autorisée → 200', autorisee.statut === 200, `= ${autorisee.statut}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nGarde de signature (le point qui distingue ce worker du referral)');
{
  const s = bucket();
  const sans = await appel(s, { entetes: { 'X-Mentality-Token': null } });
  verifie('sans passe → 401', sans.statut === 401, `= ${sans.statut}`);

  const dev = await appel(s, { entetes: { 'X-Mentality-Token': TOKEN_DEV } });
  verifie('passe DEV non signé « M2. » → 401 (le fallback referral n\'a PAS été recopié)',
    dev.statut === 401, `= ${dev.statut} ${JSON.stringify(dev.corps)}`);

  const intrus = await appel(s, { entetes: { 'X-Mentality-Token': TOKEN_INTRUS } });
  verifie('signature d\'un autre émetteur → 401',
    intrus.statut === 401, `= ${intrus.statut}`);

  const abime = await appel(s, { entetes: { 'X-Mentality-Token': TOKEN.slice(0, -4) + 'AAAA' } });
  verifie('signature altérée → 401', abime.statut === 401, `= ${abime.statut}`);

  verifie('aucun objet écrit par un passe refusé', s._m.size === 0, `${s._m.size} objets`);

  const signe200 = await appel(s);
  verifie('passe signé → 200', signe200.statut === 200, `= ${signe200.statut}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nConsentement art. 9 : preuve ET finalité');
{
  const s = bucket();
  const sansVersion = await appel(s, { entetes: { 'X-Consent-Version': null } });
  verifie('sans version de consentement → 403',
    sansVersion.statut === 403, `= ${sansVersion.statut}`);

  const versionVide = await appel(s, { entetes: { 'X-Consent-Version': '   ' } });
  verifie('version blanche → 403', versionVide.statut === 403, `= ${versionVide.statut}`);

  const sansFinalite = await appel(s, { entetes: { 'X-Consent-Purpose': null } });
  verifie('sans finalité → 403', sansFinalite.statut === 403, `= ${sansFinalite.statut}`);

  const finaliteAudio = await appel(s, {
    entetes: { 'X-Consent-Purpose': 'recording-and-analysis' },
  });
  verifie('un consentement AUDIO n\'autorise pas un envoi de santé → 403',
    finaliteAudio.statut === 403, `= ${finaliteAudio.statut}`);

  verifie('aucun objet écrit sans consentement adéquat', s._m.size === 0, `${s._m.size} objets`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nÉcriture nominale : clé, partition, metadata');
{
  const s = bucket();
  const r = await appel(s);
  verifie('envoi nominal → 200', r.statut === 200, `= ${r.statut} ${JSON.stringify(r.corps)}`);
  verifie('réponse : stored + itemCount',
    r.corps.stored === true && r.corps.itemCount === 3, JSON.stringify(r.corps));

  const cle = [...s._m.keys()][0];
  verifie('un seul objet écrit', s._m.size === 1, `${s._m.size} objets`);
  verifie('clé partitionnée par account dérivé du passe',
    cle.startsWith(`responses/${account}/j1_personality/`), cle);
  verifie('clé terminée par un uuid .json',
    /\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.json$/.test(cle), cle);
  verifie('aucun horodatage dans la clé', !/\d{4}-\d{2}-\d{2}T|\d{13}/.test(cle), cle);

  const { options, value } = s._m.get(cle);
  const meta = options.customMetadata;
  verifie('metadata received_day : DATE seule, jamais l\'heure',
    /^\d{4}-\d{2}-\d{2}$/.test(meta.received_day), meta.received_day);
  verifie('metadata décrit le module sans le rouvrir',
    meta.module_id === 'j1_personality' && meta.day === '1' &&
    meta.kind === 'announced' && meta.partial === 'false' && meta.item_count === '3',
    JSON.stringify(meta));
  verifie('metadata porte la preuve de consentement (version + finalité)',
    meta.consent_version === VERSION && meta.consent_purpose === PURPOSE,
    JSON.stringify(meta));
  verifie('metadata account = celui du passe', meta.account === account, meta.account);
  verifie('contentType application/json',
    options.httpMetadata.contentType === 'application/json',
    JSON.stringify(options.httpMetadata));

  const ecrit = JSON.parse(value);
  verifie('corps stocké : réponses intactes',
    JSON.stringify(ecrit.answers) === JSON.stringify({ ipip1: 3, ipip2: 1, ipip3: 5 }),
    JSON.stringify(ecrit.answers));
  verifie('corps stocké : aucun horodatage',
    !JSON.stringify(ecrit).match(/\d{4}-\d{2}-\d{2}T\d{2}/), JSON.stringify(ecrit));
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nCloisonnement : le client ne choisit jamais sa partition');
{
  const s = bucket();
  // Le corps prétend appartenir à quelqu'un d'autre ; le worker doit l'ignorer.
  await appel(s, { body: charge({ account: accountAutrui, moduleId: 'j1_personality' }) });
  const cle = [...s._m.keys()][0];
  verifie('un account envoyé dans le corps est ignoré',
    cle.startsWith(`responses/${account}/`), cle);
  verifie('l\'account stocké reste celui du passe',
    JSON.parse(s._m.get(cle).value).account === account,
    JSON.parse(s._m.get(cle).value).account);

  await appel(s, { entetes: { 'X-Mentality-Token': TOKEN_AUTRUI } });
  const prefixes = new Set([...s._m.keys()].map((k) => k.split('/')[1]));
  verifie('deux passes → deux partitions distinctes',
    prefixes.size === 2 && prefixes.has(account) && prefixes.has(accountAutrui),
    [...prefixes].join(' '));
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nDonnées partielles et envois répétés');
{
  const s = bucket();
  await appel(s, { body: charge({ partial: true, answers: { ipip1: 3 } }) });
  const cleP = [...s._m.keys()][0];
  verifie('un abandon part marqué partiel',
    s._m.get(cleP).options.customMetadata.partial === 'true',
    s._m.get(cleP).options.customMetadata.partial);

  await appel(s, { body: charge() }); // le même module, terminé cette fois
  verifie('le partiel n\'est pas écrasé par le complet (2 objets)',
    s._m.size === 2, `${s._m.size} objets`);
  const finaux = [...s._m.values()]
    .filter((o) => o.options.customMetadata.partial === 'false');
  verifie('le jeu final se reconnaît à partial=false',
    finaux.length === 1 && finaux[0].options.customMetadata.item_count === '3',
    JSON.stringify(finaux.map((o) => o.options.customMetadata)));

  await appel(s, { body: charge() }); // rejeu d'une confirmation perdue
  verifie('un rejeu produit une clé neuve, sans rien écraser',
    s._m.size === 3, `${s._m.size} objets`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nValidation de la charge utile');
{
  const s = bucket();
  const cas = [
    ['corps vide → 400', { sansCorps: true }, 400],
    ['JSON illisible → 400', { brut: '{pas du json' }, 400],
    ['tableau au lieu d\'objet → 400', { body: [1, 2] }, 400],
    ['schéma inconnu → 400', { body: charge({ schema: 2 }) }, 400],
    ['schéma absent → 400', { body: charge({ schema: undefined }) }, 400],
    ['moduleId absent → 400', { body: charge({ moduleId: '' }) }, 400],
    ['moduleId en traversée de chemin → 400', { body: charge({ moduleId: '../../etc' }) }, 400],
    ['day = 0 → 400', { body: charge({ day: 0 }) }, 400],
    ['day = 9 → 400', { body: charge({ day: 9 }) }, 400],
    ['day non entier → 400', { body: charge({ day: 1.5 }) }, 400],
    ['kind inconnu → 400', { body: charge({ kind: 'share' }) }, 400],
    ['partial non booléen → 400', { body: charge({ partial: 'oui' }) }, 400],
    ['answers absent → 400', { body: charge({ answers: undefined }) }, 400],
    ['answers vide → 400', { body: charge({ answers: {} }) }, 400],
    ['answers en tableau → 400', { body: charge({ answers: [1, 2] }) }, 400],
    ['réponse non entière → 400', { body: charge({ answers: { a: 'trois' } }) }, 400],
    ['réponse décimale → 400', { body: charge({ answers: { a: 2.5 } }) }, 400],
    ['identifiant d\'item démesuré → 400', { body: charge({ answers: { ['x'.repeat(65)]: 1 } }) }, 400],
    ['locale mal formée → 400', { body: charge({ locale: 'fr/../x' }) }, 400],
    ['valeur démesurée (1e308 est un « entier » en JS) → 400',
      { body: charge({ answers: { a: 1e308 } }) }, 400],
    ['valeur hors bornes basse → 400', { body: charge({ answers: { a: -100000 } }) }, 400],
  ];
  for (const [nom, options, attendu] of cas) {
    const r = await appel(s, options);
    verifie(nom, r.statut === attendu, `= ${r.statut} ${JSON.stringify(r.corps)}`);
  }
  verifie('aucune charge utile invalide n\'a été écrite', s._m.size === 0, `${s._m.size} objets`);

  const enorme = { ...charge(), answers: {} };
  for (let i = 0; i < 20000; i++) enorme.answers[`item${i}`] = 1;
  const trop = await appel(s, { body: enorme });
  verifie('charge utile > 256 Ko → 413', trop.statut === 413, `= ${trop.statut}`);

  const tropDItems = { ...charge(), answers: {} };
  for (let i = 0; i < 501; i++) tropDItems.answers[`i${i}`] = 1;
  const items = await appel(s, { body: tropDItems });
  verifie('plus de 500 réponses → 400', items.statut === 400, `= ${items.statut}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nPannes serveur : distinguables d\'un refus');
{
  const casse = bucket({ echoue: true });
  const r = await appel(casse);
  verifie('échec d\'écriture R2 → 502 (le client rejouera)',
    r.statut === 502, `= ${r.statut}`);

  const sansBinding = await worker.fetch(
    new Request('https://selftest/responses', {
      method: 'POST',
      headers: {
        'X-Mentality-Token': TOKEN,
        'X-Consent-Version': VERSION,
        'X-Consent-Purpose': PURPOSE,
      },
      body: JSON.stringify(charge()),
    }),
    {},
  );
  verifie('bucket non lié → 500', sansBinding.status === 500, `= ${sansBinding.status}`);
}

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) {
  console.error('Échecs : ' + echecs.join(' | '));
  process.exit(1);
}
