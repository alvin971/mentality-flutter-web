// D'où vient VRAIMENT le libellé d'un instrument validé.
//
// Les sept gardes de contenu vérifient la FORME : le volume, l'ordre, les six
// langues, l'homogénéité de l'échelle. Aucune ne peut vérifier qu'un item est
// LE VRAI. Un item d'instrument validé mal restitué ne plante rien, ne casse
// aucune garde, et fausse le barème en silence — c'est exactement ce que le
// plan produit §10 appelle « reformuler un instrument casse le barème
// silencieusement ».
//
// Ce type ne résout pas le problème : il le rend VISIBLE. Un instrument
// déclare comment son libellé est arrivé jusqu'ici, et à quel point on en
// répond. La page Méthodologie affiche ces déclarations telles quelles, et une
// garde de test tient le registre des instruments encore non vérifiés.
//
// Pourquoi un NIVEAU en plus du statut : `recalled` est binaire, la confiance
// ne l'est pas. Un instrument de 7 items à formulation figée depuis vingt ans
// et un instrument de 19 items dont les traductions circulent en plusieurs
// variantes porteraient la même étiquette, et la page Méthodologie dirait la
// même chose des deux — plus trompeur que pas d'étiquette du tout.

import 'package:equatable/equatable.dart';

/// Comment le libellé des items est arrivé dans le code.
enum QSourceStatus {
  /// Recopié depuis la source primaire, sous les yeux. Le seul statut qui
  /// autorise à afficher un seuil publié sans réserve.
  verified,

  /// Restitué de mémoire, sans la source sous la main. Le sens et la structure
  /// sont tenus ; la lettre ne l'est pas. Tant qu'un instrument est dans cet
  /// état, son seuil se lit comme une indication, pas comme une mesure.
  recalled,
}

/// À quel point on répond de la restitution. N'a de sens que pour
/// [QSourceStatus.recalled] — un instrument vérifié n'a pas de degré.
enum QSourceConfidence {
  /// Instrument court, très diffusé, formulation stable depuis sa publication.
  high,

  /// Le sens de chaque item et la structure sont tenus ; la formulation exacte
  /// du sous-ensemble publié l'est moins.
  medium,

  /// Plusieurs versions en circulation, de longueurs ou de cotations
  /// différentes. À vérifier avant toute mise en avant du score.
  low,
}

/// La déclaration de provenance d'un bloc validé.
class QProvenance extends Equatable {
  /// Recopié depuis la source primaire. [reference] la cite pour qu'on puisse
  /// aller vérifier — ce n'est PAS la citation de licence
  /// (`QInstrument.citation`) : celle-là est une obligation CC BY, celle-ci
  /// est un pointeur de vérification.
  ///
  /// Le niveau de confiance n'existe QUE pour un instrument restitué de
  /// mémoire : il n'y a pas de degré dans « je l'ai sous les yeux ». C'est
  /// pourquoi les deux états sont deux constructeurs et non un champ
  /// optionnel — on ne peut pas déclarer `verified` en oubliant le niveau, ni
  /// `recalled` sans le donner.
  const QProvenance.verified({required this.reference, this.note = ''})
      : status = QSourceStatus.verified,
        confidence = null;

  /// Restitué de mémoire. [note] dit en une phrase CE QUI est tenu et ce qui
  /// ne l'est pas — elle est affichée telle quelle en page Méthodologie, donc
  /// elle s'écrit pour être lue par quelqu'un qui n'a pas lu ce fichier.
  const QProvenance.recalled({
    required QSourceConfidence level,
    required this.reference,
    required this.note,
  })  : status = QSourceStatus.recalled,
        confidence = level;

  final QSourceStatus status;
  final QSourceConfidence? confidence;
  final String reference;
  final String note;

  bool get isVerified => status == QSourceStatus.verified;

  @override
  List<Object?> get props => [status, confidence, reference, note];
}
