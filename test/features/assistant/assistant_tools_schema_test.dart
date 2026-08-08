import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_schema.dart';

/// Task 15 — schema coverage for the pinned-messages voice tools
/// (pin_message/unpin_message/list_pinned). Scoped to just these three: the
/// rest of assistantToolSchemas() is exercised indirectly through
/// assistant_tools_executor_test.dart and the wider assistant test suite.
void main() {
  final tools = assistantToolSchemas(translatorMode: false);

  Map<String, dynamic> toolNamed(String name) =>
      tools.singleWhere((t) => t['name'] == name);

  group('pin_message schema', () {
    test('is present exactly once with conversationId/messageId required', () {
      final matches = tools.where((t) => t['name'] == 'pin_message');
      expect(matches, hasLength(1));

      final tool = toolNamed('pin_message');
      expect(tool['type'], 'function');
      expect(tool['description'], isA<String>());
      expect((tool['description'] as String).isNotEmpty, isTrue);

      final params = tool['parameters'] as Map<String, dynamic>;
      final props = params['properties'] as Map<String, dynamic>;
      expect(props.containsKey('conversationId'), isTrue);
      expect(props.containsKey('messageId'), isTrue);
      expect(params['required'], unorderedEquals(['conversationId', 'messageId']));
    });
  });

  group('unpin_message schema', () {
    test('is present exactly once with conversationId/messageId required', () {
      final matches = tools.where((t) => t['name'] == 'unpin_message');
      expect(matches, hasLength(1));

      final tool = toolNamed('unpin_message');
      expect(tool['type'], 'function');
      expect(tool['description'], isA<String>());
      expect((tool['description'] as String).isNotEmpty, isTrue);

      final params = tool['parameters'] as Map<String, dynamic>;
      final props = params['properties'] as Map<String, dynamic>;
      expect(props.containsKey('conversationId'), isTrue);
      expect(props.containsKey('messageId'), isTrue);
      expect(params['required'], unorderedEquals(['conversationId', 'messageId']));
    });
  });

  group('list_pinned schema', () {
    test('is present exactly once with only conversationId required', () {
      final matches = tools.where((t) => t['name'] == 'list_pinned');
      expect(matches, hasLength(1));

      final tool = toolNamed('list_pinned');
      expect(tool['type'], 'function');
      expect(tool['description'], isA<String>());
      expect((tool['description'] as String).isNotEmpty, isTrue);

      final params = tool['parameters'] as Map<String, dynamic>;
      final props = params['properties'] as Map<String, dynamic>;
      expect(props.containsKey('conversationId'), isTrue);
      expect(params['required'], ['conversationId']);
    });
  });

  test('translator mode does not expose the pin tools (only exit_translator_mode)', () {
    final translatorTools = assistantToolSchemas(translatorMode: true);
    final names = translatorTools.map((t) => t['name']).toSet();
    expect(names, {'exit_translator_mode'});
  });

  test('assistantToolSchemasForCompletions carries the three pin tools through', () {
    final completionsTools = assistantToolSchemasForCompletions();
    final names = completionsTools
        .map((t) => (t['function'] as Map<String, dynamic>)['name'])
        .toSet();
    expect(names, containsAll(['pin_message', 'unpin_message', 'list_pinned']));
  });
}
