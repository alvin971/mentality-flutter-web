// Rendu WIDGET-FIDÈLE des items VP en cartes PNG pour audit visuel.
//
// Usage audit (1 PNG par item + sidecar JSON par seed) :
//   flutter test test/exercises_implementations/visual_puzzles/render_item_cards_audit_test.dart \
//     --dart-define=VP_AUDIT_SEEDS=1,2,3 \
//     --dart-define=VP_AUDIT_OUT=/chemin/absolu/de/sortie
//
// Sans dart-define : smoke-test (seed 7 dans un répertoire temporaire) —
// le fichier reste un test vert permanent de la chaîne de capture.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/domain/puzzle_generator.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_piece_widget.dart';

import 'support/vp_audit_capture.dart';

const _seedsEnv = String.fromEnvironment('VP_AUDIT_SEEDS');
const _outEnv = String.fromEnvironment('VP_AUDIT_OUT');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadRealFonts);

  testWidgets('cartes item widget-fidèles (audit visuel, env-gated)',
      (tester) async {
    final seeds = _seedsEnv.isEmpty
        ? const [7]
        : _seedsEnv.split(',').map((s) => int.parse(s.trim())).toList();
    final outDir = _outEnv.isEmpty
        ? Directory.systemTemp.createTempSync('vp_cards_').path
        : _outEnv;
    Directory(outDir).createSync(recursive: true);

    await tester.binding.setSurfaceSize(const Size(760, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var pngCount = 0;
    await guardedFontZone(() async {
    for (final seed in seeds) {
      final items = PuzzleGenerator(seed: seed).generateComplete26Items();
      final sidecar = <Map<String, dynamic>>[];
      final seedTag = 'seed${seed.toString().padLeft(3, '0')}';

      for (final item in items) {
        final key = GlobalKey();
        await tester.pumpWidget(wrapCard(AuditCard(item: item, captureKey: key)));
        await tester.pump(const Duration(milliseconds: 20));

        final ppu = PuzzlePieceWidget.pixelsPerUnit(
            kAuditTileSide, item.maxPieceExtent);
        final png = '$outDir/${seedTag}_item'
            '${item.index.toString().padLeft(2, '0')}_palier${item.palier}.png';
        await tester.runAsync(() async {
          final img = await captureCard(key);
          await compositeAndSave(
              card: img, item: item, seed: seed, ppu: ppu, outPath: png);
        });
        pngCount++;

        sidecar.add(itemMetadata(item, seed: seed));
        // Démontage entre items (aucun timer/état ne doit fuir).
        await tester.pumpWidget(const SizedBox.shrink());
      }

      File('$outDir/${seedTag}_meta.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(sidecar));
      // ignore: avoid_print
      print('VP_AUDIT $seedTag → 26 PNG + sidecar dans $outDir');
    }
    });

    expect(unexpectedZoneErrors, isEmpty,
        reason: 'seul le bruit réseau google_fonts est toléré');
    final written = Directory(outDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .length;
    expect(written, pngCount,
        reason: 'chaque item rendu doit produire son PNG');
    expect(pngCount, 26 * seeds.length);
  });
}
