import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';
import 'package:taler_id_mobile/core/platform/secure_storage.dart';

/// Minimal in-memory fake that mirrors the subset of [SecureStorage]
/// that [UserIdentityKey] relies on. Avoids plugin calls in unit tests.
class _MemStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();
}

void main() {
  group('UserIdentityKey', () {
    test('generate produces 32-byte public + private bytes', () async {
      final key = await UserIdentityKey.generate();
      expect(key.publicKey.length, 32);
      expect(key.privateKeyBytes.length, 32);
    });

    test('loadOrCreate creates on first call, returns same key on second', () async {
      final storage = _MemStorage();

      final first = await UserIdentityKey.loadOrCreate(storage);
      final second = await UserIdentityKey.loadOrCreate(storage);

      expect(first.publicKey, equals(second.publicKey));
      expect(first.privateKeyBytes, equals(second.privateKeyBytes));
    });

    test('sign + verify round-trip succeeds', () async {
      final key = await UserIdentityKey.generate();
      final msg = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sig = await key.sign(msg);

      final ok = await UserIdentityKey.verify(
        publicKey: key.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isTrue);
    });

    test('verify rejects signature from different key', () async {
      final a = await UserIdentityKey.generate();
      final b = await UserIdentityKey.generate();
      final msg = Uint8List.fromList([7, 7, 7]);
      final sig = await a.sign(msg);

      final ok = await UserIdentityKey.verify(
        publicKey: b.publicKey,
        message: msg,
        signature: sig,
      );
      expect(ok, isFalse);
    });
  });
}
