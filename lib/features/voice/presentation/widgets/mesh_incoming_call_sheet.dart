import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../l10n/app_localizations.dart';

class _AvatarWidget extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;

  const _AvatarWidget({required this.displayName, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        child: ClipOval(
          child: Image.network(
            url,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsWidget(),
          ),
        ),
      );
    }
    return CircleAvatar(radius: 48, child: _initialsWidget());
  }

  Widget _initialsWidget() => Text(
        displayName.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 28),
      );
}

class MeshIncomingCallSheet extends StatefulWidget {
  final PeerId peer;
  final String? peerName;
  final String? peerAvatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Duration autoDeclineAfter;

  const MeshIncomingCallSheet({
    super.key,
    required this.peer,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.onAccept,
    required this.onDecline,
    this.autoDeclineAfter = const Duration(seconds: 30),
  });

  @override
  State<MeshIncomingCallSheet> createState() => _MeshIncomingCallSheetState();
}

class _MeshIncomingCallSheetState extends State<MeshIncomingCallSheet> {
  Timer? _autoDecline;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _autoDecline = Timer(widget.autoDeclineAfter, () {
      if (_fired) return;
      _fired = true;
      widget.onDecline();
    });
  }

  @override
  void dispose() {
    _autoDecline?.cancel();
    super.dispose();
  }

  void _handleAccept() {
    if (_fired) return;
    _fired = true;
    _autoDecline?.cancel();
    widget.onAccept();
  }

  void _handleDecline() {
    if (_fired) return;
    _fired = true;
    _autoDecline?.cancel();
    widget.onDecline();
  }

  String _displayName(AppLocalizations l10n) {
    final n = widget.peerName;
    if (n != null && n.isNotEmpty) return n;
    final hex = widget.peer.toHex();
    return l10n.meshDeviceFallback(hex.substring(0, 8));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = widget.peerAvatarUrl;
    final displayName = _displayName(l10n);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarWidget(
              displayName: displayName,
              avatarUrl: avatarUrl,
            ),
            const SizedBox(height: 16),
            Text(displayName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.meshIncomingCallLabel,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-decline'),
                  onPressed: _handleDecline,
                  icon: const Icon(Icons.call_end),
                  label: Text(l10n.incomingCallDecline),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-accept'),
                  onPressed: _handleAccept,
                  icon: const Icon(Icons.call),
                  label: Text(l10n.incomingCallAccept),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
