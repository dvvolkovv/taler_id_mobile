import 'package:flutter/material.dart';

/// A single permission row visualised as a tall (~84 px) rounded card.
///
/// States:
///   - `!handled` → primary "Разрешить" tonal button on the right
///   - `handled && granted` → green ✓ + "Разрешено" text on the right
///   - `handled && !granted` → red ✗ + "Запрещено" text on the right
///     + a red [deniedHint] rendered under the row (tappable if [onDeniedHintTap] is set)
class PermissionRowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool handled;
  final bool granted;
  final String deniedHint;
  final VoidCallback? onDeniedHintTap;
  final List<Color> accentGradient;
  final VoidCallback onPressed;

  const PermissionRowCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.handled,
    required this.granted,
    required this.deniedHint,
    this.onDeniedHintTap,
    required this.accentGradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _IconCircle(
                icon: icon,
                handled: handled,
                granted: granted,
                accentGradient: accentGradient,
                onSurfaceColor: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (!handled)
                FilledButton.tonal(
                  onPressed: onPressed,
                  child: const Text('Разрешить'),
                )
              else if (granted)
                Text(
                  '✓ Разрешено',
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  '✗ Запрещено',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (handled && !granted)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: GestureDetector(
              onTap: onDeniedHintTap,
              child: Text(
                deniedHint,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  decoration: onDeniedHintTap != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: theme.colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool handled;
  final bool granted;
  final List<Color> accentGradient;
  final Color onSurfaceColor;

  const _IconCircle({
    required this.icon,
    required this.handled,
    required this.granted,
    required this.accentGradient,
    required this.onSurfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (!handled) {
      bgColor = accentGradient[0].withValues(alpha: 0.18);
    } else if (granted) {
      bgColor = Colors.green.shade400.withValues(alpha: 0.18);
    } else {
      bgColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.18);
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: onSurfaceColor),
    );
  }
}
