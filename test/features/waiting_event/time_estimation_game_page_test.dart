// L'écran du jeu des durées, joué de bout en bout.
//
// Ce que ces tests protègent, dans l'ordre d'importance :
//
// 1. AUCUNE MINUTERIE NE SURVIT À L'ÉCRAN. C'est la garde propre à ce lot : les
//    deux jeux précédents n'avaient aucune minuterie, celui-ci en a besoin. Le
//    test démonte l'écran en plein intervalle et s'arrête là — sans avancer
//    l'horloge. Si `dispose` n'annulait pas, le banc d'essai refuserait le test
//    (« a Timer is still pending »).
// 2. L'ENCHAÎNEMENT DES QUATRE TEMPS EST EXACT. Temps mort, premier intervalle,
//    coupure, second intervalle : le panneau doit s'allumer et s'éteindre aux
//    millisecondes prévues, sinon la durée vue n'est pas la durée notée.
// 3. AUCUN CHRONOMÈTRE DU CÔTÉ DE LA PERSONNE. Elle peut prendre tout son temps
//    pour répondre sans que rien ne bouge.
// 4. RIEN NE PART. Le record est un fichier local ; la file d'envoi de
//    l'événement porte des données de santé sous consentement art. 9.
// 5. LE JEU RESTE FACULTATIF. « Plus tard » sort sans jouer.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/time_estimation/data/time_estimation_record_store.dart';
import 'package:mentality/features/waiting_event/time_estimation/domain/services/time_estimation_run.dart';
import 'package:mentality/features/waiting_event/time_estimation/presentation/pages/time_estimation_game_page.dart';
import 'package:mentality/features/waiting_event/time_estimation/presentation/widgets/duration_panel.dart';

/// Graine fixe : le test doit savoir quelle durée et quelle position l'attendent.
const int graine = 4242;

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

/// Espion du service d'envoi : il compte, il n'envoie rien. Installé pour tout le
/// groupe, il évite aussi qu'un chemin oublié n'ouvre une box Hive.
class _ServiceEspion extends EventUploadService {
  int envois = 0;
  int rejeux = 0;

  @override
  Future<EventUploadOutcome> submit(submission) async {
    envois++;
    return EventUploadOutcome.confirmed;
  }

  @override
  Future<Map<String, EventUploadOutcome>> retryPending() async {
    rejeux++;
    return const {};
  }
}

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget host(
  TimeEstimationRecordStore store, {
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
        home: TimeEstimationGamePage(store: store, seed: graine),
      ),
    );

/// Le panneau est-il allumé, à cet instant ?
bool panneauAllume(WidgetTester tester) =>
    tester.widget<DurationPanel>(find.byType(DurationPanel)).lit;

Future<void> demarrer(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.text(l10n.weTeStart));
  await tester.pump();
}

/// Avance l'horloge des quatre temps d'un essai, jusqu'à la question.
///
/// Les durées viennent d'une partie MIROIR, construite sur la même graine : c'est
/// la seule façon de savoir combien avancer, et cela vérifie au passage que
/// l'écran suit bien la partie du domaine.
Future<void> presenter(WidgetTester tester, TimeEstimationRun miroir) async {
  final essai = miroir.trial!;
  await tester.pump(TimeEstimationGamePage.beforeTrial);
  await tester.pump(Duration(milliseconds: essai.firstMs));
  await tester.pump(TimeEstimationGamePage.betweenIntervals);
  await tester.pump(Duration(milliseconds: essai.secondMs));
}

/// Joue toute la partie. [juste] décide, essai par essai, si la réponse est bonne.
Future<TimeEstimationRun> jouerPartie(
  WidgetTester tester, {
  required bool Function(int index) juste,
}) async {
  var miroir = TimeEstimationRun.start(seed: graine);
  while (!miroir.isDone) {
    await presenter(tester, miroir);
    final essai = miroir.trial!;
    final ok = juste(miroir.answered);
    final premier = ok ? essai.comparisonFirst : !essai.comparisonFirst;
    await tester.tap(find.byKey(answerKey(first: premier)));
    miroir = miroir.answer(choseFirst: premier);
    // Une seule image, SANS avance d'horloge : `pumpAndSettle` avance le temps
    // par pas de 100 ms et déclencherait les minuteries de l'essai suivant à
    // contretemps.
    if (miroir.isDone) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
  return miroir;
}

void main() {
  late _ServiceEspion espion;

  setUp(() {
    espion = _ServiceEspion();
    EventUploadService.debugSetInstance(espion);
  });

  // Un `static` mutable fuit d'un fichier de test à l'autre : on le repose.
  tearDown(() => EventUploadService.debugSetInstance(EventUploadService()));

  group('la minuterie', () {
    testWidgets('★ aucune ne survit au démontage de l\'écran', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      // En plein temps mort : une minuterie est programmée pour dans 400 ms.
      await tester.pump(const Duration(milliseconds: 300));

      // L'écran disparaît SUR-LE-CHAMP — pas de transition de route à attendre,
      // donc aucune avance d'horloge parasite.
      await tester.pumpWidget(const SizedBox());

      // Le test s'arrête ici, sans avancer l'horloge : si `dispose` n'avait pas
      // annulé, la minuterie serait encore en vol et le banc d'essai refuserait
      // ce test.
    });

    testWidgets('★ les quatre temps s\'enchaînent aux durées prévues',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      final essai = TimeEstimationRun.start(seed: graine).trial!;

      // Temps mort : le panneau est éteint et la question n'est pas posée.
      expect(panneauAllume(tester), isFalse);
      expect(find.text(l10n.weTeWatch), findsOneWidget);
      expect(find.text(l10n.weTePrompt), findsNothing);

      await tester.pump(TimeEstimationGamePage.beforeTrial);
      expect(panneauAllume(tester), isTrue, reason: 'premier intervalle');

      await tester.pump(Duration(milliseconds: essai.firstMs));
      expect(panneauAllume(tester), isFalse, reason: 'coupure');

      await tester.pump(TimeEstimationGamePage.betweenIntervals);
      expect(panneauAllume(tester), isTrue, reason: 'second intervalle');

      await tester.pump(Duration(milliseconds: essai.secondMs));
      expect(panneauAllume(tester), isFalse, reason: 'question posée');
      expect(find.text(l10n.weTePrompt), findsOneWidget);
    });

    testWidgets('★ répondre n\'est jamais chronométré', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await presenter(tester, TimeEstimationRun.start(seed: graine));

      // Une minute passe sans que personne ne réponde : la question est toujours
      // là, l'essai n'a pas été perdu, rien n'a été compté.
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(l10n.weTePrompt), findsOneWidget);
      expect(panneauAllume(tester), isFalse);
    });

    testWidgets('aucune réponse n\'est acceptée avant la question',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      // Pendant la présentation, les boutons sont là mais inertes : taper ne doit
      // pas faire avancer l'essai.
      await tester.pump(TimeEstimationGamePage.beforeTrial);
      await tester.tap(find.byKey(answerKey(first: true)),
          warnIfMissed: false);
      await tester.pump();
      expect(find.text(l10n.weTePrompt), findsNothing);
      expect(panneauAllume(tester), isTrue);

      // On laisse l'essai s'achever pour ne pas finir sur une minuterie en vol.
      final essai = TimeEstimationRun.start(seed: graine).trial!;
      await tester.pump(Duration(milliseconds: essai.firstMs));
      await tester.pump(TimeEstimationGamePage.betweenIntervals);
      await tester.pump(Duration(milliseconds: essai.secondMs));
    });
  });

  group('le résultat', () {
    testWidgets('★ une partie réaliste annonce un seuil', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      // Juste deux fois sur trois : le régime vers lequel l'escalier attire.
      final miroir = await jouerPartie(tester, juste: (i) => i % 3 != 2);
      final attendu = miroir.score;

      expect(attendu.isReliable, isTrue);
      expect(find.text(l10n.weTeResultTitle), findsOneWidget);
      expect(find.text(l10n.weTeThreshold(attendu.thresholdPercent)),
          findsOneWidget);
      expect(find.text(l10n.weTeAccuracyNote(attendu.accuracyPercent)),
          findsOneWidget);
    });

    testWidgets('★ un sans-faute n\'annonce RIEN', (tester) async {
      // Aucune erreur, donc aucune inversion : on n'a pas trouvé la limite de la
      // personne, on a seulement constaté qu'elle ne s'est pas trompée. Annoncer
      // « 2 % » serait inventer un seuil que rien n'a mesuré.
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(TimeEstimationRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerPartie(tester, juste: (_) => true);

      expect(find.text(l10n.weTeUnreliableTitle), findsOneWidget);
      expect(memoire.data, isEmpty, reason: 'rien ne doit être enregistré');
    });

    testWidgets('les deux garde-fous de lecture sont affichés', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerPartie(tester, juste: (i) => i % 3 != 2);

      await tester.ensureVisible(find.text(l10n.weTeNotSpeed));
      await tester.pumpAndSettle();
      expect(find.text(l10n.weTeNotSpeed), findsOneWidget);
      expect(find.text(l10n.weTeNotClinical), findsOneWidget);
    });

    testWidgets('★ le record se prend par le PLUS FIN', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(TimeEstimationRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      final premiere = await jouerPartie(tester, juste: (i) => i % 3 != 2);
      final seuil1 = premiere.score.thresholdPercent;

      // Première partie : c'est un record, donc annoncé comme tel.
      expect(find.text(l10n.weTeNewBest), findsOneWidget);
      expect(memoire.data[TimeEstimationRecordStore.moduleId]!
          .valueOf(TimeEstimationRecordStore.bestKey), seuil1);

      // Même partie rejouée à l'identique : le seuil est le même, donc PAS un
      // nouveau record — le record ne se prend que strictement en dessous.
      await tester.tap(find.text(l10n.weTeReplay));
      await tester.pump();
      await jouerPartie(tester, juste: (i) => i % 3 != 2);

      expect(find.text(l10n.weTeNewBest), findsNothing);
      await tester.ensureVisible(find.text(l10n.weTeBest(seuil1)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.weTeBest(seuil1)), findsOneWidget);
      expect(memoire.data[TimeEstimationRecordStore.moduleId]!
          .valueOf(TimeEstimationRecordStore.playsKey), 2);
    });
  });

  group('ce qui est gardé, et ce qui ne part pas', () {
    testWidgets('★ RIEN n\'est envoyé, ni pendant ni après', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(TimeEstimationRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerPartie(tester, juste: (i) => i % 3 != 2);

      expect(espion.envois, 0);
      expect(espion.rejeux, 0);
    });

    testWidgets('★ le stockage ne garde que le record, la dernière et le compte',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(TimeEstimationRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerPartie(tester, juste: (i) => i % 3 != 2);

      final garde = memoire.data[TimeEstimationRecordStore.moduleId]!;
      expect(garde.answers.keys.toSet(), {
        TimeEstimationRecordStore.bestKey,
        TimeEstimationRecordStore.lastKey,
        TimeEstimationRecordStore.playsKey,
      });
    });

    testWidgets('une partie abandonnée n\'écrit rien', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(TimeEstimationRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      var miroir = TimeEstimationRun.start(seed: graine);
      await presenter(tester, miroir);
      await tester.tap(find.byKey(answerKey(first: true)));
      miroir = miroir.answer(choseFirst: true);
      await tester.pump();
      // L'écran part avec un essai en cours.
      await tester.pumpWidget(const SizedBox());

      expect(memoire.data, isEmpty);
    });
  });

  group('le jeu reste facultatif', () {
    testWidgets('« Plus tard » sort sans jouer', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (context, __) => Scaffold(
              body: Builder(
                builder: (inner) => TextButton(
                  onPressed: () => Navigator.of(inner).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TimeEstimationGamePage(
                        store: TimeEstimationRecordStore(memoire),
                        seed: graine,
                      ),
                    ),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.weTeLater));
      await tester.pumpAndSettle();

      expect(find.text('ouvrir'), findsOneWidget);
      expect(memoire.data, isEmpty);
    });
  });

  group('six langues', () {
    testWidgets('★ la consigne et la question tiennent dans les six',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        ecranTelephone(tester);
        final l10n = await AppLocalizations.delegate.load(locale);
        // Re-`pumpWidget` réutiliserait l'état de l'itération précédente : une
        // `UniqueKey` force un écran neuf à chaque langue.
        await tester.pumpWidget(
          host(TimeEstimationRecordStore(StoreMemoire()),
              locale: locale, key: UniqueKey()),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.weTeIntroTooShortToCount), findsOneWidget,
            reason: '$locale');
        await tester.tap(find.text(l10n.weTeStart));
        await tester.pump();

        await presenter(tester, TimeEstimationRun.start(seed: graine));
        expect(find.text(l10n.weTePrompt), findsOneWidget, reason: '$locale');
        expect(find.text(l10n.weTeFirst), findsOneWidget, reason: '$locale');
        expect(find.text(l10n.weTeSecond), findsOneWidget, reason: '$locale');
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
