// Client HTTP du worker referral (déblocage des résultats par paliers).
//
// Même philosophie que R2UploadService : le client n'a AUCUNE clé Supabase,
// il parle au worker (workers/referral/) authentifié par le token signé.
// Si le worker n'est pas configuré (URL placeholder) ou injoignable, les
// appels renvoient `null` et l'appelant décide (le gate se désactive
// proprement en cas de worker non configuré, mais JAMAIS de déblocage
// par défaut quand le worker est configuré mais en erreur).

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_local_store.dart';

/// État du déblocage renvoyé par le worker (autorité serveur sur `stage`).
class UnlockProgress {
  /// 1=inviter, 2=attente filleuls, 3=délai d'attente serveur, 4=débloqué.
  final int stage;
  final String referralCode;

  /// Nombre de filleuls ayant réellement TERMINÉ leur test complet.
  final int completedReferrals;
  final int requiredReferrals;

  const UnlockProgress({
    required this.stage,
    required this.referralCode,
    required this.completedReferrals,
    required this.requiredReferrals,
  });

  factory UnlockProgress.fromJson(Map<String, dynamic> j) => UnlockProgress(
        stage: (j['stage'] as num?)?.toInt() ?? 1,
        referralCode: j['referralCode'] as String? ?? '',
        completedReferrals: (j['completedReferrals'] as num?)?.toInt() ?? 0,
        requiredReferrals: (j['requiredReferrals'] as num?)?.toInt() ?? 3,
      );

  bool get unlocked => stage >= 4;

  /// Lien d'invitation à partager, lié au token du parrain.
  String get inviteLink => '${AppConstants.inviteBaseUrl}?ref=$referralCode';
}

class UnlockService {
  static final UnlockService instance = UnlockService._();
  UnlockService._();

  /// `true` si une URL de worker réelle est configurée (pas le placeholder).
  bool get isConfigured =>
      !AppConstants.referralWorkerUrl.contains('YOUR_SUBDOMAIN');

  /// Le gate est actif seulement si le flag ET le worker sont configurés.
  bool get gateEnabled => AppConstants.unlockGateEnabled && isConfigured;

  /// Les résultats doivent-ils être verrouillés (floutés) ?
  ///
  /// LE SERVEUR EST L'AUTORITÉ : tant qu'il répond, c'est lui qui tranche. Le
  /// cache local n'est qu'un SECOURS hors-ligne, jamais un court-circuit.
  ///
  /// Consulter le cache en premier (ancien comportement) rendait le serveur
  /// incapable de re-verrouiller : un compte remis à zéro côté serveur restait
  /// débloqué à vie sur l'appareil, puisque le client ne redemandait plus rien.
  Future<bool> isLocked() async {
    if (!gateEnabled) return false;
    try {
      final p = await getProgress();
      if (p != null) return !p.unlocked; // autorité serveur
    } catch (_) {
      // Réseau/serveur indisponible → on se rabat sur le cache ci-dessous.
    }
    // Serveur injoignable : un déblocage DÉJÀ acquis reste honoré (sinon une
    // simple coupure re-flouterait un résultat légitimement gagné) ; sans
    // cache, on reste verrouillé (fail-closed).
    try {
      return !(await AuthLocalStore.instance.getResultsUnlocked());
    } catch (_) {
      return true;
    }
  }

  /// Persiste le déblocage dès qu'une réponse serveur atteint le stage 4.
  UnlockProgress _rememberIfUnlocked(UnlockProgress p) {
    if (p.unlocked) {
      // fire-and-forget : le cache est une optimisation, pas une autorité.
      AuthLocalStore.instance.saveResultsUnlocked().catchError((_) {});
    }
    return p;
  }

  Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthLocalStore.instance.getToken();
    if (token == null || token.isEmpty) return null;
    return {'Content-Type': 'application/json', 'X-Mentality-Token': token};
  }

  /// Initialise (idempotent) le suivi de déblocage à la fin du test. Envoie
  /// aussi le code de parrainage en attente : c'est le moment où ce testeur,
  /// s'il est filleul, valide son parrain (test complet terminé). Le code est
  /// effacé localement en cas de succès.
  Future<UnlockProgress?> initProgress() async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return null;
    try {
      final referrer =
          await AuthLocalStore.instance.getPendingReferrerCode();
      final resp = await http.post(
        Uri.parse('${AppConstants.referralWorkerUrl}/progress/init'),
        headers: headers,
        body: jsonEncode({if (referrer != null) 'referrerCode': referrer}),
      );
      if (resp.statusCode != 200) return null;
      if (referrer != null) {
        await AuthLocalStore.instance.clearPendingReferrerCode();
      }
      return _rememberIfUnlocked(UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  /// Déclare au serveur que le test complet vient d'être TERMINÉ — seul appel
  /// qui crédite le parrain du filleul.
  ///
  /// À n'appeler QUE depuis la fin réelle d'un test, jamais depuis un simple
  /// affichage : ouvrir l'écran des missions ne doit pas valider un parrainage.
  /// Le serveur vérifie la plausibilité de la session avant de créditer.
  Future<UnlockProgress?> declareTestCompleted({
    required int subtestsCompleted,
    required int durationSeconds,
  }) async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return null;
    try {
      final resp = await http.post(
        Uri.parse('${AppConstants.referralWorkerUrl}/complete'),
        headers: headers,
        body: jsonEncode({
          'subtestsCompleted': subtestsCompleted,
          'durationSeconds': durationSeconds,
        }),
      );
      if (resp.statusCode != 200) return null;
      return _rememberIfUnlocked(UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  /// État courant (les transitions de palier sont calculées côté serveur).
  Future<UnlockProgress?> getProgress() async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return null;
    try {
      final resp = await http.get(
        Uri.parse('${AppConstants.referralWorkerUrl}/progress'),
        headers: headers,
      );
      if (resp.statusCode == 404) return initProgress();
      if (resp.statusCode != 200) return null;
      return _rememberIfUnlocked(UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  /// Vérifie qu'un code d'invitation existe (landing /invite, sans token).
  Future<bool> resolveCode(String code) async {
    if (!isConfigured) return false;
    try {
      final resp = await http.get(
        Uri.parse('${AppConstants.referralWorkerUrl}/resolve/$code'),
      );
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['valid'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
