import '../domain/entities/message_entity.dart';

/// id первого непрочитанного входящего — перед ним рисуется линия
/// «Непрочитанные сообщения».
///
/// [messages] в хронологическом порядке (нулевой — самый старый).
/// [lastReadAt] — собственный курсор чтения из read-state; null означает, что в
/// беседе не прочитано ничего.
///
/// Считаем по курсору, а не по `unreadCount` беседы: у счётчика два писателя без
/// порядка между ними, он бывает временно неверным, а курсор — факт.
///
/// Свои и системные строки пропускаются: линия перед собственной репликой или
/// перед «X присоединился» не несёт смысла.
///
/// Возвращает null, если непрочитанного нет — тогда линии нет вовсе.
String? findFirstUnreadMessageId({
  required List<MessageEntity> messages,
  required String myUserId,
  required DateTime? lastReadAt,
}) {
  for (final m in messages) {
    if (m.senderId == myUserId || m.isSystem) continue;
    if (lastReadAt == null || m.sentAt.isAfter(lastReadAt)) return m.id;
  }
  return null;
}
