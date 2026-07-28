// Rendu du hub de l'événement.
//
// Les deux autres fichiers du dossier vérifient les RÈGLES (le programme, les
// statuts) sans jamais construire d'écran. Ce fichier-ci monte la vraie page :
// il attrape ce qu'aucune règle ne peut voir — une clé de traduction absente,
// un `switch` non exhaustif, un débordement de mise en page.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart';

/// Cale le banc d'essai sur un écran de téléphone.
///
/// Sans cela la surface de test fait 800 × 600, et ScreenUtilInit — calé sur
/// 375 × 812 — multiplie toutes les tailles `.sp` par plus de deux : l'AppBar
/// déborde et chaque test échoue pour une raison qui n'existe sur aucun
/// appareil réel.
void _ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Hôte réaliste : ScreenUtilInit et les délégués de traduction actifs,
/// comme dans l'app.
Widget _host(int serverDayIndex, {Locale locale = const Locale('fr')}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DayHubPage(serverDayIndex: serverDayIndex),
      ),
    );

void main() {
  testWidgets('les 8 journées sont listées, quel que soit le jour courant',
      (tester) async {
    _ecranTelephone(tester);
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    for (var d = 1; d <= 8; d++) {
      expect(find.text('J$d'), findsOneWidget, reason: 'journée $d absente');
    }
  });

  testWidgets('le titre annonce le jour serveur', (tester) async {
    _ecranTelephone(tester);
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();
    expect(find.text('Jour 3'), findsOneWidget);
  });

  testWidgets('une fois débloqué (9), le titre change et rien n\'est verrouillé',
      (tester) async {
    _ecranTelephone(tester);
    await tester.pumpWidget(_host(9));
    await tester.pumpAndSettle();

    expect(find.text('Programme terminé'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing,
        reason: 'l\'événement se termine, il ne se ferme pas');
  });

  testWidgets('exactement une journée « Aujourd\'hui », le reste réparti',
      (tester) async {
    _ecranTelephone(tester);
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('À rattraper'), findsNWidgets(2), reason: 'J1 et J2');
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(5),
        reason: 'J4 à J8 restent à venir');
  });

  testWidgets('une journée à venir ne s\'ouvre pas au toucher', (tester) async {
    _ecranTelephone(tester);
    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('J8'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('En préparation'), findsNothing,
        reason: 'aucune action ne doit ouvrir un jour en avance');
  });

  testWidgets('une journée sans révélation s\'ouvre sur une annonce honnête',
      (tester) async {
    _ecranTelephone(tester);
    // Le jour 7 est le SEUL sans révélation (jour vedette, sans concurrence) :
    // c'est donc le seul dont l'ouverture mène directement à l'activité. Les
    // autres passent d'abord par leur révélation — l'ordre du programme est
    // vérifié dans day_hub_reveal_flow_test.dart.
    await tester.pumpWidget(_host(7));
    await tester.pumpAndSettle();

    // Le hub défile : la septième carte est sous la ligne de flottaison, et
    // un tap sans défilement préalable ne toucherait rien du tout.
    await tester.ensureVisible(find.text('J7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J7'));
    await tester.pumpAndSettle();

    expect(find.text('En préparation'), findsOneWidget);
  });

  testWidgets('rendu identique dans les 6 langues, sans clé manquante',
      (tester) async {
    _ecranTelephone(tester);
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(_host(4, locale: locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'échec de rendu en $locale');
      expect(find.text('J4'), findsOneWidget, reason: 'en $locale');
    }
  });
}
