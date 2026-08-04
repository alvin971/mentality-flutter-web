// Le record du jeu des durées — sur l'appareil, et NULLE PART AILLEURS.
//
// ═══ RIEN NE PART ═══
//
// Troisième jeu, troisième fois le même raisonnement, et il vaut la peine d'être
// redit une dernière fois puisqu'il vaudra encore pour H4 et H5. La file d'envoi
// de l'événement est bâtie pour des réponses de questionnaire de santé : le
// worker n'accepte que les cadrages `announced` et `contribution`, et exige la
// finalité art. 9 `event-health-research`. Un résultat de jeu n'est ni l'un ni
// l'autre ; l'y faire passer imposerait de l'étiqueter comme donnée de santé
// dans le jeu de données lui-même. Faire monter les agrégats de jeu demande une
// extension explicite du contrat de fil (Dart ET worker) et une décision sur la
// base légale — cela n'a pas à se glisser dans un lot de jeu. Une garde de test
// espionne `EventUploadService`.
//
// ═══ UN RECORD, ET IL SE PREND PAR LE BAS ═══
//
// Contrairement au jeu du délai, celui-ci garde un meilleur score. La raison est
// dans l'en-tête de [TimeAcuityScore] : un seuil de discrimination a un sens
// orienté, plus fin est objectivement plus fin, et chercher à le réduire est un
// effort honnête. Le record se prend donc par MINIMUM, comme l'écart du Stroop.
//
// Seules les parties fiables entrent au record. Une partie tapée au hasard ou
// abandonnée produit un seuil que rien ne soutient ; la laisser s'inscrire
// gèlerait un chiffre que personne ne pourrait plus battre honnêtement.

import '../../_shared/data/event_local_store.dart';
import '../../_shared/domain/models/q_answer_set.dart';
import '../domain/models/time_acuity_score.dart';

/// L'état du jeu sur cet appareil.
class TimeEstimationRecord {
  const TimeEstimationRecord({
    this.bestThresholdPercent,
    this.lastThresholdPercent,
    this.plays = 0,
  });

  /// Jamais joué — ou stockage illisible. Les deux se traitent pareil.
  static const TimeEstimationRecord none = TimeEstimationRecord();

  /// Le seuil le plus FIN obtenu sur une partie fiable.
  final int? bestThresholdPercent;

  final int? lastThresholdPercent;

  /// Nombre de parties fiables enregistrées.
  final int plays;

  bool get hasPlayed => plays > 0;
}

class TimeEstimationRecordStore {
  const TimeEstimationRecordStore([EventAnswerStore? store]) : _injecte = store;

  /// Identifiant de stockage. Ce n'est PAS un module du programme : il n'est
  /// enregistré dans aucun `QModuleRegistry`, donc il n'entre dans aucune règle
  /// de volume 40-50 et n'apparaît sur la journée d'aucun questionnaire.
  static const String moduleId = 'time_estimation_game';

  /// Clés PERSISTÉES : les renommer effacerait silencieusement les parties déjà
  /// jouées.
  static const String bestKey = 'best_threshold_percent';
  static const String lastKey = 'last_threshold_percent';
  static const String playsKey = 'plays';

  final EventAnswerStore? _injecte;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  /// Un incident de lecture vaut « jamais joué » : la carte s'affiche, et la
  /// partie suivante s'enregistrera. Refuser d'ouvrir le jeu parce qu'on n'arrive
  /// pas à relire un chiffre serait disproportionné.
  Future<TimeEstimationRecord> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(moduleId);
    } catch (_) {
      return TimeEstimationRecord.none;
    }
    if (set == null) return TimeEstimationRecord.none;
    return TimeEstimationRecord(
      bestThresholdPercent: set.valueOf(bestKey),
      lastThresholdPercent: set.valueOf(lastKey),
      plays: set.valueOf(playsKey) ?? 0,
    );
  }

  /// Enregistre [score] et renvoie le record mis à jour.
  ///
  /// Une partie non fiable n'écrit RIEN et laisse le record intact : elle ne
  /// compte ni comme partie jouée, ni comme tentative de record. Le record rendu
  /// est alors celui d'avant, tel quel.
  Future<TimeEstimationRecord> record(TimeAcuityScore score) async {
    if (!score.isReliable) return read();

    final avant = await read();
    final ancien = avant.bestThresholdPercent;
    final seuil = score.thresholdPercent;
    final meilleur = ancien == null || seuil < ancien ? seuil : ancien;

    final apres = TimeEstimationRecord(
      bestThresholdPercent: meilleur,
      lastThresholdPercent: seuil,
      plays: avant.plays + 1,
    );

    try {
      await _store.save(
        QAnswerSet(moduleId: moduleId)
            .withAnswer(bestKey, meilleur)
            .withAnswer(lastKey, seuil)
            .withAnswer(playsKey, apres.plays)
            .markCompleted(),
      );
    } catch (_) {
      // Le disque a refusé : la partie qui vient d'être jouée s'affiche quand
      // même avec son résultat, elle ne sera simplement pas retrouvée la
      // prochaine fois. Mentir sur l'enregistrement ne servirait personne.
      return avant;
    }
    return apres;
  }
}
