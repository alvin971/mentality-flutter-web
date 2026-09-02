#!/usr/bin/env node
/**
 * Auto-test du module partagé `_shared` : vérification de token (sv 2 et sv 3)
 * et lecture du plan porté par les claims.
 *
 *   node workers/_shared/scripts/selftest.mjs
 *
 * Aucune dépendance, aucun réseau, aucun compte Cloudflare : les modules de
 * production sont importés tels quels.
 *
 * POURQUOI CE FICHIER. `_shared/token_verify.js` est BUNDLÉ dans chaque worker
 * au `wrangler deploy` : une régression ici casse simultanément referral, event,
 * r2-upload et le tokeniser — c'est-à-dire toute l'app live. Les selftests de
 * chaque worker exercent le module de biais, à travers leurs routes ; celui-ci
 * l'exerce de face, y compris les cas qu'aucun worker ne produit encore.
 *
 * ENJEU PARTICULIER DU sv 3. Les claims `p` / `cc` / `cv` sont la PREUVE de
 * consentement à la conservation et à la cession d'un enregistrement vocal.
 * Un sv 3 mal formé accepté « au mieux » ferait entrer un fichier dans le
 * corpus cessible sans consentement valable. D'où les quatre cas de forme
 * ci-dessous : ils doivent tous refuser, jamais deviner.
 *
 * Même procédé que `workers/event/scripts/selftest.mjs` : on forge un vrai
 * couple de clés Ed25519 et on enregistre la publique dans la map partagée
 * `TOKEN_SIGNING_PUBLIC_KEYS` (propriétés mutables), ce qui évite d'ouvrir une
 * couture d'injection dans le code de production. La vérification exercée est
 * donc la VRAIE.
 *
 * À lancer avant chaque `wrangler deploy` d'un worker qui importe `_shared`.
 */

import { verifyToken, TOKEN_SIGNING_PUBLIC_KEYS } from '../token_verify.js';
import { readPlan } from '../token_plan.js';

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

const cle = await keypair('ktest_shared');
const NONCE = 'nonce-partage';

/** Claims sv 3 nominales ; [extra] écrase, une valeur `undefined` supprime. */
const claims3 = (extra = {}) => {
  const base = {
    s: 'M', y: 1998, m: 7, r: 'IDF',
    p: 'free', cc: true, cv: '2026-09-02.v1',
    d: 20700, n: NONCE, sv: 3,
  };
  const fusion = { ...base, ...extra };
  for (const [k, v] of Object.entries(fusion)) if (v === undefined) delete fusion[k];
  return fusion;
};

const verif = (token) => verifyToken(token, TOKEN_SIGNING_PUBLIC_KEYS);

let ok = 0;
const echecs = [];
function verifie(nom, condition, detail = '') {
  if (condition) { ok++; console.log(`  ✓ ${nom}`); }
  else { echecs.push(nom); console.log(`  ✗ ${nom}  ${detail}`); }
}

console.log('\n─── Module partagé — workers/_shared ───\n');

// ─────────────────────────────────────────────────────────────────────────────
console.log('Vérification de token — versions de schéma');
{
  const v2 = await verif(await signe(cle, { s: 'F', y: 1990, m: 3, r: 'IDF', d: 20700, n: NONCE, sv: 2 }));
  verifie('sv 2 signé → valide (les anciens passes restent acceptés)',
    v2.valid === true && v2.nonce === NONCE, `reason = ${v2.reason}`);

  const v3 = await verif(await signe(cle, claims3()));
  verifie('sv 3 signé bien formé → valide, claims de plan lisibles',
    v3.valid === true && v3.claims.p === 'free' && v3.claims.cc === true
      && v3.claims.cv === '2026-09-02.v1',
    `reason = ${v3.reason} claims = ${JSON.stringify(v3.claims)}`);

  const v4 = await verif(await signe(cle, claims3({ sv: 4 })));
  verifie('sv 4 (schéma futur) → refus « schema_version »',
    v4.valid === false && v4.reason === 'schema_version', `reason = ${v4.reason}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nForme stricte des claims sv 3 — un plan mal formé ne vaut jamais consentement');
{
  const gold = await verif(await signe(cle, claims3({ p: 'gold' })));
  verifie('sv 3 avec p:\'gold\' (plan inconnu) → refus « claims »',
    gold.valid === false && gold.reason === 'claims', `reason = ${gold.reason}`);

  const ccTexte = await verif(await signe(cle, claims3({ cc: 'true' })));
  verifie('sv 3 avec cc non booléen → refus « claims »',
    ccTexte.valid === false && ccTexte.reason === 'claims', `reason = ${ccTexte.reason}`);

  const sansCv = await verif(await signe(cle, claims3({ cv: undefined })));
  verifie('sv 3 sans cv (version légale absente) → refus « claims »',
    sansCv.valid === false && sansCv.reason === 'claims', `reason = ${sansCv.reason}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nAucun repli DEV ici — la vérification partagée exige une signature');
{
  // Le worker referral accepte ce format en repli (gate marketing, données non
  // sensibles) ; le module partagé, lui, ne le reconnaît même pas comme un JWS.
  const dev = await verif('M2.' + segment(claims3()));
  verifie('token DEV « M2.<claims> » → refus « format » (jamais de repli ici)',
    dev.valid === false && dev.reason === 'format', `reason = ${dev.reason}`);
}

// ─────────────────────────────────────────────────────────────────────────────
console.log('\nreadPlan — autorité des claims signées');
{
  const sv2 = readPlan({ s: 'M', y: 1998, m: 7, r: 'IDF', d: 20700, n: NONCE, sv: 2 });
  verifie('readPlan sur des claims sv 2 → plan null (repli écran in-app)',
    sv2.plan === null && sv2.corpusConsent === false && sv2.legalVersion === null,
    JSON.stringify(sv2));

  const gratuit = readPlan(claims3({ p: 'free', cc: true }));
  verifie('readPlan free + cc:true → corpusConsent true, version lue',
    gratuit.plan === 'free' && gratuit.corpusConsent === true
      && gratuit.legalVersion === '2026-09-02.v1',
    JSON.stringify(gratuit));

  const payant = readPlan(claims3({ p: 'paid', cc: true }));
  verifie('readPlan paid + cc:true → corpusConsent FORCÉ à false (art. 7.4)',
    payant.plan === 'paid' && payant.corpusConsent === false,
    JSON.stringify(payant));
}

console.log(`\n${ok} vérifications OK, ${echecs.length} en échec`);
if (echecs.length) {
  console.error('Échecs : ' + echecs.join(' | '));
  process.exit(1);
}
