// lib/core/desktop/focus_ring.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';

/// Усиленный visible focus ring для keyboard nav на десктопе.
/// На мобиле — passthrough.
///
/// Использовать только если нужна обёртка над не-input widget.
/// Для TextFormField есть `desktopInputDecoration()` helper.
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.focusNode,
    this.ringWidth = 3,
    this.ringColor,
    this.borderRadius = 12,
  });

  final Widget child;
  final FocusNode? focusNode;
  final double ringWidth;
  final Color? ringColor;
  final double borderRadius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  late final FocusNode _internalNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _internalNode = widget.focusNode ?? FocusNode();
    _internalNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _internalNode.removeListener(_onFocus);
    if (widget.focusNode == null) _internalNode.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _internalNode.hasFocus) {
      setState(() => _focused = _internalNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.instance.isDesktop) return widget.child;
    final color = widget.ringColor ?? Theme.of(context).colorScheme.primary;
    return Focus(
      focusNode: _internalNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _focused
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 0, spreadRadius: widget.ringWidth)]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
