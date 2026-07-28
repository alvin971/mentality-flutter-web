// LE GATE ART. 9 — la seule porte, et elle est fermée par défaut.
//
// Ce fichier vérifie un ORDRE et une IMPOSSIBILITÉ, pas une apparence :
// aucun chemin de l'app ne doit mener aux questions de santé avant que le
// consentement explicite n'ait été accordé ET écrit. La nuance « et écrit »
// est tout l'enjeu : un écran qui enchaînerait sur l'intention de
// l'utilisateur plutôt que sur le résultat de l'écriture collecterait des
// déclarations de santé que plus rien n'autoriserait à envoyer — et la
// personne, elle, croirait avoir accepté.
//
// Le gate est DUR ici, alors qu'il est souple pour les questionnaires du
// programme (jouables sans consentement, score affiché, rien d'envoyé). La
// différence est assumée : le bloc diagnostic n'affiche aucun résultat et ne
// calcule rien. Le faire remplir sans pouvoir l'exploiter, ce serait prendre
// deux écrans de déclarations de santé pour rien.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/consent/consent_record.dart';
import 'package:mentality/core/consent/consent_service.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_local_store.dart';
import 'package:mentality/features/waiting_event/_shared/data/event_upload_service.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_submission.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/q_answer_set.dart';
import 'package:mentality/features/waiting_event/_shared/domain/services/event_consent.dart';
import 'package:mentality/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/data/diagnostic_block_store.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/domain/models/diagnostic_answers.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/presentation/pages/diagnostic_block_page.dart';
import 'package:mentality/features/waiting_event/diagnostic_block/presentation/pages/event_consent_page.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';
import 'package:mentality/features/waiting_event/reveals/domain/services/reveal_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compte les rejeux sans toucher au réseau ni au disque.
class _ServiceEspion extends EventUploadService {
  int rejeux = 0;

  @override
  Future<Map<String, EventUploadOutcome>> retryPending() async {
    rejeux++;
    return const {};
  }
}

class StoreMemoire implements EventAnswerStore {
  final Map<String, QAnswerSet> data = {};

  @override
  Future<QAnswerSet?> load(String moduleId) async => data[moduleId];

  @override
  Future<void> save(QAnswerSet answers) async => data[answers.moduleId] = answers;

  @override
  Future<void> clear(String moduleId) async => data.remove(moduleId);
}

/// Le consentement art. 9, scénarisable. [ecritureOk] rejoue le cas d'un
/// stockage qui refuse : l'utilisateur a dit oui, rien n'a été gardé.
class ConsentFaux implements EventConsent {
  ConsentFaux({this.accorde = false, this.ecritureOk = true});

  bool accorde;
  final bool ecritureOk;
  int ecritures = 0;

  @override
  Future<bool> isGranted() async => accorde;

  @override
  Future<bool> setGranted(bool granted) async {
    ecritures++;
    if (!ecritureOk) return false;
    accorde = granted;
    return true;
  }
}

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget host({
  required DiagnosticBlockStore diagnostic,
  required EventConsent consent,
  required SelfEstimateStore estimation,
  Locale locale = const Locale('fr'),
}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        key: UniqueKey(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DayHubPage(
          serverDayIndex: 1,
          revealSource: RevealSource(load: () async => []),
          selfEstimateStore: estimation,
          diagnosticStore: diagnostic,
          eventConsent: consent,
        ),
      ),
    );

/// Le hub DÉFILE : sans `ensureVisible`, un tap sur une carte basse ne touche
/// rien et le test passe pour la mauvaise raison.
Future<void> toucher(WidgetTester tester, String texte) async {
  await tester.ensureVisible(find.text(texte));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texte), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  late StoreMemoire disque;
  late List<EventSubmission> envois;
  late DiagnosticBlockStore diagnostic;
  late SelfEstimateStore estimation;
  late AppLocalizations l10n;

  setUp(() async {
    disque = StoreMemoire();
    envois = [];
    diagnostic = DiagnosticBlockStore(
      store: disque,
      submit: (s) async => envois.add(s),
    );
    estimation = SelfEstimateStore(StoreMemoire());
    // Les libellés de boutons sont TRADUITS : les charger, jamais les écrire
    // en dur.
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  group('rien avant le consentement', () {
    testWidgets('la carte mène au recueil, PAS aux questions de santé',
        (tester) async {
      ecranTelephone(tester);
      final consent = ConsentFaux();
      await tester.pumpWidget(host(
          diagnostic: diagnostic, consent: consent, estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);

      expect(find.byType(EventConsentPage), findsOneWidget);
      expect(find.byType(DiagnosticBlockPage), findsNothing,
          reason: 'une question de santé posée avant l\'accord serait '
              'collectée sans base légale');
    });

    testWidgets('un refus n\'ouvre rien et n\'écrit rien', (tester) async {
      ecranTelephone(tester);
      final consent = ConsentFaux();
      await tester.pumpWidget(host(
          diagnostic: diagnostic, consent: consent, estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);
      await tester.tap(find.text(l10n.weCsDecline));
      await tester.pumpAndSettle();

      expect(find.byType(DiagnosticBlockPage), findsNothing);
      expect(consent.accorde, isFalse);
      expect(disque.data, isEmpty);
      expect(envois, isEmpty);
      // Et on explique pourquoi le bloc ne s'ouvre pas, plutôt que de ne rien
      // faire du tout.
      expect(find.text(l10n.weDxDeclinedTitle), findsOneWidget);
    });

    testWidgets('un refus laisse la carte en place — on peut revenir',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(
          diagnostic: diagnostic,
          consent: ConsentFaux(),
          estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);
      await tester.tap(find.text(l10n.weCsDecline));
      await tester.pumpAndSettle();
      // On referme le message.
      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weDxCardSubtitle), findsOneWidget);
    });

    testWidgets('un accord que le stockage refuse n\'ouvre PAS le bloc',
        (tester) async {
      ecranTelephone(tester);
      final consent = ConsentFaux(ecritureOk: false);
      await tester.pumpWidget(host(
          diagnostic: diagnostic, consent: consent, estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);
      await tester.tap(find.text(l10n.weCsAccept));
      await tester.pumpAndSettle();

      expect(consent.ecritures, 1, reason: 'l\'écriture a bien été tentée');
      expect(find.byType(DiagnosticBlockPage), findsNothing,
          reason: 'l\'écran doit enchaîner sur le RÉSULTAT de l\'écriture, '
              'jamais sur l\'intention de l\'utilisateur');
      expect(find.text(l10n.weDxDeclinedTitle), findsOneWidget);
    });

    testWidgets('un accord écrit ouvre le bloc', (tester) async {
      ecranTelephone(tester);
      final consent = ConsentFaux();
      await tester.pumpWidget(host(
          diagnostic: diagnostic, consent: consent, estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);
      await tester.tap(find.text(l10n.weCsAccept));
      await tester.pumpAndSettle();

      expect(consent.accorde, isTrue);
      expect(find.byType(DiagnosticBlockPage), findsOneWidget);
    });

    testWidgets('un consentement déjà accordé ne se redemande pas',
        (tester) async {
      ecranTelephone(tester);
      final consent = ConsentFaux(accorde: true);
      await tester.pumpWidget(host(
          diagnostic: diagnostic, consent: consent, estimation: estimation));
      await tester.pumpAndSettle();

      await toucher(tester, l10n.weDxCardSubtitle);

      expect(find.byType(EventConsentPage), findsNothing);
      expect(find.byType(DiagnosticBlockPage), findsOneWidget);
      expect(consent.ecritures, 0);
    });
  });

  group('le parcours complet', () {
    Future<void> ouvrirLeBloc(WidgetTester tester) async {
      await tester.pumpWidget(host(
          diagnostic: diagnostic,
          consent: ConsentFaux(accorde: true),
          estimation: estimation));
      await tester.pumpAndSettle();
      await toucher(tester, l10n.weDxCardSubtitle);
    }

    testWidgets('« aucun » saute le détail et clôt la question',
        (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxNone);
      await toucher(tester, l10n.weRunnerNext);

      expect(find.text(l10n.weDxSourceQuestion), findsNothing,
          reason: 'il n\'y a rien à détailler quand rien n\'est déclaré');
      expect(find.text(l10n.weDxDoneTitle), findsOneWidget);
      expect(envois.single.answers, {'none': 1});
    });

    testWidgets('un trouble coché passe par son détail, puis part',
        (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxAdhd);
      await toucher(tester, l10n.weRunnerNext);

      // Le nom du trouble est répété dans le CORPS : la barre de titre a une
      // hauteur fixe et ellipse les libellés longs.
      expect(find.text(l10n.weDxAdhd), findsOneWidget);
      // Le bouton reste inerte tant que les quatre réponses ne sont pas là.
      await toucher(tester, l10n.weRunnerFinish);
      expect(find.text(l10n.weDxDoneTitle), findsNothing,
          reason: 'un détail à trous n\'est pas une déclaration');

      await toucher(tester, l10n.weDxSourcePsychiatrist);
      await toucher(tester, l10n.weDxWhenUnder1);
      await toucher(tester, l10n.weDxTreatmentYes);
      await toucher(tester, l10n.weDxAssessmentUnknown);
      await toucher(tester, l10n.weRunnerFinish);

      expect(find.text(l10n.weDxDoneTitle), findsOneWidget);
      expect(envois.single.answers, {
        'dx.adhd': 1,
        'dx.adhd.source': 1,
        'dx.adhd.recency': 1,
        'dx.adhd.treatment': 1,
        'dx.adhd.assessment': 3,
      });
    });

    testWidgets('la carte disparaît une fois la question close',
        (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxNone);
      await toucher(tester, l10n.weRunnerNext);
      await toucher(tester, l10n.weRunnerDoneCta);

      expect(find.text(l10n.weDxCardSubtitle), findsNothing,
          reason: 'posé une seule fois : la proposer encore serait la '
              'promesse d\'une question qui sera refusée');
    });

    testWidgets('« aucun » et un trouble coché ne coexistent jamais',
        (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxAdhd);
      await toucher(tester, l10n.weDxNone);
      await toucher(tester, l10n.weRunnerNext);

      expect(envois.single.answers, {'none': 1},
          reason: 'cocher « aucun » doit décocher le reste : la forme mixte '
              'n\'a aucune lecture défendable à l\'analyse');
    });

    testWidgets('le refus de répondre efface la sélection et s\'envoie seul',
        (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxAutism);
      await toucher(tester, l10n.weDxPreferNotToSay);
      await toucher(tester, l10n.weRunnerNext);

      expect(envois.single.answers, {'declined': 1});
    });

    testWidgets('quitter en route n\'enregistre rien', (tester) async {
      ecranTelephone(tester);
      await ouvrirLeBloc(tester);

      await toucher(tester, l10n.weDxAdhd);
      // La charte Kepler dessine son propre bouton de retour : `pageBack()`
      // ne le trouve pas.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.weRunnerQuitLeave));
      await tester.pumpAndSettle();

      expect(disque.data, isEmpty);
      expect(envois, isEmpty);
      expect(find.text(l10n.weDxCardSubtitle), findsOneWidget,
          reason: 'la question reste entière, donc la carte reste');
    });

    testWidgets('un bloc déjà rempli n\'est plus proposé', (tester) async {
      await diagnostic.record(DiagnosticAnswers.none, locale: 'fr');
      envois.clear();

      ecranTelephone(tester);
      await tester.pumpWidget(host(
          diagnostic: diagnostic,
          consent: ConsentFaux(accorde: true),
          estimation: estimation));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weDxCardSubtitle), findsNothing);
    });
  });

  // Les fakes ci-dessus prouvent l'ORDRE des écrans ; ce groupe-ci prouve que
  // le port réel fait bien ce que les fakes simulent. C'est le câblage jamais
  // exercé qui avait fait perdre les parrainages.
  group('le port réel — AppEventConsent', () {
    late _ServiceEspion espion;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ConsentService.instance.withdraw();
      // L'espion remplace le service de production pour TOUT le groupe : le
      // vrai ouvrirait une box Hive, qu'aucun test unitaire n'initialise.
      espion = _ServiceEspion();
      EventUploadService.debugSetInstance(espion);
    });

    tearDown(() => EventUploadService.debugSetInstance(EventUploadService()));

    test('accorder écrit vraiment, et se relit', () async {
      const port = AppEventConsent();

      expect(await port.isGranted(), isFalse);
      expect(await port.setGranted(true), isTrue);
      expect(await port.isGranted(), isTrue);
      expect(await ConsentService.instance.eventConsentVersion(),
          kEventConsentVersion);
    });

    test('accorder libère ce qui attendait en file', () async {
      // Des réponses ont pu être mises en file AVANT l'accord (module joué,
      // envoi refusé faute de consentement). Sans ce rejeu, elles
      // patienteraient jusqu'au prochain démarrage de l'app alors que la seule
      // chose qui les bloquait vient d'être levée.
      await const AppEventConsent().setGranted(true);
      // Le rejeu n'est pas attendu par l'appelant : on laisse la micro-tâche
      // s'exécuter.
      await Future<void>.delayed(Duration.zero);

      expect(espion.rejeux, 1);
    });

    test('retirer ne relance aucun envoi', () async {
      await const AppEventConsent().setGranted(true);
      await Future<void>.delayed(Duration.zero);
      espion.rejeux = 0;

      await const AppEventConsent().setGranted(false);
      await Future<void>.delayed(Duration.zero);

      expect(espion.rejeux, 0,
          reason: 'rejouer après un retrait relancerait des envois que le '
              'consentement ne couvre plus');
      expect(await const AppEventConsent().isGranted(), isFalse);
    });
  });

  group('les six langues', () {
    for (final locale in const [
      Locale('fr'),
      Locale('en'),
      Locale('en', 'GB'),
      Locale('de'),
      Locale('es'),
      Locale('pt'),
    ]) {
      testWidgets('le gate et la liste tiennent en ${locale.toString()}',
          (tester) async {
        ecranTelephone(tester);
        final traduit = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(host(
          diagnostic: diagnostic,
          consent: ConsentFaux(),
          estimation: estimation,
          locale: locale,
        ));
        await tester.pumpAndSettle();

        await toucher(tester, traduit.weDxCardSubtitle);
        expect(find.text(traduit.weCsAccept), findsOneWidget);
        expect(find.text(traduit.weCsDecline), findsOneWidget);

        await tester.tap(find.text(traduit.weCsAccept));
        await tester.pumpAndSettle();

        // La question elle-même, et les deux cases qui ne sont pas des
        // troubles : celles dont l'absence ruinerait le corpus.
        await tester.ensureVisible(find.text(traduit.weDxNone));
        await tester.pumpAndSettle();
        expect(find.text(traduit.weDxPreferNotToSay), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
