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
  alternativeCut,

  /// Vraie pièce agrandie/réduite. Détectable par comparaison des tailles.
  scaled,

  /// Vraie pièce en miroir. Les pièces peuvent être tournées mais PAS
  /// retournées → invalide. (Rejeté si la pièce est symétrique.)
  mirrored,

  /// Vraie pièce étirée selon un axe (proportions fausses). En mode subtil,
  /// l'aire est préservée (étirement compensé) — piège redoutable.
  stretched,

  /// Pièce d'une autre forme de base (silhouette différente) — piège évident,
  /// réservé aux premiers items.
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

  /// Tente de produire un piège de type `kind` à partir de la pièce `source`.
  /// Retourne null si ce type est inapplicable (ex. miroir d'une pièce
  /// symétrique) — l'appelant essaiera un autre type.
  Polygon? tryTrap({
    required TrapKind kind,
    required Polygon source,
    required Polygon target,
    required List<Polygon> truePieces,
    required double subtlety,
  }) {
    final t = subtlety.clamp(0.0, 1.0);
    switch (kind) {
      case TrapKind.scaled:
        final mag = _lerp(0.34, 0.14, t);
        final factor = _rng.nextBool() ? 1 + mag : 1 / (1 + mag);
        return source.transform(scale: factor);

      case TrapKind.mirrored:
        final m = source.transform(mirrored: true);
        // Inutile si la pièce est symétrique (le miroir = rotation valide).
        if (congruent(m, source)) return null;
        return m;

      case TrapKind.stretched:
        final mag = _lerp(0.40, 0.18, t);
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
            // Jamais congruente à une vraie pièce (sinon 2 réponses valides),
            // miroir compris (le candidat pourrait être retourné par hasard).
            for (final tp in truePieces) {
              if (congruent(p, tp, allowMirror: true)) return false;
            }
            // En mode subtil, on privilégie une aire proche de la source.
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
        // Morceau d'une autre silhouette, clairement étranger.
        final shapes = BaseShape.values
            .where((s) => buildBaseShape(s).vertices.length <= 8)
            .toList();
        final shape = shapes[_rng.nextInt(shapes.length)];
        final other = buildBaseShape(shape);
        final pieces = _cutEngine.cut(other, CutStrategy.twoOblique);
        if (pieces.length != 3) return null;
        final pick = pieces[_rng.nextInt(pieces.length)];
        if (pick.vertices.length < 3) return null;
        for (final tp in truePieces) {
          if (congruent(pick, tp, allowMirror: true)) return null;
        }
        return pick;
    }
  }
}
