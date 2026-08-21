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

  /// Fin de l'attente telle que le SERVEUR la date. Sert de discriminant
  /// (« un compte à rebours s'applique-t-il ? »), jamais de base de calcul :
  /// le comparer à `DateTime.now()` rendrait le compteur manipulable en
  /// avançant l'horloge du téléphone.
  final DateTime? unlockAt;

  /// Secondes restantes AU MOMENT DE LA RÉPONSE, calculées par le serveur.
  final int secondsRemaining;

  /// Nombre de jours que l'UI doit annoncer.
  final int displayDelayDays;

  /// Délai réel en minutes — n'est affiché que dans la bannière MODE TEST.
  final int delayMinutes;

  /// Le serveur tourne avec un délai d'affichage forcé (recette). L'UI DOIT
  /// alors afficher une bannière visible : voir [debugDelayBannerText].
  final bool debugDelayOverride;

  /// Jour courant de l'événement d'attente : 1..8 pendant l'attente, 9 une
  /// fois débloqué. Calculé PAR LE SERVEUR depuis son ancre — même autorité
  /// que [secondsRemaining], et pour la même raison : un jour déduit de
  /// `DateTime.now()` s'ouvrirait en avançant l'horloge du téléphone.
  ///
  /// `null` dans deux cas qu'il est inutile de distinguer côté UI : l'attente
  /// n'a pas commencé (stage < 3), ou le worker déployé est antérieur au
  /// champ. Dans les deux cas l'événement ne s'affiche pas — dégradation
  /// silencieuse, jamais un jour inventé.
  final int? dayIndex;

  /// Repère MONOTONE (pas une date) du moment où cette réponse est arrivée.
  final Duration anchor;

  const UnlockProgress({
    required this.stage,
    required this.referralCode,
    required this.completedReferrals,
    required this.requiredReferrals,
    this.unlockAt,
    this.secondsRemaining = 0,
    this.displayDelayDays = 0,
    this.delayMinutes = 0,
    this.debugDelayOverride = false,
    this.dayIndex,
    this.anchor = Duration.zero,
  });

  /// [anchor] : valeur du compteur monotone au moment de la réception.
  ///
  /// Chaque nouveau champ a un défaut : face à un worker plus ancien encore
  /// déployé, `unlockAt` est absent, [countdownApplicable] est faux et la carte
  /// s'affiche sans décompte — pas de plantage. Même principe pour
  /// [dayIndex], à ceci près que son défaut est `null` et non un nombre :
  /// inventer un jour 1 ouvrirait l'événement à contretemps.
  factory UnlockProgress.fromJson(
    Map<String, dynamic> j, {
    Duration anchor = Duration.zero,
  }) =>
      UnlockProgress(
        stage: (j['stage'] as num?)?.toInt() ?? 1,
        referralCode: j['referralCode'] as String? ?? '',
        completedReferrals: (j['completedReferrals'] as num?)?.toInt() ?? 0,
        requiredReferrals: (j['requiredReferrals'] as num?)?.toInt() ?? 3,
        unlockAt: DateTime.tryParse(j['unlockAt'] as String? ?? ''),
        secondsRemaining: (j['secondsRemaining'] as num?)?.toInt() ?? 0,
        displayDelayDays: (j['displayDelayDays'] as num?)?.toInt() ?? 0,
        delayMinutes: (j['delayMinutes'] as num?)?.toInt() ?? 0,
        debugDelayOverride: j['debugDelayOverride'] as bool? ?? false,
        // Volontairement SANS valeur de repli : champ absent (vieux worker) et
        // `null` explicite (attente pas commencée) mènent au même refus
        // d'afficher l'événement.
        dayIndex: (j['dayIndex'] as num?)?.toInt(),
        anchor: anchor,
      );

  bool get unlocked => stage >= 4;

  /// Un compte à rebours a-t-il un sens dans cet état ?
  ///
  /// Jamais déduit de `secondsRemaining == 0`, qui vaut aussi bien « l'attente
  /// n'a pas commencé » que « l'attente est finie ».
  bool get countdownApplicable => stage == 3 && unlockAt != null;

  /// Temps restant, dérivé du COMPTEUR MONOTONE — aucune horloge murale.
  ///
  /// C'est ce qui rend le décompte insensible à un changement de date système :
  /// [monotonicNow] vient d'un [Stopwatch], que modifier l'heure du téléphone
  /// ne déplace pas. Ne jamais « simplifier » en `unlockAt.difference(
  /// DateTime.now())` : ce serait rouvrir exactement la faille.
  Duration remainingAt(Duration monotonicNow) {
    if (unlocked) return Duration.zero;
    final left = Duration(seconds: secondsRemaining) - (monotonicNow - anchor);
    return left.isNegative ? Duration.zero : left;
  }

  /// Lien d'invitation à partager, lié au token du parrain.
  String get inviteLink => '${AppConstants.inviteBaseUrl}?ref=$referralCode';
}

/// Issue d'une déclaration de fin de test.
enum CompletionOutcome {
  /// Le serveur a enregistré la complétion (le parrain est crédité).
  confirmed,

  /// Le serveur refuse la session (non plausible) : inutile de réessayer.
  rejected,

  /// Rien n'a pu être établi (hors-ligne, panne, worker non configuré) :
  /// la déclaration reste à rejouer.
  unreachable,
}

class CompletionResult {
  final CompletionOutcome outcome;
  final UnlockProgress? progress;
  const CompletionResult(this.outcome, [this.progress]);
}

class UnlockService {
  static final UnlockService instance = UnlockService._();
  UnlockService._();

  /// Horloge MONOTONE du processus — l'UNIQUE référence temporelle du compte à
  /// rebours. Adossée à une source monotone (`CLOCK_MONOTONIC` sur mobile,
  /// `performance.now()` sur le web), elle est insensible à un changement de
  /// date système.
  ///
  /// Effet de bord connu, et il échoue du bon côté : en veille profonde le
  /// compteur n'avance pas, donc l'UI annonce PLUS de temps restant que la
  /// réalité, jamais moins. Le rafraîchissement au retour en avant-plan
  /// recale en un aller-retour.
  static final Stopwatch _monotonic = Stopwatch()..start();

  Duration get monotonicNow => _monotonic.elapsed;

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
          jsonDecode(resp.body) as Map<String, dynamic>,
          anchor: monotonicNow));
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
  ///
  /// Le résultat DISTINGUE les trois issues, là où l'ancien `null` fourre-tout
  /// les confondait : un refus définitif ne doit pas être rejoué indéfiniment,
  /// et une coupure réseau ne doit pas faire perdre le parrainage.
  Future<CompletionResult> declareTestCompleted({
    required int subtestsCompleted,
    required int durationSeconds,
  }) async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) {
      return const CompletionResult(CompletionOutcome.unreachable);
    }
    try {
      final resp = await http.post(
        Uri.parse('${AppConstants.referralWorkerUrl}/complete'),
        headers: headers,
        body: jsonEncode({
          'subtestsCompleted': subtestsCompleted,
          'durationSeconds': durationSeconds,
        }),
      );
      if (resp.statusCode == 200) {
        return CompletionResult(
          CompletionOutcome.confirmed,
          _rememberIfUnlocked(UnlockProgress.fromJson(
              jsonDecode(resp.body) as Map<String, dynamic>,
              anchor: monotonicNow)),
        );
      }
      // 4xx = le serveur a compris et refuse (session jugée non plausible) :
      // rejouer la même charge utile donnera éternellement le même refus.
      if (resp.statusCode >= 400 && resp.statusCode < 500) {
        return const CompletionResult(CompletionOutcome.rejected);
      }
      return const CompletionResult(CompletionOutcome.unreachable);
    } catch (_) {
      return const CompletionResult(CompletionOutcome.unreachable);
    }
  }

  /// Téléverse les mesures vers `POST /results`, au fil de l'eau.
  ///
  /// Rattachées au token — donc à `account = SHA256(nonce)`, jamais à une
  /// identité. C'est ce qui rend une passation portable d'un appareil à l'autre :
  /// `/login-token` recalcule le même `account` et la retrouve.
  ///
  /// [clientSessionId] est l'UUID généré par l'app et conservé pendant toute la
  /// passation. Le serveur fait un upsert dessus : rejouer un envoi n'écrit
  /// jamais de doublon, et une app fermée en cours de test reprend la MÊME
  /// session au lieu d'en ouvrir une seconde.
  ///
  /// [status] vaut `in_progress` pendant le test et `completed` au dernier envoi.
  /// [oral] porte les métadonnées de l'épreuve orale — jamais d'audio, qui suit
  /// son propre chemin vers R2.
  ///
  /// Les horodatages sont réduits à la JOURNÉE côté serveur (migration 011) :
  /// la précision fine ne sert qu'à la durée, jamais à situer la passation.
  ///
  /// FAIL-SOFT ASSUMÉ : renvoie `false` sans jamais lever. Un échec d'envoi ne
  /// doit ni bloquer l'utilisateur ni lui faire perdre ses résultats, qui
  /// restent de toute façon en local (Hive).
  Future<bool> uploadTestResults({
    required String clientSessionId,
    List<Map<String, dynamic>> subtests = const [],
    List<Map<String, dynamic>> oral = const [],
    String status = 'in_progress',
    DateTime? startedAt,
    int? durationSeconds,
  }) async {
    final headers = await _authHeaders();
    if (!isConfigured || headers == null) return false;
    if (subtests.isEmpty && oral.isEmpty && status != 'completed') return false;
    try {
      final now = DateTime.now().toUtc();
      final resp = await http.post(
        Uri.parse('${AppConstants.referralWorkerUrl}/results'),
        headers: headers,
        body: jsonEncode({
          'clientSessionId': clientSessionId,
          'status': status,
          'startedAt': (startedAt?.toUtc() ?? now).toIso8601String(),
          if (status == 'completed') 'completedAt': now.toIso8601String(),
          if (durationSeconds != null) 'durationS': durationSeconds,
          if (subtests.isNotEmpty) 'subtests': subtests,
          if (oral.isNotEmpty) 'oral': oral,
        }),
      );
      if (resp.statusCode != 200) return false;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['stored'] == true;
    } catch (_) {
      return false;
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
          jsonDecode(resp.body) as Map<String, dynamic>,
          anchor: monotonicNow));
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
