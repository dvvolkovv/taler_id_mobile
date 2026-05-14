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
}
