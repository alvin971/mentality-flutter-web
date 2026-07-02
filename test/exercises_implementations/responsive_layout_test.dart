import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';

import 'package:mentality/features/exercises_implementations/arithmetic/presentation/pages/arithmetic_test_page.dart';
import 'package:mentality/features/exercises_implementations/coding/presentation/pages/coding_test_page.dart';
import 'package:mentality/features/exercises_implementations/cubes/presentation/pages/cubes_test_page.dart';
import 'package:mentality/features/exercises_implementations/digit_span/presentation/pages/digit_span_test_page.dart';
import 'package:mentality/features/exercises_implementations/figure_weights/presentation/pages/figure_weights_test_page.dart';
import 'package:mentality/features/exercises_implementations/information/presentation/pages/information_test_page.dart';
import 'package:mentality/features/exercises_implementations/matrices/presentation/pages/matrices_test_page.dart';
import 'package:mentality/features/exercises_implementations/picture_span/presentation/pages/picture_span_test_page.dart';
import 'package:mentality/features/exercises_implementations/similarities/presentation/pages/similarities_test_page.dart';
import 'package:mentality/features/exercises_implementations/symbol_search/presentation/pages/symbol_search_test_page.dart';
import 'package:mentality/features/exercises_implementations/visual_puzzles/presentation/pages/visual_puzzles_test_page.dart';
import 'package:mentality/features/exercises_implementations/vocabulary/presentation/pages/vocabulary_test_page.dart';

/// Tailles de téléphones représentatives (logical pixels) :
/// du plus petit (iPhone SE 1 / petits Android) au plus grand.
const _phoneSizes = <Size>[
  Size(320, 568), // iPhone SE 1ʳᵉ gén / très petits Android
  Size(360, 640), // Android compact très répandu
  Size(375, 667), // iPhone 6/7/8
  Size(375, 812), // iPhone X/11 Pro (design de référence)
  Size(414, 896), // iPhone 11 / XR
  Size(412, 732), // Pixel / Galaxy
];

Widget _wrap(Widget page) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      // Les pages utilisent context.l10n : on fournit les delegates et on
      // épingle le français pour que les libellés testés ("Valider",
      // "Commencer") restent ceux d'avant l'internationalisation.
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

/// Pompe [page] à chaque taille de téléphone et échoue si un overflow
/// (RenderFlex/RenderConstrainedBox) est levé pendant le layout.
Future<void> _expectNoOverflow(
  WidgetTester tester,
  Widget Function() pageBuilder, {
  Duration settle = const Duration(seconds: 2),
}) async {
  for (final size in _phoneSizes) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(pageBuilder()));
    // Quelques frames pour les timers/animations de la page.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(settle);

    final exception = tester.takeException();
    expect(exception, isNull,
        reason: 'Overflow/exception à la taille ${size.width}x${size.height} '
            'pour ${pageBuilder().runtimeType} : $exception');

    // Démonte la page (annule les timers) avant la taille suivante.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  group('Responsivité — aucun overflow sur les tailles de téléphone', () {
    testWidgets('Matrices', (tester) async {
      await _expectNoOverflow(tester, () => const MatricesTestPage());
    });

    testWidgets('Cubes', (tester) async {
      await _expectNoOverflow(tester, () => const CubesTestPage());
    });

    testWidgets('Balances Quantitatives', (tester) async {
      await _expectNoOverflow(tester, () => const FigureWeightsTestPage());
    });

    testWidgets('Puzzles Visuels', (tester) async {
      await _expectNoOverflow(tester, () => const VisualPuzzlesTestPage());
    });

    testWidgets('Vocabulaire', (tester) async {
      await _expectNoOverflow(tester, () => const VocabularyTestPage());
    });

    testWidgets('Similitudes', (tester) async {
      await _expectNoOverflow(tester, () => const SimilaritiesTestPage());
    });

    testWidgets('Information', (tester) async {
      await _expectNoOverflow(tester, () => const InformationTestPage());
    });

    testWidgets('Arithmétique (intro)', (tester) async {
      await _expectNoOverflow(tester, () => const ArithmeticTestPage());
    });

    testWidgets('Mémoire des Chiffres (intro)', (tester) async {
      await _expectNoOverflow(tester, () => const DigitSpanTestPage());
    });

    testWidgets('Mémoire des Images (intro)', (tester) async {
      await _expectNoOverflow(tester, () => const PictureSpanTestPage());
    });

    testWidgets('Recherche de Symboles (intro)', (tester) async {
      await _expectNoOverflow(tester, () => const SymbolSearchTestPage());
    });

    testWidgets('Code (intro)', (tester) async {
      await _expectNoOverflow(tester, () => const CodingTestPage());
    });
  });

  group('Responsivité — le bouton de validation est visible sans scroll', () {
    Future<void> expectValidateVisible(
      WidgetTester tester,
      Widget page,
      String label,
    ) async {
      tester.view.physicalSize = const Size(320, 568); // pire cas
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(page));
      await tester.pump(const Duration(milliseconds: 100));

      final finder = find.textContaining(label, findRichText: true);
      expect(finder, findsWidgets,
          reason: 'Bouton "$label" introuvable à l\'écran');
      // Le bouton doit être entièrement dans le viewport (pas sous le pli).
      final rect = tester.getRect(finder.first);
      expect(rect.bottom, lessThanOrEqualTo(568),
          reason: 'Bouton "$label" sous le pli (bottom=${rect.bottom})');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('Matrices — Valider visible', (tester) async {
      await expectValidateVisible(
          tester, const MatricesTestPage(), 'Valider');
    });

    testWidgets('Balances — Valider visible', (tester) async {
      await expectValidateVisible(
          tester, const FigureWeightsTestPage(), 'Valider');
    });

    // Vocabulaire et Similitudes s'ouvrent désormais sur l'écran
    // d'entraînement (verbal, sans validation notée) : le bouton primaire
    // visible sans scroll est « Commencer le test ».
    testWidgets('Vocabulaire (entraînement) — Commencer visible',
        (tester) async {
      await expectValidateVisible(
          tester, const VocabularyTestPage(), 'Commencer');
    });

    testWidgets('Similitudes (entraînement) — Commencer visible',
        (tester) async {
      await expectValidateVisible(
          tester, const SimilaritiesTestPage(), 'Commencer');
    });

    testWidgets('Information — Valider visible', (tester) async {
      await expectValidateVisible(
          tester, const InformationTestPage(), 'Valider');
    });

    testWidgets('Cubes — Valider visible', (tester) async {
      await expectValidateVisible(tester, const CubesTestPage(), 'Valider');
    });

    testWidgets('Intro Mémoire des Chiffres — Commencer visible',
        (tester) async {
      await expectValidateVisible(
          tester, const DigitSpanTestPage(), 'Commencer');
    });

    testWidgets('Intro Code — Commencer visible', (tester) async {
      await expectValidateVisible(tester, const CodingTestPage(), 'Commencer');
    });
  });
}
