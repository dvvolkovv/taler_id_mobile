import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/voice/mesh_prefs_service.dart';
import '../../../../l10n/app_localizations.dart';

class IosMeshOnboardingTooltip {
  /// If running on iOS and the onboarding has not yet been shown, presents a
  /// modal AlertDialog warning about background-suspend behavior. Marks the
  /// onboarding flag persistently after dismissal.
  ///
  /// Returns true iff the dialog was actually shown (and dismissed) just now.
  /// On non-iOS or when the flag is already set, returns false immediately.
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (kIsWeb || !Platform.isIOS) return false;
    final prefs = GetIt.I<MeshPrefsService>();
    if (await prefs.isOnboardingShown()) return false;
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meshOnboardingTitle),
        content: Text(l10n.meshOnboardingBody),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.meshOnboardingAck),
          ),
        ],
      ),
    );
    await prefs.markOnboardingShown();
    return true;
  }
}
