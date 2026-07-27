// Ce qui part au serveur — et rien de plus.
//
// Une soumission est le jeu de réponses d'UN module, accompagné du strict
// nécessaire pour l'exploiter : la journée, le cadrage RGPD (annoncé ou
// contribution), la langue de passation, et le drapeau partiel.
//
// Trois absences valent d'être écrites noir sur blanc :
//
// · AUCUN HORODATAGE, ici non plus. Ni date, ni heure, ni durée. Le worker
//   posera lui-même une date au JOUR ; l'instant précis d'un envoi de santé
//   serait un quasi-identifiant.
// · AUCUN `account`. La partition est dérivée SERVEUR du passe signé. Un
//   compte glissé dans la charge utile serait ignoré (le selftest du worker le
//   vérifie) — autant ne pas l'envoyer.
// · AUCUN SCORE. Les scores se calculent sur l'appareil ; envoyer une valeur
//   déjà interprétée reviendrait à figer un barème dans les données brutes.

import 'package:equatable/equatable.dart';

import 'event_day.dart';
import 'q_answer_set.dart';
import 'q_module.dart';

/// Version du contrat de charge utile. Miroir de `SUPPORTED_SCHEMA` dans
/// workers/event/index.js — le worker refuse (400) toute autre valeur.
const int kEventPayloadSchema = 1;

class EventSubmission extends Equatable {
  const EventSubmission({
    required this.moduleId,
    required this.day,
    required this.kind,
    required this.locale,
    required this.partial,
    required this.answers,
  });

  /// Construit la soumission d'un jeu de réponses pour son module.
  ///
  /// [answers.isPartial] fait foi sur le drapeau : un abandon part marqué tel
  /// quel, jamais requalifié en questionnaire complet.
  factory EventSubmission.of(
    QModule module,
    QAnswerSet answers, {
    required String locale,
  }) =>
      EventSubmission(
        moduleId: answers.moduleId,
        day: module.day,
        kind: module.kind,
        locale: locale,
        partial: answers.isPartial,
        answers: Map.unmodifiable(answers.answers),
      );

  final String moduleId;
  final int day;
  final DayActivityKind kind;
  final String locale;
  final bool partial;

  /// identifiant d'item → valeur BRUTE de la cotation publiée.
  final Map<String, int> answers;

  bool get isEmpty => answers.isEmpty;

  /// La charge utile envoyée au worker. Les noms de champs sont un contrat
  /// partagé avec workers/event/index.js.
  Map<String, dynamic> toWire() => {
        'schema': kEventPayloadSchema,
        'moduleId': moduleId,
        'day': day,
        'kind': kind.name,
        'partial': partial,
        'locale': locale,
        'answers': answers,
      };

  /// Forme persistée dans la file d'attente locale. Identique à la charge
  /// utile : ce qui attend sur le disque est exactement ce qui partira, il n'y
  /// a donc rien à re-dériver au moment du rejeu.
  Map<String, dynamic> toJson() => toWire();

  /// Relecture tolérante. Une entrée dont le cadrage ou la journée sont
  /// illisibles est rejetée (`null`) plutôt que devinée : envoyer un module
  /// sous un mauvais cadrage RGPD serait pire que ne pas l'envoyer.
  static EventSubmission? fromJson(Map<String, dynamic> json) {
    final moduleId = json['moduleId'];
    final day = json['day'];
    final locale = json['locale'];
    final partial = json['partial'];
    if (moduleId is! String || moduleId.isEmpty) return null;
    if (day is! int || day < 1 || day > 8) return null;
    if (locale is! String || locale.isEmpty) return null;
    if (partial is! bool) return null;

    DayActivityKind? kind;
    for (final candidat in DayActivityKind.values) {
      if (candidat.name == json['kind']) kind = candidat;
    }
    if (kind == null) return null;

    final brut = json['answers'];
    if (brut is! Map) return null;
    final reponses = <String, int>{};
    brut.forEach((cle, valeur) {
      if (cle is String && valeur is int) reponses[cle] = valeur;
    });
    if (reponses.isEmpty) return null;

    return EventSubmission(
      moduleId: moduleId,
      day: day,
      kind: kind,
      locale: locale,
      partial: partial,
      answers: Map.unmodifiable(reponses),
    );
  }

  @override
  List<Object?> get props => [moduleId, day, kind, locale, partial, answers];
}
