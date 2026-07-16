// Régressions de l'audit visuel 2026-07-16 (boucle REACT, tour 1) :
// 1. Échelle unifiée EXACTE de la cible — l'ancien budget de cadre (+40/+46)
//    faisait rétrécir silencieusement la cible de ~2,3 % via
//    min(fitScale, ppu) sur 130/260 items audités.
// 2. Sous-peinture des pièces — le clipping des régions laissait des
//    encoches non peintes aux sommets aigus.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_piece_widget.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_target_widget.dart';

import 'support/vp_audit_capture.dart';

/// Échelle effective du painter cible (réplique de _TargetPainter) pour un
/// cadre donné : min(fitScale, ppu).
double _painterScale(Rect bb, double ppu, Size frame) {
  const padH = 24.0; // LTRB(12,24,12,10)
  const padV = 34.0;
  final pad = PuzzleTargetWidget.painterPadding;
  final availW = (frame.width - padH) * (1 - 2 * pad);
  final availH = (frame.height - padV) * (1 - 2 * pad);
  final fitScale = math.min(availW / bb.width, availH / bb.height);
  return math.min(fitScale, ppu);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('échelle unifiée cible == pièces (dérive interdite)', () {
    // Les deux layouts réels de la page : large (tile 180, cadre 470×380)
    // et étroit (tile ~111, cadre 440×250 par défaut).
    const layouts = [
      (tile: 180.0, maxW: 470.0, maxH: 380.0),
      (tile: 111.0, maxW: 440.0, maxH: 250.0),
    ];

    for (final l in layouts) {
      test('cadre ${l.maxW.toInt()}×${l.maxH.toInt()}, tuile ${l.tile}', () {
        for (final seed in [1, 4, 7, 10, 42]) {
          final items = PuzzleGenerator(seed: seed).generateComplete26Items();
          for (final item in items) {
            final ppu =
                PuzzlePieceWidget.pixelsPerUnit(l.tile, item.maxPieceExtent);
            final bb = item.targetPolygon.bbox();
            final frame = PuzzleTargetWidget.unifiedFrameSize(bb, ppu,
                maxWidth: l.maxW, maxHeight: l.maxH);
            final scale = _painterScale(bb, ppu, frame);
            expect(scale, moreOrLessEquals(ppu, epsilon: 1e-9),
                reason: 'seed $seed item ${item.index} : la cible doit être '
                    'dessinée exactement à ppu (dérive = ${ppu / scale})');
          }
        }
      });
    }
  });

  // Métriques VERROUILLÉES de l'audit visuel (60 seeds × 26 items) — toute
  // régression sur l'un de ces invariants doit être un choix explicite.
  test('métriques verrouillées : inflation, distinctness mono, fallback', () {
    double worstInfl = 0;
    int fallbacks = 0, monoViolations = 0, items = 0;
    for (var seed = 1; seed <= 60; seed++) {
      for (final it in PuzzleGenerator(seed: seed).generateComplete26Items()) {
        items++;
        if (it.fallbackUsed) fallbacks++;

        // Inflation d'échelle par rotation (défaut L) : bbox affiché max /
        // bbox non tourné max. Avant fix : 1,41 (cible ~53 px sur mobile).
        double maxUnrot = 0, maxDisp = 0;
        for (final o in it.options) {
          final ub = o.polygon.bbox();
          final db = o.displayPolygon.bbox();
          maxUnrot = math.max(maxUnrot, math.max(ub.width, ub.height));
          maxDisp = math.max(maxDisp, math.max(db.width, db.height));
        }
        worstInfl = math.max(worstInfl, maxDisp / maxUnrot);

        // Distinctness monochrome (défaut mono) : aucun piège non-miroir
        // quasi identique à une vraie pièce quand la couleur n'aide pas.
        if (it.palette.length == 1) {
          for (final o in it.options
              .where((o) => !o.isCorrect && o.trapKind != TrapKind.mirrored)) {
            for (final t in it.options.where((o) => o.isCorrect)) {
              if (perceptuallyIdentical(o.polygon, t.polygon,
                  allowMirror: true, relTol: kMonoDistinctTol)) {
                monoViolations++;
              }
            }
          }
        }
      }
    }
    expect(worstInfl, lessThanOrEqualTo(1.22),
        reason: 'inflation d échelle par rotation (√2×0,8 + cas X-mode)');
    expect(monoViolations, 0,
        reason: 'piège quasi-jumeau d une vraie pièce sur item monochrome');
    expect(fallbacks / items, lessThan(0.05),
        reason: 'les gardes ne doivent pas asphyxier la génération');
  });

  test('perceptuallyIdentical est symétrique (paires d options réelles)', () {
    for (final seed in [7, 23, 38, 53]) {
      for (final it in PuzzleGenerator(seed: seed).generateComplete26Items()) {
        for (int i = 0; i < it.options.length; i++) {
          for (int j = i + 1; j < it.options.length; j++) {
            final a = it.options[i].polygon;
            final b = it.options[j].polygon;
            expect(
              perceptuallyIdentical(a, b, allowMirror: true),
              perceptuallyIdentical(b, a, allowMirror: true),
              reason: 'seed $seed item ${it.index} options ${i + 1}/${j + 1}',
            );
          }
        }
      }
    }
  });

  testWidgets('sous-peinture : aucune encoche non peinte dans la silhouette',
      (tester) async {
    // Pièce artificielle dont la région ne couvre que la moitié gauche :
    // la moitié droite doit être sous-peinte avec la couleur dominante,
    // jamais laissée à la couleur de fond de la case.
    const square = Polygon([
      Offset(0, 0),
      Offset(1, 0),
      Offset(1, 1),
      Offset(0, 1),
    ]);
    const leftHalf = Polygon([
      Offset(0, 0),
      Offset(0.5, 0),
      Offset(0.5, 1),
      Offset(0, 1),
    ]);
    const piece = PuzzlePiece(
      id: 'probe',
      polygon: square,
      regions: [ColoredRegion(leftHalf, 0)],
    );
    const paletteColor = Color(0xFF2B6CB0);

    final key = GlobalKey();
    // wrapCard : délégués l10n requis par le widget (context.l10n) ; zone
    // gardée : le fetch google_fonts échoue toujours hors ligne en test.
    await guardedFontZone(() async {
      await tester.pumpWidget(wrapCard(RepaintBoundary(
        key: key,
        child: SizedBox(
          width: 180,
          height: 180,
          child: PuzzlePieceWidget(
            piece: piece,
            label: '1',
            unitsPerTile: 1.0,
            palette: const [paletteColor],
          ),
        ),
      )));
      await tester.pump();
    });

    final probe = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      // Zone de dessin : padding 4 + LTRB(4,20,4,4) → boîte 164×148 en
      // (8,28) ; painter padding 0.03 sur le côté court (148) → échelle
      // 139.1, bbox 1×1 centrée. Point sondé : moitié droite (x≈0.75).
      const scale = 148 * 0.94;
      const ox = 8 + (164 - scale) / 2;
      const oy = 28 + (148 - scale) / 2;
      final px = (ox + 0.75 * scale).round();
      final py = (oy + 0.5 * scale).round();
      final o = (py * img.width + px) * 4;
      return (
        r: data!.getUint8(o),
        g: data.getUint8(o + 1),
        b: data.getUint8(o + 2),
      );
    });

    expect(
      Color.fromARGB(255, probe!.r, probe.g, probe.b),
      paletteColor,
      reason: 'la moitié non couverte par la région doit être sous-peinte '
          'avec la couleur dominante (encoches blanches interdites)',
    );
  });
}
