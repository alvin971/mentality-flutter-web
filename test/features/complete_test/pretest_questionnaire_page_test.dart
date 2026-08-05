// Le questionnaire préalable, monté pour de vrai, avant le premier sous-test.
//
// Ce qui se vérifie ici et pas au niveau de la donnée : l'embranchement (une
// mesure et une croyance ne se demandent pas aux mêmes personnes), le verrou
// anti-saut sur la question obligatoire, et surtout le fait que fermer l'écran
// en cours de route ne laisse RIEN derrière — l'écriture étant unique, un
// demi-questionnaire enregistré condamnerait sa moitié manquante pour toujours.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/widgets/kepler_button.dart';
import 'package:mentality/core/widgets/kepler_card.dart';
import 'package:mentality/features/complete_test/data/pretest_store.dart';
import 'package:mentality/features/complete_test/domain/models/pretest_answers.dart';
import 'package:mentality/features/complete_test/presentation/pages/pretest_questionnaire_page.dart';
import 'package:mentality/features/complete_test/presentation/pretest_chain.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';

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

// ─── Libellés attendus (locale fr) ──────────────────────────────────────────

const kPro = 'Oui, avec un psychiatre ou un psychologue';
const kEnLigne = 'Oui, un test en ligne peu fiable';
const kJamais = 'Non, jamais — mais j\'ai toujours voulu en faire un';
const kContinuer = 'Continuer';
const kRetour = 'Retour';
const kEcranFacultatif = 'Deux questions facultatives';
const kEcranEstimation = 'À combien estimes-tu ton QI ?';
const kValider = 'Valider mon estimation';
const kRefus = 'Je préfère ne pas répondre';

/// Le second écran attendu selon la branche — utilisé par le balayage des six
/// langues, qui se pilote par widgets et non par libellés.
enum _EcranAttendu { champs, estimation }

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// L'écran est monté DERRIÈRE une route : c'est sa situation réelle (il est
/// poussé depuis le bouton de lancement) et c'est la seule façon de tester ce
/// que devient la pile quand il se referme.
class _Hote extends StatefulWidget {
  const _Hote({super.key, required this.store});

  final PretestStore store;

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  /// Ce que `ensurePretest` a renvoyé — c'est-à-dire : la batterie démarre-t-elle ?
  bool? resultat;
  int appels = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              appels++;
              final ok = await ensurePretest(context, store: widget.store);
              setState(() => resultat = ok);
            },
            child: const Text('LANCER'),
          ),
        ),
      );
}

Widget host(Widget child, {Locale locale = const Locale('fr')}) =>
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
        home: child,
      ),
    );

void main() {
  late StoreMemoire disque;
  late PretestStore pretest;

  setUp(() {
    disque = StoreMemoire();
    pretest = PretestStore(store: disque);
  });

  Map<String, int> ecrit() =>
      disque.data[PretestStore.moduleId]?.answers ?? const {};

  /// Monte l'hôte et ouvre le questionnaire.
  Future<_HoteState> ouvrir(WidgetTester tester) async {
    ecranTelephone(tester);
    final cle = GlobalKey<_HoteState>();
    await tester.pumpWidget(host(_Hote(key: cle, store: pretest)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LANCER'));
    await tester.pumpAndSettle();
    return cle.currentState!;
  }

  KeplerButton bouton(WidgetTester tester, String label) =>
      tester.widget<KeplerButton>(find.widgetWithText(KeplerButton, label));

  group('la question obligatoire', () {
    testWidgets('n\'a aucune modalité pré-cochée, et le bouton reste inerte',
        (tester) async {
      await ouvrir(tester);

      expect(find.text(kPro), findsOneWidget);
      expect(find.text(kEnLigne), findsOneWidget);
      expect(find.text(kJamais), findsOneWidget);

      expect(bouton(tester, kContinuer).onPressed, isNull,
          reason: 'une valeur par défaut partirait comme une réponse que '
              'personne n\'a donnée');

      await tester.tap(find.text(kJamais));
      await tester.pumpAndSettle();
      expect(bouton(tester, kContinuer).onPressed, isNotNull);
    });

    testWidgets('annonce que rien ne quitte l\'appareil', (tester) async {
      await ouvrir(tester);
      expect(find.textContaining('restent sur ton téléphone'), findsOneWidget);
    });
  });

  group('l\'embranchement', () {
    testWidgets('« chez un professionnel » mène à l\'âge et au score, '
        'jamais à l\'estimation', (tester) async {
      await ouvrir(tester);
      await tester.tap(find.text(kPro));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      expect(find.text(kEcranFacultatif), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text(kEcranEstimation), findsNothing,
          reason: 'qui connaît son score répondrait avec ce score : ce ne '
              'serait plus une croyance');
    });

    for (final choix in const [kEnLigne, kJamais]) {
      testWidgets('« $choix » mène à l\'estimation, sans champ de score',
          (tester) async {
        await ouvrir(tester);
        await tester.tap(find.text(choix));
        await tester.pumpAndSettle();
        await tester.tap(find.text(kContinuer));
        await tester.pumpAndSettle();

        expect(find.text(kEcranEstimation), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text(kEcranFacultatif), findsNothing);
      });
    }

    testWidgets('se corrige : le retour ramène au choix et change de branche',
        (tester) async {
      await ouvrir(tester);
      await tester.tap(find.text(kPro));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();
      expect(find.text(kEcranFacultatif), findsOneWidget);

      await tester.tap(find.text(kRetour));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kJamais));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      expect(find.text(kEcranEstimation), findsOneWidget);
      expect(ecrit(), isEmpty,
          reason: 'aucune des deux branches n\'a été menée à son terme');
    });
  });

  group('les champs facultatifs', () {
    testWidgets('laissés vides, n\'empêchent pas de continuer', (tester) async {
      final hote = await ouvrir(tester);
      await tester.tap(find.text(kPro));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      expect(bouton(tester, kContinuer).onPressed, isNotNull,
          reason: 'un bouton inerte devant des champs vides ferait croire '
              'qu\'ils sont obligatoires');
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      expect(ecrit()[PretestAnswers.itemPriorTest], 1);
      expect(ecrit().containsKey(PretestAnswers.itemAgeAtTest), isFalse);
      expect(hote.resultat, isTrue, reason: 'la batterie doit démarrer');
    });

    testWidgets('remplis, sont enregistrés', (tester) async {
      await ouvrir(tester);
      await tester.tap(find.text(kPro));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '12');
      await tester.enterText(find.byType(TextField).at(1), '128');
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      expect(ecrit()[PretestAnswers.itemAgeAtTest], 12);
      expect(ecrit()[PretestAnswers.itemPriorScore], 128);
    });

    testWidgets('hors bornes, affichent une erreur et ne sont pas écrits',
        (tester) async {
      await ouvrir(tester);
      await tester.tap(find.text(kPro));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '999');
      await tester.pumpAndSettle();
      expect(find.text('Un score entre 40 et 200.'), findsOneWidget);

      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();
      expect(ecrit().containsKey(PretestAnswers.itemPriorScore), isFalse,
          reason: 'une faute de frappe ne se ramène pas silencieusement à '
              'la borne la plus proche');
    });
  });

  group('l\'auto-estimation', () {
    Future<void> allerAEstimation(WidgetTester tester) async {
      await tester.tap(find.text(kJamais));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();
    }

    testWidgets('reste inerte tant que la valeur n\'a pas été touchée',
        (tester) async {
      await ouvrir(tester);
      await allerAEstimation(tester);

      expect(bouton(tester, kValider).onPressed, isNull,
          reason: '100 est une valeur de départ, pas une réponse');

      await tester.tap(find.byTooltip('Augmenter d\'un point'));
      await tester.pumpAndSettle();
      expect(bouton(tester, kValider).onPressed, isNotNull);
    });

    testWidgets('validée, s\'enregistre dans son propre stockage',
        (tester) async {
      final hote = await ouvrir(tester);
      await allerAEstimation(tester);

      await tester.tap(find.byTooltip('Augmenter d\'un point'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kValider));
      await tester.pumpAndSettle();

      expect((await SelfEstimateStore(disque).read()).value, 101);
      expect(ecrit()[PretestAnswers.itemPriorTest], 3);
      expect(hote.resultat, isTrue);
    });

    testWidgets('refusée, clôt la question et lance quand même la batterie',
        (tester) async {
      final hote = await ouvrir(tester);
      await allerAEstimation(tester);

      await tester.tap(find.text(kRefus));
      await tester.pumpAndSettle();

      final estimation = await SelfEstimateStore(disque).read();
      expect(estimation.value, isNull);
      expect(estimation.declined, isTrue);
      expect(hote.resultat, isTrue);
    });
  });

  group('sortir en cours de route', () {
    testWidgets('n\'écrit rien et ne lance pas la batterie', (tester) async {
      final hote = await ouvrir(tester);
      await tester.tap(find.text(kEnLigne));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();
      expect(find.text(kEcranEstimation), findsOneWidget);

      // Le retour système : l'utilisateur ressort du questionnaire.
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await tester.pumpAndSettle();

      expect(ecrit(), isEmpty,
          reason: 'l\'écriture est unique : un demi-questionnaire enregistré '
              'condamnerait sa moitié manquante pour toujours');
      expect(hote.resultat, isFalse,
          reason: 'la question obligatoire l\'est vraiment — on revient à '
              'l\'écran de lancement au lieu de démarrer le test');
    });
  });

  group('la question ne se repose jamais', () {
    testWidgets('un second lancement n\'ouvre plus le questionnaire',
        (tester) async {
      final hote = await ouvrir(tester);
      await tester.tap(find.text(kJamais));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kContinuer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(kRefus));
      await tester.pumpAndSettle();

      // Deuxième appui sur « Lancer » — c'est exactement le chemin de la
      // reprise d'un test interrompu.
      await tester.tap(find.text('LANCER'));
      await tester.pumpAndSettle();

      expect(find.text(kJamais), findsNothing,
          reason: 'redemander son estimation à quelqu\'un qui a déjà vu des '
              'exercices ferait de la question un péage');
      expect(hote.appels, 2);
      expect(hote.resultat, isTrue);
    });
  });

  group('les six langues', () {
    for (final locale in const [
      Locale('fr'),
      Locale('en'),
      Locale('en', 'GB'),
      Locale('es'),
      Locale('pt'),
      Locale('de'),
    ]) {
      testWidgets('$locale : les trois écrans se rendent sans déborder',
          (tester) async {
        // Le pilotage passe par les widgets, pas par les libellés : un test
        // qui épellerait les traductions ne vérifierait plus que lui-même.
        // Les trois cartes de l'écran 1 sont les trois modalités, dans
        // l'ordre de `PriorIqTest`.
        for (final (indice, attendu) in const [
          (0, _EcranAttendu.champs),
          (2, _EcranAttendu.estimation),
        ]) {
          ecranTelephone(tester);
          // Démontage réel entre deux passes : re-`pumpWidget` d'un écran du
          // même type réutiliserait le `State` existant et repartirait de
          // l'écran où la passe précédente s'était arrêtée.
          await tester.pumpWidget(host(const SizedBox.shrink()));
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            host(PretestQuestionnairePage(store: PretestStore(store: StoreMemoire())),
                locale: locale),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'écran 1 illisible en $locale');
          expect(find.byType(KeplerCard), findsNWidgets(3));

          await tester.tap(find.byType(KeplerCard).at(indice));
          await tester.pumpAndSettle();
          // Le bouton principal est le dernier de la barre.
          await tester.tap(find.byType(KeplerButton).last);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'écran 2 illisible en $locale');
          expect(find.byType(TextField),
              attendu == _EcranAttendu.champs
                  ? findsNWidgets(2)
                  : findsNothing);
          expect(find.byType(Slider),
              attendu == _EcranAttendu.estimation
                  ? findsOneWidget
                  : findsNothing);
        }
      });
    }
  });
}
