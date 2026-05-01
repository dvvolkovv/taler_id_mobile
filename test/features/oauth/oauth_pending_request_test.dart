import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/oauth/data/oauth_pending_request.dart';

class _FakeStorage implements OAuthPendingStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}

void main() {
  group('OAuthPendingRequest', () {
    late _FakeStorage storage;
    late OAuthPendingRequest pending;
    late DateTime fakeNow;

    setUp(() {
      storage = _FakeStorage();
      fakeNow = DateTime.utc(2026, 4, 30, 12, 0, 0);
      pending = OAuthPendingRequest(storage: storage, now: () => fakeNow);
    });

    test('save persists params to storage with timestamp', () async {
      final uri = Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=mybook');
      await pending.save(uri);
      expect(await storage.read(), isNotNull);
    });

    test('consume returns saved uri and clears storage', () async {
      final uri = Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=mybook');
      await pending.save(uri);
      final result = await pending.consume();
      expect(result, uri);
      expect(await storage.read(), isNull);
    });

    test('consume returns null when nothing stored', () async {
      final result = await pending.consume();
      expect(result, isNull);
    });

    test('consume returns null and clears storage when TTL exceeded', () async {
      final uri = Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=mybook');
      await pending.save(uri);

      fakeNow = fakeNow.add(const Duration(minutes: 6));
      final result = await pending.consume();
      expect(result, isNull);
      expect(await storage.read(), isNull);
    });

    test('consume within TTL returns uri', () async {
      final uri = Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=mybook');
      await pending.save(uri);

      fakeNow = fakeNow.add(const Duration(minutes: 4));
      final result = await pending.consume();
      expect(result, uri);
    });

    test('save overwrites previous value', () async {
      await pending.save(Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=A'));
      await pending.save(Uri.parse('https://id.taler.tirol/oauth/authorize?client_id=B'));
      final result = await pending.consume();
      expect(result!.queryParameters['client_id'], 'B');
    });
  });
}
