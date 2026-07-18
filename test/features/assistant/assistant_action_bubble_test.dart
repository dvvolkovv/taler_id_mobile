import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/domain/assistant_action.dart';
import 'package:taler_id_mobile/features/assistant/presentation/widgets/assistant_action_bubble.dart';

void main() {
  testWidgets('renders title + icon and fires onTap', (tester) async {
    AssistantAction? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AssistantActionBubble(
          action: const AssistantAction(
            type: AssistantActionType.eventCreated,
            entityId: 'evt-1',
            title: 'Встреча с Иваном',
          ),
          onTap: (a) => tapped = a,
        ),
      ),
    ));
    expect(find.text('Встреча с Иваном'), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
    await tester.tap(find.byType(AssistantActionBubble));
    expect(tapped?.entityId, 'evt-1');
  });
}
