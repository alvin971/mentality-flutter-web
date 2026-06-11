import 'dart:math' as math;
import 'base_shapes.dart';
import 'cut_engine.dart';
import 'geometry.dart';

/// Types de pièges. Tous produisent des pièces PLAUSIBLES (polygones propres,
/// pas de déformations cabossées) — la difficulté vient de la subtilité de la
/// différence, pas de l'aspect "cassé".
enum TrapKind {
  /// Pièce issue d'une AUTRE découpe valide de la même cible — très plausible,
  /// mais ne complète pas les deux autres pièces.
  /// ⚠ Réservé aux niveaux MEDIUM et HARD uniquement.
  alternativeCut,

  /// Vraie pièce agrandie/réduite. Amplitude forte en début de test
  /// (clairement trop petite) → subtile en fin.
  scaled,

  /// Vraie pièce en miroir. Les pièces peuvent être tournées mais PAS
  /// retournées → invalide. (Rejeté si la pièce est symétrique.)
  mirrored,

  /// Vraie pièce étirée selon un axe (proportions fausses). En mode subtil,
  /// l'aire est préservée (étirement compensé) — piège redoutable.
  stretched,

  /// Pièce d'une forme visuellement CONTRASTANTE (courbe vs angulaire) —
  /// piège évident, réservé aux items faciles.
  foreignShape,
}

/// Fabrique de distracteurs.
///
/// `subtlety` ∈ [0,1] : 0 = piège énorme (début de test), 1 = piège quasi
/// indétectable (fin de test). Les amplitudes sont interpolées en conséquence.
class TrapEngine {
  TrapEngine({math.Random? rng, CutEngine? cutEngine})
      : _rng = rng ?? math.Random(),
        _cutEngine = cutEngine ?? CutEngine(rng: rng);

  final math.Random _rng;
  final CutEngine _cutEngine;

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Tente de produire un piège de type `kind`.
  ///
  /// [targetShape] est utilisé par [TrapKind.foreignShape] pour choisir une
  /// forme visuellement contrastante (courbe pour cible angulaire, etc.).
  Polygon? tryTrap({
    required TrapKind kind,
    required Polygon source,
    required Polygon target,
    required List<Polygon> truePieces,
    required double subtlety,
    BaseShape? targetShape,
  }) {
    final t = subtlety.clamp(0.0, 1.0);
    switch (kind) {
      case TrapKind.scaled:
        // Amplitude large en début de test : pièce clairement trop petite.
        // Pour t < 0.5 on réduit TOUJOURS (jamais d'agrandissement), ce qui
        // évite d'augmenter le maxPieceExtent et de réduire les vraies pièces.
        // Pour t ≥ 0.5 (medium/hard) : les deux directions, amplitude subtile.
        final mag = _lerp(0.56, 0.12, t);
        final factor = t < 0.5
            ? 1.0 - mag
            : (_rng.nextBool() ? 1.0 + mag : 1.0 - mag);
        return source.transform(scale: factor);

      case TrapKind.mirrored:
        final m = source.transform(mirrored: true);
        if (congruent(m, source)) return null;
        return m;

      case TrapKind.stretched:
        // Amplitude bien plus grande qu'avant : visible dès les items moyens.
        final mag = _lerp(0.78, 0.18, t);
        final fx = _rng.nextBool() ? 1 + mag : 1 / (1 + mag);
        // En mode subtil : étirement à aire constante (fy = 1/fx).
        final fy = t > 0.55 ? 1 / fx : 1.0;
        final s = _rng.nextBool()
            ? source.transform(scaleX: fx, scaleY: fy)
            : source.transform(scaleX: fy, scaleY: fx);
        if (congruent(s, source)) return null;
        return s;

      case TrapKind.alternativeCut:
        for (int attempt = 0; attempt < 6; attempt++) {
          final strategy =
              CutStrategy.values[_rng.nextInt(CutStrategy.values.length)];
          final pieces = _cutEngine.cut(target, strategy);
          if (pieces.length != 3) continue;
          final candidates = pieces.where((p) {
            if (p.vertices.length < 3) return false;
            for (final tp in truePieces) {
              if (congruent(p, tp, allowMirror: true)) return false;
            }
            if (t > 0.5) {
              final ratio = p.area() / math.max(source.area(), kGeomEps);
              if (ratio < 0.6 || ratio > 1.6) return false;
            }
            return true;
          }).toList();
          if (candidates.isNotEmpty) {
            return candidates[_rng.nextInt(candidates.length)];
          }
        }
        return null;

      case TrapKind.foreignShape:
        // Choisir une forme visuellement CONTRASTANTE avec la cible :
        // - courbe (cercle, demi-cercle) pour cible angulaire → arc évident
        // - angulaire simple pour cible courbe
        final shapes = _contrastingShapes(targetShape);
        final shape = shapes[_rng.nextInt(shapes.length)];
        final other = buildBaseShape(shape);
        // Coupes simples (bandes) pour items faciles → fragment reconnaissable.
        final strategy =
            t < 0.4 ? CutStrategy.twoParallel : CutStrategy.twoOblique;
        final pieces = _cutEngine.cut(other, strategy);
        if (pieces.length != 3) return null;
        final pick = pieces[_rng.nextInt(pieces.length)];
        if (pick.vertices.length < 3) return null;
        for (final tp in truePieces) {
          if (congruent(pick, tp, allowMirror: true)) return null;
        }
        return pick;
    }
  }

  // ---------- Shapes contrastantes ----------

  /// Renvoie les formes de base qui contrastent visuellement avec [target].
  ///
  /// Logique :
  /// - cible angulaire simple (≤6 sommets) → préférer formes COURBES
  /// - cible courbe (cercle/demi-cercle) → préférer formes angulaires
  /// - cible complexe (maison, polygones ≥5 côtés) → préférer rectangulaires
  List<BaseShape> _contrastingShapes(BaseShape? target) {
    const curved = [BaseShape.circle, BaseShape.semicircle];
    const simpleAngular = [
      BaseShape.square,
      BaseShape.rectangleWide,
      BaseShape.rectangleTall,
      BaseShape.triangleEq,
      BaseShape.triangleRight,
      BaseShape.diamond,
    ];
    const complex = [
      BaseShape.trapezoid,
      BaseShape.parallelogram,
      BaseShape.house,
      BaseShape.pentagon,
      BaseShape.hexagon,
      BaseShape.octagon,
    ];

    if (target == null) return [...curved, ...simpleAngular];

    if (curved.contains(target)) return simpleAngular;
    if (simpleAngular.contains(target)) return [...curved, ...complex];
    // Complex target → prefer simple angular for obvious contrast
    return [...simpleAngular, ...curved];
  }
}
