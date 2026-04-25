import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';

void main() {
  group('AnalystSeam.fromJson', () {
    test('parses steps with kind+count and durationMs', () {
      final seam = AnalystSeam.fromJson({
        'conversationId': 'c1',
        'messageId': 'm1',
        'steps': [
          {'kind': 'search', 'count': 2},
          {'kind': 'file', 'count': 3},
        ],
        'durationMs': 12345,
      });
      expect(seam.conversationId, 'c1');
      expect(seam.messageId, 'm1');
      expect(seam.steps, hasLength(2));
      expect(seam.steps[0].kind, 'search');
      expect(seam.steps[0].count, 2);
      expect(seam.durationMs, 12345);
    });
  });

  group('AnalystChunk.fromJson', () {
    test('parses conversationId and text', () {
      final chunk = AnalystChunk.fromJson({'conversationId': 'c', 'text': 'hi'});
      expect(chunk.conversationId, 'c');
      expect(chunk.text, 'hi');
    });
  });

  group('AnalystSeam.fromMetadata', () {
    test('builds seam from Message.metadata', () {
      final seam = AnalystSeam.fromMetadata(
        conversationId: 'c', messageId: 'm',
        metadata: {
          'steps': [{'kind': 'cmd', 'count': 4}],
          'durationMs': 500,
        },
      );
      expect(seam!.steps.first.kind, 'cmd');
      expect(seam.durationMs, 500);
    });
    test('returns null when metadata has no steps', () {
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: null), null);
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: {}), null);
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: {'steps': []}), null);
    });
  });
}
