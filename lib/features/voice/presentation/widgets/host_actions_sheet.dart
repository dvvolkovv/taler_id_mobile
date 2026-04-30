import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Bottom sheet shown when the host long-presses a participant tile in the
/// active group call screen. Currently exposes only the "Kick" action; the
/// other host-level actions (mute-all, add) live on the action bar.
class HostActionsSheet extends StatelessWidget {
  final String targetName;
  final VoidCallback onKick;

  const HostActionsSheet({
    super.key,
    required this.targetName,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.redAccent),
            title: Text(l10n.groupCallKickConfirm(targetName)),
            onTap: () {
              Navigator.pop(context);
              onKick();
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(l10n.groupCallCancelAction),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
