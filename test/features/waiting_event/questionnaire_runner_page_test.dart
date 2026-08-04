// Le moteur de questionnaire, monté pour de vrai, sur 45 questions.
//
// C'est le test d'acceptation du moteur : un module factice de 45 questions se
// passe de bout en bout, se reprend après fermeture, et garde l'ordre de ses
// items. Les quatre règles structurelles y sont vérifiées à l'écran plutôt
// qu'en intention — on ne peut pas avancer sans répondre, on peut abandonner
// sans rien perdre, un changement d'échelle s'annonce, et une contribution
// annonce qu'elle ne calcule aucun score.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/widgets/kepler_button.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_item.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_module.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_scale.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';
import 'package:mentality/features/waiting_event/_shared/presentation/questionnaire_runner_page.dart';
import 'package:mentality/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart';

// ─── Le module factice : 30 items validés + 15 candidats = 45 ────────────────

const int kValides = 30;
const int kCandidats = 15;
const int kTotal = kValides + kCandidats;

QText t(String s) => QText(fr: s, en: s, enGB: s, de: s, es: s, pt: s);

final scaleA = QScale(
  id: 'a4',
  options: [
    for (var v = 0; v <= 3; v++)
      QScaleOption(value: v, label: t('a-opt$v')),
  ],
);

final scaleB = QScale(
  id: 'b7',
  options: [
    for (var v = 1; v <= 7; v++)
      QScaleOption(value: v, label: t('b-opt$v')),
  ],
);

final moduleFactice = QModule(
  id: 'factice',
  day: 7,
  kind: DayActivityKind.announced,
  instruments: [
    QInstrument(
      id: 'valide',
      origin: QItemOrigin.validated,
      scale: scaleA,
      items: [
        for (var i = 1; i <= kValides; i++)
          QItem(id: 'v$i', text: t('V-$i')),
      ],
    ),
    QInstrument(
      id: 'maison',
      origin: QItemOrigin.candidate,
      scale: scaleB,
      transition: QTransition(title: t('Partie 2'), body: t('L\'échelle change.')),
      items: [
        for (var i = 1; i <= kCandidats; i++)
          QItem(id: 'c$i', text: t('C-$i')),
      ],
    ),
  ],
);

/// Réponses en mémoire — le moteur ne doit rien savoir de Hive.
class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};
  int ecritures = 0;

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async {
    data[answers.moduleId] = answers;
    ecritures++;
  }

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget host(Widget child, {Locale locale = const Locale('fr')}) => ScreenUtilInit(
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
        home: child,
      ),
    );

Widget runner(StoreMemoire store, {QModule? module, ValueChanged<QAnswerSet>? onFinished}) =>
    QuestionnaireRunnerPage(
      module: module ?? moduleFactice,
      store: store,
      title: 'Bilan factice',
      onFinished: onFinished,
      // Le moteur ne doit rien savoir du réseau : l'envoi est neutralisé ici et
      // vérifié à part (questionnaire_runner_upload_test.dart).
      submit: (_) async {},
    );

/// Ferme l'écran pour de bon.
///
/// Re-`pumpWidget` d'un écran du même type réutiliserait le `State` existant —
/// `initState` ne serait pas rejoué et la reprise ne serait jamais testée. Il
/// faut donc vraiment démonter la page entre deux sessions.
Future<void> fermerEcran(WidgetTester tester) async {
  await tester.pumpWidget(host(const SizedBox.shrink()));
  await tester.pumpAndSettle();
}

/// Le texte attendu de la question n° [q] (1-based) — c'est l'ordre du module.
String texteDeLaQuestion(int q) => q <= kValides ? 'V-$q' : 'C-${q - kValides}';

/// L'option choisie à la question [q], et sa valeur brute.
(String, int) choixPour(int q) => q <= kValides ? ('a-opt2', 2) : ('b-opt5', 5);

Future<void> tapper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Répond aux questions de [depuis] à [jusqua] incluses, en franchissant les
/// écrans de transition rencontrés.
Future<void> repondre(
  WidgetTester tester, {
  int depuis = 1,
  int jusqua = kTotal,
}) async {
  for (var q = depuis; q <= jusqua; q++) {
    if (find.text('Partie 2').evaluate().isNotEmpty) {
      await tapper(tester, find.text('Continuer'));
    }
    expect(find.text(texteDeLaQuestion(q)), findsOneWidget,
        reason: 'question $q : l\'ordre du module doit être respecté');
    await tapper(tester, find.text(choixPour(q).$1));
    await tapper(tester, find.text(q == kTotal ? 'Terminer' : 'Suivant'));
  }
}

void main() {
  testWidgets('ACCEPTATION : 45 questions de bout en bout, dans l\'ordre',
      (tester) async {
    ecranTelephone(tester);
    final store = StoreMemoire();
    QAnswerSet? rendu;
    await tester.pumpWidget(host(runner(store, onFinished: (a) => rendu = a)));
    await tester.pumpAndSettle();

    expect(find.text('01 / 45'), findsOneWidget);
    await repondre(tester);

    expect(find.text('C\'est terminé'), findsOneWidget);
    expect(rendu, isNotNull, reason: 'la fin doit être notifiée une fois');
    expect(rendu!.answeredCount, kTotal);
    expect(rendu!.isPartial, isFalse);

    // Chaque réponse est rangée sous SON item, avec la valeur brute de son
    // échelle — jamais un indice de bouton.
    for (var q = 1; q <= kTotal; q++) {
      final id = q <= kValides ? 'v$q' : 'c${q - kValides}';
      expect(rendu!.valueOf(id), choixPour(q).$2, reason: 'réponse de $id');
    }
  });

  testWidgets('aucune question n\'est sautable : « Suivant » reste inerte',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(host(runner(StoreMemoire())));
    await tester.pumpAndSettle();

    KeplerButton suivant() =>
        tester.widget<KeplerButton>(find.widgetWithText(KeplerButton, 'Suivant'));

    expect(suivant().onPressed, isNull,
        reason: 'sans réponse, il ne doit exister aucun chemin vers la suite');

    await tapper(tester, find.text('a-opt1'));
    expect(suivant().onPressed, isNotNull);

    // Et on est bien resté sur la même question : pas d'avance automatique.
    expect(find.text('V-1'), findsOneWidget);
    expect(find.text('01 / 45'), findsOneWidget);
  });

  testWidgets('revenir en arrière pour se corriger est permis', (tester) async {
    ecranTelephone(tester);
    final store = StoreMemoire();
    await tester.pumpWidget(host(runner(store)));
    await tester.pumpAndSettle();

    await repondre(tester, jusqua: 2);
    expect(find.text('V-3'), findsOneWidget);

    await tapper(tester, find.text('Précédent'));
    expect(find.text('V-2'), findsOneWidget);
    await tapper(tester, find.text('a-opt0'));

    expect(store.data['factice']!.valueOf('v2'), 0,
        reason: 'la correction remplace la réponse');
    expect(store.data['factice']!.answeredCount, 2,
        reason: 'se corriger n\'ajoute pas une réponse');
  });

  testWidgets('la première question n\'offre pas de retour', (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(host(runner(StoreMemoire())));
    await tester.pumpAndSettle();
    expect(find.text('Précédent'), findsNothing);
  });

  group('reprise après fermeture', () {
    testWidgets('on rouvre à la question suivante, et on le dit',
        (tester) async {
      ecranTelephone(tester);
      final store = StoreMemoire();

      // Première session : 20 questions, puis on ferme l'écran.
      await tester.pumpWidget(host(runner(store)));
      await tester.pumpAndSettle();
      await repondre(tester, jusqua: 20);
      expect(store.data['factice']!.answeredCount, 20);
      expect(store.data['factice']!.isPartial, isTrue,
          reason: 'un abandon ne doit jamais passer pour un questionnaire fini');

      // Seconde session : le même store, un écran neuf.
      await fermerEcran(tester);
      await tester.pumpWidget(host(runner(store)));
      await tester.pumpAndSettle();

      expect(find.text('V-21'), findsOneWidget);
      expect(find.text('21 / 45'), findsOneWidget);
      expect(find.text('Tu reprends là où tu t\'étais arrêté.'), findsOneWidget);
    });

    testWidgets('la reprise va jusqu\'au bout et conserve les 20 réponses',
        (tester) async {
      ecranTelephone(tester);
      final store = StoreMemoire();
      await tester.pumpWidget(host(runner(store)));
      await tester.pumpAndSettle();
      await repondre(tester, jusqua: 20);

      QAnswerSet? rendu;
      await fermerEcran(tester);
      await tester
          .pumpWidget(host(runner(store, onFinished: (a) => rendu = a)));
      await tester.pumpAndSettle();
      await repondre(tester, depuis: 21);

      expect(rendu!.answeredCount, kTotal);
      expect(rendu!.isPartial, isFalse);
      expect(rendu!.valueOf('v1'), 2, reason: 'réponse de la 1re session');
      expect(rendu!.valueOf('c15'), 5, reason: 'réponse de la 2de session');
    });

    testWidgets('un module déjà terminé se rouvre sur sa fin, sans redemander',
        (tester) async {
      ecranTelephone(tester);
      final store = StoreMemoire();
      var reponses = const QAnswerSet(moduleId: 'factice');
      for (final item in moduleFactice.items) {
        reponses = reponses.withAnswer(item.id, 1);
      }
      await store.save(reponses.markCompleted());

      await tester.pumpWidget(host(runner(store)));
      await tester.pumpAndSettle();

      expect(find.text('C\'est terminé'), findsOneWidget);
      expect(find.text('V-1'), findsNothing);
    });
  });

  testWidgets('le changement d\'échelle est annoncé avant la question 31',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(host(runner(StoreMemoire())));
    await tester.pumpAndSettle();

    await repondre(tester, jusqua: kValides);

    // L'écran de transition s'interpose : aucune question n'est visible.
    expect(find.text('Partie 2'), findsOneWidget);
    expect(find.text('L\'échelle change.'), findsOneWidget);
    expect(find.text('C-1'), findsNothing);

    await tapper(tester, find.text('Continuer'));
    expect(find.text('C-1'), findsOneWidget);
    expect(find.text('b-opt7'), findsOneWidget,
        reason: 'la nouvelle échelle est en place');
  });

  testWidgets('un bloc candidat annonce qu\'il ne calcule aucun score',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(host(runner(StoreMemoire())));
    await tester.pumpAndSettle();

    const cadrage =
        'Ces questions ne calculent aucun score pour toi : elles servent à construire l\'outil pour les suivants.';
    expect(find.text(cadrage), findsNothing,
        reason: 'le bloc validé, lui, promet bien un résultat');

    await repondre(tester, jusqua: kValides);
    await tapper(tester, find.text('Continuer'));
    expect(find.text(cadrage), findsOneWidget);
  });

  testWidgets('un module de contribution le dit jusque dans son écran de fin',
      (tester) async {
    ecranTelephone(tester);
    final contribution = QModule(
      id: 'contrib',
      day: 2,
      kind: DayActivityKind.contribution,
      instruments: [
        QInstrument(
          id: 'maison',
          origin: QItemOrigin.candidate,
          scale: scaleA,
          items: [QItem(id: 'x1', text: t('X-1'))],
        ),
      ],
    );
    await tester.pumpWidget(
      host(runner(StoreMemoire(), module: contribution)),
    );
    await tester.pumpAndSettle();

    // KeplerProgress met son étiquette en capitales.
    expect(find.text('CONTRIBUTION'), findsOneWidget,
        reason: 'la barre de progression porte le cadrage');
    await tapper(tester, find.text('a-opt2'));
    await tapper(tester, find.text('Terminer'));

    expect(
        find.text(
            'Merci — tes réponses vont servir à construire notre test. Aucun score n\'est calculé pour toi.'),
        findsOneWidget);
  });

  group('abandon', () {
    testWidgets('quitter demande confirmation et ne perd rien', (tester) async {
      ecranTelephone(tester);
      final store = StoreMemoire();
      await tester.pumpWidget(host(runner(store)));
      await tester.pumpAndSettle();
      await repondre(tester, jusqua: 3);

      // Retour matériel : intercepté par le PopScope.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Quitter le questionnaire ?'), findsOneWidget);
      await tapper(tester, find.text('Continuer'));

      expect(find.text('Quitter le questionnaire ?'), findsNothing);
      expect(find.text('V-4'), findsOneWidget, reason: 'on reste où on était');
      expect(store.data['factice']!.answeredCount, 3);
      expect(store.data['factice']!.isPartial, isTrue);
    });
  });

  testWidgets('rendu dans les 6 langues, sans clé manquante', (tester) async {
    ecranTelephone(tester);
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(host(runner(StoreMemoire()), locale: locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'échec de rendu en $locale');
      expect(find.text('V-1'), findsOneWidget, reason: 'en $locale');
      expect(find.text('01 / 45'), findsOneWidget, reason: 'en $locale');
    }
  });

  group('intégration : le hub ouvre le questionnaire', () {
    testWidgets('une journée dont le module est livré ouvre le moteur',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(DayHubPage(
        serverDayIndex: 7,
        moduleForDay: (day) => day == 7 ? moduleFactice : null,
        store: StoreMemoire(),
      )));
      await tester.pumpAndSettle();

      await tapper(tester, find.text('J7'));

      expect(find.text('V-1'), findsOneWidget);
      expect(find.text('01 / 45'), findsOneWidget);
      expect(find.text('En préparation'), findsNothing);
    });

    testWidgets('une journée sans module livré garde l\'annonce honnête',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(DayHubPage(
        serverDayIndex: 7,
        moduleForDay: (_) => null,
        store: StoreMemoire(),
      )));
      await tester.pumpAndSettle();

      await tapper(tester, find.text('J7'));
      expect(find.text('En préparation'), findsOneWidget);
    });
  });
}
