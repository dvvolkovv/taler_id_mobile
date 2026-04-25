import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

/// On mobile: uses FlutterSecureStorage (encrypted keychain/keystore).
/// On web: uses Hive (localStorage-backed) since flutter_secure_storage's
/// SubtleCrypto encryption can hang during read operations.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _webBoxName = 'auth_tokens';

  static Future<void> initWeb() async {
    if (kIsWeb) {
      await Hive.openBox(_webBoxName);
    }
  }

  Box? get _webBox => kIsWeb ? Hive.box(_webBoxName) : null;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final box = _webBox!;
      await box.put(ApiConstants.accessTokenKey, accessToken);
      await box.put(ApiConstants.refreshTokenKey, refreshToken);
    } else {
      await Future.wait([
        _storage.write(key: ApiConstants.accessTokenKey, value: accessToken),
        _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken),
      ]);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.accessTokenKey) as String?;
    }
    try {
      return await _storage.read(key: ApiConstants.accessTokenKey);
    } catch (_) {
      // Corrupted keystore after reinstall — wipe all and return null
      try { await _storage.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.refreshTokenKey) as String?;
    }
    try {
      return await _storage.read(key: ApiConstants.refreshTokenKey);
    } catch (_) {
      try { await _storage.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final box = _webBox!;
      await box.delete(ApiConstants.accessTokenKey);
      await box.delete(ApiConstants.refreshTokenKey);
    } else {
      await Future.wait([
        _storage.delete(key: ApiConstants.accessTokenKey),
        _storage.delete(key: ApiConstants.refreshTokenKey),
      ]);
    }
  }

  Future<bool> get isBiometricEnabled async {
    if (kIsWeb) return false;
    final val = await _storage.read(key: ApiConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _storage.write(key: ApiConstants.biometricEnabledKey, value: enabled.toString());
  }

  Future<String?> getUserId() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.userIdKey) as String?;
    }
    return _storage.read(key: ApiConstants.userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.userIdKey, userId);
    } else {
      await _storage.write(key: ApiConstants.userIdKey, value: userId);
    }
  }

  Future<bool> get hasRefreshToken async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> get isPinEnabled async {
    if (kIsWeb) return false;
    final val = await _storage.read(key: ApiConstants.pinEnabledKey);
    return val == 'true';
  }

  Future<void> setPinEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _storage.write(key: ApiConstants.pinEnabledKey, value: enabled.toString());
  }

  Future<String?> getPinHash() async {
    if (kIsWeb) return null;
    return _storage.read(key: ApiConstants.pinHashKey);
  }

  Future<void> savePinHash(String hash) async {
    if (kIsWeb) return;
    await _storage.write(key: ApiConstants.pinHashKey, value: hash);
  }

  Future<void> clearPin() async {
    if (kIsWeb) return;
    await Future.wait([
      _storage.delete(key: ApiConstants.pinHashKey),
      _storage.delete(key: ApiConstants.pinEnabledKey),
    ]);
  }

  Future<String?> getLanguage() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.languageKey) as String?;
    }
    return _storage.read(key: ApiConstants.languageKey);
  }

  Future<void> saveLanguage(String lang) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.languageKey, lang);
    } else {
      await _storage.write(key: ApiConstants.languageKey, value: lang);
    }
  }

  Future<String?> getThemeMode() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.themeKey) as String?;
    }
    return _storage.read(key: ApiConstants.themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.themeKey, mode);
    } else {
      await _storage.write(key: ApiConstants.themeKey, value: mode);
    }
  }

  Future<String?> getWallpaper() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.wallpaperKey) as String?;
    }
    return _storage.read(key: ApiConstants.wallpaperKey);
  }

  Future<void> saveWallpaper(String? id) async {
    if (kIsWeb) {
      if (id == null) {
        await _webBox?.delete(ApiConstants.wallpaperKey);
      } else {
        await _webBox?.put(ApiConstants.wallpaperKey, id);
      }
    } else {
      if (id == null) {
        await _storage.delete(key: ApiConstants.wallpaperKey);
      } else {
        await _storage.write(key: ApiConstants.wallpaperKey, value: id);
      }
    }
  }

  Future<bool> get isOnboardingSeen async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.onboardingSeenKey) == 'true';
    }
    final val = await _storage.read(key: ApiConstants.onboardingSeenKey);
    return val == 'true';
  }

  Future<void> setOnboardingSeen() async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.onboardingSeenKey, 'true');
    } else {
      await _storage.write(key: ApiConstants.onboardingSeenKey, value: 'true');
    }
  }

  Future<void> clearOnboardingSeen() async {
    if (kIsWeb) {
      await _webBox?.delete(ApiConstants.onboardingSeenKey);
    } else {
      await _storage.delete(key: ApiConstants.onboardingSeenKey);
    }
  }

  // Badge seen counts — persist across app restarts
  Future<int> getSeenMissedCalls() async {
    final v = kIsWeb ? _webBox?.get('seen_missed_calls') as String? : await _storage.read(key: 'seen_missed_calls');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setSeenMissedCalls(int count) async {
    if (kIsWeb) {
      await _webBox?.put('seen_missed_calls', '$count');
    } else {
      await _storage.write(key: 'seen_missed_calls', value: '$count');
    }
  }

  Future<int> getSeenCalendarInvites() async {
    final v = kIsWeb ? _webBox?.get('seen_calendar_invites') as String? : await _storage.read(key: 'seen_calendar_invites');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setSeenCalendarInvites(int count) async {
    if (kIsWeb) {
      await _webBox?.put('seen_calendar_invites', '$count');
    } else {
      await _storage.write(key: 'seen_calendar_invites', value: '$count');
    }
  }

  /// Generic key-value read. Returns null if not set.
  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webBox?.get(key) as String?;
    }
    return _storage.read(key: key);
  }

  /// Generic key-value write.
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      await _webBox?.put(key, value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }
}
