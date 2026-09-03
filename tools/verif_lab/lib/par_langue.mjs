#!/usr/bin/env node
/**
 * Tableau par langue pour le JOURNAL, depuis le cache (comptes seulement) :
 * pire / médiane du recouvrement des cas sélectionnés, meilleur imposteur
 * (max sur les autres textes de la langue), latence médiane.
 *   node tools/verif_lab/lib/par_langue.mjs --model @cf/openai/whisper [--language app] [--wave 1] [--content full] [--proc clean]
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { reference, recouvrementDepuisHits } from './tokens.mjs';
import { cheminAudio, LANGUES } from '../manifest.mjs';

const LAB = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const RACINE = path.resolve(LAB, '..', '..');
const SLUGS = { '@cf/openai/whisper': 'whisper', '@cf/openai/whisper-large-v3-turbo': 'whisper-large-v3-turbo', '@cf/openai/whisper-tiny-en': 'whisper-tiny-en', '@cf/deepgram/nova-3': 'nova-3' };
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const MODEL = opt('--model', '@cf/openai/whisper'); const POLICY = opt('--language', 'app');
const WAVE = opt('--wave', null); const CONTENT = opt('--content', 'full'); const PROC = opt('--proc', 'clean');

const texts = JSON.parse(fs.readFileSync(path.join(LAB, 'manifests', 'texts.json'), 'utf8')).texts;
const corpus = new Map();
for (const l of LANGUES) for (const x of fs.readFileSync(path.join(RACINE, 'assets', 'reading_corpus', `${l}.jsonl`), 'utf8').trim().split('\n')) { const o = JSON.parse(x); corpus.set(o.id, o.text); }
const refs = new Map(texts.map((t) => [t.id, reference(corpus.get(t.id))]));
const index = JSON.parse(fs.readFileSync(path.join(LAB, 'manifests', 'audio_index.json'), 'utf8'));
const dir = path.join(LAB, 'cache', SLUGS[MODEL], POLICY);
const cache = new Map();
for (const f of fs.readdirSync(dir)) { const e = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); cache.set(`${e.audio_sha}|${e.language_param}`, e); }
const cas = fs.readFileSync(path.join(LAB, 'manifests', 'cases.jsonl'), 'utf8').trim().split('\n').map(JSON.parse)
  .filter((c) => !c.holdout && c.set === 'pos' && (!WAVE || c.wave === Number(WAVE)) && (CONTENT === '*' || c.content === CONTENT) && (PROC === '*' || c.proc === PROC));
const par = {};
for (const c of cas) {
  const m = index[cheminAudio(c)]; const e = m && cache.get(`${m.sha256}|${POLICY === 'app' ? c.langParam : ''}`);
  if (!e || e.status !== 'ok') continue;
  const ov = recouvrementDepuisHits((e.hits || {})[c.target] || [], refs.get(c.target)).overlap;
  let best = 0;
  for (const t of texts) if (t.lang === c.lang && !t.holdout && t.id !== c.target) { const o = recouvrementDepuisHits((e.hits || {})[t.id] || [], refs.get(t.id)).overlap; if (o > best) best = o; }
  (par[c.lang] ||= []).push({ ov, best, ms: e.ms, d: e.duration_s, det: e.lang_detected });
}
console.log(`| langue | n | pire recouvrement | médiane | meilleur imposteur | ms / min d'audio (méd.) | langue détectée |`);
console.log('|---|---|---|---|---|---|---|');
for (const l of LANGUES) {
  const v = par[l] || []; if (!v.length) continue;
  const ovs = v.map((x) => x.ov).sort((a, b) => a - b); const ms = v.map((x) => x.ms / (x.d / 60)).sort((a, b) => a - b);
  const det = {}; for (const x of v) if (x.det) det[x.det] = (det[x.det] || 0) + 1;
  console.log(`| ${l} | ${v.length} | ${ovs[0].toFixed(3).replace('.', ',')} | ${ovs[ovs.length >> 1].toFixed(3).replace('.', ',')} | ${Math.max(...v.map((x) => x.best)).toFixed(3).replace('.', ',')} | ${Math.round(ms[ms.length >> 1]).toLocaleString('fr-FR')} | ${Object.entries(det).map(([k, n]) => `${k}=${n}`).join(' ') || '—'} |`);
}
