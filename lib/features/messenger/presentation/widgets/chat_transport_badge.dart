import 'package:flutter/material.dart';

enum TransportBadgeState {
  /// Socket.io connected; messages go to server.
  server,

  /// Server unreachable, peer visible via mesh; messages go via mesh.
  mesh,

  /// Server unreachable and no mesh peer; messages queued.
  queued,
}

/// Small icon shown in ChatRoomScreen header so the user can tell whether
/// their outbound messages are going over the server, mesh, or are queued.
class ChatTransportBadge extends StatelessWidget {
  final TransportBadgeState state;
  const ChatTransportBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (state) {
      TransportBadgeState.server => (Icons.language, Colors.green, 'Server'),
      TransportBadgeState.mesh => (Icons.wifi_tethering, Colors.lightBlue, 'Mesh (offline fallback)'),
      TransportBadgeState.queued => (Icons.cloud_off, Colors.orange, 'Queued — no server, no mesh peer'),
    };
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
