#!/usr/bin/env node
/**
 * Fabrique les audios synthétiques du banc (protocole §3). CACHE : un fichier
 * déjà présent n'est jamais régénéré — la graine et les manifestes suffisent à
 * tout reconstruire à l'identique.
 *
 *   node tools/verif_lab/synth.mjs [--wave 1,2] [--set pos,neg,sum] [--lang fr,en]
 *                                  [--holdout] [--jobs 6] [--dry-run]
 *
 * Voix : piper (~/.venvs/piper, voix dans ~/.cache/piper-voices, cf. voices.json).
 * Dégradations / encodages : degrade.sh (ffmpeg). Sorties :
 *   work/<lang>/<textId>.<voix>.<contenu>.wav         wav propre 22,05 kHz (intermédiaire)
 *   audio/<lang>/<textId>.<voix>.<contenu>.<proc>.<fmt> fichier final, tel que l'app l'enverrait
 *   manifests/audio_index.json                        chemin → { bytes, duration_s, sha256 }
 * Le contenu des résumés (resumes_src.json) et des traductions (xlang_src.json)
 * est rédigé à part ; un cas dont la source manque est sauté et signalé.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn, execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { cheminAudio, LANGUES } from './manifest.mjs';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const RACINE = path.resolve(ICI, '..', '..');
const CORPUS = path.join(RACINE, 'assets', 'reading_corpus');
const PIPER_PY = path.join(os.homedir(), '.venvs', 'piper', 'bin', 'python');
const VOICES_DIR = path.join(os.homedir(), '.cache', 'piper-voices');

// ─── arguments ─────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const has = (k) => args.includes(k);
const WAVES = opt('--wave', '') ? opt('--wave').split(',').map(Number) : null;
const SETS = opt('--set', '') ? opt('--set').split(',') : null;
const LANGS = opt('--lang', '') ? opt('--lang').split(',') : null;
const HOLDOUT = has('--holdout');
const JOBS = parseInt(opt('--jobs', '6'), 10);
const DRY = has('--dry-run');

// ─── données ───────────────────────────────────────────────────────────────
const manifests = path.join(ICI, 'manifests');
const cas = fs.readFileSync(path.join(manifests, 'cases.jsonl'), 'utf8').trim().split('\n').map(JSON.parse)
  .filter((c) => (!WAVES || WAVES.includes(c.wave)) && (!SETS || SETS.includes(c.set)) && (!LANGS || LANGS.includes(c.lang)) && (HOLDOUT || !c.holdout));
const voix = JSON.parse(fs.readFileSync(path.join(manifests, 'voices.json'), 'utf8'));
const lireJson = (f) => (fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : {});
const resumes = lireJson(path.join(manifests, 'resumes_src.json'));
const xlang = lireJson(path.join(manifests, 'xlang_src.json'));
const textes = new Map();
for (const lang of LANGUES) {
  for (const l of fs.readFileSync(path.join(CORPUS, `${lang}.jsonl`), 'utf8').trim().split('\n')) {
    const o = JSON.parse(l); textes.set(o.id, o.text.trim());
  }
}

// ─── manipulations de texte (§3) ───────────────────────────────────────────
function mulberry32(a) {
  return function () { a |= 0; a = (a + 0x6d2b79f5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}
const graineDe = (s) => parseInt(crypto.createHash('sha256').update(s).digest('hex').slice(0, 8), 16);
const mots = (t) => t.split(/\s+/);
const part = (t, p) => { const m = mots(t); return m.slice(0, Math.max(1, Math.round(m.length * p))).join(' '); };
function premierePhrase(t) { const m = t.match(/^[\s\S]*?[.!?](?=\s|$)/); return (m ? m[0] : part(t, 0.15)).trim(); }
function melange(t, graine) {
  const rnd = mulberry32(graine); const m = mots(t).map((w) => w.replace(/[.,;:!?…«»"()]/g, '')).filter(Boolean);
  for (let i = m.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [m[i], m[j]] = [m[j], m[i]]; }
  // Phrases de 8 a 12 mots : une seule phrase de 130 mots fait exploser la
  // memoire du modele VITS (attention quadratique -> OOM tue par le noyau,
  // reveil 2) et personne ne lit 130 mots sans reprendre son souffle.
  const phrases = []; let i = 0;
  while (i < m.length) { const n = 8 + Math.floor(rnd() * 5); phrases.push(m.slice(i, i + n).join(' ')); i += n; }
  return phrases.map((x) => x.charAt(0).toUpperCase() + x.slice(1) + '.').join(' ');
}

/** Texte à synthétiser + voix pour la base wav d'un cas ; null si source manquante. */
function baseDe(c) {
  const t = textes.get(c.textId);
  const modeleVoix = (lang, v) => path.join(VOICES_DIR, `${voix[lang][v]}.onnx`);
  switch (c.content) {
    case 'full': return { texte: t, voix: modeleVoix(c.lang, c.voice) };
    case 'p75': return { texte: part(t, 0.75), voix: modeleVoix(c.lang, c.voice) };
    case 'p60': return { texte: part(t, 0.60), voix: modeleVoix(c.lang, c.voice) };
    case 'p25sil': return { texte: part(t, 0.25), voix: modeleVoix(c.lang, c.voice), post: 'pad10' };
    case 'loop': return { texte: premierePhrase(t), voix: modeleVoix(c.lang, c.voice), post: 'loop30' };
    case 'shuffle': return { texte: melange(t, graineDe(c.textId)), voix: modeleVoix(c.lang, c.voice) };
    case 'xlang': { const x = xlang[c.textId]; return x && x.text ? { texte: x.text, voix: modeleVoix(x.lang, 'A') } : null; }
    case 'bgspeech': return { texte: textes.get(c.srcTextId), voix: modeleVoix(c.lang, 'B'), proc: 'bg' };
    case 'sum30': { const r = resumes[c.textId]; return r && r.sum30 ? { texte: r.sum30, voix: modeleVoix(c.lang, c.voice) } : null; }
    case 'sum8': { const r = resumes[c.textId]; return r && r.sum8 ? { texte: r.sum8, voix: modeleVoix(c.lang, c.voice) } : null; }
    default: return null;
  }
}

// ─── négatifs communs sans parole (silence, bruit, « musique ») ────────────
function sourceCommune(c) {
  const secondes = parseInt(c.proc.replace(/\D/g, ''), 10);
  if (c.content === 'silence') return `anullsrc=r=16000:cl=mono`;
  if (c.content === 'noise') { const couleur = c.proc.replace(/\d+s$/, ''); return `anoisesrc=c=${couleur}:a=0.05:r=16000:s=5`; }
  if (c.content === 'music') return `aevalsrc=0.25*sin(2*PI*220*t)*(0.6+0.4*sin(2*PI*0.5*t))+0.15*sin(2*PI*277*t)+0.15*sin(2*PI*330*t)*mod(floor(t*2)\\,2)+0.1*sin(2*PI*440*t)*mod(floor(t*4)\\,2):s=16000`;
  throw new Error(`contenu commun inconnu ${c.content}`);
}

// ─── exécution ─────────────────────────────────────────────────────────────
const workDir = path.join(ICI, 'work');
const travauxPiper = new Map(); // base wav → {voix, texte}
const finals = []; // {c, base, proc, out, post}
let sautes = 0;
for (const c of cas) {
  const out = path.join(ICI, cheminAudio(c));
  if (fs.existsSync(out)) continue;
  if (c.textId === '_') { finals.push({ c, out, commun: true }); continue; }
  const b = baseDe(c);
  if (!b) { sautes++; continue; }
  const cle = c.content === 'bgspeech' ? `${c.srcTextId}.B.full` : c.content === 'xlang' ? `${c.textId}.xlang.A` : `${c.textId}.${c.voice}.${c.content}`;
  const base = path.join(workDir, c.lang, `${cle}.wav`);
  if (!fs.existsSync(base)) travauxPiper.set(base, { voice: b.voix, text: b.texte, out: base });
  finals.push({ c, base, out, proc: b.proc || c.proc, post: b.post });
}
console.log(`cas sélectionnés ${cas.length} · à produire ${finals.length} · bases piper ${travauxPiper.size} · sautés (source absente) ${sautes}`);
if (DRY) process.exit(0);

// piper : un processus par voix, JOBS en parallèle
function lancerPiper(groupe) {
  return new Promise((resolve, reject) => {
    const p = spawn(PIPER_PY, [path.join(ICI, 'lib', 'synth_piper.py')], { stdio: ['pipe', 'pipe', 'pipe'], env: { ...process.env, OMP_NUM_THREADS: '2', ORT_NUM_THREADS: '2' } });
    let n = 0; let err = '';
    p.stdout.on('data', (d) => { n += String(d).split('\n').filter(Boolean).length; });
    p.stderr.on('data', (d) => { const s = String(d); if (!/INFO|WARNING/.test(s)) err += s; });
    p.on('close', (code) => (code === 0 ? resolve(n) : reject(new Error(`piper ${code}: ${err.slice(0, 500)}`))));
    p.stdin.end(groupe.map((j) => JSON.stringify(j)).join('\n') + '\n');
  });
}
async function pool(items, n, fn) {
  const file = items.slice(); let ok = 0; const erreurs = [];
  await Promise.all(Array.from({ length: Math.min(n, file.length) }, async () => {
    while (file.length) { const it = file.shift(); try { await fn(it); ok++; } catch (e) { erreurs.push(String(e.message || e).slice(0, 300)); } }
  }));
  return { ok, erreurs };
}
const parVoix = new Map();
for (const j of travauxPiper.values()) (parVoix.get(j.voice) || parVoix.set(j.voice, []).get(j.voice)).push(j);
const t0 = Date.now();
if (parVoix.size) {
  // découpe les gros groupes pour équilibrer les processus
  const groupes = [];
  for (const lst of parVoix.values()) for (let i = 0; i < lst.length; i += 20) groupes.push(lst.slice(i, i + 20));
  const r = await pool(groupes, JOBS, lancerPiper);
  console.log(`piper : ${travauxPiper.size} bases en ${((Date.now() - t0) / 1000).toFixed(0)} s · groupes ok ${r.ok}` + (r.erreurs.length ? ` · erreurs ${r.erreurs.length} : ${r.erreurs[0]}` : ''));
}

// post-traitements (pad / loop) puis dégradation + encodage
const sh = (cmd, a) => execFileSync(cmd, a, { stdio: ['ignore', 'pipe', 'pipe'] });
function ffmpeg(a) { sh('ffmpeg', ['-nostats', '-loglevel', 'error', '-y', ...a]); }
const t1 = Date.now();
const r2 = await pool(finals, JOBS, async (f) => {
  fs.mkdirSync(path.dirname(f.out), { recursive: true });
  if (f.commun) {
    const secondes = parseInt(f.c.proc.replace(/\D/g, ''), 10);
    const enc = f.c.format === 'webm' ? ['-c:a', 'libopus', '-b:a', '32k', '-ar', '16000', '-ac', '1'] : ['-c:a', 'aac', '-b:a', '32k', '-ar', '16000', '-ac', '1'];
    const tmp = `${f.out}.part.${f.c.format}`;
    ffmpeg(['-f', 'lavfi', '-i', sourceCommune(f.c), '-t', String(secondes), ...enc, tmp]);
    fs.renameSync(tmp, f.out);
    return;
  }
  if (!fs.existsSync(f.base)) throw new Error(`base absente ${path.basename(f.base)}`);
  let src = f.base;
  if (f.post === 'pad10') { src = f.base.replace(/\.wav$/, '.pad.wav'); if (!fs.existsSync(src)) ffmpeg(['-i', f.base, '-af', 'apad=pad_dur=10', src]); }
  if (f.post === 'loop30') { src = f.base.replace(/\.wav$/, '.loop.wav'); if (!fs.existsSync(src)) ffmpeg(['-stream_loop', '-1', '-i', f.base, '-t', '30', src]); }
  sh(path.join(ICI, 'degrade.sh'), [src, f.out, f.proc || 'clean']);
});
console.log(`ffmpeg : ${r2.ok} fichiers en ${((Date.now() - t1) / 1000).toFixed(0)} s` + (r2.erreurs.length ? ` · erreurs ${r2.erreurs.length} : ${r2.erreurs.slice(0, 3).join(' | ')}` : ''));

// index audio (comptes seulement)
const indexPath = path.join(manifests, 'audio_index.json');
const index = lireJson(indexPath);
let ajoutes = 0;
for (const c of cas) {
  const rel = cheminAudio(c); const abs = path.join(ICI, rel);
  if (index[rel] || !fs.existsSync(abs)) continue;
  const buf = fs.readFileSync(abs);
  const duration = parseFloat(String(sh('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', abs])).trim());
  index[rel] = { bytes: buf.length, duration_s: Math.round(duration * 100) / 100, sha256: crypto.createHash('sha256').update(buf).digest('hex') };
  ajoutes++;
}
fs.writeFileSync(indexPath, JSON.stringify(index, null, 1));
const total = Object.values(index).reduce((a, v) => a + v.duration_s, 0);
console.log(`index : +${ajoutes} → ${Object.keys(index).length} fichiers, ${(total / 60).toFixed(1)} min d'audio au total`);
