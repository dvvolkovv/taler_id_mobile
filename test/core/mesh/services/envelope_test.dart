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
  });
}
