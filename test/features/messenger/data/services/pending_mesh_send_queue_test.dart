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
}
