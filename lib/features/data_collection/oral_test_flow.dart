// lib/features/data_collection/oral_test_flow.dart
// Orchestrateur : 5 cycles complets Lecture → Pause → Résumé, puis — pour un
// passe Gratuit — l'ATTENTE DE VÉRIFICATION de l'enregistrement par le serveur.
//
// Gère :
//   - le GARDE DE PLAN : un passe Payant n'est jamais enregistré (sortie
//     immédiate), quelle que soit la porte d'entrée — orchestrateur de fin de
//     bilan, écran d'accueil des épreuves, ou route directe /test/oral
//   - vérification du consentement audio (ConsentService, granulaire + versionné)
//   - mélange aléatoire des 5 textes
//   - machine d'états _FlowStep
//   - barre de progression "Texte X sur 5"
//   - la vérification côté serveur (POST /validate du tokeniseur) : en cours →
//     on réessaie avec un délai croissant ; refusée → on propose de
//     réenregistrer ; vérifiée → l'étape se referme avec `true`.
//
// Usage :
//   final verifie = await Navigator.push<bool>(
//       context, MaterialPageRoute(builder: (_) => const OralTestFlow()));
//   `true` si le serveur a vérifié l'enregistrement, `false`/`null` sinon
//   (refus, délai dépassé, réseau, retour arrière, passe sans plan).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/consent/consent_service.dart';
import '../../core/services/results_sync.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/l10n/locale_notifier.dart';
import '../../core/services/auth_local_store.dart';
import '../../core/services/token_claims_reader.dart';
import '../../core/services/token_issuer.dart';
import '../../core/services/token_plan.dart';
import '../../core/theme/app_colors.dart';
import '../../data/reading_corpus_service.dart';
import '../../data/reading_texts.dart';
import '../../services/session_manager.dart';
import '../../services/tokeniser_service.dart';
import 'oral_reading_test.dart';
import 'oral_summary_test.dart';
import '../../core/theme/kepler_colors.dart';

enum _FlowStep {
  checkingConsent,
  noConsent,
  reading,
  pause,
  summary,

  /// Passe Gratuit, après le 5e cycle : le serveur vérifie l'enregistrement.
  verifying,

  /// Le serveur a REFUSÉ l'enregistrement (absent, vide, sans rapport).
  verificationFailed,

  /// Plusieurs erreurs réseau consécutives : on ne sait pas.
  verificationUnreachable,

  /// Le serveur répond toujours « en cours » après le budget d'attente.
  verificationTimeout,

  /// Passe sans plan lisible (`sv: 2`) : écran de fin historique.
  completed,
}

class OralTestFlow extends StatefulWidget {
  /// Appelé après le 5ème cycle. Optionnel.
  final VoidCallback? onAllCompleted;

  const OralTestFlow({super.key, this.onAllCompleted});

  /// Budget total d'attente quand le serveur répond « en cours » : au-delà,
  /// on cesse de réessayer seul et l'on rend la main.
  static const Duration budgetVerification = Duration(seconds: 90);

  /// Délai avant la tentative n° [tentative] (la première est immédiate) :
  /// 2 s, 4 s, puis 8 s à chaque fois — soit ~86 s d'attente cumulée avant
  /// d'atteindre [budgetVerification].
  @visibleForTesting
  static Duration delaiAvantTentative(int tentative) => switch (tentative) {
        <= 1 => const Duration(seconds: 2),
        2 => const Duration(seconds: 4),
        _ => const Duration(seconds: 8),
      };

  /// TESTS UNIQUEMENT : remplace le délai réel entre deux tentatives (le
  /// budget, lui, est toujours décompté avec le délai nominal). Avancer
  /// l'horloge simulée de plusieurs secondes réveillerait aussi les
  /// minuteries de l'orchestrateur de bilan, qui lanceraient de vraies pages
  /// de sous-test par-dessus cette étape.
  @visibleForTesting
  static Duration? debugDelaiDeReprise;

  /// TESTS UNIQUEMENT : saute les 5 cycles d'enregistrement (micro, plugin
  /// `record`, R2) et enchaîne directement sur ce qui suit — la vérification
  /// pour un passe Gratuit, l'écran de fin sinon. Le banc d'essai n'a pas de
  /// micro ; ce qu'il vérifie, c'est ce que l'app fait DU VERDICT du serveur.
  @visibleForTesting
  static bool debugSauterLesEnregistrements = false;

  @override
  State<OralTestFlow> createState() => _OralTestFlowState();
}

class _OralTestFlowState extends State<OralTestFlow> {
  _FlowStep _step = _FlowStep.checkingConsent;
  int _currentCycle = 0; // 0 à 4
  late List<ReadingText> _shuffledTexts;
  late String _sessionId;
  int _pauseCountdown = 5;
  Timer? _pauseTimer;

  /// Plan porté par le passe, lu une fois à l'ouverture. `unknown` = repli
  /// historique (`sv: 2`) : consentement in-app, étape sautable, pas de
  /// vérification bloquante.
  TokenPlan _plan = TokenPlan.unknown;

  /// Case OBLIGATOIRE : enregistrement + analyse pour réaliser le test.
  bool _consentRequired = false;

  /// Case OPTIONNELLE : réutilisation à des fins de recherche/commerciales.
  bool _consentCommercial = false;

  // ─── Vérification (passe Gratuit) ──────────────────────────────────────────

  Timer? _retryTimer;

  /// Incrémenté à chaque (re)démarrage de vérification : une réponse arrivée
  /// après un « Réenregistrer » ou un nouveau « Réessayer » est ignorée.
  int _verifGeneration = 0;

  /// Tentatives déjà faites dans la vérification courante.
  int _tentatives = 0;

  /// Erreurs réseau d'affilée ; à [_echecsReseauMax], on rend la main.
  int _echecsReseauConsecutifs = 0;
  static const int _echecsReseauMax = 3;

  /// Attente cumulée (délais nominaux) dans la vérification courante.
  Duration _attenteCumulee = Duration.zero;

  /// Vrai pendant un enregistrement : sortir demande confirmation.
  bool get _enregistrementEnCours =>
      _step == _FlowStep.reading ||
      _step == _FlowStep.pause ||
      _step == _FlowStep.summary;

  @override
  void initState() {
    super.initState();
    _sessionId = SessionManager.instance.currentSessionId;
    _initializeFlow();
  }

  /// Aligne le consentement sur le passe, puis charge les 5 textes de la
  /// session (corpus complet, anti-répétition).
  ///
  /// LE GARDE VIT ICI, pas seulement chez l'appelant. L'épreuve a trois portes
  /// d'entrée — l'orchestrateur de fin de bilan, l'écran d'accueil des
  /// épreuves et la route `/test/oral` — et un garde posé sur l'une d'elles
  /// laisse les deux autres ouvertes. Un passe Payant sort immédiatement :
  /// il a payé pour que rien ne soit enregistré.
  Future<void> _initializeFlow() async {
    final plan = await TokenClaimsReader.currentPlan();
    if (!mounted) return;
    if (plan.plan == TokenPlan.paid) {
      _quitterLEtape();
      return;
    }
    _plan = plan.plan;

    // `free` réécrit le consentement local depuis le token (aucun écran :
    // il a été recueilli sur le site) ; `unknown` est un no-op, sauf s'il
    // neutralise un consentement dont le passe porteur a disparu.
    await ConsentService.instance
        .syncFromToken(plan, locale: localeNotifier.contentTag);

    final results = await Future.wait([
      ReadingCorpusService.instance.pickSessionTexts(count: 5),
      ConsentService.instance.hasValidConsent(),
    ]);
    if (!mounted) return;
    final textes = results[0] as List<ReadingText>;
    final consenti = results[1] as bool;

    if (consenti && OralTestFlow.debugSauterLesEnregistrements) {
      _shuffledTexts = textes;
      _terminerLesCycles();
      return;
    }
    setState(() {
      _shuffledTexts = textes;
      _step = consenti ? _FlowStep.reading : _FlowStep.noConsent;
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  // ─── Consentement ────────────────────────────────────────────────────────────

  /// N'est appelable que lorsque la case obligatoire est cochée.
  /// Enregistre une preuve de consentement granulaire, horodatée et versionnée.
  Future<void> _grantConsent() async {
    if (!_consentRequired) return;
    await ConsentService.instance.grant(
      sessionId: _sessionId,
      locale: localeNotifier.contentTag,
      recordingAndAnalysis: true,
      commercialReuse: _consentCommercial,
    );
    if (!mounted) return;
    setState(() => _step = _FlowStep.reading);
  }

  void _declineConsent() {
    _quitterLEtape();
  }

  /// Referme l'étape orale — depuis n'importe laquelle de ses trois portes —
  /// en rendant [verifie] à l'appelant (`true` = enregistrement vérifié par
  /// le serveur).
  ///
  /// LE PIÈGE : `Navigator.pop()` seul ne marchait que si l'on était ARRIVÉ
  /// d'ailleurs. Sur la route go_router de premier niveau `/test/oral`
  /// (app_router.dart), l'étape orale est la seule page de la pile : il n'y a
  /// rien à dépiler, le pop est un no-op silencieux, et l'écran reste figé sur
  /// « vérification » — un passe Payant se retrouvait bloqué là, et un refus
  /// de consentement ne refusait rien du tout.
  void _quitterLEtape({bool? verifie}) {
    final navigateur = Navigator.of(context);
    if (navigateur.canPop()) {
      navigateur.pop(verifie);
      return;
    }
    // Rien à dépiler : on repart de l'accueil, qui est toujours une
    // destination valable. `maybeOf` parce qu'un banc d'essai peut monter
    // cette page sans routeur du tout.
    GoRouter.maybeOf(context)?.go(AppConstants.routeHome);
  }

  // ─── Progression des cycles ───────────────────────────────────────────────────

  void _onReadingCompleted(String textId, String sessionId) {
    _pauseTimer?.cancel();
    _consigneOral(kind: 'reading', textId: textId, r2SessionId: sessionId);
    setState(() {
      _step = _FlowStep.pause;
      _pauseCountdown = 5;
    });
    _startPause();
  }

  void _startPause() {
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _pauseCountdown--);
      if (_pauseCountdown <= 0) {
        t.cancel();
        if (mounted) setState(() => _step = _FlowStep.summary);
      }
    });
  }

  void _onSummaryCompleted(String textId, String sessionId) {
    _pauseTimer?.cancel();
    _consigneOral(kind: 'summary', textId: textId, r2SessionId: sessionId);
    if (_currentCycle < 4) {
      setState(() {
        _currentCycle++;
        _step = _FlowStep.reading;
      });
    } else {
      _terminerLesCycles();
    }
  }

  /// Les 5 cycles sont faits. Ce qui suit dépend du passe :
  ///
  ///   · Gratuit : l'enregistrement est la CONTREPARTIE du bilan, et les
  ///     résultats ne s'affichent qu'une fois qu'il est vérifié (décision
  ///     fondateur, 2026-09-03). On attend donc le verdict du serveur ici.
  ///   · sans plan (`sv: 2`) : comportement historique — écran de fin, et la
  ///     complétion est enregistrée côté serveur en tir-et-oublie.
  void _terminerLesCycles() {
    widget.onAllCompleted?.call();
    if (_plan == TokenPlan.free) {
      _demarrerVerification();
      return;
    }
    setState(() => _step = _FlowStep.completed);
    _validateTokenAfterTest();
  }

  /// Consigne en base ce qui a été lu, et sous quelle couche R2.
  ///
  /// Rien de sonore ne part ici : l'audio suit son propre chemin vers R2. On
  /// n'enregistre que de quoi retrouver et interpréter l'enregistrement — quel
  /// texte du corpus, quel cycle, quel consentement. Cette information
  /// n'existait nulle part jusqu'ici : on avait des fichiers audio sans savoir
  /// ce qu'ils contenaient.
  ///
  /// `layer` reprend la règle du worker r2-upload : `reusable/` quand la
  /// personne a consenti à la cession commerciale, `internal/` sinon. La
  /// source est le consentement PERSISTÉ, jamais les cases de cet écran :
  /// quand le consentement vient du token, ces cases n'ont jamais été
  /// affichées et resteraient à `false` — la base aurait dit `internal` là où
  /// R2 a réellement écrit sous `reusable/`.
  ///
  /// Tir-et-oublie : un échec ne doit jamais interrompre l'épreuve.
  void _consigneOral({
    required String kind,
    required String textId,
    required String r2SessionId,
  }) {
    final cession = ConsentService.instance.current?.commercialReuse ?? false;
    unawaited(ResultsSync.instance.flushOral(<String, dynamic>{
      'cycle': _currentCycle,
      'kind': kind,
      'textId': textId,
      'r2SessionId': r2SessionId,
      'layer': cession ? 'reusable' : 'internal',
      'commercialReuse': cession,
      'uploadOk': true,
    }));
  }

  /// Passe SANS plan : enregistre côté serveur que le token a complété le
  /// test (le token local ne change pas — rien à re-sauvegarder). Non
  /// bloquant : un échec réseau ne doit pas empêcher la fin du test (la
  /// complétion pourra être retentée ultérieurement).
  Future<void> _validateTokenAfterTest() async {
    try {
      final token = await AuthLocalStore.instance.getToken();
      if (token == null) return;
      await TokenIssuer.markCompleted(token);
    } catch (_) {
      // silencieux : la complétion du test reste effective.
    }
  }

  // ─── Vérification de l'enregistrement (passe Gratuit) ────────────────────────

  /// (Re)part de zéro : première tentative immédiate, puis délais croissants
  /// tant que le serveur répond « en cours ».
  void _demarrerVerification() {
    _retryTimer?.cancel();
    _verifGeneration++;
    _tentatives = 0;
    _echecsReseauConsecutifs = 0;
    _attenteCumulee = Duration.zero;
    setState(() => _step = _FlowStep.verifying);
    _tenterVerification();
  }

  Future<void> _tenterVerification() async {
    final generation = _verifGeneration;
    _tentatives++;

    TokenValidationResult resultat;
    try {
      final token = await AuthLocalStore.instance.getToken();
      resultat = token == null
          ? const TokenValidationResult.failed(message: 'aucun token')
          : await TokenIssuer.verifyCompletion(token);
    } catch (e) {
      resultat = TokenValidationResult.network('$e');
    }
    if (!mounted || generation != _verifGeneration) return;

    switch (resultat.status) {
      case TokenValidationStatus.ok:
      // Sans tokeniseur, rien à vérifier : `verifyCompletion` ne renvoie
      // pas ce statut, on le range avec « vérifié » par prudence.
      case TokenValidationStatus.unconfigured:
        _quitterLEtape(verifie: true);
      case TokenValidationStatus.failed:
        setState(() => _step = _FlowStep.verificationFailed);
      case TokenValidationStatus.pending:
        _echecsReseauConsecutifs = 0;
        _programmerNouvelleTentative();
      case TokenValidationStatus.network:
        _echecsReseauConsecutifs++;
        if (_echecsReseauConsecutifs >= _echecsReseauMax) {
          setState(() => _step = _FlowStep.verificationUnreachable);
          return;
        }
        _programmerNouvelleTentative();
    }
  }

  /// Arme la prochaine tentative, ou rend la main si le budget est épuisé.
  void _programmerNouvelleTentative() {
    final nominal = OralTestFlow.delaiAvantTentative(_tentatives);
    if (_attenteCumulee + nominal > OralTestFlow.budgetVerification) {
      setState(() => _step = _FlowStep.verificationTimeout);
      return;
    }
    _attenteCumulee += nominal;
    final generation = _verifGeneration;
    _retryTimer = Timer(OralTestFlow.debugDelaiDeReprise ?? nominal, () {
      if (mounted && generation == _verifGeneration) _tenterVerification();
    });
  }

  /// « Réenregistrer » : on repart au cycle 1 avec de NOUVEAUX textes (le
  /// corpus est anti-répétition) ; les anciens enregistrements restent où ils
  /// sont, le serveur comptera ce qui arrive en plus.
  Future<void> _reenregistrer() async {
    _retryTimer?.cancel();
    _verifGeneration++;
    setState(() {
      _step = _FlowStep.checkingConsent;
      _currentCycle = 0;
    });
    final textes = await ReadingCorpusService.instance.pickSessionTexts(count: 5);
    if (!mounted) return;
    setState(() {
      _shuffledTexts = textes;
      _step = _FlowStep.reading;
    });
  }

  // ─── Valeur de progression (0.0 → 1.0) ───────────────────────────────────────

  double get _progressValue {
    final cycleProgress = _step == _FlowStep.summary || _step == _FlowStep.pause
        ? _currentCycle + 0.5
        : _currentCycle.toDouble();
    return cycleProgress / 5.0;
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Pendant la vérification, le retour arrière est permis : il rend
      // `null` à l'appelant, qui saura que rien n'est vérifié.
      canPop: !_enregistrementEnCours,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _enregistrementEnCours) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.oralFlowTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: KeplerColors.of(context).onAccentFill,
          elevation: 0,
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      _FlowStep.checkingConsent =>
        const Center(child: CircularProgressIndicator()),
      _FlowStep.noConsent => _buildConsentScreen(),
      _FlowStep.reading => _buildActiveStep(),
      _FlowStep.pause => _buildPauseScreen(),
      _FlowStep.summary => _buildActiveStep(),
      _FlowStep.verifying => _buildVerifyingScreen(),
      _FlowStep.verificationFailed => _buildVerificationFailedScreen(),
      _FlowStep.verificationUnreachable =>
        _buildVerificationUnreachableScreen(),
      _FlowStep.verificationTimeout => _buildVerificationTimeoutScreen(),
      _FlowStep.completed => _buildCompletedScreen(),
    };
  }

  // ─── Écran de consentement ────────────────────────────────────────────────────

  Widget _buildConsentScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          Icon(Icons.record_voice_over, size: 64.sp, color: KeplerColors.of(context).primary),
          SizedBox(height: 24.h),
          Text(
            context.l10n.oralConsentTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _ConsentSection(
            icon: Icons.mic_none,
            title: context.l10n.oralConsentRecordTitle,
            body: context.l10n.oralConsentRecordBody,
          ),
          SizedBox(height: 12.h),
          _ConsentSection(
            icon: Icons.lock_outline,
            title: context.l10n.oralConsentAnonTitle,
            body: context.l10n.oralConsentAnonBody,
          ),
          SizedBox(height: 12.h),
          _ConsentSection(
            icon: Icons.science_outlined,
            title: context.l10n.oralConsentUsageTitle,
            body: context.l10n.oralConsentUsageBody,
          ),
          SizedBox(height: 24.h),
          // Case OBLIGATOIRE — sans elle, pas de test (action positive requise).
          CheckboxListTile(
            value: _consentRequired,
            onChanged: (v) => setState(() => _consentRequired = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppColors.primary,
            title: Text(
              context.l10n.oralConsentRequiredCheckbox,
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          // Case OPTIONNELLE — réutilisation recherche/commerciale séparée.
          CheckboxListTile(
            value: _consentCommercial,
            onChanged: (v) => setState(() => _consentCommercial = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppColors.primary,
            title: Text(
              context.l10n.oralConsentCommercialCheckbox,
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            // Désactivé tant que la case obligatoire n'est pas cochée.
            onPressed: _consentRequired ? _grantConsent : null,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.l10n.oralAcceptAndStart),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: KeplerColors.of(context).onAccentFill,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.35),
              disabledForegroundColor: KeplerColors.of(context).textTertiary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              textStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
          if (!_consentRequired) ...[
            SizedBox(height: 8.h),
            Text(
              context.l10n.oralConsentRequiredHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(context).colorScheme.error,
                  fontStyle: FontStyle.italic),
            ),
          ],
          SizedBox(height: 12.h),
          TextButton(
            onPressed: _declineConsent,
            child: Text(
              context.l10n.oralDeclineAndGoBack,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            context.l10n.oralWithdrawConsentNote,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).colorScheme.outline,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ─── Étape active (lecture ou résumé) ─────────────────────────────────────────

  Widget _buildActiveStep() {
    // Passe Gratuit : pas de « passer » — l'enregistrement conditionne les
    // résultats, un saut ici ne ferait que reporter l'échec à la vérification.
    final peutSauter = _plan != TokenPlan.free;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressHeader(),
          SizedBox(height: 10.h),
          Expanded(
            child: _step == _FlowStep.reading
                ? OralReadingTest(
                    key: ValueKey('reading_$_currentCycle'),
                    text: _shuffledTexts[_currentCycle],
                    sessionId: _sessionId,
                    onCompleted: _onReadingCompleted,
                    peutSauter: peutSauter,
                  )
                : OralSummaryTest(
                    key: ValueKey('summary_$_currentCycle'),
                    originalText: _shuffledTexts[_currentCycle],
                    sessionId: _sessionId,
                    onCompleted: _onSummaryCompleted,
                    peutSauter: peutSauter,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.oralTextProgress(_currentCycle + 1),
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Text(
              _step == _FlowStep.reading
                  ? context.l10n.oralStepReading
                  : context.l10n.oralStepSummary,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: KeplerColors.of(context).primary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 8.h,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ─── Pause entre lecture et résumé ───────────────────────────────────────────

  Widget _buildPauseScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded,
                size: 56.sp, color: KeplerColors.of(context).primary),
            SizedBox(height: 24.h),
            Text(
              context.l10n.oralPauseWellDone,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              context.l10n.oralPauseNowSummarize,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 32.h),
            Text(
              context.l10n.oralPauseStartingIn,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.outline),
            ),
            SizedBox(height: 8.h),
            Text(
              '$_pauseCountdown',
              style: TextStyle(
                fontSize: 64.sp,
                fontWeight: FontWeight.bold,
                color: KeplerColors.of(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Vérification (passe Gratuit) ────────────────────────────────────────────

  Widget _buildVerifyingScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: CircularProgressIndicator(
                  color: KeplerColors.of(context).primary),
            ),
            SizedBox(height: 28.h),
            Text(
              context.l10n.oralVerifTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              context.l10n.oralVerifBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationFailedScreen() {
    return _VerificationProblem(
      icon: Icons.error_outline_rounded,
      iconColor: KeplerColors.of(context).error,
      title: context.l10n.oralVerifFailedTitle,
      body: context.l10n.oralVerifFailedBody,
      actions: [
        ElevatedButton.icon(
          onPressed: _reenregistrer,
          icon: const Icon(Icons.mic),
          label: Text(context.l10n.oralVerifReRecord),
          style: _boutonPrincipal(),
        ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: _demarrerVerification,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.oralVerifRetryCheck),
        ),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: () => _quitterLEtape(verifie: false),
          child: Text(context.l10n.oralVerifLeave),
        ),
      ],
    );
  }

  Widget _buildVerificationUnreachableScreen() {
    return _VerificationProblem(
      icon: Icons.wifi_off_rounded,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      title: context.l10n.oralVerifUnreachableTitle,
      body: context.l10n.oralVerifUnreachableBody,
      actions: [
        ElevatedButton.icon(
          onPressed: _demarrerVerification,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.oralVerifRetry),
          style: _boutonPrincipal(),
        ),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: () => _quitterLEtape(verifie: false),
          child: Text(context.l10n.oralVerifLeave),
        ),
      ],
    );
  }

  Widget _buildVerificationTimeoutScreen() {
    return _VerificationProblem(
      icon: Icons.hourglass_bottom_rounded,
      iconColor: KeplerColors.of(context).primary,
      title: context.l10n.oralVerifTimeoutTitle,
      body: context.l10n.oralVerifTimeoutBody,
      actions: [
        ElevatedButton.icon(
          onPressed: _demarrerVerification,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.oralVerifRetryCheck),
          style: _boutonPrincipal(),
        ),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: () => _quitterLEtape(verifie: false),
          child: Text(context.l10n.oralVerifLeave),
        ),
      ],
    );
  }

  ButtonStyle _boutonPrincipal() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: KeplerColors.of(context).onAccentFill,
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
        textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
      );

  // ─── Écran de fin (passe sans plan) ─────────────────────────────────────────

  Widget _buildCompletedScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 72.sp, color: KeplerColors.of(context).success),
            SizedBox(height: 24.h),
            Text(
              context.l10n.oralCompletedThanks,
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text(
              context.l10n.oralCompletedBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6),
            ),
            SizedBox(height: 40.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_outlined),
              label: Text(context.l10n.oralBackToHome),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: KeplerColors.of(context).onAccentFill,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                textStyle: TextStyle(fontSize: 15.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialog de sortie pendant un enregistrement ───────────────────────────────

  Future<void> _showExitConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.oralExitDialogTitle),
        content: Text(context.l10n.oralExitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.oralContinue),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.oralQuit),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

/// Écran de verdict de vérification (refus, réseau, délai) : une icône, un
/// titre, une explication, et les actions possibles.
class _VerificationProblem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> actions;

  const _VerificationProblem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          Icon(icon, size: 64.sp, color: iconColor),
          SizedBox(height: 24.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5),
          ),
          SizedBox(height: 32.h),
          ...actions,
        ],
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ConsentSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: KeplerColors.of(context).primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(body,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
