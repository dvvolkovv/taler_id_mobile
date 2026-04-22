import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/user_identity_key.dart';

/// Minimal in-memory fake that mirrors the subset of FlutterSecureStorage
/// UserIdentityKey relies on. Avoids MissingPluginException in unit tests.
class _MemStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  // Unused methods — delegate to noSuchMethod to avoid implementing the whole surface.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
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
