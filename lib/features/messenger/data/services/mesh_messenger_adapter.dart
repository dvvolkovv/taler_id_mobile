import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/mesh/services/envelope.dart';
import '../../../../core/mesh/services/mesh_messaging_service.dart';
import '../../../../core/mesh/transport/peer_id.dart';

class AdaptedInboundMessage {
  final String contactUserId;
  final String conversationId;
  final String text;
  /// Sender's wall-clock send time (from `envelope.sentAt`), NOT local
  /// arrival time. Named `receivedAt` for ergonomic alignment with
  /// `MessageReceived.receivedAt` in the bloc, but semantically this is
  /// the sender-supplied timestamp. Critical for the Phase 2 dedup
  /// heuristic in MessengerBloc (§7 of spec): the 10s window comparison
  /// is between this value and the SERVER's `MessageEntity.sentAt`,
  /// which is also the sender's wall-clock — so the two clocks align.
  /// Using `DateTime.now()` here would break the dedup window if the
  /// receiver's clock is skewed vs the sender's.
  final DateTime receivedAt;
  final String clientId;
  AdaptedInboundMessage({
    required this.contactUserId,
    required this.conversationId,
    required this.text,
    required this.receivedAt,
    required this.clientId,
  });
}

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

/// Phase 2 — envelope-aware bridge between MeshMessagingService and the
/// messenger layer. Inbound: routes by envelope.convId (uniform 1:1+group).
/// Outbound: per-peer fanout via [sendEnvelopeToPeer]; one logical send →
/// one [AdaptedOutboundMessage] via explicit [emitOutbound] (caller fires
/// it once after the per-peer fanout, so MessengerBloc replaces the
/// optimistic temp_clientId entry exactly once, not per peer).
class MeshMessengerAdapter {
  final Future<void> Function({required PeerId toUserPk, required Envelope envelope})
      meshSendEnvelope;
  final Stream<InboundEnvelope> meshInbound;
  final PeerId? Function(PeerId devicePk) lookupUserByDevice;
  final String? Function(PeerId userPk) contactUserIdForUserPk;
  final String? Function() currentUserIdProvider;
  final void Function(Map<String, dynamic> entry) persistLocal;

  static const String _kTransport = 'mesh';

  final _ctrl = StreamController<AdaptedInboundMessage>.broadcast();
  final _outCtrl = StreamController<AdaptedOutboundMessage>.broadcast();
  StreamSubscription<InboundEnvelope>? _sub;

  MeshMessengerAdapter({
    required this.meshSendEnvelope,
    required this.meshInbound,
    required this.lookupUserByDevice,
    required this.contactUserIdForUserPk,
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

  void _onInbound(InboundEnvelope inbound) {
    final userPk = lookupUserByDevice(inbound.fromUserPk);
    if (userPk == null) {
      debugPrint('[mesh-adapter] inbound from unknown devicePk, dropped');
      return;
    }
    final contactUserId = contactUserIdForUserPk(userPk);
    if (contactUserId == null) {
      debugPrint('[mesh-adapter] inbound from unknown userPk, dropped');
      return;
    }
    final convId = inbound.envelope.convId;
    final clientId = inbound.envelope.clientId;
    persistLocal({
      'id': clientId,
      'conversationId': convId,
      'contactUserId': contactUserId,
      'senderId': contactUserId,
      'content': inbound.envelope.text,
      'transport': _kTransport,
      'direction': 'inbound',
      'sentAt': inbound.envelope.sentAt.toUtc().toIso8601String(),
    });
    _ctrl.add(AdaptedInboundMessage(
      contactUserId: contactUserId,
      conversationId: convId,
      text: inbound.envelope.text,
      receivedAt: inbound.envelope.sentAt,
      clientId: clientId,
    ));
  }

  /// Phase 2 — single-peer mesh send. Caller (MessengerRepositoryImpl)
  /// invokes this once per visible+known peer in the group.
  ///
  /// Idempotency note: this method persists a local outbound record on
  /// every call. For a group fanout to N peers, [persistLocal] is invoked
  /// N times with the same [envelope.clientId] as the entry id.
  /// [MessengerCacheService.appendMeshMessage] (Phase 1f T2) dedupes by
  /// id, so the extra calls are no-ops at the Hive layer — semantically
  /// equivalent to one write. The N writes per fanout are cheap (Hive
  /// keeps an in-memory map; each put is ~µs) and bounded by the 50-peer
  /// group cap in MessengerRepositoryImpl. If group sizes ever grow
  /// substantially, hoist persistLocal to [emitOutbound] (one call per
  /// logical send) instead.
  Future<void> sendEnvelopeToPeer({
    required PeerId peerDevicePk,
    required String contactUserId,
    required Envelope envelope,
  }) async {
    await meshSendEnvelope(toUserPk: peerDevicePk, envelope: envelope);
    final myUserId = currentUserIdProvider();
    if (myUserId == null || myUserId.isEmpty) return;
    persistLocal({
      'id': envelope.clientId,
      'conversationId': envelope.convId,
      'contactUserId': contactUserId,
      'senderId': myUserId,
      'content': envelope.text,
      'transport': _kTransport,
      'direction': 'outbound',
      'sentAt': envelope.sentAt.toUtc().toIso8601String(),
    });
  }

  /// Phase 2 — emit a single AdaptedOutboundMessage for a logical send
  /// regardless of how many peers received it via mesh. Caller invokes
  /// this once per logical send AFTER all per-peer sendEnvelopeToPeer
  /// calls fire (or in fire-and-forget mode, after at least one succeeded).
  void emitOutbound(AdaptedOutboundMessage event) {
    _outCtrl.add(event);
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
    await _outCtrl.close();
  }
}
