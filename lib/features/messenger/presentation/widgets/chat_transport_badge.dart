import 'package:flutter/material.dart';

enum TransportBadgeState {
  /// Socket.io connected; messages go to server.
  server,

  /// 1:1: server unreachable, peer visible via mesh.
  mesh,

  /// Group: at least one participant visible via mesh.
  /// Use [visibleCount] / [totalCount] to render "N/M".
  meshGroup,

  /// Server unreachable and no mesh peer; messages queued.
  queued,
}

/// Small icon shown in ChatRoomScreen header so the user can tell whether
/// their outbound messages are going over the server, mesh, or are queued.
/// Phase 2: in group chats, also displays "<visibleCount>/<totalCount>"
/// when state is [TransportBadgeState.meshGroup].
class ChatTransportBadge extends StatelessWidget {
  final TransportBadgeState state;
  final int? visibleCount;
  final int? totalCount;

  const ChatTransportBadge({
    super.key,
    required this.state,
    this.visibleCount,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (state) {
      TransportBadgeState.server =>
          (Icons.language, Colors.green, 'Server'),
      TransportBadgeState.mesh =>
          (Icons.wifi_tethering, Colors.lightBlue, 'Mesh (offline fallback)'),
      TransportBadgeState.meshGroup => (
            Icons.wifi_tethering,
            Colors.lightBlue,
            'Group mesh ($visibleCount/$totalCount visible)'
          ),
      TransportBadgeState.queued => (
            Icons.cloud_off,
            Colors.orange,
            'Queued — no server, no mesh peer'
          ),
    };
    final iconWidget = Icon(icon, size: 18, color: color);
    final body = state == TransportBadgeState.meshGroup
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 4),
              Text(
                '$visibleCount/$totalCount',
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          )
        : iconWidget;
    return Tooltip(message: tooltip, child: body);
  }
}
