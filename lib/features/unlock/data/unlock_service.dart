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
  /// 1=inviter, 2=attente filleuls, 3=instagram, 4=débloqué.
  final int stage;
  final String referralCode;

  /// Nombre de filleuls ayant réellement TERMINÉ leur test complet.
  final int completedReferrals;
  final int requiredReferrals;
  final bool instagramSubmitted;

  /// Le lien filleul→parrain est-il enregistré côté serveur ? `false` tant que
  /// la preuve de complétion du test n'est pas visible (le code de parrainage
  /// local doit alors être CONSERVÉ pour re-tenter). `null` = worker antérieur
  /// au champ (comportement historique : considérer comme enregistré).
  final bool? refereeRecorded;

  const UnlockProgress({
    required this.stage,
    required this.referralCode,
    required this.completedReferrals,
    required this.requiredReferrals,
    required this.instagramSubmitted,
    this.refereeRecorded,
  });

  factory UnlockProgress.fromJson(Map<String, dynamic> j) => UnlockProgress(
        stage: (j['stage'] as num?)?.toInt() ?? 1,
        referralCode: j['referralCode'] as String? ?? '',
        completedReferrals: (j['completedReferrals'] as num?)?.toInt() ?? 0,
        requiredReferrals: (j['requiredReferrals'] as num?)?.toInt() ?? 3,
        instagramSubmitted: j['instagramSubmitted'] as bool? ?? false,
        refereeRecorded: j['refereeRecorded'] as bool?,
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
      final progress = UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
      // N'effacer le code de parrainage local que si le serveur a bien
      // enregistré le lien (refereeRecorded). S'il vaut false, la preuve de
      // complétion n'était pas encore visible côté worker (course /validate ou
      // uploads en retard) : on garde le code et le prochain passage re-tente.
      if (referrer != null && progress.refereeRecorded != false) {
        await AuthLocalStore.instance.clearPendingReferrerCode();
      }
      return progress;
    } catch (_) {
      return null;
    }
  }

  /// État courant (les transitions de palier sont calculées côté serveur).
  Future<UnlockProgress?> getProgress() async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return null;
    // Un code de parrainage attend toujours d'être validé ? Repasser par
    // /progress/init (idempotent) : c'est lui qui porte le referrerCode.
    if (await AuthLocalStore.instance.getPendingReferrerCode() != null) {
      return initProgress();
    }
    try {
      final resp = await http.get(
        Uri.parse('${AppConstants.referralWorkerUrl}/progress'),
        headers: headers,
      );
      if (resp.statusCode == 404) return initProgress();
      if (resp.statusCode != 200) return null;
      return UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Soumet le pseudo Instagram (palier 3) — démarre la « vérification ».
  Future<UnlockProgress?> submitInstagram(String handle) async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return null;
    try {
      final resp = await http.post(
        Uri.parse('${AppConstants.referralWorkerUrl}/instagram'),
        headers: headers,
        body: jsonEncode({'handle': handle}),
      );
      if (resp.statusCode != 200) return null;
      return UnlockProgress.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
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
