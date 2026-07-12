// Flux complet des Puzzles Visuels après la refonte 2026-07-12 :
// démo (feedback pédagogique) → écran « Prêt ? » (chrono à l'appui) →
// item 1 (feedback NEUTRE, journal par item écrit dans mentality_keep).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/widgets/puzzle_piece_widget.dart';
import 'package:mentality/services/data_collection_service.dart';
import 'package:mentality/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget page) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );
}

/// Sélectionne les 3 vraies pièces affichées puis valide.
Future<void> _solveCurrentItem(WidgetTester tester) async {
  final pieces = tester
      .widgetList<PuzzlePieceWidget>(find.byType(PuzzlePieceWidget))
      .toList();
  expect(pieces.length, 6);
  // Cibler par id (l'arbre est reconstruit à chaque sélection : les
  // instances capturées deviennent obsolètes après un pump).
  final correctIds =
      pieces.where((w) => w.piece.isCorrect).map((w) => w.piece.id).toList();
  for (final id in correctIds) {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is PuzzlePieceWidget && w.piece.id == id));
    await tester.pump();
  }
  await tester.tap(find.text('Valider'));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.createTempSync('vp_flow_').path);
    await DataCollectionService.instance.initialize();
  });

  testWidgets('démo → Prêt → item 1 : feedback, chrono et journal', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final svc = DataCollectionService.instance;
    final baseline = svc.cognitiveRecordCount;

    await tester.pumpWidget(_wrap(const VisualPuzzlesTestPage()));
    await tester.pump(const Duration(milliseconds: 100));

    // --- Démo : pas de chrono, feedback pédagogique complet.
    expect(find.text('DÉMONSTRATION'), findsOneWidget);
    await _solveCurrentItem(tester);
    // Les 3 bonnes pièces sont révélées (bordures vertes) EN DÉMO SEULEMENT.
    final demoRevealed = tester
        .widgetList<PuzzlePieceWidget>(find.byType(PuzzlePieceWidget))
        .where((w) => w.showCorrect)
        .length;
    expect(demoRevealed, 3, reason: 'la démo doit garder son feedback');
    // La démo n'écrit RIEN dans le journal.
    expect(svc.cognitiveRecordCount, baseline);

    // --- Écran « Prêt ? » : l'item 1 n'est pas affiché, pas de chrono.
    await tester.tap(find.text('Commencer le test'));
    await tester.pump();
    expect(find.text('Prêt ?'), findsOneWidget);
    expect(find.byType(PuzzlePieceWidget), findsNothing,
        reason: 'aucune prévisualisation gratuite de l\'item 1');

    // --- Item 1 : chrono affiché, résolution, feedback NEUTRE, journal.
    await tester.tap(find.text('Lancer le test'));
    await tester.pump();
    expect(find.text('00:20'), findsOneWidget,
        reason: 'le chrono de l\'item 1 (20 s) démarre au bouton');
    await _solveCurrentItem(tester);

    // Aucune révélation des bonnes pièces pendant le test réel.
    final realRevealed = tester
        .widgetList<PuzzlePieceWidget>(find.byType(PuzzlePieceWidget))
        .where((w) => w.showCorrect || w.showIncorrect)
        .length;
    expect(realRevealed, 0,
        reason: 'le test réel ne doit révéler AUCUNE réponse');
    expect(find.text('Réponse enregistrée'), findsOneWidget);
    expect(find.text('Correct'), findsNothing);

    // Journal : un enregistrement vp_item complet.
    expect(svc.cognitiveRecordCount, baseline + 1);
    final records = await svc
        .getCognitiveSessionData(SessionManager.instance.currentSessionId);
    final itemRecord = records.lastWhere((r) => r['type'] == 'vp_item');
    expect(itemRecord['item_index'], 1);
    expect(itemRecord['palier'], 1);
    expect(itemRecord['is_correct'], true);
    expect(itemRecord['auto_submit'], false);
    expect(itemRecord['seed'], isA<int>());
    expect(itemRecord['rt_ms'], isA<int>());
    expect((itemRecord['options'] as List).length, 6);

    // L'item 2 s'enchaîne après le bref délai inter-item.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('00:20'), findsOneWidget, reason: 'item 2 démarré');

    // Démontage propre (timers annulés par dispose).
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
