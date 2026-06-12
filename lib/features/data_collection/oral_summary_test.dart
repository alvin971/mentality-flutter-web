// lib/features/data_collection/oral_summary_test.dart
// Module 2 — Enregistrement du résumé oral.
//
// L'utilisateur résume oralement le texte qu'il vient de lire.
// Sauvegarde deux enregistrements dans mentality_sell :
//   - Layer C : audio du résumé
//   - Layer D : paire NLU (texte original + chemin audio résumé)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../data/reading_texts.dart';
import '../../services/data_collection_service.dart';

class OralSummaryTest extends StatefulWidget {
  final ReadingText originalText;
  final String sessionId;
  final void Function(String textId, String sessionId) onCompleted;

  const OralSummaryTest({
    super.key,
    required this.originalText,
    required this.sessionId,
    required this.onCompleted,
  });

  @override
  State<OralSummaryTest> createState() => _OralSummaryTestState();
}

class _OralSummaryTestState extends State<OralSummaryTest> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;
  Timer? _blinkTimer;
  int _elapsedSeconds = 0;
  bool _isRecording = false;
  bool _blinkVisible = true;
  bool _isSaving = false;
  bool _permissionDenied = false;

  static const int _minDurationSeconds = 20;

  @override
  void dispose() {
    _timer?.cancel();
    _blinkTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Permission ──────────────────────────────────────────────────────────────

  Future<void> _showPermissionDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: AppColors.primary, size: 24.sp),
            SizedBox(width: 8.w),
            Text(context.l10n.oralMicAccessTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.oralSummaryPermissionBody1,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              context.l10n.oralSummaryPermissionBody2,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.oralCancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.mic),
            label: Text(context.l10n.oralStartSummary),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _requestPermissionAndStart();
    }
  }

  Future<void> _requestPermissionAndStart() async {
    bool granted;
    try {
      granted = await _recorder.hasPermission();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;

    if (!granted) {
      _handleRecordingUnavailable(context.l10n.oralMicDeniedOrUnavailable);
      return;
    }

    try {
      await _startRecording();
    } catch (_) {
      if (!mounted) return;
      _handleRecordingUnavailable(context.l10n.oralCannotStartRecording);
    }
  }

  /// Affiche un message d'erreur et débloque l'utilisateur en lui permettant
  /// de passer à l'étape suivante (le micro ne doit jamais bloquer le parcours).
  void _handleRecordingUnavailable(String message) {
    if (!mounted) return;
    setState(() {
      _permissionDenied = true;
      _isRecording = false;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.oralCanSkipToNextStep(message)),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: context.l10n.oralSkip,
          textColor: Colors.white,
          onPressed: () =>
              widget.onCompleted(widget.originalText.id, widget.sessionId),
        ),
      ),
    );
  }

  // ─── Enregistrement ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final encoder = await _resolveSupportedEncoder();
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: 'mentality_summary.webm',
    );
    if (!mounted) return;
    setState(() => _isRecording = true);
    _startTimers();
  }

  /// Choisit un encodeur réellement supporté par le navigateur courant.
  /// opus (webm) : Chrome/Firefox/Edge — aacLc (mp4) : Safari — wav : secours.
  Future<AudioEncoder> _resolveSupportedEncoder() async {
    for (final enc in const [
      AudioEncoder.opus,
      AudioEncoder.aacLc,
      AudioEncoder.wav,
    ]) {
      try {
        if (await _recorder.isEncoderSupported(enc)) return enc;
      } catch (_) {
        // Encodeur non disponible : on essaie le suivant.
      }
    }
    return AudioEncoder.opus;
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isSaving = true);

    try {
      final blobUrl = await _recorder.stop();
      final timestamp = DateTime.now().toIso8601String();

      // Record 1 — Layer C : audio du résumé
      await DataCollectionService.instance.saveAudioRecord({
        'session_id': widget.sessionId,
        'text_id': widget.originalText.id,
        'audio_summary_path': blobUrl ?? '',
        'duration_seconds': _elapsedSeconds,
        'timestamp': timestamp,
        'language': 'fr',
        'layer': 'C',
        'anonymized': true,
      });

      // Record 2 — Layer D : paire NLU (la donnée la plus précieuse)
      // summary_transcription est vide : il sera rempli par l'ASR côté serveur.
      await DataCollectionService.instance.saveNluRecord({
        'session_id': widget.sessionId,
        'text_id': widget.originalText.id,
        'original_text': widget.originalText.body,
        'summary_audio_path': blobUrl ?? '',
        'summary_transcription': '',
        'timestamp': timestamp,
        'layer': 'D',
        'anonymized': true,
      });
    } catch (_) {
      // L'échec de sauvegarde ne doit pas bloquer le parcours.
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isSaving = false;
    });

    widget.onCompleted(widget.originalText.id, widget.sessionId);
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _blinkVisible = !_blinkVisible);
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInstruction(),
        SizedBox(height: 14.h),
        _buildOriginalTextCard(),
        SizedBox(height: 20.h),
        _buildRecordingControls(),
      ],
    );
  }

  Widget _buildInstruction() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: Colors.teal.shade700, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: context.l10n.oralSummaryInstructionLead,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  TextSpan(
                    text: context.l10n.oralSummaryInstructionBody,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalTextCard() {
    return Expanded(
      child: Card(
        elevation: 1,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.article_outlined,
                      size: 16.sp,
                      color: Theme.of(context).colorScheme.outline),
                  SizedBox(width: 6.w),
                  Text(
                    context.l10n.oralReferenceText,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.originalText.body,
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.65,
                      color: Theme.of(context)
                          .colorScheme
                          .outline, // grisé = référence non interactive
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      children: [
        if (_isRecording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: _blinkVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                context.l10n.oralRecordingInProgress,
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _formatTime(_elapsedSeconds),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          if (_elapsedSeconds < _minDurationSeconds)
            Text(
              context.l10n
                  .oralKeepGoingSeconds(_minDurationSeconds - _elapsedSeconds),
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.outline),
            ),
          SizedBox(height: 16.h),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecording && !_isSaving) ...[
              ElevatedButton.icon(
                onPressed: _showPermissionDialog,
                icon: const Icon(Icons.mic),
                label: Text(context.l10n.oralStartSummary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                  textStyle: TextStyle(fontSize: 15.sp),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: (_isRecording &&
                        _elapsedSeconds >= _minDurationSeconds &&
                        !_isSaving)
                    ? _stopRecording
                    : null,
                icon: _isSaving
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.stop_circle),
                label: Text(_isSaving
                    ? context.l10n.oralSaving
                    : context.l10n.oralFinishSummary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                  textStyle: TextStyle(fontSize: 15.sp),
                ),
              ),
            ],
          ],
        ),
        if (_permissionDenied) ...[
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () =>
                widget.onCompleted(widget.originalText.id, widget.sessionId),
            child: Text(
              context.l10n.oralSkipThisStep,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
