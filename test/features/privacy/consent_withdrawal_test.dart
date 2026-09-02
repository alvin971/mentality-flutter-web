// LE RETRAIT DU CONSENTEMENT EXISTE, ET ON PEUT L'ATTEINDRE.
//
// `ConsentService.withdraw()` n'avait AUCUN appelant dans lib/ : la méthode
// existait, les textes de l'app la promettaient (« Vous pouvez retirer votre
// consentement à tout moment depuis les paramètres de l'application ») et la
// politique de confidentialité du site la promettait aussi. Le geste, lui,
// n'était offert nulle part. L'art. 7-3 du RGPD exige qu'il soit aussi simple
// de retirer que de donner : il était impossible.
//
// Ce fichier prouve TROIS choses, dans cet ordre :
//
//   1. le PARCOURS existe pour de vrai — on part de l'accueil, on touche ce
//      qu'un utilisateur touche, et le consentement finit retiré. Un test qui
//      appellerait `withdraw()` directement ne prouverait rien : c'est
//      précisément ce qui manquait ;
//   2. le retrait EMPÊCHE l'étape orale de démarrer, même avec un passe sv 3
//      « free » — la régression la plus facile à réintroduire, puisque
//      l'étape orale réaligne le consentement sur le passe à chaque ouverture ;
//   3. le garde du passe Payant fonctionne AUSSI sur la route de premier
//      niveau `/test/oral`, où il n'y a rien à dépiler.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mentality/core/consent/consent_service.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/core/services/auth_local_store.dart';
import 'package:mentality/core/services/token_plan.dart';
import 'package:mentality/features/data_collection/oral_test_flow.dart';
import 'package:mentality/features/home/presentation/pages/home_page.dart';
import 'package:mentality/features/privacy/presentation/pages/privacy_consent_page.dart';

import '../complete_test/referral_credit_kit.dart';

/// Le plan que porte un passe Gratuit avec la case corpus cochée.
const _passeGratuit = TokenPlanInfo(
  plan: TokenPlan.free,
  corpusConsent: true,
  legalVersion: '2026-09-02.v1',
  issuedDay: 20693,
);

/// Hôte piloté par un VRAI routeur go_router, pour reproduire la route de
/// premier niveau `/test/oral` : c'est la seule façon d'exercer le cas où la
/// pile de navigation est vide.
Widget hoteRoute(GoRouter routeur) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp.router(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: routeur,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLocalizations l10n;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Hive.init(
        Directory.systemTemp.createTempSync('mentality_retrait_test').path);
    await AuthLocalStore.instance.saveToken(tokenDeTestPlan(cc: true));
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    installeFauxReseau();
    await ConsentService.instance.debugReset();
  });

  /// Fait avancer l'arbre SANS `pumpAndSettle` : l'accueil anime son logo en
  /// boucle (`EtLogoAnimated`), et `pumpAndSettle` n'y converge jamais — il
  /// expire au bout de dix minutes simulées. On alterne donc temps réel (E/S
  /// SharedPreferences) et reconstructions, comme partout ailleurs ici.
  Future<void> avance(WidgetTester tester, {int tours = 8}) async {
    for (var i = 0; i < tours; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> demonte(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await attendLeReseau(tester, tours: 4);
    await tester.pump(const Duration(seconds: 1));
  }

  // ─── 1. LE PARCOURS RÉEL ──────────────────────────────────────────────────

  group('le parcours d\'interface qui mène au retrait', () {
    testWidgets(
        'accueil → « Confidentialité et consentement » → « Retirer mon '
        'consentement » → confirmation → le consentement ne vaut plus',
        (tester) async {
      // Un consentement bien vivant, porté par le passe, comme après une
      // inscription sur mental-et.com.
      await tester.runAsync(() => ConsentService.instance
          .syncFromToken(_passeGratuit, locale: 'fr'));
      expect(
          await tester
              .runAsync(() => ConsentService.instance.hasValidConsent()),
          isTrue);

      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(hote(const HomePage()));
      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump();

      // ÉTAPE 1 — la porte est visible sur l'accueil, sans rien déplier.
      final porte = find.text(l10n.privacyTitle);
      expect(porte, findsOneWidget,
          reason: 'une promesse de retrait qu\'il faut chercher n\'est pas '
              'tenue : l\'entrée doit être sur l\'accueil, en clair');
      // Sur un écran de téléphone la carte 04 est sous la ligne de flottaison :
      // on fait ce que fait l'utilisateur, on descend jusqu'à elle.
      await tester.ensureVisible(porte);
      await tester.pump();
      await tester.tap(porte);
      await avance(tester);

      expect(find.byType(PrivacyConsentPage), findsOneWidget);
      expect(find.text(l10n.privacyStatusActive), findsOneWidget,
          reason: 'l\'écran dit d\'abord ce qui vaut aujourd\'hui');

      // ÉTAPE 2 — le bouton de retrait.
      final bouton = find.text(l10n.privacyWithdrawAction);
      expect(bouton, findsOneWidget);
      await tester.ensureVisible(bouton);
      await tester.pump();
      await tester.tap(bouton);
      await avance(tester);

      // ÉTAPE 3 — la confirmation DIT CE QUE ÇA CHANGE avant d'agir.
      expect(find.text(l10n.privacyWithdrawDialogTitle), findsOneWidget);
      expect(find.text(l10n.privacyWithdrawDialogBody), findsOneWidget,
          reason: 'un retrait qui surprend la personne n\'est pas plus '
              'éclairé qu\'un consentement arraché');
      await tester.tap(find.text(l10n.privacyWithdrawConfirm));
      await avance(tester);

      // ÉTAPE 4 — le retrait a réellement eu lieu.
      expect(
          await tester
              .runAsync(() => ConsentService.instance.hasValidConsent()),
          isFalse,
          reason: 'c\'est TOUT le sujet : le bouton doit appeler withdraw(), '
              'pas afficher un message');
      expect(
          await tester.runAsync(() => ConsentService.instance.isWithdrawn()),
          isTrue);
      expect(await tester.runAsync(() => ConsentService.instance.load()),
          isNull);

      await avance(tester);
      expect(find.text(l10n.privacyWithdrawDone), findsOneWidget,
          reason: 'et l\'écran le confirme, sans avoir à quitter la page');
      expect(find.text(l10n.privacyWithdrawAction), findsNothing,
          reason: 'proposer de retirer ce qui est déjà retiré sèmerait le '
              'doute');

      await demonte(tester);
    });

    testWidgets('annuler la confirmation ne retire rien', (tester) async {
      await tester.runAsync(() => ConsentService.instance
          .syncFromToken(_passeGratuit, locale: 'fr'));

      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(hote(const PrivacyConsentPage()));
      await avance(tester);

      await tester.tap(find.text(l10n.privacyWithdrawAction));
      await avance(tester);
      await tester.tap(find.text(l10n.commonCancel));
      await avance(tester);

      expect(
          await tester
              .runAsync(() => ConsentService.instance.hasValidConsent()),
          isTrue,
          reason: 'le retrait est irréversible côté preuve : il ne doit pas '
              'partir sur un geste ambigu');

      await demonte(tester);
    });
  });

  // ─── 2. LE RETRAIT FERME L'ÉTAPE ORALE ────────────────────────────────────

  group('après le retrait, l\'étape orale ne démarre plus', () {
    testWidgets('même avec un passe sv 3 « free » en poche', (tester) async {
      await tester.runAsync(() async {
        await AuthLocalStore.instance.saveToken(tokenDeTestPlan(cc: true));
        await ConsentService.instance
            .syncFromToken(_passeGratuit, locale: 'fr');
        await ConsentService.instance.withdraw();
      });

      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(hote(const OralTestFlow()));
      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump(const Duration(milliseconds: 300));

      // L'étape orale réaligne le consentement sur le passe À CHAQUE
      // ouverture : sans marqueur durable, elle venait de le rétablir.
      expect(
          await tester
              .runAsync(() => ConsentService.instance.hasValidConsent()),
          isFalse,
          reason: 'le passe ne défait pas un retrait');
      expect(find.byType(CheckboxListTile), findsWidgets,
          reason: 'l\'écran de consentement in-app reprend la main : on ne '
              'lit rien à voix haute tant que la personne n\'a pas '
              'explicitement re-consenti');

      await demonte(tester);
    });
  });

  // ─── 3. LE GARDE « PAYANT » SUR LA ROUTE DE PREMIER NIVEAU ────────────────

  group('le garde du passe Payant tient sur /test/oral', () {
    testWidgets('rien à dépiler → retour à l\'accueil, pas d\'écran figé',
        (tester) async {
      await tester.runAsync(() => AuthLocalStore.instance
          .saveToken(tokenDeTestPlan(p: 'paid', cc: false)));

      final routeur = GoRouter(
        initialLocation: '/test/oral',
        routes: [
          GoRoute(
              path: '/test/oral', builder: (_, __) => const OralTestFlow()),
          GoRoute(
            path: '/home',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('accueil'))),
          ),
        ],
      );

      ecranTelephone(tester);
      ignoreDebordementsDeMiseEnPage();
      await tester.pumpWidget(hoteRoute(routeur));
      await tester.pump();
      await attendLeReseau(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await avance(tester);

      expect(find.text('accueil'), findsOneWidget,
          reason: 'sur une route de premier niveau la pile est vide : le '
              'pop du garde était un no-op silencieux, et l\'écran restait '
              'bloqué sur « vérification » — un passe Payant s\'y '
              'retrouvait prisonnier');
      expect(find.byType(OralTestFlow), findsNothing);

      await demonte(tester);
    });
  });
}
