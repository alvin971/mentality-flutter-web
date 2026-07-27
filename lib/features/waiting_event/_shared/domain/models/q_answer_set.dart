// Les réponses d'un module — l'état repris à la réouverture, et la charge
// utile que le worker recevra plus tard.
//
// Deux choix de conception valent d'être écrits noir sur blanc :
//
// 1. AUCUN HORODATAGE. Ni ici, ni dans le stockage. Le programme ne lit jamais
//    l'horloge du téléphone (le jour vient du serveur), et les conventions
//    anti-ré-identification du dépôt proscrivent l'horodatage fin d'une donnée
//    de santé. Une date seule accompagnera l'envoi, côté worker.
//
// 2. LE PARTIEL EST UN ÉTAT NOMMÉ. Abandonner est permis ; ce qui ne l'est pas,
//    c'est qu'un abandon ressemble à un questionnaire fini. Tant que
//    [QAnswerStatus.completed] n'est pas atteint, le jeu de réponses se déclare
//    partiel, et il partira marqué comme tel.

import 'package:equatable/equatable.dart';

enum QAnswerStatus {
  /// Commencé, pas terminé. C'est aussi l'état d'un abandon : les réponses
  /// déjà données restent, et la reprise les retrouve.
  inProgress,

  /// Toutes les questions ont reçu une réponse.
  completed,
}

class QAnswerSet extends Equatable {
  const QAnswerSet({
    required this.moduleId,
    this.answers = const {},
    this.status = QAnswerStatus.inProgress,
  });

  final String moduleId;

  /// identifiant d'item → valeur BRUTE choisie (la cotation publiée, jamais un
  /// indice de bouton : renuméroter ici casserait les seuils).
  final Map<String, int> answers;

  final QAnswerStatus status;

  /// Ce qui partira marqué « partiel ». Un abandon n'est pas une erreur, mais
  /// il ne doit jamais passer pour un questionnaire complet.
  bool get isPartial => status != QAnswerStatus.completed;

  int get answeredCount => answers.length;

  Set<String> get answeredItemIds => answers.keys.toSet();

  /// La réponse donnée à [itemId], ou `null`.
  int? valueOf(String itemId) => answers[itemId];

  /// Enregistre (ou remplace) une réponse. Revenir en arrière pour se corriger
  /// est permis — ce n'est pas sauter une question.
  QAnswerSet withAnswer(String itemId, int value) => QAnswerSet(
        moduleId: moduleId,
        answers: {...answers, itemId: value},
        status: status,
      );

  /// Marque le questionnaire terminé. Appelé une seule fois, quand la dernière
  /// question a reçu sa réponse.
  QAnswerSet markCompleted() => QAnswerSet(
        moduleId: moduleId,
        answers: answers,
        status: QAnswerStatus.completed,
      );

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'answers': answers,
        'status': status.name,
      };

  /// Relecture tolérante : une entrée illisible est ignorée plutôt que de
  /// faire perdre tout le reste des réponses.
  factory QAnswerSet.fromJson(Map<String, dynamic> json) {
    final brut = json['answers'];
    final reponses = <String, int>{};
    if (brut is Map) {
      brut.forEach((cle, valeur) {
        if (cle is String && valeur is int) reponses[cle] = valeur;
      });
    }
    return QAnswerSet(
      moduleId: json['moduleId'] as String? ?? '',
      answers: reponses,
      status: json['status'] == QAnswerStatus.completed.name
          ? QAnswerStatus.completed
          : QAnswerStatus.inProgress,
    );
  }

  @override
  List<Object?> get props => [moduleId, answers, status];
}
