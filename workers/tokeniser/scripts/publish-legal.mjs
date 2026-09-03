#!/usr/bin/env node
/**
 * Archive des TEXTES LÉGAUX dans le KV du tokeniser (famille de clés `legal:`).
 *
 *   node workers/tokeniser/scripts/publish-legal.mjs --dir <chemin>/legal/<cv>/
 *   node workers/tokeniser/scripts/publish-legal.mjs --dir … --force   (réécriture)
 *
 * POURQUOI. Le token sv 3 porte une claim `cv` : « la personne a accepté la
 * version 2026-09-02.v1 ». Sans archive du texte correspondant, cette claim ne
 * prouve rien — on saurait qu'un consentement a été donné, pas SUR QUOI. Ce
 * script pousse donc, sous `legal:<cv>:…`, les textes exacts affichés au moment
 * du consentement :
 *
 *     legal:<cv>:cgu              contenu de cgu.md
 *     legal:<cv>:confidentialite  contenu de confidentialite.md
 *     legal:<cv>:consent-corpus   contenu de consent-corpus.md
 *     legal:<cv>:sha256           le sha256.json (empreintes des trois)
 *
 * Ce contenu est strictement PUBLIC (ce sont les pages du site) : aucune donnée
 * personnelle n'entre en KV ici, l'engagement d'anonymat du worker est intact.
 *
 * Le dossier `legal/<cv>/` est produit par `scripts/export-legal.mjs` du site
 * Astro (~/projects/web-site-maker/clients/mental-et).
 *
 * DEUX GARDE-FOUS, tous deux bloquants :
 *   1. les sha256 recalculés doivent correspondre à `sha256.json` — un texte
 *      retouché à la main après l'export ne part pas ;
 *   2. une version déjà présente en KV n'est jamais écrasée sans `--force` :
 *      réécrire l'archive d'un consentement déjà donné le viderait de sa valeur
 *      (art. 7(1) RGPD). Un texte qui change appelle un NOUVEAU `cv`, pas un
 *      écrasement.
 *
 * Node pur, zéro dépendance. Nécessite `CLOUDFLARE_API_TOKEN` dans
 * l'environnement (comme tout appel wrangler du dépôt) et un `id` de namespace
 * réel dans wrangler.toml.
 */

import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Racine du worker : wrangler y trouve wrangler.toml (donc le binding RATE_KV).
const WORKER_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const BINDING = 'RATE_KV';

// Fichier sur disque → suffixe de clé KV. Les trois documents sont OBLIGATOIRES :
// un consentement partiellement archivé ne prouve rien de plus qu'aucun.
const DOCUMENTS = [
  ['cgu.md', 'cgu'],
  ['confidentialite.md', 'confidentialite'],
  ['consent-corpus.md', 'consent-corpus'],
];
const MANIFESTE = 'sha256.json';

function mourir(message) {
  console.error(`\n✗ ${message}\n`);
  process.exit(1);
}

// ─── Arguments ────────────────────────────────────────────────────────────────

function lireArguments(argv) {
  let dir = null;
  let force = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--force') { force = true; continue; }
    if (a === '--dir') { dir = argv[++i] ?? null; continue; }
    if (a.startsWith('--dir=')) { dir = a.slice('--dir='.length); continue; }
    if (a === '--help' || a === '-h') {
      console.log('Usage : publish-legal.mjs --dir <chemin d\'un dossier legal/<cv>/> [--force]');
      process.exit(0);
    }
    mourir(`Argument inconnu : ${a}`);
  }
  if (!dir) mourir('--dir <chemin d\'un dossier legal/<cv>/> est requis.');
  return { dir: isAbsolute(dir) ? dir : resolve(process.cwd(), dir), force };
}

// ─── Lecture et vérification du dossier ───────────────────────────────────────

const sha256hex = (buf) => createHash('sha256').update(buf).digest('hex');

function lireDossier(dir) {
  if (!existsSync(dir) || !statSync(dir).isDirectory()) {
    mourir(`Dossier introuvable : ${dir}`);
  }
  const cheminManifeste = join(dir, MANIFESTE);
  if (!existsSync(cheminManifeste)) {
    mourir(`${MANIFESTE} manquant dans ${dir} (produit par scripts/export-legal.mjs du site).`);
  }

  let manifeste;
  try {
    manifeste = JSON.parse(readFileSync(cheminManifeste, 'utf8'));
  } catch (e) {
    mourir(`${MANIFESTE} illisible : ${e.message}`);
  }
  const cv = manifeste && typeof manifeste.version === 'string' ? manifeste.version.trim() : '';
  if (!cv) mourir(`${MANIFESTE} : champ "version" absent ou vide (c'est le cv du token).`);
  const empreintes = manifeste && typeof manifeste.files === 'object' && manifeste.files !== null
    ? manifeste.files
    : null;
  if (!empreintes) mourir(`${MANIFESTE} : champ "files" absent (map nom de fichier → sha256).`);

  // Vérification d'intégrité, fichier par fichier.
  const fichiers = [];
  const ecarts = [];
  for (const [nom, suffixe] of DOCUMENTS) {
    const chemin = join(dir, nom);
    if (!existsSync(chemin)) { ecarts.push(`${nom} : fichier manquant`); continue; }
    const attendu = empreintes[nom];
    if (typeof attendu !== 'string' || attendu.length === 0) {
      ecarts.push(`${nom} : aucune empreinte dans ${MANIFESTE}`);
      continue;
    }
    const reel = sha256hex(readFileSync(chemin));
    if (reel.toLowerCase() !== attendu.toLowerCase()) {
      ecarts.push(`${nom} : sha256 ${reel} ≠ ${attendu} annoncé`);
      continue;
    }
    fichiers.push({ nom, suffixe, chemin, sha: reel });
  }
  // Une empreinte annoncée sans document sur disque = export incomplet.
  for (const nom of Object.keys(empreintes)) {
    if (!DOCUMENTS.some(([n]) => n === nom)) {
      ecarts.push(`${nom} : annoncé dans ${MANIFESTE} mais hors du jeu de documents attendu`);
    }
  }
  if (ecarts.length) {
    mourir(
      `Intégrité du dossier ${dir} :\n    - ${ecarts.join('\n    - ')}\n` +
      '  Re-lancer `npm run build` côté site (export-legal.mjs) plutôt que de retoucher les .md.',
    );
  }
  return { cv, fichiers, cheminManifeste };
}

// ─── wrangler ─────────────────────────────────────────────────────────────────

function wrangler(args) {
  const r = spawnSync('npx', ['--yes', 'wrangler@latest', ...args], {
    cwd: WORKER_DIR,
    encoding: 'utf8',
    env: process.env,
  });
  if (r.error) mourir(`Impossible de lancer wrangler : ${r.error.message}`);
  return { code: r.status, stdout: r.stdout || '', stderr: r.stderr || '' };
}

// Messages d'erreur wrangler qui NE signifient PAS « clé absente » : les
// confondre ferait croire la version libre et autoriserait un écrasement.
const ERREURS_BLOQUANTES =
  /authenticat|unauthoriz|not logged in|api token|10000|10001|credential|forbidden|namespace|binding/i;

/** True si la clé existe déjà en KV. Sort en erreur si le doute est possible. */
function cleExistante(cle) {
  const r = wrangler(['kv', 'key', 'get', '--binding', BINDING, '--remote', cle]);
  if (r.code === 0) return true;
  const bruit = `${r.stdout}\n${r.stderr}`;
  // Clé absente : wrangler répond 404 « Not Found ». À tester AVANT la liste des
  // erreurs bloquantes, car l'URL de l'API contient « namespaces » et faisait
  // passer une absence normale pour une panne (constaté au premier lancement).
  if (/\b404\b|Not Found/i.test(bruit)) return false;
  if (ERREURS_BLOQUANTES.test(bruit)) {
    mourir(
      `Lecture de ${cle} impossible (ce n'est PAS une clé absente) :\n${bruit.trim()}\n` +
      "  Vérifier CLOUDFLARE_API_TOKEN et l'`id` du namespace RATE_KV dans wrangler.toml.",
    );
  }
  return false; // clé absente
}

function poserCle(cle, chemin) {
  const r = wrangler(['kv', 'key', 'put', '--binding', BINDING, '--remote', cle, '--path', chemin]);
  if (r.code !== 0) {
    mourir(`Écriture de ${cle} en échec :\n${(r.stderr || r.stdout).trim()}`);
  }
}

// ─── Programme ────────────────────────────────────────────────────────────────

const { dir, force } = lireArguments(process.argv.slice(2));
const { cv, fichiers, cheminManifeste } = lireDossier(dir);

console.log(`\n─── Archive légale ${cv} → KV ${BINDING} ───\n`);
for (const f of fichiers) console.log(`  ✓ ${f.nom.padEnd(22)} sha256 ${f.sha.slice(0, 16)}…`);

const aEcrire = [
  ...fichiers.map((f) => ({ cle: `legal:${cv}:${f.suffixe}`, chemin: f.chemin })),
  { cle: `legal:${cv}:sha256`, chemin: cheminManifeste },
];

const dejaLa = aEcrire.map((e) => e.cle).filter((cle) => cleExistante(cle));
if (dejaLa.length && !force) {
  mourir(
    `La version ${cv} est DÉJÀ archivée en KV :\n    - ${dejaLa.join('\n    - ')}\n` +
    '  Un texte qui change appelle un NOUVEAU numéro de version (bump de\n' +
    '  LEGAL_VERSION côté site + LEGAL_VERSIONS dans wrangler.toml), jamais un\n' +
    '  écrasement : réécrire l\'archive d\'un consentement déjà donné le viderait\n' +
    '  de sa valeur probante (RGPD art. 7(1)).\n' +
    '  Réécriture délibérée (version jamais servie en production) : --force.',
  );
}
if (dejaLa.length) {
  console.log(`\n  ⚠️  --force : ${dejaLa.length} clé(s) existante(s) vont être ÉCRASÉES.`);
}

console.log('');
for (const { cle, chemin } of aEcrire) {
  poserCle(cle, chemin);
  console.log(`  → ${cle}`);
}

console.log(
  `\n${aEcrire.length} clés écrites. Contrôle :\n` +
  `  npx --yes wrangler@latest kv key list --binding ${BINDING} --remote --prefix legal:${cv}:\n` +
  `  npx --yes wrangler@latest kv key get  --binding ${BINDING} --remote legal:${cv}:sha256\n` +
  '  (consigner ce sha256 au vault, Projects/Mentality/Decisions.md)\n',
);
