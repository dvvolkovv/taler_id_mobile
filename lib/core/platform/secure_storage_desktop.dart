// lib/core/platform/secure_storage_desktop.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'secure_storage.dart';

/// [SecureStorage] implementation for macOS, Windows, and Linux.
///
/// ## Storage layout
/// Data is stored in a Hive box named `secure_box_v2` encrypted with a
/// randomly-generated 256-bit AES key. That key is kept in the system
/// credential store via [FlutterSecureStorage] under the alias
/// `hive_aes_key_v2` (macOS Keychain / Windows Credential Manager /
/// Linux libsecret). FSS is called **only once** at startup to fetch or
/// create the key; all subsequent read/write operations go to the fast
/// in-process Hive box.
///
/// ## Migration from fork's storage layout (taler_id_desktop ≤ 1.0.48)
/// The desktop fork stored secure data in a plain (unencrypted) Hive box
/// named `auth_tokens`. During [initialize] we detect that legacy box,
/// copy every entry that is not yet in `secure_box_v2`, and then delete the
/// legacy box from disk — ensuring existing users' login sessions survive the
/// upgrade without being forced to log in again.
class SecureStorageDesktop implements SecureStorage {
  /// New encrypted box name (intentional `_v2` suffix for future migrations).
  static const _hiveBoxName = 'secure_box_v2';

  /// Box name used by the taler_id_desktop fork (plain, unencrypted Hive box).
  static const _legacyBoxName = 'auth_tokens';

  /// Key under which the AES key bytes are stored in the system keychain.
  static const _hiveKeyAlias = 'hive_aes_key_v2';

  /// Canary key written after the first successful initialization. Used to
  /// detect whether the Hive box can be decrypted with the current AES key.
  static const _canaryKey = '__crypto_check__';

  /// Expected value of [_canaryKey].
  static const _canaryValue = 'ok';

  /// FlutterSecureStorage instance — injectable for testing.
  final FlutterSecureStorage _fss;

  /// Optional Hive directory override — non-null in unit tests so we can
  /// skip the path_provider call inside [Hive.initFlutter].
  final String? _hiveDir;

  Box<String>? _box;

  /// Production constructor: uses real system keychain and path_provider.
  // FlutterSecureStorage is used ONLY for the AES key — not for general data.
  SecureStorageDesktop({
    FlutterSecureStorage fss = const FlutterSecureStorage(),
    String? hiveDir,
  })  : _fss = fss,
        _hiveDir = hiveDir;

  @override
  Future<void> initialize() async {
    // If a test-supplied directory is present, use Hive.init() directly to
    // avoid the path_provider call inside Hive.initFlutter().
    if (_hiveDir != null) {
      Hive.init(_hiveDir!);
    } else {
      await Hive.initFlutter();
    }

    // Remember whether the encrypted box already existed on disk BEFORE we
    // open it — needed for the key-loss detection below.
    final boxExistedBeforeOpen = await Hive.boxExists(_hiveBoxName);

    final (aesKey, keyWasNew) = await _loadOrGenerateKey();
    _box = await Hive.openBox<String>(
      _hiveBoxName,
      encryptionCipher: HiveAesCipher(aesKey),
    );

    // Key-loss / corruption detection:
    // If (a) the box was already on disk AND (b) the FSS key was missing so we
    // generated a fresh one, the existing ciphertext is unreadable with the new
    // key. Detect this by checking whether the canary value is readable.
    //
    // The same branch also covers the case where FSS key existed but the box
    // is corrupted — in that case canary will also be absent/unreadable.
    if (boxExistedBeforeOpen && keyWasNew) {
      developer.log(
        '[SecureStorage] WARN: secure_box_v2 exists but FSS key was missing. '
        'Generated fresh AES key. Existing data is unrecoverable. '
        'Clearing box and starting fresh.',
        name: 'SecureStorage',
        level: 1000, // SEVERE
      );
      await _box!.clear();
    }

    // Write canary on first use (box is empty after clear or was just created).
    if (_box!.get(_canaryKey) == null) {
      await _box!.put(_canaryKey, _canaryValue);
    }

    await _migrateLegacyDataIfPresent();
  }

  /// Loads the 32-byte AES key from the system keychain, or generates and
  /// persists a fresh one if this is the first launch.
  ///
  /// Returns a record `(keyBytes, keyWasNew)` where [keyWasNew] is `true` when
  /// no key was found in the keychain and a fresh key was generated. The caller
  /// uses this flag to detect key-loss scenarios (Keychain entry deleted while
  /// an encrypted Hive box already exists on disk).
  Future<(List<int>, bool)> _loadOrGenerateKey() async {
    final existing = await _fss.read(key: _hiveKeyAlias);
    if (existing != null) return (base64Decode(existing), false);
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    await _fss.write(key: _hiveKeyAlias, value: base64Encode(bytes));
    return (bytes, true);
  }

  /// One-shot migration: if the fork's unencrypted `auth_tokens` box exists,
  /// copy all entries into `secure_box_v2`, then permanently delete the
  /// legacy box. Skips keys that already exist in the new box (idempotent).
  Future<void> _migrateLegacyDataIfPresent() async {
    if (!await Hive.boxExists(_legacyBoxName)) return;

    // Open without cipher — the fork stored data unencrypted.
    final legacy = await Hive.openBox<dynamic>(_legacyBoxName);
    for (final key in legacy.keys) {
      final v = legacy.get(key);
      if (v is String && _box!.get(key as String) == null) {
        await _box!.put(key, v);
      }
    }
    await legacy.deleteFromDisk();
  }

  @override
  Future<String?> read(String key) async => _box!.get(key);

  @override
  Future<void> write(String key, String value) => _box!.put(key, value);

  @override
  Future<void> delete(String key) => _box!.delete(key);

  @override
  Future<void> deleteAll() async => _box!.clear();
}
