import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_chat_controller.dart';

void main() {
  late RoomChatController c;

  setUp(() => c = RoomChatController());

  test('принимает пакет chat_message и кладёт его в ленту', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'name': 'Аня', 'ts': 1000},
      fallbackName: 'Гость',
    );

    expect(handled, isTrue);
    expect(c.messages, hasLength(1));
    expect(c.messages.single.text, 'Привет');
    expect(c.messages.single.name, 'Аня');
    expect(c.messages.single.own, isFalse);
    expect(c.messages.single.sentAt.millisecondsSinceEpoch, 1000);
  });

  test('пакет чужого типа не трогает ленту', () {
    final handled = c.handlePacket(
      {'type': 'recording_approved'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('пустой текст игнорируется', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': '   ', 'name': 'Аня'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('без имени берётся запасное', () {
    c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет'},
      fallbackName: 'Гость',
    );

    expect(c.messages.single.name, 'Гость');
  });

  test('чужие сообщения при закрытой панели считаются непрочитанными', () {
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');
    c.handlePacket({'type': 'chat_message', 'text': 'два'}, fallbackName: 'Г');

    expect(c.unread, 2);
  });

  test('открытие панели обнуляет счётчик', () {
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');
    c.setOpen(true);

    expect(c.unread, 0);
    expect(c.isOpen, isTrue);
  });

  test('при открытой панели непрочитанные не копятся', () {
    c.setOpen(true);
    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');

    expect(c.unread, 0);
  });

  test('своё сообщение не считается непрочитанным', () {
    c.addOwn('Я', 'привет');

    expect(c.messages.single.own, isTrue);
    expect(c.unread, 0);
  });

  test('уведомляет слушателей о новом сообщении', () {
    var notified = 0;
    c.addListener(() => notified++);

    c.handlePacket({'type': 'chat_message', 'text': 'раз'}, fallbackName: 'Г');

    expect(notified, 1);
  });

  // --- устойчивость к типам из jsonDecode ---------------------------------

  test('не-строковый text не роняет разбор и не попадает в ленту', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 42, 'name': 'Аня'},
      fallbackName: 'Гость',
    );

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('не-строковое name заменяется запасным', () {
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'name': 7},
      fallbackName: 'Гость',
    );

    expect(handled, isTrue);
    expect(c.messages.single.name, 'Гость');
  });

  test('не-целочисленный ts заменяется текущим временем', () {
    final before = DateTime.now();
    final handled = c.handlePacket(
      {'type': 'chat_message', 'text': 'Привет', 'ts': '1000'},
      fallbackName: 'Гость',
    );
    final after = DateTime.now();

    expect(handled, isTrue);
    final sentAt = c.messages.single.sentAt;
    expect(sentAt.isBefore(before), isFalse);
    expect(sentAt.isAfter(after), isFalse);
  });

  test('не-строковый type не роняет разбор', () {
    final handled = c.handlePacket({'type': 5}, fallbackName: 'Гость');

    expect(handled, isFalse);
    expect(c.messages, isEmpty);
  });

  test('лента снаружи неизменяема', () {
    c.addOwn('Я', 'привет');

    expect(
      () => c.messages.add(
        RoomChatMessage(
          name: 'X',
          text: 'y',
          sentAt: DateTime.now(),
          own: false,
        ),
      ),
      throwsUnsupportedError,
    );
  });
}
