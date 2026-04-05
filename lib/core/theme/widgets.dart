import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Frosted glass card with backdrop blur
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? blurSigma;
  final double? opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blurSigma,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sigma = blurSigma ?? colors.glassBlurSigma;
    final bgOpacity = opacity ?? colors.glassOpacity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassColor.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.glassColor.withOpacity(colors.glassBorderOpacity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Backward-compatible alias
typedef AppCard = GlassCard;

/// KYC/KYB status badge — glass-tinted
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// Full-width loading button with blue gradient
class LoadingButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;
  const LoadingButton(
      {super.key,
      required this.text,
      required this.loading,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = !loading && onPressed != null;
    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? colors.primaryGradient : null,
        color: enabled ? null : colors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassColor.withOpacity(0.08)),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.primary.withOpacity(0.45),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Skeleton loading placeholder — glass shimmer
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonBox({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.of(context).glassColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

/// Wraps a child with a slow scale + glow pulse, used to draw the eye to
/// status indicators (unread badges, verified KYC, missed calls, etc).
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool enabled;
  final double maxScale;
  final Duration period;
  final BorderRadius borderRadius;

  const PulsingBadge({
    super.key,
    required this.child,
    required this.glowColor,
    this.enabled = true,
    this.maxScale = 1.08,
    this.period = const Duration(milliseconds: 1400),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    // Pulse the glow (box-shadow) only — avoid Transform.scale since it
    // can cause 1-pixel BOTTOM OVERFLOWED warnings inside tight parents
    // like ListTile trailing columns.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final glow = 0.35 + 0.4 * _ctrl.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(glow),
                blurRadius: 6 + 8 * _ctrl.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Empty-state placeholder with a gradient circular icon, title, subtitle,
/// and optional action button. Used for "no items yet" screens.
class EmptyStateView extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Color> gradient;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.gradient = const [Color(0xFF3B82F6), Color(0xFFA855F7)],
  });

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = widget.gradient.first;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                final scale = 1.0 + 0.05 * math.sin(t * math.pi);
                final glow = 0.35 + 0.25 * t;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: glow),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, size: 42, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (widget.action != null) ...[
              const SizedBox(height: 20),
              widget.action!,
            ],
          ],
        ),
      ),
    );
  }
}
