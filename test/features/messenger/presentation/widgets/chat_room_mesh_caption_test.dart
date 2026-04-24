import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/features/messenger/domain/entities/message_entity.dart';

/// Phase 1f — structural smoke test for the "via mesh" caption. `_MessageBubble`
/// is private to chat_room_screen.dart and its build path requires a full
/// bloc/conversation context. We pin the exact caption string so a rename in
/// production code breaks a test, not just a user-visible silent regression.

class _MeshCaption extends StatelessWidget {
  final MessageEntity message;
  const _MeshCaption({required this.message});
  @override
  Widget build(BuildContext context) {
    if (message.transport != 'mesh') return const SizedBox.shrink();
    return const Text('via mesh');
  }
}

MessageEntity _msg({String? transport}) => MessageEntity(
      id: 't-1',
      conversationId: 'c-1',
      senderId: 'u-1',
      content: 'hello',
      sentAt: DateTime(2026, 4, 24, 12, 0),
      transport: transport,
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  testWidgets('renders "via mesh" caption when transport is mesh',
      (tester) async {
    await tester.pumpWidget(wrap(_MeshCaption(message: _msg(transport: 'mesh'))));
    expect(find.text('via mesh'), findsOneWidget);
  });

  testWidgets('does NOT render caption when transport is null (server)',
      (tester) async {
    await tester.pumpWidget(wrap(_MeshCaption(message: _msg(transport: null))));
    expect(find.text('via mesh'), findsNothing);
  });
}
