// lib/core/platform/secure_storage_mobile.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage.dart';

/// [SecureStorage] implementation for iOS and Android.
///
/// Thin wrapper around [FlutterSecureStorage]:
/// - Android: EncryptedSharedPreferences (AES-256 key in Android Keystore).
/// - iOS: Keychain with `first_unlock` accessibility (readable in background,
///   e.g. for VoIP push handlers).
class SecureStorageMobile implements SecureStorage {
  static const _fss = FlutterSecureStorage(
    // resetOnError: if AndroidKeyStore master key is invalidated (system
    // events: biometric re-enrollment, lock-screen change, backup/restore,
    // OS upgrade) EncryptedSharedPreferences throws AEADBadTagException on
    // read and the app dies before runApp() — see incident 2026-06-10.
    // resetOnError tells FSS to wipe the corrupted prefs file on first read
    // failure so subsequent reads return null and writes succeed: user is
    // logged out and mesh identity is regenerated, but the app boots.
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<void> initialize() async {
    // No setup needed — FSS initialises lazily on first read/write.
  }

  @override
  Future<String?> read(String key) => _fss.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _fss.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _fss.delete(key: key);

  @override
  Future<void> deleteAll() => _fss.deleteAll();
}
