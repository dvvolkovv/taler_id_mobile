// lib/core/platform/secure_storage.dart
import 'platform_utils.dart';
import 'secure_storage_mobile.dart';
import 'secure_storage_desktop.dart';

/// Platform-agnostic secure key-value storage.
///
/// On mobile (iOS/Android): delegates to [FlutterSecureStorage] — encrypted
/// Keychain / EncryptedSharedPreferences.
///
/// On desktop (macOS/Windows/Linux): stores data in an AES-256-encrypted Hive
/// box (`secure_box_v2`). The AES key is derived once at startup and stored in
/// the system keychain via [FlutterSecureStorage] (macOS Keychain, Windows
/// Credential Manager, Linux libsecret). This avoids the synchronous-read
/// hangs that FSS can cause in sandboxed macOS apps when called repeatedly.
///
/// Call [SecureStorage.instance.initialize()] once at app startup before any
/// read/write operations.
abstract class SecureStorage {
  static SecureStorage? _instance;

  /// Returns the singleton instance, choosing the correct implementation for
  /// the current platform.
  static SecureStorage get instance =>
      _instance ??= PlatformUtils.instance.isDesktop
          ? SecureStorageDesktop()
          : SecureStorageMobile();

  /// Initializes the storage backend. Must be awaited before any [read] /
  /// [write] / [delete] calls.
  Future<void> initialize();

  /// Reads [key]. Returns `null` if not set.
  Future<String?> read(String key);

  /// Writes [value] under [key], overwriting any previous value.
  Future<void> write(String key, String value);

  /// Deletes [key]. No-op if absent.
  Future<void> delete(String key);

  /// Deletes all stored entries.
  Future<void> deleteAll();
}
