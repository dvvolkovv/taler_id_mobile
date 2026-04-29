import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/services/envelope.dart';

void main() {
  group('Envelope', () {
    test('round-trips toJson/fromJson with all fields', () {
      final env = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-uuid-123',
        clientId: 'client-uuid-456',
        text: 'Привет 👋',
        sentAt: DateTime.parse('2026-04-26T12:34:56.789Z'),
      );
      final json = env.toJson();
      expect(json['v'], 1);
      expect(json['type'], 'text');
      expect(json['convId'], 'conv-uuid-123');
      expect(json['clientId'], 'client-uuid-456');
      expect(json['text'], 'Привет 👋');
      expect(json['sentAt'], '2026-04-26T12:34:56.789Z');
      final decoded = Envelope.fromJson(json);
      expect(decoded.version, 1);
      expect(decoded.type, 'text');
      expect(decoded.convId, 'conv-uuid-123');
      expect(decoded.clientId, 'client-uuid-456');
      expect(decoded.text, 'Привет 👋');
      expect(decoded.sentAt, env.sentAt);
    });

    test('round-trips through JSON string with multibyte characters', () {
      final env = Envelope(
        version: 1,
        type: 'text',
        convId: 'c-1',
        clientId: 'cl-1',
        text: 'эмодзи 🎉 китайский 你好 emoji 🚀',
        sentAt: DateTime.parse('2026-04-26T00:00:00.000Z'),
      );
      final encoded = jsonEncode(env.toJson());
      final decoded = Envelope.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>);
      expect(decoded.text, env.text);
    });

    test('fromJson tolerates unknown extra fields (forward-compat)', () {
      final json = {
        'v': 1,
        'type': 'text',
        'convId': 'c-1',
        'clientId': 'cl-1',
        'text': 'hi',
        'sentAt': '2026-04-26T00:00:00.000Z',
        'futureField': 'ignored',  // simulating a Phase 2.5 extension
      };
      final env = Envelope.fromJson(json);
      expect(env.text, 'hi');
    });

    test('fromJson throws FormatException on missing required field', () {
      expect(
        () => Envelope.fromJson({'v': 1, 'type': 'text'}),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException on malformed sentAt', () {
      expect(
        () => Envelope.fromJson({
          'v': 1,
          'type': 'text',
          'convId': 'c-1',
          'clientId': 'cl-1',
          'text': 'hi',
          'sentAt': 'not-a-date',
        }),
        throwsFormatException,
      );
    });

    test('fromJson throws FormatException on null required field', () {
      expect(
        () => Envelope.fromJson({
          'v': 1,
          'type': 'text',
          'convId': 'c-1',
          'clientId': null,
          'text': 'hi',
          'sentAt': '2026-04-26T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('fromJson normalises sentAt to UTC even when input has offset', () {
      // Input has +05:00 offset; output should be UTC equivalent.
      final env = Envelope.fromJson({
        'v': 1,
        'type': 'text',
        'convId': 'c-1',
        'clientId': 'cl-1',
        'text': 'tz check',
        'sentAt': '2026-04-26T05:00:00.000+05:00',  // = 00:00 UTC
      });
      expect(env.sentAt.isUtc, isTrue);
      expect(env.sentAt.toIso8601String(), '2026-04-26T00:00:00.000Z');
    });
  });

  group('Envelope.extra', () {
    test('roundtrip preserves extra map', () {
      final e = Envelope(
        version: 1,
        type: 'call_invite',
        convId: 'conv-1',
        clientId: 'call-uuid-1',
        text: '',
        sentAt: DateTime.utc(2026, 4, 29, 12),
        extra: {'codec': 'opus', 'rate': 16000},
      );
      final json = e.toJson();
      expect(json['extra'], {'codec': 'opus', 'rate': 16000});

      final back = Envelope.fromJson(json);
      expect(back.extra, {'codec': 'opus', 'rate': 16000});
    });

    test('fromJson tolerates missing extra (backward compat with v1 peers)', () {
      final e = Envelope.fromJson({
        'v': 1,
        'type': 'text',
        'convId': 'conv-1',
        'clientId': 'msg-1',
        'text': 'hi',
        'sentAt': '2026-04-29T12:00:00.000Z',
      });
      expect(e.extra, isNull);
    });

    test('toJson omits extra when null', () {
      final e = Envelope(
        version: 1,
        type: 'text',
        convId: 'conv-1',
        clientId: 'msg-1',
        text: 'hi',
        sentAt: DateTime.utc(2026, 4, 29, 12),
      );
      final json = e.toJson();
      expect(json.containsKey('extra'), isFalse);
    });
  });
}
