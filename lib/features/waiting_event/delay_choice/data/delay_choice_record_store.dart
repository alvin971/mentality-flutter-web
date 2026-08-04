// Ce que le jeu de délai garde sur l'appareil — et ce qu'il refuse de garder.
//
// ═══ RIEN NE PART ═══
//
// Comme le Stroop : écriture dans la box chiffrée du module, JAMAIS dans la file
// d'envoi. Une garde de test l'espionne.
//
// Le raisonnement est le même et vaut d'être redit, parce qu'il vaudra encore
// pour les jeux H3 à H5. La file de l'événement est bâtie pour des réponses de
// questionnaire de santé : le worker n'accepte que les cadrages `announced` et
// `contribution`, et exige la finalité art. 9 `event-health-research`. Un
// résultat de jeu n'est ni l'un ni l'autre ; l'y faire passer imposerait de
// l'étiqueter comme donnée de santé dans le jeu de données lui-même. Faire
// monter les agrégats de jeu demande une extension explicite du contrat de fil
// (Dart ET worker) et une décision sur la base légale — cela n'a pas à se
// glisser dans un lot de jeu.
//
// ═══ PAS DE RECORD — ET C'EST LE POINT ═══
//
// Le Stroop garde un meilleur écart. Ce jeu-ci n'a PAS d'équivalent, et
// l'absence est délibérée : il n'y a pas de bonne réponse à un arbitrage entre
// maintenant et plus tard (voir l'en-tête de [DelayChoiceScore]). Un « meilleur
// score » désignerait un bout de l'échelle comme supérieur à l'autre, et
// pousserait à répondre pour le battre plutôt que selon sa préférence — auquel
// cas la seule chose mesurée serait l'envie de gagner.
//
// Ce qui est gardé, c'est la DERNIÈRE partie. Se comparer à soi-même d'un mois
// sur l'autre a du sens ; se classer n'en a pas.
//
// Seules les parties cohérentes s'enregistrent : une courbe qui remonte
// franchement (critère de monotonie) ne compte pas même comme partie jouée.

import '../../_shared/data/event_local_store.dart';
import '../../_shared/domain/models/q_answer_set.dart';
import '../domain/models/delay_choice_score.dart';

/// L'état du jeu sur cet appareil.
class DelayChoiceRecord {
  const DelayChoiceRecord({this.lastPatiencePercent, this.plays = 0});

  /// Jamais joué — ou stockage illisible. Les deux se traitent pareil.
  static const DelayChoiceRecord none = DelayChoiceRecord();

  /// L'index de la dernière partie cohérente, sur 100. Jamais un maximum.
  final int? lastPatiencePercent;

  /// Nombre de parties cohérentes enregistrées.
  final int plays;

  bool get hasPlayed => plays > 0;
}

class DelayChoiceRecordStore {
  const DelayChoiceRecordStore([EventAnswerStore? store]) : _injecte = store;

  /// Identifiant de stockage. Ce n'est PAS un module du programme : il n'est
  /// enregistré dans aucun `QModuleRegistry`, donc il n'entre dans aucune règle
  /// de volume 40-50 et n'apparaît sur la journée d'aucun questionnaire.
  static const String moduleId = 'delay_choice_game';

  /// Clés PERSISTÉES : les renommer effacerait silencieusement les parties déjà
  /// jouées.
  static const String lastKey = 'last_patience_percent';
  static const String playsKey = 'plays';

  final EventAnswerStore? _injecte;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  /// Un incident de lecture vaut « jamais joué » : la carte s'affiche, et la
  /// partie suivante s'enregistrera. Refuser d'ouvrir le jeu parce qu'on
  /// n'arrive pas à relire un chiffre serait disproportionné.
  Future<DelayChoiceRecord> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(moduleId);
    } catch (_) {
      return DelayChoiceRecord.none;
    }
    if (set == null) return DelayChoiceRecord.none;
    return DelayChoiceRecord(
      lastPatiencePercent: set.valueOf(lastKey),
      plays: set.valueOf(playsKey) ?? 0,
    );
  }

  /// Enregistre [score] et rend l'état d'AVANT — c'est lui que l'écran de
  /// résultat affiche (« la dernière fois : … »).
  ///
  /// Rendre l'état d'après n'aurait aucun intérêt ici : il contiendrait la
  /// partie qu'on vient de jouer, déjà affichée juste au-dessus. C'est
  /// exactement l'inverse du Stroop, qui rend l'état d'après parce que le
  /// record a pu changer.
  ///
  /// Une partie incohérente n'écrit RIEN et laisse tout intact : elle ne compte
  /// pas comme partie jouée.
  Future<DelayChoiceRecord> record(DelayChoiceScore score) async {
    final avant = await read();
    if (!score.isReliable) return avant;

    try {
      await _store.save(
        QAnswerSet(moduleId: moduleId)
            .withAnswer(lastKey, score.patiencePercent)
            .withAnswer(playsKey, avant.plays + 1)
            .markCompleted(),
      );
    } catch (_) {
      // Le disque a refusé : la partie s'affiche quand même avec son résultat,
      // elle ne sera simplement pas retrouvée la prochaine fois. Mentir sur
      // l'enregistrement ne servirait personne.
      return avant;
    }
    return avant;
  }
}
