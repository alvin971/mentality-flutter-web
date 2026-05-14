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
            const Text('Accès au microphone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous allez maintenant enregistrer votre résumé oral du texte.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Parlez naturellement, comme si vous expliquiez le texte à un ami. '
              'Prenez entre 30 et 60 secondes.',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.mic),
            label: const Text('Démarrer le résumé'),
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
    final granted = await _recorder.hasPermission();
    if (!mounted) return;
    if (granted) {
      await _startRecording();
    } else {
      setState(() => _permissionDenied = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Microphone refusé. Vous pouvez passer à l\'étape suivante.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Passer',
              textColor: Colors.white,
              onPressed: () => widget.onCompleted(
                  widget.originalText.id, widget.sessionId),
            ),
          ),
        );
      }
    }
  }

  // ─── Enregistrement ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.opus,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: 'mentality_summary.webm',
    );
    if (!mounted) return;
    setState(() => _isRecording = true);
    _startTimers();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _blinkTimer?.cancel();
    setState(() => _isSaving = true);

    final blobUrl = await _recorder.stop();
    if (!mounted) return;

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
          Icon(Icons.chat_bubble_outline, color: Colors.teal.shade700, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Vous venez de lire ce texte. ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  TextSpan(
                    text: 'Résumez ce que vous avez compris avec vos propres mots. '
                        'Prenez entre 30 et 60 secondes. '
                        'Parlez naturellement, comme si vous l\'expliquiez à un ami.',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.article_outlined,
                      size: 16.sp, color: Theme.of(context).colorScheme.outline),
                  SizedBox(width: 6.w),
                  Text(
                    'Texte de référence',
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
                      color: Theme.of(context).colorScheme.outline, // grisé = référence non interactive
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
                'Enregistrement en cours',
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
              'Continuez encore ${_minDurationSeconds - _elapsedSeconds}s...',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.outline),
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
                label: const Text('Démarrer le résumé'),
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
                label: Text(_isSaving ? 'Sauvegarde...' : 'Terminer le résumé'),
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
            onPressed: () => widget.onCompleted(
                widget.originalText.id, widget.sessionId),
            child: Text(
              'Passer cette étape',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
