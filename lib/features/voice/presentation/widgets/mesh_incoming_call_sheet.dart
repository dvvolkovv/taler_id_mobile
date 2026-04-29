import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/mesh/transport/peer_id.dart';

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

  String _displayName() {
    final n = widget.peerName;
    if (n != null && n.isNotEmpty) return n;
    final hex = widget.peer.toHex();
    return 'Mesh-устройство ${hex.substring(0, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.peerAvatarUrl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarWidget(
              displayName: _displayName(),
              avatarUrl: avatarUrl,
            ),
            const SizedBox(height: 16),
            Text(_displayName(),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('📡 Входящий mesh-звонок',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-decline'),
                  onPressed: _handleDecline,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Отклонить'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  key: const Key('mesh-incoming-accept'),
                  onPressed: _handleAccept,
                  icon: const Icon(Icons.call),
                  label: const Text('Принять'),
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
