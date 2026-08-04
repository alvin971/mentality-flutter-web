// Un bloc de questions homogène : une échelle, une origine, un ordre.
//
// C'est l'unité qui protège les instruments validés. Un `QInstrument` d'origine
// [QItemOrigin.validated] est reproduit INTACT — ses items dans leur ordre
// d'origine, rien d'inséré entre eux, son échelle inchangée — parce que le
// seuil publié a été calibré ainsi. Nos questions maison forment leurs PROPRES
// blocs, placés après, et ne peuvent donc pas s'intercaler par accident.

import 'package:equatable/equatable.dart';

import 'q_item.dart';
import 'q_provenance.dart';
import 'q_scale.dart';
import 'q_text.dart';

/// D'où viennent les questions d'un bloc — et donc ce qu'on a le droit d'en
/// faire.
enum QItemOrigin {
  /// Instrument publié et validé. Reproduit tel quel, il porte le score et le
  /// seuil. Le reformuler casserait le barème et en ferait une œuvre dérivée.
  validated,

  /// Nos questions candidates. Elles ne calculent AUCUN score affiché : elles
  /// servent à construire nos propres échelles.
  candidate,
}

/// Écran de couture, affiché quand un bloc change l'échelle de réponse.
///
/// Déclarer la transition est OBLIGATOIRE dès que l'échelle change (une garde
/// de test le vérifie) : sans elle, l'utilisateur verrait les boutons changer
/// sous ses doigts sans explication.
class QTransition extends Equatable {
  const QTransition({required this.title, required this.body});

  final QText title;
  final QText body;

  @override
  List<Object?> get props => [title, body];
}

class QInstrument extends Equatable {
  const QInstrument({
    required this.id,
    required this.origin,
    required this.scale,
    required this.items,
    this.citation,
    this.provenance,
    this.transition,
  });

  /// Identifiant stable du bloc (`raads14`, `catq`, `autism_extra`…).
  final String id;

  final QItemOrigin origin;

  /// L'échelle de TOUT le bloc — un bloc, une échelle.
  final QScale scale;

  /// Les items dans leur ordre canonique. L'ordre est un contrat, pas une
  /// préférence d'affichage.
  final List<QItem> items;

  /// Citation exigée par la licence (CC BY pour le RAADS-14 et le CAT-Q).
  /// Affichée en page Méthodologie, jamais au milieu du flux.
  final String? citation;

  /// D'où vient le libellé des items — recopié d'une source, ou restitué de
  /// mémoire. `null` pour un bloc [QItemOrigin.candidate] : nos questions sont
  /// à nous, il n'y a pas de source dont s'écarter.
  ///
  /// Obligatoire pour un bloc validé, et une garde de contenu le vérifie. Un
  /// instrument publié dont on ne dit pas comment il est arrivé ici est
  /// exactement ce qu'on ne saura plus juger dans six mois.
  final QProvenance? provenance;

  /// Écran annonçant le changement d'échelle, quand ce bloc en ouvre une
  /// nouvelle.
  final QTransition? transition;

  /// True si ce bloc porte un score affichable à l'utilisateur.
  bool get isScored => origin == QItemOrigin.validated;

  /// True si le libellé de ce bloc n'a PAS été confronté à sa source primaire.
  /// Le registre en tient la liste, et la page Méthodologie l'affiche.
  bool get isRecalled => provenance?.status == QSourceStatus.recalled;

  @override
  List<Object?> get props =>
      [id, origin, scale, items, citation, provenance, transition];
}
