import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou architectural du mode sombre.
///
/// Le test de contraste voisin vérifie que les JETONS sont bons. Celui-ci
/// vérifie que les PAGES les utilisent — c'est l'autre moitié du bug corrigé
/// le 2026-07-25 : la palette sombre était correctement définie, mais les
/// pages appelaient `AppText.body()` (couleur du mode clair gravée dans le
/// style) et `AppColors.grey600` (valeur figée). Résultat : du texte à
/// Lc 1.04 sur fond sombre, donc invisible.
///
/// Deux interdits dans `lib/features/` et `lib/core/widgets/` :
///   1. `AppText.<méthode>()` sans passer par `AppText.of(context)`
///   2. `AppColors.grey*` dans le chrome
///
/// ## Exceptions volontaires
///
/// Les répertoires `presentation/widgets/` des exercices sont exclus : ils
/// rendent les STIMULI (faces de cubes, cellules de matrices, jetons,
/// balances). Leurs couleurs font partie du matériel de test — les
/// thématiser modifierait la difficulté perceptive, donc la mesure.

const _scannedRoots = ['lib/features', 'lib/core/widgets'];

/// Rendu de stimuli : hors charte, volontairement.
bool _isStimulusFile(String path) =>
    path.contains('/exercises_implementations/') &&
    path.contains('/presentation/widgets/');

List<File> _dartFiles() {
  final out = <File>[];
  for (final root in _scannedRoots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart') && !_isStimulusFile(e.path)) {
        out.add(e);
      }
    }
  }
  return out;
}

/// `AppText.body()` mais pas `AppText.of(context).body()`.
final _staticAppText = RegExp(
  r'(?<!of\(context\)\.)\bAppText\.(heroDisplay|heroItalic|h1|h1Italic|h2|'
  r'h2Italic|h3|body|bodyStrong|bodySmall|button|mono|monoLabel|monoScore)\(',
);

final _hardcodedGrey = RegExp(r'\bAppColors\.grey\d+\b');

void main() {
  test('aucune page n\'appelle la typographie statique (couleur clair figée)',
      () {
    final offenders = <String>[];
    for (final f in _dartFiles()) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_staticAppText.hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Ces appels gravent la couleur du mode CLAIR et deviennent '
          'invisibles en sombre. Utiliser AppText.of(context).<méthode>() :\n'
          '${offenders.join('\n')}',
    );
  });

  test('aucun gris figé dans le chrome', () {
    final offenders = <String>[];
    for (final f in _dartFiles()) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_hardcodedGrey.hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'L\'échelle de gris est calibrée pour le mode clair uniquement. '
          'Utiliser KeplerColors.of(context) :\n${offenders.join('\n')}',
    );
  });
}
