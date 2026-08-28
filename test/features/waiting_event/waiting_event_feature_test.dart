// L'événement est éteint — et il n'y a qu'un interrupteur.
//
// Décision de lancement : pendant les 8 jours, l'utilisateur voit le décompte
// et rien d'autre. Un programme de huit journées à remplir est beaucoup à
// assumer pour un début. Le code n'est PAS supprimé : il reste dans la
// branche, ses ~950 tests continuent de tourner, et le rallumer est un
// changement d'une ligne.
//
// Ce fichier tient les deux moitiés de cette promesse :
//
//  1. l'interrupteur est bien sur OFF — épinglé, pour qu'un rallumage soit une
//     décision et jamais un effet de bord ;
//  2. il n'y a qu'UNE porte. C'est la partie qui vaut le test : un
//     interrupteur ne vaut que si rien ne le contourne. Le jour où quelqu'un
//     ajoutera un raccourci vers le hub depuis l'accueil, ce test tombera.
//
// La vérification est faite sur la SOURCE plutôt qu'en montant les écrans :
// une porte qui n'existe pas ne se teste pas en la cherchant à l'écran — on
// vérifie qu'aucune n'a été percée ailleurs.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/waiting_event/waiting_event_feature.dart';

/// Le dossier de l'événement. Tout ce qui vit dedans a le droit de se
/// référencer librement : c'est l'intérieur de la pièce fermée.
const String _dossierEvenement = 'lib/features/waiting_event/';

/// La seule porte, et le seul fichier hors de l'événement qui a le droit de la
/// nommer.
const String _porte = 'lib/features/unlock/presentation/pages/unlock_gate_page.dart';

/// Les écrans par lesquels on ENTRE dans l'événement. Aucun ne doit être
/// nommable depuis le reste de l'app.
const List<String> _ecransDEntree = [
  'DayHubPage',
  'RevealPage',
  'SelfEstimatePage',
  'DiagnosticBlockPage',
  'EventConsentPage',
  'QuestionnaireRunnerPage',
  'StroopGamePage',
  'DelayChoiceGamePage',
  'TimeEstimationGamePage',
];

/// Les worktrees git imbriqués (`.claude/worktrees/`) sont des CHECKOUTS
/// D'AUTRES BRANCHES : ignorés par git (`.gitignore`), jamais livrés, et hors
/// du périmètre de cette garde. Sans ce filtre la garde est rouge en
/// permanence — donc morte : elle ne signalerait plus une vraie infraction.
bool _horsPerimetre(String chemin) => chemin.contains('/.claude/');

List<File> _fichiersDart() {
  final out = <File>[];
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart') && !_horsPerimetre(e.path)) {
      out.add(e);
    }
  }
  return out;
}

void main() {
  test('L\'INTERRUPTEUR EST SUR OFF', () {
    // Épinglé volontairement. Si ce test tombe, c'est soit qu'on rallume
    // l'événement — auquel cas on met à jour ce test EN CONNAISSANCE DE CAUSE,
    // après avoir vérifié que `AppConstants.eventWorkerUrl` n'est plus un
    // gabarit et que `workers/event` est déployé — soit qu'il vient de se
    // rallumer tout seul, ce qui est exactement ce qu'on veut voir.
    expect(kWaitingEventEnabled, isFalse,
        reason: 'l\'événement des 8 jours est mis de côté pour le lancement : '
            'l\'utilisateur ne doit voir que le décompte');
  });

  test('la porte est unique : un seul fichier hors de l\'événement le nomme',
      () {
    final intrus = <String>[];
    for (final fichier in _fichiersDart()) {
      final chemin = fichier.path;
      if (chemin.startsWith(_dossierEvenement)) continue;
      if (chemin.endsWith('/gen/') || chemin.contains('/l10n/gen/')) continue;

      final source = fichier.readAsStringSync();
      for (final ecran in _ecransDEntree) {
        if (!RegExp('\\b$ecran\\b').hasMatch(source)) continue;
        if (chemin == _porte && ecran == 'DayHubPage') continue;
        intrus.add('$chemin → $ecran');
      }
    }

    expect(intrus, isEmpty,
        reason: 'une seconde porte vers l\'événement rendrait l\'interrupteur '
            'inopérant sans que rien ne le signale :\n${intrus.join("\n")}');
  });

  test('la porte unique est bien gardée par l\'interrupteur', () {
    final source = File(_porte).readAsStringSync();

    // La condition la PLUS PROCHE de la construction du hub. Remonter au
    // premier `if (` du fichier passerait sous silence un garde-fou déplacé.
    final ouverture = source.indexOf('DayHubPage(');
    expect(ouverture, greaterThan(-1),
        reason: 'la porte a changé de forme : relire ce test avant de le '
            'faire taire');
    final avant = source.substring(0, ouverture);
    final dernierIf = avant.lastIndexOf('if (');
    expect(dernierIf, greaterThan(-1),
        reason: 'la construction de DayHubPage n\'est plus dans une condition');

    expect(avant.substring(dernierIf), contains('kWaitingEventEnabled'),
        reason: 'la porte doit être gardée par l\'interrupteur, pas seulement '
            'par la présence de `dayIndex` — un worker qui renvoie le jour '
            'rouvrirait alors l\'événement tout seul');

    expect(source, contains("waiting_event/waiting_event_feature.dart"),
        reason: 'l\'interrupteur doit être importé depuis sa source unique');
  });

  test('rien ne peut entrer dans la file d\'envoi', () {
    // La garde art. 9 et le rejeu restent en place, mais ils gardent une file
    // que PLUS RIEN n'alimente : `submit` n'est appelé que depuis des écrans de
    // l'événement, tous derrière la porte fermée. C'est plus fort qu'un
    // interdit — c'est une impossibilité de chemin.
    final appelants = <String>[];
    for (final fichier in _fichiersDart()) {
      if (fichier.path.startsWith(_dossierEvenement)) continue;
      final source = fichier.readAsStringSync();
      if (RegExp(r'EventUploadService\.instance\.submit\b').hasMatch(source)) {
        appelants.add(fichier.path);
      }
    }
    expect(appelants, isEmpty,
        reason: 'un envoi déclenché hors de l\'événement survivrait à '
            'l\'extinction :\n${appelants.join("\n")}');
  });

  test('le code mis de côté est toujours là, entier', () {
    // L'inverse de la garde précédente : on a éteint, on n'a pas effacé. Si ces
    // fichiers disparaissaient, l'interrupteur n'aurait plus rien à rallumer —
    // et c'est précisément ce qu'on a promis de ne pas faire.
    for (final chemin in [
      'lib/features/waiting_event/day_hub/presentation/pages/day_hub_page.dart',
      'lib/features/waiting_event/_shared/data/question_bank/ipip50.dart',
      'lib/features/waiting_event/personality/domain/personality_module.dart',
      'lib/features/waiting_event/diagnostic_block/presentation/diagnostic_chain.dart',
      'lib/features/waiting_event/stroop/presentation/pages/stroop_game_page.dart',
      'lib/features/waiting_event/delay_choice/presentation/pages/delay_choice_game_page.dart',
      'lib/features/waiting_event/time_estimation/presentation/pages/time_estimation_game_page.dart',
      'lib/features/waiting_event/reveals/presentation/pages/reveal_page.dart',
    ]) {
      expect(File(chemin).existsSync(), isTrue, reason: '$chemin a disparu');
    }
  });
}
