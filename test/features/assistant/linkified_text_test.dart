import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/presentation/widgets/linkified_text.dart';

void main() {
  const base = TextStyle(color: Colors.white);
  const link = TextStyle(color: Colors.blue);

  group('linkifiedSpans', () {
    test('text with 2 URLs and surrounding words -> 5 spans', () {
      final spans = linkifiedSpans(
        'см. https://example.com/a и https://example.org/b конец',
        base,
        link,
      );
      expect(spans, hasLength(5));
      expect((spans[0] as TextSpan).text, 'см. ');
      expect((spans[1] as TextSpan).text, 'https://example.com/a');
      expect((spans[1] as TextSpan).recognizer, isNotNull);
      expect((spans[2] as TextSpan).text, ' и ');
      expect((spans[3] as TextSpan).text, 'https://example.org/b');
      expect((spans[3] as TextSpan).recognizer, isNotNull);
      expect((spans[4] as TextSpan).text, ' конец');
      expect((spans[0] as TextSpan).recognizer, isNull);
      expect((spans[2] as TextSpan).recognizer, isNull);
      expect((spans[4] as TextSpan).recognizer, isNull);
    });

    test('text without URLs -> 1 span', () {
      final spans = linkifiedSpans('просто текст без ссылок', base, link);
      expect(spans, hasLength(1));
      expect((spans[0] as TextSpan).text, 'просто текст без ссылок');
      expect((spans[0] as TextSpan).recognizer, isNull);
    });
  });
}
