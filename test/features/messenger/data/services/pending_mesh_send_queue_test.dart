import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';

void main() {
  group('PendingMeshSendQueue enqueue + dueFor', () {
    test('enqueue then dueFor returns the entry for a participant peer', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
      );

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, hasLength(1));
      expect(due.single.clientId, 'temp_abc');
      expect(due.single.conversationId, 'conv-1');
      expect(due.single.content, 'hello');
    });

    test('dueFor filters out peers not in conversation participants', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      final due = queue.dueFor(
        peerUserId: 'user-charlie', // not in participants
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, isEmpty);
    });

    test('enqueue with same clientId overwrites, no duplicates', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'first',
        sentAt: DateTime.now().toUtc(),
      );
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'second',
        sentAt: DateTime.now().toUtc(),
      );

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob'],
      ).toList();

      expect(due, hasLength(1));
      expect(due.single.content, 'second');
    });
  });

  group('PendingMeshSendQueue markFannedOut', () {
    test('first call returns true, subsequent calls return false', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      final first = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      final second = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('first call for second peer also returns false (clientId already had a fanout)', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );

      queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');
      final second = queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-charlie');
      expect(second, isFalse);
    });

    test('marked peer is excluded from subsequent dueFor', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      queue.markFannedOut(clientId: 'temp_abc', peerUserId: 'user-bob');

      final due = queue.dueFor(
        peerUserId: 'user-bob',
        participantsOf: (_) => ['user-bob', 'user-me'],
      ).toList();

      expect(due, isEmpty);
    });

    test('markFannedOut on missing clientId is a no-op and returns false', () {
      final queue = PendingMeshSendQueue();
      final r = queue.markFannedOut(clientId: 'no-such-id', peerUserId: 'user-bob');
      expect(r, isFalse);
    });
  });

  group('PendingMeshSendQueue TTL + remove + pendingCount', () {
    test('expired entries are not returned by dueFor and are purged lazily', () {
      withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:00Z')), () {
        final queue = PendingMeshSendQueue(ttl: const Duration(seconds: 30));
        queue.enqueue(
          clientId: 'temp_abc',
          conversationId: 'conv-1',
          content: 'hello',
          sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
        );
        expect(queue.pendingCount, 1);

        // Advance fake time past TTL.
        withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:31Z')), () {
          final due = queue.dueFor(
            peerUserId: 'user-bob',
            participantsOf: (_) => ['user-bob'],
          ).toList();
          expect(due, isEmpty);
          expect(queue.pendingCount, 0,
              reason: 'lazy purge during dueFor must drop expired entries');
        });
      });
    });

    test('non-expired entries survive a dueFor call', () {
      withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:00Z')), () {
        final queue = PendingMeshSendQueue(ttl: const Duration(seconds: 30));
        queue.enqueue(
          clientId: 'temp_abc',
          conversationId: 'conv-1',
          content: 'hello',
          sentAt: DateTime.parse('2026-04-27T10:00:00Z'),
        );

        withClock(Clock.fixed(DateTime.parse('2026-04-27T10:00:10Z')), () {
          queue.dueFor(
            peerUserId: 'user-charlie', // not a participant; just trigger purge
            participantsOf: (_) => ['user-bob'],
          ).toList();
          expect(queue.pendingCount, 1);
        });
      });
    });

    test('remove drops the entry explicitly', () {
      final queue = PendingMeshSendQueue();
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      expect(queue.pendingCount, 1);
      queue.remove('temp_abc');
      expect(queue.pendingCount, 0);
      queue.remove('temp_abc'); // second remove is a no-op
      expect(queue.pendingCount, 0);
    });
  });
}
