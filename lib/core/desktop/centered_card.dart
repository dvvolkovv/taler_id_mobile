// lib/core/desktop/centered_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism-карточка, в которую заворачивается desktop-форма.
/// На мобиле использовать не нужно — это desktop-only widget.
class CenteredCard extends StatelessWidget {
  const CenteredCard({
    super.key,
    required this.child,
    this.useGlass = true,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = 20,
  });

  final Widget child;
  final bool useGlass;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: useGlass
            ? Colors.white.withOpacity(0.07)
            : Theme.of(context).colorScheme.surface,
        border: useGlass
            ? Border.all(color: Colors.white.withOpacity(0.14))
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!useGlass) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: card,
      ),
    );
  }
}
