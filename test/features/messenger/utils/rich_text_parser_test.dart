import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/utils/rich_text_parser.dart';

void main() {
  group('parseRichText', () {
    test('plain text stays one plain token', () {
      expect(parseRichText('привет'), [const RichToken('привет', RichStyle.plain)]);
    });

    test('parses each marker', () {
      expect(parseRichText('**ж**'), [const RichToken('ж', RichStyle.bold)]);
      expect(parseRichText('__к__'), [const RichToken('к', RichStyle.italic)]);
      expect(parseRichText('~~з~~'), [const RichToken('з', RichStyle.strike)]);
      expect(parseRichText('`код`'), [const RichToken('код', RichStyle.code)]);
      expect(parseRichText('||секрет||'), [const RichToken('секрет', RichStyle.spoiler)]);
    });

    test('keeps the surrounding text', () {
      expect(parseRichText('до **тут** после'), [
        const RichToken('до ', RichStyle.plain),
        const RichToken('тут', RichStyle.bold),
        const RichToken(' после', RichStyle.plain),
      ]);
    });

    test('leaves an unclosed marker as plain text', () {
      // «2**2» не должно превращать половину сообщения в жирный текст.
      expect(parseRichText('2**2'), [const RichToken('2**2', RichStyle.plain)]);
    });

    test('leaves an empty pair as plain text', () {
      expect(parseRichText('****'), [const RichToken('****', RichStyle.plain)]);
    });

    test('does not parse markup inside code', () {
      expect(parseRichText('`**не жирный**`'),
          [const RichToken('**не жирный**', RichStyle.code)]);
    });

    test('does not parse markup inside a spoiler', () {
      expect(parseRichText('||`код`||'), [const RichToken('`код`', RichStyle.spoiler)]);
    });

    test('handles several spans in a row', () {
      expect(parseRichText('**а**__б__'), [
        const RichToken('а', RichStyle.bold),
        const RichToken('б', RichStyle.italic),
      ]);
    });

    test('empty input yields nothing', () {
      expect(parseRichText(''), isEmpty);
    });

    test('a lone marker is just a character', () {
      expect(parseRichText('|'), [const RichToken('|', RichStyle.plain)]);
      expect(parseRichText('a * b'), [const RichToken('a * b', RichStyle.plain)]);
    });
  });

  group('hasRichMarkup', () {
    test('false for ordinary text', () {
      expect(hasRichMarkup('обычное сообщение'), isFalse);
      expect(hasRichMarkup('2**2 = 4'), isFalse);
    });

    test('true when there is real markup', () {
      expect(hasRichMarkup('это **важно**'), isTrue);
      expect(hasRichMarkup('||тайна||'), isTrue);
    });
  });

  group('applyMarker', () {
    test('wraps the selection and keeps the cursor on it', () {
      final r = applyMarker('привет мир', 7, 10, RichStyle.bold);
      expect(r.text, 'привет **мир**');
      // Курсор должен остаться на выделенном слове, а не улететь в конец.
      expect(r.text.substring(r.selectionStart, r.selectionEnd), 'мир');
    });

    test('wraps an empty selection so the user can type inside', () {
      final r = applyMarker('привет ', 7, 7, RichStyle.spoiler);
      expect(r.text, 'привет ||||');
      expect(r.selectionStart, r.selectionEnd);
      expect(r.selectionStart, 9);
    });

    test('survives out-of-range offsets', () {
      expect(() => applyMarker('коротко', 0, 999, RichStyle.italic), returnsNormally);
    });
  });
}
