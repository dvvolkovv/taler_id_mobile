import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/voice/mesh_prefs_service.dart';
import '../../../../l10n/app_localizations.dart';

class BatteryExemptionDialog {
  /// Show the battery-exemption educational dialog if running on Android
  /// and the user hasn't been prompted before. Returns true if dialog was
  /// shown (and dismissed).
  static Future<bool> showIfNeeded(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final prefs = GetIt.I<MeshPrefsService>();
    if (await prefs.isBatteryPromptShown()) return false;
    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.batteryExemptionTitle),
          content: Text(l10n.batteryExemptionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.batteryExemptionDismiss),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.batteryExemptionAccept),
            ),
          ],
        ),
      ),
    );
    // Only persist the "shown" flag if the user explicitly chose either
    // button. If the dialog was auto-dismissed (back gesture, app
    // backgrounded, route swap), keep the flag false so it surfaces again
    // on the next foreground-service start.
    if (accepted == null) return false;
    await prefs.markBatteryPromptShown();
    if (accepted) {
      try {
        await Permission.ignoreBatteryOptimizations.request();
      } catch (_) {}
    }
    return true;
  }
}
