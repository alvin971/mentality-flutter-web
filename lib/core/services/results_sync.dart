// lib/core/services/results_sync.dart
//
// Envoi des mesures AU FIL DE L'EAU, sous-test par sous-test.
//
// Avant, tout partait en un seul envoi à la toute fin : une app fermée au 8e
// sous-test perdait cinquante minutes de mesures, et la mise en pause avec
// reprise était impossible puisque rien n'existait côté serveur avant la fin.
//
// L'identité de la passation est un UUID généré ICI au premier sous-test et
// persisté dans le coffre local. Le serveur fait un upsert dessus : l'app peut
// fermer, planter ou perdre le réseau, elle reprendra la MÊME session au lieu
// d'en ouvrir une seconde. Chaque envoi est donc idempotent, et rejouer un
// envoi n'écrit jamais de doublon.
//
// FAIL-SOFT PARTOUT. Aucune méthode ne lève. Un envoi qui échoue est remis dans
// une file en mémoire et retenté au prochain, puis à la clôture : perdre du
// réseau au milieu du test ne doit ni bloquer l'utilisateur, ni lui faire
// perdre ses mesures.
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../features/unlock/data/unlock_service.dart';
import 'auth_local_store.dart';

class ResultsSync {
  ResultsSync._();
  static final ResultsSync instance = ResultsSync._();

  static const _uuid = Uuid();

  String? _sessionId;

  /// Jour d'ouverture de la passation — ce que le serveur écrit dans
  /// `started_on`, et donc ce qui date la péremption de la reprise.
  DateTime? _startedAt;

  /// Origine de la mesure de durée. Distincte de [_startedAt] : lors d'une
  /// reprise sur un appareil neuf, elle recule de la durée déjà acquise pour que
  /// `duration_s` reste continu, alors que le jour d'ouverture, lui, ne bouge
  /// jamais.
  DateTime? _debutMesure;

  /// Sous-tests dont l'envoi a échoué, à rejouer au prochain flush.
  final List<Map<String, dynamic>> _enAttente = [];

  /// Enregistrements oraux en attente d'envoi.
  final List<Map<String, dynamic>> _oralEnAttente = [];

  bool _envoiEnCours = false;
  bool _charge = false;

  /// Durée courante de la passation, envoyée à CHAQUE sous-test et plus
  /// seulement à la clôture.
  ///
  /// C'est ce qui rend la reprise possible depuis un autre appareil sans mentir
  /// sur la durée : le stockage local y est vide, seul le serveur peut dire
  /// depuis combien de temps la passation dure. Sans elle, `duration_s` restait
  /// nul jusqu'à la fin, une reprise ne mesurait que sa propre portion, et la
  /// déclaration de fin pouvait tomber sous le plancher de plausibilité du
  /// worker (300 s) — 400 définitif, parrainage perdu, et un message d'échec
  /// affiché à quelqu'un qui a réellement tout passé.
  ///
  /// L'horloge est ICI et non dans le BLoC : la première version la recevait du
  /// BLoC, qui n'apprend la fin d'un sous-test qu'après le `pop` de sa page —
  /// donc APRÈS que la page ait déjà appelé `flushSubtest`. La durée arrivait
  /// systématiquement un sous-test trop tard, et restait nulle sur le premier
  /// envoi. Vérifié sur la première passation réelle : `duration_s` à `null`
  /// après Cubes.
  int? _dureeCourante() {
    if (_debutMesure == null) return null;
    final s = DateTime.now().difference(_debutMesure!).inSeconds;
    return s > 0 ? s : null;
  }

  /// UUID de la passation, créé au premier appel et conservé jusqu'à `complete`.
  Future<String> sessionId() async {
    if (_sessionId != null) return _sessionId!;
    try {
      final existant = await AuthLocalStore.instance.getTestSessionId();
      if (existant != null && existant.isNotEmpty) {
        _sessionId = existant;
        // Les dates aussi : sans elles, une app redémarrée en cours de bilan
        // renvoie `startedAt = maintenant`, l'upsert déplace `started_on` à
        // aujourd'hui, et la fenêtre de reprise repart de zéro en silence.
        final d = await AuthLocalStore.instance.getTestSessionDates();
        _startedAt ??= d.ouverture;
        _debutMesure ??= d.mesureDepuis;
        return existant;
      }
    } catch (_) {
      // Coffre illisible : on repart d'un identifiant neuf plutôt que d'échouer.
    }
    final neuf = _uuid.v4();
    _sessionId = neuf;
    final maintenant = DateTime.now();
    _startedAt ??= maintenant;
    _debutMesure ??= maintenant;
    try {
      await AuthLocalStore.instance.saveTestSessionId(neuf);
      await AuthLocalStore.instance.saveTestSessionDates(
        ouverture: _startedAt,
        mesureDepuis: _debutMesure,
      );
    } catch (_) {/* l'envoi reste possible sans persistance */}
    return neuf;
  }

  /// Ouvre la passation MAINTENANT, au lancement de la batterie.
  ///
  /// Sans cet appel, l'horloge ne démarrait qu'à la PREMIÈRE invocation de
  /// [sessionId], c'est-à-dire au premier envoi — donc à la FIN du premier
  /// exercice. La durée de ce premier envoi valait alors zéro, et le serveur
  /// recevait `duration_s` nul. Observé tel quel sur la première passation
  /// réelle : Cubes terminé, `duration_s` à `null` en base.
  ///
  /// Idempotent : une passation déjà ouverte (ou adoptée à la reprise) n'est
  /// pas réinitialisée.
  Future<void> demarrer() => sessionId();

  /// Reprend une passation DÉJÀ OUVERTE au lieu d'en créer une nouvelle.
  ///
  /// Appelé par `ResumeService.adopt` quand l'utilisateur choisit de continuer
  /// un bilan interrompu. Sans ça, une reprise sur un autre appareil — ou après
  /// un effacement local — repartirait avec un identifiant neuf : le serveur
  /// ouvrirait une SECONDE passation et la première resterait `in_progress`
  /// pour toujours, ses mesures orphelines.
  ///
  /// [debut] est le jour d'ouverture connu du serveur. On le réinjecte pour que
  /// l'upsert ne réécrive pas `started_on` à la date du jour : sinon reprendre
  /// tous les six jours prolongerait indéfiniment la fenêtre de reprise, et la
  /// date de début finirait par désigner la dernière reprise plutôt que le
  /// début réel.
  ///
  /// La file en attente est CONSERVÉE : ce qu'elle contient appartient au même
  /// bilan, et l'upsert serveur sur (session, sous-test) rend le rattachement
  /// inoffensif.
  Future<void> adopterSession(
    String id, {
    DateTime? jourOuverture,
    DateTime? mesureDepuis,
  }) async {
    if (id.isEmpty) return;
    _sessionId = id;
    _startedAt = jourOuverture ?? _startedAt;
    _debutMesure = mesureDepuis ?? _debutMesure ?? DateTime.now();
    try {
      await AuthLocalStore.instance.saveTestSessionId(id);
      await AuthLocalStore.instance.saveTestSessionDates(
        ouverture: _startedAt,
        mesureDepuis: _debutMesure,
      );
    } catch (_) {/* l'envoi reste possible sans persistance */}
  }

  /// Envoie un sous-test terminé. À appeler dès la dernière réponse validée.
  ///
  /// [payload] vient de `SubtestInstrumentation.toPayload()`.
  Future<void> flushSubtest(Map<String, dynamic> payload) async {
    // Un sous-test ne peut figurer QU'UNE FOIS dans la file. Depuis que les
    // exercices s'envoient aussi en cours de route, un envoi partiel non parti
    // pouvait être rejoint par l'envoi final du même exercice : les deux lignes
    // partaient dans la MÊME requête, et Postgres refuse un upsert qui touche
    // deux fois la même ligne de conflit. Le dernier état gagne, ce qui est
    // exactement la sémantique voulue.
    final code = payload['subtest'];
    if (code is String && code.isNotEmpty) {
      _enAttente.removeWhere((e) => e['subtest'] == code);
    }
    _enAttente.add(payload);
    await _persiste();          // AVANT l'envoi : si l'app meurt ici, rien n'est perdu
    await _envoie(status: 'in_progress');
  }

  /// Enregistre les métadonnées d'un cycle de l'épreuve orale.
  ///
  /// L'audio part vers R2 par son propre chemin ; on ne consigne ici que de quoi
  /// le retrouver et l'interpréter — texte lu, cycle, couche, consentement.
  Future<void> flushOral(Map<String, dynamic> enregistrement) async {
    _oralEnAttente.add(enregistrement);
    await _persiste();
    await _envoie(status: 'in_progress');
  }

  /// Clôt la passation et libère l'identifiant local.
  ///
  /// Rejoue au passage tout ce qui restait en attente.
  /// [subtests] permet d'emporter un dernier lot : les exercices pas encore
  /// instrumentés n'envoient rien en cours de route, leurs scores agrégés
  /// partent donc ici. L'upsert serveur sur (session, sous-test) rend l'envoi
  /// inoffensif même pour un sous-test déjà transmis.
  Future<void> complete({
    required int durationSeconds,
    List<Map<String, dynamic>> subtests = const [],
  }) async {
    _enAttente.addAll(subtests);
    final abouti =
        await _envoie(status: 'completed', durationSeconds: durationSeconds);

    // On n'efface QUE si la clôture a réellement abouti. Effacer inconditionnel-
    // lement perdait les mesures dans deux cas bien réels : un envoi concurrent
    // encore en vol (_envoie sort alors immédiatement), et un échec réseau. Dans
    // les deux, la file survivait mais son identifiant de session disparaissait —
    // elle n'aurait plus jamais pu être rattachée à la bonne passation.
    if (!abouti) return;

    _sessionId = null;
    _startedAt = null;
    _debutMesure = null;
    try {
      await AuthLocalStore.instance.clearTestSessionId();
    } catch (_) {/* sans conséquence : un nouvel UUID sera généré */}
  }

  /// Abandonne la passation courante sans rien envoyer (changement de token,
  /// réinitialisation). L'éventuelle session serveur restera `in_progress`.
  Future<void> reset() async {
    _sessionId = null;
    _startedAt = null;
    _debutMesure = null;
    _enAttente.clear();
    _oralEnAttente.clear();
    try {
      await AuthLocalStore.instance.clearPendingResults();
      await AuthLocalStore.instance.clearTestSessionId();
    } catch (_) {/* rien à faire */}
  }

  /// Relit la file laissée par une exécution précédente et tente de l'envoyer.
  ///
  /// À appeler au DÉMARRAGE de l'app. Sans ça, un exercice terminé juste avant
  /// que le système ne tue l'app en arrière-plan ne repartirait jamais : la file
  /// est persistée, mais rien ne la relirait.
  Future<void> restaureEtRejoue() async {
    if (_charge) return;
    _charge = true;
    try {
      final brut = await AuthLocalStore.instance.getPendingResults();
      if (brut == null || brut.isEmpty) return;
      final d = jsonDecode(brut) as Map<String, dynamic>;
      _enAttente.addAll((d['subtests'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)));
      _oralEnAttente.addAll((d['oral'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      // File illisible (format changé, coffre corrompu) : on repart propre
      // plutôt que de bloquer le démarrage.
      try {
        await AuthLocalStore.instance.clearPendingResults();
      } catch (_) {/* rien à faire */}
      return;
    }
    await _envoie(status: 'in_progress');
  }

  /// Écrit la file dans le coffre chiffré. Silencieux en cas d'échec : perdre la
  /// persistance ne doit pas empêcher l'envoi immédiat de fonctionner.
  Future<void> _persiste() async {
    try {
      if (_enAttente.isEmpty && _oralEnAttente.isEmpty) {
        await AuthLocalStore.instance.clearPendingResults();
        return;
      }
      await AuthLocalStore.instance.savePendingResults(
        jsonEncode({'subtests': _enAttente, 'oral': _oralEnAttente}),
      );
    } catch (_) {/* la file reste au moins en mémoire */}
  }

  /// Rejoue ce qui attend, après qu'un token soit devenu disponible.
  ///
  /// Sans token, `UnlockService._authHeaders()` renvoie null et chaque envoi
  /// échoue en silence. La file survit (correctif de la revue), mais plus rien
  /// ne la relançait : les mesures d'un parcours entier se perdaient à la
  /// fermeture de l'app.
  ///
  /// Appelé à la connexion (`TokenRestorePage`), seul endroit où un token entre
  /// désormais dans l'app — elle n'en crée plus aucun, l'inscription se faisant
  /// exclusivement sur mental-et.com/inscription.
  Future<void> retryPending() async {
    if (_enAttente.isEmpty && _oralEnAttente.isEmpty) return;
    await _envoie(status: 'in_progress');
  }

  /// Rend `true` si l'envoi a réellement abouti — c'est ce verdict qui autorise
  /// [complete] à libérer la session.
  Future<bool> _envoie({
    required String status,
    int? durationSeconds,
  }) async {
    if (_envoiEnCours) return false;   // un envoi concurrent rejouera la file
    if (_enAttente.isEmpty && _oralEnAttente.isEmpty && status != 'completed') {
      return false;
    }
    _envoiEnCours = true;
    // On copie AVANT l'envoi : ce qui part est retiré de la file seulement en
    // cas de succès, pour qu'un échec réseau ne perde rien.
    final sousTests = List<Map<String, dynamic>>.from(_enAttente);
    final oral = List<Map<String, dynamic>>.from(_oralEnAttente);
    try {
      // Résolu AVANT de composer l'appel : c'est `sessionId()` qui relit les
      // dates persistées, et les deux arguments suivants en dépendent. Les
      // laisser en ligne ferait reposer la justesse sur l'ordre d'évaluation
      // des arguments nommés.
      final id = await sessionId();
      final ok = await UnlockService.instance.uploadTestResults(
        clientSessionId: id,
        startedAt: _startedAt,
        subtests: sousTests,
        oral: oral,
        status: status,
        durationSeconds: durationSeconds ?? _dureeCourante(),
      );
      if (ok) {
        _enAttente.removeRange(0, sousTests.length);
        _oralEnAttente.removeRange(0, oral.length);
        await _persiste();
      }
      return ok;
    } catch (_) {
      // La file est conservée telle quelle ; le prochain flush réessaiera.
      return false;
    } finally {
      _envoiEnCours = false;
    }
  }
}
