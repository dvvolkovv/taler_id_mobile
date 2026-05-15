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
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
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
