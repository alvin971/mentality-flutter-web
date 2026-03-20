// lib/features/data_collection/oral_test_flow.dart
// Orchestrateur : 5 cycles complets Lecture → Pause → Résumé.
//
// Gère :
//   - vérification du consentement audio (SharedPreferences)
//   - mélange aléatoire des 5 textes
//   - machine d'états _FlowStep
//   - barre de progression "Texte X sur 5"
//
// Usage :
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const OralTestFlow()));

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _consentKey = 'consent_audio';

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
    final prefs = await SharedPreferences.getInstance();
    final hasConsent = prefs.getBool(_consentKey) ?? false;
    if (!mounted) return;
    setState(() {
      _step = hasConsent ? _FlowStep.reading : _FlowStep.noConsent;
    });
  }

  Future<void> _grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
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
      setState(() => _step = _FlowStep.completed);
      widget.onAllCompleted?.call();
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
          title: const Text('Collecte audio'),
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
      _FlowStep.checkingConsent => const Center(child: CircularProgressIndicator()),
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
            'Test de Compréhension Orale',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _ConsentSection(
            icon: Icons.mic_none,
            title: 'Ce que nous enregistrons',
            body:
                'Votre voix pendant la lecture de 5 courts textes (environ 1 min chacun) '
                'et votre résumé oral (environ 40 secondes par texte).',
          ),
          SizedBox(height: 12.h),
          _ConsentSection(
            icon: Icons.lock_outline,
            title: 'Anonymisation',
            body:
                'Aucun nom, aucune information personnelle n\'est associé aux '
                'enregistrements. Un identifiant de session aléatoire est utilisé.',
          ),
          SizedBox(height: 12.h),
          _ConsentSection(
            icon: Icons.science_outlined,
            title: 'Utilisation',
            body:
                'Ces enregistrements pourront contribuer à l\'amélioration de la '
                'reconnaissance vocale du français, notamment pour des modèles '
                'comme Whisper ou Speechmatics.',
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: _grantConsent,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('J\'accepte et je commence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              textStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: _declineConsent,
            child: Text(
              'Refuser et revenir en arrière',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Vous pouvez retirer votre consentement à tout moment depuis les '
            'paramètres de l\'application.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
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
              'Texte ${_currentCycle + 1} sur 5',
              style:
                  TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            Text(
              _step == _FlowStep.reading ? 'Lecture' : 'Résumé',
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
            backgroundColor: Colors.grey.shade200,
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
              'Bien !',
              style: TextStyle(
                  fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              'Maintenant, résumez oralement ce texte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 32.h),
            Text(
              'Début dans...',
              style:
                  TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
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
              'Merci !',
              style: TextStyle(
                  fontSize: 26.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text(
              'Vous avez complété les 5 textes.\n'
              'Vos enregistrements contribueront à l\'amélioration\n'
              'de la reconnaissance vocale en français.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade700, height: 1.6),
            ),
            SizedBox(height: 40.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
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
        title: const Text('Quitter ?'),
        content: const Text(
            'Un enregistrement est en cours. Si vous quittez maintenant, '
            'il ne sera pas sauvegardé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quitter'),
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
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
                        fontSize: 13.sp, color: Colors.grey.shade700, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
