// L'écran du jeu de délai, joué de bout en bout.
//
// Ce que ces tests protègent, dans l'ordre d'importance :
//
// 1. « SOMMES IMAGINAIRES » EST DIT, ET REDIT. En toutes lettres à l'ouverture,
//    puis sur chacun des vingt écrans de choix. C'est la garde la plus
//    importante du lot : l'app vend un bilan par ailleurs, et quelqu'un qui
//    croirait avoir gagné 150 € répondrait pour toucher l'argent.
// 2. AUCUN RECORD, AUCUN « MEILLEUR ». Il n'y a pas de bonne réponse à un
//    arbitrage entre maintenant et plus tard. Rien à l'écran ne doit désigner
//    un bout de l'échelle comme supérieur à l'autre.
// 3. RIEN NE PART. Le résultat est un fichier local ; la file d'envoi de
//    l'événement porte des données de santé sous consentement art. 9.
// 4. LES DEUX OFFRES SONT INTERCHANGEABLES DE PRÉSENTATION et changent de
//    place — sinon on répond à l'endroit, ou à la mise en avant.
// 5. LE JEU RESTE FACULTATIF. « Plus tard » sort sans jouer.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/delay_choice/data/delay_choice_material.dart';
import 'package:mentality/features/waiting_event/delay_choice/data/delay_choice_record_store.dart';
import 'package:mentality/features/waiting_event/delay_choice/domain/services/delay_choice_run.dart';
import 'package:mentality/features/waiting_event/delay_choice/presentation/pages/delay_choice_game_page.dart';

/// Graine fixe : le test doit savoir quel délai et quelle position l'attendent.
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

/// Espion du service d'envoi : il compte, il n'envoie rien. Installé pour tout
/// le groupe, il évite aussi qu'un chemin oublié n'ouvre une box Hive.
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
  DelayChoiceRecordStore store, {
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
        home: DelayChoiceGamePage(store: store, seed: graine),
      ),
    );

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Lance la partie depuis l'écran d'introduction.
Future<void> demarrer(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.text(l10n.weDcStart));
  await tester.pumpAndSettle();
}

/// Joue les vingt choix avec la même réponse à chaque fois.
Future<void> jouerTout(WidgetTester tester, {required bool toutDeSuite}) async {
  for (var i = 0; i < DelayChoiceRun.delaysDays.length * DelayChoiceRun.stepsPerDelay; i++) {
    await tapKey(tester, offerKey(immediate: toutDeSuite));
  }
}

void main() {
  late _ServiceEspion espion;

  setUp(() {
    // Un test qui toucherait `EventUploadService.instance` ouvrirait une box
    // Hive non initialisée. L'espion ferme ce chemin pour tout le groupe.
    espion = _ServiceEspion();
    EventUploadService.debugSetInstance(espion);
  });

  // Un `static` mutable fuit d'un fichier de test à l'autre : on le repose.
  tearDown(() => EventUploadService.debugSetInstance(EventUploadService()));

  group('avertissement', () {
    testWidgets('★ l\'introduction dit que les sommes sont imaginaires',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weDcIntroImaginary), findsOneWidget);
      expect(find.text(l10n.weDcIntroNoRightAnswer), findsOneWidget);
    });

    testWidgets('★ le rappel accompagne l\'argent sur CHAQUE écran de choix',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      final total =
          DelayChoiceRun.delaysDays.length * DelayChoiceRun.stepsPerDelay;
      for (var i = 0; i < total; i++) {
        expect(find.text(l10n.weDcImaginaryTag), findsOneWidget,
            reason: 'écran de choix ${i + 1}');
        await tapKey(tester, offerKey(immediate: i.isEven));
      }
    });
  });

  group('la partie', () {
    testWidgets('les deux offres sont proposées, montants et échéances',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      expect(find.byKey(offerKey(immediate: true)), findsOneWidget);
      expect(find.byKey(offerKey(immediate: false)), findsOneWidget);
      // La somme différée est celle du jeu, écrite en euros dans une locale fr.
      expect(
        find.text(DelayChoiceMaterial.amount(
            DelayChoiceRun.delayedAmount, const Locale('fr'))),
        findsOneWidget,
      );
      // Le premier choix part à la moitié.
      expect(
        find.text(DelayChoiceMaterial.amount(75, const Locale('fr'))),
        findsOneWidget,
      );
    });

    testWidgets('★ les deux offres changent de place au fil de la partie',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      // On relève, essai par essai, laquelle des deux cartes est la plus haute.
      final immediateEnHaut = <bool>[];
      for (var i = 0; i < 8; i++) {
        final yImmediate =
            tester.getTopLeft(find.byKey(offerKey(immediate: true))).dy;
        final yDifferee =
            tester.getTopLeft(find.byKey(offerKey(immediate: false))).dy;
        immediateEnHaut.add(yImmediate < yDifferee);
        await tapKey(tester, offerKey(immediate: i.isEven));
      }
      expect(immediateEnHaut.toSet().length, 2,
          reason: 'les positions ne bougent jamais');
    });

    testWidgets('★ aucune des deux offres n\'est mise en avant', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);

      // Même taille de carte : une offre plus grande, plus colorée ou plus
      // haute suggérerait la bonne réponse, et le jeu ne mesurerait plus une
      // préférence mais l'obéissance à une mise en page.
      final immediate = tester.getSize(find.byKey(offerKey(immediate: true)));
      final differee = tester.getSize(find.byKey(offerKey(immediate: false)));
      expect(immediate, differee);
    });

    testWidgets('prendre toujours l\'immédiat mène au bout et à un résultat',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      expect(find.text(l10n.weDcResultTitle), findsOneWidget);
      // Quelqu'un qui ne veut jamais attendre : index au plancher, et c'est un
      // résultat parfaitement valable.
      expect(find.text(l10n.weDcPatienceScore(3)), findsOneWidget);
    });

    testWidgets('attendre toujours mène aussi à un résultat', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: false);

      expect(find.text(l10n.weDcResultTitle), findsOneWidget);
      expect(find.text(l10n.weDcPatienceScore(98)), findsOneWidget);
    });
  });

  group('le résultat', () {
    testWidgets('★ ni record ni « meilleur » n\'apparaissent nulle part',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      // Le lexique du classement est banni de cet écran : il désignerait un
      // bout de l'échelle comme supérieur à l'autre.
      final textes = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => (t.data ?? '').toLowerCase())
          .join(' ');
      for (final mot in [
        'record',
        'meilleur',
        'impulsi',
        'bravo',
        'félicitation',
      ]) {
        expect(textes.contains(mot), isFalse, reason: 'le mot « $mot » sort');
      }
    });

    testWidgets('les deux garde-fous de lecture sont affichés', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      await tester.ensureVisible(find.text(l10n.weDcNoBetterEnd));
      expect(find.text(l10n.weDcNoBetterEnd), findsOneWidget);
      expect(find.text(l10n.weDcNotClinical), findsOneWidget);
    });

    testWidgets('la phrase concrète redit le chiffre en langue humaine',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      const fr = Locale('fr');
      expect(
        find.text(l10n.weDcIndifference(
          DelayChoiceMaterial.amount(DelayChoiceRun.delayedAmount, fr),
          DelayChoiceMaterial.amount(3, fr),
        )),
        findsOneWidget,
      );
    });

    testWidgets('le tableau montre les cinq délais', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      await tester.ensureVisible(find.text(l10n.weDcCurveTitle));
      for (final jours in DelayChoiceRun.delaysDays) {
        expect(
          find.text(DelayChoiceMaterial.shortDelayLabel(jours)
              .resolve(const Locale('fr'))),
          findsOneWidget,
          reason: 'délai $jours',
        );
      }
    });

    testWidgets('★ « la dernière fois » n\'apparaît qu\'à la deuxième partie',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final store = DelayChoiceRecordStore(StoreMemoire());
      await tester.pumpWidget(host(store));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      // Première partie : rien à comparer, donc rien d'affiché — annoncer une
      // comparaison sur un passé vide serait une flatterie automatique.
      expect(find.text(l10n.weDcPrevious(3)), findsNothing);

      await tester.tap(find.text(l10n.weDcReplay));
      await tester.pumpAndSettle();
      await jouerTout(tester, toutDeSuite: true);

      await tester.ensureVisible(find.text(l10n.weDcPrevious(3)));
      expect(find.text(l10n.weDcPrevious(3)), findsOneWidget);
    });
  });

  group('ce qui est gardé, et ce qui ne part pas', () {
    testWidgets('★ RIEN n\'est envoyé, ni pendant ni après', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(DelayChoiceRecordStore(StoreMemoire())));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      expect(espion.envois, 0);
      expect(espion.rejeux, 0);
    });

    testWidgets('★ le stockage ne garde QUE la dernière partie et le compte',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(DelayChoiceRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await jouerTout(tester, toutDeSuite: true);

      final garde = memoire.data[DelayChoiceRecordStore.moduleId]!;
      // Aucune clé de record : l'absence est le contrat, pas un oubli.
      expect(garde.answers.keys.toSet(), {
        DelayChoiceRecordStore.lastKey,
        DelayChoiceRecordStore.playsKey,
      });
      expect(garde.valueOf(DelayChoiceRecordStore.lastKey), 3);
      expect(garde.valueOf(DelayChoiceRecordStore.playsKey), 1);
    });

    testWidgets('une partie abandonnée n\'écrit rien', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final memoire = StoreMemoire();
      await tester.pumpWidget(host(DelayChoiceRecordStore(memoire)));
      await tester.pumpAndSettle();
      await demarrer(tester, l10n);
      await tapKey(tester, offerKey(immediate: true));

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
                      builder: (_) => DelayChoiceGamePage(
                        store: DelayChoiceRecordStore(memoire),
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

      await tester.tap(find.text(l10n.weDcLater));
      await tester.pumpAndSettle();

      expect(find.text('ouvrir'), findsOneWidget);
      expect(memoire.data, isEmpty);
    });
  });

  group('six langues', () {
    testWidgets('★ l\'avertissement et les offres tiennent dans les six',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        ecranTelephone(tester);
        final l10n = await AppLocalizations.delegate.load(locale);
        // Re-`pumpWidget` réutiliserait l'état de l'itération précédente : une
        // `UniqueKey` force un écran neuf à chaque langue.
        await tester.pumpWidget(
          host(DelayChoiceRecordStore(StoreMemoire()),
              locale: locale, key: UniqueKey()),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.weDcIntroImaginary), findsOneWidget,
            reason: '$locale');
        await tester.tap(find.text(l10n.weDcStart));
        await tester.pumpAndSettle();

        expect(find.text(l10n.weDcImaginaryTag), findsOneWidget,
            reason: '$locale');
        // Le montant s'écrit dans la devise de la langue, jamais converti.
        expect(
          find.text(DelayChoiceMaterial.amount(
              DelayChoiceRun.delayedAmount, locale)),
          findsOneWidget,
          reason: '$locale',
        );
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
