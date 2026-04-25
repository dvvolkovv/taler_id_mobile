import 'dart:async';

import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/peer_id.dart';

/// Adapted mesh outbound event — emitted AFTER the local transport ack,
/// so the bloc can replace the optimistic `temp_*` bubble with a
/// `mesh-out-*` MessageEntity carrying `transport: 'mesh'`.
class AdaptedOutboundMessage {
  final String id;
  final String conversationId;
  final String contactUserId;
  final String? clientTempId;
  final String text;
  final DateTime sentAt;
  AdaptedOutboundMessage({
    required this.id,
    required this.conversationId,
    required this.contactUserId,
    required this.clientTempId,
    required this.text,
    required this.sentAt,
  });
}

/// Adapted mesh inbound event for the messenger layer.
class AdaptedInboundMessage {
  final String contactUserId;
  final String conversationId;
  final String text;
  final DateTime receivedAt;
  AdaptedInboundMessage({
    required this.contactUserId,
    required this.conversationId,
    required this.text,
    required this.receivedAt,
  });
}

/// Bridges [MeshMessagingService] (transport level) and the messenger
/// layer. On inbound: resolves devicePk → userPk → contactUserId →
/// conversationId and emits an [AdaptedInboundMessage] the messenger
/// bloc consumes alongside server-delivered messages. On outbound: sends
/// via [meshSendText] and persists a local record flagged
/// `transport: 'mesh'`.
class MeshMessengerAdapter {
  static const _kTransport = 'mesh';

  final Future<void> Function({required PeerId toUserPk, required String text})
      meshSendText;
  final Stream<InboundMessage> meshInbound;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;

  /// Phase 1f — given a Taler ID contactUserId, return the existing DIRECT
  /// conversationId if one exists in the cache. When no server chat has
  /// ever happened with this contact, implementations should fall back to
  /// `meshOnly:<userId>` so the ghost chat still captures history.
  final String Function(String contactUserId) resolveConversationId;

  /// Phase 1f — provider that returns the currently authenticated Taler ID
  /// userId (or null before login). Used to stamp outbound mesh entries with
  /// the real senderId so chat bubbles render with the correct alignment.
  /// When the provider returns null, persistence is skipped entirely (see
  /// [sendMessage]) to avoid a bogus `'me'`-stamped entry that would render
  /// on the wrong side after app restart.
  final String? Function() currentUserIdProvider;

  final void Function(Map<String, dynamic> entry) persistLocal;

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  final _outCtrl = StreamController<AdaptedOutboundMessage>.broadcast();
  StreamSubscription<InboundMessage>? _sub;

  MeshMessengerAdapter({
    required this.meshSendText,
    required this.meshInbound,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
    required this.resolveConversationId,
    required this.currentUserIdProvider,
    required this.persistLocal,
  });

  Stream<AdaptedInboundMessage> get inbound => _ctrl.stream;
  Stream<AdaptedOutboundMessage> get outbound => _outCtrl.stream;

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
    final convId = resolveConversationId(contactUserId);
    final msgId = _inboundId(contactUserId, now);
    persistLocal({
      'id': msgId,
      'conversationId': convId,
      'contactUserId': contactUserId,
      'senderId': contactUserId,
      'content': msg.text,
      'transport': _kTransport,
      'direction': 'inbound',
      'sentAt': now.toUtc().toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      conversationId: convId,
      text: msg.text,
      receivedAt: now,
    ));
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required PeerId contactDevicePk,
    required String contactUserId,
    String? clientTempId,
  }) async {
    await meshSendText(toUserPk: contactDevicePk, text: text);
    final now = DateTime.now();
    final myUserId = currentUserIdProvider();
    if (myUserId == null || myUserId.isEmpty) {
      // Rare: bloc currentUserId not yet populated. Skip persistence so a
      // bogus `senderId: 'me'` entry doesn't render on the wrong side of
      // the chat after app restart — the transport send already succeeded,
      // so the message IS delivered; we just don't cache it locally.
      // Runtime inbound delivery on the receiver side is unaffected.
      return;
    }
    final msgId = _outboundId(contactUserId, now);
    persistLocal({
      'id': msgId,
      'conversationId': conversationId,
      'contactUserId': contactUserId,
      'senderId': myUserId,
      'content': text,
      'transport': _kTransport,
      'direction': 'outbound',
      'sentAt': now.toUtc().toIso8601String(),
    });
    _outCtrl.add(AdaptedOutboundMessage(
      id: msgId,
      conversationId: conversationId,
      contactUserId: contactUserId,
      clientTempId: clientTempId,
      text: text,
      sentAt: now,
    ));
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
    await _outCtrl.close();
  }

  // Id scheme matches MessengerBloc._onMeshMessageReceived so the same
  // message isn't double-rendered after T6 merges Hive mesh history into
  // bloc state. The 1ms window is safe: mesh RTT (BLE/Bonjour) is
  // ~100ms, so two messages from the same contact in <1ms cannot happen.
  static String _inboundId(String contactUserId, DateTime at) =>
      'mesh-in-$contactUserId-${at.millisecondsSinceEpoch}';

  static String _outboundId(String contactUserId, DateTime at) =>
      'mesh-out-$contactUserId-${at.millisecondsSinceEpoch}';
}
