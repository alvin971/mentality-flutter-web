// Le test d'une journée : une suite ordonnée de blocs.
//
// L'ordre interne est la règle la plus stricte du programme :
//   1. les blocs validés d'abord, INTACTS, dans leur ordre d'origine ;
//   2. nos questions candidates ensuite, après le calcul du score.
// Inverser les deux suffirait à fausser des seuils publiés sans qu'aucun écran
// ne change d'apparence — c'est exactement le genre de régression qu'une garde
// de test doit attraper, d'où les propriétés vérifiables exposées ici.

import 'package:equatable/equatable.dart';

import 'event_day.dart';
import 'q_instrument.dart';
import 'q_item.dart';
import 'q_scale.dart';

class QModule extends Equatable {
  const QModule({
    required this.id,
    required this.day,
    required this.kind,
    required this.instruments,
  });

  /// Identifiant stable — clé de stockage des réponses.
  final String id;

  /// La journée du programme (1..8) à laquelle ce module se rattache.
  final int day;

  /// Cadrage promis à l'utilisateur : un test annoncé affiche un score, une
  /// contribution n'en affiche aucun et le dit d'emblée.
  final DayActivityKind kind;

  /// Les blocs dans l'ordre de passation.
  final List<QInstrument> instruments;

  /// Tous les items, à plat, dans l'ordre de passation.
  List<QItem> get items => [for (final b in instruments) ...b.items];

  int get questionCount => items.length;

  /// Le bloc dont relève l'item d'indice [index] (indice à plat).
  QInstrument instrumentAt(int index) {
    var reste = index;
    for (final bloc in instruments) {
      if (reste < bloc.items.length) return bloc;
      reste -= bloc.items.length;
    }
    throw RangeError.index(index, items, 'index', 'item hors module', questionCount);
  }

  /// L'échelle à proposer sous l'item d'indice [index].
  QScale scaleAt(int index) => instrumentAt(index).scale;

  /// True si [index] est le PREMIER item de son bloc.
  bool startsBlockAt(int index) {
    var debut = 0;
    for (final bloc in instruments) {
      if (index == debut) return true;
      debut += bloc.items.length;
    }
    return false;
  }

  /// True si [index] ouvre un bloc dont l'échelle diffère de celle du bloc
  /// précédent — le seul moment où un écran de transition a un sens.
  bool startsNewScaleAt(int index) {
    if (!startsBlockAt(index) || index == 0) return false;
    return instrumentAt(index).scale.id != instrumentAt(index - 1).scale.id;
  }

  /// L'indice où reprendre, connaissant les items déjà répondus : le PREMIER
  /// item sans réponse, dans l'ordre du module.
  ///
  /// Reprendre au premier trou plutôt qu'à une position mémorisée est
  /// volontaire : une position peut désynchroniser, un trou non. Et comme
  /// aucune question n'est sautable, le premier trou est aussi l'endroit exact
  /// où l'utilisateur s'est arrêté.
  int resumeIndexFor(Set<String> answeredItemIds) {
    for (var i = 0; i < items.length; i++) {
      if (!answeredItemIds.contains(items[i].id)) return i;
    }
    return items.length;
  }

  /// True si tous les items ont une réponse.
  bool isCompleteFor(Set<String> answeredItemIds) =>
      resumeIndexFor(answeredItemIds) == items.length;

  /// True si aucun bloc validé n'est précédé d'un bloc candidat — la règle
  /// « instrument validé en premier, nos questions après ».
  bool get validatedBlocksComeFirst {
    var vuCandidat = false;
    for (final bloc in instruments) {
      if (bloc.origin == QItemOrigin.candidate) {
        vuCandidat = true;
      } else if (vuCandidat) {
        return false;
      }
    }
    return true;
  }

  /// Les indices qui ouvrent une nouvelle échelle SANS écran de transition
  /// déclaré. Doit rester vide.
  List<int> get undeclaredScaleChanges => [
        for (var i = 0; i < questionCount; i++)
          if (startsNewScaleAt(i) && instrumentAt(i).transition == null) i
      ];

  @override
  List<Object?> get props => [id, day, kind, instruments];
}
