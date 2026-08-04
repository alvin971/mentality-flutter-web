// L'auto-estimation du QI — une question, posée une seule fois, gardée ici.
//
// C'est le seul reste de l'échelle HPI écartée : puisque le QI est MESURÉ par
// la batterie, un questionnaire qui le devine n'a aucun sens ; en revanche,
// l'écart entre ce que quelqu'un croit valoir et ce qu'il mesure est une
// donnée que personne d'autre n'a. Elle se recueille au jour 1, AVANT toute
// révélation, et se rend au jour 8.
//
// Trois propriétés tiennent la valeur de cette donnée :
//
// · ÉCRITURE UNIQUE. Une seconde estimation serait POSTÉRIEURE à une
//   révélation, donc ancrée par elle : elle ne mesurerait plus une croyance
//   mais un souvenir. La première réponse est donc la seule, et `record`
//   refuse d'écraser.
// · LE REFUS EST UNE RÉPONSE. Sans lui, quelqu'un qui ne veut pas se prononcer
//   se verrait reposer la question à chaque ouverture du jour 1 jusqu'à
//   répondre n'importe quoi. Un refus explicite clôt la question sans rien
//   inventer.
// · RIEN NE PART. On réutilise le stockage chiffré et cloisonné par passe du
//   moteur de questionnaire, mais JAMAIS sa file d'envoi : cette valeur reste
//   sur l'appareil. Aucun consentement art. 9 n'est recueilli à ce stade, donc
//   rien n'a le droit de sortir (une garde de test le vérifie).

import '../../_shared/data/event_local_store.dart';
import '../../_shared/domain/models/q_answer_set.dart';

/// Ce que l'on sait de l'estimation : sa valeur, ou le fait qu'elle ait été
/// refusée, ou rien encore.
class SelfEstimate {
  const SelfEstimate({this.value, this.declined = false});

  /// Jamais posée, ou pas encore lisible (aucun passe exploitable).
  static const SelfEstimate absent = SelfEstimate();

  static const SelfEstimate refused = SelfEstimate(declined: true);

  final int? value;
  final bool declined;

  /// True quand la question est CLOSE — répondue ou déclinée. C'est ce que
  /// regarde le jour 1 pour ne jamais la reposer.
  bool get isSettled => value != null || declined;

  @override
  String toString() => value != null
      ? 'SelfEstimate($value)'
      : (declined ? 'SelfEstimate(refusée)' : 'SelfEstimate(absente)');
}

class SelfEstimateStore {
  const SelfEstimateStore([EventAnswerStore? store]) : _injecte = store;

  /// Identifiant de stockage. Ce n'est PAS un module du programme : il n'est
  /// pas enregistré dans `QModuleRegistry`, donc il n'apparaît sur aucune
  /// journée et n'entre dans aucune règle de volume.
  static const String moduleId = 'self_estimate';

  static const String estimateItemId = 'iq_self_estimate';

  /// Clé du refus. Distincte de la valeur pour qu'un refus ne puisse jamais
  /// être relu comme un nombre.
  static const String declinedItemId = 'declined';

  /// Bornes de l'échelle proposée. Une valeur hors bornes est une donnée
  /// corrompue, pas une estimation : elle est refusée à l'écriture et ignorée
  /// à la lecture.
  static const int minValue = 60;
  static const int maxValue = 150;

  final EventAnswerStore? _injecte;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  /// Un incident de lecture vaut « question encore ouverte » : la journée
  /// s'ouvre quand même, et la question pourra être posée. C'est la même
  /// prudence que [RevealSource] — un stockage indisponible ne doit pas
  /// empêcher d'entrer dans le programme.
  Future<SelfEstimate> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(moduleId);
    } catch (_) {
      return SelfEstimate.absent;
    }
    if (set == null) return SelfEstimate.absent;
    final valeur = set.valueOf(estimateItemId);
    if (valeur != null && valeur >= minValue && valeur <= maxValue) {
      return SelfEstimate(value: valeur);
    }
    if (set.valueOf(declinedItemId) != null) return SelfEstimate.refused;
    return SelfEstimate.absent;
  }

  /// Verrou d'écriture. `record` lit, teste, puis écrit : sans lui, deux
  /// appels lancés avant que le premier n'ait sauvegardé verraient tous deux
  /// une question ouverte, et le second écraserait le premier — l'écriture
  /// unique ne serait qu'une intention. Le stockage est asynchrone
  /// (dérivation de clé, ouverture de box), la fenêtre est donc réelle.
  ///
  /// Il REFUSE plutôt qu'il ne met en file : c'est le sens même de l'écriture
  /// unique. Un second appel concurrent n'a pas à attendre son tour pour
  /// découvrir qu'il arrive trop tard — la seule réponse juste est « non ».
  ///
  /// Statique, et pas d'instance : il n'y a qu'UNE question d'auto-estimation
  /// par appareil, mais rien n'empêche deux écrans de construire chacun leur
  /// `SelfEstimateStore` — un verrou par instance ne garderait alors rien.
  /// C'est aussi ce qui laisse le constructeur `const`.
  static bool _ecritureEnCours = false;

  /// Enregistre l'estimation [value], ou un refus si elle est `null`.
  ///
  /// Renvoie `false` sans rien écrire quand la question est déjà close (voir
  /// « écriture unique » en tête de fichier), quand la valeur est hors bornes,
  /// quand une autre écriture est déjà en vol, ou quand l'écriture elle-même
  /// a échoué.
  Future<bool> record(int? value) async {
    if (_ecritureEnCours) return false;
    _ecritureEnCours = true;
    try {
      return await _record(value);
    } finally {
      _ecritureEnCours = false;
    }
  }

  Future<bool> _record(int? value) async {
    if (value != null && (value < minValue || value > maxValue)) return false;
    final deja = await read();
    if (deja.isSettled) return false;

    final set = QAnswerSet(moduleId: moduleId)
        .withAnswer(value == null ? declinedItemId : estimateItemId, value ?? 1)
        .markCompleted();
    try {
      await _store.save(set);
    } catch (_) {
      // Rien n'est écrit : la question reste ouverte et se reposera. Mieux vaut
      // la reposer que faire croire à un enregistrement qui n'a pas eu lieu.
      return false;
    }
    return true;
  }
}
