#!/usr/bin/env node
/**
 * Publication de la RÉFÉRENCE de vérification du corpus de lecture dans R2.
 *
 *   node workers/r2-upload/scripts/publish-corpus.mjs --dry-run --out <dossier>
 *   node workers/r2-upload/scripts/publish-corpus.mjs               (pousse dans R2)
 *
 * POURQUOI. Le worker r2-upload vérifie chaque enregistrement de lecture en
 * comparant une transcription bon marché au texte que la personne devait lire.
 * Il lui faut donc, côté serveur, la liste des mots de chaque texte du corpus
 * (assets/reading_corpus/*.jsonl, embarqué dans l'app). Ce script produit,
 * pour chaque texte, un objet compact :
 *
 *     corpus/<textId>.json   →   { "id": "fr_00042", "lang": "fr", "words": [ … ] }
 *
 * où `words` = mots DISTINCTS normalisés du corps du texte (minuscules, sans
 * accent, sans ponctuation, longueur ≥ 4), calculés par
 * workers/_shared/text_norm.js — STRICTEMENT la même fonction que celle
 * appliquée à la transcription dans le worker. C'est ce qui rend le
 * recouvrement comparable ; ne jamais normaliser ici autrement que là-bas.
 *
 * `<textId>` est la valeur que l'app envoie dans l'en-tête X-Text-Id (champ
 * `id` du jsonl, ex. `fr_00042`, `en_GB_00007`) : le worker lit exactement
 * `corpus/<X-Text-Id>.json`.
 *
 * Ces objets sont du contenu PUBLIC (les textes lus sont dans l'app) : aucune
 * donnée personnelle n'entre en R2 par ce script.
 *
 * --dry-run --out <dossier> : écrit les fichiers dans le dossier indiqué, sans
 * toucher à R2, et affiche le nombre de textes et la taille totale. C'est le
 * seul mode utilisable tant que R2 n'est pas activé sur le compte.
 *
 * Mode réel : un `wrangler r2 object put --remote` par texte (bucket
 * `mentality-audio`, juridiction eu). Nécessite CLOUDFLARE_API_TOKEN et un
 * bucket existant. Réécrit sans demander : la référence est déterministe, la
 * réécrire ne perd rien. Compter ~1 à 2 s par objet, soit 15 à 25 min pour
 * l'ensemble du corpus.
 *
 * Node pur, zéro dépendance.
 */

import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { LONGUEUR_MIN_MOT, motsDistincts } from '../../_shared/text_norm.js';

// Racine du worker : wrangler y trouve wrangler.toml.
const WORKER_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const REPO_DIR = resolve(WORKER_DIR, '..', '..');
const CORPUS_DIR = join(REPO_DIR, 'assets', 'reading_corpus');

const BUCKET = 'mentality-audio';
const JURIDICTION = 'eu';
const PREFIXE = 'corpus/';

// Même format que les fragments de clé acceptés par le worker (X-Text-Id) :
// un id hors format ne pourrait jamais être demandé, donc jamais publié.
const FORMAT_ID = /^[A-Za-z0-9_-]{1,80}$/;

function mourir(message) {
  console.error(`\n✗ ${message}\n`);
  process.exit(1);
}

// ─── Arguments ────────────────────────────────────────────────────────────────

function lireArguments(argv) {
  let dryRun = false;
  let out = null;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') { dryRun = true; continue; }
    if (a === '--out') { out = argv[++i] ?? null; continue; }
    if (a.startsWith('--out=')) { out = a.slice('--out='.length); continue; }
    if (a === '--help' || a === '-h') {
      console.log('Usage : publish-corpus.mjs [--dry-run --out <dossier>]');
      process.exit(0);
    }
    mourir(`Argument inconnu : ${a}`);
  }
  if (dryRun && !out) mourir('--dry-run exige --out <dossier> (où écrire les fichiers).');
  if (!dryRun && out) mourir('--out n\'a de sens qu\'avec --dry-run.');
  return { dryRun, out: out ? (isAbsolute(out) ? out : resolve(process.cwd(), out)) : null };
}

// ─── Lecture du corpus ────────────────────────────────────────────────────────

/**
 * Lit tous les jsonl du corpus et renvoie la liste des objets de référence.
 * Sort en erreur au premier texte mal formé : une référence partielle
 * pénaliserait silencieusement les personnes tombées sur le texte manquant.
 */
function lireCorpus() {
  if (!existsSync(CORPUS_DIR) || !statSync(CORPUS_DIR).isDirectory()) {
    mourir(`Dossier du corpus introuvable : ${CORPUS_DIR}`);
  }
  const fichiers = readdirSync(CORPUS_DIR).filter((f) => f.endsWith('.jsonl')).sort();
  if (fichiers.length === 0) mourir(`Aucun .jsonl dans ${CORPUS_DIR}`);

  const references = [];
  const vus = new Set();
  const ecarts = [];
  for (const fichier of fichiers) {
    const lignes = readFileSync(join(CORPUS_DIR, fichier), 'utf8').split('\n');
    lignes.forEach((brut, index) => {
      const ligne = brut.trim();
      if (!ligne) return;
      const ou = `${fichier}:${index + 1}`;
      let d;
      try { d = JSON.parse(ligne); } catch (e) { ecarts.push(`${ou} : JSON illisible (${e.message})`); return; }
      if (typeof d.id !== 'string' || !FORMAT_ID.test(d.id)) { ecarts.push(`${ou} : id absent ou hors format`); return; }
      if (typeof d.lang !== 'string' || !d.lang) { ecarts.push(`${ou} : lang absente`); return; }
      if (typeof d.text !== 'string' || !d.text.trim()) { ecarts.push(`${ou} : text absent ou vide`); return; }
      if (vus.has(d.id)) { ecarts.push(`${ou} : id ${d.id} en double`); return; }
      vus.add(d.id);
      const words = motsDistincts(d.text);
      if (words.length === 0) { ecarts.push(`${ou} : aucun mot de ${LONGUEUR_MIN_MOT}+ caractères`); return; }
      references.push({ id: d.id, lang: d.lang, words });
    });
  }
  if (ecarts.length) {
    mourir(`Corpus invalide :\n    - ${ecarts.join('\n    - ')}`);
  }
  return references;
}

/** Sérialisation compacte, identique en dry-run et en réel. */
const serialise = (ref) => JSON.stringify(ref);

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

function poserObjet(cle, chemin) {
  const r = wrangler([
    'r2', 'object', 'put', `${BUCKET}/${cle}`,
    '--file', chemin,
    '--content-type', 'application/json',
    '--jurisdiction', JURIDICTION,
    '--remote',
  ]);
  if (r.code !== 0) {
    mourir(`Écriture de ${cle} en échec :\n${(r.stderr || r.stdout).trim()}`);
  }
}

// ─── Programme ────────────────────────────────────────────────────────────────

const { dryRun, out } = lireArguments(process.argv.slice(2));
const references = lireCorpus();

const parLangue = {};
let octets = 0;
let motsMin = Infinity;
let motsMax = 0;
for (const ref of references) {
  parLangue[ref.lang] = (parLangue[ref.lang] || 0) + 1;
  octets += Buffer.byteLength(serialise(ref), 'utf8');
  motsMin = Math.min(motsMin, ref.words.length);
  motsMax = Math.max(motsMax, ref.words.length);
}

const resume = () => {
  console.log(`\n  textes      : ${references.length}`);
  console.log(`  par langue  : ${Object.entries(parLangue).map(([l, n]) => `${l}=${n}`).join(', ')}`);
  console.log(`  mots/texte  : ${motsMin} à ${motsMax} (distincts, ≥ ${LONGUEUR_MIN_MOT} caractères)`);
  console.log(`  taille      : ${octets} octets (${(octets / 1024).toFixed(1)} Kio) au total\n`);
};

if (dryRun) {
  console.log(`\n─── Référence du corpus → dossier local ${out} (dry-run, R2 non touché) ───`);
  mkdirSync(out, { recursive: true });
  for (const ref of references) writeFileSync(join(out, `${ref.id}.json`), serialise(ref));
  resume();
  console.log(`  ${references.length} fichiers écrits sous ${out}\n`);
  process.exit(0);
}

console.log(`\n─── Référence du corpus → R2 ${BUCKET} (${JURIDICTION}) sous ${PREFIXE} ───`);
if (!process.env.CLOUDFLARE_API_TOKEN) {
  mourir('CLOUDFLARE_API_TOKEN absent de l\'environnement (requis par wrangler).');
}
const tmp = mkdtempSync(join(tmpdir(), 'corpus-ref-'));
try {
  let n = 0;
  for (const ref of references) {
    const chemin = join(tmp, `${ref.id}.json`);
    writeFileSync(chemin, serialise(ref));
    poserObjet(`${PREFIXE}${ref.id}.json`, chemin);
    n++;
    if (n % 50 === 0 || n === references.length) {
      console.log(`  ${n}/${references.length} objets publiés`);
    }
  }
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
resume();
