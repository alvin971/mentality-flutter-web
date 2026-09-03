#!/usr/bin/env node
/**
 * Transcrit les cas du banc par le mini-worker (env.AI.run — même primitive que
 * la production) et met en cache des COMPTES, jamais le texte (lib/tokens.mjs).
 *
 *   node tools/verif_lab/transcribe.mjs --model @cf/openai/whisper [--minutes 60]
 *        [--wave 1,2] [--set pos,neg,sum] [--lang fr] [--holdout] [--language app|none]
 *        [--jobs 3] [--clear-sample 0.10 --seed 7] [--dry-run]
 *
 * Entrée du modèle : octets bruts du fichier, comme le worker les reçoit de
 * l'app ; forme `bytes` (tableau d'octets, production) ou `base64` selon le
 * modèle (MODELES). `language` = X-Language tel que l'app l'envoie (policy
 * `app`), avec le MÊME repli que la production (second essai sans `language`
 * si le modèle refuse) ; policy `none` = jamais de paramètre.
 *
 * Cache : cache/<slug>/<policy>/<sha256(audio_sha|langParam|forme)>.json.
 * Budget : au plus --minutes d'audio NOUVELLEMENT transcrit par exécution ;
 * les cas déjà en cache sont rejoués gratuitement. Ledger : results/ledger.jsonl.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { cheminAudio, LANGUES } from './manifest.mjs';
import { jetons, reference, suiteHits, histogrammes, signatureNormalisation } from './lib/tokens.mjs';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const RACINE = path.resolve(ICI, '..', '..');
const CORPUS = path.join(RACINE, 'assets', 'reading_corpus');
const LAB = process.env.VERIF_LAB_URL || 'http://127.0.0.1:8799';

export const MODELES = {
  '@cf/openai/whisper': { slug: 'whisper', form: 'bytes' },
  '@cf/openai/whisper-large-v3-turbo': { slug: 'whisper-large-v3-turbo', form: 'base64' },
  '@cf/openai/whisper-tiny-en': { slug: 'whisper-tiny-en', form: 'bytes' },
  '@cf/deepgram/nova-3': { slug: 'nova-3', form: 'bytes' },
};

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const has = (k) => args.includes(k);
const MODEL = opt('--model', '@cf/openai/whisper');
if (!MODELES[MODEL]) { console.error(`modèle inconnu ${MODEL}`); process.exit(2); }
const { slug, form } = MODELES[MODEL];
const MINUTES = parseFloat(opt('--minutes', '60'));
const WAVES = opt('--wave', '') ? opt('--wave').split(',').map(Number) : null;
const SETS = opt('--set', '') ? opt('--set').split(',') : null;
const LANGS = opt('--lang', '') ? opt('--lang').split(',') : null;
const HOLDOUT = has('--holdout');
const POLICY = opt('--language', 'app');
const JOBS = parseInt(opt('--jobs', '3'), 10);
const CLEAR = parseFloat(opt('--clear-sample', '0'));
const SEED = parseInt(opt('--seed', '1'), 10);
const DRY = has('--dry-run');

// ─── données ───────────────────────────────────────────────────────────────
const manifests = path.join(ICI, 'manifests');
const index = JSON.parse(fs.readFileSync(path.join(manifests, 'audio_index.json'), 'utf8'));
const texts = JSON.parse(fs.readFileSync(path.join(manifests, 'texts.json'), 'utf8')).texts;
const texteIndex = new Map(texts.map((t) => [t.id, t.index]));
/** Ordre d'équité : à vague égale, le texte n° 0 de chaque langue avant le n° 1, etc. — un budget partiel couvre toutes les langues. */
const indexDe = (c) => texteIndex.get(c.textId) ?? 0;
const cas = fs.readFileSync(path.join(manifests, 'cases.jsonl'), 'utf8').trim().split('\n').map(JSON.parse)
  .filter((c) => (!WAVES || WAVES.includes(c.wave)) && (!SETS || SETS.includes(c.set)) && (!LANGS || LANGS.includes(c.lang)) && (HOLDOUT || !c.holdout))
  .sort((a, b) => a.wave - b.wave || indexDe(a) - indexDe(b) || a.lang.localeCompare(b.lang) || a.id.localeCompare(b.id));
const corpus = new Map();
for (const lang of LANGUES) for (const l of fs.readFileSync(path.join(CORPUS, `${lang}.jsonl`), 'utf8').trim().split('\n')) { const o = JSON.parse(l); corpus.set(o.id, o.text); }
const refs = new Map(texts.map((t) => [t.id, reference(corpus.get(t.id))]));
const SIG = signatureNormalisation();

// ─── cache ─────────────────────────────────────────────────────────────────
const cacheDir = path.join(ICI, 'cache', slug, POLICY);
fs.mkdirSync(cacheDir, { recursive: true });
const cle = (audioSha, langParam) => crypto.createHash('sha256').update(`${audioSha}|${langParam}|${form}`).digest('hex');

// audio distinct → cas (plusieurs cas peuvent partager un fichier)
const parAudio = new Map();
for (const c of cas) {
  const rel = cheminAudio(c); const meta = index[rel];
  if (!meta) continue;
  const langParam = POLICY === 'app' ? c.langParam : '';
  const k = cle(meta.sha256, langParam);
  if (!parAudio.has(k)) parAudio.set(k, { k, rel, meta, langParam, lang: c.lang, cas: [] });
  parAudio.get(k).cas.push(c.id);
}
const fichiers = [...parAudio.values()];
const enCache = (f) => fs.existsSync(path.join(cacheDir, `${f.k}.json`));

// stabilité : vider une fraction tirée au sort du cache des cas sélectionnés
let vides = 0;
if (CLEAR > 0) {
  let a = SEED; const rnd = () => { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  for (const f of fichiers) if (enCache(f) && rnd() < CLEAR) { if (!DRY) fs.unlinkSync(path.join(cacheDir, `${f.k}.json`)); vides++; }
}
const aFaire = fichiers.filter((f) => !enCache(f));
const rejoues = fichiers.length - aFaire.length;
let budget = MINUTES * 60; const selection = [];
for (const f of aFaire) { if (f.meta.duration_s <= budget) { budget -= f.meta.duration_s; selection.push(f); } }
const minutesNouvelles = selection.reduce((a, f) => a + f.meta.duration_s, 0) / 60;
console.log(`${MODEL} · policy ${POLICY} · cas ${cas.length} → fichiers distincts ${fichiers.length} · en cache ${rejoues} (vidés ${vides}) · manquants ${aFaire.length} · sélection ${selection.length} = ${minutesNouvelles.toFixed(1)} min (budget ${MINUTES})`);
if (DRY || !selection.length) process.exit(0);

// ─── appel modèle (miroir de transcrire() en production) ────────────────────
function extraireTexte(reponse) {
  if (typeof reponse === 'string') return reponse;
  if (!reponse || typeof reponse !== 'object') return null;
  if (typeof reponse.text === 'string') return reponse.text;
  if (reponse.result && typeof reponse.result.text === 'string') return reponse.result.text;
  if (typeof reponse.transcription === 'string') return reponse.transcription;
  return null;
}
async function appel(buf, language) {
  const h = { 'X-Model': MODEL, 'X-Input-Form': form };
  if (language) h['X-Language'] = language;
  const r = await fetch(`${LAB}/transcribe`, { method: 'POST', headers: h, body: buf, signal: AbortSignal.timeout(180000) });
  return r.json();
}
async function transcrire(f) {
  const buf = fs.readFileSync(path.join(ICI, f.rel));
  const t0 = Date.now();
  let r = await appel(buf, f.langParam); let fallback = false;
  if (!r.ok && f.langParam) { r = await appel(buf, ''); fallback = true; }
  const ms = Date.now() - t0;
  const entree = {
    model: MODEL, form, policy: POLICY, audio: f.rel, audio_sha: f.meta.sha256, bytes: f.meta.bytes, duration_s: f.meta.duration_s,
    language_param: f.langParam, language_used: fallback ? '' : f.langParam, fallback, ms, ms_model: r.ms ?? null,
    day: new Date().toISOString().slice(0, 10), norm_sig: SIG, status: 'ok', error: null, response_keys: null,
    histo: null, hits: null, lang_detected: null,
  };
  if (!r.ok) { entree.status = 'ai_error'; entree.error = String(r.error || '').slice(0, 200); return entree; }
  const resp = r.response;
  entree.response_keys = resp && typeof resp === 'object' ? Object.keys(resp) : [typeof resp];
  if (resp && resp.transcription_info && typeof resp.transcription_info.language === 'string') entree.lang_detected = resp.transcription_info.language;
  const texte = extraireTexte(resp);
  if (texte === null) { entree.status = 'ai_response_format'; return entree; }
  const j = jetons(texte);
  entree.histo = histogrammes(j);
  entree.hits = {};
  for (const [id, ref] of refs) { const s = suiteHits(j, ref); if (s.length) entree.hits[id] = s; }
  return entree;
}

// ─── exécution ─────────────────────────────────────────────────────────────
const file = selection.slice(); let ok = 0, erreurs = 0, msTotal = 0, secondes = 0; const codes = {};
await Promise.all(Array.from({ length: Math.min(JOBS, file.length) }, async () => {
  while (file.length) {
    const f = file.shift();
    try {
      const e = await transcrire(f);
      fs.writeFileSync(path.join(cacheDir, `${f.k}.json`), JSON.stringify(e));
      msTotal += e.ms; secondes += f.meta.duration_s;
      if (e.status === 'ok') ok++; else { erreurs++; codes[e.status] = (codes[e.status] || 0) + 1; }
    } catch (err) {
      erreurs++; codes.reseau = (codes.reseau || 0) + 1;
      console.error(`échec ${f.rel} : ${String(err.message || err).slice(0, 120)}`);
    }
  }
}));
const ligne = { day: new Date().toISOString().slice(0, 10), model: MODEL, policy: POLICY, new_files: ok + erreurs, new_minutes: Math.round((secondes / 60) * 10) / 10, replayed: rejoues, cleared: vides, errors: erreurs, error_codes: codes, ms_per_audio_min: secondes ? Math.round(msTotal / (secondes / 60)) : null };
fs.appendFileSync(path.join(ICI, 'results', 'ledger.jsonl'), JSON.stringify(ligne) + '\n');
console.log(JSON.stringify(ligne));
