import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/message_entity.dart';

/// Telegram-style pinned-messages bar shown at the top of a chat.
///
/// Displays one pin at a time, starting with [pins].first. Callers are
/// expected to pass [pins] newest-first (the order `getPinnedMessages`
/// returns) so the initially-shown pin is the newest one.
///
/// Tapping the body jumps to the currently-shown pin (via [onJump]) and
/// advances to the next pin; repeated taps cycle through all pins, wrapping
/// back to the first after the last. The list icon opens the full pinned
/// list ([onOpenList]); the close icon hides the bar ([onDismiss]).
class PinnedBanner extends StatefulWidget {
  final List<MessageEntity> pins;
  final void Function(String messageId) onJump;
  final VoidCallback onDismiss;
  final VoidCallback onOpenList;

  const PinnedBanner({
    super.key,
    required this.pins,
    required this.onJump,
    required this.onDismiss,
    required this.onOpenList,
  });

  @override
  State<PinnedBanner> createState() => _PinnedBannerState();
}

class _PinnedBannerState extends State<PinnedBanner> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant PinnedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The list can shrink (a pin got unpinned elsewhere, or a fresher list
    // arrived) — clamp back to a valid index rather than crash on the next
    // build's `pins[_index]`.
    if (_index >= widget.pins.length) {
      _index = 0;
    }
  }

  void _handleTap() {
    final pins = widget.pins;
    if (pins.isEmpty) return;
    final current = pins[_index];
    widget.onJump(current.id);
    setState(() {
      _index = (_index + 1) % pins.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pins = widget.pins;
    if (pins.isEmpty) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Defensive: didUpdateWidget already clamps, but build can run before it
    // (e.g. first frame) so guard here too.
    final index = _index < pins.length ? _index : 0;
    final current = pins[index];
    final preview = current.content.replaceAll('\n', ' ');

    return Material(
      color: colors.card,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border),
            left: BorderSide(color: colors.primary, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _handleTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pins.length > 1
                            ? l10n.pinnedCounter(index + 1, pins.length)
                            : l10n.pinnedMessage,
                        style: TextStyle(
                            color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onOpenList,
              icon: Icon(Icons.list_alt_rounded, color: colors.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: widget.onDismiss,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
