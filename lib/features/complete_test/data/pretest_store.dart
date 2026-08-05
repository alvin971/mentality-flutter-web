// Stockage du questionnaire préalable — chiffré, cloisonné, écrit une fois.
//
// POURQUOI CE FICHIER RÉUTILISE LE STOCKAGE DE L'ÉVÉNEMENT. `EventLocalStore`
// n'est pas « le stockage de l'événement des 8 jours » : c'est la box Hive
// AES-256 partagée de l'app, cloisonnée par passe et fail-closed sans passe
// exploitable. Le questionnaire préalable a exactement les mêmes exigences.
// Écrire une seconde box dupliquerait la dérivation de clé, le cloisonnement
// et le comportement en l'absence de passe — trois endroits où se tromper deux
// fois. `SelfEstimateStore` avait déjà pris ce chemin avant nous.
//
// ⚠️ CONSÉQUENCE : `event_local_store.dart` et `self_estimate_store.dart` ne
// sont plus du code d'événement. Ils portent le questionnaire préalable, qui
// est sur le chemin OBLIGATOIRE du test — ils survivent donc à l'extinction de
// l'événement, et une suppression du dossier `waiting_event/` casserait le
// démarrage du test. Une garde de test épingle ce fait.
//
// RIEN NE PART, ET CE N'EST PAS UN OUBLI. La branche « oui, avec un psychiatre
// ou un psychologue » révèle un contact avec un professionnel de santé
// mentale : c'est une donnée de l'art. 9 RGPD. Le seul chemin d'envoi de l'app
// pour ce type de donnée (`EventUploadService`) exige un consentement art. 9
// que le parcours du test ne recueille nulle part, et pointe vers un worker
// dont l'URL est encore un gabarit. Les réponses restent donc sur l'appareil,
// chiffrées — l'écran le dit à l'utilisateur, et une garde de test vérifie
// qu'aucune n'entre dans la file d'envoi.
//
// ÉCRITURE UNIQUE. La question ne se repose jamais : ni à la reprise d'un test
// interrompu, ni au test suivant. Une seconde réponse serait POSTÉRIEURE à un
// score connu — l'estimation en particulier ne mesurerait plus une croyance
// mais un souvenir de résultat.

import '../../waiting_event/_shared/data/event_local_store.dart';
import '../../waiting_event/_shared/domain/models/q_answer_set.dart';
import '../../waiting_event/reveals/data/self_estimate_store.dart';
import '../domain/models/pretest_answers.dart';

/// Ce que l'on sait du questionnaire préalable : ses réponses, ou rien encore.
class Pretest {
  const Pretest({this.answers, this.estimate = SelfEstimate.absent});

  /// Jamais posé, ou pas encore lisible (aucun passe exploitable).
  static const Pretest absent = Pretest();

  final PretestAnswers? answers;

  /// L'auto-estimation, quand elle a été demandée. Vit dans son propre
  /// stockage à écriture unique — voir [PretestStore.record].
  final SelfEstimate estimate;

  /// True quand la question obligatoire a reçu sa réponse. C'est ce que regarde
  /// l'écran de lancement pour ne jamais reposer le questionnaire.
  bool get isSettled => answers != null;
}

class PretestStore {
  const PretestStore({
    EventAnswerStore? store,
    SelfEstimateStore? estimate,
  })  : _injecte = store,
        _estimateInjecte = estimate;

  /// Identifiant de stockage. Ce n'est PAS un module du programme des 8 jours :
  /// il n'est enregistré dans aucun `QModuleRegistry`, n'apparaît sur aucune
  /// journée et n'entre dans aucune règle de volume.
  static const String moduleId = 'pretest';

  final EventAnswerStore? _injecte;
  final SelfEstimateStore? _estimateInjecte;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  SelfEstimateStore get _estimate =>
      _estimateInjecte ?? SelfEstimateStore(_injecte);

  /// Un incident de lecture vaut « question encore ouverte ». Le test doit
  /// pouvoir démarrer même si le stockage est indisponible : mieux vaut
  /// reposer la question qu'empêcher quelqu'un de passer le test.
  Future<Pretest> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(moduleId);
    } catch (_) {
      return Pretest.absent;
    }
    if (set == null) return Pretest.absent;
    final answers = PretestAnswers.fromItems(set.answers);
    if (answers == null) return Pretest.absent;

    SelfEstimate estimate;
    try {
      estimate = await _estimate.read();
    } catch (_) {
      estimate = SelfEstimate.absent;
    }
    return Pretest(answers: answers, estimate: estimate);
  }

  /// Verrou de ré-entrance. `record` lit, teste, puis écrit : sans lui, deux
  /// appuis rapprochés verraient tous deux une question ouverte et le second
  /// écraserait le premier — l'écriture unique ne serait qu'une intention.
  ///
  /// Statique, et pas d'instance : rien n'empêche deux écrans de construire
  /// chacun leur `PretestStore`, et un verrou par instance ne garderait alors
  /// rien. C'est aussi ce qui laisse le constructeur `const`.
  static bool _ecritureEnCours = false;

  /// Enregistre les réponses. Renvoie `false` sans rien écrire quand la
  /// question est déjà close, quand une autre écriture est déjà en vol, ou
  /// quand l'écriture elle-même a échoué.
  ///
  /// [askedEstimate] dit si la question d'auto-estimation a été POSÉE (branches
  /// « test en ligne » et « jamais »). Quand elle l'a été, [estimate] porte la
  /// valeur donnée, ou `null` pour un refus explicite — un refus est une
  /// réponse, il clôt la question au lieu de la faire revenir.
  ///
  /// L'estimation part dans SON stockage, jamais dans les items ci-dessus :
  /// c'est ce qui garantit qu'elle ne sera pas reposée si le programme des
  /// 8 jours est rallumé un jour. Son échec d'écriture ne fait PAS échouer
  /// l'ensemble — la question obligatoire, elle, est enregistrée.
  Future<bool> record(
    PretestAnswers answers, {
    bool askedEstimate = false,
    int? estimate,
  }) async {
    if (_ecritureEnCours) return false;
    _ecritureEnCours = true;
    try {
      return await _record(answers,
          askedEstimate: askedEstimate, estimate: estimate);
    } finally {
      _ecritureEnCours = false;
    }
  }

  Future<bool> _record(
    PretestAnswers answers, {
    required bool askedEstimate,
    required int? estimate,
  }) async {
    final deja = await read();
    if (deja.isSettled) return false;

    var set = QAnswerSet(moduleId: moduleId);
    answers.toItems().forEach((item, valeur) {
      set = set.withAnswer(item, valeur);
    });
    try {
      await _store.save(set.markCompleted());
    } catch (_) {
      // Rien n'est écrit : la question reste ouverte et se reposera au prochain
      // lancement. Mieux vaut la reposer que faire croire à un enregistrement
      // qui n'a pas eu lieu.
      return false;
    }

    if (askedEstimate) {
      // Volontairement APRÈS, et sans propager son échec : la valeur de
      // l'estimation tient à ce qu'elle soit donnée avant tout résultat, pas à
      // ce qu'elle accompagne la réponse obligatoire. Si elle n'a pas pu être
      // écrite, elle reste ouverte de son côté.
      try {
        await _estimate.record(estimate);
      } catch (_) {
        // ignoré : voir ci-dessus.
      }
    }
    return true;
  }
}
