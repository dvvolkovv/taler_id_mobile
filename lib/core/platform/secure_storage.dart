// lib/core/platform/secure_storage.dart
import 'package:flutter/foundation.dart';

import 'platform_utils.dart';
import 'secure_storage_mobile.dart';
import 'secure_storage_desktop.dart';

/// Platform-dispatched secure storage abstraction.
///
/// On mobile (iOS/Android): delegates to [FlutterSecureStorage] — encrypted
/// Keychain / EncryptedSharedPreferences. [initialize] is a no-op — [read]/
/// [write] work without it.
///
/// On desktop (macOS/Windows/Linux): stores data in an AES-256-encrypted Hive
/// box (`secure_box_v2`). The AES key is derived once at startup and stored in
/// the system keychain via [FlutterSecureStorage] (macOS Keychain, Windows
/// Credential Manager, Linux libsecret). This avoids the synchronous-read
/// hangs that FSS can cause in sandboxed macOS apps when called repeatedly.
/// [initialize] MUST be called before any read/write call; it opens the
/// encrypted Hive box that backs all operations.
///
/// In the main isolate, [initialize] is called from `main()` before
/// `setupDependencies()`. Background isolates (e.g. the FCM background
/// handler) do NOT inherit the main isolate's initialized state because
/// `_instance` is per-isolate. Background isolates should only call this
/// abstraction on mobile platforms, where [initialize] is a no-op.
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

  /// Resets the cached singleton so the next [instance] access creates a fresh
  /// implementation. **Test use only** — never call in production code.
  @visibleForTesting
  static void debugResetForTest() {
    _instance = null;
  }

  /// Overrides the singleton with a test double. **Test use only** — never
  /// call in production code. Call [debugResetForTest] in `tearDown` to clean
  /// up.
  @visibleForTesting
  static set debugInstance(SecureStorage instance) {
    _instance = instance;
  }
}
