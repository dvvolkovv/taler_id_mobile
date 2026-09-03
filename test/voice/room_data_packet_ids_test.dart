import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_chat_controller.dart';
import 'package:taler_id_mobile/features/voice/presentation/controllers/room_data_packet_ids.dart';

/// Пакет чата ровно в том виде, в каком его кладёт в data-канал
/// `_sendChatMessage`: id проставляет `_broadcastData` через [ids].
Map<String, dynamic> chatPacket(RoomDataPacketIds ids, String text) => {
      'type': 'chat_message',
      'text': text,
      'name': 'Алиса',
      'ts': DateTime.now().millisecondsSinceEpoch,
      'msgId': ids.next(),
    };

/// Приёмная сторона так, как её собирает `_handleDataReceived`: сначала
/// общая дедупликация по msgId, потом разбор пакета чата.
bool receive(
  RoomDataPacketIds ids,
  RoomChatController chat,
  Map<String, dynamic> packet, {
  String fallbackName = 'identity-алисы',
}) {
  final msgId = packet['msgId'];
  if (msgId is String && ids.isDuplicate(msgId)) return false;
  return chat.handlePacket(packet, fallbackName: fallbackName);
}

void main() {
  group('RoomDataPacketIds', () {
    test('нумерует пакеты последовательно', () {
      final ids = RoomDataPacketIds(prefix: 'p');
      expect([ids.next(), ids.next(), ids.next()], ['p_0', 'p_1', 'p_2']);
    });

    test('без явного префикса два экземпляра дают непересекающиеся id', () {
      final first = RoomDataPacketIds();
      final second = RoomDataPacketIds();
      final firstIds = List.generate(20, (_) => first.next()).toSet();
      final secondIds = List.generate(20, (_) => second.next()).toSet();
      expect(firstIds.intersection(secondIds), isEmpty);
    });

    test('отсеивает повтор и пропускает новый id', () {
      final ids = RoomDataPacketIds();
      expect(ids.isDuplicate('a'), isFalse);
      expect(ids.isDuplicate('a'), isTrue);
      expect(ids.isDuplicate('b'), isFalse);
    });

    test('переполнение набора не роняет дедупликацию свежих id', () {
      final ids = RoomDataPacketIds();
      for (var i = 0; i <= RoomDataPacketIds.maxRemembered; i++) {
        expect(ids.isDuplicate('id_$i'), isFalse);
      }
      // Набор очистился, старые id уже забыты — это осознанный компромисс.
      expect(ids.isDuplicate('свежий'), isFalse);
      expect(ids.isDuplicate('свежий'), isTrue);
    });
  });

  group('проводка приёма чата', () {
    test('обычная доставка: пакет доходит до ленты', () {
      final sender = RoomDataPacketIds();
      final receiverIds = RoomDataPacketIds();
      final chat = RoomChatController();

      expect(receive(receiverIds, chat, chatPacket(sender, 'привет')), isTrue);
      expect(chat.messages.single.text, 'привет');
      expect(chat.messages.single.name, 'Алиса');
      expect(chat.unread, 1);
    });

    test('повтор того же пакета в ленту не попадает', () {
      final sender = RoomDataPacketIds();
      final receiverIds = RoomDataPacketIds();
      final chat = RoomChatController();

      final packet = chatPacket(sender, 'привет');
      expect(receive(receiverIds, chat, packet), isTrue);
      expect(receive(receiverIds, chat, packet), isFalse);
      expect(chat.messages, hasLength(1));
    });

    test('без имени в пакете подставляется fallbackName', () {
      final sender = RoomDataPacketIds();
      final receiverIds = RoomDataPacketIds();
      final chat = RoomChatController();

      final packet = chatPacket(sender, 'привет')..['name'] = '';
      expect(receive(receiverIds, chat, packet), isTrue);
      expect(chat.messages.single.name, 'identity-алисы');
    });

    // Регрессия: экран звонка сворачивается (`_minimizeCall` → `context.pop()`),
    // комната и identity живут дальше в CallStateService, а состояние экрана
    // пересоздаётся. Если бы префикс msgId строился из identity, счётчик пошёл
    // бы с нуля и первые сообщения после возврата собеседник отбросил бы как
    // дубли — молча, отправитель бы видел свой пузырь.
    test('после пересоздания экрана отправителя сообщения не глотаются', () {
      final receiverIds = RoomDataPacketIds();
      final chat = RoomChatController();

      final beforeMinimize = RoomDataPacketIds();
      for (var i = 0; i < 3; i++) {
        expect(receive(receiverIds, chat, chatPacket(beforeMinimize, 'до $i')),
            isTrue);
      }

      // Экран свернули и открыли заново: новое состояние — новый генератор,
      // та же комната и та же identity у отправителя.
      final afterRestore = RoomDataPacketIds();
      for (var i = 0; i < 3; i++) {
        expect(receive(receiverIds, chat, chatPacket(afterRestore, 'после $i')),
            isTrue,
            reason: 'сообщение $i после возврата на экран отброшено как дубль');
      }

      expect(chat.messages.map((m) => m.text).toList(),
          ['до 0', 'до 1', 'до 2', 'после 0', 'после 1', 'после 2']);
    });
  });
}
