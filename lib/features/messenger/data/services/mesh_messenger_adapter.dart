import 'dart:async';

import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/peer_id.dart';

/// Adapted mesh inbound event for the messenger layer.
class AdaptedInboundMessage {
  final String contactUserId;
  final String text;
  final DateTime receivedAt;
  AdaptedInboundMessage({
    required this.contactUserId,
    required this.text,
    required this.receivedAt,
  });
}

/// Bridges [MeshMessagingService] (transport level) and the messenger
/// layer. On inbound: resolves the sender's devicePk → userPk → Taler ID
/// contactUserId and emits an [AdaptedInboundMessage] that the messenger
/// bloc can consume alongside server-delivered messages. On outbound:
/// sends via [meshSendText] and persists a local record flagged
/// `transport: 'mesh'`.
///
/// The contact resolution + local persistence are injected as callbacks
/// so this adapter is easily unit-testable without touching Hive or the
/// DI graph.
class MeshMessengerAdapter {
  final Future<void> Function({required PeerId toUserPk, required String text})
      meshSendText;
  final Stream<InboundMessage> meshInbound;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;
  final void Function(Map<String, dynamic> entry) persistLocal;

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  StreamSubscription<InboundMessage>? _sub;

  MeshMessengerAdapter({
    required this.meshSendText,
    required this.meshInbound,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
    required this.persistLocal,
  });

  Stream<AdaptedInboundMessage> get inbound => _ctrl.stream;

  void start() {
    _sub ??= meshInbound.listen(_onInbound);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onInbound(InboundMessage msg) {
    final userPk = lookupUserByDevice(msg.fromUserPk);
    if (userPk == null) return;
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) return;
    final now = DateTime.now();
    persistLocal({
      'conversationId': 'meshOnly:$contactUserId',
      'contactUserId': contactUserId,
      'text': msg.text,
      'transport': 'mesh',
      'meshOnly': true,
      'direction': 'inbound',
      'sentAt': now.toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      text: msg.text,
      receivedAt: now,
    ));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required PeerId contactDevicePk,
    required String contactUserId,
  }) async {
    await meshSendText(toUserPk: contactDevicePk, text: text);
    persistLocal({
      'conversationId': conversationId,
      'contactUserId': contactUserId,
      'text': text,
      'transport': 'mesh',
      'meshOnly': true,
      'direction': 'outbound',
      'sentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
  }
}
