// test/core/platform/secure_storage_test.dart
//
// Tests for the SecureStorage abstraction.
//
// When run on macOS (the typical local/CI host for this project) the test
// runner targets the host OS, which PlatformUtils treats as desktop. Therefore
// SecureStorageDesktop is exercised here, giving us coverage of the
// encrypted-Hive path and the migration stub.
//
// We inject:
//   • A fake FlutterSecureStorage (in-memory map) to avoid Keychain calls.
//   • A temp directory for Hive so path_provider is not needed.
//
// This keeps the tests fully hermetic — no plugin channels required.

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taler_id_mobile/core/platform/secure_storage_desktop.dart';

// ---------------------------------------------------------------------------
// Minimal in-memory fake for FlutterSecureStorage
// ---------------------------------------------------------------------------
class _MemFss implements FlutterSecureStorage {
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

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.remove(key);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SecureStorageDesktop storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('secure_storage_test_');
    storage = SecureStorageDesktop(
      fss: _MemFss(),
      hiveDir: tempDir.path,
    );
    await storage.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('read returns null for unknown key', () async {
    expect(await storage.read('non_existent_key_xyz'), isNull);
  });

  test('write then read returns the same value', () async {
    await storage.write('test_key', 'test_value');
    expect(await storage.read('test_key'), equals('test_value'));
    await storage.delete('test_key');
  });

  test('migration: legacy auth_tokens box is copied then deleted', () async {
    // -----------------------------------------------------------------------
    // This test verifies the one-shot migration path:
    // 1. Seed a plain (unencrypted) Hive box named 'auth_tokens' with data,
    //    mimicking what the taler_id_desktop fork (≤ 1.0.48) left behind.
    // 2. Run SecureStorageDesktop.initialize() against the same directory.
    // 3. Confirm migrated values are readable via the new encrypted box.
    // 4. Confirm the legacy box no longer exists on disk.
    // -----------------------------------------------------------------------

    // Tear down the storage that setUp() already opened (uses 'secure_box_v2')
    // so we can seed the legacy box in the same Hive directory.
    await Hive.close();

    // Seed the legacy unencrypted box in the SAME tempDir.
    Hive.init(tempDir.path);
    final legacy = await Hive.openBox<dynamic>('auth_tokens');
    await legacy.put('access_token', 'fake_jwt');
    await legacy.put('refresh_token', 'fake_refresh');
    await legacy.close();

    // Close Hive before re-initializing via SecureStorageDesktop.
    await Hive.close();

    // Create a fresh instance (fresh _MemFss → no pre-existing AES key).
    final ss = SecureStorageDesktop(
      fss: _MemFss(),
      hiveDir: tempDir.path,
    );
    await ss.initialize();

    // Migrated data should be readable via the new encrypted API.
    expect(await ss.read('access_token'), equals('fake_jwt'));
    expect(await ss.read('refresh_token'), equals('fake_refresh'));

    // Legacy box must be gone from disk after migration.
    expect(await Hive.boxExists('auth_tokens'), isFalse);
  });
}
