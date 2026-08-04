// Quel module de questions se rattache à quelle journée.
//
// Chaque lot de contenu ajoute son module ici, et la journée s'active
// d'elle-même. Les journées dont le module n'est pas encore enregistré
// continuent de s'annoncer dans le hub (via `EventSchedule`) et ouvrent leur
// message d'attente.
//
// Ce fichier porte aussi [QModuleRegistry.recalled] — la liste des blocs
// validés dont le libellé n'a PAS été confronté à sa source primaire. Elle vit
// ici plutôt que dans un test parce qu'elle doit être AFFICHÉE (page
// Méthodologie) autant que vérifiée : une incertitude qu'on ne montre qu'aux
// développeurs n'est pas déclarée, elle est cachée.

import '../models/q_instrument.dart';
import '../models/q_module.dart';
import '../../../personality/domain/personality_module.dart';

abstract final class QModuleRegistry {
  /// Les modules livrés, par ordre de journée.
  static final List<QModule> modules = [
    personalityModule, // J1 — IPIP-50
  ];

  /// Tous les blocs validés dont la provenance est `recalled`, dans l'ordre du
  /// programme. C'est la liste que la page Méthodologie doit refléter et qu'une
  /// garde de test énumère nommément.
  ///
  /// Vide un jour = tous les instruments ont été confrontés à leur source.
  /// Ce jour-là, la garde tombera, et ce sera la bonne nouvelle.
  static List<QInstrument> get recalled => [
        for (final module in modules)
          for (final bloc in module.instruments)
            if (bloc.isRecalled) bloc,
      ];

  /// Le module de la journée [day], ou `null` si son contenu n'est pas encore
  /// livré.
  static QModule? forDay(int day) {
    for (final module in modules) {
      if (module.day == day) return module;
    }
    return null;
  }
}

/// Comment le hub retrouve le module d'une journée. Injectable pour que le
/// chemin « le hub ouvre le questionnaire » soit vérifiable sans dépendre du
/// calendrier de livraison des contenus.
typedef QModuleResolver = QModule? Function(int day);
