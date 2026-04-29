import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.redAccent),
            title: Text('Удалить $targetName из звонка'),
            onTap: () {
              Navigator.pop(context);
              onKick();
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Отмена'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
