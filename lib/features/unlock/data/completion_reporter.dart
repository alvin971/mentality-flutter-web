// Déclaration de fin de test — DURABLE et REJOUÉE jusqu'à confirmation.
//
// Rappel du modèle : `POST /complete` du worker referral est la SEULE porte
// qui crédite le parrain d'un filleul. Tant que cette requête n'a pas abouti,
// le filleul n'est compté par personne.
//
// Avant, elle partait une seule fois, depuis l'écran de résultats, en
// « tire et oublie » : tout échec (réseau coupé, app fermée avant l'écran,
// refus serveur) perdait le parrainage POUR TOUJOURS et sans un mot. Depuis
// que l'étape orale s'intercale entre la fin de la batterie et les résultats,
// cette fenêtre de perte durait une dizaine de minutes.
//
// Nouvelle règle, tenue par ce service :
//   1. la fin de test est ENREGISTRÉE localement dès le dernier sous-test,
//      avant toute étape facultative ;
//   2. elle est envoyée aussitôt, puis REJOUÉE à chaque occasion (démarrage de
//      l'app, écran des missions, page de résultats) tant que le serveur n'a
//      pas confirmé ;
//   3. un refus explicite du serveur est mémorisé pour être EXPLIQUÉ à
//      l'utilisateur, au lieu de le laisser croire sa mission validée.

import '../../../core/services/auth_local_store.dart';
import 'unlock_service.dart';

class CompletionReporter {
  static final CompletionReporter instance = CompletionReporter._();
  CompletionReporter._();

  /// Évite deux envois concurrents (démarrage de l'app + écran des missions).
  bool _envoiEnCours = false;

  /// Enregistre la fin de test et tente de la déclarer immédiatement.
  ///
  /// À appeler DÈS le dernier sous-test terminé — jamais après une étape
  /// facultative, sous peine de rouvrir la fenêtre de perte.
  Future<CompletionOutcome> declare({
    required int subtestsCompleted,
    required int durationSeconds,
  }) async {
    if (!UnlockService.instance.gateEnabled) {
      return CompletionOutcome.confirmed;
    }
    try {
      await AuthLocalStore.instance.savePendingCompletion(
        subtestsCompleted: subtestsCompleted,
        durationSeconds: durationSeconds,
      );
      await AuthLocalStore.instance.clearCompletionRejected();
    } catch (_) {
      // Le stockage local a échoué : on tente quand même l'envoi direct.
    }
    return _envoie(
      subtestsCompleted: subtestsCompleted,
      durationSeconds: durationSeconds,
    );
  }

  /// Rejoue la déclaration en attente, s'il y en a une pour le passe courant.
  /// Sans objet (et sans coût réseau) quand tout a déjà été confirmé.
  Future<CompletionOutcome?> retryPending() async {
    if (!UnlockService.instance.gateEnabled || _envoiEnCours) return null;
    final attente = await AuthLocalStore.instance.getPendingCompletion();
    if (attente == null) return null;
    return _envoie(
      subtestsCompleted: attente.subtestsCompleted,
      durationSeconds: attente.durationSeconds,
    );
  }

  /// Y a-t-il une fin de test encore non confirmée par le serveur ?
  Future<bool> hasPending() async {
    try {
      return (await AuthLocalStore.instance.getPendingCompletion()) != null;
    } catch (_) {
      return false;
    }
  }

  /// Le serveur a-t-il explicitement refusé la fin de test de ce passe ?
  Future<bool> wasRejected() async {
    try {
      return await AuthLocalStore.instance.getCompletionRejected();
    } catch (_) {
      return false;
    }
  }

  Future<CompletionOutcome> _envoie({
    required int subtestsCompleted,
    required int durationSeconds,
  }) async {
    _envoiEnCours = true;
    try {
      final res = await UnlockService.instance.declareTestCompleted(
        subtestsCompleted: subtestsCompleted,
        durationSeconds: durationSeconds,
      );
      switch (res.outcome) {
        case CompletionOutcome.confirmed:
          await AuthLocalStore.instance.clearPendingCompletion();
          await AuthLocalStore.instance.clearCompletionRejected();
        case CompletionOutcome.rejected:
          // Refus définitif : rejouer la même charge utile ne changerait rien.
          // On cesse de réessayer, mais on garde la trace pour l'expliquer.
          await AuthLocalStore.instance.clearPendingCompletion();
          await AuthLocalStore.instance.saveCompletionRejected();
        case CompletionOutcome.unreachable:
          break; // la déclaration reste en attente, on rejouera
      }
      return res.outcome;
    } catch (_) {
      return CompletionOutcome.unreachable;
    } finally {
      _envoiEnCours = false;
    }
  }
}
