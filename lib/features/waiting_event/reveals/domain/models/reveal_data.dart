// Ce que les révélations affichent — dérivé de l'historique, et rien de plus.
//
// Une révélation ne CALCULE aucun score : tout a été mesuré pendant les
// 90 minutes de bilan, et l'événement se contente de rendre son dû morceau par
// morceau. Ce fichier est donc une lecture, pas un barème.
//
// Deux choix méritent d'être écrits noir sur blanc :
//
// · LA BANDE EST RECALCULÉE, PAS RELUE. `SessionHistoryEntry.classification`
//   est une CHAÎNE figée dans la langue de la passation : l'afficher telle
//   quelle montrerait « Moyen » à quelqu'un qui lit en allemand. On repart
//   donc du nombre, avec les bornes du barème de l'app (une garde de test
//   vérifie qu'elles n'ont pas divergé de `CompositeScoreTables.classify`).
// · LA RÈGLE DES FORCES EST CELLE DE L'APP. ±10 points autour du QI global,
//   exactement comme `IQScore.strengths` — une garde de parité l'ancre, pour
//   qu'un même profil ne raconte pas deux histoires selon l'écran qui
//   l'affiche.

import 'package:equatable/equatable.dart';

import '../../../../../services/session_history_service.dart';
import '../../../_shared/domain/models/event_day.dart';

/// Les cinq indices primaires, ceux que les journées 1 à 5 révèlent un à un.
enum CognitiveIndex {
  vci,
  vsi,
  fri,
  wmi,
  psi;

  /// Le code utilisé partout ailleurs dans le moteur de notation (tables de
  /// fidélité, intervalles de confiance).
  String get code => switch (this) {
        CognitiveIndex.vci => 'VCI',
        CognitiveIndex.vsi => 'VSI',
        CognitiveIndex.fri => 'FRI',
        CognitiveIndex.wmi => 'WMI',
        CognitiveIndex.psi => 'PSI',
      };
}

/// Bande descriptive d'un score composite (moyenne 100, écart-type 15).
///
/// Les bornes sont celles de `CompositeScoreTables.classify` — mais l'enum ne
/// porte AUCUN texte : les libellés viennent des ARB via le contexte, seule
/// façon d'afficher la bonne langue. La fonction du moteur de notation, elle,
/// résout ses libellés sur `localeNotifier` (hors arbre de widgets), ce qui
/// afficherait le français à un écran monté en portugais.
enum RevealBand {
  extremelyLow,
  borderline,
  lowAverage,
  average,
  highAverage,
  superior,
  verySuperior;

  static RevealBand of(int composite) {
    if (composite >= 130) return RevealBand.verySuperior;
    if (composite >= 120) return RevealBand.superior;
    if (composite >= 110) return RevealBand.highAverage;
    if (composite >= 90) return RevealBand.average;
    if (composite >= 80) return RevealBand.lowAverage;
    if (composite >= 70) return RevealBand.borderline;
    return RevealBand.extremelyLow;
  }
}

/// Le profil déjà gagné pendant le bilan, réduit à ce que les sept
/// révélations ont besoin d'afficher.
class RevealData extends Equatable {
  const RevealData({
    required this.fsiq,
    this.vci,
    this.vsi,
    this.fri,
    this.wmi,
    this.psi,
  });

  final int fsiq;
  final int? vci;
  final int? vsi;
  final int? fri;
  final int? wmi;
  final int? psi;

  /// Le profil du bilan [entry]. `null` quand il n'y a rien à révéler — aucun
  /// écran n'invente alors de chiffre, il le dit (fail-closed : c'est la même
  /// règle que l'historique, qui ne montre jamais le résultat d'un autre passe).
  static RevealData? fromHistory(SessionHistoryEntry? entry) => entry == null
      ? null
      : RevealData(
          fsiq: entry.fsiq,
          vci: entry.vci,
          vsi: entry.vsi,
          fri: entry.fri,
          wmi: entry.wmi,
          psi: entry.psi,
        );

  int? scoreOf(CognitiveIndex index) => switch (index) {
        CognitiveIndex.vci => vci,
        CognitiveIndex.vsi => vsi,
        CognitiveIndex.fri => fri,
        CognitiveIndex.wmi => wmi,
        CognitiveIndex.psi => psi,
      };

  /// L'indice que révèle [kind], ou `null` pour les deux révélations qui n'en
  /// portent pas un seul (les forces comparent les cinq, le QI global les
  /// résume).
  static CognitiveIndex? indexFor(RevealKind kind) => switch (kind) {
        RevealKind.vci => CognitiveIndex.vci,
        RevealKind.vsi => CognitiveIndex.vsi,
        RevealKind.fri => CognitiveIndex.fri,
        RevealKind.wmi => CognitiveIndex.wmi,
        RevealKind.psi => CognitiveIndex.psi,
        RevealKind.strengths => null,
        RevealKind.fullIq => null,
      };

  /// Les indices mesurés, dans l'ordre où l'app les nomme partout.
  List<CognitiveIndex> get measuredIndices =>
      [for (final i in CognitiveIndex.values) if (scoreOf(i) != null) i];

  /// Ce qui dépasse le QI global de plus de 10 points. Une force est
  /// RELATIVE : elle se lit par rapport au niveau moyen de la personne, jamais
  /// comme un talent absolu.
  List<CognitiveIndex> get strengths =>
      [for (final i in measuredIndices) if (scoreOf(i)! > fsiq + 10) i];

  List<CognitiveIndex> get weaknesses =>
      [for (final i in measuredIndices) if (scoreOf(i)! < fsiq - 10) i];

  /// Profil régulier : aucun indice ne s'écarte de la moyenne des indices de
  /// plus d'un écart-type.
  bool get isHomogeneousProfile {
    final scores = [for (final i in measuredIndices) scoreOf(i)!];
    if (scores.length < 2) return true;
    final moyenne = scores.reduce((a, b) => a + b) / scores.length;
    final ecartMax = scores
        .map((s) => (s - moyenne).abs())
        .reduce((a, b) => a > b ? a : b);
    return ecartMax < 15;
  }

  /// Amplitude du profil : du plus haut indice au plus bas.
  int get maxIndexDiscrepancy {
    final scores = [for (final i in measuredIndices) scoreOf(i)!];
    if (scores.isEmpty) return 0;
    final max = scores.reduce((a, b) => a > b ? a : b);
    final min = scores.reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  /// True si [kind] a de quoi s'afficher. Une révélation d'indice manquant
  /// (sous-test non passé) se dit, elle ne se devine pas.
  bool hasDataFor(RevealKind kind) {
    final index = indexFor(kind);
    return index == null ? true : scoreOf(index) != null;
  }

  @override
  List<Object?> get props => [fsiq, vci, vsi, fri, wmi, psi];
}
