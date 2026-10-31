import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/call_orientation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// The call screen's "Не поворачивать экран" toggle.
///
/// [CallRotationLockButton.appBar] sits among the call app bar's actions in
/// portrait. [CallRotationLockButton.floating] is the round 36 px button
/// (48 px to tap) for the top-right corner in landscape, where the app bar
/// is gone — styled to pair with the back chevron in the top-left one.
///
/// The tooltip names what a tap will do, not the current state.
class CallRotationLockButton extends StatelessWidget {
  const CallRotationLockButton.appBar({super.key, required this.service})
      : floating = false;

  const CallRotationLockButton.floating({super.key, required this.service})
      : floating = true;

  final CallOrientationService service;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.rotationLocked,
      builder: (context, locked, _) {
        final l10n = AppLocalizations.of(context)!;
        final colors = AppColors.of(context);
        final icon = locked
            ? Icons.screen_lock_portrait_rounded
            : Icons.screen_rotation_rounded;
        final label =
            locked ? l10n.voiceRotationUnlock : l10n.voiceRotationLock;
        void toggle() => unawaited(service.setRotationLocked(!locked));

        if (!floating) {
          return IconButton(
            key: const Key('call-rotation-lock'),
            icon: Icon(icon, color: locked ? colors.primary : null),
            tooltip: label,
            onPressed: toggle,
          );
        }
        // One node for screen readers: a button named by the action. The
        // tooltip is only the long-press hint, so it stays out of semantics
        // (an IconButton gets the same from its tooltip by itself).
        // The circle pairs with the back chevron at 36 px, but is tapped in a
        // 48 px square: in a landscape video call this corner lies over the
        // user's own tile, where a near-miss flips the camera. Locked, the
        // circle is filled rather than the icon tinted — a primary icon on
        // the dark circle all but disappears in the light theme.
        return Semantics(
          container: true,
          button: true,
          label: label,
          child: Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: GestureDetector(
              key: const Key('call-rotation-lock'),
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: locked
                        ? colors.primary
                        : Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
