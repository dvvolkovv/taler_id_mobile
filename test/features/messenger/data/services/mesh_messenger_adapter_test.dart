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

class _ContactLookupDouble {
  PeerId? Function(PeerId) lookupUserByDevice = (_) => null;
  String? Function(PeerId) contactUserIdForUserPk = (_) => null;
}

class _CacheSpy {
  final List<Map<String, dynamic>> persisted = [];

  void persist(Map<String, dynamic> entry) {
    persisted.add(entry);
  }
}

void main() {
  group('MeshMessengerAdapter', () {
    test('inbound from known contact emits adapted Message', () async {
      final messaging = _FakeMessaging();
      final lookup = _ContactLookupDouble();
      lookup.lookupUserByDevice = (dev) =>
          dev.toHex() == 'a' * 64 ? PeerId.fromHex('b' * 64) : null;
      lookup.contactUserIdForUserPk = (user) =>
          user.toHex() == 'b' * 64 ? 'contact-1' : null;
      final cache = _CacheSpy();

      final events = <AdaptedInboundMessage>[];
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: lookup.contactUserIdForUserPk,
        persistLocal: cache.persist,
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();

      messaging.pushInbound(PeerId.fromHex('a' * 64), 'Hello');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.contactUserId, 'contact-1');
      expect(events.first.text, 'Hello');
      expect(cache.persisted, hasLength(1));
      expect(cache.persisted.first['transport'], 'mesh');
      expect(cache.persisted.first['text'], 'Hello');

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('inbound from unknown contact is dropped', () async {
      final messaging = _FakeMessaging();
      final lookup = _ContactLookupDouble();
      final cache = _CacheSpy();

      final events = <AdaptedInboundMessage>[];
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: lookup.lookupUserByDevice,
        contactUserIdForUserPk: lookup.contactUserIdForUserPk,
        persistLocal: cache.persist,
      );
      final sub = adapter.inbound.listen(events.add);
      adapter.start();

      messaging.pushInbound(PeerId.fromHex('c' * 64), 'ignore me');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, isEmpty);
      expect(cache.persisted, isEmpty);

      await sub.cancel();
      await adapter.stop();
      await messaging.dispose();
    });

    test('sendMessage routes to meshMessaging and persists locally', () async {
      final messaging = _FakeMessaging();
      final cache = _CacheSpy();
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
        persistLocal: cache.persist,
      );

      await adapter.sendMessage(
        conversationId: 'conv-1',
        text: 'Hi there',
        contactDevicePk: PeerId.fromHex('a' * 64),
        contactUserId: 'contact-1',
      );

      expect(messaging.sentCalls, hasLength(1));
      expect(messaging.sentCalls.first.$1, PeerId.fromHex('a' * 64));
      expect(messaging.sentCalls.first.$2, 'Hi there');
      expect(cache.persisted, hasLength(1));
      expect(cache.persisted.first['transport'], 'mesh');
      expect(cache.persisted.first['conversationId'], 'conv-1');

      await messaging.dispose();
    });

    test('sendMessage surfaces error when underlying transport fails', () async {
      final messaging = _FakeMessaging()..fail = true;
      final cache = _CacheSpy();
      final adapter = MeshMessengerAdapter(
        meshSendText: messaging.sendText,
        meshInbound: messaging.inbound,
        lookupUserByDevice: (_) => null,
        contactUserIdForUserPk: (_) => null,
        persistLocal: cache.persist,
      );

      await expectLater(
        adapter.sendMessage(
          conversationId: 'conv-1',
          text: 'Hi there',
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
