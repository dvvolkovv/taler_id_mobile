import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';

void main() {
  group('MeshMessengerAdapter Phase 2', () {
    late StreamController<InboundEnvelope> meshInboundCtrl;
    final List<({PeerId toUserPk, Envelope envelope})> sentCalls = [];
    final List<Map<String, dynamic>> persisted = [];
    final List<AdaptedInboundMessage> emitted = [];
    final List<AdaptedOutboundMessage> emittedOut = [];
    late MeshMessengerAdapter adapter;
    late StreamSubscription sub;
    late StreamSubscription outSub;

    setUp(() {
      meshInboundCtrl = StreamController<InboundEnvelope>.broadcast();
      sentCalls.clear();
      persisted.clear();
      emitted.clear();
      emittedOut.clear();
      adapter = MeshMessengerAdapter(
        meshSendEnvelope: ({required toUserPk, required envelope}) async {
          sentCalls.add((toUserPk: toUserPk, envelope: envelope));
        },
        meshInbound: meshInboundCtrl.stream,
        lookupUserByDevice: (devicePk) =>
            devicePk == PeerId.fromHex('b' * 64) ? PeerId.fromHex('b' * 64) : null,
        contactUserIdForUserPk: (userPk) =>
            userPk == PeerId.fromHex('b' * 64) ? 'contact-1' : null,
        currentUserIdProvider: () => 'me-user-id',
        persistLocal: persisted.add,
      );
      sub = adapter.inbound.listen(emitted.add);
      outSub = adapter.outbound.listen(emittedOut.add);
      adapter.start();
    });

    tearDown(() async {
      await sub.cancel();
      await outSub.cancel();
      await adapter.dispose();
      await meshInboundCtrl.close();
    });

    test('inbound envelope routes via envelope.convId (group case)', () async {
      meshInboundCtrl.add(InboundEnvelope(
        fromUserPk: PeerId.fromHex('b' * 64),
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'group-conv-42',
          clientId: 'cl-1',
          text: 'hi group',
          sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, hasLength(1));
      expect(emitted.first.contactUserId, 'contact-1');
      expect(emitted.first.conversationId, 'group-conv-42');
      expect(emitted.first.text, 'hi group');
      expect(emitted.first.clientId, 'cl-1');
      expect(persisted, hasLength(1));
      expect(persisted.first['id'], 'cl-1');
      expect(persisted.first['transport'], 'mesh');
      expect(persisted.first['conversationId'], 'group-conv-42');
      expect(persisted.first['senderId'], 'contact-1');
    });

    test('inbound from unknown device drops silently', () async {
      meshInboundCtrl.add(InboundEnvelope(
        fromUserPk: PeerId.fromHex('c' * 64),
        envelope: Envelope(
          version: 1,
          type: 'text',
          convId: 'whatever',
          clientId: 'cl-x',
          text: 'should be dropped',
          sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, isEmpty);
      expect(persisted, isEmpty);
    });

    test('sendEnvelopeToPeer wraps params and dispatches to messaging', () async {
      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: 'group-conv-42',
        clientId: 'cl-out',
        text: 'group send',
        sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
      );
      await adapter.sendEnvelopeToPeer(
        peerDevicePk: PeerId.fromHex('a' * 64),
        contactUserId: 'contact-X',
        envelope: envelope,
      );
      expect(sentCalls, hasLength(1));
      expect(sentCalls.first.toUserPk, PeerId.fromHex('a' * 64));
      expect(sentCalls.first.envelope.clientId, 'cl-out');
      expect(persisted, hasLength(1));
      expect(persisted.first['id'], 'cl-out');
      expect(persisted.first['conversationId'], 'group-conv-42');
      expect(persisted.first['senderId'], 'me-user-id');
      expect(persisted.first['transport'], 'mesh');
      expect(persisted.first['direction'], 'outbound');
    });

    test('emitOutbound publishes to outbound stream once', () async {
      final event = AdaptedOutboundMessage(
        id: 'mesh-out-1',
        conversationId: 'conv-1',
        contactUserId: 'contact-1',
        clientTempId: 'temp_uuid',
        text: 'hi',
        sentAt: DateTime.parse('2026-04-26T12:00:00.000Z'),
      );
      adapter.emitOutbound(event);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emittedOut, hasLength(1));
      expect(emittedOut.first.id, 'mesh-out-1');
      expect(emittedOut.first.clientTempId, 'temp_uuid');
    });
  });
}
