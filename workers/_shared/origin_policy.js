/**
 * Politique d'Origin EXPLICITE des workers Mentality — point unique de décision.
 *
 * Trois cas, et trois seulement :
 *   - Origin présent et listé      → accepté (navigateur légitime).
 *   - Origin présent et NON listé  → refusé, 403 (site tiers).
 *   - Origin ABSENT                → accepté. ASSUMÉ : c'est le SEUL chemin de
 *     l'app mobile native, qui n'envoie aucun en-tête Origin. Un curl passe
 *     donc cet étage — ce n'est PAS un contrôle d'accès (CORS ≠ contrôle
 *     d'accès, cf. README du tokeniser). La compensation est le contrôle qui
 *     vient DERRIÈRE : token X-Mentality-Token (referral), signature Ed25519
 *     re-vérifiée (r2-upload/event), plafond d'émission agrégé (tokeniser).
 *
 * DETTE LOT 1 (anti-faux-test) : la fermeture réelle du chemin curl n'arrive
 * qu'avec les badges signés obligatoires (fin du repli `M2.` non signé). Ce
 * module est LE point de bascule prévu — ne pas re-durcir ailleurs.
 */

/**
 * Évalue l'Origin d'une requête contre une allow-list (égalité STRICTE,
 * jamais startsWith). Renvoie { allowed, origin, headerless } ; l'appelant
 * répond 403 quand `allowed` est faux.
 */
export function checkOrigin(request, allowedOrigins) {
  const origin = request.headers.get('Origin') || '';
  if (origin === '') return { allowed: true, origin, headerless: true };
  return { allowed: allowedOrigins.includes(origin), origin, headerless: false };
}
