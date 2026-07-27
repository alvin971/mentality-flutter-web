// Quel module de questions se rattache à quelle journée.
//
// Le registre est VIDE tant que les contenus ne sont pas livrés, et c'est
// voulu : les items d'un instrument validé se recopient à la virgule près,
// avec leur cotation et leur citation. En inventer pour faire tourner le
// moteur produirait un score faux sous une étiquette vraie — précisément ce
// que l'intégrité des instruments interdit.
//
// D'ici là, `EventSchedule` annonce le programme (le hub affiche donc bien les
// huit journées et leur contenu) et le hub ouvre son message d'attente. Chaque
// lot de contenu ajoutera son module ici, et la journée s'activera d'elle-même.

import '../models/q_module.dart';

abstract final class QModuleRegistry {
  /// Les modules livrés, par ordre de journée.
  static const List<QModule> modules = [];

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
