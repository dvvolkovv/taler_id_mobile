import 'package:flutter/material.dart';

/// 7 rainbow colors for participant glow borders.
const _rainbowColors = [
  Color(0xFFFF0000), // red
  Color(0xFFFF8000), // orange
  Color(0xFFFFFF00), // yellow
  Color(0xFF00FF00), // green
  Color(0xFF00BFFF), // cyan
  Color(0xFF0040FF), // blue
  Color(0xFF8000FF), // violet
];

/// Returns a deterministic rainbow color based on a string key (e.g. participant identity).
Color rainbowColorFor(String key) {
  return _rainbowColors[key.hashCode.abs() % _rainbowColors.length];
}

/// Circular avatar with a pulsating rainbow-colored glow border.
///
/// When [isSpeaking] is true, the avatar physically scales up/down (1.0–1.12)
/// with a fast rhythm and the glow intensifies.
/// When false, a subtle idle glow pulses slowly.
class PulsingAvatar extends StatefulWidget {
  final double radius;
  final Color glowColor;
  final Widget child;
  final bool isSpeaking;

  const PulsingAvatar({
    super.key,
    required this.radius,
    required this.glowColor,
    required this.child,
    this.isSpeaking = false,
  });

  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isSpeaking ? 400 : 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      _ctrl.duration = Duration(milliseconds: widget.isSpeaking ? 400 : 1800);
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speaking = widget.isSpeaking;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final v = _pulse.value;

        // Scale: when speaking, pulse between 1.0 and 1.12
        final scale = speaking ? 1.0 + 0.12 * v : 1.0;

        // Glow
        final glowAlpha = speaking
            ? 0.6 + 0.4 * v    // 0.6–1.0 when speaking
            : 0.12 + 0.12 * v; // 0.12–0.24 idle (very subtle)
        final blur = speaking
            ? 14.0 + 12.0 * v  // 14–26 when speaking
            : 3.0 + 3.0 * v;   // 3–6 idle
        final spread = speaking
            ? 3.0 + 5.0 * v    // 3–8 when speaking
            : 0.5 + 0.5 * v;   // 0.5–1 idle
        final borderAlpha = speaking
            ? 0.8 + 0.2 * v
            : 0.25 + 0.15 * v;
        final borderWidth = speaking ? 3.0 : 2.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: glowAlpha),
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.glowColor.withValues(alpha: borderAlpha),
                  width: borderWidth,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
