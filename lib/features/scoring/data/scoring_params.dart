/// SOURCE DE VÉRITÉ UNIQUE du système de notation Mentality.
///
/// Ce fichier ne contient QUE des nombres et des compositions — aucune logique.
/// Il est conçu pour être édité par des psychologues : ajuster une moyenne, une
/// courbe d'âge ou une corrélation ici suffit à recalibrer tout le système, sans
/// toucher au moteur ([NormativeTables], [CompositeScoreTables]).
///
/// Statut : valeurs PROVISOIRES (priors). Elles seront remplacées par des
/// estimations EMPIRIQUES (moyenne/écart-type réels par tranche d'âge) dès qu'on
/// aura collecté assez de sessions. Voir docs/REFONTE_NOTATION_SPEC.md.
library;

/// Grands domaines cognitifs — déterminent la trajectoire avec l'âge.
enum CognitiveDomain {
  /// Intelligence cristallisée : monte puis plateau (VO, IN, SI).
  crystallized,

  /// Raisonnement fluide : pic vers 25 ans puis déclin (MR, FW, VP, BD).
  fluid,

  /// Mémoire de travail : léger déclin après 35 ans (DS, AR, PM).
  workingMemory,

  /// Vitesse de traitement : déclin le plus marqué (CD, SS).
  processingSpeed,
}

/// Norme d'un sous-test : étendue du brut + distribution attendue à l'âge de référence.
class SubtestNorm {
  /// Brut minimum admissible (le moteur borne le brut à cet intervalle).
  final int rawMin;

  /// Brut maximum réellement atteignable par un participant parfait.
  final int rawMax;

  /// Moyenne attendue du brut à l'âge de référence (25-35 ans).
  final double muRef;

  /// Écart-type attendu du brut.
  final double sigmaRef;

  /// Domaine cognitif (pour la courbe d'âge).
  final CognitiveDomain domain;

  const SubtestNorm({
    required this.rawMin,
    required this.rawMax,
    required this.muRef,
    required this.sigmaRef,
    required this.domain,
  });
}

/// Norme d'un indice composite : sa composition et ses paramètres psychométriques.
class IndexNorm {
  /// Codes des sous-tests qui composent l'indice (k = longueur).
  final List<String> subtests;

  /// Corrélation moyenne inter-sous-tests (→ écart-type de la somme).
  final double r;

  /// Coefficient de fidélité (→ SEM = 15·√(1−rxx), donc l'intervalle de confiance).
  final double rxx;

  const IndexNorm({
    required this.subtests,
    required this.r,
    required this.rxx,
  });

  /// Nombre de sous-tests dans l'indice.
  int get k => subtests.length;
}

/// Paramètres globaux du système de notation. Tout est `const` et éditable.
class ScoringParams {
  ScoringParams._();

  // ───────────────────────────────────────────────────────────────────────
  // COURBES D'ÂGE
  // µ_attendu(âge) = muRef · ageFactor(domaine, âge).
  // Les facteurs valent ~1.0 à l'âge de référence (25 ans) et modulent la
  // moyenne attendue selon l'âge → la note est toujours relative à l'âge.
  // ───────────────────────────────────────────────────────────────────────

  /// Âges (en années) où la courbe est ancrée. Interpolation linéaire entre eux.
  static const List<int> ageAnchorsYears = [16, 25, 35, 45, 55, 65, 75, 85];

  /// Facteur multiplicatif de la moyenne attendue, par domaine et par âge d'ancrage.
  static const Map<CognitiveDomain, List<double>> ageFactorByDomain = {
    // monte jusqu'à ~50, plateau, légère baisse après 70
    CognitiveDomain.crystallized: [0.90, 0.98, 1.00, 1.02, 1.02, 1.00, 0.96, 0.90],
    // pic à 25, déclin régulier
    CognitiveDomain.fluid: [0.97, 1.00, 0.97, 0.92, 0.86, 0.79, 0.71, 0.62],
    // léger déclin après 35
    CognitiveDomain.workingMemory: [0.97, 1.00, 0.99, 0.96, 0.92, 0.87, 0.81, 0.74],
    // déclin le plus marqué
    CognitiveDomain.processingSpeed: [0.95, 1.00, 0.97, 0.90, 0.82, 0.72, 0.62, 0.52],
  };

  // ───────────────────────────────────────────────────────────────────────
  // NORMES PAR SOUS-TEST
  // muRef ≈ 0,55·rawMax, sigmaRef ≈ 0,16·rawMax (priors par défaut).
  // rawMax = brut max RÉEL mesuré dans le code (audit 2026-06-16).
  // ───────────────────────────────────────────────────────────────────────
  static const Map<String, SubtestNorm> subtests = {
    'BD': SubtestNorm(rawMin: 0, rawMax: 42, muRef: 23.1, sigmaRef: 6.7, domain: CognitiveDomain.fluid),
    'SI': SubtestNorm(rawMin: 0, rawMax: 42, muRef: 23.0, sigmaRef: 6.7, domain: CognitiveDomain.crystallized),
    'DS': SubtestNorm(rawMin: 0, rawMax: 46, muRef: 25.3, sigmaRef: 7.4, domain: CognitiveDomain.workingMemory),
    'MR': SubtestNorm(rawMin: 0, rawMax: 26, muRef: 14.3, sigmaRef: 4.2, domain: CognitiveDomain.fluid),
    'VO': SubtestNorm(rawMin: 0, rawMax: 60, muRef: 33.0, sigmaRef: 9.6, domain: CognitiveDomain.crystallized),
    'AR': SubtestNorm(rawMin: 0, rawMax: 22, muRef: 12.1, sigmaRef: 3.5, domain: CognitiveDomain.workingMemory),
    // SS : brut = corrects − erreurs, borné ≥ 0 (rawMin: 0 corrige le brut négatif).
    'SS': SubtestNorm(rawMin: 0, rawMax: 60, muRef: 33.0, sigmaRef: 9.6, domain: CognitiveDomain.processingSpeed),
    'VP': SubtestNorm(rawMin: 0, rawMax: 26, muRef: 14.3, sigmaRef: 4.2, domain: CognitiveDomain.fluid),
    'IN': SubtestNorm(rawMin: 0, rawMax: 28, muRef: 15.4, sigmaRef: 4.5, domain: CognitiveDomain.crystallized),
    'CD': SubtestNorm(rawMin: 0, rawMax: 135, muRef: 74.0, sigmaRef: 21.6, domain: CognitiveDomain.processingSpeed),
    'PM': SubtestNorm(rawMin: 0, rawMax: 12, muRef: 6.6, sigmaRef: 1.9, domain: CognitiveDomain.workingMemory),
    'FW': SubtestNorm(rawMin: 0, rawMax: 27, muRef: 14.9, sigmaRef: 4.3, domain: CognitiveDomain.fluid),
  };

  // ───────────────────────────────────────────────────────────────────────
  // NORMES PAR INDICE COMPOSITE
  // L'écart-type de la somme est DÉRIVÉ de k et r : σ = 3·√(k + k(k−1)·r).
  // WMI inclut désormais PM (Mémoire des images).
  // ───────────────────────────────────────────────────────────────────────
  static const Map<String, IndexNorm> indices = {
    'VCI': IndexNorm(subtests: ['SI', 'VO', 'IN'], r: 0.65, rxx: 0.96),
    'VSI': IndexNorm(subtests: ['BD', 'VP'], r: 0.58, rxx: 0.94),
    'FRI': IndexNorm(subtests: ['MR', 'FW'], r: 0.55, rxx: 0.93),
    'WMI': IndexNorm(subtests: ['DS', 'AR', 'PM'], r: 0.52, rxx: 0.93),
    'PSI': IndexNorm(subtests: ['CD', 'SS'], r: 0.48, rxx: 0.90),
    'FSIQ': IndexNorm(
      subtests: ['BD', 'SI', 'DS', 'MR', 'VO', 'AR', 'SS', 'VP', 'IN', 'CD'],
      r: 0.50,
      rxx: 0.97,
    ),
  };

  /// Facteur d'âge interpolé pour un [domain] et un âge donné en mois.
  ///
  /// Renvoie 1.0 à l'âge de référence ; <1 ou >1 selon la trajectoire du domaine.
  /// Extrapolation plate au-delà des âges d'ancrage (16 et 85 ans).
  static double ageFactor(CognitiveDomain domain, int ageInMonths) {
    final factors = ageFactorByDomain[domain]!;
    final ageYears = ageInMonths / 12.0;

    if (ageYears <= ageAnchorsYears.first) return factors.first;
    if (ageYears >= ageAnchorsYears.last) return factors.last;

    for (var i = 0; i < ageAnchorsYears.length - 1; i++) {
      final a0 = ageAnchorsYears[i];
      final a1 = ageAnchorsYears[i + 1];
      if (ageYears >= a0 && ageYears <= a1) {
        final t = (ageYears - a0) / (a1 - a0);
        return factors[i] + t * (factors[i + 1] - factors[i]);
      }
    }
    return 1.0;
  }
}
