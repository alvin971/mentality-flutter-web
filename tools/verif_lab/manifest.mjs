#!/usr/bin/env node
/**
 * Construit les manifestes du banc « vérification vocale » (protocole §3).
 *
 *   node tools/verif_lab/manifest.mjs
 *
 * Écrit dans tools/verif_lab/manifests/ :
 *   texts.json   — 40 textes par langue tirés au sort (graine fixée), dont 6 en
 *                  holdout jamais regardés pendant la calibration ;
 *   voices.json  — les deux voix piper par langue (timbres différents) ;
 *   cases.jsonl  — un cas par ligne : audio à produire, référence à comparer,
 *                  verdict attendu, vague de priorité (budget §2).
 *
 * Aucun texte transcrit ici : seulement des identifiants du corpus public.
 * La normalisation vient de workers/_shared/text_norm.js (importée, jamais
 * copiée) — uniquement pour compter les mots de référence (`words_ref`).
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { motsDistincts } from '../../workers/_shared/text_norm.js';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const RACINE = path.resolve(ICI, '..', '..');
const CORPUS = path.join(RACINE, 'assets', 'reading_corpus');
const OUT = path.join(ICI, 'manifests');

/** Graine du tirage — consignée dans le JOURNAL (réveil 1). Ne jamais changer. */
export const GRAINE = 20260903;
export const LANGUES = ['fr', 'en', 'en_GB', 'es', 'pt', 'de'];
export const TEXTES_PAR_LANGUE = 40;
export const HOLDOUT_PAR_LANGUE = 6; // 15 %

/** Valeur exacte de X-Language envoyée par l'app (LocaleNotifier.contentTag) et
 * passée telle quelle au modèle par le worker : `en-GB` pour l'anglais britannique. */
export const LANG_PARAM = { fr: 'fr', en: 'en', en_GB: 'en-GB', es: 'es', pt: 'pt', de: 'de' };

/** Langue cible des « traductions lues » (négatif xlang) : chaque langue reçoit aussi. */
const XLANG_VERS = { fr: 'en', en: 'es', en_GB: 'fr', es: 'pt', pt: 'de', de: 'en_GB' };

/** Deux voix par langue, timbres différents (A = féminine quand disponible). */
export const VOIX = {
  fr: { A: 'fr_FR-siwis-medium', B: 'fr_FR-tom-medium' },
  en: { A: 'en_US-lessac-medium', B: 'en_US-ryan-medium' },
  en_GB: { A: 'en_GB-jenny_dioco-medium', B: 'en_GB-alan-medium' },
  es: { A: 'es_MX-claude-high', B: 'es_ES-davefx-medium' },
  pt: { A: 'pt_BR-faber-medium', B: 'pt_PT-tugão-medium' },
  de: { A: 'de_DE-kerstin-low', B: 'de_DE-thorsten-medium' },
};

// ─── PRNG déterministe (mulberry32) ────────────────────────────────────────
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
function melange(tableau, rnd) {
  const t = tableau.slice();
  for (let i = t.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [t[i], t[j]] = [t[j], t[i]];
  }
  return t;
}

// ─── Tirage des textes ─────────────────────────────────────────────────────
function lireCorpus(lang) {
  return fs.readFileSync(path.join(CORPUS, `${lang}.jsonl`), 'utf8')
    .trim().split('\n').map((l) => JSON.parse(l));
}

export function tirerTextes() {
  const textes = [];
  for (const lang of LANGUES) {
    const rnd = mulberry32(GRAINE + LANGUES.indexOf(lang));
    const tous = lireCorpus(lang).sort((a, b) => a.id.localeCompare(b.id));
    const tires = melange(tous, rnd).slice(0, TEXTES_PAR_LANGUE);
    tires.forEach((t, i) => {
      const holdout = i >= TEXTES_PAR_LANGUE - HOLDOUT_PAR_LANGUE;
      textes.push({
        lang, id: t.id, holdout,
        index: holdout ? i - (TEXTES_PAR_LANGUE - HOLDOUT_PAR_LANGUE) : i,
        words: t.text.trim().split(/\s+/).length,
        words_ref: motsDistincts(t.text).length,
        chars: t.text.length,
      });
    });
  }
  return textes;
}

// ─── Grille des cas ────────────────────────────────────────────────────────
/**
 * Un cas = { id, set, lang, textId, target, voice, content, proc, format,
 *            expected, wave, holdout, langParam, srcLang? }
 *   - textId  : texte dont l'audio est fabriqué (ou '_' pour silence/bruit) ;
 *   - target  : référence contre laquelle on compare (= textId pour un positif) ;
 *   - content : full | p75 | p60 | p25sil | loop | shuffle | xlang | bgspeech |
 *               silence | noise | music | sum30 | sum8 ;
 *   - proc    : clean | x0.8 | x1.3 | noise-20 | noise-10 | room-20 | gain-15 | gain+12 ;
 *   - format  : wav | webm | mp4 ;
 *   - wave    : ordre de transcription sous budget (1 = le plus discriminant).
 * Les négatifs « autre texte » (même langue / autre langue) ne portent pas
 * d'audio propre : ils réutilisent la transcription d'un positif `full`, et
 * score.mjs les dérive (content = other / other_xlang).
 */
export function construireCas(textes) {
  const cas = [];
  const ajouter = (c) => {
    const id = [c.set, c.lang, c.textId, c.voice || '-', c.content, c.proc, c.format, c.target].join(':');
    if (cas.some((x) => x.id === id)) return;
    cas.push({ id, langParam: LANG_PARAM[c.lang], ...c });
  };
  const parLangue = {};
  for (const t of textes) (parLangue[t.lang] ||= []).push(t);

  for (const lang of LANGUES) {
    const calib = parLangue[lang].filter((t) => !t.holdout);
    const hold = parLangue[lang].filter((t) => t.holdout);
    const n = calib.length;

    calib.forEach((t, i) => {
      const rot = i % 3;
      const vv = i % 2 === 0 ? 'A' : 'B'; // voix des variantes, alternée
      const base = { lang, textId: t.id, target: t.id, holdout: false };
      // Vague 1 — lecture intégrale, voix A, opus webm (format dominant).
      ajouter({ ...base, set: 'pos', voice: 'A', content: 'full', proc: 'clean', format: 'webm', expected: true, wave: 1 });
      // Vague 2 — négatifs qui exigent un audio propre (rotation 1/3).
      if (rot === 0) ajouter({ ...base, set: 'neg', voice: vv, content: 'shuffle', proc: 'clean', format: 'webm', expected: false, wave: 2 });
      if (rot === 1) ajouter({ ...base, set: 'neg', voice: vv, content: 'p25sil', proc: 'clean', format: 'webm', expected: false, wave: 2 });
      if (rot === 2) ajouter({ ...base, set: 'neg', voice: vv, content: 'loop', proc: 'clean', format: 'webm', expected: false, wave: 2 });
      if (i % 11 === 0) ajouter({ ...base, set: 'neg', voice: 'A', content: 'xlang', proc: 'clean', format: 'webm', expected: false, wave: 2, srcLang: XLANG_VERS[lang] });
      if (i % 11 === 1) ajouter({ ...base, set: 'neg', voice: 'B', content: 'bgspeech', proc: 'clean', format: 'webm', expected: false, wave: 2, srcTextId: calib[(i + 5) % n].id });
      // Résumés (6 textes par langue) — vague 2, légers.
      if (i % 6 === 2) {
        ajouter({ ...base, set: 'sum', voice: 'A', content: 'sum30', proc: 'clean', format: 'webm', expected: true, wave: 2 });
        ajouter({ ...base, set: 'sum', voice: 'A', content: 'sum8', proc: 'clean', format: 'webm', expected: false, wave: 2 });
        if (i % 12 === 2) ajouter({ ...base, set: 'sum', voice: 'B', content: 'sum30', proc: 'noise-20', format: 'webm', expected: true, wave: 2 });
        else ajouter({ ...base, set: 'sum', voice: 'B', content: 'sum30', proc: 'x1.3', format: 'mp4', expected: true, wave: 2 });
      }
      // Vague 3 — lecture intégrale, voix B, aac mp4.
      ajouter({ ...base, set: 'pos', voice: 'B', content: 'full', proc: 'clean', format: 'mp4', expected: true, wave: 3 });
      // Vague 4 — lectures partielles.
      if (rot !== 1) ajouter({ ...base, set: 'pos', voice: vv, content: 'p75', proc: 'clean', format: 'webm', expected: true, wave: 4 });
      if (rot === 0) ajouter({ ...base, set: 'pos', voice: vv, content: 'p75', proc: 'clean', format: 'mp4', expected: true, wave: 4 });
      if (rot === 1) ajouter({ ...base, set: 'pos', voice: vv, content: 'p60', proc: 'clean', format: 'webm', expected: true, wave: 4 });
      // Vague 5 — dégradations acoustiques (rotation 1/3, voix alternée).
      if (rot === 0) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'x0.8', format: 'webm', expected: true, wave: 5 });
      if (rot === 1) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'x1.3', format: 'webm', expected: true, wave: 5 });
      if (rot === 2) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'noise-20', format: 'webm', expected: true, wave: 5 });
      if (rot === 0) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'noise-10', format: 'webm', expected: true, wave: 5 });
      if (rot === 1) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'room-20', format: 'webm', expected: true, wave: 5 });
      if (rot === 2) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'gain-15', format: 'webm', expected: true, wave: 5 });
      if (rot === 0) ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: 'gain+12', format: 'webm', expected: true, wave: 5 });
      // Vague 6 — croisement voix × format ; vague 7 — wav (secours).
      if (rot === 1) ajouter({ ...base, set: 'pos', voice: 'A', content: 'full', proc: 'clean', format: 'mp4', expected: true, wave: 6 });
      if (rot === 2) ajouter({ ...base, set: 'pos', voice: 'B', content: 'full', proc: 'clean', format: 'webm', expected: true, wave: 6 });
      if (rot === 0) ajouter({ ...base, set: 'pos', voice: 'A', content: 'full', proc: 'clean', format: 'wav', expected: true, wave: 7 });
      if (rot === 1) ajouter({ ...base, set: 'pos', voice: 'B', content: 'full', proc: 'clean', format: 'wav', expected: true, wave: 7 });
    });

    // Holdout — vague 9, même grille resserrée, jamais regardé avant la fin.
    hold.forEach((t, i) => {
      const vv = i % 2 === 0 ? 'A' : 'B';
      const base = { lang, textId: t.id, target: t.id, holdout: true, wave: 9 };
      ajouter({ ...base, set: 'pos', voice: 'A', content: 'full', proc: 'clean', format: 'webm', expected: true });
      ajouter({ ...base, set: 'pos', voice: 'B', content: 'full', proc: 'clean', format: 'mp4', expected: true });
      ajouter({ ...base, set: 'pos', voice: vv, content: 'p75', proc: 'clean', format: 'webm', expected: true });
      ajouter({ ...base, set: 'pos', voice: vv, content: 'full', proc: i % 3 === 0 ? 'noise-10' : i % 3 === 1 ? 'x1.3' : 'gain-15', format: 'webm', expected: true });
      if (i % 2 === 0) ajouter({ ...base, set: 'neg', voice: vv, content: 'shuffle', proc: 'clean', format: 'webm', expected: false });
      else ajouter({ ...base, set: 'neg', voice: vv, content: 'p25sil', proc: 'clean', format: 'webm', expected: false });
      if (i === 0) ajouter({ ...base, set: 'sum', voice: 'A', content: 'sum30', proc: 'clean', format: 'webm', expected: true });
      if (i === 1) ajouter({ ...base, set: 'sum', voice: 'A', content: 'sum8', proc: 'clean', format: 'webm', expected: false });
    });
  }

  // Négatifs sans parole, communs à toutes les langues (cible = un texte fr,
  // n'importe lequel : la référence n'a aucune importance sans mots).
  const cible = textes.find((t) => t.lang === 'fr' && !t.holdout).id;
  for (const [content, variante] of [['silence', '5s'], ['silence', '30s'], ['silence', '60s'],
    ['noise', 'white30s'], ['noise', 'pink30s'], ['noise', 'brown60s'], ['music', '30s'], ['music', '60s']]) {
    for (const format of ['webm', 'mp4']) {
      ajouter({ set: 'neg', lang: 'fr', textId: '_', target: cible, voice: '-', content, proc: variante, format, expected: false, wave: 2, holdout: false });
    }
  }
  // Résumé = silence (protocole §3) : réutilise le silence 30 s.
  ajouter({ set: 'sum', lang: 'fr', textId: '_', target: '-', voice: '-', content: 'silence', proc: '30s', format: 'webm', expected: false, wave: 2, holdout: false });
  return cas;
}

// ─── Chemin de l'audio d'un cas (audio/<lang>/<textId>.<variante>.<ext>) ───
export function cheminAudio(c) {
  if (c.textId === '_') return path.join('audio', '_common', `${c.content}.${c.proc}.${c.format}`);
  const variante = [c.voice, c.content, c.proc].join('.');
  return path.join('audio', c.lang, `${c.textId}.${variante}.${c.format}`);
}

// ─── main ──────────────────────────────────────────────────────────────────
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  fs.mkdirSync(OUT, { recursive: true });
  const textes = tirerTextes();
  fs.writeFileSync(path.join(OUT, 'texts.json'), JSON.stringify({
    seed: GRAINE, per_lang: TEXTES_PAR_LANGUE, holdout_per_lang: HOLDOUT_PAR_LANGUE, texts: textes,
  }, null, 1));
  fs.writeFileSync(path.join(OUT, 'voices.json'), JSON.stringify(VOIX, null, 2));
  const cas = construireCas(textes);
  fs.writeFileSync(path.join(OUT, 'cases.jsonl'), cas.map((c) => JSON.stringify(c)).join('\n') + '\n');

  const compte = (f) => cas.filter(f).length;
  console.log(`textes : ${textes.length} (${LANGUES.length} langues × ${TEXTES_PAR_LANGUE}, holdout ${HOLDOUT_PAR_LANGUE}/langue), graine ${GRAINE}`);
  for (const lang of LANGUES) {
    const wr = textes.filter((t) => t.lang === lang).map((t) => t.words_ref).sort((a, b) => a - b);
    console.log(`  ${lang.padEnd(6)} words_ref min ${wr[0]} · méd ${wr[wr.length >> 1]} · max ${wr[wr.length - 1]}`);
  }
  console.log(`cas : ${cas.length} — pos ${compte((c) => c.set === 'pos')} · neg ${compte((c) => c.set === 'neg')} · sum ${compte((c) => c.set === 'sum')} · holdout ${compte((c) => c.holdout)}`);
  for (let w = 1; w <= 9; w++) {
    const k = compte((c) => c.wave === w);
    if (k) console.log(`  vague ${w} : ${k} cas`);
  }
  const contenus = {};
  for (const c of cas) contenus[`${c.set}/${c.content}/${c.proc}`] = (contenus[`${c.set}/${c.content}/${c.proc}`] || 0) + 1;
  console.log(Object.entries(contenus).sort().map(([k, v]) => `${k}=${v}`).join('  '));
}
