import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';
import 'package:taler_id_mobile/features/messenger/utils/unread_anchor.dart';

void main() {
  const me = 'u-me';
  const them = 'u-them';

  MessageEntity msg(
    String id,
    String senderId,
    String isoTime, {
    bool isSystem = false,
  }) =>
      MessageEntity(
        id: id,
        conversationId: 'c1',
        senderId: senderId,
        content: id,
        sentAt: DateTime.parse(isoTime),
        isSystem: isSystem,
      );

  final t = DateTime.parse('2026-08-10T10:00:00Z');

  test('picks the first incoming message after the read cursor', () {
    final anchor = findFirstUnreadMessageId(
      messages: [
        msg('old', them, '2026-08-10T09:00:00Z'),
        msg('first-new', them, '2026-08-10T11:00:00Z'),
        msg('second-new', them, '2026-08-10T12:00:00Z'),
      ],
      myUserId: me,
      lastReadAt: t,
    );

    expect(anchor, 'first-new');
  });

  test('returns null when everything is read', () {
    final anchor = findFirstUnreadMessageId(
      messages: [msg('a', them, '2026-08-10T09:00:00Z')],
      myUserId: me,
      lastReadAt: t,
    );

    expect(anchor, isNull);
  });

  test('never anchors on my own message', () {
    // Линия «непрочитанные» перед собственной репликой бессмысленна.
    final anchor = findFirstUnreadMessageId(
      messages: [
        msg('mine', me, '2026-08-10T11:00:00Z'),
        msg('theirs', them, '2026-08-10T12:00:00Z'),
      ],
      myUserId: me,
      lastReadAt: t,
    );

    expect(anchor, 'theirs');
  });

  test('skips system rows', () {
    final anchor = findFirstUnreadMessageId(
      messages: [
        msg('joined', them, '2026-08-10T11:00:00Z', isSystem: true),
        msg('real', them, '2026-08-10T12:00:00Z'),
      ],
      myUserId: me,
      lastReadAt: t,
    );

    expect(anchor, 'real');
  });

  test('a never-read conversation anchors on the very first incoming', () {
    final anchor = findFirstUnreadMessageId(
      messages: [
        msg('mine', me, '2026-08-10T08:00:00Z'),
        msg('theirs', them, '2026-08-10T09:00:00Z'),
      ],
      myUserId: me,
      lastReadAt: null,
    );

    expect(anchor, 'theirs');
  });

  test('a message exactly at the cursor counts as read', () {
    // Курсор указывает на последнее прочитанное, а не на первое непрочитанное.
    final anchor = findFirstUnreadMessageId(
      messages: [msg('edge', them, '2026-08-10T10:00:00Z')],
      myUserId: me,
      lastReadAt: t,
    );

    expect(anchor, isNull);
  });

  test('an empty conversation has no anchor', () {
    expect(
      findFirstUnreadMessageId(messages: [], myUserId: me, lastReadAt: t),
      isNull,
    );
  });
}
