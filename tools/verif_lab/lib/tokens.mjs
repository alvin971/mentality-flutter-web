/**
 * Jetons et recouvrement pour le banc — construit SUR workers/_shared/text_norm.js
 * (importé, jamais recopié) pour que le banc mesure exactement la production.
 *
 * Doctrine : aucune transcription n'est écrite sur disque. Le cache ne garde,
 * pour chaque référence publique du corpus, que la SUITE DES INDICES des mots
 * de cette référence retrouvés dans la transcription (dans l'ordre de la
 * transcription, répétitions comprises) et des histogrammes de longueurs. Ces
 * entiers suffisent à recalculer le recouvrement de production et à mesurer
 * des règles d'ordre ou de couverture, sans qu'un mot transcrit ne subsiste.
 *
 * Les indices pointent dans la liste des jetons DISTINCTS de longueur ≥ 1 de
 * la référence (même découpe que `motsNormalises`, sans le filtre de longueur)
 * pour rester valables si LONGUEUR_MIN_MOT changeait ; le filtre de production
 * (≥ LONGUEUR_MIN_MOT) est appliqué au moment du calcul.
 */
import crypto from 'node:crypto';
import { normaliseTexte, motsDistincts, recouvrement, scoreOrdre as scoreOrdrePartage, LONGUEUR_MIN_MOT } from '../../../workers/_shared/text_norm.js';

export { LONGUEUR_MIN_MOT };

/** Jetons normalisés de longueur ≥ 1, dans l'ordre, avec répétitions. */
export function jetons(texte) {
  return normaliseTexte(texte).split(/[^\p{L}\p{N}]+/u).filter((w) => w.length >= 1);
}

/** Référence d'un texte : jetons distincts (≥ 1) + index jeton → position. */
export function reference(texte) {
  const distincts = [...new Set(jetons(texte))];
  const index = new Map(distincts.map((w, i) => [w, i]));
  return { tokens: distincts, index, lens: distincts.map((w) => w.length) };
}

/** Suite des indices de [ref] rencontrés dans les jetons d'une transcription. */
export function suiteHits(jetonsTranscription, ref) {
  const out = [];
  for (const w of jetonsTranscription) { const i = ref.index.get(w); if (i !== undefined) out.push(i); }
  return out;
}

/** Histogrammes de longueurs des jetons transcrits (totaux et distincts). */
export function histogrammes(jetonsTranscription) {
  const total = {}; const distinct = {}; const vus = new Set();
  for (const w of jetonsTranscription) {
    const k = Math.min(w.length, 12);
    total[k] = (total[k] || 0) + 1;
    if (!vus.has(w)) { vus.add(w); distinct[k] = (distinct[k] || 0) + 1; }
  }
  return { total, distinct, n_total: jetonsTranscription.length, n_distinct: vus.size };
}

/** Nombre de mots distincts transcrits de longueur ≥ [minLen] (= `words_transcribed`). */
export function distinctsAuMoins(histo, minLen = LONGUEUR_MIN_MOT) {
  return Object.entries(histo.distinct).reduce((a, [k, v]) => a + (Number(k) >= minLen ? v : 0), 0);
}

/**
 * Recouvrement de production recalculé depuis une suite d'indices :
 * identique à `recouvrement(motsDistincts(ref), motsDistincts(transcription))`.
 */
export function recouvrementDepuisHits(hits, ref, minLen = LONGUEUR_MIN_MOT) {
  const refN = ref.lens.filter((l) => l >= minLen).length;
  const distinctsHits = new Set(hits.filter((i) => ref.lens[i] >= minLen));
  const hit = distinctsHits.size;
  const overlap = refN === 0 ? 0 : Math.round((hit / refN) * 10000) / 10000;
  return { overlap, hit, ref: refN };
}

/** Part des mots (≥ minLen) du DERNIER TIERS de la référence retrouvés — signal de couverture (§4.6). */
export function couvertureDernierTiers(hits, ref, minLen = LONGUEUR_MIN_MOT) {
  const idx = ref.lens.map((l, i) => (l >= minLen ? i : -1)).filter((i) => i >= 0);
  const dernier = idx.slice(Math.floor((idx.length * 2) / 3));
  if (!dernier.length) return 0;
  const vus = new Set(hits);
  return Math.round((dernier.filter((i) => vus.has(i)).length / dernier.length) * 10000) / 10000;
}

/**
 * Score d'ordre d'un cas — délègue à `scoreOrdre` de `workers/_shared/text_norm.js`
 * (la règle de production, jamais une copie). Les indices du cache sont
 * retraduits en la suite de mots que le worker verrait : les mots de la
 * référence, dans l'ordre de la transcription. Les mots hors référence et ceux
 * de moins de [minLen] caractères ne peuvent pas matcher : les omettre donne
 * exactement le même score.
 */
export function scoreOrdre(hits, ref, minLen = LONGUEUR_MIN_MOT) {
  const reference = ref.tokens.filter((_, i) => ref.lens[i] >= minLen);
  const transcription = hits.filter((i) => ref.lens[i] >= minLen).map((i) => ref.tokens[i]);
  return scoreOrdrePartage(reference, transcription).ordre;
}

/** Signature comportementale de la normalisation partagée (change ⇒ cache à retranscrire). */
export function signatureNormalisation() {
  const sonde = "L'école : œuvre, Æther, Straße — naïve ! 42 mots… ¿Qué? Ça va ; e-mail, don't, l'homme";
  return crypto.createHash('sha256').update(JSON.stringify([LONGUEUR_MIN_MOT, jetons(sonde), motsDistincts(sonde)])).digest('hex').slice(0, 16);
}

/** Auto-test : le recalcul depuis les indices coïncide avec la production. */
export function autoTest() {
  const textes = ["Les abeilles ne se contentent pas de produire du miel : elles rendent un service essentiel à la nature.",
    "Comets are sometimes called dirty snowballs, and the nickname fits them surprisingly well.",
    "Die Fotosynthese ist ein lebenswichtiger Prozess, der in den Blättern der Pflanzen stattfindet."];
  const trans = ["les abeilles produisent du miel et rendent service à la nature nature nature", "comets are dirty snowballs the nickname fits", "die fotosynthese ist ein prozess in den blattern", ""];
  for (const t of textes) for (const x of trans) {
    const attendu = recouvrement(motsDistincts(t), motsDistincts(x));
    const ref = reference(t); const hits = suiteHits(jetons(x), ref);
    const obtenu = recouvrementDepuisHits(hits, ref);
    if (attendu.overlap !== obtenu.overlap || attendu.hit !== obtenu.hit || attendu.ref !== obtenu.ref) throw new Error(`divergence : ${JSON.stringify(attendu)} vs ${JSON.stringify(obtenu)}`);
    if (attendu.transcribed !== distinctsAuMoins(histogrammes(jetons(x)))) throw new Error('divergence words_transcribed');
    const ordreAttendu = scoreOrdrePartage(motsDistincts(t), jetons(x)).ordre;
    if (ordreAttendu !== scoreOrdre(hits, ref)) throw new Error(`divergence ordre : ${ordreAttendu} vs ${scoreOrdre(hits, ref)}`);
  }
  return true;
}
