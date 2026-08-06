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
import { sha256hex } from '../../_shared/token_verify.js';

const TOKEN = 'M2.' + Buffer.from(JSON.stringify({ n: 'selftest', sv: 2 }))
  .toString('base64url');

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
 * ET une preuve de complétion PLAUSIBLE du propriétaire — sans elle, le gate
 * propriétaire (faille 11) gèlerait comptage et transitions dans tous les
 * scénarios historiques de ce fichier.
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

console.log('\nGate propriétaire — faille 11 (compte-mule)');
{
  const s = kv({ stage: 1 });
  s._m.delete(`completed:${account}`);
  const { corps } = await appel(s, PROD);
  verifie('propriétaire sans complétion : 3 filleuls affichés 0, stage gelé à 1',
    corps.completedReferrals === 0 && corps.stage === 1, JSON.stringify(corps));
}
{
  const s = kv({ stage: 1 });
  const { corps } = await appel(s, PROD);
  verifie('propriétaire avec complétion : 3 filleuls comptés, stage 3',
    corps.completedReferrals === 3 && corps.stage === 3, JSON.stringify(corps));
}
{
  // RÉVERSIBILITÉ : les ref: accumulés pendant le gel ne sont jamais perdus.
  const s = kv({ stage: 1 });
  s._m.delete(`completed:${account}`);
  await appel(s, PROD);
  await appel(s, PROD, '/complete', 'POST', { subtestsCompleted: 12, durationSeconds: 4500 });
  const { corps } = await appel(s, PROD);
  verifie('le propriétaire termine son test → comptage et transitions reprennent (3, stage 3)',
    corps.completedReferrals === 3 && corps.stage === 3, JSON.stringify(corps));
}
{
  // Un déblocage acquis reste acquis, gate ou pas.
  const s = kv({ stage: 4, unlockedAt: iso(maintenant - 1000) }, 0);
  s._m.delete(`completed:${account}`);
  const { corps } = await appel(s, PROD);
  verifie('stage 4 acquis sans complétion propriétaire → reste 4 (jamais rétrogradé)',
    corps.stage === 4 && corps.dayIndex === 9, JSON.stringify(corps));
}
{
  // Ligne stage 3 GELÉE sans ancre : répond comme « attente pas commencée »,
  // sans crash (toISOString sur NaN) et SANS poser d'ancre pendant le gel.
  const s = kv({ stage: 3 });
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

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) { console.error('Échecs : ' + echecs.join(' | ')); process.exit(1); }
