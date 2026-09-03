/**
 * Normalisation de texte PARTAGÉE entre la publication de la référence du
 * corpus (workers/r2-upload/scripts/publish-corpus.mjs) et la vérification des
 * enregistrements vocaux (workers/r2-upload/index.js).
 *
 * POURQUOI UN MODULE À PART. La vérification calcule un recouvrement entre les
 * mots d'une transcription et les mots du texte que la personne devait lire.
 * Ce recouvrement n'a de sens que si les DEUX côtés découpent et normalisent
 * exactement de la même façon : la référence publiée dans R2 et la
 * transcription reçue de Workers AI doivent passer par la MÊME fonction. Toute
 * divergence (accent conservé d'un côté, apostrophe traitée autrement de
 * l'autre) ferait chuter le recouvrement sans qu'aucun enregistrement n'ait
 * changé. D'où une seule définition, importée des deux côtés.
 *
 * Règles (dans cet ordre) :
 *   1. minuscules ;
 *   2. accents et diacritiques retirés (NFD puis suppression des marques
 *      combinantes) ; ligatures et lettres sans décomposition Unicode
 *      rabattues à la main (œ → oe, æ → ae, ß → ss) ;
 *   3. tout ce qui n'est ni lettre ni chiffre devient un séparateur (ponctuation,
 *      apostrophes, tirets, guillemets, espaces) : « l'école » → « l », « ecole » ;
 *   4. seuls les mots de LONGUEUR_MIN_MOT caractères ou plus sont gardés — les
 *      mots courts (le, la, de, une, et…) sont trop fréquents pour signifier
 *      quoi que ce soit sur la lecture d'un texte précis.
 */

/** Longueur minimale d'un mot retenu, en caractères après normalisation. */
export const LONGUEUR_MIN_MOT = 4;

/**
 * Ramène [texte] à une chaîne en minuscules sans accent. Ne découpe pas.
 * Toute valeur non textuelle donne une chaîne vide.
 */
export function normaliseTexte(texte) {
  if (typeof texte !== 'string') return '';
  return texte
    .toLowerCase()
    .replace(/œ/g, 'oe')
    .replace(/æ/g, 'ae')
    .replace(/ß/g, 'ss')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

/**
 * Mots normalisés de [texte], DANS L'ORDRE et AVEC répétitions, de longueur
 * ≥ LONGUEUR_MIN_MOT. Un séparateur est tout caractère qui n'est ni une
 * lettre ni un chiffre (au sens Unicode).
 */
export function motsNormalises(texte) {
  return normaliseTexte(texte)
    .split(/[^\p{L}\p{N}]+/u)
    .filter((mot) => mot.length >= LONGUEUR_MIN_MOT);
}

/**
 * Mots DISTINCTS normalisés de [texte], dans l'ordre de première apparition.
 * C'est la forme publiée dans la référence `corpus/<textId>.json` et celle
 * comparée à la transcription.
 */
export function motsDistincts(texte) {
  return [...new Set(motsNormalises(texte))];
}

/**
 * Recouvrement d'une [transcription] par rapport à une [reference] (deux
 * listes de mots déjà normalisés, typiquement issues de `motsDistincts`).
 *
 * Renvoie { overlap, hit, ref, transcribed } :
 *   - ref         : nombre de mots distincts de la référence ;
 *   - transcribed : nombre de mots distincts de la transcription ;
 *   - hit         : nombre de mots de la référence retrouvés dans la
 *                   transcription ;
 *   - overlap     : hit / ref, arrondi à 4 décimales (0 si la référence est
 *                   vide : rien à retrouver, rien de retrouvé).
 */
export function recouvrement(reference, transcription) {
  const ref = new Set(Array.isArray(reference) ? reference : []);
  const trans = new Set(Array.isArray(transcription) ? transcription : []);
  let hit = 0;
  for (const mot of ref) if (trans.has(mot)) hit++;
  const overlap = ref.size === 0 ? 0 : Math.round((hit / ref.size) * 10000) / 10000;
  return { overlap, hit, ref: ref.size, transcribed: trans.size };
}
