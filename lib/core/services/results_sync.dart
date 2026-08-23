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
import 'package:uuid/uuid.dart';

import '../../features/unlock/data/unlock_service.dart';
import 'auth_local_store.dart';

class ResultsSync {
  ResultsSync._();
  static final ResultsSync instance = ResultsSync._();

  static const _uuid = Uuid();

  String? _sessionId;
  DateTime? _startedAt;

  /// Sous-tests dont l'envoi a échoué, à rejouer au prochain flush.
  final List<Map<String, dynamic>> _enAttente = [];

  /// Enregistrements oraux en attente d'envoi.
  final List<Map<String, dynamic>> _oralEnAttente = [];

  bool _envoiEnCours = false;

  /// UUID de la passation, créé au premier appel et conservé jusqu'à `complete`.
  Future<String> sessionId() async {
    if (_sessionId != null) return _sessionId!;
    try {
      final existant = await AuthLocalStore.instance.getTestSessionId();
      if (existant != null && existant.isNotEmpty) {
        _sessionId = existant;
        return existant;
      }
    } catch (_) {
      // Coffre illisible : on repart d'un identifiant neuf plutôt que d'échouer.
    }
    final neuf = _uuid.v4();
    _sessionId = neuf;
    _startedAt ??= DateTime.now();
    try {
      await AuthLocalStore.instance.saveTestSessionId(neuf);
    } catch (_) {/* l'envoi reste possible sans persistance */}
    return neuf;
  }

  /// Envoie un sous-test terminé. À appeler dès la dernière réponse validée.
  ///
  /// [payload] vient de `SubtestInstrumentation.toPayload()`.
  Future<void> flushSubtest(Map<String, dynamic> payload) async {
    _enAttente.add(payload);
    await _envoie(status: 'in_progress');
  }

  /// Enregistre les métadonnées d'un cycle de l'épreuve orale.
  ///
  /// L'audio part vers R2 par son propre chemin ; on ne consigne ici que de quoi
  /// le retrouver et l'interpréter — texte lu, cycle, couche, consentement.
  Future<void> flushOral(Map<String, dynamic> enregistrement) async {
    _oralEnAttente.add(enregistrement);
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
    try {
      await AuthLocalStore.instance.clearTestSessionId();
    } catch (_) {/* sans conséquence : un nouvel UUID sera généré */}
  }

  /// Abandonne la passation courante sans rien envoyer (changement de token,
  /// réinitialisation). L'éventuelle session serveur restera `in_progress`.
  Future<void> reset() async {
    _sessionId = null;
    _startedAt = null;
    _enAttente.clear();
    _oralEnAttente.clear();
    try {
      await AuthLocalStore.instance.clearTestSessionId();
    } catch (_) {/* rien à faire */}
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
      final ok = await UnlockService.instance.uploadTestResults(
        clientSessionId: await sessionId(),
        startedAt: _startedAt,
        subtests: sousTests,
        oral: oral,
        status: status,
        durationSeconds: durationSeconds,
      );
      if (ok) {
        _enAttente.removeRange(0, sousTests.length);
        _oralEnAttente.removeRange(0, oral.length);
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
