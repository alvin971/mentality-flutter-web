// Outil de validation VISUELLE (pas un test d'assertion) :
// génère des items représentatifs et les rend en PNG dans /tmp/.
//
//   flutter test test/exercises_implementations/visual_puzzles/render_items_preview.dart
//
// Sortie : /tmp/vp_items_preview.png — une ligne par item :
// [cible] [option 1..6] (vraies pièces entourées en vert pour le debug).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';

const double tile = 150;
const double gap = 10;

void main() {
  testWidgets('rend des items représentatifs en PNG', (tester) async {
    await tester.runAsync(() async {
      final gen = PuzzleGenerator(seed: 2026);
      final all = gen.generateComplete26Items();
      final picks = [0, 3, 6, 10, 13, 16, 19, 22, 25];
      final items = [for (final i in picks) all[i]];

      final width = gap + 7 * (tile + gap);
      final height = gap + items.length * (tile + gap + 24);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xFF14161C),
      );

      double y = gap;
      for (final item in items) {
        _drawLabel(
          canvas,
          'item ${item.index}  ${item.level.name}  ${item.baseShape.name}  '
          '${item.cutStrategy.name}  t=${item.timeLimitSeconds}s',
          Offset(gap, y),
        );
        y += 24;
        // Cible
        _drawTile(canvas, Offset(gap, y), border: const Color(0xFF8A7BFF));
        _drawPolygon(
          canvas,
          item.targetPolygon,
          Rect.fromLTWH(gap, y, tile, tile),
          fit: true,
        );
        // Options
        for (int i = 0; i < item.options.length; i++) {
          final o = item.options[i];
          final x = gap + (i + 1) * (tile + gap);
          _drawTile(
            canvas,
            Offset(x, y),
            border: o.isCorrect
                ? const Color(0xFF4CAF50)
                : const Color(0xFF3A3F4D),
          );
          _drawPolygon(
            canvas,
            o.displayPolygon,
            Rect.fromLTWH(x, y, tile, tile),
            unitsPerTile: item.maxPieceExtent,
          );
          _drawLabel(canvas, '${i + 1}${o.isCorrect ? '' : ' ✕'}',
              Offset(x + 6, y + 4));
        }
        y += tile + gap;
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final file = File('/tmp/vp_items_preview.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      // ignore: avoid_print
      print('PNG écrit : ${file.path} (${bytes.lengthInBytes} octets)');
    });
  });
}

void _drawTile(Canvas canvas, Offset origin, {required Color border}) {
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(origin.dx, origin.dy, tile, tile),
    const Radius.circular(10),
  );
  canvas.drawRRect(rect, Paint()..color = const Color(0xFF1E222C));
  canvas.drawRRect(
    rect,
    Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

void _drawPolygon(Canvas canvas, Polygon polygon, Rect zone,
    {bool fit = false, double? unitsPerTile}) {
  if (polygon.vertices.length < 3) return;
  final bb = polygon.bbox();
  const pad = 0.08;
  double scale;
  if (fit || unitsPerTile == null) {
    final usable = zone.width * (1 - 2 * pad);
    scale = bb.width > 0 && bb.height > 0
        ? (usable / bb.width < usable / bb.height
            ? usable / bb.width
            : usable / bb.height)
        : 1.0;
  } else {
    scale = zone.width * (1 - 2 * pad) / unitsPerTile;
  }
  final offX = zone.left + (zone.width - bb.width * scale) / 2 - bb.left * scale;
  final offY = zone.top + (zone.height - bb.height * scale) / 2 - bb.top * scale;

  final path = Path()
    ..moveTo(polygon.vertices[0].dx * scale + offX,
        polygon.vertices[0].dy * scale + offY);
  for (int i = 1; i < polygon.vertices.length; i++) {
    path.lineTo(polygon.vertices[i].dx * scale + offX,
        polygon.vertices[i].dy * scale + offY);
  }
  path.close();

  canvas.drawPath(path, Paint()..color = const Color(0x55708BFF));
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF9DB4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

void _drawLabel(Canvas canvas, String text, Offset at) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Color(0xFFB9C2D8), fontSize: 13),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at);
}
