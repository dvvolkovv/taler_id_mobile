// lib/core/desktop/empty_state.dart
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart';
import '../theme/app_theme.dart';

/// Стандартизированный empty state с glow-иконкой, title, subtitle и optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformUtils.instance.isDesktop;
    final colors = AppColors.of(context);
    final glowSize = isDesktop ? 96.0 : 64.0;
    final iconSize = isDesktop ? 36.0 : 28.0;
    final titleSize = isDesktop ? 22.0 : 18.0;
    final subtitleSize = isDesktop ? 15.0 : 14.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(icon, size: iconSize, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: subtitleSize, color: colors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
