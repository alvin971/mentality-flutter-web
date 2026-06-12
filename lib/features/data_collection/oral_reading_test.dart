// lib/features/data_collection/oral_reading_test.dart
// Module 1 — Enregistrement de la lecture à voix haute.
//
// L'utilisateur lit un texte affiché à l'écran pendant que sa voix est enregistrée.
// Sauvegarde un enregistrement Layer C dans mentality_sell.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import '../../core/l10n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../data/reading_texts.dart';
import '../../services/data_collection_service.dart';

class OralReadingTest extends StatefulWidget {
  final ReadingText text;
  final String sessionId;
  final void Function(String textId, String sessionId) onCompleted;

  const OralReadingTest({
    super.key,
    required this.text,
    required this.sessionId,
    required this.onCompleted,
  });

  @override
  State<OralReadingTest> createState() => _OralReadingTestState();
}

class _OralReadingTestState extends State<OralReadingTest> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;
  Timer? _blinkTimer;
  int _elapsedSeconds = 0;
  bool _isRecording = false;
  bool _blinkVisible = true;
  bool _isSaving = false;
  bool _permissionDenied = false;

  static const int _minDurationSeconds = 10;

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
              context.l10n.oralReadingPermissionBody1,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              context.l10n.oralReadingPermissionBody2,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),
            Text(
              context.l10n.oralBrowserWillAskMic,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontStyle: FontStyle.italic,
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
            label: Text(context.l10n.oralAllowMicrophone),
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

    setState(() => _permissionDenied = false);

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
          onPressed: () => widget.onCompleted(widget.text.id, widget.sessionId),
        ),
      ),
    );
  }

  // ─── Enregistrement ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    // Sur Flutter Web, le paramètre path est symbolique.
    // recorder.stop() retourne un blob URL (blob:https://...).
    final encoder = await _resolveSupportedEncoder();
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: 'mentality_reading.webm',
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

      final record = <String, dynamic>{
        'session_id': widget.sessionId,
        'text_id': widget.text.id,
        'audio_path': blobUrl ?? '',
        'duration_seconds': _elapsedSeconds,
        'timestamp': DateTime.now().toIso8601String(),
        'language': 'fr',
        'layer': 'C',
        'anonymized': true,
      };

      await DataCollectionService.instance.saveAudioRecord(record);
    } catch (_) {
      // L'échec de sauvegarde ne doit pas bloquer le parcours.
    }
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isSaving = false;
    });

    widget.onCompleted(widget.text.id, widget.sessionId);
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
        _buildInstructions(),
        SizedBox(height: 16.h),
        _buildTextCard(),
        SizedBox(height: 20.h),
        _buildRecordingControls(),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.record_voice_over, color: AppColors.primary, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              context.l10n.oralReadingInstructions,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    widget.text.body,
                    style: TextStyle(
                      fontSize: 18.sp,
                      height: 1.7,
                      color: Theme.of(context).colorScheme.onSurface,
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
        // Indicateur d'enregistrement
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

        // Boutons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecording && !_isSaving) ...[
              ElevatedButton.icon(
                onPressed: _showPermissionDialog,
                icon: const Icon(Icons.mic),
                label: Text(context.l10n.oralStartReading),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                    : context.l10n.oralFinish),
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
                widget.onCompleted(widget.text.id, widget.sessionId),
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
