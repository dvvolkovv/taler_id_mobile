import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/pending_call_answers.dart';

void main() {
  late DateTime now;
  late PendingCallAnswers queue;

  setUp(() {
    now = DateTime(2026, 9, 24, 10);
    queue = PendingCallAnswers(clock: () => now);
  });

  test('отданное событие уходит один раз, в порядке постановки', () {
    queue.add('conv-1', 'room-1');
    queue.add('conv-2', 'room-2');

    expect(queue.drain(), [
      (conversationId: 'conv-1', roomName: 'room-1'),
      (conversationId: 'conv-2', roomName: 'room-2'),
    ]);
    // Второй connect (переподключение) не должен повторить call_answered:
    // повторный доходит до звонящего как «ответили на другом устройстве».
    expect(queue.drain(), isEmpty);
  });

  test('повторная постановка той же комнаты не дублирует событие', () {
    queue.add('conv-1', 'room-1');
    queue.add('conv-1', 'room-1');

    expect(queue.drain(), hasLength(1));
  });

  test('устаревшее событие выбрасывается: звонок давно кончился', () {
    queue.add('conv-1', 'room-1');
    now = now.add(PendingCallAnswers.ttl + const Duration(seconds: 1));

    expect(queue.drain(), isEmpty);
  });

  test('событие в пределах срока доходит', () {
    queue.add('conv-1', 'room-1');
    now = now.add(PendingCallAnswers.ttl - const Duration(seconds: 1));

    expect(queue.drain(), hasLength(1));
  });

  test('завершённый звонок снимается с очереди', () {
    queue.add('conv-1', 'room-1');
    queue.add('conv-2', 'room-2');
    queue.remove('room-1');

    expect(queue.drain(), [(conversationId: 'conv-2', roomName: 'room-2')]);
  });
}
