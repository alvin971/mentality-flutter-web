// Quel jeu se rattache à quelle journée — et lequel est déjà livré.
//
// Même dispositif que `QModuleRegistry` pour les questionnaires : le programme
// (`EventSchedule`) ANNONCE les cinq jeux dès le premier jour, ce registre dit
// lesquels sont jouables. Une journée dont le jeu n'est pas encore écrit
// affiche donc son nom dans le sous-titre, sans carte pour l'ouvrir — le hub
// n'a rien à savoir du calendrier de livraison.
//
// Le registre vit en `presentation/` et non en `domain/` : il rend des écrans.
// Un service de domaine qui construirait des widgets inverserait la dépendance
// entre les deux couches.

import 'package:flutter/widgets.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../stroop/data/stroop_record_store.dart';
import '../../stroop/presentation/pages/stroop_game_page.dart';
import '../domain/models/event_day.dart';

/// Un jeu livré, tel que le hub a besoin de le connaître.
class EventGame {
  const EventGame({
    required this.title,
    required this.open,
    required this.hasPlayed,
  });

  /// Le nom du jeu, résolu depuis les ARB par l'appelant.
  final String Function(AppLocalizations) title;

  /// Ouvre le jeu.
  final Widget Function(BuildContext) open;

  /// A-t-il déjà été joué au moins une fois sur cet appareil ?
  ///
  /// Sert UNIQUEMENT à décider si le jeu s'intercale dans l'enchaînement de la
  /// journée (révélation → jeu → activité, l'ordre du plan produit). Une fois
  /// joué, il ne s'y impose plus : il reste accessible par sa carte, autant de
  /// fois qu'on veut. Un jeu facultatif qui se redemanderait à chaque
  /// ouverture de la journée cesserait d'être facultatif en pratique.
  ///
  /// Un incident de lecture vaut « jamais joué » : au pire on propose une
  /// partie de plus, ce qui n'abîme rien — le jeu est rejouable par nature.
  final Future<bool> Function() hasPlayed;
}

/// Comment le hub retrouve le jeu d'une journée. Injectable pour que le chemin
/// « le hub ouvre le jeu » soit vérifiable sans dépendre de Hive.
typedef EventGameResolver = EventGame? Function(GameKind kind);

abstract final class GameRegistry {
  /// Le jeu [kind] s'il est livré, `null` sinon.
  static EventGame? forGame(GameKind kind) => switch (kind) {
        GameKind.stroop => EventGame(
            title: (l10n) => l10n.weStroopTitle,
            open: (_) => const StroopGamePage(),
            hasPlayed: () async =>
                (await const StroopRecordStore().read()).hasPlayed,
          ),
        // Lots H2 à H5 — annoncés par le programme, pas encore écrits.
        GameKind.delayChoice ||
        GameKind.timeEstimation ||
        GameKind.confidenceCalibration =>
          null,
      };
}
