import '../../../../core/l10n/l10n_ext.dart';
import '../../data/normative_tables.dart';
import '../../data/composite_score_tables.dart';
import '../entities/iq_score.dart';
import '../../../../core/models/complete_test_session.dart';

/// Service de scoring psychométrique complet
///
/// Pipeline : score brut → note standardisée → indice composite → FSIQ
/// Avec intervalles de confiance à 95% et percentiles
///
/// Barème maison, aligné sur les usages psychométriques
class ScoringService {
  const ScoringService();

  /// Calcule un [IQScore] complet à partir d'une [CompleteTestSession] et de l'âge
  ///
  /// [session] : session contenant les scores bruts de tous les sous-tests
  /// [ageInMonths] : âge du patient en mois (pour les tables normatives)
  ///
  /// Retourne null si les sous-tests primaires essentiels sont incomplets
  IQScore? computeScore(CompleteTestSession session, int ageInMonths) {
    // ─── Étape 1 : Conversion brut → notes standardisées ──────────────────
    final bd = _scaled('BD', session.cubesScore, ageInMonths);
    final si = _scaled('SI', session.similaritiesScore, ageInMonths);
    final ds = _scaled('DS', session.digitSpanScore, ageInMonths);
    final mr = _scaled('MR', session.matricesScore, ageInMonths);
    final vo = _scaled('VO', session.vocabularyScore, ageInMonths);
    final ar = _scaled('AR', session.arithmeticScore, ageInMonths);
    final ss = _scaled('SS', session.symbolSearchScore, ageInMonths);
    final vp = _scaled('VP', session.visualPuzzlesScore, ageInMonths);
    final in_ = _scaled('IN', session.informationScore, ageInMonths);
    final cd = _scaled('CD', session.codingScore, ageInMonths);
    final pm = _scaled('PM', session.pictureSpanScore, ageInMonths);
    final fw = _scaled('FW', session.figureWeightsScore, ageInMonths);

    // Vérification que les 10 sous-tests primaires sont disponibles
    final primaryScores = [bd, si, ds, mr, vo, ar, ss, vp, in_, cd];
    if (primaryScores.any((s) => s == null)) return null;

    // ─── Étape 2 : Calcul des indices composites ──────────────────────────
    // VCI : Similitudes + Vocabulaire + Information
    final vciSum = si! + vo! + in_!;
    final vciScore = CompositeScoreTables.computeCompositeScore('VCI', vciSum);

    // VSI : Cubes + Puzzles Visuels
    final vsiSum = bd! + vp!;
    final vsiScore = CompositeScoreTables.computeCompositeScore('VSI', vsiSum);

    // FRI : Matrices + Balances (Balances optionnel → fallback Matrices × 2 approximatif)
    final int friSum;
    if (fw != null) {
      friSum = mr! + fw;
    } else {
      // Estimation si Balances absent : on centre sur MR seulement
      friSum = mr! + 10; // 10 = note standardisée moyenne
    }
    final friScore = CompositeScoreTables.computeCompositeScore('FRI', friSum);

    // WMI : Mémoire des Chiffres + Arithmétique + Mémoire des Images (PM)
    // PM est optionnel → si absent, contribution moyenne (note standard 10)
    final wmiSum = ds! + ar! + (pm ?? 10);
    final wmiScore = CompositeScoreTables.computeCompositeScore('WMI', wmiSum);

    // PSI : Code + Recherche de Symboles
    final psiSum = cd! + ss!;
    final psiScore = CompositeScoreTables.computeCompositeScore('PSI', psiSum);

    // ─── Étape 3 : Calcul du FSIQ ─────────────────────────────────────────
    // Basé sur les 10 sous-tests primaires
    final sumOf10 = bd + si + ds + mr + vo + ar + ss + vp + in_ + cd;
    final fsiqScore = CompositeScoreTables.computeCompositeScore('FSIQ', sumOf10);

    // ─── Étape 4 : Percentiles ────────────────────────────────────────────
    final percentiles = <String, int>{
      'FSIQ': CompositeScoreTables.getPercentile(fsiqScore),
      'VCI': CompositeScoreTables.getPercentile(vciScore),
      'VSI': CompositeScoreTables.getPercentile(vsiScore),
      'FRI': CompositeScoreTables.getPercentile(friScore),
      'WMI': CompositeScoreTables.getPercentile(wmiScore),
      'PSI': CompositeScoreTables.getPercentile(psiScore),
    };

    // ─── Étape 5 : Intervalles de confiance à 95% ─────────────────────────
    final confidenceIntervals = <String, ConfidenceInterval>{};
    for (final entry in {
      'FSIQ': fsiqScore,
      'VCI': vciScore,
      'VSI': vsiScore,
      'FRI': friScore,
      'WMI': wmiScore,
      'PSI': psiScore,
    }.entries) {
      final (lower, upper) =
          CompositeScoreTables.getConfidenceInterval(entry.key, entry.value);
      confidenceIntervals[entry.key] = ConfidenceInterval(
        lowerBound: lower,
        upperBound: upper,
      );
    }

    // ─── Étape 6 : Classifications ────────────────────────────────────────
    final classifications = <String, String>{
      'FSIQ': CompositeScoreTables.classify(fsiqScore),
      'VCI': CompositeScoreTables.classify(vciScore),
      'VSI': CompositeScoreTables.classify(vsiScore),
      'FRI': CompositeScoreTables.classify(friScore),
      'WMI': CompositeScoreTables.classify(wmiScore),
      'PSI': CompositeScoreTables.classify(psiScore),
    };

    // ─── Étape 7 : Notes standardisées individuelles ──────────────────────
    // Stockées dans des champs additionnels via les classifications de sous-tests
    classifications['BD'] = _classifyScaled(bd);
    classifications['SI'] = _classifyScaled(si);
    classifications['DS'] = _classifyScaled(ds);
    classifications['MR'] = _classifyScaled(mr);
    classifications['VO'] = _classifyScaled(vo);
    classifications['AR'] = _classifyScaled(ar);
    classifications['SS'] = _classifyScaled(ss);
    classifications['VP'] = _classifyScaled(vp);
    classifications['IN'] = _classifyScaled(in_);
    classifications['CD'] = _classifyScaled(cd);
    if (pm != null) classifications['PM'] = _classifyScaled(pm);
    if (fw != null) classifications['FW'] = _classifyScaled(fw);

    // Scores standardisés dans percentiles (réutilise la map pour stocker)
    percentiles['BD'] = bd;
    percentiles['SI'] = si;
    percentiles['DS'] = ds;
    percentiles['MR'] = mr;
    percentiles['VO'] = vo;
    percentiles['AR'] = ar;
    percentiles['SS'] = ss;
    percentiles['VP'] = vp;
    percentiles['IN'] = in_;
    percentiles['CD'] = cd;
    if (pm != null) percentiles['PM'] = pm;
    if (fw != null) percentiles['FW'] = fw;

    return IQScore(
      fsiq: fsiqScore,
      vci: vciScore,
      vsi: vsiScore,
      fri: friScore,
      wmi: wmiScore,
      psi: psiScore,
      confidenceIntervals: confidenceIntervals,
      percentiles: percentiles,
      classifications: classifications,
      ageInMonths: ageInMonths,
      assessmentDate: session.startTime,
      assessmentId: session.startTime.millisecondsSinceEpoch.toString(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MÉTHODES PRIVÉES
  // ─────────────────────────────────────────────────────────────────────────

  /// Convertit un score brut nullable en note standardisée nullable
  int? _scaled(String code, int? rawScore, int ageInMonths) {
    if (rawScore == null) return null;
    return NormativeTables.toScaledScore(code, rawScore, ageInMonths);
  }

  /// Classification d'une note standardisée (1-19)
  String _classifyScaled(int? scaledScore) {
    if (scaledScore == null) return appL10n.scoringNotAvailable;
    if (scaledScore >= 16) return appL10n.scoringClassificationVerySuperior;
    if (scaledScore >= 13) return appL10n.scoringClassificationSuperior;
    if (scaledScore >= 11) return appL10n.scoringClassificationHighAverage;
    if (scaledScore >= 8) return appL10n.scoringClassificationAverage;
    if (scaledScore >= 6) return appL10n.scoringClassificationLowAverage;
    if (scaledScore >= 4) return appL10n.scoringClassificationBorderline;
    return appL10n.scoringClassificationExtremelyLow;
  }
}
