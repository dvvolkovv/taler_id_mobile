import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_test_');
    Hive.init(tempDir.path);
    await MessengerCacheService.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MessengerCacheService mesh persistence', () {
    test('appendMeshMessage persists entry and getMeshMessagesFor returns it',
        () async {
      final svc = MessengerCacheService();
      await svc.appendMeshMessage({
        'id': 'mesh-1',
        'conversationId': 'conv-1',
        'senderId': 'u-2',
        'content': 'hello',
        'transport': 'mesh',
        'sentAt': '2026-04-24T12:00:00.000Z',
      });

      final list = svc.getMeshMessagesFor('conv-1');
      expect(list, hasLength(1));
      expect(list.first['id'], 'mesh-1');
      expect(list.first['content'], 'hello');
      expect(list.first['transport'], 'mesh');
    });

    test('appendMeshMessage dedupes by id', () async {
      final svc = MessengerCacheService();
      final entry = {
        'id': 'mesh-1',
        'conversationId': 'conv-1',
        'senderId': 'u-2',
        'content': 'hello',
        'transport': 'mesh',
        'sentAt': '2026-04-24T12:00:00.000Z',
      };
      await svc.appendMeshMessage(entry);
      await svc.appendMeshMessage(entry);
      expect(svc.getMeshMessagesFor('conv-1'), hasLength(1));
    });

    test('getMeshMessagesFor returns list sorted ascending by sentAt',
        () async {
      final svc = MessengerCacheService();
      await svc.appendMeshMessage({
        'id': 'mesh-b',
        'conversationId': 'conv-1',
        'senderId': 'u-2',
        'content': 'later',
        'transport': 'mesh',
        'sentAt': '2026-04-24T12:02:00.000Z',
      });
      await svc.appendMeshMessage({
        'id': 'mesh-a',
        'conversationId': 'conv-1',
        'senderId': 'u-2',
        'content': 'earlier',
        'transport': 'mesh',
        'sentAt': '2026-04-24T12:00:00.000Z',
      });
      final list = svc.getMeshMessagesFor('conv-1');
      expect(list.map((m) => m['id']).toList(), ['mesh-a', 'mesh-b']);
    });

    test('getMeshMessagesFor returns empty list when no mesh history',
        () async {
      final svc = MessengerCacheService();
      expect(svc.getMeshMessagesFor('unknown'), isEmpty);
    });

    test('getConversationByContact resolves DIRECT conversation by otherUserId',
        () async {
      final svc = MessengerCacheService();
      await svc.saveConversations([
        {
          'id': 'conv-direct',
          'participantIds': ['me', 'u-2'],
          'type': 'DIRECT',
          'otherUserId': 'u-2',
        },
        {
          'id': 'conv-group',
          'participantIds': ['me', 'u-2', 'u-3'],
          'type': 'GROUP',
        },
      ]);
      final found = svc.getConversationByContact('u-2');
      expect(found?.id, 'conv-direct');
    });

    test('getConversationByContact returns null when no DIRECT chat exists',
        () async {
      final svc = MessengerCacheService();
      await svc.saveConversations([
        {
          'id': 'conv-group',
          'participantIds': ['me', 'u-2', 'u-3'],
          'type': 'GROUP',
        },
      ]);
      expect(svc.getConversationByContact('u-2'), isNull);
    });

    test('getConversationByContact ignores group chats containing the contact',
        () async {
      final svc = MessengerCacheService();
      await svc.saveConversations([
        {
          'id': 'conv-group',
          'participantIds': ['me', 'u-2'],
          'type': 'GROUP',
          'otherUserId': 'u-2',
        },
      ]);
      expect(svc.getConversationByContact('u-2'), isNull);
    });

    test('getMeshMessagesFor sorts correctly when entries mix UTC Z and local offsets',
        () async {
      final svc = MessengerCacheService();
      // 'later' is written as a Z-suffixed UTC string; 'earlier' as naive
      // (no offset) ISO. Lexicographic compare would put Z after naive; the
      // parsed-DateTime compare must put the actual earlier timestamp first.
      await svc.appendMeshMessage({
        'id': 'mesh-later',
        'conversationId': 'conv-mix',
        'senderId': 'u-2',
        'content': 'later',
        'transport': 'mesh',
        'sentAt': '2026-04-24T13:00:00.000Z',
      });
      await svc.appendMeshMessage({
        'id': 'mesh-earlier',
        'conversationId': 'conv-mix',
        'senderId': 'u-2',
        'content': 'earlier',
        'transport': 'mesh',
        'sentAt': '2026-04-24T12:00:00.000',
      });
      final list = svc.getMeshMessagesFor('conv-mix');
      expect(list.map((m) => m['id']).toList(),
          ['mesh-earlier', 'mesh-later']);
    });
  });
}
