#!/usr/bin/env node
/**
 * Recouvrement, courbes seuil → (faux négatifs, faux positifs) et check-list §6,
 * à partir du cache de transcribe.mjs (des comptes, jamais un mot).
 *
 *   node tools/verif_lab/score.mjs --model @cf/openai/whisper [--language app|none]
 *        [--holdout] [--seuil 0.30] [--min-summary 15] [--quiet]
 *
 * Par défaut : cas HORS holdout (calibration). --holdout : SEULEMENT le holdout
 * (à ne lancer qu'après convergence, protocole §6). Écrit
 * results/<slug>.<policy>[.holdout].json et imprime le résumé pour le JOURNAL.
 *
 * Négatifs DÉRIVÉS (sans audio propre, gratuits) à partir de chaque lecture
 * intégrale propre en cache : « autre texte de la même langue » (3 cibles en
 * rotation + le maximum sur toutes les paires, pour la marge) et « autre texte
 * d'une autre langue » (1 cible).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cheminAudio, LANGUES } from './manifest.mjs';
import { reference, recouvrementDepuisHits, distinctsAuMoins, couvertureDernierTiers, scoreOrdre } from './lib/tokens.mjs';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const RACINE = path.resolve(ICI, '..', '..');
const CORPUS = path.join(RACINE, 'assets', 'reading_corpus');
const SLUGS = { '@cf/openai/whisper': 'whisper', '@cf/openai/whisper-large-v3-turbo': 'whisper-large-v3-turbo', '@cf/openai/whisper-tiny-en': 'whisper-tiny-en', '@cf/deepgram/nova-3': 'nova-3' };
const PRIX_MIN = { '@cf/openai/whisper': 0.000453, '@cf/openai/whisper-large-v3-turbo': 0.000513, '@cf/openai/whisper-tiny-en': 0.000453, '@cf/deepgram/nova-3': 0.0052 };
const NEURONES_GRATUITS_USD = 10000 * 0.011 / 1000; // 10 000 neurones/jour × 0,011 $/1 000

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const has = (k) => args.includes(k);
const MODEL = opt('--model', '@cf/openai/whisper');
const POLICY = opt('--language', 'app');
const HOLDOUT = has('--holdout');
const SEUIL_PROD = parseFloat(opt('--seuil', '0.30'));
const MIN_SUM = parseInt(opt('--min-summary', '15'), 10);
/** Règle d'ordre (réveil 3) : 0 = désactivée, sinon score d'ordre minimal exigé
 *  en plus du seuil de recouvrement. `scoreOrdre` vient de _shared/text_norm.js. */
const MIN_ORDRE = parseFloat(opt('--min-ordre', '0'));
const QUIET = has('--quiet');
const slug = SLUGS[MODEL];

// ─── données ───────────────────────────────────────────────────────────────
const manifests = path.join(ICI, 'manifests');
const index = JSON.parse(fs.readFileSync(path.join(manifests, 'audio_index.json'), 'utf8'));
const textsJson = JSON.parse(fs.readFileSync(path.join(manifests, 'texts.json'), 'utf8'));
const texts = textsJson.texts;
const corpus = new Map();
for (const lang of LANGUES) for (const l of fs.readFileSync(path.join(CORPUS, `${lang}.jsonl`), 'utf8').trim().split('\n')) { const o = JSON.parse(l); corpus.set(o.id, o.text); }
const refs = new Map(texts.map((t) => [t.id, reference(corpus.get(t.id))]));
const texteInfo = new Map(texts.map((t) => [t.id, t]));
const calib = {}; for (const t of texts) if (!t.holdout) (calib[t.lang] ||= []).push(t);
for (const l of LANGUES) calib[l].sort((a, b) => a.index - b.index);
const cas = fs.readFileSync(path.join(manifests, 'cases.jsonl'), 'utf8').trim().split('\n').map(JSON.parse).filter((c) => c.holdout === HOLDOUT);

const cacheDir = path.join(ICI, 'cache', slug, POLICY);
const cache = new Map();
if (fs.existsSync(cacheDir)) for (const f of fs.readdirSync(cacheDir)) {
  const e = JSON.parse(fs.readFileSync(path.join(cacheDir, f), 'utf8'));
  cache.set(`${e.audio_sha}|${e.language_param}`, e);
}
const entreeDe = (c) => { const m = index[cheminAudio(c)]; return m ? cache.get(`${m.sha256}|${POLICY === 'app' ? c.langParam : ''}`) : undefined; };

// ─── mesures par cas ───────────────────────────────────────────────────────
const mesures = []; // {id, set, lang, textId, target, content, proc, format, expected, overlap, words, ordre, couverture, status, ms, duration_s, derived}
let nonCouverts = 0;
const mesure = (c, e, target, derived = null) => {
  const m = { id: derived ? `${c.id}→${target}` : c.id, set: derived ? 'neg' : c.set, lang: c.lang, textId: c.textId, target, content: derived || c.content, proc: c.proc, format: c.format, expected: derived ? false : c.expected, status: e.status, ms: e.ms, duration_s: e.duration_s, derived: !!derived, lang_detected: e.lang_detected, fallback: e.fallback };
  if (e.status === 'ok') {
    if (c.set === 'sum') m.words = distinctsAuMoins(e.histo);
    else {
      const ref = refs.get(target); const hits = (e.hits || {})[target] || [];
      const r = recouvrementDepuisHits(hits, ref);
      m.overlap = r.overlap; m.hit = r.hit; m.ref = r.ref; m.words = distinctsAuMoins(e.histo);
      m.ordre = scoreOrdre(hits, ref); m.couverture = couvertureDernierTiers(hits, ref);
      if (!derived) { // meilleur « autre texte » de la même langue (marge) et de toutes les langues
        let max = 0, maxId = null;
        for (const t of texts) if (t.id !== target && t.holdout === HOLDOUT) { const rr = recouvrementDepuisHits((e.hits || {})[t.id] || [], refs.get(t.id)); if (rr.overlap > max) { max = rr.overlap; maxId = t.id; } }
        m.other_max = max; m.other_max_id = maxId;
      }
    }
  }
  return m;
};
for (const c of cas) {
  const e = entreeDe(c);
  if (!e) { nonCouverts++; continue; }
  mesures.push(mesure(c, e, c.target));
  if (c.set === 'pos' && c.content === 'full' && c.proc === 'clean' && e.status === 'ok') {
    const liste = HOLDOUT ? texts.filter((t) => t.lang === c.lang && t.holdout) : calib[c.lang];
    const i = liste.findIndex((t) => t.id === c.textId); const n = liste.length;
    for (const d of [1, 7, 13]) { const t = liste[(i + d) % n]; if (t.id !== c.textId) mesures.push(mesure(c, e, t.id, 'other')); }
    const L2 = LANGUES[(LANGUES.indexOf(c.lang) + 1) % LANGUES.length];
    const liste2 = HOLDOUT ? texts.filter((t) => t.lang === L2 && t.holdout) : calib[L2];
    mesures.push(mesure(c, e, liste2[i % liste2.length].id, 'other_xlang'));
  }
}

// ─── verdicts et taux ──────────────────────────────────────────────────────
const okA = (m, s) => (m.set === 'sum' ? m.words >= MIN_SUM : m.overlap >= s && m.ordre >= MIN_ORDRE);
const taux = (liste, s, sens) => { // sens : 'ok' → part de verdicts ok ; 'rejet' → part de verdicts ok:false
  const l = liste.filter((m) => m.status === 'ok'); if (!l.length) return null;
  const k = l.filter((m) => okA(m, s) === (sens === 'ok')).length; return Math.round((k / l.length) * 10000) / 100;
};
const groupes = {
  integrales_et_75: (m) => m.set === 'pos' && (m.content === 'full' || m.content === 'p75'),
  integrales_propres: (m) => m.set === 'pos' && m.content === 'full' && m.proc === 'clean',
  integrales_degradees: (m) => m.set === 'pos' && m.content === 'full' && m.proc !== 'clean',
  p75: (m) => m.content === 'p75', p60: (m) => m.content === 'p60',
  negatifs: (m) => m.set === 'neg', silence: (m) => m.content === 'silence' && m.set === 'neg', bruit: (m) => m.content === 'noise', musique: (m) => m.content === 'music',
  autre_texte: (m) => m.content === 'other', autre_texte_autre_langue: (m) => m.content === 'other_xlang', traduction: (m) => m.content === 'xlang',
  p25_puis_silence: (m) => m.content === 'p25sil', phrase_en_boucle: (m) => m.content === 'loop', mots_melanges: (m) => m.content === 'shuffle', parole_de_fond: (m) => m.content === 'bgspeech',
  resume_30: (m) => m.content === 'sum30', resume_8: (m) => m.content === 'sum8', resume_silence: (m) => m.set === 'sum' && m.content === 'silence',
};
const sensDe = (g) => (['negatifs', 'silence', 'bruit', 'musique', 'autre_texte', 'autre_texte_autre_langue', 'traduction', 'p25_puis_silence', 'phrase_en_boucle', 'mots_melanges', 'parole_de_fond', 'resume_8', 'resume_silence'].includes(g) ? 'rejet' : 'ok');

const seuils = Array.from({ length: 19 }, (_, i) => Math.round((0.05 + i * 0.05) * 100) / 100);
const courbe = seuils.map((s) => {
  const ligne = { seuil: s };
  for (const [g, f] of Object.entries(groupes)) ligne[g] = taux(mesures.filter(f), s, sensDe(g));
  ligne.par_langue = Object.fromEntries(LANGUES.map((l) => [l, { pos: taux(mesures.filter((m) => groupes.integrales_et_75(m) && m.lang === l), s, 'ok'), neg: taux(mesures.filter((m) => m.set === 'neg' && m.lang === l), s, 'rejet') }]));
  ligne.par_format = Object.fromEntries(['webm', 'mp4', 'wav'].map((f) => [f, { pos: taux(mesures.filter((m) => groupes.integrales_et_75(m) && m.format === f), s, 'ok'), neg: taux(mesures.filter((m) => m.set === 'neg' && m.format === f), s, 'rejet') }]));
  ligne.par_variante = {};
  for (const m of mesures) if (m.set === 'pos') { const k = `${m.content}/${m.proc}`; ligne.par_variante[k] ??= taux(mesures.filter((x) => x.set === 'pos' && `${x.content}/${x.proc}` === k), s, 'ok'); }
  return ligne;
});

// ─── check-list §6 à un seuil ──────────────────────────────────────────────
const minOf = (l, k) => (l.length ? Math.min(...l.map((m) => m[k])) : null);
const maxOf = (l, k) => (l.length ? Math.max(...l.map((m) => m[k])) : null);
function checklist(s) {
  const L = courbe.find((x) => Math.abs(x.seuil - s) < 1e-9) || (() => { const ligne = { seuil: s }; for (const [g, f] of Object.entries(groupes)) ligne[g] = taux(mesures.filter(f), s, sensDe(g)); ligne.par_langue = Object.fromEntries(LANGUES.map((l) => [l, { pos: taux(mesures.filter((m) => groupes.integrales_et_75(m) && m.lang === l), s, 'ok'), neg: taux(mesures.filter((m) => m.set === 'neg' && m.lang === l), s, 'rejet') }])); ligne.par_format = Object.fromEntries(['webm', 'mp4', 'wav'].map((f) => [f, { pos: taux(mesures.filter((m) => groupes.integrales_et_75(m) && m.format === f), s, 'ok'), neg: taux(mesures.filter((m) => m.set === 'neg' && m.format === f), s, 'rejet') }])); return ligne; })();
  const positifsIntegraux = mesures.filter((m) => m.set === 'pos' && m.content === 'full' && m.status === 'ok');
  const positifsPropres = positifsIntegraux.filter((m) => m.proc === 'clean');
  const autres = mesures.filter((m) => m.content === 'other' && m.status === 'ok');
  const pireProp = minOf(positifsPropres, 'overlap'), pireInteg = minOf(positifsIntegraux, 'overlap');
  const meilleurAutre = maxOf(mesures.filter((m) => !m.derived && m.set === 'pos' && m.status === 'ok' && m.other_max != null), 'other_max');
  const c = {
    seuil: s,
    integrales_et_75: { global: L.integrales_et_75, ok: L.integrales_et_75 != null && L.integrales_et_75 >= 98, par_langue_min: Math.min(...LANGUES.map((l) => L.par_langue[l].pos ?? 100)), par_format_min: Math.min(...['webm', 'mp4'].map((f) => L.par_format[f].pos ?? 100)) },
    p60: { global: L.p60, ok: L.p60 == null || L.p60 >= 90 },
    negatifs: { global: L.negatifs, ok: L.negatifs != null && L.negatifs >= 98, silence: L.silence, bruit: L.bruit, autre_texte: L.autre_texte, cent_pour_cent: [L.silence, L.bruit, L.autre_texte].every((v) => v == null || v === 100) },
    resumes: { resume_30: L.resume_30, resume_8: L.resume_8, resume_silence: L.resume_silence },
    marge: { pire_positif_integral_propre: pireProp, pire_positif_integral_tous: pireInteg, meilleur_autre_texte: meilleurAutre, marge_propre: pireProp != null && meilleurAutre != null ? Math.round((pireProp - meilleurAutre) * 10000) / 10000 : null, ok: pireProp != null && meilleurAutre != null && pireProp - meilleurAutre >= 0.10 },
  };
  c.integrales_et_75.ok = c.integrales_et_75.ok && c.integrales_et_75.par_langue_min >= 96 && c.integrales_et_75.par_format_min >= 96;
  c.negatifs.ok = c.negatifs.ok && c.negatifs.cent_pour_cent;
  const r30 = L.resume_30, r8 = L.resume_8, rs = L.resume_silence;
  c.resumes.ok = [r30, r8, rs].every((v) => v == null || v >= 95);
  c.tout_ok = c.integrales_et_75.ok && c.p60.ok && c.negatifs.ok && c.resumes.ok && c.marge.ok;
  return c;
}
// seuil retenu : le plus bas qui tient les négatifs (§6), sinon le meilleur compromis
let retenu = null;
for (const s of seuils) { const c = checklist(s); if (c.negatifs.ok) { retenu = s; break; } }
const compromis = seuils.map((s) => { const c = checklist(s); return { s, score: (c.negatifs.global ?? 0) + (c.integrales_et_75.global ?? 0) }; }).sort((a, b) => b.score - a.score)[0];
const seuilChoisi = retenu ?? compromis.s;

// ─── coût, latence, signaux d'ordre ────────────────────────────────────────
const ok = mesures.filter((m) => !m.derived && m.status === 'ok');
const dureeMoy = (f) => { const l = mesures.filter((m) => !m.derived && f(m)); return l.length ? l.reduce((a, m) => a + m.duration_s, 0) / l.length : null; };
const dFull = dureeMoy((m) => m.content === 'full' && m.proc === 'clean'), dSum = dureeMoy((m) => m.content === 'sum30');
const minParBilan = dFull != null ? (3 * dFull + (dSum ?? 20)) / 60 : null;
const cout = minParBilan != null ? { minutes_par_bilan: Math.round(minParBilan * 100) / 100, cents_par_bilan: Math.round(minParBilan * PRIX_MIN[MODEL] * 100 * 1000) / 1000, bilans_par_jour_gratuits: Math.floor(NEURONES_GRATUITS_USD / (minParBilan * PRIX_MIN[MODEL])) } : null;
const msParMin = ok.filter((m) => m.duration_s > 5).map((m) => m.ms / (m.duration_s / 60)).sort((a, b) => a - b);
const latence = msParMin.length ? { fichiers: ok.length, ms_par_minute_audio_med: Math.round(msParMin[msParMin.length >> 1]), ms_par_minute_audio_p95: Math.round(msParMin[Math.floor(msParMin.length * 0.95)]), ms_max_par_fichier: Math.max(...ok.map((m) => m.ms)), sous_60_s: ok.every((m) => m.ms < 60000) } : null;
const quantiles = (l, k) => { const v = l.map((m) => m[k]).filter((x) => x != null).sort((a, b) => a - b); return v.length ? { n: v.length, min: v[0], p10: v[Math.floor(v.length * 0.1)], med: v[v.length >> 1], p90: v[Math.floor(v.length * 0.9)], max: v[v.length - 1] } : null; };
const signaux = {};
for (const g of ['integrales_propres', 'integrales_degradees', 'p75', 'p60', 'mots_melanges', 'p25_puis_silence', 'phrase_en_boucle', 'autre_texte', 'traduction', 'parole_de_fond']) {
  const l = mesures.filter((m) => groupes[g](m) && m.status === 'ok');
  signaux[g] = { overlap: quantiles(l, 'overlap'), ordre: quantiles(l, 'ordre'), couverture_dernier_tiers: quantiles(l, 'couverture') };
}
/**
 * Distribution COMPLÈTE des imposteurs, calculée sur le cache — donc gratuite.
 *
 * Le taux de rejet des négatifs « autre texte » est mesuré sur un échantillon
 * équilibré (3 cibles en rotation par lecture), pour ne pas noyer les négatifs
 * à audio réel sous des milliers de paires dérivées. Mais la MARGE du §6 se
 * joue sur le pire cas, et un maximum estimé sur 3 tirages est fragile : on
 * calcule donc ici TOUTES les paires (chaque lecture intégrale propre contre
 * tous les autres textes de sa langue, puis contre ceux des autres langues).
 */
function distributionImposteurs() {
  const memeLangue = [];
  const autreLangue = [];
  let pireMeme = { overlap: -1 };
  for (const c of cas) {
    if (!(c.set === 'pos' && c.content === 'full' && c.proc === 'clean')) continue;
    const e = entreeDe(c);
    if (!e || e.status !== 'ok') continue;
    for (const t of texts) {
      if (t.id === c.target || t.holdout !== HOLDOUT) continue;
      const hits = (e.hits || {})[t.id] || [];
      const r = recouvrementDepuisHits(hits, refs.get(t.id));
      const ordre = scoreOrdre(hits, refs.get(t.id));
      const entree = { overlap: r.overlap, ordre, lu: c.textId, contre: t.id };
      if (t.lang === c.lang) {
        memeLangue.push(entree);
        if (r.overlap > pireMeme.overlap) pireMeme = entree;
      } else autreLangue.push(entree);
    }
  }
  const stats = (liste) => {
    if (!liste.length) return null;
    const v = liste.map((x) => x.overlap).sort((a, b) => a - b);
    const q = (p) => v[Math.min(v.length - 1, Math.floor(v.length * p))];
    return { paires: v.length, med: q(0.5), p95: q(0.95), p99: q(0.99), p999: q(0.999), max: v[v.length - 1] };
  };
  return {
    meme_langue: stats(memeLangue),
    autre_langue: stats(autreLangue),
    // Le pire imposteur, avec son score d'ordre : si la règle d'ordre le
    // rejetait, la marge du seuil compterait moins.
    pire_meme_langue: pireMeme.overlap >= 0 ? pireMeme : null,
    // Combien de paires franchiraient un seuil donné, AVEC et SANS la règle d'ordre.
    au_dessus: Object.fromEntries([0.2, 0.25, 0.3, 0.35, 0.4].map((s) => [s, {
      seuil_seul: memeLangue.filter((x) => x.overlap >= s).length,
      avec_ordre: memeLangue.filter((x) => x.overlap >= s && x.ordre >= (MIN_ORDRE || 0)).length,
    }])),
  };
}
const imposteurs = distributionImposteurs();

const erreurs = mesures.filter((m) => !m.derived && m.status !== 'ok');
const resistent = mesures.filter((m) => m.status === 'ok' && okA(m, seuilChoisi) !== m.expected).map((m) => ({ id: m.id, target: m.target, content: m.content, overlap: m.overlap, words: m.words, ordre: m.ordre, couverture: m.couverture })).slice(0, 60);
const langDetect = {};
for (const m of ok) if (m.lang_detected) { const k = `${m.lang}→${m.lang_detected}`; langDetect[k] = (langDetect[k] || 0) + 1; }

const sortie = {
  model: MODEL, policy: POLICY, holdout: HOLDOUT, day: new Date().toISOString().slice(0, 10), seuil_prod: SEUIL_PROD, min_summary: MIN_SUM, min_ordre: MIN_ORDRE,
  couverture: { cas: cas.length, mesures_directes: mesures.filter((m) => !m.derived).length, derives: mesures.filter((m) => m.derived).length, non_couverts: nonCouverts, erreurs_modele: erreurs.length, fallback_sans_language: ok.filter((m) => m.fallback).length },
  seuil_retenu: seuilChoisi, seuil_tient_negatifs: retenu != null, checklist_retenu: checklist(seuilChoisi), checklist_prod: checklist(SEUIL_PROD),
  courbe, cout, latence, signaux, imposteurs, lang_detected: langDetect, resistent, erreurs: erreurs.map((m) => ({ id: m.id, status: m.status })).slice(0, 40),
};
fs.mkdirSync(path.join(ICI, 'results'), { recursive: true });
const outPath = path.join(ICI, 'results', `${slug}.${POLICY}${HOLDOUT ? '.holdout' : ''}.json`);
fs.writeFileSync(outPath, JSON.stringify(sortie, null, 1));

// ─── résumé lisible (JOURNAL) ──────────────────────────────────────────────
if (!QUIET) {
  const f = (v) => (v == null ? '  —  ' : `${v.toFixed(1).padStart(5)}`);
  console.log(`# ${MODEL} · language=${POLICY}${MIN_ORDRE ? ` · ordre ≥ ${MIN_ORDRE}` : ' · sans règle d\'ordre'}${HOLDOUT ? ' · HOLDOUT' : ''} · cas ${cas.length} · mesurés ${sortie.couverture.mesures_directes} (+${sortie.couverture.derives} dérivés) · non couverts ${nonCouverts} · erreurs modèle ${erreurs.length}`);
  console.log(`seuil | intég+75 | int.propre | int.dégr. |  p75  |  p60  | négatifs | silence | bruit | autre | trad. | p25sil | boucle | mélangé | fond`);
  for (const l of courbe) if (l.seuil >= 0.1 && l.seuil <= 0.7) console.log(`${l.seuil.toFixed(2)}  |${f(l.integrales_et_75)}   |${f(l.integrales_propres)}     |${f(l.integrales_degradees)}    |${f(l.p75)}|${f(l.p60)}|${f(l.negatifs)}   |${f(l.silence)}  |${f(l.bruit)}|${f(l.autre_texte)}|${f(l.traduction)}|${f(l.p25_puis_silence)} |${f(l.phrase_en_boucle)} |${f(l.mots_melanges)}  |${f(l.parole_de_fond)}`);
  const c = sortie.checklist_retenu;
  console.log(`\nseuil retenu ${seuilChoisi}${retenu == null ? ' (compromis : aucun seuil ne tient les négatifs)' : ''} · §6 : intég+75 ${c.integrales_et_75.global} % (langue min ${c.integrales_et_75.par_langue_min}, format min ${c.integrales_et_75.par_format_min}) ${c.integrales_et_75.ok ? '✓' : '✗'} · p60 ${c.p60.global} ${c.p60.ok ? '✓' : '✗'} · négatifs ${c.negatifs.global} % ${c.negatifs.ok ? '✓' : '✗'} · résumés ${c.resumes.resume_30}/${c.resumes.resume_8}/${c.resumes.resume_silence} ${c.resumes.ok ? '✓' : '✗'} · marge ${c.marge.marge_propre} (pire propre ${c.marge.pire_positif_integral_propre}, pire tous ${c.marge.pire_positif_integral_tous}, meilleur autre ${c.marge.meilleur_autre_texte}) ${c.marge.ok ? '✓' : '✗'} → ${c.tout_ok ? 'TOUT OK' : 'pas encore'}`);
  const l = courbe.find((x) => Math.abs(x.seuil - seuilChoisi) < 1e-9);
  if (l) { console.log('par langue (pos/neg) : ' + LANGUES.map((k) => `${k} ${l.par_langue[k].pos ?? '—'}/${l.par_langue[k].neg ?? '—'}`).join(' · ')); console.log('par format (pos/neg) : ' + ['webm', 'mp4', 'wav'].map((k) => `${k} ${l.par_format[k].pos ?? '—'}/${l.par_format[k].neg ?? '—'}`).join(' · ')); console.log('par variante : ' + Object.entries(l.par_variante).map(([k, v]) => `${k} ${v}`).join(' · ')); }
  if (cout) console.log(`coût : ${cout.minutes_par_bilan} min/bilan → ${cout.cents_par_bilan} ¢/bilan · ${cout.bilans_par_jour_gratuits} bilans/jour dans l'allocation gratuite`);
  if (latence) console.log(`latence : ${latence.ms_par_minute_audio_med} ms/min (p95 ${latence.ms_par_minute_audio_p95}) · max ${latence.ms_max_par_fichier} ms/fichier · < 60 s : ${latence.sous_60_s}`);
  if (imposteurs.meme_langue) {
    const i = imposteurs.meme_langue;
    console.log(`imposteurs (toutes paires) : même langue n=${i.paires} méd ${i.med} · p99 ${i.p99} · max ${i.max}` +
      (imposteurs.autre_langue ? ` | autre langue n=${imposteurs.autre_langue.paires} max ${imposteurs.autre_langue.max}` : '') +
      (imposteurs.pire_meme_langue ? ` | pire : ${imposteurs.pire_meme_langue.lu} lu contre ${imposteurs.pire_meme_langue.contre} (ordre ${imposteurs.pire_meme_langue.ordre})` : ''));
    console.log('paires au-dessus du seuil : ' + Object.entries(imposteurs.au_dessus).map(([k, v]) => `${k}→${v.seuil_seul}${MIN_ORDRE ? `/${v.avec_ordre}` : ''}`).join(' · '));
  }
  console.log('signaux (overlap med | ordre med | couverture dernier tiers med) : ' + Object.entries(signaux).filter(([, v]) => v.overlap).map(([k, v]) => `${k} ${v.overlap.med}|${v.ordre.med}|${v.couverture_dernier_tiers.med}`).join(' · '));
  if (Object.keys(langDetect).length) console.log('langue détectée : ' + Object.entries(langDetect).map(([k, v]) => `${k}=${v}`).join(' '));
  if (resistent.length) console.log(`résistent au seuil ${seuilChoisi} (${resistent.length}) : ` + resistent.slice(0, 12).map((r) => `${r.id} ov=${r.overlap ?? r.words}`).join(' ; '));
  console.log(`→ ${path.relative(RACINE, outPath)}`);
}
