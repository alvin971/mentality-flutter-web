// Le consentement art. 9 vu depuis l'événement — lecture ET écriture.
//
// `EventConsentGate` (dans event_upload_service) ne sait que LIRE, parce que
// l'envoi n'a rien à accorder. L'écran de recueil, lui, doit écrire, et le
// hub doit savoir s'il faut le montrer. D'où ce port, étroit et injectable :
// les tests d'écran n'ont alors ni SharedPreferences à installer, ni texte de
// politique à charger.
//
// UNE SEULE RÈGLE TIENT TOUT LE RESTE : `grant()` renvoie ce qui s'est
// VRAIMENT passé. Une écriture en échec doit se dire `false`, jamais se taire.
// Un écran qui enchaînerait sur les questions de santé en croyant l'accord
// enregistré collecterait des réponses que plus rien n'autorise à envoyer —
// et l'utilisateur, lui, croirait avoir accepté.

import '../../../../../core/consent/consent_service.dart';
import '../../data/event_upload_service.dart';

abstract interface class EventConsent {
  /// Un consentement art. 9 explicite, sur le texte courant, existe-t-il ?
  Future<bool> isGranted();

  /// Accorde ([granted] vrai) ou retire la finalité art. 9.
  ///
  /// Renvoie `true` si le stockage confirme l'écriture. Fail-closed : toute
  /// erreur vaut `false`.
  Future<bool> setGranted(bool granted);
}

class AppEventConsent implements EventConsent {
  const AppEventConsent();

  @override
  Future<bool> isGranted() async {
    try {
      return await ConsentService.instance.hasEventDataConsent();
    } catch (_) {
      // Un stockage illisible ne vaut pas un accord.
      return false;
    }
  }

  @override
  Future<bool> setGranted(bool granted) async {
    try {
      await ConsentService.instance.setEventHealthData(granted);
      // On relit plutôt que de faire confiance à l'appel : c'est la seule
      // vérification qui distingue « écrit » de « cru écrit ».
      final effectif = await ConsentService.instance.hasEventDataConsent();
      if (effectif != granted) return false;
    } catch (_) {
      return false;
    }

    // LIBÉRER CE QUI ATTENDAIT. Des réponses ont pu être mises en file avant
    // l'accord (module joué, envoi refusé faute de consentement) : sans ce
    // rejeu, elles patienteraient jusqu'au prochain démarrage de l'app alors
    // que la seule chose qui les bloquait vient d'être levée. Rien n'est
    // attendu ici — l'envoi est durable, il n'a pas à retarder l'écran.
    if (granted) {
      EventUploadService.instance.retryPending().catchError(
            (_) => const <String, EventUploadOutcome>{},
          );
    }
    return true;
  }
}
