// Le rendu des sept révélations, avec de VRAIES données d'historique.
//
// Les règles de formulation du plan produit (§9) ne se vérifient qu'ici : ce
// sont des propriétés de ce qui est AFFICHÉ. Un score sans sa marge d'erreur,
// une bande dans la mauvaise langue ou un zéro affiché faute de données ne se
// voient sur aucun test de logique pure.
//
// Le balayage des six langues attrape ce qu'aucune règle ne peut voir : une
// clé de traduction absente, un `switch` non exhaustif, un débordement de mise
// en page. La police de test rend chaque glyphe carré — les textes y débordent
// bien plus qu'en vrai, ce qui en fait un banc d'essai sévère et non
// complaisant.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/l10n/gen/app_localizations.dart';
import 'package:mentality/features/scoring/data/composite_score_tables.dart';
import 'package:mentality/features/waiting_event/_shared/domain/models/event_day.dart';
import 'package:mentality/features/waiting_event/reveals/data/self_estimate_store.dart';
import 'package:mentality/features/waiting_event/reveals/domain/models/reveal_data.dart';
import 'package:mentality/features/waiting_event/reveals/presentation/pages/reveal_page.dart';
import 'package:mentality/services/session_history_service.dart';

/// Un bilan réel, tel que l'app en enregistre un à la fin de la batterie.
SessionHistoryEntry bilan({
  int fsiq = 112,
  int? vci = 121,
  int? vsi = 104,
  int? fri = 115,
  int? wmi = 98,
  int? psi = 109,
}) =>
    SessionHistoryEntry(
      id: 'session-1',
      account: 'passe',
      date: DateTime(2026, 7, 20),
      ageInMonths: 372,
      fsiq: fsiq,
      vci: vci,
      vsi: vsi,
      fri: fri,
      wmi: wmi,
      psi: psi,
      classification: 'Moyen supérieur',
    );

void ecranTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget host(
  Widget page, {
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
        home: page,
      ),
    );

/// Monte la révélation SUR une route précédente, pour que sa sortie ait
/// quelque part où revenir — et pour observer ce qu'elle renvoie.
class Lanceur extends StatefulWidget {
  const Lanceur({super.key, required this.page});

  final Widget page;

  @override
  State<Lanceur> createState() => LanceurState();
}

class LanceurState extends State<Lanceur> {
  Object? resultat;
  bool revenu = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              final r = await Navigator.of(context)
                  .push<bool>(MaterialPageRoute<bool>(builder: (_) => widget.page));
              setState(() {
                resultat = r;
                revenu = true;
              });
            },
            child: const Text('ouvrir'),
          ),
        ),
      );
}

void main() {
  group('révélation d\'un indice', () {
    testWidgets('le nombre mesuré est affiché tel quel', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.vci,
        data: RevealData.fromHistory(bilan()),
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text('121'), findsOneWidget, reason: 'le VCI du bilan');
      // Deux fois : le titre de l'AppBar ET l'étiquette de la carte. Le titre
      // s'ellipse sur une ligne (« Verarbeitungsgeschwindigkeit » disparaît en
      // allemand) ; c'est la carte qui garantit qu'un nombre ne s'affiche
      // jamais sans le nom de ce qu'il mesure.
      expect(find.text('Compréhension Verbale'), findsNWidgets(2));
    });

    testWidgets('le nom de l\'indice reste lisible même là où le titre '
        's\'ellipse', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        ecranTelephone(tester);
        await tester.pumpWidget(
          host(
            RevealPage(
              kind: RevealKind.psi,
              data: RevealData.fromHistory(bilan()),
              ctaLabel: l10n.weRvContinue,
            ),
            locale: locale,
            key: UniqueKey(),
          ),
        );
        await tester.pumpAndSettle();

        // Au moins une occurrence NON tronquée dans le corps de l'écran.
        final rendus = tester
            .widgetList<Text>(find.text(l10n.ctIndexPsi))
            .where((t) => t.maxLines == null);
        expect(rendus, isNotEmpty,
            reason: 'nom de l\'indice illisible en $locale');
      }
    });

    testWidgets('le score ne part jamais seul : bande et marge d\'erreur',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.psi,
        data: RevealData.fromHistory(bilan()),
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text('109'), findsOneWidget);
      expect(find.text(l10n.scoringClassificationAverage), findsOneWidget,
          reason: '109 tombe dans la bande « Moyen »');
      // Les BORNES sont vérifiées, pas la présence du gabarit : « 95 % » est
      // dans le libellé lui-même, donc un textContaining('95') passerait même
      // si l'intervalle affiché était faux.
      final (bas, haut) =
          CompositeScoreTables.getConfidenceInterval('PSI', 109);
      expect(find.text(l10n.weRvCi(bas, haut)), findsOneWidget,
          reason: 'l\'intervalle de confiance doit accompagner le nombre');
      expect(bas, lessThan(109));
      expect(haut, greaterThan(109));
      expect(find.text(l10n.weRvCaveat), findsOneWidget);
      expect(find.text(l10n.ctIndicativeDisclaimer), findsOneWidget);
    });

    testWidgets('chacun des cinq indices affiche SON nombre', (tester) async {
      const attendus = {
        RevealKind.vci: '121',
        RevealKind.vsi: '104',
        RevealKind.fri: '115',
        RevealKind.wmi: '98',
        RevealKind.psi: '109',
      };

      for (final entry in attendus.entries) {
        ecranTelephone(tester);
        await tester.pumpWidget(host(
          RevealPage(
            kind: entry.key,
            data: RevealData.fromHistory(bilan()),
            ctaLabel: 'Continuer',
          ),
          key: UniqueKey(),
        ));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget,
            reason: 'révélation ${entry.key.name}');
      }
    });

    testWidgets('un indice manquant se dit, il ne s\'invente pas',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.psi,
        data: RevealData.fromHistory(bilan(psi: null)),
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weRvMissingTitle), findsOneWidget);
      expect(find.text('0'), findsNothing, reason: 'jamais de zéro de repli');
    });
  });

  group('sans bilan à révéler', () {
    testWidgets('l\'écran le dit, sans afficher de chiffre', (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(const RevealPage(
        kind: RevealKind.vci,
        data: null,
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weRvUnavailableTitle), findsOneWidget);
      expect(find.text(l10n.weRvScoreLabel), findsNothing);
    });

    testWidgets('la sortie reste possible', (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(const RevealPage(
        kind: RevealKind.fullIq,
        data: null,
        ctaLabel: 'Retour',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Retour'), findsOneWidget);
    });
  });

  group('forces et points de vigilance (jour 6)', () {
    testWidgets('les indices qui dépassent le QI global de 10 points sortent',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      // QI 100 ; VCI 125 est une force, WMI 85 un point de vigilance.
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.strengths,
        data: RevealData.fromHistory(bilan(
            fsiq: 100, vci: 125, vsi: 100, fri: 100, wmi: 85, psi: 100)),
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ctRelativeStrengths), findsOneWidget);
      expect(find.text(l10n.ctVigilancePoints), findsOneWidget);
      expect(find.text(l10n.ctIndexVci), findsOneWidget);
      expect(find.text(l10n.ctIndexWmi), findsOneWidget);
      expect(find.text(l10n.ctProfileHeterogeneous), findsOneWidget);
    });

    testWidgets('un profil régulier est annoncé comme un résultat, pas un vide',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.strengths,
        data: RevealData.fromHistory(bilan(
            fsiq: 100, vci: 102, vsi: 99, fri: 100, wmi: 101, psi: 98)),
        ctaLabel: 'Continuer',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weRvStrengthsNone), findsOneWidget);
      expect(find.text(l10n.ctRelativeStrengths), findsNothing);
      expect(find.text(l10n.ctProfileHomogeneous), findsOneWidget);
    });
  });

  group('QI global et auto-estimation (jour 8)', () {
    testWidgets('sans estimation au jour 1, on le dit — rien n\'est comparé',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.fullIq,
        data: RevealData.fromHistory(bilan()),
        ctaLabel: 'Retour',
      )));
      await tester.pumpAndSettle();

      expect(find.text('112'), findsOneWidget);
      expect(find.text(l10n.weRvEstimateMissing), findsOneWidget);
    });

    testWidgets('un refus au jour 1 se lit comme une absence d\'estimation',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.fullIq,
        data: RevealData.fromHistory(bilan()),
        selfEstimate: SelfEstimate.refused,
        ctaLabel: 'Retour',
      )));
      await tester.pumpAndSettle();
      expect(find.text(l10n.weRvEstimateMissing), findsOneWidget);
    });

    testWidgets('une surestimation est dite en POINTS, jamais en rang inventé',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.fullIq,
        data: RevealData.fromHistory(bilan(fsiq: 112)),
        selfEstimate: const SelfEstimate(value: 135),
        ctaLabel: 'Retour',
      )));
      await tester.pumpAndSettle();

      expect(find.text(l10n.weRvEstimateLine(135, 112)), findsOneWidget);
      expect(find.text(l10n.weRvEstimateOver(23)), findsOneWidget);
    });

    testWidgets('la confrontation ne cite aucun rang ni pourcentage',
        (tester) async {
      // « Comme 7 personnes sur 10, tu t'es surestimé » supposerait une
      // distribution que nous n'avons pas encore mesurée. Le seul pourcentage
      // autorisé à l'écran est celui de l'intervalle de confiance, qui, lui,
      // se calcule.
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final texte in [
          l10n.weRvEstimateLine(135, 112),
          l10n.weRvEstimateOver(23),
          l10n.weRvEstimateUnder(22),
          l10n.weRvEstimateClose,
          l10n.weRvEstimateMissing,
        ]) {
          expect(texte, isNot(contains('%')), reason: 'en $locale');
          expect(texte.toLowerCase(), isNot(contains('sur 10')),
              reason: 'en $locale');
        }
      }
    });

    testWidgets('une sous-estimation compte l\'écart en positif',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      await tester.pumpWidget(host(RevealPage(
        kind: RevealKind.fullIq,
        data: RevealData.fromHistory(bilan(fsiq: 112)),
        selfEstimate: const SelfEstimate(value: 90),
        ctaLabel: 'Retour',
      )));
      await tester.pumpAndSettle();
      expect(find.text(l10n.weRvEstimateUnder(22)), findsOneWidget);
    });

    testWidgets('un écart d\'exactement 5 points est un écart, pas une égalité',
        (tester) async {
      // Le texte affiché dit « moins de 5 points » : à 5 pile, il mentirait.
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      for (final (estime, attendu) in [
        (117, l10n.weRvEstimateOver(5)),
        (107, l10n.weRvEstimateUnder(5)),
      ]) {
        await tester.pumpWidget(
          host(
            RevealPage(
              kind: RevealKind.fullIq,
              data: RevealData.fromHistory(bilan(fsiq: 112)),
              selfEstimate: SelfEstimate(value: estime),
              ctaLabel: 'Retour',
            ),
            key: UniqueKey(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(attendu), findsOneWidget, reason: 'estimation $estime');
        expect(find.text(l10n.weRvEstimateClose), findsNothing,
            reason: 'estimation $estime');
      }
    });

    testWidgets('à moins de 5 points, aucun des deux n\'a tort',
        (tester) async {
      ecranTelephone(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      for (final estime in [108, 112, 116]) {
        await tester.pumpWidget(
          host(
            RevealPage(
              kind: RevealKind.fullIq,
              data: RevealData.fromHistory(bilan(fsiq: 112)),
              selfEstimate: SelfEstimate(value: estime),
              ctaLabel: 'Retour',
            ),
            key: UniqueKey(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.weRvEstimateClose), findsOneWidget,
            reason: 'estimation $estime contre 112');
      }
    });
  });

  group('sortie', () {
    testWidgets('le bouton renvoie « lue » — le retour système, non',
        (tester) async {
      ecranTelephone(tester);
      await tester.pumpWidget(host(const Lanceur(
        page: RevealPage(
          kind: RevealKind.vci,
          data: RevealData(fsiq: 100, vci: 110),
          ctaLabel: 'Continuer',
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      final etat = tester.state<LanceurState>(find.byType(Lanceur));
      expect(etat.revenu, isTrue);
      expect(etat.resultat, isTrue,
          reason: 'c\'est ce qui autorise le hub à enchaîner l\'activité');
    });
  });

  group('GARDE six langues', () {
    testWidgets('les sept révélations rendent dans les six langues',
        (tester) async {
      expect(AppLocalizations.supportedLocales.length, 6);

      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final kind in RevealKind.values) {
          ecranTelephone(tester);
          await tester.pumpWidget(
            host(
              RevealPage(
                kind: kind,
                data: RevealData.fromHistory(bilan()),
                selfEstimate: const SelfEstimate(value: 130),
                ctaLabel: l10n.weRvContinue,
              ),
              locale: locale,
              key: UniqueKey(),
            ),
          );
          await tester.pumpAndSettle();

          final ou = 'révélation ${kind.name} en $locale';
          expect(tester.takeException(), isNull, reason: ou);
          // La mise en garde est sur TOUTES les révélations, dans TOUTES les
          // langues : c'est elle qui empêche un nombre de se lire comme un
          // verdict.
          expect(find.text(l10n.weRvCaveat), findsOneWidget, reason: ou);
          expect(find.text(l10n.weRvContinue), findsOneWidget, reason: ou);
        }
      }
    });

    test('chaque libellé des révélations est VRAIMENT traduit, pas replié', () {
      // Le balayage de rendu ci-dessus ne peut PAS voir une traduction
      // manquante : `_merge.py` remplace silencieusement une clé absente par
      // l'anglais puis le français, et l'écran s'affiche donc parfaitement
      // — en anglais, au milieu d'une app allemande. La seule façon de le
      // détecter est de lire la SOURCE (les fragments et les overlays), là où
      // l'absence est encore visible.
      final fragment = jsonDecode(
              File('l10n_fragments/waiting_event.json').readAsStringSync())
          as Map<String, dynamic>;

      final clefs = fragment.keys.where((k) => k.startsWith('weRv')).toList();
      expect(clefs, hasLength(35), reason: 'les libellés du LOT D');

      for (final langue in ['de', 'es', 'pt', 'en_GB']) {
        final overlay = jsonDecode(
                File('l10n_fragments/translations/$langue.json')
                    .readAsStringSync())
            as Map<String, dynamic>;

        for (final clef in clefs) {
          final inline = fragment[clef] as Map<String, dynamic>;
          final valeur = inline[langue] ?? overlay[clef];
          expect(valeur, isA<String>(),
              reason: '$clef n\'est pas traduite en $langue');
          expect((valeur as String).trim(), isNotEmpty,
              reason: '$clef est vide en $langue');

          // Un placeholder perdu à la traduction fait disparaître une valeur
          // de l'écran sans rien casser à la compilation.
          final attendus = RegExp(r'\{(\w+)\}')
              .allMatches(inline['fr'] as String)
              .map((m) => m.group(1))
              .toSet();
          final presents = RegExp(r'\{(\w+)\}')
              .allMatches(valeur)
              .map((m) => m.group(1))
              .toSet();
          expect(presents, attendus,
              reason: 'placeholders divergents pour $clef en $langue');
        }
      }
    });

    testWidgets('la bande descriptive suit la langue de l\'écran, pas celle '
        'de la passation', (tester) async {
      // Le bilan enregistré porte une classification FIGÉE en français ; un
      // lecteur allemand ne doit pas la voir.
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        ecranTelephone(tester);
        await tester.pumpWidget(
          host(
            RevealPage(
              kind: RevealKind.fullIq,
              data: RevealData.fromHistory(bilan(fsiq: 112)),
              ctaLabel: l10n.weRvBackToHub,
            ),
            locale: locale,
            key: UniqueKey(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.scoringClassificationHighAverage), findsOneWidget,
            reason: '112 en $locale');
        if (locale.languageCode != 'fr') {
          expect(find.text('Moyen supérieur'), findsNothing,
              reason: 'la classification stockée est en français — elle ne '
                  'doit pas fuiter en $locale');
        }
      }
    });
  });
}
