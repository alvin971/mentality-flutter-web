#!/usr/bin/env node
/**
 * Auto-test de la machine à états du worker referral.
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

/** KV en mémoire, même contrat que le binding Cloudflare. */
function kv(rowFields, filleuls = 3) {
  const m = new Map();
  m.set(`progress:${account}`, JSON.stringify({
    account, referralCode: 'testcode', ...rowFields,
  }));
  for (let i = 0; i < filleuls; i++) m.set(`ref:testcode:filleul${i}`, iso(maintenant));
  return {
    _m: m,
    get: async (k) => (m.has(k) ? m.get(k) : null),
    put: async (k, v) => void m.set(k, v),
    list: async ({ prefix }) => ({
      keys: [...m.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name })),
    }),
  };
}

const requete = (path, method, body) => new Request(`https://selftest${path}`, {
  method,
  headers: { 'X-Mentality-Token': TOKEN, 'Content-Type': 'application/json' },
  body: body === undefined ? undefined : JSON.stringify(body),
});

async function appel(store, env, path = '/progress', method = 'GET', body) {
  const resp = await worker.fetch(requete(path, method, body),
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

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) { console.error('Échecs : ' + echecs.join(' | ')); process.exit(1); }
