// lib/features/data_collection/oral_test_flow.dart
// Orchestrateur : 5 cycles complets Lecture → Pause → Résumé.
//
// Gère :
//   - vérification du consentement audio (ConsentService, granulaire + versionné)
//   - mélange aléatoire des 5 textes
//   - machine d'états _FlowStep
//   - barre de progression "Texte X sur 5"
//
// Usage :
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const OralTestFlow()));

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/consent/consent_service.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/l10n/locale_notifier.dart';
import '../../core/services/auth_local_store.dart';
import '../../core/services/token_issuer.dart';
import '../../core/theme/app_colors.dart';
import '../../data/reading_texts.dart';
import '../../services/session_manager.dart';
import 'oral_reading_test.dart';
import 'oral_summary_test.dart';

enum _FlowStep {
  checkingConsent,
  noConsent,
  reading,
  pause,
  summary,
  completed,
}

class OralTestFlow extends StatefulWidget {
  /// Appelé après le 5ème cycle. Optionnel.
  final VoidCallback? onAllCompleted;

  const OralTestFlow({super.key, this.onAllCompleted});

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

  /// Case OBLIGATOIRE : enregistrement + analyse pour réaliser le test.
  bool _consentRequired = false;

  /// Case OPTIONNELLE : réutilisation à des fins de recherche/commerciales.
  bool _consentCommercial = false;

  @override
  void initState() {
    super.initState();
    _shuffledTexts = List.from(kReadingTexts)..shuffle();
    _sessionId = SessionManager.instance.currentSessionId;
    _checkConsent();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    super.dispose();
  }

  // ─── Consentement ────────────────────────────────────────────────────────────

  Future<void> _checkConsent() async {
    // Re-sollicite si aucun consentement valide OU si la version du texte a changé.
    final hasConsent = await ConsentService.instance.hasValidConsent();
    if (!mounted) return;
    setState(() {
      _step = hasConsent ? _FlowStep.reading : _FlowStep.noConsent;
    });
  }

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
    Navigator.of(context).pop();
  }

  // ─── Progression des cycles ───────────────────────────────────────────────────

  void _onReadingCompleted(String textId, String sessionId) {
    _pauseTimer?.cancel();
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
    if (_currentCycle < 4) {
      setState(() {
        _currentCycle++;
        _step = _FlowStep.reading;
      });
    } else {
      // Test terminé : soumission → le token provisoire passe à VALIDÉ (à vie).
      setState(() => _step = _FlowStep.completed);
      widget.onAllCompleted?.call();
      _validateTokenAfterTest();
    }
  }

  /// À la soumission du test, fait passer le token PROVISOIRE → VALIDÉ.
  /// Non bloquant : un échec réseau ne doit pas empêcher la fin du test
  /// (la validation pourra être retentée ultérieurement).
  Future<void> _validateTokenAfterTest() async {
    try {
      final token = await AuthLocalStore.instance.getToken();
      if (token == null) return;
      final validated = await TokenIssuer.validate(token);
      await AuthLocalStore.instance.saveToken(validated);
    } catch (_) {
      // silencieux : la complétion du test reste effective.
    }
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
      canPop: _step == _FlowStep.noConsent ||
          _step == _FlowStep.completed ||
          _step == _FlowStep.checkingConsent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            (_step == _FlowStep.reading ||
                _step == _FlowStep.pause ||
                _step == _FlowStep.summary)) {
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.oralFlowTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
          Icon(Icons.record_voice_over, size: 64.sp, color: AppColors.primary),
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
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white70,
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressHeader(),
          SizedBox(height: 16.h),
          Expanded(
            child: _step == _FlowStep.reading
                ? OralReadingTest(
                    key: ValueKey('reading_$_currentCycle'),
                    text: _shuffledTexts[_currentCycle],
                    sessionId: _sessionId,
                    onCompleted: _onReadingCompleted,
                  )
                : OralSummaryTest(
                    key: ValueKey('summary_$_currentCycle'),
                    originalText: _shuffledTexts[_currentCycle],
                    sessionId: _sessionId,
                    onCompleted: _onSummaryCompleted,
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
                  color: AppColors.primary,
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
                size: 56.sp, color: AppColors.primary),
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
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Écran de fin ─────────────────────────────────────────────────────────────

  Widget _buildCompletedScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 72.sp, color: AppColors.success),
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
                foregroundColor: Colors.white,
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

// ─── Widget utilitaire ────────────────────────────────────────────────────────

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
          Icon(icon, size: 20.sp, color: AppColors.primary),
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
