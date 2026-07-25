import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/core/theme/app_theme.dart';
import 'package:mentality/core/theme/kepler_colors.dart';
import 'package:mentality/core/widgets/test/kepler_stimulus_surface.dart';

/// Vérifie l'invariant central du panneau de stimulus : **les conditions de
/// présentation du matériel de test ne dépendent pas du thème**.
///
/// Sans cet invariant, une cellule blanche de Matrices passe de Lc 47 sur le
/// crème du mode clair à Lc 107 sur le fond sombre — le rapport figure/fond
/// change donc avec un simple réglage d'affichage, alors que les normes
/// supposent une passation dans des conditions uniques.

Widget _host({required ThemeData Function() theme, required Widget child}) =>
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: theme(),
        home: Scaffold(body: KeplerStimulusSurface(child: child)),
      ),
    );

void main() {
  testWidgets('le sous-arbre résout la palette CLAIRE, quel que soit le thème',
      (tester) async {
    final resolved = <String, KeplerColors>{};

    for (final entry in {
      'clair': AppTheme.light,
      'sombre': AppTheme.dark,
    }.entries) {
      await tester.pumpWidget(_host(
        theme: entry.value,
        child: Builder(builder: (context) {
          resolved[entry.key] = KeplerColors.of(context);
          return const SizedBox.shrink();
        }),
      ));
      await tester.pump();
    }

    expect(
      resolved['clair']!.textPrimary,
      resolved['sombre']!.textPrimary,
      reason: 'Le texte de consigne à l\'intérieur du panneau doit se rendre '
          'à l\'identique dans les deux thèmes. S\'ils diffèrent, le panneau '
          'ne bascule plus le thème et les consignes deviendront claires sur '
          'fond clair en mode nuit.',
    );
    expect(resolved['clair']!.primary, resolved['sombre']!.primary);
    expect(resolved['clair']!.background, resolved['sombre']!.background);
  });

  testWidgets('le fond du panneau est identique dans les deux thèmes',
      (tester) async {
    final backgrounds = <Color>[];

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(_host(theme: theme, child: const SizedBox()));
      await tester.pump();
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KeplerStimulusSurface),
              matching: find.byType(Container),
            )
            .first,
      );
      backgrounds.add((container.decoration! as BoxDecoration).color!);
    }

    expect(backgrounds[0], backgrounds[1]);
    expect(backgrounds[0], KeplerStimulusSurface.surface);
  });

  test('le panneau n\'est ni blanc pur ni thématisable', () {
    // Blanc pur = éblouissement maximal quand la page autour est sombre.
    expect(KeplerStimulusSurface.surface, isNot(const Color(0xFFFFFFFF)));
    // Assez clair pour préserver le rapport figure/fond d'origine.
    expect(KeplerStimulusSurface.surface.r, greaterThan(0.9));
  });
}
