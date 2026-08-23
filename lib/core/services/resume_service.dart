// lib/core/services/resume_service.dart
//
// LA REPRISE : retrouver où en est un bilan interrompu, et repartir à
// l'exercice suivant plutôt que de tout recommencer.
//
// POURQUOI CE FICHIER EXISTE
// Les mesures partaient déjà au fil de l'eau et la progression était déjà
// écrite en local — mais rien ne RELISAIT ni l'une ni l'autre. L'accueil
// affichait bien une bannière « Reprendre » : son bouton menait à l'écran de
// lancement, qui n'a qu'un seul chemin, celui qui repart de zéro. La bannière
// mentait.
//
// DEUX DÉPÔTS, AUCUN N'EST UN SUR-ENSEMBLE DE L'AUTRE
//   • le LOCAL peut en savoir plus : un envoi a échoué hors ligne, la file est
//     persistée mais pas encore partie ;
//   • le SERVEUR peut en savoir plus : appareil réinstallé, token restauré
//     ailleurs — c'est le cas d'usage même de la reprise.
// D'où l'UNION des sous-tests terminés, clé par le CODE stable
// (`block_design`), jamais par le libellé français qui change à la traduction.
// L'union est sûre parce qu'un sous-test terminé l'est définitivement : on ne
// le repasse jamais (items déjà vus → normes invalidées, même règle que
// l'absence de « Recommencer » dans les exercices).
//
// FAIL-SOFT. Pas de réseau → on se replie sur le local. Pas de local → on part
// du serveur. Ni l'un ni l'autre → aucune reprise proposée, et le parcours
// normal reste intact.
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../features/unlock/data/unlock_service.dart';
import '../../services/session_persistence_service.dart';
import '../models/complete_test_session.dart';
import 'auth_local_store.dart';
import 'results_sync.dart';

/// Une passation interrompue, prête à repartir.
class ResumableSession {
  const ResumableSession({
    required this.scoresByCode,
    required this.completedTests,
    required this.nextIndex,
    required this.startTime,
    required this.serverStartedOn,
    required this.clientSessionId,
    required this.knownToServer,
  });

  /// Code WAIS-IV stable → score brut, union du local et du serveur.
  final Map<String, int> scoresByCode;

  /// Libellés de [CompleteTestSession.testSequence] déjà terminés, DANS l'ordre
  /// de la séquence — c'est ce que le modèle de session attend.
  final List<String> completedTests;

  /// Rang, dans la séquence, du premier sous-test qui reste à passer.
  ///
  /// Calculé comme le premier ABSENT, pas comme un compteur : la séquence peut
  /// avoir des trous (un sous-test dont l'envoi a échoué et dont le score local
  /// a été perdu) et un simple `completedTests.length` sauterait alors un
  /// exercice sans que rien ne le signale.
  final int nextIndex;

  /// Début de la passation. Vaut l'instant de la reprise quand seul le serveur
  /// connaît cette passation : il n'en garde que la JOURNÉE (granularité voulue,
  /// anti-corrélation), l'heure fine n'existe nulle part. La durée déclarée à la
  /// clôture ne couvrira alors que la portion reprise — une durée partielle
  /// honnête plutôt qu'une durée reconstituée depuis minuit.
  final DateTime startTime;

  /// Jour d'ouverture tel que le SERVEUR le connaît, réinjecté dans les envois
  /// suivants pour que l'upsert ne déplace pas `started_on` à la date du jour.
  /// Sans ça, reprendre régulièrement repousserait la péremption sans fin et la
  /// date de début finirait par désigner la dernière reprise.
  final DateTime? serverStartedOn;

  /// Identifiant de la passation, à réadopter avant tout nouvel envoi.
  final String? clientSessionId;

  /// Vrai si le serveur connaît cette passation. Faux = reprise purement locale
  /// (hors ligne, ou envois jamais partis).
  final bool knownToServer;

  int get completedCount => completedTests.length;
  int get totalTests => CompleteTestSession.testSequence.length;

  /// Les 12 sous-tests notés sont faits : il ne reste que la clôture.
  bool get isComplete => nextIndex >= totalTests;

  /// Libellé du prochain exercice, `null` s'il n'en reste aucun.
  String? get nextTestName =>
      isComplete ? null : CompleteTestSession.testSequence[nextIndex];

  /// La session reconstruite, telle que le BLoC et l'UI l'attendent.
  CompleteTestSession toSession() {
    var s = CompleteTestSession(
      startTime: startTime,
      currentTestIndex: nextIndex,
      completedTests: List<String>.from(completedTests),
    );
    for (final entree in scoresByCode.entries) {
      s = _applique(s, entree.key, entree.value);
    }
    return s;
  }

  static CompleteTestSession _applique(
      CompleteTestSession s, String code, int score) {
    switch (code) {
      case 'block_design':
        return s.copyWith(cubesScore: score);
      case 'similarities':
        return s.copyWith(similaritiesScore: score);
      case 'digit_span':
        return s.copyWith(digitSpanScore: score);
      case 'matrix_reasoning':
        return s.copyWith(matricesScore: score);
      case 'vocabulary':
        return s.copyWith(vocabularyScore: score);
      case 'arithmetic':
        return s.copyWith(arithmeticScore: score);
      case 'symbol_search':
        return s.copyWith(symbolSearchScore: score);
      case 'visual_puzzles':
        return s.copyWith(visualPuzzlesScore: score);
      case 'information':
        return s.copyWith(informationScore: score);
      case 'coding':
        return s.copyWith(codingScore: score);
      case 'picture_span':
        return s.copyWith(pictureSpanScore: score);
      case 'figure_weights':
        return s.copyWith(figureWeightsScore: score);
      default:
        return s; // code inconnu (schéma futur) : ignoré, jamais fatal
    }
  }
}

class ResumeService {
  ResumeService._();
  static final ResumeService instance = ResumeService._();

  /// Fenêtre de reprise, en jours pleins. MÊME valeur que
  /// `FENETRE_REPRISE_JOURS` dans `workers/referral/index.js` : sans cet
  /// alignement, le repli hors ligne proposerait une reprise que le serveur
  /// vient de refuser — et l'utilisateur verrait la bannière apparaître et
  /// disparaître selon l'état du réseau.
  static const int fenetreJours = 7;

  /// Ce qui peut être repris, ou `null` s'il n'y a rien.
  ///
  /// LECTURE SEULE : n'écrit rien, n'adopte rien. L'accueil l'appelle à chaque
  /// affichage ; muter l'état depuis un simple rendu d'écran serait un piège.
  /// L'adoption a lieu dans [adopt], au moment où l'utilisateur choisit.
  Future<ResumableSession?> lookup() async {
    try {
      final local = _lectureLocale();
      final distant = await UnlockService.instance.fetchResumableSession();
      return fusionne(
        local: local,
        distant: distant,
        identifiantLocal: await _identifiantLocal(),
      );
    } catch (_) {
      // Cet appel a lieu à CHAQUE affichage de l'accueil. Ne pas savoir s'il y
      // a une reprise ne doit jamais empêcher d'afficher l'écran ni de lancer
      // un bilan : on se tait, la bannière ne s'affiche pas.
      return null;
    }
  }

  /// Croise ce que sait le local et ce que sait le serveur.
  ///
  /// Fonction PURE, extraite pour être testable : c'est ici que se joue toute
  /// la justesse de la reprise (quel exercice vient ensuite, quels scores sont
  /// acquis), et cette logique ne doit pas dépendre d'un réseau ni d'un coffre.
  @visibleForTesting
  static ResumableSession? fusionne({
    CompleteTestSession? local,
    RemoteResumableSession? distant,
    String? identifiantLocal,
  }) {
    if (local == null && distant == null) return null;

    // Le serveur fait autorité sur les scores qu'il connaît : le local peut
    // porter un score qu'un envoi n'a jamais réussi à transmettre, mais jamais
    // une valeur PLUS À JOUR pour un sous-test que le serveur a déjà.
    final scores = <String, int>{
      ...?local?.scoresByCode,
      ...?distant?.scoresByCode,
    };
    if (scores.isEmpty) return null;

    final faits = <String>[];
    var suivant = CompleteTestSession.testSequence.length;
    for (var i = 0; i < CompleteTestSession.testSequence.length; i++) {
      final libelle = CompleteTestSession.testSequence[i];
      final code = CompleteTestSession.subtestCodes[libelle];
      if (code != null && scores.containsKey(code)) {
        faits.add(libelle);
      } else if (suivant == CompleteTestSession.testSequence.length) {
        suivant = i; // premier ABSENT, trous compris
      }
    }

    return ResumableSession(
      scoresByCode: scores,
      completedTests: faits,
      nextIndex: suivant,
      // Reculer le départ de la durée déjà acquise, plutôt que de repartir de
      // maintenant : la sémantique de `totalDuration` (fin − début) reste celle
      // d'aujourd'hui, et une reprise sur appareil neuf ne sous-déclare plus le
      // temps passé. Sans local NI durée serveur, il n'y a rien à reconstituer.
      startTime: local?.startTime ??
          (distant?.durationS != null
              ? DateTime.now().subtract(Duration(seconds: distant!.durationS!))
              : DateTime.now()),
      serverStartedOn: distant?.startedOn ?? local?.startTime,
      clientSessionId: distant?.clientSessionId ?? identifiantLocal,
      knownToServer: distant != null,
    );
  }

  /// Session locale, si elle existe ET tient dans la fenêtre de reprise.
  CompleteTestSession? _lectureLocale() {
    final charge = SessionPersistenceService.instance.loadSession();
    if (charge == null) return null;
    if (_joursPleins(charge.session.startTime) > fenetreJours) return null;
    if (charge.session.scoresByCode.isEmpty) return null;
    return charge.session;
  }

  Future<String?> _identifiantLocal() async {
    try {
      return await AuthLocalStore.instance.getTestSessionId();
    } catch (_) {
      return null;
    }
  }

  /// Nombre de jours pleins écoulés, en JOURS CALENDAIRES — la même unité que
  /// le serveur, qui ne connaît que `started_on`.
  static int _joursPleins(DateTime debut) {
    final d = DateTime(debut.year, debut.month, debut.day);
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).difference(d).inDays;
  }

  /// Réadopte la passation avant de la poursuivre.
  ///
  /// C'EST LE POINT CRITIQUE DE LA REPRISE INTER-APPAREILS. Sans lui, un bilan
  /// repris sur un autre téléphone repartirait avec un identifiant neuf : le
  /// serveur ouvrirait une SECONDE passation, et la première resterait
  /// `in_progress` pour toujours, ses mesures orphelines.
  Future<void> adopt(ResumableSession reprise) async {
    final id = reprise.clientSessionId;
    if (id == null || id.isEmpty) return;
    await ResultsSync.instance
        .adopterSession(id, debut: reprise.serverStartedOn);
  }

  /// L'utilisateur renonce à reprendre et repart de zéro.
  ///
  /// Clôt la passation côté serveur AVANT d'effacer l'état local : l'inverse
  /// perdrait l'identifiant sans avoir pu s'en servir, et l'ancienne session
  /// reviendrait se proposer au démarrage suivant.
  Future<void> abandon(ResumableSession reprise) async {
    final id = reprise.clientSessionId;
    if (reprise.knownToServer && id != null && id.isNotEmpty) {
      await UnlockService.instance.abandonSession(id);
    }
    await SessionPersistenceService.instance.clearSession();
    await ResultsSync.instance.reset();
  }
}
