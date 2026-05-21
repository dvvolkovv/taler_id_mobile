// lib/core/desktop/animated_blob_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Анимированный фон из 3 плавающих радиальных blob-градиентов.
/// Извлечён из login_screen.dart для переиспользования на других desktop-экранах.
///
/// Использовать в `Stack` как `Positioned.fill(child: AnimatedBlobBackground())`.
class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: BlobBackgroundPainter(time: _bgCtrl.value * 2 * math.pi),
        ),
      ),
    );
  }
}

class BlobBackgroundPainter extends CustomPainter {
  final double time;
  BlobBackgroundPainter({required this.time});

  static const _blobColors = [
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFF22D3EE),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _blobColors.length; i++) {
      final phaseX = time * 0.4 + i * 1.8;
      final phaseY = time * 0.3 + i * 2.4;
      final cx = size.width * (0.5 + 0.42 * math.sin(phaseX));
      final cy = size.height * (0.35 + 0.33 * math.cos(phaseY));
      final radius = size.width * 0.75;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _blobColors[i].withOpacity(0.18),
            _blobColors[i].withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlobBackgroundPainter old) => old.time != time;
}
