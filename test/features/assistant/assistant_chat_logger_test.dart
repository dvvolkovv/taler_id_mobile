import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/data/assistant_chat_logger.dart';

void main() {
  test('batches entries and flushes after debounce', () {
    fakeAsync((async) {
      final flushed = <List<Map<String, dynamic>>>[];
      final logger = AssistantChatLogger(
        flush: (entries) async => flushed.add(List.of(entries)),
        debounce: const Duration(seconds: 2),
      );
      logger.addUser('привет', source: 'voice');
      logger.addAssistant('здравствуйте', source: 'voice');
      expect(flushed, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(flushed, hasLength(1));
      expect(flushed.single, hasLength(2));
      expect(flushed.single.first['role'], 'user');
    });
  });

  test('flushNow sends immediately and clears queue', () async {
    final flushed = <List<Map<String, dynamic>>>[];
    final logger = AssistantChatLogger(
      flush: (entries) async => flushed.add(List.of(entries)),
    );
    logger.addAction(
      role: 'assistant',
      source: 'voice',
      text: 'Встреча создана',
      action: {'type': 'event_created', 'entityId': 'e1', 'title': 'Встреча'},
    );
    await logger.flushNow();
    expect(flushed.single.single['action']['entityId'], 'e1');
    await logger.flushNow(); // empty queue — no extra flush
    expect(flushed, hasLength(1));
  });

  test('flush errors are swallowed, entries requeued once', () async {
    var calls = 0;
    final logger = AssistantChatLogger(
      flush: (entries) async {
        calls++;
        if (calls == 1) throw Exception('network');
      },
    );
    logger.addUser('x', source: 'text');
    await logger.flushNow(); // fail → requeue
    await logger.flushNow(); // success
    expect(calls, 2);
  });

  test('dropByItemId removes queued entries and itemId is stripped from flush', () async {
    final flushed = <List<Map<String, dynamic>>>[];
    final logger = AssistantChatLogger(
      flush: (entries) async => flushed.add(List.of(entries)),
    );
    logger.addUser('чужая речь', source: 'voice', itemId: 'item-1');
    logger.addUser('своя речь', source: 'voice', itemId: 'item-2');
    logger.dropByItemId('item-1');
    await logger.flushNow();
    expect(flushed.single, hasLength(1));
    expect(flushed.single.single['text'], 'своя речь');
    expect(flushed.single.single.containsKey('itemId'), isFalse);
  });
}
