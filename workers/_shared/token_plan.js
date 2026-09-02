/**
 * Lecture du PLAN porté par un token vérifié (claims sv ≥ 3).
 *
 * POURQUOI CE MODULE. Depuis le schéma 3, le passe transporte lui-même le plan
 * choisi sur le site (`p`), le consentement au corpus vocal (`cc`) et la version
 * des textes légaux acceptés (`cv`). Ces trois claims sont dans les octets
 * signés : elles font autorité, contrairement aux en-têtes envoyés par le
 * client, qui sont déclaratifs et forgeables. Chaque worker qui décide du sort
 * d'un enregistrement vocal doit lire ICI, et nulle part ailleurs.
 *
 * CONTRAT. `readPlan(claims)` ne prend QUE des claims déjà vérifiées par
 * `verifyToken()` (`v.claims`). Il ne vérifie aucune signature et n'en a pas la
 * charge ; lui passer un payload non vérifié serait une faille.
 *
 * Renvoie { sv, plan, corpusConsent, legalVersion } :
 *   - sv            : version de schéma lue (0 si illisible)
 *   - plan          : 'free' | 'paid' | null (null = pas de plan porté → repli
 *                     historique : écran de consentement in-app)
 *   - corpusConsent : booléen — TOUJOURS false hors du plan 'free'
 *   - legalVersion  : chaîne non vide, ou null
 *
 * DEUX RÈGLES DURES, volontairement redondantes avec `token_verify.js` :
 *   1. sv < 3 ⇒ plan null. Un ancien passe ne consent à rien par défaut.
 *   2. plan 'paid' ⇒ corpusConsent false quoi que dise `cc`. Le passe Payant est
 *      l'alternative SANS enregistrement : c'est ce qui rend libre le
 *      consentement du plan Gratuit (RGPD art. 7(4)). Un 'paid' avec `cc: true`
 *      est une incohérence — le tokeniser la refuse à l'émission ; si elle
 *      arrivait ici malgré tout, elle ne doit jamais valoir autorisation.
 */

// Première version de schéma qui porte les claims de plan.
const SCHEMA_VERSION_PLAN = 3;

// Plans admis pour la claim `p`.
const TOKEN_PLANS = new Set(['free', 'paid']);

/** Résultat neutre : aucun plan porté, aucun consentement, aucune version. */
function aucunPlan(sv) {
  return { sv, plan: null, corpusConsent: false, legalVersion: null };
}

/**
 * Lit le plan d'un jeu de claims VÉRIFIÉES.
 * @param {object|null|undefined} claims — `v.claims` de `verifyToken()`.
 */
export function readPlan(claims) {
  if (!claims || typeof claims !== 'object' || Array.isArray(claims)) {
    return aucunPlan(0);
  }

  const sv = Number.isInteger(claims.sv) ? claims.sv : 0;
  if (sv < SCHEMA_VERSION_PLAN) return aucunPlan(sv);

  // Forme strictement identique à celle exigée par `verifyToken()` : un claims
  // hors forme retombe sur le repli historique plutôt que sur une supposition.
  if (!TOKEN_PLANS.has(claims.p)) return aucunPlan(sv);

  const plan = claims.p;
  const legalVersion =
    typeof claims.cv === 'string' && claims.cv.length > 0 ? claims.cv : null;
  // `cc` non booléen ⇒ pas de consentement ; 'paid' ⇒ jamais de consentement.
  const corpusConsent = plan === 'free' && claims.cc === true;

  return { sv, plan, corpusConsent, legalVersion };
}
