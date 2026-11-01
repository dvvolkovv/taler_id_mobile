import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/interpreter/room/interpreter_signal.dart';

List<int> _bytes(Object json) => utf8.encode(jsonEncode(json));

void main() {
  group('parse — caption', () {
    test('parses a translation delta', () {
      final signal = parse(_bytes({
        'type': 'caption',
        'role': 'translation',
        'speaker': 'user-1',
        'text': 'Hallo',
        'final': false,
      }));
      expect(signal, isA<CaptionSignal>());
      final caption = signal as CaptionSignal;
      expect(caption.role, CaptionRole.translation);
      expect(caption.speaker, 'user-1');
      expect(caption.text, 'Hallo');
      expect(caption.isFinal, isFalse);
    });

    test('parses a final source phrase', () {
      final signal = parse(_bytes({
        'type': 'caption',
        'role': 'source',
        'speaker': 'user-1',
        'text': 'Привет',
        'final': true,
      })) as CaptionSignal;
      expect(signal.role, CaptionRole.source);
      expect(signal.isFinal, isTrue);
    });

    test('unknown role returns null', () {
      expect(
        parse(_bytes({
          'type': 'caption',
          'role': 'nonsense',
          'speaker': 'user-1',
          'text': 'x',
          'final': false,
        })),
        isNull,
      );
    });

    test('missing field returns null', () {
      expect(
        parse(_bytes({
          'type': 'caption',
          'role': 'source',
          'speaker': 'user-1',
          'final': false,
        })),
        isNull,
      );
    });

    test('wrong field type returns null', () {
      expect(
        parse(_bytes({
          'type': 'caption',
          'role': 'source',
          'speaker': 'user-1',
          'text': 'x',
          'final': 'not-a-bool',
        })),
        isNull,
      );
    });
  });

  group('parse — speaking', () {
    test('parses on', () {
      final signal = parse(_bytes({
        'type': 'speaking',
        'speaker': 'user-1',
        'on': true,
      })) as SpeakingSignal;
      expect(signal.speaker, 'user-1');
      expect(signal.on, isTrue);
    });

    test('missing field returns null', () {
      expect(parse(_bytes({'type': 'speaking', 'speaker': 'user-1'})), isNull);
    });
  });

  group('parse — status', () {
    test('parses reconnecting', () {
      final signal = parse(_bytes({'type': 'status', 'state': 'reconnecting'}))
          as StatusSignal;
      expect(signal.state, StatusState.reconnecting);
    });

    test('parses ok', () {
      final signal =
          parse(_bytes({'type': 'status', 'state': 'ok'})) as StatusSignal;
      expect(signal.state, StatusState.ok);
    });

    test('parses failed', () {
      final signal =
          parse(_bytes({'type': 'status', 'state': 'failed'})) as StatusSignal;
      expect(signal.state, StatusState.failed);
    });

    test('unknown state returns null', () {
      expect(parse(_bytes({'type': 'status', 'state': 'confused'})), isNull);
    });
  });

  group('parse — never throws', () {
    test('unknown type returns null', () {
      expect(parse(_bytes({'type': 'something_else'})), isNull);
    });

    test('bad JSON returns null', () {
      expect(parse(utf8.encode('{not valid json')), isNull);
    });

    test('non-UTF8 bytes return null', () {
      // 0xFF is not a valid start byte in UTF-8.
      expect(parse(const [0xFF, 0xFE, 0x00, 0x01]), isNull);
    });

    test('a JSON value that is not an object returns null', () {
      expect(parse(_bytes([1, 2, 3])), isNull);
    });

    test('empty bytes return null', () {
      expect(parse(const []), isNull);
    });
  });
}
