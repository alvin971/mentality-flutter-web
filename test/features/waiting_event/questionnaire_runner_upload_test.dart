// L'envoi part DE L'ÉCRAN DU QUESTIONNAIRE, pas d'un écran ultérieur.
//
// C'est la moitié la plus facile à casser du LOT J, et c'est exactement le bug
// du parrainage : le code d'envoi peut être parfait, si personne ne l'appelle
// au bon moment la donnée est perdue. Le parrainage partait depuis l'écran de
// résultats — facultatif, atteint dix minutes plus tard, souvent jamais.
//
// Les tests ci-dessous vérifient donc QUAND le moteur confie ses réponses :
// à la dernière question, et à l'abandon — dans les deux cas depuis l'écran
// lui-même, avant toute étape suivante.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_instrument.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_item.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_module.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_scale.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_text.dart';
import 'package:mentality/features/waiting_event/_shared/presentation/questionnaire_runner_page.dart';

// ─── Module factice court : 4 questions, une seule échelle ───────────────────

const int kTotal = 4;

QText t(String s) => QText(fr: s, en: s, enGB: s, de: s, es: s, pt: s);

final echelle = QScale(
  id: 'e4',
  options: [for (var v = 0; v <= 3; v++) QScaleOption(value: v, label: t('opt$v'))],
);

QModule module({
  int day = 3,
  DayActivityKind kind = DayActivityKind.announced,
}) =>
    QModule(
      id: 'factice',
      day: day,
      kind: kind,
      instruments: [
        QInstrument(
          id: 'bloc',
          origin: QItemOrigin.validated,
          scale: echelle,
          items: [for (var i = 1; i <= kTotal; i++) QItem(id: 'i$i', text: t('Q-$i'))],
        ),
      ],
    );

class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async => data[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Le questionnaire est monté SUR une route précédente : sans elle, quitter
/// viderait la pile du Navigator et ferait échouer la reconstruction.
Widget host(Widget child, {Locale locale = const Locale('fr')}) =>
    _app(locale, initialRoute: '/questionnaire', routes: {
      '/': (_) => const Scaffold(body: SizedBox.shrink()),
      '/questionnaire': (_) => child,
    });

/// Un écran neutre, pour démonter vraiment la page entre deux sessions :
/// re-`pumpWidget` d'un écran du même type réutiliserait son `State`.
Widget hostVide() => _app(const Locale('fr'), routes: {
      '/': (_) => const Scaffold(body: SizedBox.shrink()),
    });

Widget _app(
  Locale locale, {
  String initialRoute = '/',
  required Map<String, WidgetBuilder> routes,
}) {
  // Clé neuve à chaque montage : sans elle, re-`pumpWidget` réutiliserait le
  // Navigator existant (avec son historique déjà dépilé) et `initialRoute`
  // serait ignoré. La clé est créée UNE fois par appel, hors du builder — la
  // mettre dedans détruirait l'état à chaque reconstruction.
  final cle = UniqueKey();
  return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        key: cle,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: initialRoute,
        routes: routes,
      ),
  );
}

Future<void> tapper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Répond aux questions [depuis]..[jusqua] incluses. Les libellés des boutons
/// sont traduits : on les lit dans les ARB plutôt que de les écrire en dur.
Future<void> repondre(
  WidgetTester tester, {
  int depuis = 1,
  int jusqua = kTotal,
  AppLocalizations? l10n,
}) async {
  final mots = l10n ?? await AppLocalizations.delegate.load(const Locale('fr'));
  for (var q = depuis; q <= jusqua; q++) {
    expect(find.text('Q-$q'), findsOneWidget, reason: 'question $q');
    await tapper(tester, find.text('opt2'));
    await tapper(
        tester, find.text(q == kTotal ? mots.weRunnerFinish : mots.weRunnerNext));
  }
}

void main() {
  late List<EventSubmission> envoyes;
  late AppLocalizations mots;

  Widget runner({
    QModule? m,
    StoreMemoire? store,
    Locale locale = const Locale('fr'),
  }) =>
      host(
        QuestionnaireRunnerPage(
          module: m ?? module(),
          store: store ?? StoreMemoire(),
          title: 'Bilan factice',
          submit: (s) async => envoyes.add(s),
        ),
        locale: locale,
      );

  setUpAll(() async =>
      mots = await AppLocalizations.delegate.load(const Locale('fr')));

  setUp(() => envoyes = []);

  testWidgets('la dernière question déclenche l\'envoi, depuis cet écran',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(runner());
    await tester.pumpAndSettle();
    await repondre(tester);

    expect(envoyes.length, 1, reason: 'un envoi, et un seul');
    expect(envoyes.single.toWire(), {
      'schema': 1,
      'moduleId': 'factice',
      'day': 3,
      'kind': 'announced',
      'partial': false,
      'locale': 'fr',
      'answers': {'i1': 2, 'i2': 2, 'i3': 2, 'i4': 2},
    });
  });

  testWidgets('rien n\'est envoyé tant que le questionnaire n\'est pas fini',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(runner());
    await tester.pumpAndSettle();
    await repondre(tester, jusqua: kTotal - 1);

    expect(envoyes, isEmpty,
        reason: 'chaque réponse est persistée localement, mais on n\'envoie '
            'pas une soumission par question');
  });

  testWidgets('l\'abandon envoie ce qui existe, MARQUÉ partiel', (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(runner());
    await tester.pumpAndSettle();
    await repondre(tester, jusqua: 2);

    // Retour matériel : intercepté par le PopScope.
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.text(mots.weRunnerQuitTitle), findsOneWidget);
    await tapper(tester, find.text(mots.weRunnerQuitLeave));

    expect(envoyes.length, 1,
        reason: 'un abandon n\'est pas une perte : ce qui est répondu part');
    expect(envoyes.single.partial, isTrue,
        reason: 'un abandon ne doit JAMAIS passer pour un questionnaire fini');
    expect(envoyes.single.answers, {'i1': 2, 'i2': 2});
  });

  testWidgets('renoncer à quitter n\'envoie rien', (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(runner());
    await tester.pumpAndSettle();
    await repondre(tester, jusqua: 2);

    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    await tapper(tester, find.text(mots.weRunnerQuitStay));

    expect(envoyes, isEmpty, reason: 'on est resté dans le questionnaire');
  });

  testWidgets('quitter sans avoir répondu n\'envoie rien', (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(runner());
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    await tapper(tester, find.text(mots.weRunnerQuitLeave));

    expect(envoyes, isEmpty, reason: 'il n\'y a rien à envoyer');
  });

  testWidgets('une contribution part sous SON cadrage RGPD', (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(
        runner(m: module(day: 2, kind: DayActivityKind.contribution)));
    await tester.pumpAndSettle();
    await repondre(tester);

    expect(envoyes.single.kind, DayActivityKind.contribution);
    expect(envoyes.single.day, 2);
  });

  testWidgets('la langue de passation voyage avec les réponses',
      (tester) async {
    ecranTelephone(tester);
    for (final locale in AppLocalizations.supportedLocales) {
      envoyes = [];
      await tester.pumpWidget(runner(locale: locale));
      await tester.pumpAndSettle();
      await repondre(tester,
          l10n: await AppLocalizations.delegate.load(locale));

      expect(envoyes.single.locale, locale.toString(),
          reason: 'en $locale : la langue conditionne l\'interprétation des '
              'items, elle doit accompagner les réponses');
      await tester.pumpWidget(hostVide());
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'BRANCHEMENT DE PRODUCTION : sans rien injecter, le moteur atteint le '
      'service d\'envoi', (tester) async {
    // Le défaut du parrainage n'était pas dans le code d'envoi : il était dans
    // le CÂBLAGE, que rien n'exerçait. Ce test monte donc le moteur avec son
    // `submit` PAR DÉFAUT et vérifie que la soumission arrive au singleton.
    ecranTelephone(tester);
    final espion = _ServiceEspion();
    final vrai = EventUploadService.instance;
    EventUploadService.debugSetInstance(espion);
    addTearDown(() => EventUploadService.debugSetInstance(vrai));

    await tester.pumpWidget(host(QuestionnaireRunnerPage(
      module: module(),
      store: StoreMemoire(),
      title: 'Bilan factice',
      // AUCUN `submit:` — c'est tout l'objet du test.
    )));
    await tester.pumpAndSettle();
    await repondre(tester);

    expect(espion.recues.length, 1,
        reason: 'le moteur doit confier ses réponses au service réel');
    expect(espion.recues.single.moduleId, 'factice');
    expect(espion.recues.single.partial, isFalse);
  });

  testWidgets(
      'RATTRAPAGE : un jeu complet resté « en cours » part à la réouverture',
      (tester) async {
    // App tuée entre la dernière réponse et « Terminer » : les réponses sont
    // toutes sur le disque, mais `_terminer()` n'a jamais abouti — elles n'ont
    // donc jamais été confiées au service, et l'écran de fin n'offre aucun
    // second chemin.
    ecranTelephone(tester);
    final store = StoreMemoire();
    var reponses = const QAnswerSet(moduleId: 'factice');
    for (var i = 1; i <= kTotal; i++) {
      reponses = reponses.withAnswer('i$i', 2);
    }
    store.data['factice'] = reponses; // complet, mais toujours « en cours »

    await tester.pumpWidget(runner(store: store));
    await tester.pumpAndSettle();

    expect(envoyes.length, 1,
        reason: 'sans ce rattrapage, ces réponses ne partiraient plus jamais');
    expect(envoyes.single.partial, isFalse,
        reason: 'toutes les questions ont une réponse : le jeu est complet');
    expect(store.data['factice']!.isPartial, isFalse,
        reason: 'et le disque est remis d\'aplomb, pour ne pas renvoyer à '
            'chaque ouverture');
  });

  testWidgets('un module DÉJÀ terminé ne renvoie rien à la réouverture',
      (tester) async {
    ecranTelephone(tester);
    final store = StoreMemoire();
    var reponses = const QAnswerSet(moduleId: 'factice');
    for (var i = 1; i <= kTotal; i++) {
      reponses = reponses.withAnswer('i$i', 2);
    }
    store.data['factice'] = reponses.markCompleted();

    await tester.pumpWidget(runner(store: store));
    await tester.pumpAndSettle();

    expect(envoyes, isEmpty,
        reason: 'il est déjà parti : rouvrir l\'écran ne doit pas le rejouer');
  });

  testWidgets('une reprise n\'envoie que le jeu complet, une fois',
      (tester) async {
    ecranTelephone(tester);
    final store = StoreMemoire();

    // Première session : on répond à 2 questions puis on abandonne.
    await tester.pumpWidget(runner(store: store));
    await tester.pumpAndSettle();
    await repondre(tester, jusqua: 2);
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    await tapper(tester, find.text(mots.weRunnerQuitLeave));
    expect(envoyes.length, 1, reason: 'le partiel de l\'abandon');

    // Écran vraiment démonté : sinon `initState` n'est pas rejoué.
    await tester.pumpWidget(hostVide());
    await tester.pumpAndSettle();

    // Seconde session : on reprend à la question 3 et on termine.
    await tester.pumpWidget(runner(store: store));
    await tester.pumpAndSettle();
    await repondre(tester, depuis: 3);

    expect(envoyes.length, 2, reason: 'le partiel, puis le complet');
    expect(envoyes.last.partial, isFalse);
    expect(envoyes.last.answers.length, kTotal,
        reason: 'la reprise renvoie le jeu ENTIER, pas seulement le reliquat');
  });
}

/// Un service d'envoi qui note ce qu'on lui confie, sans réseau ni stockage.
class _ServiceEspion extends EventUploadService {
  _ServiceEspion()
      : super(
          outbox: _OutboxMuette(),
          transport: _TransportMuet(),
          consent: _ConsentMuet(),
        );

  final List<EventSubmission> recues = [];

  @override
  Future<EventUploadOutcome> submit(EventSubmission submission) async {
    recues.add(submission);
    return EventUploadOutcome.confirmed;
  }
}

class _OutboxMuette implements EventOutbox {
  @override
  Future<bool> enqueue(EventSubmission submission) async => true;
  @override
  Future<List<EventSubmission>> pending() async => const [];
  @override
  Future<bool> removeIf(EventSubmission envoyee) async => true;
  @override
  Future<void> markRefused(String moduleId) async {}
  @override
  Future<Set<String>> refusedModules() async => const {};
}

class _TransportMuet implements EventUploadTransport {
  @override
  Future<EventUploadOutcome> send(
    EventSubmission submission, {
    required String consentVersion,
  }) async =>
      EventUploadOutcome.confirmed;
}

class _ConsentMuet implements EventConsentGate {
  @override
  Future<String?> consentVersion() async => null;
}
