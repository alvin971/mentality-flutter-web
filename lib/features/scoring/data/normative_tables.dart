import 'scoring_params.dart';

/// Conversion d'un score brut en note standardisée (1-19), **relative à l'âge**.
///
/// Principe : on ne compare jamais un brut dans l'absolu, mais à la moyenne
/// attendue **pour l'âge de la personne**. Toute la calibration vit dans
/// [ScoringParams] (éditable par des psychologues) :
///
///   note = clamp( round( 10 + 3·(brut − µ_âge) / σ_âge ), 1, 19 )
///
/// où `µ_âge = muRef · ageFactor(domaine, âge)` et `σ_âge = sigmaRef`.
/// Moyenne 10, écart-type 3 garantis par construction.
class NormativeTables {
  NormativeTables._();

  /// (Compat) Clé de groupe d'âge — conservée pour d'éventuels usages hérités.
  /// Le moteur de notation n'en dépend plus (la courbe d'âge est continue).
  static String getAgeGroupKey(int ageInMonths) {
    if (ageInMonths < 300) return 'A'; // 16-24 ans
    if (ageInMonths < 540) return 'B'; // 25-44 ans
    if (ageInMonths < 780) return 'C'; // 45-64 ans
    return 'D'; // 65+ ans
  }

  /// Convertit un score brut en note standardisée (1-19) pour un sous-test donné,
  /// en comparant le brut à la distribution attendue à l'âge fourni.
  ///
  /// [subtestCode] : BD, SI, DS, MR, VO, AR, SS, VP, IN, CD, PM, FW.
  /// [rawScore] : brut obtenu (borné à [rawMin, rawMax] du sous-test).
  /// [ageInMonths] : âge pour la comparaison normative relative à l'âge.
  ///
  /// Retourne 10 (note moyenne) si le sous-test est inconnu.
  static int toScaledScore(String subtestCode, int rawScore, int ageInMonths) {
    final norm = ScoringParams.subtests[subtestCode];
    if (norm == null) return 10; // fallback : sous-test inconnu → note moyenne

    final raw = rawScore.clamp(norm.rawMin, norm.rawMax).toDouble();
    final mu = norm.muRef * ScoringParams.ageFactor(norm.domain, ageInMonths);
    final sigma = norm.sigmaRef <= 0 ? 1.0 : norm.sigmaRef;

    final scaled = (10 + 3 * (raw - mu) / sigma).round();
    return scaled.clamp(1, 19);
  }
}
