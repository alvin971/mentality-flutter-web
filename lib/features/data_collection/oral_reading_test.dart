// lib/features/data_collection/oral_reading_test.dart
// Module 1 — Enregistrement de la lecture à voix haute.
//
// L'utilisateur lit un texte affiché à l'écran pendant que sa voix est enregistrée.
// Sauvegarde un enregistrement Layer C dans mentality_sell.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
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
  bool _permissionGranted = false;
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
            const Text('Accès au microphone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette activité enregistre votre voix pendant que vous lisez le texte à voix haute.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Vos enregistrements seront anonymisés et pourront contribuer à l\'amélioration '
              'de la reconnaissance vocale en français.',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),
            Text(
              'Votre navigateur vous demandera ensuite d\'autoriser le microphone.',
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
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.mic),
            label: const Text('Autoriser le microphone'),
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
      setState(() {
        _permissionGranted = true;
        _permissionDenied = false;
      });
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
              onPressed: () => widget.onCompleted(widget.text.id, widget.sessionId),
            ),
          ),
        );
      }
    }
  }

  // ─── Enregistrement ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    // Sur Flutter Web, le paramètre path est symbolique.
    // recorder.stop() retourne un blob URL (blob:https://...).
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.opus, // webm/opus : seul format fiable sur Chrome/FF/Safari
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: 'mentality_reading.webm',
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
              'Lisez le texte suivant à voix haute, clairement et à votre rythme naturel. '
              'Appuyez sur "Démarrer" quand vous êtes prêt.',
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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

        // Boutons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecording && !_isSaving) ...[
              ElevatedButton.icon(
                onPressed: _showPermissionDialog,
                icon: const Icon(Icons.mic),
                label: const Text('Démarrer la lecture'),
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
                label: Text(_isSaving ? 'Sauvegarde...' : 'Terminer'),
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
              'Passer cette étape',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
