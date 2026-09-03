import 'package:flutter/foundation.dart';

/// Одно сообщение в чате комнаты.
@immutable
class RoomChatMessage {
  final String name;
  final String text;
  final DateTime sentAt;
  final bool own;

  const RoomChatMessage({
    required this.name,
    required this.text,
    required this.sentAt,
    required this.own,
  });
}

/// Состояние чата комнаты: лента, счётчик непрочитанных, открыта ли панель.
///
/// Живёт ровно столько, сколько идёт звонок: истории у чата нет, вошедший
/// позже не видит написанного до него — осознанное решение.
///
/// Дедупликацией по `msgId` не занимается: она сделана централизованно
/// в начале `_handleDataReceived`, до разбора типа пакета.
///
/// Разбор пакета намеренно устойчив к типам: данные приходят из `jsonDecode`
/// по сети, и любое поле может оказаться не той природы, которую мы ждём.
/// Приведение вида `msg['text'] as String?` бросило бы `TypeError` на числе,
/// внешний `try/catch` в `_handleDataReceived` его проглотил бы — и сообщение
/// исчезло бы молча вместе со всем остальным разбором пакета.
class RoomChatController extends ChangeNotifier {
  final List<RoomChatMessage> _messages = [];
  int _unread = 0;
  bool _open = false;

  List<RoomChatMessage> get messages => List.unmodifiable(_messages);
  int get unread => _unread;
  bool get isOpen => _open;

  void setOpen(bool open) {
    _open = open;
    if (open) _unread = 0;
    notifyListeners();
  }

  /// Разбирает пакет из data-канала. Возвращает false, если это не сообщение
  /// чата или оно пустое — вызывающая сторона тогда ничего не делает.
  bool handlePacket(
    Map<String, dynamic> msg, {
    required String fallbackName,
  }) {
    if (msg['type'] != 'chat_message') return false;

    final rawText = msg['text'];
    final text = rawText is String ? rawText.trim() : '';
    if (text.isEmpty) return false;

    final rawName = msg['name'];
    final name = rawName is String ? rawName.trim() : '';
    final ts = msg['ts'];

    _append(RoomChatMessage(
      name: name.isEmpty ? fallbackName : name,
      text: text,
      sentAt: ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now(),
      own: false,
    ));
    return true;
  }

  /// Своё отправленное сообщение — показываем сразу, не дожидаясь эха.
  void addOwn(String name, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _append(RoomChatMessage(
      name: name,
      text: trimmed,
      sentAt: DateTime.now(),
      own: true,
    ));
  }

  void _append(RoomChatMessage m) {
    _messages.add(m);
    if (!m.own && !_open) _unread++;
    notifyListeners();
  }
}
