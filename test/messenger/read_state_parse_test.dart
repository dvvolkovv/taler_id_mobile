import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_read_state.dart';
void main() {
  test('parses read-state json', () {
    final r = ConversationReadState.fromJson({'conversationId':'c1','myLastReadAt':'2026-07-02T00:00:00.000Z','unread':3});
    expect(r.conversationId, 'c1');
    expect(r.unread, 3);
    expect(r.myLastReadAt!.toUtc().year, 2026);
  });

  test('parses participant cursor json', () {
    final c = ParticipantCursor.fromJson({
      'userId': 'u2',
      'lastReadAt': '2026-07-02T00:00:00.000Z',
      'lastReadMessageId': 'm9',
    });
    expect(c.userId, 'u2');
    expect(c.lastReadAt!.toUtc().year, 2026);
  });

  test('parses participant cursor json with null lastReadAt', () {
    final c = ParticipantCursor.fromJson({'userId': 'u3', 'lastReadAt': null});
    expect(c.userId, 'u3');
    expect(c.lastReadAt, isNull);
  });

  test('parseParticipantCursors maps the raw fetchConversationReadState list', () {
    final cursors = parseParticipantCursors([
      {'userId': 'u1', 'lastReadAt': '2026-07-01T00:00:00.000Z'},
      {'userId': 'u2', 'lastReadAt': null},
    ]);
    expect(cursors.length, 2);
    expect(cursors[0].userId, 'u1');
    expect(cursors[1].lastReadAt, isNull);
  });
}
