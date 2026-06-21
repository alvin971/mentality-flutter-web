import 'dart:math';

/// Tirage stratifié réutilisable par tous les sous-tests à banque d'items.
///
/// Pour chaque bande de difficulté, mélange la banque correspondante avec [rng]
/// puis prélève le nombre de slots requis ; les bandes sont concaténées dans
/// leur ordre (difficulté croissante). Deux passations avec des [rng]
/// différents ne tirent pas le même test ; un même seed est reproductible.
///
/// - [banksByBand] : une liste d'items par bande (banques disjointes,
///   sur-dimensionnées par rapport au nombre de slots).
/// - [slotsPerBand] : nombre d'items à tirer dans chaque bande.
///
/// L'attribution du `thetaValue` par SLOT (position dans le test) reste à la
/// charge de l'appelant : c'est ce qui garantit une échelle de difficulté
/// identique d'une passation à l'autre (le tirage ne change que QUELS items
/// occupent chaque slot, pas la difficulté du slot).
List<T> stratifiedDraw<T>(
  List<List<T>> banksByBand,
  List<int> slotsPerBand,
  Random rng,
) {
  assert(
    banksByBand.length == slotsPerBand.length,
    'banksByBand (${banksByBand.length}) et slotsPerBand '
    '(${slotsPerBand.length}) doivent avoir la même longueur',
  );
  final result = <T>[];
  for (var band = 0; band < banksByBand.length; band++) {
    final slots = slotsPerBand[band];
    final pool = List<T>.of(banksByBand[band])..shuffle(rng);
    assert(
      pool.length >= slots,
      'Banque #$band trop petite : ${pool.length} items pour $slots slots',
    );
    result.addAll(pool.take(slots));
  }
  return result;
}

/// Theta du slot [slotIndex] sur une échelle linéaire commençant à [start]
/// avec un pas [step] (par défaut : -2.0 + 0.2 × index, comme la WAIS).
/// [decimals] : précision d'arrondi (1 pour un pas de 0.2, 2 pour 0.15…).
double thetaForSlot(int slotIndex,
    {double start = -2.0, double step = 0.2, int decimals = 1}) {
  return double.parse((start + step * slotIndex).toStringAsFixed(decimals));
}
