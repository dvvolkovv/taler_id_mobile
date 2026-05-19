import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Two large blurred radial gradient blobs that drift slowly across the
/// window. Same look as the mobile onboarding bg without sharing code with
/// the mobile file (avoids touching mobile during this isolated desktop
/// project).
///
/// The parent owns the AnimationController so it can be paused / resumed and
/// disposed deterministically.
class OnboardingAnimatedBackground extends StatelessWidget {
  final Animation<double> animation;
  const OnboardingAnimatedBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            Positioned(
              left: 200 + math.sin(t) * 120,
              top: 100 + math.cos(t) * 80,
              child: const _Blob(
                colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
              ),
            ),
            Positioned(
              right: 200 + math.sin(t + math.pi / 2) * 120,
              bottom: 100 + math.cos(t + math.pi / 2) * 80,
              child: const _Blob(
                colors: [Color(0xFF10B981), Color(0xFF22D3EE)],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final List<Color> colors;
  const _Blob({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [colors[0].withOpacity(0.35), colors[1].withOpacity(0.0)],
        ),
      ),
    );
  }
}
