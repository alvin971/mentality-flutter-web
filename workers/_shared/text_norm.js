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

/**
 * Score d'ORDRE d'une transcription par rapport à une référence — la part des
 * mots retrouvés qui apparaissent dans le MÊME ORDRE que dans le texte à lire.
 *
 * POURQUOI. Le recouvrement est un sac de mots : il ne distingue pas une
 * lecture du texte d'une récitation de ses mots dans le désordre. Mesuré au
 * banc (`tools/verif_lab`, réveil 3, 24 cas par langue) : les mots du texte
 * énoncés dans un ordre aléatoire obtiennent un recouvrement médian de 0,84 —
 * au-dessus de tout seuil praticable — et ne sont donc JAMAIS rejetés par le
 * seuil seul. Leur score d'ordre, lui, plafonne à 0,25 quand celui d'une
 * lecture réelle ne descend pas sous 0,98.
 *
 * COMMENT. On garde, pour chaque mot de la référence retrouvé, le rang de sa
 * PREMIÈRE apparition dans la transcription, puis on cherche la plus longue
 * sous-suite strictement croissante de ces rangs (LIS, en n log n). Le score
 * est sa longueur divisée par le nombre de mots retrouvés : 1 = tout le texte
 * lu dans l'ordre, 0,2 = ordre aléatoire. Les répétitions et les mots hors
 * référence sont ignorés ; une lecture qui saute un passage ou se répète garde
 * donc un score élevé.
 *
 * [reference] : mots normalisés DISTINCTS du texte à lire, DANS L'ORDRE du
 * texte — c'est exactement ce que produit `motsDistincts` et ce que contient
 * déjà `corpus/<textId>.json` (`words`). Aucune republication n'est requise.
 * [transcription] : mots normalisés de la transcription, DANS L'ORDRE, avec
 * répétitions — c'est-à-dire `motsNormalises`, et non `motsDistincts`.
 *
 * Renvoie { ordre, suite } :
 *   - suite : nombre de mots de la référence retrouvés (premières apparitions) ;
 *   - ordre : score dans [0, 1], arrondi à 4 décimales. **Moins de deux mots
 *     retrouvés → 1** : l'ordre n'est pas jugeable, c'est au recouvrement (qui
 *     est alors quasi nul) de trancher. Cette règle ne doit jamais transformer
 *     une absence de preuve en preuve d'ordre.
 */
export function scoreOrdre(reference, transcription) {
  const rang = new Map();
  if (Array.isArray(reference)) {
    for (let i = 0; i < reference.length; i++) if (!rang.has(reference[i])) rang.set(reference[i], i);
  }
  const vus = new Set();
  const suite = [];
  if (Array.isArray(transcription)) {
    for (const mot of transcription) {
      const r = rang.get(mot);
      if (r !== undefined && !vus.has(r)) { vus.add(r); suite.push(r); }
    }
  }
  if (suite.length < 2) return { ordre: 1, suite: suite.length };
  // Plus longue sous-suite strictement croissante (patience sorting).
  const queues = [];
  for (const x of suite) {
    let lo = 0, hi = queues.length;
    while (lo < hi) { const m = (lo + hi) >> 1; if (queues[m] < x) lo = m + 1; else hi = m; }
    queues[lo] = x;
  }
  return { ordre: Math.round((queues.length / suite.length) * 10000) / 10000, suite: suite.length };
}
