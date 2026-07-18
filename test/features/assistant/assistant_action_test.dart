import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/domain/assistant_action.dart';

void main() {
  group('AssistantAction', () {
    test('parses full metadata action', () {
      final a = AssistantAction.fromMetadata({
        'assistantRole': 'assistant',
        'source': 'voice',
        'action': {
          'type': 'message_sent',
          'entityId': 'msg-1',
          'conversationId': 'conv-2',
          'title': 'Сообщение для Ивана',
        },
      });
      expect(a, isNotNull);
      expect(a!.type, AssistantActionType.messageSent);
      expect(a.entityId, 'msg-1');
      expect(a.conversationId, 'conv-2');
      expect(a.title, 'Сообщение для Ивана');
    });

    test('returns null without action', () {
      expect(AssistantAction.fromMetadata({'assistantRole': 'user'}), isNull);
      expect(AssistantAction.fromMetadata(null), isNull);
    });

    test('unknown type -> null (forward compat)', () {
      expect(
        AssistantAction.fromMetadata({
          'action': {'type': 'teleport', 'entityId': 'x', 'title': 't'},
        }),
        isNull,
      );
    });

    test('toJson roundtrip', () {
      const a = AssistantAction(
        type: AssistantActionType.eventCreated,
        entityId: 'evt-1',
        title: 'Встреча',
      );
      expect(AssistantAction.fromMetadata({'action': a.toJson()}), a);
    });
  });
}
