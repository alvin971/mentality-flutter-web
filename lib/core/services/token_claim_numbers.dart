// lib/core/services/token_claim_numbers.dart
//
// Lecture des claims NUMÉRIQUES d'un token, avec exactement la tolérance des
// workers.
//
// POURQUOI CE FICHIER EXISTE. JavaScript n'a qu'un seul type de nombre : `3`
// et `3.0` y sont la même valeur, et `Number.isInteger(3.0)` répond `true`.
// Les workers (`workers/_shared/token_verify.js`, `token_plan.js`) acceptent
// donc sans broncher un passe dont le `sv` a été sérialisé « 3.0 ». Dart, lui,
// distingue les deux : `jsonDecode('{"sv":3.0}')` rend un `double`, qu'un test
// `sv is! int` REJETTE. Le même passe serait alors « sv 3 » pour le worker et
// « schéma inconnu » pour l'application — refusé à l'écran sans qu'aucune des
// deux moitiés soit en tort, et sans le moindre message exploitable.
//
// La règle retenue est donc celle du bord JS : est un entier tout nombre dont
// la VALEUR est entière. Ce qui reste refusé l'est volontairement — un décimal
// véritable (3.5), un NaN, un infini, une chaîne « 3 » : on n'accepte que ce
// que l'autre bord accepte déjà, on ne devine rien de plus.

/// La valeur entière d'un claim numérique, ou `null` si ce n'en est pas un.
///
/// Accepte `3` comme `3.0` (miroir de `Number.isInteger`), refuse `3.5`, les
/// non-nombres, NaN et les infinis.
int? claimEntier(Object? valeur) {
  if (valeur is int) return valeur;
  if (valeur is double) {
    // `isFinite` d'abord : `double.infinity.truncateToDouble()` vaut l'infini,
    // qui se comparerait égal à lui-même et passerait la garde suivante.
    if (!valeur.isFinite || valeur != valeur.truncateToDouble()) return null;
    return valeur.toInt();
  }
  return null;
}
