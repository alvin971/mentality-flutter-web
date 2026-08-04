// L'écran du Stroop, joué de bout en bout.
//
// Ce que ces tests protègent, dans l'ordre d'importance :
//
// 1. AUCUNE VITESSE BRUTE À L'ÉCRAN. Le calcul est déjà gardé par
//    `stroop_score_test`, mais rien n'empêcherait un écran d'afficher les deux
//    médianes « pour information » — et de remesurer le PSI par la bande.
// 2. LES BOUTONS NE SONT PAS COLORÉS. Peints chacun dans leur teinte, ils
//    permettraient de répondre en appariant deux couleurs sans jamais nommer
//    quoi que ce soit : l'interférence lexicale disparaîtrait.
// 3. RIEN NE PART. Le record est un fichier local ; la file d'envoi de
//    l'événement porte des données de santé sous consentement art. 9, un
//    résultat de jeu n'a rien à y faire.
// 4. LE JEU RESTE FACULTATIF. « Plus tard » sort sans jouer, et la journée
//    continue.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/widgets/test/kepler_stimulus_surface.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/stroop/data/stroop_material.dart';
import 'package:mentality/features/waiting_event/stroop/data/stroop_record_store.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_score.dart';
import 'package:mentality/features/waiting_event/stroop/domain/models/stroop_trial.dart';
import 'package:mentality/features/waiting_event/stroop/domain/services/stroop_chrono.dart';
import 'package:mentality/features/waiting_event/stroop/domain/services/stroop_sequence.dart';
import 'package:mentality/features/waiting_event/stroop/presentation/pages/stroop_game_page.dart';
import 'package:mentality/features/waiting_event/stroop/presentation/widgets/stroop_stimulus.dart';

/// Graine fixe : le test doit savoir quelle encre l'attend à chaque essai.
const int graine = 4242;

/// Chronomètre piloté par le test. Un vrai `Stopwatch` renverrait quelques
/// millisecondes par `pump()`, donc sous le seuil d'anticipation : toute la
/// passation tomberait hors médiane.
class ChronoFactice implements StroopChrono {
  int prochain = 600;
  int demarrages = 0;

  @override
  void start() => demarrages++;

  @override
  int get elapsedMs => prochain;
}

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

/// `KeplerProgress` met son étiquette EN MAJUSCULES. Chercher le libellé tel
/// qu'il est écrit dans l'ARB ne trouverait rien.
String etiquette(String label) => label.toUpperCase();

Widget host(
  StroopRecordStore store, {
  required ChronoFactice chrono,
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
        home: StroopGamePage(store: store, chrono: chrono, seed: graine),
      ),
    );

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Joue la passation entière : [msNeutre] et [msConflit] fixent les temps de
/// réponse, [fauxAPartirDe] fait répondre à côté à partir de cet essai compté.
Future<void> jouerToute(
  WidgetTester tester,
  ChronoFactice chrono, {
  int msNeutre = 600,
  int msConflit = 800,
  int fauxAPartirDe = 1 << 30,
  int? arreterApres,
}) async {
  final essais = StroopSequence.build(seed: graine);
  var compte = 0;

  for (var i = 0; i < essais.length; i++) {
    if (arreterApres != null && i >= arreterApres) return;
    final essai = essais[i];

    // Chaque bloc s'ouvre par un écran d'annonce.
    if (find.byType(StroopStimulus).evaluate().isEmpty) {
      await tapText(tester, 'Continuer');
    }

    chrono.prochain =
        essai.condition == StroopCondition.neutral ? msNeutre : msConflit;

    if (essai.scored) compte++;
    final aCoteDeLaPlaque = essai.scored && compte > fauxAPartirDe;
    final choix = aCoteDeLaPlaque
        ? StroopInk.values.firstWhere((e) => e != essai.ink)
        : essai.ink;

    await tapKey(tester, answerKey(choix));
  }
}

void main() {
  late StoreMemoire disque;
  late StroopRecordStore store;
  late ChronoFactice chrono;
  late _ServiceEspion espion;

  setUp(() {
    disque = StoreMemoire();
    store = StroopRecordStore(disque);
    chrono = ChronoFactice();
    espion = _ServiceEspion();
    EventUploadService.debugSetInstance(espion);
  });

  group('le déroulé', () {
    testWidgets('l\'introduction montre un exemple contrarié avant de lancer',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();

      expect(find.text('Nomme la couleur, pas le mot'), findsOneWidget);
      expect(find.byType(StroopStimulus), findsOneWidget,
          reason: 'la consigne se comprend en une seconde devant un exemple');
      expect(find.byKey(answerKey(StroopInk.rouge)), findsNothing,
          reason: 'l\'exemple ne se répond pas');
    });

    testWidgets('« Plus tard » sort sans jouer et sans rien enregistrer',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScreenUtilInit(
                  designSize: const Size(375, 812),
                  builder: (_, __) =>
                      StroopGamePage(store: store, chrono: chrono),
                ),
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ));
      await tapText(tester, 'ouvrir');

      await tapText(tester, 'Plus tard');

      expect(find.byType(StroopGamePage), findsNothing);
      expect(disque.data, isEmpty,
          reason: 'un jeu facultatif refusé ne laisse aucune trace');
    });

    testWidgets('la passation complète débouche sur l\'écart, pas sur un temps',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      await jouerToute(tester, chrono, msNeutre: 600, msConflit: 800);

      expect(find.text('Ton écart'), findsOneWidget);
      expect(find.text('200 ms'), findsOneWidget);
      expect(find.text('600 ms'), findsNothing,
          reason: 'la médiane neutre est une VITESSE — le PSI la mesure déjà');
      expect(find.text('800 ms'), findsNothing,
          reason: 'la médiane en conflit est une vitesse elle aussi');
    });

    testWidgets('la justesse est rapportée à part, jamais fondue dans le temps',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      // Les 4 derniers essais comptés sont répondus à côté.
      await jouerToute(tester, chrono, fauxAPartirDe: 32);

      expect(find.text('32 bonnes réponses sur 36'), findsOneWidget);
      expect(find.text('Ton écart'), findsOneWidget,
          reason: 'quatre erreurs ne suffisent pas à rendre la partie '
              'inexploitable');
    });

    testWidgets('les essais d\'entraînement sont annoncés comme tels',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      expect(find.text(etiquette('Entraînement')), findsOneWidget);
      expect(find.text(etiquette('Compté')), findsNothing);

      await jouerToute(tester, chrono,
          arreterApres: StroopSequence.practiceCount);
      await tapText(tester, 'Continuer');

      expect(find.text(etiquette('Compté')), findsOneWidget);
      expect(find.text(etiquette('Entraînement')), findsNothing);
    });
  });

  group('le matériel à l\'écran', () {
    testWidgets('le stimulus est posé sur le panneau à luminance fixe',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      expect(
        find.descendant(
          of: find.byType(StroopStimulus),
          matching: find.byType(KeplerStimulusSurface),
        ),
        findsOneWidget,
        reason: 'sur le fond de page, le rapport figure/fond changerait avec '
            'le thème — deux personnes ne joueraient plus le même jeu',
      );
    });

    testWidgets('★ les boutons de réponse ne sont pas peints dans leur teinte',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      final couleurs = <Color?>[];
      for (final encre in StroopInk.values) {
        final texte = tester.widget<Text>(find.descendant(
          of: find.byKey(answerKey(encre)),
          matching: find.byType(Text),
        ));
        couleurs.add(texte.style?.color);
      }

      expect(couleurs.toSet(), hasLength(1),
          reason: 'des boutons colorés se répondraient par appariement de '
              'couleurs, sans jamais nommer : l\'interférence lexicale — tout '
              'l\'objet de la mesure — disparaîtrait');
    });

    testWidgets('l\'ordre des boutons ne bouge pas d\'un essai à l\'autre',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      List<double> positions() => [
            for (final encre in StroopInk.values)
              tester.getTopLeft(find.byKey(answerKey(encre))).dy
          ];

      final avant = positions();
      await jouerToute(tester, chrono, arreterApres: 2);
      expect(positions(), avant,
          reason: 'des boutons mobiles mesureraient la recherche visuelle du '
              'bouton, pas l\'inhibition');
    });

    testWidgets('les six langues rendent leurs trois boutons', (tester) async {
      for (final tag in ['fr', 'en', 'en_GB', 'de', 'es', 'pt']) {
        final parts = tag.split('_');
        final locale = parts.length == 1
            ? Locale(parts[0])
            : Locale(parts[0], parts[1]);
        final memoire = StoreMemoire();
        ecranTelephone(tester);
        // `UniqueKey` : sans elle, re-`pumpWidget` RÉUTILISE l'état de
        // l'itération précédente — la page serait déjà passé l'introduction,
        // et le test échouerait à trouver le bouton de départ.
        await tester.pumpWidget(
          host(StroopRecordStore(memoire),
              chrono: ChronoFactice(), locale: locale, key: UniqueKey()),
        );
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        await tapText(tester, l10n.weStroopStart);

        for (final encre in StroopInk.values) {
          final attendu = StroopMaterial.nameOf(encre).resolve(locale);
          expect(
            find.descendant(
              of: find.byKey(answerKey(encre)),
              matching: find.text(attendu),
            ),
            findsOneWidget,
            reason: '$tag : le bouton $encre devrait dire « $attendu »',
          );
        }
      }
    });
  });

  group('le record, et rien d\'autre', () {
    testWidgets('★ aucune donnée ne rejoint la file d\'envoi', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      await jouerToute(tester, chrono);

      expect(espion.envois, 0,
          reason: 'la file d\'envoi porte des données de santé sous '
              'consentement art. 9 ; un résultat de jeu n\'y a pas sa place');
      expect(espion.rejeux, 0);
    });

    testWidgets('une partie fiable s\'enregistre, une seconde garde le '
        'meilleur écart', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');
      await jouerToute(tester, chrono, msNeutre: 600, msConflit: 800);

      expect((await store.read()).bestInterferenceMs, 200);
      expect(find.text('Nouveau meilleur écart'), findsOneWidget);

      // Deuxième partie, moins bonne : le record ne bouge pas.
      await tapText(tester, 'Rejouer');
      await jouerToute(tester, chrono, msNeutre: 600, msConflit: 950);

      final apres = await store.read();
      expect(apres.bestInterferenceMs, 200,
          reason: 'meilleur = le plus PETIT écart');
      expect(apres.lastInterferenceMs, 350);
      expect(apres.plays, 2);
      expect(find.text('Ton meilleur écart : 200 ms'), findsOneWidget);
      expect(find.text('Nouveau meilleur écart'), findsNothing);
    });

    testWidgets('une partie de réponses au hasard n\'annonce aucun écart et '
        'laisse le record intact', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');
      await jouerToute(tester, chrono);
      expect((await store.read()).bestInterferenceMs, 200);

      await tapText(tester, 'Rejouer');
      // Tout faux : plus aucun temps exploitable.
      await jouerToute(tester, chrono, fauxAPartirDe: 0);

      expect(find.text('Trop peu de réponses pour compter'), findsOneWidget);
      expect(find.textContaining(' ms'), findsNothing,
          reason: 'aucun chiffre ne doit être annoncé, même nuancé');
      final apres = await store.read();
      expect(apres.bestInterferenceMs, 200, reason: 'le record reste intact');
      expect(apres.plays, 1, reason: 'une partie non fiable ne compte pas');
    });

    testWidgets('un appui trop rapide pour être une réponse est ignoré, et '
        'l\'essai reste posé', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(store, chrono: chrono));
      await tester.pumpAndSettle();
      await tapText(tester, 'Commencer');

      final premier = StroopSequence.build(seed: graine).first;
      chrono.prochain = 20; // la fin du geste précédent, pas une réponse
      await tapKey(tester, answerKey(premier.ink));

      expect(find.text(etiquette('Entraînement')), findsOneWidget,
          reason: 'toujours le premier essai : rien n\'a été consommé');
    });
  });

  testWidgets('les deux garde-fous de lecture sont toujours affichés',
      (tester) async {
    ecranTelephone(tester);
    await tester.pumpWidget(host(store, chrono: chrono));
    await tester.pumpAndSettle();
    await tapText(tester, 'Commencer');
    await jouerToute(tester, chrono);

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.weStroopNotSpeed), findsOneWidget);
    expect(find.text(l10n.weStroopNotClinical), findsOneWidget);
  });

  test('les seuils du score et ceux de l\'écran restent cohérents', () {
    // Un bloc doit pouvoir fournir le minimum d'essais valides ; sinon le jeu
    // serait « non fiable » par construction, quoi qu'on joue.
    expect(StroopSequence.blockLength,
        greaterThanOrEqualTo(StroopScore.minTrialsPerCondition));
  });
}
