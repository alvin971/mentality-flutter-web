// Le bloc diagnostic — écrit une fois, puis plus jamais.
//
// Trois propriétés, chacune payée par une leçon du dépôt :
//
// · ÉCRITURE UNIQUE, comme l'auto-estimation. La spec produit le dit sans
//   ambiguïté : posé une seule fois, jamais reposé. Reposer la question
//   agacerait, mais surtout : la seconde réponse arriverait APRÈS le
//   dépistage autisme du jour 7, donc amorcée par lui. Le verrou est
//   statique, pour la même raison que dans `SelfEstimateStore` — deux écrans
//   peuvent construire chacun leur store, un verrou d'instance ne garderait
//   alors rien.
//
// · TOUT OU RIEN. Le moteur de questionnaire persiste chaque réponse au fur
//   et à mesure ; ici, non. Une déclaration à moitié remplie (« TDAH » coché,
//   détail jamais donné) entrerait dans le groupe critère sans qu'on sache si
//   le diagnostic vient d'un psychiatre ou d'une intuition — c'est exactement
//   la confusion que le bloc existe pour éviter. Abandonner en route
//   n'enregistre donc rien, et la question reste entière.
//
// · L'ENVOI PART D'ICI. Pas d'un écran de remerciement, pas d'un retour au
//   hub : de la méthode qui écrit. C'est la leçon du parrainage perdu, où
//   l'unique appel qui créditait un parrain vivait derrière un écran
//   facultatif que beaucoup n'atteignaient jamais.

import '../../_shared/data/event_local_store.dart';
import '../../_shared/data/event_upload_service.dart';
import '../../_shared/domain/models/event_day.dart';
import '../../_shared/domain/models/event_submission.dart';
import '../../_shared/domain/models/q_answer_set.dart';
import '../domain/models/diagnostic_answers.dart';

/// Ce qui emporte la déclaration vers le serveur. Injecté pour que les tests
/// du bloc n'aient pas de réseau à simuler.
typedef DiagnosticSubmitter = Future<void> Function(EventSubmission submission);

Future<void> _envoiParDefaut(EventSubmission submission) =>
    EventUploadService.instance.submit(submission);

class DiagnosticBlockStore {
  const DiagnosticBlockStore({
    EventAnswerStore? store,
    this.submit = _envoiParDefaut,
  }) : _injecte = store;

  final EventAnswerStore? _injecte;
  final DiagnosticSubmitter submit;

  EventAnswerStore get _store => _injecte ?? EventLocalStore.instance;

  /// La journée à laquelle le bloc se rattache. Le programme le pose à la fin
  /// du jour 1 : posé plus tard, il aurait été contaminé par les dépistages
  /// des jours suivants.
  static const int day = 1;

  /// Cadrage RGPD : aucune de ces réponses ne calcule quoi que ce soit pour
  /// la personne. Elles servent à construire nos outils, et l'écran le dit.
  static const DayActivityKind kind = DayActivityKind.contribution;

  /// Ce qui a été déclaré, ou `null` si la question est encore entière.
  ///
  /// Un incident de lecture vaut « pas encore déclaré » : la journée s'ouvre,
  /// la question pourra être posée, et le verrou d'écriture rattrapera un
  /// éventuel doublon.
  Future<DiagnosticAnswers?> read() async {
    final QAnswerSet? set;
    try {
      set = await _store.load(DiagnosticAnswers.moduleId);
    } catch (_) {
      return null;
    }
    if (set == null) return null;
    return DiagnosticAnswers.fromAnswers(set.answers);
  }

  /// La question a-t-elle déjà reçu sa réponse ?
  Future<bool> isRecorded() async => await read() != null;

  /// Voir [SelfEstimateStore] : un verrou qui REFUSE plutôt qu'il ne met en
  /// file. Un second appel concurrent n'a pas à attendre son tour pour
  /// découvrir qu'il arrive trop tard.
  static bool _ecritureEnCours = false;

  /// Enregistre [answers], puis confie la déclaration au service d'envoi.
  ///
  /// Renvoie `false` sans rien écrire ni rien envoyer quand la question est
  /// déjà close, quand une autre écriture est en vol, ou quand l'écriture
  /// elle-même a échoué. L'appelant DOIT propager ce `false` : afficher un
  /// remerciement sur une écriture qui n'a pas eu lieu ferait croire à une
  /// déclaration enregistrée, et la question se reposerait ensuite.
  ///
  /// [locale] est la langue de PASSATION, remise par l'écran : un store n'a
  /// pas de `BuildContext`, et une langue mémorisée dans une variable statique
  /// fuirait d'un écran à l'autre — et d'un test au suivant.
  Future<bool> record(DiagnosticAnswers answers, {required String locale}) async {
    if (_ecritureEnCours) return false;
    _ecritureEnCours = true;
    try {
      return await _record(answers, locale);
    } finally {
      _ecritureEnCours = false;
    }
  }

  Future<bool> _record(DiagnosticAnswers answers, String locale) async {
    if (await read() != null) return false;

    final carte = answers.toAnswers();
    // Une carte vide ne décrirait aucune des trois formes : elle se relirait
    // « jamais répondu », et la question se reposerait indéfiniment.
    if (carte.isEmpty) return false;

    final set = QAnswerSet(
      moduleId: DiagnosticAnswers.moduleId,
      answers: carte,
    ).markCompleted();

    try {
      await _store.save(set);
    } catch (_) {
      // Rien n'est écrit : la question reste entière et se reposera. Mieux
      // vaut la reposer que faire croire à un enregistrement qui n'a pas eu
      // lieu — et surtout, ne rien envoyer de ce qu'on n'a pas su garder.
      return false;
    }

    // Confié au service d'envoi, qui enregistre d'abord et rejoue tant que le
    // serveur n'a pas confirmé. Rien n'est attendu ici.
    //
    // La garde art. 9 vit dans ce service, re-vérifiée à CHAQUE tentative : si
    // le consentement était retiré entre l'écran de recueil et cette ligne, la
    // déclaration resterait en file sans qu'un octet ne parte.
    submit(EventSubmission(
      moduleId: DiagnosticAnswers.moduleId,
      day: day,
      kind: kind,
      locale: locale,
      // Jamais partielle : le tout-ou-rien garantit qu'on n'écrit qu'une
      // déclaration entière.
      partial: false,
      answers: carte,
    ));
    return true;
  }
}
