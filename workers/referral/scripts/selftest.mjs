#!/usr/bin/env node
/**
 * Auto-test du worker referral : machine à états des paliers, et depuis le
 * LOT 0 anti-faux-test : plausibilité de /complete à chaque appel, cohérence
 * temporelle, crédit-jonction (maybeCredit), gate propriétaire (faille 11),
 * politique d'Origin.
 *
 *   node workers/referral/scripts/selftest.mjs
 *
 * Aucune dépendance, aucun réseau, aucun compte Cloudflare : le worker est
 * importé tel quel et branché sur un KV en mémoire.
 *
 * POURQUOI CE FICHIER. Les tests Dart (test/features/unlock_stage_machine_test.dart)
 * répliquent la règle en Dart — utile pour la documenter, mais une réplique peut
 * diverger du code qu'elle décrit sans que rien ne le signale. Ici c'est le JS
 * de production qui s'exécute, avec son vrai module de vérification de token.
 * Les deux se complètent : le Dart dit ce que la règle DOIT être, ce fichier
 * vérifie ce qu'elle EST.
 *
 * À lancer avant chaque `wrangler deploy`.
 */

import worker from '../index.js';
import { sha256hex, TOKEN_SIGNING_PUBLIC_KEYS } from '../../_shared/token_verify.js';

const TOKEN = 'M2.' + Buffer.from(JSON.stringify({ n: 'selftest', sv: 2 }))
  .toString('base64url');

// ─── Token SIGNÉ Ed25519 — le chemin NOMINAL de production (tokens émis par
//     le tokeniser). Sans lui, seul le repli `M2.` serait exercé : une casse
//     de la branche signée de resolveNonce (→ 401 = 4xx définitif côté client
//     déployé) laisserait tout ce fichier vert. Kid dédié pour ne pas toucher
//     aux clés réelles (propriétés mutables, même procédé que le selftest du
//     tokeniser). ──────────────────────────────────────────────────────────
const kpSelftest = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
TOKEN_SIGNING_PUBLIC_KEYS.selftest = Buffer
  .from(new Uint8Array(await crypto.subtle.exportKey('raw', kpSelftest.publicKey)))
  .toString('base64url');
const segment = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const signingInput =
  `${segment({ alg: 'EdDSA', kid: 'selftest' })}.${segment({ n: 'selftest-signe', sv: 2 })}`;
const TOKEN_SIGNE = `${signingInput}.` + Buffer
  .from(new Uint8Array(await crypto.subtle.sign(
    { name: 'Ed25519' }, kpSelftest.privateKey, new TextEncoder().encode(signingInput))))
  .toString('base64url');
const accountSigne = (await sha256hex('selftest-signe')).slice(0, 32);

const HUIT_JOURS_MIN = 11520;
const PROD = { UNLOCK_DELAY_MINUTES: String(HUIT_JOURS_MIN) };

const account = (await sha256hex('selftest')).slice(0, 32);
const iso = (ms) => new Date(ms).toISOString();
const maintenant = Date.now();

/** Store KV en mémoire, même contrat que le binding Cloudflare. */
function storeDepuis(m) {
  return {
    _m: m,
    get: async (k) => (m.has(k) ? m.get(k) : null),
    put: async (k, v) => void m.set(k, v),
    list: async ({ prefix }) => ({
      keys: [...m.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name })),
    }),
  };
}

/**
 * Store de la machine à états : une ligne de suivi + N filleuls crédités,
 * ET une preuve de complétion PLAUSIBLE du propriétaire. Les lignes de kv()
 * sont LEGACY (sans firstSeenVia) donc exemptées du gate propriétaire ; les
 * scénarios du gate passent explicitement `firstSeenVia` pour être gatés, et
 * la preuve seedée garde les scénarios historiques sur le chemin nominal.
 */
function kv(rowFields, filleuls = 3) {
  const m = new Map();
  m.set(`progress:${account}`, JSON.stringify({
    account, referralCode: 'testcode', ...rowFields,
  }));
  m.set(`completed:${account}`, JSON.stringify({
    at: iso(maintenant - 86400000), subtests: 12, durationS: 4500,
  }));
  for (let i = 0; i < filleuls; i++) m.set(`ref:testcode:filleul${i}`, iso(maintenant));
  return storeDepuis(m);
}

/** Store VIERGE (compte jamais vu du serveur), seedable clé par clé. */
function kvNu(seed = {}) {
  return storeDepuis(new Map(Object.entries(seed)));
}

const requete = (path, method, body, opts = {}) => {
  const headers = { 'Content-Type': 'application/json' };
  const token = 'token' in opts ? opts.token : TOKEN;
  if (token) headers['X-Mentality-Token'] = token;
  if (opts.origin) headers['Origin'] = opts.origin;
  return new Request(`https://selftest${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
};

async function appel(store, env, path = '/progress', method = 'GET', body, opts) {
  const resp = await worker.fetch(requete(path, method, body, opts),
    { REFERRAL_KV: store, ...env });
  return { statut: resp.status, corps: await resp.json() };
}
const ligne = (store) => JSON.parse(store._m.get(`progress:${account}`));

let ok = 0;
const echecs = [];
function verifie(nom, condition, detail = '') {
  if (condition) { ok++; console.log(`  ✓ ${nom}`); }
  else { echecs.push(nom); console.log(`  ✗ ${nom}  ${detail}`); }
}

console.log('\n─── Machine à états — workers/referral/index.js ───\n');

console.log('Autorité serveur');
{
  const s = kv({ stage: 1 });
  const { corps } = await appel(s, PROD);
  verifie("3 filleuls → stage 3, jamais 4 d'emblée", corps.stage === 3, JSON.stringify(corps));
  verifie('unlockAt renseigné au stage 3', typeof corps.unlockAt === 'string');
}
{
  const s = kv({ stage: 1 }, 2);
  const { corps } = await appel(s, PROD);
  verifie('2 filleuls → reste stage 1, unlockAt null',
    corps.stage === 1 && corps.unlockAt === null, JSON.stringify(corps));
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - HUIT_JOURS_MIN * 60000 + 5000) });
  const { corps } = await appel(s, PROD);
  verifie('5 s avant le terme → toujours verrouillé', corps.stage === 3, JSON.stringify(corps));
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - HUIT_JOURS_MIN * 60000) });
  const { corps } = await appel(s, PROD);
  verifie('terme atteint → stage 4', corps.stage === 4, JSON.stringify(corps));
}

console.log('\nMigration des lignes déjà en production');
{
  // (a) un déblocage acquis ne se recalcule jamais, même sans filleuls.
  const s = kv({ stage: 4, unlockedAt: iso(maintenant - 1000),
    instagramSubmittedAt: iso(maintenant - 99 * 86400000) }, 0);
  const { corps } = await appel(s, PROD);
  verifie('(a) stage 4 reste 4 sans aucun filleul', corps.stage === 4, JSON.stringify(corps));
  verifie('(a) aucune ancre posée sur une ligne débloquée', !ligne(s).stage3StartedAt);
}
{
  // (b) l'attente déjà écoulée n'est pas perdue.
  const il7Jours = iso(maintenant - 7 * 86400000);
  const s = kv({ stage: 3, instagramSubmittedAt: il7Jours, instagramHandle: 'quelquun' });
  const { corps } = await appel(s, PROD);
  verifie("(b) ancre héritée de l'ancien horodatage",
    ligne(s).stage3StartedAt === il7Jours, String(ligne(s).stage3StartedAt));
  verifie('(b) ~1 jour restant, pas 8',
    Math.abs(corps.secondsRemaining - 86400) <= 2, `= ${corps.secondsRemaining}`);
}
{
  const s = kv({ stage: 3, instagramSubmittedAt: iso(maintenant - 9 * 86400000) });
  const { corps } = await appel(s, PROD);
  verifie('(b bis) attente héritée dépassée → débloqué', corps.stage === 4, JSON.stringify(corps));
}
{
  // (c) rien à hériter : le compteur démarre à la première lecture.
  const s = kv({ stage: 3 });
  const { corps } = await appel(s, PROD);
  verifie('(c) ancre posée maintenant', !!ligne(s).stage3StartedAt);
  verifie('(c) délai complet, non tronqué',
    corps.secondsRemaining === HUIT_JOURS_MIN * 60, `= ${corps.secondsRemaining}`);
}
{
  const s = kv({ stage: 3 });
  await appel(s, PROD);
  const ancre = ligne(s).stage3StartedAt;
  await appel(s, PROD);
  verifie("l'ancre n'est posée qu'une fois", ligne(s).stage3StartedAt === ancre);
}

console.log('\nPurge RGPD');
{
  const s = kv({ stage: 3, instagramHandle: 'quelquun',
    instagramSubmittedAt: iso(maintenant - 86400000), instagramVerified: false });
  await appel(s, PROD);
  const row = ligne(s);
  verifie("les 3 champs Instagram disparaissent à l'écriture",
    !('instagramHandle' in row) && !('instagramSubmittedAt' in row) &&
    !('instagramVerified' in row), Object.keys(row).join(','));
  verifie('la ligne SURVIT (code de parrainage préservé)',
    row.referralCode === 'testcode');
}

console.log('\nDélai annoncé');
{
  const s = kv({ stage: 3 });
  const { corps } = await appel(s, PROD);
  verifie('8 jours dérivés du délai réel', corps.displayDelayDays === 8, `= ${corps.displayDelayDays}`);
  verifie("pas d'override en configuration de prod", corps.debugDelayOverride === false);
}
{
  const s = kv({ stage: 3 });
  const { corps } = await appel(s, { UNLOCK_DELAY_MINUTES: '11521' });
  verifie('arrondi AU SUPÉRIEUR : 11521 min → 9 jours',
    corps.displayDelayDays === 9, `= ${corps.displayDelayDays}`);
}
{
  const s = kv({ stage: 3 });
  const { corps } = await appel(s,
    { UNLOCK_DELAY_MINUTES: '1', DEBUG_DISPLAY_DELAY_DAYS: '8' });
  verifie('recette : annonce 8 jours', corps.displayDelayDays === 8);
  verifie('recette : délai réel exposé (bannière)', corps.delayMinutes === 1);
  verifie('recette : debugDelayOverride VRAI', corps.debugDelayOverride === true,
    "sans ce drapeau un délai de test passerait en prod inaperçu");
  verifie('recette : 60 s restantes', corps.secondsRemaining === 60, `= ${corps.secondsRemaining}`);
}

// Jour courant de l'événement des 8 jours. Le serveur en est la SEULE
// autorité : le client ne le dérive jamais de son horloge.
//
// Les ancres sont posées à au moins une heure d'une frontière de jour —
// l'horloge réelle tourne pendant le run, et un test qui se joue à la
// milliseconde près deviendrait intermittent.
console.log('\nJour courant (dayIndex)');
{
  const s = kv({ stage: 1 }, 2);
  const { corps } = await appel(s, PROD);
  verifie("attente pas commencée → null, et le champ est bien émis",
    corps.dayIndex === null && 'dayIndex' in corps, `= ${JSON.stringify(corps.dayIndex)}`);
}
{
  const s = kv({ stage: 1 }, 3);
  const { corps } = await appel(s, PROD);
  verifie('promotion fraîche au palier 3 → jour 1',
    corps.stage === 3 && corps.dayIndex === 1, `stage ${corps.stage}, jour ${corps.dayIndex}`);
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - 25 * 3600000) });
  const { corps } = await appel(s, PROD);
  verifie('h+25 h → jour 2', corps.dayIndex === 2, `= ${corps.dayIndex}`);
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - 167 * 3600000) });
  const { corps } = await appel(s, PROD);
  verifie('h+167 h → jour 7', corps.dayIndex === 7, `= ${corps.dayIndex}`);
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - 191 * 3600000) });
  const { corps } = await appel(s, PROD);
  verifie('veille du terme → jour 8, et JAMAIS 9 tant que l\'attente court',
    corps.stage === 3 && corps.dayIndex === 8, `stage ${corps.stage}, jour ${corps.dayIndex}`);
}
{
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - HUIT_JOURS_MIN * 60000) });
  const { corps } = await appel(s, PROD);
  verifie('terme atteint → stage 4 et jour 9',
    corps.stage === 4 && corps.dayIndex === 9, `stage ${corps.stage}, jour ${corps.dayIndex}`);
}
{
  // Ligne héritée débloquée AVANT l'existence de l'ancre : Date.parse(null)
  // vaudrait NaN, sérialisé silencieusement en null par JSON.stringify.
  const s = kv({ stage: 4, unlockedAt: iso(maintenant - 1000) }, 0);
  const { corps } = await appel(s, PROD);
  verifie('ligne héritée en stage 4 sans ancre → jour 9, jamais NaN',
    corps.dayIndex === 9, `= ${JSON.stringify(corps.dayIndex)}`);
}
{
  // Dérive d'horloge entre instances : l'ancre peut être légèrement future.
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant + 3600000) });
  const { corps } = await appel(s, PROD);
  verifie('ancre dans le futur → clampé au jour 1, jamais 0 ni négatif',
    corps.dayIndex === 1, `= ${corps.dayIndex}`);
}
{
  // Deux lectures de suite sur la MÊME ancre : le jour ne dépend que d'elle.
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - 73 * 3600000) });
  const premier = (await appel(s, PROD)).corps.dayIndex;
  const second = (await appel(s, PROD)).corps.dayIndex;
  verifie('jour stable d\'une lecture à l\'autre (dérivé de l\'ancre seule)',
    premier === 4 && second === 4, `${premier} puis ${second}`);
}
{
  // Un « jour » vaut 1/8 du délai réel : en recette le compteur reste
  // traversable au lieu de rester figé au jour 1 pendant tout le test.
  const s = kv({ stage: 3, stage3StartedAt: iso(maintenant - 31000) });
  const { corps } = await appel(s, { UNLOCK_DELAY_MINUTES: '1' });
  verifie('recette (délai 1 min) : 31 s écoulées → jour 5',
    corps.dayIndex === 5, `= ${corps.dayIndex}`);
}

console.log('\nPierre tombale POST /instagram');
{
  const s = kv({ stage: 3 });
  const { statut, corps } = await appel(s, PROD, '/instagram', 'POST',
    { handle: '!!!pseudo invalide!!!' });
  verifie('répond 200 (les vieilles builds ne sont pas murées)', statut === 200,
    `HTTP ${statut}`);
  verifie("le pseudo n'est PAS stocké", !('instagramHandle' in ligne(s)));
  verifie('compat instagramSubmitted vrai au stage 3', corps.instagramSubmitted === true);
}

// ═══ LOT 0 anti-faux-test ════════════════════════════════════════════════════

console.log('\n/complete — plausibilité et écritures (première déclaration)');
{
  const s = kvNu();
  const { statut, corps } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  const row = ligne(s);
  const preuve = JSON.parse(s._m.get(`completed:${account}`) ?? 'null');
  verifie('déclaration plausible → 200, preuve stockée', statut === 200 &&
    preuve && preuve.subtests === 12 && preuve.durationS === 4500, `HTTP ${statut}`);
  verifie("ligne créée à la volée, marquée firstSeenVia 'complete'",
    row && row.firstSeenVia === 'complete', JSON.stringify(row));
  verifie("le code d'invitation existe (clé code:)", [...s._m.keys()].some((k) => k.startsWith('code:')));
  const champs = ['stage', 'referralCode', 'completedReferrals', 'requiredReferrals',
    'unlockAt', 'secondsRemaining', 'dayIndex', 'displayDelayDays', 'delayMinutes',
    'debugDelayOverride', 'instagramSubmitted'];
  verifie('les 11 champs du contrat client sont tous émis',
    champs.every((c) => c in corps), champs.filter((c) => !(c in corps)).join(','));
  // Présence ≠ contrat : l'app déployée LIT ces valeurs. `referralCode: null`
  // ou `requiredReferrals: "3"` passeraient un simple `in`.
  verifie('… et VALEURS conformes à ce que le client lit (pas seulement présents)',
    corps.stage === 1 && /^[a-z0-9]{8}$/.test(corps.referralCode) &&
    corps.completedReferrals === 0 && corps.requiredReferrals === 3 &&
    corps.unlockAt === null && corps.secondsRemaining === 0 &&
    corps.dayIndex === null && corps.displayDelayDays === 8 &&
    corps.delayMinutes === HUIT_JOURS_MIN && corps.debugDelayOverride === false &&
    corps.instagramSubmitted === false,
    JSON.stringify(corps));
}
{
  // Frontière EXACTE des planchers : un off-by-one (`>=` → `>`) enverrait un
  // 400 DÉFINITIF à une déclaration légitime pile au seuil.
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 10, durationSeconds: 300 });
  verifie('frontière exacte 10 sous-tests / 300 s → 200 (plancher inclusif)',
    statut === 200, `HTTP ${statut}`);
}

console.log('\nToken SIGNÉ Ed25519 — chemin nominal de production');
{
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 }, { token: TOKEN_SIGNE });
  const rowSigne = JSON.parse(s._m.get(`progress:${accountSigne}`) ?? 'null');
  verifie('token signé accepté : 200, ligne sous le compte dérivé du nonce SIGNÉ',
    statut === 200 && rowSigne !== null && rowSigne.firstSeenVia === 'complete',
    `HTTP ${statut}`);
}
{
  // Signature invalide sans repli M2 possible : 401, rien d'écrit.
  const [enTete, charge] = TOKEN_SIGNE.split('.');
  const forge = `${enTete}.${charge}.${'A'.repeat(86)}`;
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/progress', 'GET', undefined, { token: forge });
  verifie('signature cassée (hors format M2) → 401, aucune écriture',
    statut === 401 && s._m.size === 0, `HTTP ${statut}`);
}

console.log('\nCode referral DÉTERMINISTE — la course de création converge');
{
  // L'app déployée lance /complete (rejoué) et /progress/init (2-3×) EN
  // CONCURRENCE dans l'initState de la page de résultats. Un code tiré au
  // hasard par créateur scindait le compte en deux codes : la ligne n'en
  // gardait qu'un, l'autre restait résolvable/liable mais invisible au
  // comptage — filleuls perdus À VIE (referee: est write-once). Le code
  // étant dérivé du compte, tous les créateurs convergent.
  const a = kvNu();
  const b = kvNu();
  await appel(a, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  await appel(b, PROD, '/progress/init', 'POST', {});
  verifie('création par /complete et par /init → MÊME code (dérivé du compte)',
    /^[a-z0-9]{8}$/.test(ligne(a).referralCode) &&
    ligne(a).referralCode === ligne(b).referralCode,
    `${ligne(a).referralCode} vs ${ligne(b).referralCode}`);
}
{
  // La course réelle : trois requêtes concurrentes sur le MÊME store vierge.
  const s = kvNu();
  await Promise.all([
    appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 }),
    appel(s, PROD, '/progress/init', 'POST', {}),
    appel(s, PROD, '/progress/init', 'POST', {}),
  ]);
  const codes = [...s._m.keys()].filter((k) => k.startsWith('code:'));
  verifie('course complete × init ×2 → UN SEUL code:, aligné sur la ligne stockée',
    codes.length === 1 && codes[0] === `code:${ligne(s).referralCode}`,
    codes.join(','));
}
{
  // Collision : le code dérivé appartient déjà à un AUTRE compte → repli
  // aléatoire, et le mapping du tiers n'est JAMAIS écrasé.
  const hex = await sha256hex(`refcode-v1:${account}`);
  const derive = BigInt('0x' + hex.slice(0, 12)).toString(36).padStart(8, '0').slice(-8);
  const s = kvNu({ [`code:${derive}`]: 'untierscompte' });
  await appel(s, PROD, '/progress/init', 'POST', {});
  verifie('code dérivé déjà pris par un tiers → repli aléatoire, mapping du tiers intact',
    ligne(s).referralCode !== derive && s._m.get(`code:${derive}`) === 'untierscompte',
    `ligne=${ligne(s).referralCode}, dérivé=${derive}`);
}
{
  // AUTO-RÉPARATION : une création passée a échoué à mi-chemin (ligne écrite,
  // mapping code: jamais posé) → le code affiché ne résolvait plus, aucun
  // filleul ne pouvait se lier. Le passage suivant répare.
  const s = kvNu();
  await appel(s, PROD, '/progress/init', 'POST', {});
  const code = ligne(s).referralCode;
  s._m.delete(`code:${code}`);
  await appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('mapping code: perdu → reposé au passage suivant (parrainage réparé)',
    s._m.get(`code:${code}`) === account, String(s._m.get(`code:${code}`)));
}
{
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 1, durationSeconds: 10 });
  verifie('déclaration grossière → 400 et RIEN d\'écrit (ni ligne, ni code, ni preuve)',
    statut === 400 && s._m.size === 0, `HTTP ${statut}, ${s._m.size} clés`);
}
{
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 9, durationSeconds: 4500 });
  verifie('9 sous-tests < plancher → 400', statut === 400, `HTTP ${statut}`);
}
{
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 299 });
  verifie('299 s < plancher → 400', statut === 400, `HTTP ${statut}`);
}
{
  const s = kvNu();
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 'abc', durationSeconds: 4500 });
  verifie('subtests non numérique → 400', statut === 400, `HTTP ${statut}`);
}

console.log('\n/complete — cohérence temporelle (base sûre : le lien posé par le SITE)');
{
  // ATTAQUE n°2 (link puis complete immédiat) via le VRAI endpoint /link :
  // un lien via:'link' est posé à la CRÉATION du passe, donc AVANT tout test —
  // déclarer ensuite 4500 s de test en quelques secondes est impossible.
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  const lien = await appel(s, PROD, '/link', 'POST', { referrerCode: 'testcode' });
  const refereeBrut = s._m.get(`referee:${account}`);
  const referee = JSON.parse(refereeBrut ?? 'null');
  verifie("/link pose un lien JSON HORODATÉ {code, at, via:'link'}",
    lien.corps.linked === true && referee && referee.code === 'testcode' &&
    referee.via === 'link' && Number.isFinite(Date.parse(referee.at)), String(refereeBrut));
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('link (site) → complete immédiat : durée > âge du passe → 400, preuve NON écrite',
    statut === 400 && !s._m.has(`completed:${account}`), `HTTP ${statut}`);
}
{
  // Lien via:'link' ANCIEN : la durée déclarée tient dans l'âge du passe → 200.
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify({ code: 'testcode', at: iso(maintenant - 5000000), via: 'link' }),
    'code:testcode': 'autreproprio',
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('lien site ancien : durée ≤ âge du passe → 200', statut === 200, `HTTP ${statut}`);
}
{
  // IMMUNITÉ AUX SAUTS D'HORLOGE CLIENT : durationS vient de l'horloge MURALE
  // du téléphone (un recalage NTP/manuel pendant le test le gonfle d'autant).
  // Un lien plus vieux que MIN_TEST_DURATION_S n'est JAMAIS une base de 400,
  // même si la durée déclarée dépasse son âge : une passation honnête occupe
  // au moins ce temps RÉEL après la pose du lien, l'exemption est prouvable.
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify(
      { code: 'testcode', at: iso(Date.now() - 400000), via: 'link' }),
    'code:testcode': 'autreproprio',
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('lien site de 400 s + durée 4500 s (horloge cliente sautée) → 200, jamais 400',
    statut === 200, `HTTP ${statut}`);
}
{
  // Bornes de la fenêtre éclair, à durée déclarée MINIMALE plausible (300 s) :
  // la marge de 120 s doit être RÉELLE des deux côtés.
  const cas = async (ageS) => {
    const s = kvNu({
      [`referee:${account}`]: JSON.stringify(
        { code: 'testcode', at: iso(Date.now() - ageS * 1000), via: 'link' }),
      'code:testcode': 'autreproprio',
    });
    return (await appel(s, PROD, '/complete', 'POST',
      { subtestsCompleted: 12, durationSeconds: 300 })).statut;
  };
  verifie('durée 300 s : lien de 175 s → 400 (éclair), lien de 185 s → 200 (dans la marge)',
    (await cas(175)) === 400 && (await cas(185)) === 200,
    `175s=${await cas(175)}, 185s=${await cas(185)}`);
}
{
  // GARDE ANTI-FAUX-POSITIF — LA course réelle de l'app : si le /complete
  // initial a échoué (réseau), complete_test_results_page relance retryPending,
  // isLocked et getProgress EN CONCURRENCE (initState sans await). Un init peut
  // donc créer ligne + lien via:'init' quelques secondes AVANT le /complete
  // rejoué. RIEN de ce que l'app pose n'est une base de rejet : un 400 serait
  // un refus DÉFINITIF pour un utilisateur honnête.
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  await appel(s, PROD, '/progress/init', 'POST', { referrerCode: 'testcode' });
  const referee = JSON.parse(s._m.get(`referee:${account}`) ?? 'null');
  verifie("init pose un lien via:'init' (jamais une base de rejet)",
    referee && referee.via === 'init', JSON.stringify(referee));
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('course init/retry : ligne + lien app récents → 200 (retry honnête sûr) et crédit posé',
    statut === 200 && s._m.has(`ref:testcode:${account}`), `HTTP ${statut}`);
}
{
  // Ligne LEGACY sans marqueur, récente : origine inconnue → jamais de rejet.
  const s = kvNu({ [`progress:${account}`]: JSON.stringify({
    account, referralCode: 'testcode', stage: 1,
    createdAt: iso(maintenant - 60000),
  }) });
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('ligne legacy récente sans marqueur → 200 (jamais une base de rejet)',
    statut === 200, `HTTP ${statut}`);
}
{
  // Lien LEGACY (string sans date) : pas de base temporelle → pas de contrôle,
  // et le crédit fonctionne quand même (rétrocompat).
  const s = kvNu({
    [`referee:${account}`]: 'testcode',
    'code:testcode': 'autreproprio',
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('lien legacy sans date → 200 et crédit posé (rétrocompat)',
    statut === 200 && s._m.has(`ref:testcode:${account}`), `HTTP ${statut}`);
}

console.log('\nCrédit-jonction — (lien ∧ complétion plausible), quel que soit l\'ordre');
{
  // Ordre SITE : lien posé à la création du passe (ancien), test passé ensuite.
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify({ code: 'testcode', at: iso(maintenant - 5000000) }),
    'code:testcode': 'autreproprio',
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST',
    { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('link (ancien) → complete : crédit posé par /complete',
    statut === 200 && s._m.has(`ref:testcode:${account}`), `HTTP ${statut}`);
}
{
  // Ordre APP NOMINAL : /complete au dernier sous-test, PUIS l'écran des
  // missions envoie /progress/init {referrerCode}. C'était LE flux cassé :
  // le lien arrivait trop tard et le crédit n'était jamais posé.
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  await appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  verifie('complete seul : pas encore de crédit (aucun lien)',
    !s._m.has(`ref:testcode:${account}`));
  const { statut } = await appel(s, PROD, '/progress/init', 'POST', { referrerCode: 'testcode' });
  verifie('… puis init {referrerCode} : crédit posé À L\'INIT (flux nominal réparé)',
    statut === 200 && s._m.has(`ref:testcode:${account}`), `HTTP ${statut}`);
}
{
  // Ordre complete → /link (rattrapage par le site).
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  await appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  const { statut, corps } = await appel(s, PROD, '/link', 'POST', { referrerCode: 'testcode' });
  verifie('complete → link : crédit posé AU LINK',
    statut === 200 && corps.linked === true && s._m.has(`ref:testcode:${account}`),
    `HTTP ${statut}`);
}
{
  // 4e point de matérialisation : /link RÉPÉTÉ alors que le lien existe déjà
  // et que la complétion est arrivée entre-temps (branche « lien existant »
  // de handleLink — rattrapage sans nouvelle écriture du lien).
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify(
      { code: 'testcode', at: iso(maintenant - 5000000), via: 'link' }),
    'code:testcode': 'autreproprio',
    [`completed:${account}`]: JSON.stringify(
      { at: iso(maintenant - 3600000), subtests: 12, durationS: 4500 }),
  });
  const avant = s._m.get(`referee:${account}`);
  const { statut, corps } = await appel(s, PROD, '/link', 'POST', { referrerCode: 'testcode' });
  verifie('/link répété (lien existant + complétion présente) → crédit matérialisé, lien INTACT',
    statut === 200 && corps.linked === true &&
    s._m.has(`ref:testcode:${account}`) && s._m.get(`referee:${account}`) === avant,
    `HTTP ${statut}`);
}
{
  // Rejeu au corps VIDE après complétion légitime : plus aucun seuil sauté,
  // et le crédit déjà posé n'est JAMAIS réécrit (write-once).
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify({ code: 'testcode', at: iso(maintenant - 5000000) }),
    'code:testcode': 'autreproprio',
    [`completed:${account}`]: JSON.stringify({ at: iso(maintenant - 3600000), subtests: 12, durationS: 4500 }),
    [`ref:testcode:${account}`]: 'SENTINELLE',
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST', {});
  verifie('rejeu corps vide → 200 (jamais 400 en rejeu), crédit INCHANGÉ',
    statut === 200 && s._m.get(`ref:testcode:${account}`) === 'SENTINELLE', `HTTP ${statut}`);
}
{
  // Ouvrir l'écran des missions sans avoir terminé de test ne crédite rien.
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  const { statut } = await appel(s, PROD, '/progress/init', 'POST', { referrerCode: 'testcode' });
  verifie('init seul (aucune complétion) → lien posé mais AUCUN crédit',
    statut === 200 && s._m.has(`referee:${account}`) && !s._m.has(`ref:testcode:${account}`),
    `HTTP ${statut}`);
}
{
  // Auto-parrainage injecté : jamais de crédit.
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify({ code: 'testcode', at: iso(maintenant - 5000000) }),
    'code:testcode': account, // le compte possède son propre code
    [`completed:${account}`]: JSON.stringify({ at: iso(maintenant), subtests: 12, durationS: 4500 }),
  });
  await appel(s, PROD, '/complete', 'POST', {});
  verifie('auto-parrainage → jamais de crédit', !s._m.has(`ref:testcode:${account}`));
}
{
  // Preuve stockée IMPLAUSIBLE (héritage/injection) : la jonction revalide et
  // refuse de créditer — sans jamais renvoyer 400 en rejeu.
  const s = kvNu({
    [`referee:${account}`]: JSON.stringify({ code: 'testcode', at: iso(maintenant - 5000000) }),
    'code:testcode': 'autreproprio',
    [`completed:${account}`]: JSON.stringify({ at: iso(maintenant), subtests: 1, durationS: 10 }),
  });
  const { statut } = await appel(s, PROD, '/complete', 'POST', {});
  verifie('preuve stockée implausible → 200 mais AUCUN crédit',
    statut === 200 && !s._m.has(`ref:testcode:${account}`), `HTTP ${statut}`);
}
{
  // Second /link avec un autre code : first-write-wins, lien intact.
  const s = kvNu({ 'code:testcode': 'autreproprio', 'code:autrecode': 'troisieme' });
  await appel(s, PROD, '/link', 'POST', { referrerCode: 'testcode' });
  const avant = s._m.get(`referee:${account}`);
  const { corps } = await appel(s, PROD, '/link', 'POST', { referrerCode: 'autrecode' });
  verifie('second /link autre code → linked:false, lien INCHANGÉ',
    corps.linked === false && s._m.get(`referee:${account}`) === avant);
}

console.log('\nGate propriétaire — faille 11 (compte-mule, lignes LOT 0 seulement)');
{
  const s = kv({ stage: 1, firstSeenVia: 'init' });
  s._m.delete(`completed:${account}`);
  const { corps } = await appel(s, PROD);
  verifie('ligne LOT 0 sans complétion : 3 filleuls affichés 0, stage gelé à 1',
    corps.completedReferrals === 0 && corps.stage === 1, JSON.stringify(corps));
}
{
  // EXEMPTION LEGACY : une ligne née AVANT le LOT 0 (sans firstSeenVia) peut
  // ne plus JAMAIS pouvoir produire completed: — builds pré-bba99db
  // (2026-07-19) qui n'appellent pas /complete du tout, honnêtes rejetés 400
  // sous le plancher 600 s (refus mémorisé définitif par le client). La gater
  // serait un gel À VIE de parrains honnêtes : le gate ne s'applique qu'aux
  // lignes marquées LOT 0.
  const s = kv({ stage: 1 });
  s._m.delete(`completed:${account}`);
  const { corps } = await appel(s, PROD);
  verifie('ligne LEGACY sans complétion : filleuls COMPTÉS, transitions ACTIVES (exemption)',
    corps.completedReferrals === 3 && corps.stage === 3, JSON.stringify(corps));
}
{
  const s = kv({ stage: 1 });
  const { corps } = await appel(s, PROD);
  verifie('propriétaire avec complétion : 3 filleuls comptés, stage 3',
    corps.completedReferrals === 3 && corps.stage === 3, JSON.stringify(corps));
}
{
  // RÉVERSIBILITÉ : les ref: accumulés pendant le gel ne sont jamais perdus.
  const s = kv({ stage: 1, firstSeenVia: 'init' });
  s._m.delete(`completed:${account}`);
  const gele = (await appel(s, PROD)).corps;
  await appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  const { corps } = await appel(s, PROD);
  verifie('le propriétaire termine son test → comptage et transitions reprennent (3, stage 3)',
    gele.stage === 1 && corps.completedReferrals === 3 && corps.stage === 3,
    JSON.stringify(corps));
}
{
  // Un déblocage acquis reste acquis, gate ou pas.
  const s = kv({ stage: 4, unlockedAt: iso(maintenant - 1000), firstSeenVia: 'init' }, 0);
  s._m.delete(`completed:${account}`);
  const { corps } = await appel(s, PROD);
  verifie('stage 4 acquis sans complétion propriétaire → reste 4 (jamais rétrogradé)',
    corps.stage === 4 && corps.dayIndex === 9, JSON.stringify(corps));
}
{
  // Ligne stage 3 GELÉE sans ancre : répond comme « attente pas commencée »,
  // sans crash (toISOString sur NaN) et SANS poser d'ancre pendant le gel.
  const s = kv({ stage: 3, firstSeenVia: 'init' });
  s._m.delete(`completed:${account}`);
  const { statut, corps } = await appel(s, PROD);
  verifie('stage 3 gelé sans ancre → 200, pas d\'ancre posée, compte à rebours neutre',
    statut === 200 && corps.unlockAt === null && corps.dayIndex === null &&
    !ligne(s).stage3StartedAt, `HTTP ${statut} ${JSON.stringify(corps)}`);
}

console.log("\nPolitique d'Origin");
{
  const s = kv({ stage: 1 });
  const { statut } = await appel(s, PROD, '/progress', 'GET', undefined,
    { origin: 'https://evil.example' });
  verifie('Origin non listée → 403', statut === 403, `HTTP ${statut}`);
}
{
  const s = kv({ stage: 1 });
  const { statut } = await appel(s, PROD, '/progress', 'GET', undefined,
    { origin: 'https://mental-et.com' });
  verifie('Origin listée → 200', statut === 200, `HTTP ${statut}`);
}
{
  const s = kv({ stage: 1 });
  const sansOrigin = await appel(s, PROD);
  const sansToken = await appel(s, PROD, '/progress', 'GET', undefined, { token: null });
  verifie('Origin absente : accepté AVEC token (app native), 401 SANS token',
    sansOrigin.statut === 200 && sansToken.statut === 401,
    `avec ${sansOrigin.statut}, sans ${sansToken.statut}`);
}

console.log('\n/resolve — contrat de la page invite');
{
  const s = kvNu({ 'code:testcode': 'autreproprio' });
  const connu = await appel(s, PROD, '/resolve/testcode', 'GET', undefined, { token: null });
  const inconnu = await appel(s, PROD, '/resolve/zzzzzzzz', 'GET', undefined, { token: null });
  verifie('code connu → {valid:true}, inconnu → {valid:false}, sans auth',
    connu.corps.valid === true && inconnu.corps.valid === false,
    JSON.stringify([connu.corps, inconnu.corps]));
}

console.log('\n/results — passations rattachées au token, écrites au fil de l\'eau');
{
  const vraiFetch = globalThis.fetch;
  const capte = [];
  const SB = { SUPABASE_URL: 'https://sb.test', SUPABASE_SERVICE_KEY: 'sb_secret_faux' };
  const brancher = (impl) => { globalThis.fetch = impl; };
  const debrancher = () => { globalThis.fetch = vraiFetch; };
  const CSID = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  const supabaseOk = async (url, init) => {
    capte.push({ url: String(url), body: JSON.parse(init.body) });
    if (String(url).includes('test_sessions')) {
      return new Response(JSON.stringify([{ id: 'sess-1' }]), { status: 201 });
    }
    return new Response('[]', { status: 201 });
  };

  const charge = {
    clientSessionId: CSID,
    startedAt: '2026-08-21T13:00:00.000Z',
    completedAt: '2026-08-21T14:03:27.512Z',
    status: 'completed',
    durationS: 4500,
    subtests: [
      { subtest: 'block_design', rawScore: 42 },
      { subtest: 'digit_span', rawScore: 18 },
    ],
  };
  const sessionDe = () => capte.find((c) => c.url.includes('test_sessions'));

  {
    const { statut, corps } = await appel(kvNu(), PROD, '/results', 'POST', charge);
    verifie('sans secrets Supabase → 200 stored:false not_configured',
      statut === 200 && corps.stored === false && corps.reason === 'not_configured',
      JSON.stringify(corps));
  }

  {
    capte.length = 0; brancher(supabaseOk);
    const { statut, corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', charge);
    debrancher();
    verifie('chemin nominal → 200 stored:true, 2 sous-tests',
      statut === 200 && corps.stored === true && corps.subtests === 2, JSON.stringify(corps));

    const se = sessionDe();
    verifie("l'horodatage est réduit à la JOURNÉE (anti-corrélation)",
      se && se.body.completed_on === '2026-08-21' && se.body.started_on === '2026-08-21',
      JSON.stringify(se && se.body));
    verifie('aucune heure fine ne fuit vers la base',
      se && !JSON.stringify(se.body).includes('14:03'), JSON.stringify(se && se.body));
    verifie("la clé écrite est l'account dérivé, jamais le token",
      se && /^[0-9a-f]{32}$/.test(se.body.account) && !JSON.stringify(se.body).includes(TOKEN),
      JSON.stringify(se && se.body));
    verifie('la durée fine est CONSERVÉE (contrôle de plausibilité)',
      se && se.body.duration_s === 4500);
    // La cible du conflit doit être le COUPLE : sur `client_session_id` seul, un
    // envoi sous un autre compte réattribuerait la passation existante au lieu
    // d'en ouvrir une nouvelle (défaut trouvé en revue, migration 015).
    verifie("l'upsert cible le COUPLE (client_session_id, account), pas l'id seul",
      se && se.url.includes('on_conflict=client_session_id,account')
      && se.body.client_session_id === CSID, se && se.url);

    const results = capte.find((c) => c.url.includes('test_results'));
    // Le défaut trouvé au premier test réel : l'app envoyait
    // itemsAdministered / itemsCorrect / medianLatencyMs, le worker les jetait,
    // et les colonnes de la 013 restaient vides. On compare désormais ce qui
    // ENTRE à ce qui SORT, au lieu de vérifier seulement que quelque chose sort.

    verifie('les sous-tests sont rattachés à la session créée',
      results && results.body.length === 2 && results.body.every((r) => r.session_id === 'sess-1'),
      JSON.stringify(results && results.body));
  }

  {
    capte.length = 0; brancher(supabaseOk);
    await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', {
      ...charge,
      subtests: [{
        subtest: 'vocabulary', rawScore: 30, maxScore: 60,
        itemsAdministered: 21, itemsCorrect: 17, medianLatencyMs: 4300,
      }],
    });
    debrancher();
    const w = capte.find((c) => c.url.includes('test_results'));
    verifie('les métriques agrégées ne sont PAS jetées en route',
      w && w.body[0].items_administered === 21 && w.body[0].items_correct === 17
      && w.body[0].median_latency_ms === 4300, JSON.stringify(w && w.body[0]));
  }

  console.log('\n/results — écriture incrémentale (pause et reprise)');
  {
    capte.length = 0; brancher(supabaseOk);
    // 1er flush : le test commence, rien n'est terminé.
    const f1 = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', {
      clientSessionId: CSID, startedAt: '2026-08-21T13:00:00.000Z',
      subtests: [{ subtest: 'block_design', rawScore: 42, items: [{ index: 0, response: 'a' }] }],
    });
    const s1 = sessionDe();
    verifie('flush intermédiaire → status in_progress, aucune date de fin',
      f1.corps.status === 'in_progress' && s1 && s1.body.status === 'in_progress'
      && s1.body.completed_on === undefined, JSON.stringify(s1 && s1.body));

    capte.length = 0;
    const f2 = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { ...charge, subtests: [] });
    debrancher();
    const s2 = sessionDe();
    verifie('flush final sans sous-test → session close en completed',
      f2.statut === 200 && s2 && s2.body.status === 'completed'
      && s2.body.completed_on === '2026-08-21', JSON.stringify(s2 && s2.body));
    verifie('le même clientSessionId est réutilisé → une seule passation',
      s1 && s2 && s1.body.client_session_id === s2.body.client_session_id);
  }

  {
    // Régression : un envoi SANS completedAt ni status laissait `day` à null,
    // et ce null partait dans accounts.last_seen, qui est NOT NULL. Le registre
    // échouait, la session tombait sur sa clé étrangère, et l'échec était muet.
    // C'est exactement la requête que produit un premier flush réel.
    capte.length = 0; brancher(supabaseOk);
    const { corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', {
      clientSessionId: CSID,
      subtests: [{ subtest: 'block_design', rawScore: 1 }],
    });
    debrancher();
    const compte = capte.find((c) => c.url.includes('/accounts'));
    verifie('flush sans completedAt → last_seen JAMAIS null (NOT NULL en base)',
      compte && compte.body.last_seen != null
      && /^\d{4}-\d{2}-\d{2}$/.test(compte.body.last_seen),
      JSON.stringify(compte && compte.body));
    verifie('… et la session est bien écrite malgré tout',
      corps.stored === true && corps.status === 'in_progress', JSON.stringify(corps));
  }

  {
    // Le registre en échec doit être REMONTÉ, pas avalé.
    brancher(async (url) => String(url).includes('/accounts')
      ? new Response('{"message":"null value in column last_seen"}', { status: 400 })
      : new Response(JSON.stringify([{ id: 'sess-1' }]), { status: 201 }));
    const { corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', charge);
    debrancher();
    verifie('registre en échec → account_failed remonté, session non tentée',
      corps.stored === false && corps.reason === 'account_failed', JSON.stringify(corps));
  }

  console.log('\n/results — épreuve orale');
  {
    capte.length = 0; brancher(supabaseOk);
    const { corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', {
      clientSessionId: CSID,
      oral: [
        { cycle: 0, kind: 'reading', textId: 'fr_0042', r2SessionId: 'sess-r2-1',
          layer: 'reusable', durationMs: 61000, latencyMs: 2300, uploadOk: true,
          commercialReuse: true },
        { cycle: 0, kind: 'summary', textId: 'fr_0042', layer: 'internal',
          durationMs: 45000, uploadOk: false, commercialReuse: false },
        { kind: 'reading' },   // sans cycle → rejeté
      ],
    });
    debrancher();
    const o = capte.find((c) => c.url.includes('oral_recordings'));
    verifie('les enregistrements oraux sont écrits, sans cycle ils sont rejetés',
      corps.oral === 2 && o && o.body.length === 2, JSON.stringify(corps));
    verifie('le texte lu, la couche R2 et le consentement sont conservés',
      o && o.body[0].text_id === 'fr_0042' && o.body[0].layer === 'reusable'
      && o.body[0].commercial_reuse === true && o.body[1].layer === 'internal',
      JSON.stringify(o && o.body[0]));
    verifie('aucune donnée sonore ne transite par la base',
      o && !JSON.stringify(o.body).match(/audio|webm|base64|blob/i));
  }

  console.log('\n/results — entrées invalides et robustesse');
  {
    brancher(supabaseOk);
    const sansId = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { ...charge, clientSessionId: undefined });
    const idKo = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { ...charge, clientSessionId: 'pas-un-uuid' });
    const vide = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { clientSessionId: CSID });
    const trop = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { ...charge, subtests: Array.from({ length: 33 }, () => ({ subtest: 'x', rawScore: 1 })) });
    const dateKo = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST',
      { ...charge, completedAt: 'pas-une-date' });
    debrancher();
    verifie('clientSessionId absent → 400', sansId.statut === 400);
    verifie('clientSessionId non UUID → 400', idKo.statut === 400);
    verifie('flush vide et non terminal → 400', vide.statut === 400);
    verifie('plus de 32 sous-tests → 400', trop.statut === 400);
    verifie('completedAt invalide → 400', dateKo.statut === 400);
  }

  {
    brancher(async () => { throw new Error('réseau coupé'); });
    const { statut, corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', charge);
    debrancher();
    verifie('Supabase injoignable → 200 stored:false, jamais 5xx',
      statut === 200 && corps.stored === false && corps.reason === 'unreachable',
      JSON.stringify(corps));
  }

  console.log('\n/results — grain item et registre des comptes');
  {
    capte.length = 0; brancher(supabaseOk);
    const avecItems = {
      ...charge,
      subtests: [{
        subtest: 'vocabulary', rawScore: 30,
        items: [
          { index: 0, itemId: 'voc_01', response: 'chaise', isCorrect: true, score: 2,
            latencyMs: 4300, firstInputMs: 900, editsCount: 2, backspacesCount: 1 },
          { index: 1, itemId: 'voc_02', response: '', skipped: true },
        ],
      }],
    };
    const { corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', avecItems);
    debrancher();
    const it = capte.find((c) => c.url.includes('test_items'));
    verifie('les items sont enregistrés et rattachés à la session',
      corps.items === 2 && it && it.body.length === 2
      && it.body.every((r) => r.session_id === 'sess-1'), JSON.stringify(corps));
    verifie("les métriques d'hésitation et de correction sont transmises",
      it && it.body[0].first_input_ms === 900 && it.body[0].backspaces_count === 1,
      JSON.stringify(it && it.body[0]));
    verifie('un item sauté est marqué comme tel',
      it && it.body[1].skipped === true && it.body[1].is_correct === null);
    verifie("l'upsert des items cible (session, sous-test, rang)",
      it && it.url.includes('on_conflict=session_id,subtest,item_index'), it && it.url);

    const iComptes = capte.findIndex((c) => c.url.includes('/accounts'));
    const iSession = capte.findIndex((c) => c.url.includes('test_sessions'));
    verifie('le compte est enregistré AVANT la passation (contrainte FK)',
      iComptes >= 0 && iSession >= 0 && iComptes < iSession, `${iComptes} < ${iSession}`);
    const compte = capte[iComptes] && capte[iComptes].body;
    verifie("le registre est clé par l'account, jamais par le token",
      compte && /^[0-9a-f]{32}$/.test(compte.account)
      && !JSON.stringify(compte).includes(TOKEN), JSON.stringify(compte));
    verifie('TOKEN de test non signé → AUCUNE démographie enregistrée',
      compte && compte.sex === undefined && compte.region === undefined,
      JSON.stringify(compte));
  }

  {
    capte.length = 0; brancher(supabaseOk);
    const enorme = {
      ...charge,
      subtests: [{ subtest: 'flood', rawScore: 0,
        items: Array.from({ length: 900 }, (_, i) => ({ index: i, response: 'x' })) }],
    };
    const { corps } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', enorme);
    debrancher();
    verifie("flot d'items plafonné à 600", corps.items === 600, JSON.stringify(corps));
  }

  {
    brancher(supabaseOk);
    const { statut } = await appel(kvNu(), { ...PROD, ...SB }, '/results', 'POST', charge,
      { token: 'bidon' });
    debrancher();
    verifie('token invalide → 401 avant toute écriture', statut === 401);
  }
}

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) { console.error('Échecs : ' + echecs.join(' | ')); process.exit(1); }
