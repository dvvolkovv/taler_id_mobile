import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_read_state.dart';
void main() {
  test('parses read-state json', () {
    final r = ConversationReadState.fromJson({'conversationId':'c1','myLastReadAt':'2026-07-02T00:00:00.000Z','unread':3});
    expect(r.conversationId, 'c1');
    expect(r.unread, 3);
    expect(r.myLastReadAt!.toUtc().year, 2026);
  });
}
