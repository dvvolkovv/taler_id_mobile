import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/mesh_messaging_service.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';

class _FakeMessaging {
  final _ctrl = StreamController<InboundMessage>.broadcast();
  final sentCalls = <(PeerId, String)>[];
  bool fail = false;

  Stream<InboundMessage> get inbound => _ctrl.stream;

  Future<void> sendText({required PeerId toUserPk, required String text}) async {
    if (fail) throw StateError('send boom');
    sentCalls.add((toUserPk, text));
  }

  void pushInbound(PeerId from, String text) {
    _ctrl.add(InboundMessage(fromUserPk: from, text: text));
  }

  Future<void> dispose() => _ctrl.close();
}

class _CacheSpy {
  final List<Map<String, dynamic>> persisted = [];
  void persist(Map<String, dynamic> entry) => persisted.add(entry);
}

MeshMessengerAdapter _adapter(
  _FakeMessaging m,
  _CacheSpy cache, {
  PeerId? Function(PeerId)? lookupUserByDevice,
  String? Function(PeerId)? contactUserIdForUserPk,
  String Function(String)? resolveConversationId,
}) {
  return MeshMessengerAdapter(
    meshSendText: m.sendText,
    meshInbound: m.inbound,
    lookupUserByDevice: lookupUserByDevice ?? (_) => null,
    contactUserIdForUserPk: contactUserIdForUserPk ?? (_) => null,
    resolveConversationId:
        resolveConversationId ?? (userId) => 'meshOnly:$userId',
    persistLocal: cache.persist,
  );
}

void main() {
  group('MeshMessengerAdapter', () {
    test('inbound from known contact emits AdaptedInboundMessage with resolved conversationId',
        () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final events = <AdaptedInboundMessage>[];
      final adapter = _adapter(
        messaging,
        cache,
        lookupUserByDevice: (dev) =>
            dev.toHex() == 'a' * 64 ? PeerId.fromHex('b' * 64) : null,
        contactUserIdForUserPk: (user) =>
            user.toHex() == 'b' * 64 ? 'contact-1' : null,
        resolveConversationId: (uid) =>
            uid == 'contact-1' ? 'server-conv-42' : 'meshOnly:$uid',
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();

      messaging.pushInbound(PeerId.fromHex('a' * 64), 'Hello');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.contactUserId, 'contact-1');
      expect(events.first.conversationId, 'server-conv-42');
      expect(events.first.text, 'Hello');
      expect(cache.persisted, hasLength(1));
      final e = cache.persisted.first;
      expect(e['transport'], 'mesh');
      expect(e['conversationId'], 'server-conv-42');
      expect(e['content'], 'Hello');
      expect(e['senderId'], 'contact-1');
      expect(e['id'], startsWith('mesh-'),
          reason: 'persisted entry must carry a deterministic mesh-prefixed id for dedup');

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('inbound falls back to meshOnly:<userId> when no server chat exists',
        () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final events = <AdaptedInboundMessage>[];
      final adapter = _adapter(
        messaging,
        cache,
        lookupUserByDevice: (_) => PeerId.fromHex('b' * 64),
        contactUserIdForUserPk: (_) => 'contact-2',
        resolveConversationId: (uid) => 'meshOnly:$uid',
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();
      messaging.pushInbound(PeerId.fromHex('a' * 64), 'first contact');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.conversationId, 'meshOnly:contact-2');
      expect(cache.persisted.first['conversationId'], 'meshOnly:contact-2');

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('inbound from unknown device is dropped silently', () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final events = <AdaptedInboundMessage>[];
      final adapter = _adapter(messaging, cache);
      final sub = adapter.inbound.listen(events.add);
      adapter.start();
      messaging.pushInbound(PeerId.fromHex('c' * 64), 'ignore');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events, isEmpty);
      expect(cache.persisted, isEmpty);
      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('sendMessage persists outbound entry with deterministic id + caller conversationId',
        () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final adapter = _adapter(messaging, cache);

      await adapter.sendMessage(
        conversationId: 'server-conv-42',
        text: 'Hi there',
        contactDevicePk: PeerId.fromHex('a' * 64),
        contactUserId: 'contact-1',
      );

      expect(messaging.sentCalls, hasLength(1));
      expect(messaging.sentCalls.first.$1, PeerId.fromHex('a' * 64));
      expect(messaging.sentCalls.first.$2, 'Hi there');
      expect(cache.persisted, hasLength(1));
      final e = cache.persisted.first;
      expect(e['transport'], 'mesh');
      expect(e['conversationId'], 'server-conv-42');
      expect(e['direction'], 'outbound');
      expect(e['id'], startsWith('mesh-out-'));

      await messaging.dispose();
    });

    test('sendMessage surfaces error from underlying transport and does NOT persist',
        () async {
      final messaging = _FakeMessaging()..fail = true;
      final cache = _CacheSpy();
      final adapter = _adapter(messaging, cache);

      await expectLater(
        adapter.sendMessage(
          conversationId: 'server-conv-42',
          text: 'boom',
          contactDevicePk: PeerId.fromHex('a' * 64),
          contactUserId: 'contact-1',
        ),
        throwsStateError,
      );
      expect(cache.persisted, isEmpty);

      await messaging.dispose();
    });
  });
}
