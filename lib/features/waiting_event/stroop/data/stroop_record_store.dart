// Le record du Stroop — sur l'appareil, et NULLE PART AILLEURS.
//
// ═══ RIEN NE PART ═══
//
// Ce store écrit dans la box chiffrée du module (le même stockage que le
// moteur de questionnaire), mais ne touche JAMAIS la file d'envoi. Une garde
// de test le vérifie en espionnant `EventUploadService`.
//
// Ce n'est pas un oubli, c'est le seul chemin correct aujourd'hui. La file
// d'envoi de l'événement est bâtie pour des réponses de questionnaire de
// santé : le worker n'accepte que les cadrages `announced` et `contribution`,
// et il exige la finalité art. 9 `event-health-research`. Un résultat de jeu
// n'est ni l'un ni l'autre. L'y faire passer imposerait de le déguiser en
// contribution — c'est-à-dire d'étiqueter un jeu comme une donnée de santé
// dans le jeu de données lui-même. Faire monter les agrégats de jeu demande
// une extension explicite du contrat de fil (côté Dart ET côté worker) et une
// décision sur la base légale qui s'y applique : cela n'a pas à se glisser
// dans un lot de jeu.
//
// ═══ REJOUABLE, DONC PAS EN ÉCRITURE UNIQUE ═══
//
// Contrairement à l'auto-estimation du QI (une croyance, qu'une révélation
// ancrerait à jamais), le Stroop se rejoue autant qu'on veut : rien ne se
// gâte à le refaire. Le store garde donc DEUX choses — la dernière partie, et
// le meilleur écart obtenu.
//
// Seules les parties FIABLES entrent au record. Une partie écourtée, ou noyée
// d'erreurs, produit une médiane que le hasard suffit à expliquer ; la laisser
// s'inscrire comme meilleur score gèlerait un chiffre que personne ne pourrait
// plus battre honnêtement.
//
// ═══ MEILLEUR = LE PLUS BAS ═══
//
// L'écart mesure un COÛT : moins il est grand, mieux l'inhibition a marché.
// Le record se prend donc par minimum — et il accepte les valeurs négatives,
// qui sont rares mais réelles.

import '../../_shared/data/event_local_store.dart';
import '../../_shared/domain/models/q_answer_set.dart';
import '../domain/models/stroop_score.dart';

/// L'état du jeu sur cet appareil : ce qui a déjà été joué, s'il y a lieu.
class StroopRecord {
  const StroopRecord({
    this.bestInterferenceMs,
    this.lastInterferenceMs,
    this.lastAccuracyPercent,
    this.plays = 0,
  });

  /// Jamais joué — ou stockage illisible. Les deux se traitent pareil :
  /// l'écran s'ouvre, et la partie qu'on y jouera s'enregistrera.
  static const StroopRecord none = StroopRecord();

  /// Le plus PETIT écart obtenu sur une partie fiable.
  final int? bestInterferenceMs;

  final int? lastInterferenceMs;
  final int? lastAccuracyPercent;

  /// Nombre de parties fiables enregistrées.
  final int plays;

  bool get hasPlayed => bestInterferenceMs != null;
}

class StroopRecordStore {
  const StroopRecordStore([EventAnswerStore? store]) : _injecte = store;

  /// Identifiant de stockage. Ce n'est PAS un module du programme : il n'est
  /// enregistré dans aucun `QModuleRegistry`, donc il n'entre dans aucune
  /// règle de volume 40-50 et n'apparaît sur la journée d'aucun questionnaire.
  static const String moduleId = 'stroop_game';

  /// Les clés du record. Ce sont des CLÉS PERSISTÉES : les renommer effacerait
  /// silencieusement les parties déjà jouées.
  static const String bestKey = 'best_interference_ms';
  static const String lastKey = 'last_interference_ms';
  static const String accuracyKey = 'last_accuracy_percent';
  static const String playsKey = 'plays';

  final EventAnswerStore? _injecte;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  /// Un incident de lecture vaut « jamais joué » : la carte s'affiche sans
  /// record, et la partie suivante s'enregistrera. Refuser d'ouvrir le jeu
  /// parce qu'on n'arrive pas à relire un score serait disproportionné.
  Future<StroopRecord> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(moduleId);
    } catch (_) {
      return StroopRecord.none;
    }
    if (set == null) return StroopRecord.none;
    return StroopRecord(
      bestInterferenceMs: set.valueOf(bestKey),
      lastInterferenceMs: set.valueOf(lastKey),
      lastAccuracyPercent: set.valueOf(accuracyKey),
      plays: set.valueOf(playsKey) ?? 0,
    );
  }

  /// Enregistre [score] et renvoie le record mis à jour.
  ///
  /// Une partie non fiable n'écrit RIEN et laisse le record intact : elle ne
  /// compte ni comme partie jouée, ni comme tentative de record. Le record
  /// rendu est alors celui d'avant, tel quel.
  Future<StroopRecord> record(StroopScore score) async {
    if (!score.isReliable) return read();

    final avant = await read();
    final ancien = avant.bestInterferenceMs;
    final ecart = score.interferenceMs;
    final meilleur = ancien == null || ecart < ancien ? ecart : ancien;

    final apres = StroopRecord(
      bestInterferenceMs: meilleur,
      lastInterferenceMs: ecart,
      lastAccuracyPercent: score.accuracyPercent,
      plays: avant.plays + 1,
    );

    try {
      await _store.save(
        QAnswerSet(moduleId: moduleId)
            .withAnswer(bestKey, meilleur)
            .withAnswer(lastKey, ecart)
            .withAnswer(accuracyKey, score.accuracyPercent)
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
