import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/room/caption_lines.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_signal.dart';

CaptionSignal _delta(CaptionRole role, String text, {String speaker = 's'}) =>
    CaptionSignal(role: role, speaker: speaker, text: text, isFinal: false);

CaptionSignal _final(CaptionRole role, String text, {String speaker = 's'}) =>
    CaptionSignal(role: role, speaker: speaker, text: text, isFinal: true);

void main() {
  final t0 = DateTime.utc(2026, 11, 1, 12, 0, 0);

  group('deltas', () {
    test('consecutive deltas within the gap join into one open line', () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.translation, 'Hal'), t0);
      lines.add(_delta(CaptionRole.translation, 'lo'),
          t0.add(const Duration(milliseconds: 500)));

      final result = lines.linesFor(CaptionRole.translation);
      expect(result, hasLength(1));
      expect(result.single.text, 'Hallo');
      expect(result.single.isFinal, isFalse);
    });

    test('a gap over 1.2s starts a new line', () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.translation, 'A'), t0);
      lines.add(_delta(CaptionRole.translation, 'B'),
          t0.add(const Duration(milliseconds: 1201)));

      final result = lines.linesFor(CaptionRole.translation);
      expect(result, hasLength(2));
      expect(result[0].text, 'A');
      expect(result[1].text, 'B');
    });

    test(
        'exactly at the gap boundary still joins (strictly greater-than splits)',
        () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.translation, 'A'), t0);
      lines.add(_delta(CaptionRole.translation, 'B'),
          t0.add(const Duration(milliseconds: 1200)));

      final result = lines.linesFor(CaptionRole.translation);
      expect(result, hasLength(1));
      expect(result.single.text, 'AB');
    });
  });

  group('final phrases', () {
    test('final:true is always its own line, not merged with an open delta',
        () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.source, 'partial'), t0);
      lines.add(_final(CaptionRole.source, 'full phrase'),
          t0.add(const Duration(milliseconds: 100)));

      final result = lines.linesFor(CaptionRole.source);
      expect(result, hasLength(2));
      expect(result[0].text, 'partial');
      expect(result[0].isFinal, isFalse);
      expect(result[1].text, 'full phrase');
      expect(result[1].isFinal, isTrue);
    });

    test(
        'a delta after a final always starts fresh, even within the gap window',
        () {
      final lines = CaptionLines();
      lines.add(_final(CaptionRole.source, 'done.'), t0);
      lines.add(_delta(CaptionRole.source, 'next'),
          t0.add(const Duration(milliseconds: 10)));

      final result = lines.linesFor(CaptionRole.source);
      expect(result, hasLength(2));
      expect(result[1].text, 'next');
      expect(result[1].isFinal, isFalse);
    });
  });

  group('cap at 20 lines per role', () {
    test('keeps only the most recent 20, newest last', () {
      final lines = CaptionLines();
      for (var i = 0; i < 25; i++) {
        lines.add(
            _final(CaptionRole.source, 'line$i'), t0.add(Duration(seconds: i)));
      }

      final result = lines.linesFor(CaptionRole.source);
      expect(result, hasLength(20));
      expect(result.first.text, 'line5');
      expect(result.last.text, 'line24');
    });
  });

  group('roles are independent', () {
    test('source and translation lines never mix', () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.source, 'rus'), t0);
      lines.add(_delta(CaptionRole.translation, 'deu'), t0);
      lines.add(_delta(CaptionRole.source, 'skiy'),
          t0.add(const Duration(milliseconds: 100)));

      expect(lines.linesFor(CaptionRole.source).single.text, 'russkiy');
      expect(lines.linesFor(CaptionRole.translation).single.text, 'deu');
    });

    test('a gap in one role does not affect the other', () {
      final lines = CaptionLines();
      lines.add(_delta(CaptionRole.source, 'A'), t0);
      lines.add(_delta(CaptionRole.translation, 'X'),
          t0.add(const Duration(seconds: 5)));
      lines.add(
          _delta(CaptionRole.source, 'B'), t0.add(const Duration(seconds: 5)));

      // source had a 5s gap -> 2 lines; translation's only delta -> 1 line.
      expect(lines.linesFor(CaptionRole.source), hasLength(2));
      expect(lines.linesFor(CaptionRole.translation), hasLength(1));
    });
  });

  test('linesFor returns an empty list for a role with no signals yet', () {
    final lines = CaptionLines();
    expect(lines.linesFor(CaptionRole.source), isEmpty);
  });
}
