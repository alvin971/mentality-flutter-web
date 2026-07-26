// Garde-fous de la carte de partage.
//
// L'image exportée est publiée telle quelle sur une story : elle doit être
// IDENTIQUE pour tout le monde et faire exactement 1080 × 1920 px. Deux dérives
// sont faciles à introduire sans s'en rendre compte, et ce fichier les bloque :
//
//   1. Utiliser `.w` / `.h` / `.sp` (flutter_screenutil) — ou AppText, dont
//      toutes les tailles passent par `.sp`. Ces unités dépendent de la taille
//      de l'appareil : la carte deviendrait différente selon le téléphone.
//   2. Utiliser KeplerColors.of(context) ou AppText.of(context) : la carte
//      suivrait le thème clair/sombre de celui qui partage.
//
// On ne capture pas de PNG ici. Encoder une image exige `tester.runAsync`, où
// GoogleFonts tente un vrai téléchargement qui échoue en CI — on testerait
// surtout la disponibilité du réseau. On mesure directement les deux propriétés
// qui comptent : la carte se dispose TOUJOURS à 360 × 640 logiques, et tous ses
// styles de texte sont identiques d'une configuration à l'autre. La taille de
// l'image en découle par construction (360 × 3 = 1080, 640 × 3 = 1920).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/theme/app_theme.dart';
import 'package:mentality/features/share_score/presentation/widgets/score_share_card.dart';

const _carte = ScoreShareCard(
  iq: 128,
  percentile: 97,
  classification: 'Très supérieur',
  inviteCode: 'a1b2c3d4',
  scoreLabel: 'Score global',
  percentileLabel: 'Plus élevé que 97 % des participants',
  codeLabel: "Code d'invitation",
  siteLabel: 'mental-et.com',
);

/// Hôte réaliste : ScreenUtilInit est actif, exactement comme dans l'app.
///
/// C'est ce qui donne son mordant aux tests d'invariance : sous ScreenUtilInit,
/// un `.sp` produit bien des tailles DIFFÉRENTES selon l'écran physique. Si la
/// carte en contenait un, les relevés divergeraient.
Widget _host({required ThemeData Function() theme}) => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: theme(),
        home: Scaffold(
          // OverflowBox : la carte se dispose à sa taille NATURELLE même si la
          // surface de test (800 × 600 par défaut) est plus petite. Sans lui on
          // mesurerait une carte rognée par le banc d'essai — alors que la
          // capture réelle part d'une RepaintBoundary, qui ignore les
          // contraintes de l'écran hôte.
          body: Center(
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: _carte,
            ),
          ),
        ),
      ),
    );

/// Relevé complet de ce qui détermine le rendu : taille disposée + tous les
/// styles de texte, dans l'ordre de l'arbre.
({Size taille, List<String> styles}) _releve(WidgetTester tester) {
  final taille = tester.getSize(find.byType(ScoreShareCard));
  final styles = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => '${t.data}|${t.style?.fontSize}|${t.style?.color}|'
          '${t.style?.fontWeight}|${t.style?.letterSpacing}|${t.style?.height}')
      .toList();
  return (taille: taille, styles: styles);
}

Future<({Size taille, List<String> styles})> _mesurer(
  WidgetTester tester, {
  required Size ecran,
  required ThemeData Function() theme,
}) async {
  tester.view.physicalSize = ecran;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(theme: theme));
  await tester.pump();
  return _releve(tester);
}

void main() {
  group('carte de partage — format de sortie', () {
    test('les constantes donnent bien 1080 × 1920 et 1080 × 1400 utiles', () {
      expect(ScoreShareCard.width * ScoreShareCard.capturePixelRatio, 1080);
      expect(ScoreShareCard.height * ScoreShareCard.capturePixelRatio, 1920);
      // Instagram recouvre ~250 px en haut et en bas ; on en réserve 260, ce
      // qui laisse une zone utile de 1400 px pile et 10 px de marge.
      expect(ScoreShareCard.unsafeBandPx, greaterThanOrEqualTo(250));
      expect(ScoreShareCard.safeHeightPx, 1400);
      // `closeTo` : unsafeBand vaut 260/3, le retour en pixels traîne l'erreur
      // de la division binaire — sans aucune conséquence à l'écran.
      expect(ScoreShareCard.unsafeBand * ScoreShareCard.capturePixelRatio,
          closeTo(ScoreShareCard.unsafeBandPx, 0.001));
    });

    testWidgets('la carte se dispose exactement à 360 × 640 logiques',
        (tester) async {
      final m = await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.light);
      expect(m.taille, const Size(ScoreShareCard.width, ScoreShareCard.height));
    });

    testWidgets('aucun débordement de composition', (tester) async {
      // Les zones calmes sont des Spacer : l'espace restant se redistribue au
      // lieu de rogner du contenu. Un débordement ici passerait inaperçu
      // jusqu'à la publication de l'image.
      await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.light);
      expect(tester.takeException(), isNull);
    });
  });

  group('carte de partage — rendu invariant', () {
    testWidgets('identique sous deux tailles d\'écran (garde screenutil)',
        (tester) async {
      final petit = await _mesurer(tester,
          ecran: const Size(720, 1280), theme: AppTheme.light);
      final grand = await _mesurer(tester,
          ecran: const Size(1440, 3120), theme: AppTheme.light);

      const pourquoi = 'un .w/.h/.sp (ou AppText, qui en dépend) s\'est glissé '
          'dans la carte : l\'image varierait selon le téléphone';
      expect(petit.taille, grand.taille, reason: pourquoi);
      expect(petit.styles, grand.styles, reason: pourquoi);
    });

    testWidgets('identique en thème clair et en thème sombre', (tester) async {
      final clair = await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.light);
      final sombre = await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.dark);

      const pourquoi = 'la carte suit le thème de l\'appareil : deux personnes '
          'partageraient le même score avec des images différentes';
      expect(clair.taille, sombre.taille, reason: pourquoi);
      expect(clair.styles, sombre.styles, reason: pourquoi);
    });

    testWidgets('toutes les couleurs viennent de la palette fixe',
        (tester) async {
      await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.dark);
      // Pas de `const` : Color n'a pas d'égalité primitive, un littéral
      // d'ensemble constant ne compile pas.
      final palette = <Color?>{
        ScoreShareCard.brand,
        ScoreShareCard.ink,
        ScoreShareCard.inkSoft,
      };
      final couleurs = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.style?.color)
          .toSet();
      expect(couleurs.difference(palette), isEmpty,
          reason: 'une couleur hors palette signifie une dépendance au thème');
    });
  });

  group('carte de partage — contenu', () {
    testWidgets('score, classement, code et URL sont affichés', (tester) async {
      await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.light);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('Très supérieur'), findsOneWidget);
      expect(find.text('Plus élevé que 97 % des participants'), findsOneWidget);
      expect(find.text('A1B2C3D4'), findsOneWidget);
      expect(find.text('mental-et.com'), findsOneWidget);
      expect(find.text('MENTAL E.T.'), findsOneWidget);
    });

    testWidgets('aucune donnée démographique n\'est rendue', (tester) async {
      // La carte n'expose aucun paramètre de sexe, d'âge ou de région : elle ne
      // PEUT donc pas les afficher. On verrouille l'ensemble EXACT des textes —
      // ajouter un champ démographique casserait ce test.
      await _mesurer(tester,
          ecran: const Size(1080, 2400), theme: AppTheme.light);
      final textes = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toSet();
      expect(textes, {
        'MENTAL E.T.',
        'SCORE GLOBAL',
        '128',
        'Très supérieur',
        'Plus élevé que 97 % des participants',
        "CODE D'INVITATION",
        'A1B2C3D4',
        'mental-et.com',
      });
    });
  });
}
