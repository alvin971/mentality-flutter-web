import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/data_collection/widgets/adaptive_reading_text.dart';

/// Texte long représentatif du pire cas du corpus (~150 mots, EN-GB).
const _longText =
    'There is a particular smell that belongs to old libraries and to nowhere '
    'else, a blend of aged paper, leather bindings, and the faint mustiness of '
    'rooms that have been kept just slightly too cool for comfort. Scientists '
    'have traced it to a cocktail of compounds released as paper breaks down '
    'over time, including vanilla-scented aldehydes and the sharper notes of '
    'organic acids. Yet for most people who grew up spending Saturday mornings '
    'among the stacks, the chemistry matters far less than the memory the smell '
    'unlocks. It speaks of wet coats hung over chair backs, of pencils chewed at '
    'the end, of the particular quiet that settles when a roomful of people are '
    'each absorbed in a separate world, every page turning a little world apart.';

/// Tailles de téléphones représentatives (logical pixels).
const _phoneSizes = <Size>[
  Size(320, 568), // iPhone SE 1 / très petits Android (pire cas)
  Size(360, 640),
  Size(375, 812), // design de référence
  Size(414, 896),
];

/// Reproduit la zone réelle : header + Card(Expanded) + barre de contrôles,
/// avec [AdaptiveReadingText] dans l'Expanded de la carte.
Widget _wrapInLayout(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 56), // header de progression simulé
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Titre'),
                          const SizedBox(height: 8),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56), // barre de contrôles simulée
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Boîte de taille fixe pour tester directement les bornes de l'algo.
Widget _wrapInBox(Widget child, {required double width, required double height}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  );
}

AdaptiveReadingText _widget(String text) => AdaptiveReadingText(
      text: text,
      textColor: Colors.black,
      surfaceColor: Colors.white,
      minFontSp: 12,
      maxFontSp: 30,
      height: 1.5,
    );

void main() {
  group('AdaptiveReadingText', () {
    testWidgets('texte court + grande boîte → statique à maxFont, sans scroll',
        (tester) async {
      await tester.pumpWidget(
        _wrapInBox(_widget('Bonjour le monde.'),
            width: 600, height: 1000),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Pas de fallback scroll.
      expect(find.byType(SingleChildScrollView), findsNothing);
      // Police = plafond demandé.
      final body = tester.widget<Text>(find.text('Bonjour le monde.'));
      expect(body.style?.fontSize, 30);
    });

    testWidgets(
        'texte long + boîte minuscule → fallback scroll à minFont, sans overflow',
        (tester) async {
      await tester.pumpWidget(
        _wrapInBox(_widget(_longText), width: 300, height: 90),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Indicateur de scroll présent.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // Police = plancher lisible.
      final body = tester.widget<Text>(find.text(_longText));
      expect(body.style?.fontSize, 12);
    });

    testWidgets('police choisie toujours dans [min, max]', (tester) async {
      await tester.pumpWidget(
        _wrapInBox(_widget(_longText), width: 360, height: 400),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final body = tester.widget<Text>(find.text(_longText));
      final fs = body.style!.fontSize!;
      expect(fs, greaterThanOrEqualTo(12));
      expect(fs, lessThanOrEqualTo(30));
    });

    testWidgets('aucun overflow sur toutes les tailles de téléphone',
        (tester) async {
      for (final size in _phoneSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_wrapInLayout(_widget(_longText)));
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull,
            reason: 'Overflow à ${size.width}x${size.height}');

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  });
}
