// AUDIT de solvabilité humaine (outil permanent, cf. audit 2026-07-02) :
// 1. rendu COLORÉ fidèle à l'app (cible = motif sans lignes de découpe ;
//    options = régions colorées à l'échelle commune) pour contrôle visuel ;
// 2. métriques de solvabilité sur 60 seeds, VERROUILLÉES par assertions :
//    zéro piège quasi congruent à une vraie pièce, zéro wrongColors réduit
//    à un jugement de taille, zéro palette ambiguë, zéro pièce aiguille.
//
//   flutter test test/exercises_implementations/visual_puzzles/render_items_audit_test.dart
//
// Sorties :
//   /tmp/vp_audit_<seed>.png  — bordure VERTE = vraie pièce, ROUGE = piège,
//                               ORANGE = piège wrongColors.
//   stdout — détail des items rendus + statistiques sur 60 seeds.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

const double tile = 150;
const double gap = 10;

void main() {
  testWidgets('rendu coloré pour audit', (tester) async {
    await tester.runAsync(() async {
      for (final seed in [2026, 7]) {
        final gen = PuzzleGenerator(seed: seed);
        final all = gen.generateComplete26Items();
        final picks = [0, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25];
        final items = [for (final i in picks) all[i]];

        final width = gap + 7 * (tile + gap);
        final height = gap + items.length * (tile + gap);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
            Paint()..color = const Color(0xFF22252D));

        double y = gap;
        for (final item in items) {
          // ---- log console
          final buf = StringBuffer(
              'item ${item.index} ${item.level.name} ${item.baseShape.name} '
              '${item.cutStrategy.name} palette=${item.palette.map((c) => c.toARGB32().toRadixString(16).substring(2)).join(",")} | ');
          for (int i = 0; i < item.options.length; i++) {
            final o = item.options[i];
            buf.write(
                '${i + 1}:${o.isCorrect ? "OK" : o.trapKind?.name ?? "?"}'
                '${o.displayRotationDeg != 0 ? "(r${o.displayRotationDeg.toInt()})" : ""} ');
          }
          // ignore: avoid_print
          print(buf);

          // ---- cible
          _tileBg(canvas, Offset(gap, y), const Color(0xFF8A7BFF));
          _drawRegions(canvas, item.targetPolygon, item.colorZones,
              item.palette, Rect.fromLTWH(gap, y, tile, tile),
              fit: true);
          // ---- options
          for (int i = 0; i < item.options.length; i++) {
            final o = item.options[i];
            final x = gap + (i + 1) * (tile + gap);
            final border = o.isCorrect
                ? const Color(0xFF4CAF50)
                : (o.trapKind == TrapKind.wrongColors
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFB3453F));
            _tileBg(canvas, Offset(x, y), border);
            _drawRegions(canvas, o.displayPolygon, o.displayRegions,
                item.palette, Rect.fromLTWH(x, y, tile, tile),
                unitsPerTile: item.maxPieceExtent);
          }
          y += tile + gap;
        }

        final picture = recorder.endRecording();
        final img = await picture.toImage(width.toInt(), height.toInt());
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final f = File('/tmp/vp_audit_$seed.png');
        await f.writeAsBytes(bytes!.buffer.asUint8List());
        // ignore: avoid_print
        print('PNG écrit : ${f.path}');
      }
    });
  });

  test('métriques de solvabilité sur 60 seeds', () {
    int items = 0;
    int ambiguousGeom = 0; // piège quasi congruent à une vraie pièce (≤6 %)
    int dupTrueTrap = 0; // paire visuellement identique vraie/piège
    int dupTrapTrap = 0;
    int wrongColorsUniReduced = 0; // wrongColors uni ↔ vraie pièce uni même couleur
    int sliverOptions = 0;
    int itemsWithSliver = 0;
    int itemsWithClosePalette = 0;
    int itemsWithCvdPair = 0;
    final trapCounts = <String, int>{};
    final examples = <String>[];
    // Ventilation par niveau + par position d'item (1-7 = début de test).
    final byLevelAmbig = <String, int>{};
    final byLevelWcUni = <String, int>{};
    int earlyProblemItems = 0; // items 1-7 avec ambiguïté ou réduction taille
    final ambigByKind = <String, int>{};

    Map<int, double> histo(PuzzlePiece p) {
      final h = <int, double>{};
      final total = math.max(p.polygon.area(), 1e-9);
      for (final r in p.regions) {
        h[r.colorIndex] = (h[r.colorIndex] ?? 0) + r.polygon.area() / total;
      }
      return h;
    }

    double histoDiff(Map<int, double> a, Map<int, double> b) {
      double d = 0;
      for (final k in {...a.keys, ...b.keys}) {
        d += ((a[k] ?? 0) - (b[k] ?? 0)).abs();
      }
      return d / 2;
    }

    double rgbDist(Color a, Color b) {
      final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
      return math.sqrt(dr * dr + dg * dg + db * db);
    }

    bool isCvdConfusable(Color a, Color b) {
      // Approx deutéranopie : projection sans axe rouge-vert.
      double l(Color c) => 0.3 * c.r + 0.6 * c.g + 0.1 * c.b;
      final dl = (l(a) - l(b)).abs() * 255;
      final dbl = ((a.b - b.b) * 255).abs();
      return dl < 40 && dbl < 40;
    }

    for (int seed = 1; seed <= 60; seed++) {
      final gen = PuzzleGenerator(seed: seed);
      for (final item in gen.generateComplete26Items()) {
        items++;
        final trues = item.options.where((o) => o.isCorrect).toList();
        final traps = item.options.where((o) => !o.isCorrect).toList();
        for (final t in traps) {
          trapCounts[t.trapKind?.name ?? '?'] =
              (trapCounts[t.trapKind?.name ?? '?'] ?? 0) + 1;
        }

        // 1. géométrie quasi identique à une vraie pièce
        bool itemAmbig = false;
        for (final d in traps) {
          if (d.trapKind == TrapKind.wrongColors) continue;
          for (final t in trues) {
            if (congruent(d.polygon, t.polygon, relTol: 0.06)) {
              ambiguousGeom++;
              itemAmbig = true;
              ambigByKind[d.trapKind?.name ?? '?'] =
                  (ambigByKind[d.trapKind?.name ?? '?'] ?? 0) + 1;
              if (examples.length < 8) {
                examples.add(
                    'seed=$seed item=${item.index} ${d.trapKind?.name} ≈ vraie pièce (${item.baseShape.name}/${item.cutStrategy.name})');
              }
              break;
            }
          }
        }
        if (itemAmbig) {
          byLevelAmbig[item.level.name] =
              (byLevelAmbig[item.level.name] ?? 0) + 1;
        }

        // 2. paires d'options indistinguables (géométrie + couleurs)
        for (int i = 0; i < item.options.length; i++) {
          for (int j = i + 1; j < item.options.length; j++) {
            final a = item.options[i], b = item.options[j];
            if (a.isCorrect && b.isCorrect) continue;
            if (congruent(a.polygon, b.polygon, relTol: 0.04) &&
                histoDiff(histo(a), histo(b)) < 0.08) {
              if (a.isCorrect != b.isCorrect) {
                dupTrueTrap++;
              } else {
                dupTrapTrap++;
              }
            }
          }
        }

        // 3. wrongColors réduit à une discrimination de taille
        bool itemWcUni = false;
        for (final d in traps) {
          if (d.trapKind != TrapKind.wrongColors) continue;
          final hd = histo(d);
          if (hd.length == 1) {
            final color = hd.keys.first;
            for (final t in trues) {
              final ht = histo(t);
              if (ht.length == 1 && ht.keys.first == color) {
                wrongColorsUniReduced++;
                itemWcUni = true;
                break;
              }
            }
          }
        }
        if (itemWcUni) {
          byLevelWcUni[item.level.name] =
              (byLevelWcUni[item.level.name] ?? 0) + 1;
        }
        if ((itemAmbig || itemWcUni) && item.index <= 7) earlyProblemItems++;

        // 4. slivers affichés
        bool sliverHere = false;
        for (final o in item.options) {
          final bb = o.displayPolygon.bbox();
          final ratio = math.min(bb.width, bb.height) /
              math.max(math.max(bb.width, bb.height), 1e-9);
          if (ratio < 0.16) {
            sliverOptions++;
            sliverHere = true;
          }
        }
        if (sliverHere) itemsWithSliver++;

        // 5. palette perceptuellement proche / daltonisme
        bool close = false, cvd = false;
        for (int i = 0; i < item.palette.length; i++) {
          for (int j = i + 1; j < item.palette.length; j++) {
            if (rgbDist(item.palette[i], item.palette[j]) < 100) close = true;
            if (isCvdConfusable(item.palette[i], item.palette[j])) cvd = true;
          }
        }
        if (close) itemsWithClosePalette++;
        if (cvd) itemsWithCvdPair++;
      }
    }

    // ignore: avoid_print
    print('''
==== MÉTRIQUES ($items items, 60 seeds) ====
pièges par type            : $trapCounts
géom. quasi vraie (≤6%)    : $ambiguousGeom
paires identiques vrai/piège: $dupTrueTrap
paires identiques piège/piège: $dupTrapTrap
wrongColors→discrim. taille : $wrongColorsUniReduced
options "sliver" (<16%)     : $sliverOptions (items concernés: $itemsWithSliver)
items palette proche (<100) : $itemsWithClosePalette
items palette daltonien     : $itemsWithCvdPair
ambig. par type de piège    : $ambigByKind
items ambigus par niveau    : $byLevelAmbig
wc→taille par niveau        : $byLevelWcUni
items 1-7 problématiques    : $earlyProblemItems (sur ${60 * 7})
exemples: ${examples.join(' | ')}
''');

    // ---- Verrouillage : les problèmes de l'audit 2026-07-02 ne doivent
    // jamais réapparaître (chaque compteur correspond à un correctif).
    expect(ambiguousGeom, 0,
        reason: 'piège quasi congruent à une vraie pièce (gardes '
            'kPerceptualTol) — exemples : ${examples.join(' | ')}');
    expect(dupTrueTrap, 0,
        reason: 'paire vraie/piège visuellement identique');
    expect(wrongColorsUniReduced, 0,
        reason: 'wrongColors réduit à une discrimination de taille');
    expect(sliverOptions, 0, reason: 'option plus fine que 16 % de sa bbox');
    expect(itemsWithClosePalette, 0,
        reason: 'palette avec paire de couleurs trop proches (< 100 RGB)');
    expect(itemsWithCvdPair, 0,
        reason: 'palette confusable pour un daltonien rouge-vert');
  });
}

void _tileBg(Canvas canvas, Offset origin, Color border) {
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(origin.dx, origin.dy, tile, tile),
    const Radius.circular(10),
  );
  canvas.drawRRect(rect, Paint()..color = const Color(0xFFE8EAF0));
  canvas.drawRRect(
    rect,
    Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
}

void _drawRegions(Canvas canvas, Polygon outline, List<ColoredRegion> regions,
    List<Color> palette, Rect zone,
    {bool fit = false, double? unitsPerTile}) {
  if (outline.vertices.length < 3) return;
  final bb = outline.bbox();
  const pad = 0.08;
  double scale;
  if (fit || unitsPerTile == null) {
    final usable = zone.width * (1 - 2 * pad);
    scale = bb.width > 0 && bb.height > 0
        ? math.min(usable / bb.width, usable / bb.height)
        : 1.0;
  } else {
    scale = zone.width * (1 - 2 * pad) / unitsPerTile;
  }
  final offX =
      zone.left + (zone.width - bb.width * scale) / 2 - bb.left * scale;
  final offY =
      zone.top + (zone.height - bb.height * scale) / 2 - bb.top * scale;

  Path mk(Polygon p) {
    final path = Path()
      ..moveTo(p.vertices[0].dx * scale + offX, p.vertices[0].dy * scale + offY);
    for (int i = 1; i < p.vertices.length; i++) {
      path.lineTo(p.vertices[i].dx * scale + offX,
          p.vertices[i].dy * scale + offY);
    }
    path.close();
    return path;
  }

  for (final r in regions) {
    if (r.polygon.vertices.length < 3) continue;
    final color = palette[r.colorIndex % palette.length];
    canvas.drawPath(mk(r.polygon), Paint()..color = color);
    canvas.drawPath(
        mk(r.polygon),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }
  canvas.drawPath(
    mk(outline),
    Paint()
      ..color = const Color(0xFF30343E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
}
