import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Full-screen overlay with a circular camera preview.
/// Recording starts automatically on mount, stops + returns path on [onDone].
/// The parent is responsible for showing/hiding this widget.
class VideoNoteRecorder extends StatefulWidget {
  /// Called with the recorded file path when recording ends.
  final void Function(String path) onDone;

  /// Called when the user cancels (e.g. error or swipe-away).
  final VoidCallback onCancel;

  const VideoNoteRecorder({super.key, required this.onDone, required this.onCancel});

  @override
  State<VideoNoteRecorder> createState() => _VideoNoteRecorderState();
}

class _VideoNoteRecorderState extends State<VideoNoteRecorder> with SingleTickerProviderStateMixin {
  CameraController? _cam;
  bool _initializing = true;
  bool _recording = false;
  bool _stopping = false;
  Timer? _timer;
  int _seconds = 0;
  static const _maxSeconds = 60;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) { widget.onCancel(); return; }
      // Prefer front camera
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cam = CameraController(front, ResolutionPreset.medium, enableAudio: true);
      await _cam!.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
      _startRecording();
    } catch (e) {
      debugPrint('[VideoNote] Camera init error: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _startRecording() async {
    if (_cam == null || !_cam!.value.isInitialized) return;
    try {
      await _cam!.startVideoRecording();
      setState(() => _recording = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) stopAndSend();
      });
    } catch (e) {
      debugPrint('[VideoNote] Start recording error: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> stopAndSend() async {
    if (_stopping || !_recording) return;
    _stopping = true;
    _timer?.cancel();
    try {
      final xfile = await _cam!.stopVideoRecording();
      // Move to temp directory with proper extension
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/video_note_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(xfile.path).copy(outPath);
      if (mounted) widget.onDone(outPath);
    } catch (e) {
      debugPrint('[VideoNote] Stop recording error: $e');
      if (mounted) widget.onCancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _cam?.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.7;

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Circular camera preview
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring
                if (_recording)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: circleSize + 8 + (_pulseCtrl.value * 6),
                      height: circleSize + 8 + (_pulseCtrl.value * 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.error.withValues(alpha: 0.5 + _pulseCtrl.value * 0.3),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                // Camera preview circle
                ClipOval(
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: _initializing || _cam == null
                        ? Container(
                            color: colors.surface,
                            child: Center(child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2)),
                          )
                        : FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cam!.value.previewSize?.height ?? circleSize,
                              height: _cam!.value.previewSize?.width ?? circleSize,
                              child: CameraPreview(_cam!),
                            ),
                          ),
                  ),
                ),
                // Timer overlay
                if (_recording)
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_timeStr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Отпустите для отправки',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
