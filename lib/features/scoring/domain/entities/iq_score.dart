import 'package:equatable/equatable.dart';

import '../../../../core/l10n/l10n_ext.dart';

/// Entité représentant un score de QI complet avec tous les indices
///
/// Cette classe encapsule le QI Total et les 5 indices primaires,
/// avec leurs intervalles de confiance et classifications
class IQScore extends Equatable {
  /// QI Total (Full Scale IQ)
  final int fsiq;

  /// Indice de Compréhension Verbale
  final int? vci;

  /// Indice Visuo-Spatial
  final int? vsi;

  /// Indice de Raisonnement Fluide
  final int? fri;

  /// Indice de Mémoire de Travail
  final int? wmi;

  /// Indice de Vitesse de Traitement
  final int? psi;

  /// Indice d'Aptitude Générale (optionnel)
  final int? gai;

  /// Indice Non-Verbal (optionnel)
  final int? nvi;

  /// Indice de Compétence Cognitive (optionnel)
  final int? cci;

  /// Intervalles de confiance à 95% pour chaque score
  final Map<String, ConfidenceInterval> confidenceIntervals;

  /// Percentiles correspondants
  final Map<String, int> percentiles;

  /// Classifications descriptives
  final Map<String, String> classifications;

  /// Âge de l'utilisateur au moment de l'évaluation (en mois)
  final int ageInMonths;

  /// Date de l'évaluation
  final DateTime assessmentDate;

  /// ID de la session d'évaluation
  final String assessmentId;

  const IQScore({
    required this.fsiq,
    this.vci,
    this.vsi,
    this.fri,
    this.wmi,
    this.psi,
    this.gai,
    this.nvi,
    this.cci,
    required this.confidenceIntervals,
    required this.percentiles,
    required this.classifications,
    required this.ageInMonths,
    required this.assessmentDate,
    required this.assessmentId,
  });

  /// Récupère l'intervalle de confiance du QI Total
  ConfidenceInterval get fsiqCI => confidenceIntervals['FSIQ']!;

  /// Récupère le percentile du QI Total
  int get fsiqPercentile => percentiles['FSIQ']!;

  /// Récupère la classification du QI Total
  String get fsiqClassification => classifications['FSIQ']!;

  /// Vérifie si le profil est homogène (écarts < 1 écart-type)
  bool get isHomogeneousProfile {
    final scores = [vci, vsi, fri, wmi, psi].whereType<int>().toList();
    if (scores.length < 2) return true;

    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final maxDeviation = scores.map((s) => (s - mean).abs()).reduce(
          (a, b) => a > b ? a : b,
        );

    return maxDeviation < 15; // 1 écart-type
  }

  /// Identifie les forces (indices > QI Total + 10)
  List<String> get strengths {
    final strengths = <String>[];
    if (vci != null && vci! > fsiq + 10) strengths.add('VCI');
    if (vsi != null && vsi! > fsiq + 10) strengths.add('VSI');
    if (fri != null && fri! > fsiq + 10) strengths.add('FRI');
    if (wmi != null && wmi! > fsiq + 10) strengths.add('WMI');
    if (psi != null && psi! > fsiq + 10) strengths.add('PSI');
    return strengths;
  }

  /// Identifie les faiblesses (indices < QI Total - 10)
  List<String> get weaknesses {
    final weaknesses = <String>[];
    if (vci != null && vci! < fsiq - 10) weaknesses.add('VCI');
    if (vsi != null && vsi! < fsiq - 10) weaknesses.add('VSI');
    if (fri != null && fri! < fsiq - 10) weaknesses.add('FRI');
    if (wmi != null && wmi! < fsiq - 10) weaknesses.add('WMI');
    if (psi != null && psi! < fsiq - 10) weaknesses.add('PSI');
    return weaknesses;
  }

  /// Calcule l'écart maximal entre indices
  int get maxIndexDiscrepancy {
    final scores = [vci, vsi, fri, wmi, psi].whereType<int>().toList();
    if (scores.isEmpty) return 0;

    final max = scores.reduce((a, b) => a > b ? a : b);
    final min = scores.reduce((a, b) => a < b ? a : b);

    return max - min;
  }

  /// Vérifie si l'écart entre indices est statistiquement significatif
  bool isDiscrepancySignificant(String index1, String index2) {
    final score1 = _getIndexScore(index1);
    final score2 = _getIndexScore(index2);

    if (score1 == null || score2 == null) return false;

    // Différence de 15+ points (1 écart-type) est considérée significative
    return (score1 - score2).abs() >= 15;
  }

  /// Récupère un score d'indice par son code
  int? _getIndexScore(String indexCode) {
    switch (indexCode) {
      case 'VCI':
        return vci;
      case 'VSI':
        return vsi;
      case 'FRI':
        return fri;
      case 'WMI':
        return wmi;
      case 'PSI':
        return psi;
      case 'GAI':
        return gai;
      case 'NVI':
        return nvi;
      case 'CCI':
        return cci;
      default:
        return null;
    }
  }

  /// Génère un résumé textuel du profil
  String generateProfileSummary() {
    final l10n = appL10n;
    final buffer = StringBuffer();

    buffer.writeln(l10n.scoringSummaryFullScaleIq(fsiq, fsiqClassification));
    buffer.writeln(l10n.scoringSummaryPercentile(fsiqPercentile));
    buffer.writeln(l10n.scoringSummaryConfidenceInterval(
        fsiqCI.lowerBound, fsiqCI.upperBound));

    if (vci != null) {
      buffer.writeln('${l10n.scoringIndexVerbalComprehension}: $vci');
    }
    if (vsi != null) {
      buffer.writeln('${l10n.scoringIndexVisualSpatial}: $vsi');
    }
    if (fri != null) {
      buffer.writeln('${l10n.scoringIndexFluidReasoning}: $fri');
    }
    if (wmi != null) {
      buffer.writeln('${l10n.scoringIndexWorkingMemory}: $wmi');
    }
    if (psi != null) {
      buffer.writeln('${l10n.scoringIndexProcessingSpeed}: $psi');
    }

    if (strengths.isNotEmpty) {
      buffer.writeln(
          '\n${l10n.scoringSummaryRelativeStrengths(strengths.join(', '))}');
    }

    if (weaknesses.isNotEmpty) {
      buffer.writeln(
          l10n.scoringSummaryRelativeWeaknesses(weaknesses.join(', ')));
    }

    if (isHomogeneousProfile) {
      buffer.writeln('\n${l10n.scoringSummaryHomogeneousProfile}');
    } else {
      buffer.writeln(
          '\n${l10n.scoringSummaryHeterogeneousProfile(maxIndexDiscrepancy)}');
    }

    return buffer.toString();
  }

  /// Copie avec modifications
  IQScore copyWith({
    int? fsiq,
    int? vci,
    int? vsi,
    int? fri,
    int? wmi,
    int? psi,
    int? gai,
    int? nvi,
    int? cci,
    Map<String, ConfidenceInterval>? confidenceIntervals,
    Map<String, int>? percentiles,
    Map<String, String>? classifications,
    int? ageInMonths,
    DateTime? assessmentDate,
    String? assessmentId,
  }) {
    return IQScore(
      fsiq: fsiq ?? this.fsiq,
      vci: vci ?? this.vci,
      vsi: vsi ?? this.vsi,
      fri: fri ?? this.fri,
      wmi: wmi ?? this.wmi,
      psi: psi ?? this.psi,
      gai: gai ?? this.gai,
      nvi: nvi ?? this.nvi,
      cci: cci ?? this.cci,
      confidenceIntervals: confidenceIntervals ?? this.confidenceIntervals,
      percentiles: percentiles ?? this.percentiles,
      classifications: classifications ?? this.classifications,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      assessmentId: assessmentId ?? this.assessmentId,
    );
  }

  @override
  List<Object?> get props => [
        fsiq,
        vci,
        vsi,
        fri,
        wmi,
        psi,
        gai,
        nvi,
        cci,
        confidenceIntervals,
        percentiles,
        classifications,
        ageInMonths,
        assessmentDate,
        assessmentId,
      ];
}

/// Intervalle de confiance
class ConfidenceInterval extends Equatable {
  /// Borne inférieure
  final int lowerBound;

  /// Borne supérieure
  final int upperBound;

  /// Niveau de confiance (0.95 pour 95%)
  final double confidenceLevel;

  const ConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    this.confidenceLevel = 0.95,
  });

  /// Largeur de l'intervalle
  int get width => upperBound - lowerBound;

  /// Point médian
  int get midpoint => ((lowerBound + upperBound) / 2).round();

  /// Vérifie si un score est dans l'intervalle
  bool contains(int score) => score >= lowerBound && score <= upperBound;

  @override
  List<Object?> get props => [lowerBound, upperBound, confidenceLevel];

  @override
  String toString() =>
      '[$lowerBound - $upperBound] (${(confidenceLevel * 100).toInt()}% CI)';
}

/// Score brut d'un sous-test
class RawScore extends Equatable {
  /// Code du sous-test
  final String subtestCode;

  /// Score brut (nombre de points)
  final int rawScore;

  /// Nombre d'items administrés
  final int itemsAdministered;

  /// Nombre d'items corrects
  final int itemsCorrect;

  /// Durée de passation (secondes)
  final int durationSeconds;

  const RawScore({
    required this.subtestCode,
    required this.rawScore,
    required this.itemsAdministered,
    required this.itemsCorrect,
    required this.durationSeconds,
  });

  /// Taux de réussite
  double get successRate =>
      itemsAdministered > 0 ? itemsCorrect / itemsAdministered : 0.0;

  @override
  List<Object?> get props => [
        subtestCode,
        rawScore,
        itemsAdministered,
        itemsCorrect,
        durationSeconds,
      ];
}

/// Score standardisé (note standard sur échelle 1-19)
class ScaledScore extends Equatable {
  /// Code du sous-test
  final String subtestCode;

  /// Score brut correspondant
  final int rawScore;

  /// Note standard (moyenne 10, écart-type 3)
  final int scaledScore;

  /// Âge de référence (en mois)
  final int ageInMonths;

  const ScaledScore({
    required this.subtestCode,
    required this.rawScore,
    required this.scaledScore,
    required this.ageInMonths,
  });

  /// Classification descriptive
  String get classification {
    if (scaledScore >= 16) return appL10n.scoringClassificationVerySuperior;
    if (scaledScore >= 13) return appL10n.scoringClassificationSuperior;
    if (scaledScore >= 11) return appL10n.scoringClassificationHighAverage;
    if (scaledScore >= 8) return appL10n.scoringClassificationAverage;
    if (scaledScore >= 6) return appL10n.scoringClassificationLowAverage;
    if (scaledScore >= 4) return appL10n.scoringClassificationBorderline;
    return appL10n.scoringClassificationExtremelyLow;
  }

  @override
  List<Object?> get props => [subtestCode, rawScore, scaledScore, ageInMonths];
}
