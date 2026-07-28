// La place du jeu dans une journée — l'ordre du plan produit, et sa limite.
//
// Le plan fixe l'enchaînement d'une journée : révélation, PUIS jeu, PUIS
// instrument. Mais il pose aussi qu'« aucune activité n'en conditionne une
// autre ». Les deux règles se contrediraient si le jeu barrait la route au
// questionnaire — ce fichier vérifie qu'il ne le fait pas :
//
// · le jeu s'intercale la PREMIÈRE fois seulement, sinon un jeu déclaré
//   facultatif redeviendrait un péage quotidien ;
// · le refuser (« Plus tard ») laisse la journée continuer ;
// · sa carte reste sous la journée, pour le rejouer sans retraverser la
//   révélation.
//
// Aucun de ces comportements ne se voit sur une capture d'écran.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/presentation/game_registry.dart';
import 'package:mentality/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';
import 'package:mentality/features/waiting_event/reveals/domain/services/reveal_source.dart';
import 'package:mentality/features/waiting_event/reveals/presentation/pages/reveal_page.dart';
import 'package:mentality/features/waiting_event/stroop/presentation/pages/stroop_game_page.dart';
import 'package:mentality/services/session_history_service.dart';

class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async =>
      data[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

/// Écran bouchon : le vrai Stroop est testé ailleurs. Ce qui se vérifie ici,
/// c'est QUAND le hub l'ouvre, pas ce qu'il contient.
class PageJeuFactice extends StatelessWidget {
  const PageJeuFactice({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('sortir du jeu'),
          ),
        ),
      );
}

/// Registre de test : un seul jeu livré, celui du jour 2, dont on pilote
/// l'historique.
class RegistreFactice {
  RegistreFactice({this.dejaJoue = false});

  bool dejaJoue;
  int lectures = 0;

  EventGame? resolve(GameKind kind) => kind == GameKind.stroop
      ? EventGame(
          title: (l10n) => l10n.weStroopTitle,
          open: (_) => const PageJeuFactice(),
          hasPlayed: () async {
            lectures++;
            return dejaJoue;
          },
        )
      : null;
}

SessionHistoryEntry bilan() => SessionHistoryEntry(
      id: 's1',
      account: 'passe',
      date: DateTime(2026, 7, 20),
      ageInMonths: 372,
      fsiq: 112,
      vci: 121,
      vsi: 104,
      fri: 115,
      wmi: 98,
      psi: 109,
      classification: 'Moyen supérieur',
    );

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget host(
  int serverDayIndex, {
  required SelfEstimateStore estimation,
  required EventGameResolver gameFor,
  Key? key,
}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        key: key,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DayHubPage(
          serverDayIndex: serverDayIndex,
          gameFor: gameFor,
          revealSource: RevealSource(load: () async => [bilan()]),
          selfEstimateStore: estimation,
        ),
      ),
    );

/// Le hub DÉFILE : sans `ensureVisible`, un appui sur une carte basse ne
/// touche rien, et le test passerait pour la mauvaise raison.
Future<void> tapTexte(WidgetTester tester, String texte) async {
  await tester.ensureVisible(find.text(texte));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texte), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  late StoreMemoire disque;
  late SelfEstimateStore estimation;
  late RegistreFactice registre;

  setUp(() async {
    disque = StoreMemoire();
    estimation = SelfEstimateStore(disque);
    // L'auto-estimation est réglée : elle passe avant TOUTE révélation, et ce
    // n'est pas ce que ce fichier vérifie.
    await estimation.record(100);
    registre = RegistreFactice();
  });

  group('la carte du jeu', () {
    testWidgets('une journée à jeu livré porte sa carte', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      expect(find.text('Couleurs contrariées'), findsOneWidget);
      expect(find.text('Jeu du jour · 2 minutes · rejouable'), findsOneWidget);
    });

    testWidgets('elle ouvre le jeu sans passer par la révélation',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'Couleurs contrariées');

      expect(find.byType(PageJeuFactice), findsOneWidget);
      expect(find.byType(RevealPage), findsNothing,
          reason: 'rejouer ne doit pas imposer de relire sa vitesse');
    });

    testWidgets('elle reste là une fois le jeu joué — c\'est un jeu, pas une '
        'question posée une fois', (tester) async {
      registre.dejaJoue = true;
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      expect(find.text('Couleurs contrariées'), findsOneWidget);
    });

    testWidgets('les jeux non livrés n\'ont pas de carte', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(9, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      // Les jours 4, 5 et 6 annoncent leur jeu dans le sous-titre…
      expect(find.textContaining('tolérance au délai'), findsOneWidget);
      // …mais une seule carte de jeu existe : celle du jour 2.
      expect(find.text('Jeu du jour · 2 minutes · rejouable'), findsOneWidget);
    });

    testWidgets('une journée verrouillée n\'expose pas son jeu',
        (tester) async {
      ecranTelephone(tester);
      // Jour serveur 1 : le jour 2 est encore à venir.
      await tester.pumpWidget(
          host(1, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      expect(find.text('Couleurs contrariées'), findsNothing,
          reason: 'une carte tactile sous une journée verrouillée ouvrirait '
              'du contenu en avance');
    });
  });

  group('l\'ordre de la journée', () {
    testWidgets('la révélation enchaîne sur le jeu, la première fois',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'J2');
      expect(find.byType(RevealPage), findsOneWidget);

      await tapTexte(tester, 'Continuer');

      expect(find.byType(PageJeuFactice), findsOneWidget,
          reason: 'l\'ordre du programme : révélation, puis jeu, puis '
              'activité');
    });

    testWidgets('une fois joué, il ne s\'intercale plus', (tester) async {
      registre.dejaJoue = true;
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'J2');
      await tapTexte(tester, 'Continuer');

      expect(find.byType(PageJeuFactice), findsNothing,
          reason: 'se le voir reproposer à chaque ouverture le rendrait '
              'obligatoire en pratique');
      expect(find.text('En préparation'), findsOneWidget,
          reason: 'la journée passe directement à son activité');
    });

    testWidgets('quitter le jeu n\'arrête pas la journée', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'J2');
      await tapTexte(tester, 'Continuer');
      await tapTexte(tester, 'sortir du jeu');

      expect(find.text('En préparation'), findsOneWidget,
          reason: 'aucune activité n\'en conditionne une autre — refuser le '
              'jeu ne doit pas fermer la journée');
    });

    testWidgets('une journée sans jeu n\'interroge même pas le registre',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(3, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'J1');
      await tapTexte(tester, 'Continuer');

      expect(registre.lectures, 0);
      expect(find.byType(PageJeuFactice), findsNothing);
    });

    testWidgets('le jour 7, sans révélation ni jeu, ouvre droit son activité',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(
          host(9, estimation: estimation, gameFor: registre.resolve));
      await tester.pumpAndSettle();

      await tapTexte(tester, 'J7');

      expect(find.text('En préparation'), findsOneWidget);
    });
  });

  testWidgets('le registre de production ne livre que le Stroop',
      (tester) async {
    expect(GameRegistry.forGame(GameKind.stroop), isNotNull);
    for (final kind in [
      GameKind.delayChoice,
      GameKind.timeEstimation,
      GameKind.confidenceCalibration,
    ]) {
      expect(GameRegistry.forGame(kind), isNull,
          reason: '$kind n\'est pas encore écrit — lots H2 à H5');
    }

    // Et il ouvre bien le vrai écran.
    ecranTelephone(tester);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: GameRegistry.forGame(GameKind.stroop)!.open,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(StroopGamePage), findsOneWidget);
  });
}
