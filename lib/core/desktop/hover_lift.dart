// lib/core/desktop/hover_lift.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

/// Поднимает дочерний widget на `liftPx` при hover на десктопе.
/// На мобиле — passthrough.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.liftPx = 2.0,
    this.shadowBoost,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final double liftPx;
  final Color? shadowBoost;
  final Duration duration;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -widget.liftPx : 0, 0),
        decoration: BoxDecoration(
          boxShadow: _hover && widget.shadowBoost != null
              ? [
                  BoxShadow(
                    color: widget.shadowBoost!.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
