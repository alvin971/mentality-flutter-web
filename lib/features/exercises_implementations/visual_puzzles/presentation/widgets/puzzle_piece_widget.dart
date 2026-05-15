import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/puzzle_generator.dart';

/// Widget tappable affichant une pièce de puzzle.
///
/// Rendu CustomPaint avec arêtes interlock visibles (convex/concave/jagged).
/// Couleurs adaptées light/dark via Theme.of(context) + accent VSI.
class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.label,
    this.isSelected = false,
    this.showCorrect = false,
    this.showIncorrect = false,
    this.onTap,
    this.aspectRatio = 1.0,
  });

  final PuzzlePiece piece;
  final String label; // 'A', 'B', 'C', 'D', 'E', 'F'
  final bool isSelected;
  final bool showCorrect;
  final bool showIncorrect;
  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppColors.accentForBrightness(
        AppColors.indexVSI, Theme.of(context).brightness);

    Color borderColor;
    double borderWidth;
    if (showCorrect) {
      borderColor = AppColors.success;
      borderWidth = 3;
    } else if (showIncorrect) {
      borderColor = AppColors.error;
      borderWidth = 3;
    } else if (isSelected) {
      borderColor = accent;
      borderWidth = 3;
    } else {
      borderColor = cs.outline.withValues(alpha: 0.3);
      borderWidth = 1;
    }

    return Semantics(
      button: true,
      label: 'Pièce $label',
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // Label A/B/C... en haut-gauche
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label,
                      style: AppText.monoLabel(color: accent)),
                ),
                SizedBox(height: 4.h),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: CustomPaint(
                      painter: _PiecePainter(
                        piece: piece,
                        fillColor: accent.withValues(alpha: 0.22),
                        strokeColor: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter qui dessine une pièce avec ses arêtes (convex / concave / jagged).
class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.piece,
    required this.fillColor,
    required this.strokeColor,
  });

  final PuzzlePiece piece;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Normalise vers un carré centré, marge pour les bumps d'arêtes
    final s = math.min(size.width, size.height) * 0.78 * piece.scale;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: s, height: s);

    canvas.save();
    canvas.translate(cx, cy);
    if (piece.mirrored) canvas.scale(-1, 1);
    canvas.rotate(piece.rotationDeg * math.pi / 180);
    canvas.translate(-cx, -cy);

    final path = _buildShapePath(piece.shape, rect, piece.edges);

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    canvas.restore();
  }

  /// Construit le path de la pièce. Pour les formes rectangulaires, applique
  /// les arêtes [edges] sur top/right/bottom/left. Pour les autres formes
  /// (triangle, parallélogramme…), trace la silhouette de base.
  Path _buildShapePath(PuzzleShape shape, Rect rect, EdgePattern edges) {
    final path = Path();
    switch (shape) {
      case PuzzleShape.square:
      case PuzzleShape.rectangleH:
      case PuzzleShape.rectangleV:
        return _rectWithEdges(rect, edges);
      case PuzzleShape.triangle:
        path.moveTo(rect.center.dx, rect.top);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
        path.close();
        return path;
      case PuzzleShape.trapezoid:
        final dx = rect.width * 0.18;
        path.moveTo(rect.left + dx, rect.top);
        path.lineTo(rect.right - dx, rect.top);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
        path.close();
        return path;
      case PuzzleShape.parallelogram:
        final dx = rect.width * 0.2;
        path.moveTo(rect.left + dx, rect.top);
        path.lineTo(rect.right, rect.top);
        path.lineTo(rect.right - dx, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
        path.close();
        return path;
      case PuzzleShape.lShape:
        final w = rect.width;
        final h = rect.height;
        path.moveTo(rect.left, rect.top);
        path.lineTo(rect.left + w * 0.55, rect.top);
        path.lineTo(rect.left + w * 0.55, rect.top + h * 0.55);
        path.lineTo(rect.right, rect.top + h * 0.55);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
        path.close();
        return path;
      case PuzzleShape.tShape:
        final w = rect.width;
        final h = rect.height;
        path.moveTo(rect.left, rect.top);
        path.lineTo(rect.right, rect.top);
        path.lineTo(rect.right, rect.top + h * 0.4);
        path.lineTo(rect.left + w * 0.65, rect.top + h * 0.4);
        path.lineTo(rect.left + w * 0.65, rect.bottom);
        path.lineTo(rect.left + w * 0.35, rect.bottom);
        path.lineTo(rect.left + w * 0.35, rect.top + h * 0.4);
        path.lineTo(rect.left, rect.top + h * 0.4);
        path.close();
        return path;
      case PuzzleShape.zShape:
        final w = rect.width;
        final h = rect.height;
        path.moveTo(rect.left, rect.top);
        path.lineTo(rect.left + w * 0.7, rect.top);
        path.lineTo(rect.left + w * 0.7, rect.top + h * 0.5);
        path.lineTo(rect.right, rect.top + h * 0.5);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left + w * 0.3, rect.bottom);
        path.lineTo(rect.left + w * 0.3, rect.top + h * 0.5);
        path.lineTo(rect.left, rect.top + h * 0.5);
        path.close();
        return path;
    }
  }

  /// Path d'un rectangle avec arêtes interlock sur les 4 côtés.
  Path _rectWithEdges(Rect rect, EdgePattern edges) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    // Amplitude des bumps : 18% de la taille du côté
    final bumpW = w * 0.18;
    final bumpH = h * 0.18;

    // TOP : gauche → droite
    path.moveTo(rect.left, rect.top);
    _appendEdge(path, edges.top, _Side.top, rect, bumpH);

    // RIGHT : haut → bas
    _appendEdge(path, edges.right, _Side.right, rect, bumpW);

    // BOTTOM : droite → gauche
    _appendEdge(path, edges.bottom, _Side.bottom, rect, bumpH);

    // LEFT : bas → haut
    _appendEdge(path, edges.left, _Side.left, rect, bumpW);

    path.close();
    return path;
  }

  /// Ajoute un côté au path avec son type d'arête.
  void _appendEdge(Path path, EdgeType type, _Side side, Rect rect, double bump) {
    // Points de départ et arrivée selon le côté
    final start = _edgeStart(side, rect);
    final end = _edgeEnd(side, rect);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    // Direction perpendiculaire (vers l'extérieur de la pièce)
    final outward = _outwardNormal(side);

    switch (type) {
      case EdgeType.flat:
        path.lineTo(end.dx, end.dy);
        break;
      case EdgeType.convex:
        // Bosse vers l'extérieur (bump positif)
        _drawBump(path, start, end, mid, outward, bump, sign: 1);
        break;
      case EdgeType.concave:
        // Creux vers l'intérieur (bump négatif)
        _drawBump(path, start, end, mid, outward, bump, sign: -1);
        break;
      case EdgeType.jaggedOut:
        _drawJagged(path, start, end, outward, bump, sign: 1);
        break;
      case EdgeType.jaggedIn:
        _drawJagged(path, start, end, outward, bump, sign: -1);
        break;
    }
  }

  Offset _edgeStart(_Side side, Rect r) => switch (side) {
        _Side.top => Offset(r.left, r.top),
        _Side.right => Offset(r.right, r.top),
        _Side.bottom => Offset(r.right, r.bottom),
        _Side.left => Offset(r.left, r.bottom),
      };

  Offset _edgeEnd(_Side side, Rect r) => switch (side) {
        _Side.top => Offset(r.right, r.top),
        _Side.right => Offset(r.right, r.bottom),
        _Side.bottom => Offset(r.left, r.bottom),
        _Side.left => Offset(r.left, r.top),
      };

  Offset _outwardNormal(_Side side) => switch (side) {
        _Side.top => const Offset(0, -1),
        _Side.right => const Offset(1, 0),
        _Side.bottom => const Offset(0, 1),
        _Side.left => const Offset(-1, 0),
      };

  void _drawBump(Path path, Offset start, Offset end, Offset mid, Offset out,
      double bump,
      {required int sign}) {
    // Une bosse semi-circulaire au milieu du segment (sign=1: vers extérieur,
    // sign=-1: vers intérieur).
    final amp = bump * sign;
    // Tier point pour cubic
    final dir = Offset(end.dx - start.dx, end.dy - start.dy);
    final t1 = Offset(start.dx + dir.dx * 0.30, start.dy + dir.dy * 0.30);
    final t2 = Offset(start.dx + dir.dx * 0.70, start.dy + dir.dy * 0.70);
    final c1 = Offset(t1.dx + out.dx * amp, t1.dy + out.dy * amp);
    final c2 = Offset(t2.dx + out.dx * amp, t2.dy + out.dy * amp);
    path.lineTo(t1.dx, t1.dy);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, t2.dx, t2.dy);
    path.lineTo(end.dx, end.dy);
  }

  void _drawJagged(Path path, Offset start, Offset end, Offset out, double bump,
      {required int sign}) {
    // 3 dents triangulaires (sign=1: out, sign=-1: in)
    const teeth = 3;
    final amp = bump * sign * 0.65;
    final dir = Offset(end.dx - start.dx, end.dy - start.dy);
    for (int i = 1; i <= teeth * 2; i++) {
      final t = i / (teeth * 2 + 1);
      final p = Offset(start.dx + dir.dx * t, start.dy + dir.dy * t);
      final isApex = i.isOdd;
      if (isApex) {
        path.lineTo(p.dx + out.dx * amp, p.dy + out.dy * amp);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.lineTo(end.dx, end.dy);
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.piece != piece ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}

enum _Side { top, right, bottom, left }

/// Façade publique pour réutiliser le rendu de pièce depuis d'autres painters
/// (ex: PuzzleTargetWidget compose les 3 targetPieces).
class PuzzlePiecePainterFacade {
  PuzzlePiecePainterFacade._();

  static void paintPiece({
    required Canvas canvas,
    required PuzzlePiece piece,
    required Size size,
    required Color fillColor,
    required Color strokeColor,
    bool forceFullCell = false,
  }) {
    final painter = _PiecePainter(
      piece: forceFullCell
          ? piece.copyWith(scale: 1.0, rotationDeg: 0, mirrored: false)
          : piece,
      fillColor: fillColor,
      strokeColor: strokeColor,
    );
    if (forceFullCell) {
      // Pour la cible : dessiner pièce à pleine cellule sans marge interne.
      painter._paintFullCell(canvas, size);
    } else {
      painter.paint(canvas, size);
    }
  }
}

extension _PiecePainterFullCell on _PiecePainter {
  /// Variante "remplit toute la cellule" pour la silhouette cible.
  void _paintFullCell(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildShapePath(piece.shape, rect, piece.edges);

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }
}
