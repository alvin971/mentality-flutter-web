// L'ORDRE d'une journée — la règle que rien à l'écran ne trahirait.
//
// Le plan produit fixe une séquence : au jour 1 l'auto-estimation du QI passe
// AVANT toute révélation, puis vient la révélation, puis l'activité. L'ordre
// n'est pas une préférence de mise en scène : une estimation donnée après
// avoir lu un premier indice est ancrée par ce chiffre, donc la comparaison du
// jour 8 ne mesure plus rien. Si l'ordre s'inversait, aucun écran ne
// changerait d'apparence — seule la donnée deviendrait fausse.
//
// D'où ce fichier : il ne vérifie pas des pixels, il vérifie un enchaînement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_schedule.dart';
import 'package:mentality/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';
import 'package:mentality/features/waiting_event/reveals/domain/models/reveal_data.dart';
import 'package:mentality/features/waiting_event/reveals/domain/services/reveal_source.dart';
import 'package:mentality/features/waiting_event/reveals/presentation/pages/reveal_page.dart';
import 'package:mentality/features/waiting_event/reveals/presentation/pages/self_estimate_page.dart';
import 'package:mentality/services/session_history_service.dart';

class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async => data[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

/// Stockage lent : la latence est ce qui ouvre la fenêtre du double appui.
class StoreLent implements EventAnswerStore {
  StoreLent(this.delai);

  final Duration delai;
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async {
    await Future<void>.delayed(delai);
    return data[moduleId];
  }

  @override
  Future<void> save(QAnswerSet answers) async {
    await Future<void>.delayed(delai);
    data[answers.moduleId] = answers;
  }

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

/// Stockage qui refuse d'écrire.
class StorePanne implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async =>
      throw StateError('disque indisponible');

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
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
  RevealSource? source,
  Locale locale = const Locale('fr'),
  Key? key,
}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        key: key,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DayHubPage(
          serverDayIndex: serverDayIndex,
          revealSource: source ?? RevealSource(load: () async => [bilan()]),
          selfEstimateStore: estimation,
        ),
      ),
    );

/// Ouvre la carte d'une journée. Le hub défile — sans `ensureVisible`, un tap
/// sur une carte basse ne touche RIEN, et un test qui attend « rien ne s'ouvre »
/// passerait alors pour la mauvaise raison.
Future<void> ouvrirJour(WidgetTester tester, String jour) async {
  await tester.ensureVisible(find.text(jour));
  await tester.pumpAndSettle();
  await tester.tap(find.text(jour), warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Ressort d'un écran par la flèche de l'AppBar — le chemin « je referme »,
/// distinct du bouton de validation. `pageBack()` ne le trouve pas : la charte
/// Kepler dessine son propre bouton de retour.
Future<void> retourSysteme(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
  await tester.pumpAndSettle();
}

void main() {
  late StoreMemoire disque;
  late SelfEstimateStore estimation;

  setUp(() {
    disque = StoreMemoire();
    estimation = SelfEstimateStore(disque);
  });

  group('jour 1 — l\'estimation passe avant la révélation', () {
    testWidgets('l\'ouverture pose la question, et RIEN d\'autre',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');

      expect(find.byType(SelfEstimatePage), findsOneWidget);
      expect(find.byType(RevealPage), findsNothing,
          reason: 'une révélation ici ancrerait la réponse');
      expect(find.text('121'), findsNothing, reason: 'aucun indice visible');
    });

    testWidgets('la réponse validée débouche sur la révélation verbale',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');

      // Le bouton reste inerte tant que rien n'a bougé : la valeur de départ
      // ne doit pas partir comme une réponse que personne n'a donnée.
      await tester.tap(find.text(l10n.weRvSelfConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(SelfEstimatePage), findsOneWidget,
          reason: 'le bouton devait être inerte avant tout réglage');

      await tester.tap(find.byTooltip(l10n.weRvSelfIncrease));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.weRvSelfConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(RevealPage), findsOneWidget);
      expect(find.text('121'), findsOneWidget, reason: 'le VCI du bilan');
      expect((await estimation.read()).value, 101);
    });

    testWidgets('une estimation déjà donnée n\'est jamais redemandée',
        (tester) async {
      await estimation.record(118);
      ecranTelephone(tester);
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');

      expect(find.byType(SelfEstimatePage), findsNothing);
      expect(find.byType(RevealPage), findsOneWidget);
    });

    testWidgets('un refus clôt la question et laisse passer la révélation',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');
      await tester.tap(find.text(l10n.weRvSelfDecline));
      await tester.pumpAndSettle();

      expect(find.byType(RevealPage), findsOneWidget);
      final lue = await estimation.read();
      expect(lue.declined, isTrue);
      expect(lue.value, isNull, reason: 'un refus n\'invente pas de nombre');
    });

    testWidgets('refermer la question sans y répondre ne révèle rien',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');
      // Retour système : ni réponse, ni refus.
      await retourSysteme(tester);

      expect(find.byType(RevealPage), findsNothing,
          reason: 'sinon la question resterait ouverte APRÈS une révélation, '
              'et sa réponse serait ancrée');
      expect(find.byType(DayHubPage), findsOneWidget);
      expect((await estimation.read()).isSettled, isFalse,
          reason: 'la question reste entière, elle se reposera');
    });
  });

  group('GARDE d\'ancrage : aucune révélation avant l\'estimation', () {
    testWidgets('rattraper le jour 2 pose D\'ABORD la question du jour 1',
        (tester) async {
      // Le piège : la garde était indexée sur « sommes-nous au jour 1 ». Or
      // les journées passées sont rattrapables — au jour serveur 3, rien
      // n'oblige à ouvrir le jour 1 en premier. Celui qui rattrape le jour 2
      // y lirait sa vitesse de traitement, et l'estimation demandée ensuite
      // ne mesurerait plus une croyance mais un calcul.
      ecranTelephone(tester);
      await tester.pumpWidget(host(3, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J2');

      expect(find.byType(SelfEstimatePage), findsOneWidget,
          reason: 'la question passe avant TOUTE révélation, pas seulement '
              'avant celle du jour 1');
      expect(find.byType(RevealPage), findsNothing);
      expect(find.text('109'), findsNothing, reason: 'le PSI reste caché');
    });

    testWidgets('aucune journée à révélation n\'y échappe', (tester) async {
      for (final jour in EventSchedule.days) {
        if (jour.reveal == null) continue;
        final memoire = StoreMemoire();
        ecranTelephone(tester);
        await tester.pumpWidget(host(
          9, // tout est rattrapable : n'importe quelle carte peut être la 1re
          estimation: SelfEstimateStore(memoire),
          key: UniqueKey(),
        ));
        await tester.pumpAndSettle();

        await ouvrirJour(tester, 'J${jour.day}');
        expect(find.byType(SelfEstimatePage), findsOneWidget,
            reason: 'le jour ${jour.day} révèle sans avoir posé la question');
        expect(find.byType(RevealPage), findsNothing,
            reason: 'le jour ${jour.day}');
      }
    });

    testWidgets('le jour 7, qui ne révèle rien, ne la pose pas non plus',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(7, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J7');
      expect(find.byType(SelfEstimatePage), findsNothing,
          reason: 'rien à ancrer : aucune raison de demander quoi que ce soit');
      expect((await estimation.read()).isSettled, isFalse);
    });

    testWidgets('une écriture en échec n\'ouvre pas la révélation',
        (tester) async {
      // Sinon la question se reposerait à la prochaine ouverture — cette
      // fois APRÈS avoir montré un indice.
      final casse = StorePanne();
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(
          host(1, estimation: SelfEstimateStore(casse), key: UniqueKey()));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');
      await tester.tap(find.text(l10n.weRvSelfDecline));
      await tester.pumpAndSettle();

      expect(find.byType(RevealPage), findsNothing);
      expect(find.byType(DayHubPage), findsOneWidget);
    });

    testWidgets('deux appuis rapides ne dépilent pas le hub', (tester) async {
      // L'écriture ouvre une box chiffrée : plusieurs centaines de ms pendant
      // lesquelles les boutons restent tactiles. Sans verrou, le second pop
      // retire la route SUIVANTE — le hub — et la révélation s'affiche
      // par-dessus l'écran de déblocage.
      final lent = StoreLent(const Duration(milliseconds: 120));
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(
          host(1, estimation: SelfEstimateStore(lent), key: UniqueKey()));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');
      await tester.tap(find.text(l10n.weRvSelfDecline));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.text(l10n.weRvSelfDecline), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(DayHubPage, skipOffstage: false), findsOneWidget,
          reason: 'le hub doit rester sous la révélation');
      expect(find.byType(RevealPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(SelfEstimatePage, skipOffstage: false), findsNothing);
    });
  });

  group('les autres journées', () {
    testWidgets('une journée passée reste rattrapable et révèle son indice',
        (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      // Jour serveur 5 : le jour 2 est passé, donc « à rattraper ».
      await tester.pumpWidget(host(5, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J2');

      expect(find.byType(RevealPage), findsOneWidget);
      expect(find.text('109'), findsOneWidget, reason: 'le PSI du bilan');
      expect(find.byType(SelfEstimatePage), findsNothing,
          reason: 'l\'estimation n\'appartient qu\'au jour 1');
    });

    testWidgets('le jour 7 n\'a aucune révélation — il ouvre son activité',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(7, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J7');

      expect(find.byType(RevealPage), findsNothing,
          reason: 'jour vedette : rien ne doit lui faire concurrence');
      expect(find.text('En préparation'), findsOneWidget);
    });

    testWidgets('une journée à venir n\'ouvre ni estimation ni révélation',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(1, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J6');

      expect(find.byType(RevealPage), findsNothing);
      expect(find.byType(SelfEstimatePage), findsNothing);
      expect(find.byType(DayHubPage), findsOneWidget);
    });
  });

  group('ce qui suit la révélation', () {
    testWidgets('quand une activité suit, le bouton l\'annonce et y mène',
        (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(3, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J3');
      expect(find.text(l10n.weRvContinue), findsOneWidget);

      await tester.tap(find.text(l10n.weRvContinue));
      await tester.pumpAndSettle();
      expect(find.text('En préparation'), findsOneWidget,
          reason: 'le module du jour 3 n\'est pas encore livré');
    });

    testWidgets('le jour 8 s\'arrête sur le QI global, sans annonce de plus',
        (tester) async {
      await estimation.record(130);
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(9, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J8');

      expect(find.text('112'), findsOneWidget);
      expect(find.text(l10n.weRvEstimateLine(130, 112)), findsOneWidget,
          reason: 'l\'estimation du jour 1 revient ici, et nulle part ailleurs');
      expect(find.text(l10n.weRvBackToHub), findsOneWidget);

      await tester.tap(find.text(l10n.weRvBackToHub));
      await tester.pumpAndSettle();
      expect(find.text('En préparation'), findsNothing,
          reason: 'la carte de partage vit dans l\'écran de déblocage — pas '
              'd\'annonce « contenu à venir » après la récompense finale');
      expect(find.byType(DayHubPage), findsOneWidget);
    });

    testWidgets('refermer la révélation ne déclenche pas l\'activité',
        (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      await tester.pumpWidget(host(3, estimation: estimation));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J3');
      await retourSysteme(tester);

      expect(find.text('En préparation'), findsNothing);
      expect(find.byType(DayHubPage), findsOneWidget);
    });
  });

  group('sans bilan enregistré', () {
    testWidgets('la journée s\'ouvre quand même, et le dit', (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(
        3,
        estimation: estimation,
        source: RevealSource(load: () async => []),
      ));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J3');

      expect(find.text(l10n.weRvUnavailableTitle), findsOneWidget);
    });

    testWidgets('un stockage en panne ne ferme pas la journée', (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      await tester.pumpWidget(host(
        3,
        estimation: estimation,
        source: RevealSource(load: () async => throw StateError('disque HS')),
      ));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J3');

      expect(tester.takeException(), isNull);
      expect(find.byType(RevealPage), findsOneWidget);
    });
  });

  group('GARDE : la donnée révélée vient du bilan, pas de l\'écran', () {
    testWidgets('un autre bilan donne d\'autres nombres, sans rien changer '
        'au code', (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      final autre = SessionHistoryEntry(
        id: 's2',
        account: 'passe',
        date: DateTime(2026, 7, 25),
        ageInMonths: 300,
        fsiq: 88,
        vci: 84,
        vsi: 92,
        fri: 90,
        wmi: 86,
        psi: 88,
        classification: 'Moyen faible',
      );

      await tester.pumpWidget(host(
        1,
        estimation: estimation,
        source: RevealSource(load: () async => [autre]),
      ));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');

      expect(find.text('84'), findsOneWidget, reason: 'le VCI de CE bilan');
      expect(find.text('121'), findsNothing);
    });

    testWidgets('c\'est le bilan le plus récent qui est révélé', (tester) async {
      await estimation.record(100);
      ecranTelephone(tester);
      final ancien = SessionHistoryEntry(
        id: 'vieux',
        account: 'passe',
        date: DateTime(2025, 1, 1),
        ageInMonths: 300,
        fsiq: 88,
        vci: 84,
        classification: 'Moyen faible',
      );

      // `getAllForCurrentAccount` rend la liste du plus récent au plus ancien.
      await tester.pumpWidget(host(
        1,
        estimation: estimation,
        source: RevealSource(load: () async => [bilan(), ancien]),
      ));
      await tester.pumpAndSettle();

      await ouvrirJour(tester, 'J1');

      expect(find.text('121'), findsOneWidget);
      expect(find.text('84'), findsNothing);
    });
  });

  group('GARDE six langues sur l\'enchaînement', () {
    testWidgets('estimation puis révélation, dans les six langues',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        final memoire = StoreMemoire();
        final store = SelfEstimateStore(memoire);

        ecranTelephone(tester);
        await tester.pumpWidget(
          host(1, estimation: store, locale: locale, key: UniqueKey()),
        );
        await tester.pumpAndSettle();

        await ouvrirJour(tester, 'J1');
        expect(tester.takeException(), isNull, reason: 'estimation en $locale');
        expect(find.byType(SelfEstimatePage), findsOneWidget,
            reason: 'en $locale');

        await tester.tap(find.byTooltip(l10n.weRvSelfIncrease));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.weRvSelfConfirm));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'révélation en $locale');
        expect(find.byType(RevealPage), findsOneWidget, reason: 'en $locale');
        expect(find.text('121'), findsOneWidget, reason: 'en $locale');
      }
    });
  });

  test('GARDE : chaque révélation du programme sait quoi lire', () {
    // La répartition jour → révélation est gardée par event_schedule_test ;
    // ici on vérifie le pont : aucune révélation inscrite au programme ne peut
    // rester sans source de données.
    for (final jour in EventSchedule.days) {
      final reveal = jour.reveal;
      if (reveal == null) continue;
      final index = RevealData.indexFor(reveal);
      final data = RevealData.fromHistory(bilan())!;
      expect(data.hasDataFor(reveal), isTrue,
          reason: 'jour ${jour.day} : révélation ${reveal.name} sans donnée');
      if (index != null) {
        expect(data.scoreOf(index), isNotNull,
            reason: 'jour ${jour.day} : indice ${index.code} introuvable');
      }
    }
  });
}
