import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import '../platform/secure_storage.dart';
import '../utils/constants.dart';

/// On mobile: uses [SecureStorage.instance] (backed by [FlutterSecureStorage]).
/// On web: uses Hive (localStorage-backed) since flutter_secure_storage's
/// SubtleCrypto encryption can hang during read operations.
class SecureStorageService {
  static const _webBoxName = 'auth_tokens';

  static Future<void> initWeb() async {
    if (kIsWeb) {
      await Hive.openBox(_webBoxName);
    }
  }

  Box? get _webBox => kIsWeb ? Hive.box(_webBoxName) : null;

  SecureStorage get _ss => SecureStorage.instance;

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
        _ss.write(ApiConstants.accessTokenKey, accessToken),
        _ss.write(ApiConstants.refreshTokenKey, refreshToken),
      ]);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.accessTokenKey) as String?;
    }
    try {
      return await _ss.read(ApiConstants.accessTokenKey);
    } catch (_) {
      // Corrupted keystore after reinstall — wipe all and return null
      try { await _ss.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.refreshTokenKey) as String?;
    }
    try {
      return await _ss.read(ApiConstants.refreshTokenKey);
    } catch (_) {
      try { await _ss.deleteAll(); } catch (_) {}
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
        _ss.delete(ApiConstants.accessTokenKey),
        _ss.delete(ApiConstants.refreshTokenKey),
      ]);
    }
  }

  Future<bool> get isBiometricEnabled async {
    if (kIsWeb) return false;
    final val = await _ss.read(ApiConstants.biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _ss.write(ApiConstants.biometricEnabledKey, enabled.toString());
  }

  Future<String?> getUserId() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.userIdKey) as String?;
    }
    return _ss.read(ApiConstants.userIdKey);
  }

  Future<void> saveUserId(String userId) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.userIdKey, userId);
    } else {
      await _ss.write(ApiConstants.userIdKey, userId);
    }
  }

  Future<bool> get hasRefreshToken async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> get isPinEnabled async {
    if (kIsWeb) return false;
    final val = await _ss.read(ApiConstants.pinEnabledKey);
    return val == 'true';
  }

  Future<void> setPinEnabled(bool enabled) async {
    if (kIsWeb) return;
    await _ss.write(ApiConstants.pinEnabledKey, enabled.toString());
  }

  Future<String?> getPinHash() async {
    if (kIsWeb) return null;
    return _ss.read(ApiConstants.pinHashKey);
  }

  Future<void> savePinHash(String hash) async {
    if (kIsWeb) return;
    await _ss.write(ApiConstants.pinHashKey, hash);
  }

  Future<void> clearPin() async {
    if (kIsWeb) return;
    await Future.wait([
      _ss.delete(ApiConstants.pinHashKey),
      _ss.delete(ApiConstants.pinEnabledKey),
    ]);
  }

  Future<String?> getLanguage() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.languageKey) as String?;
    }
    return _ss.read(ApiConstants.languageKey);
  }

  Future<void> saveLanguage(String lang) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.languageKey, lang);
    } else {
      await _ss.write(ApiConstants.languageKey, lang);
    }
  }

  Future<String?> getThemeMode() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.themeKey) as String?;
    }
    return _ss.read(ApiConstants.themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.themeKey, mode);
    } else {
      await _ss.write(ApiConstants.themeKey, mode);
    }
  }

  Future<String?> getWallpaper() async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.wallpaperKey) as String?;
    }
    return _ss.read(ApiConstants.wallpaperKey);
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
        await _ss.delete(ApiConstants.wallpaperKey);
      } else {
        await _ss.write(ApiConstants.wallpaperKey, id);
      }
    }
  }

  Future<bool> get isOnboardingSeen async {
    if (kIsWeb) {
      return _webBox?.get(ApiConstants.onboardingSeenKey) == 'true';
    }
    final val = await _ss.read(ApiConstants.onboardingSeenKey);
    return val == 'true';
  }

  Future<void> setOnboardingSeen() async {
    if (kIsWeb) {
      await _webBox?.put(ApiConstants.onboardingSeenKey, 'true');
    } else {
      await _ss.write(ApiConstants.onboardingSeenKey, 'true');
    }
  }

  Future<void> clearOnboardingSeen() async {
    if (kIsWeb) {
      await _webBox?.delete(ApiConstants.onboardingSeenKey);
    } else {
      await _ss.delete(ApiConstants.onboardingSeenKey);
    }
  }

  // Badge seen counts — persist across app restarts
  Future<int> getSeenMissedCalls() async {
    final v = kIsWeb
        ? _webBox?.get('seen_missed_calls') as String?
        : await _ss.read('seen_missed_calls');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setSeenMissedCalls(int count) async {
    if (kIsWeb) {
      await _webBox?.put('seen_missed_calls', '$count');
    } else {
      await _ss.write('seen_missed_calls', '$count');
    }
  }

  Future<int> getSeenCalendarInvites() async {
    final v = kIsWeb
        ? _webBox?.get('seen_calendar_invites') as String?
        : await _ss.read('seen_calendar_invites');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<void> setSeenCalendarInvites(int count) async {
    if (kIsWeb) {
      await _webBox?.put('seen_calendar_invites', '$count');
    } else {
      await _ss.write('seen_calendar_invites', '$count');
    }
  }

  static const _mailSetupDismissedKey = 'mail_setup_dismissed';

  Future<bool> get isMailSetupDismissed async {
    if (kIsWeb) {
      return _webBox?.get(_mailSetupDismissedKey) == 'true';
    }
    final val = await _ss.read(_mailSetupDismissedKey);
    return val == 'true';
  }

  Future<void> setMailSetupDismissed() async {
    if (kIsWeb) {
      await _webBox?.put(_mailSetupDismissedKey, 'true');
    } else {
      await _ss.write(_mailSetupDismissedKey, 'true');
    }
  }

  static const _mailSetupConfirmedKey = 'mail_setup_confirmed';

  /// Returns true if the user has already successfully created a mailbox on
  /// this device. Used to skip the `getAccount()` network call on every login.
  Future<bool> get isMailSetupConfirmed async {
    if (kIsWeb) {
      return _webBox?.get(_mailSetupConfirmedKey) == 'true';
    }
    final val = await _ss.read(_mailSetupConfirmedKey);
    return val == 'true';
  }

  Future<void> setMailSetupConfirmed() async {
    if (kIsWeb) {
      await _webBox?.put(_mailSetupConfirmedKey, 'true');
    } else {
      await _ss.write(_mailSetupConfirmedKey, 'true');
    }
  }

  /// Generic key-value read. Returns null if not set.
  Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webBox?.get(key) as String?;
    }
    return _ss.read(key);
  }

  /// Generic key-value write.
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      await _webBox?.put(key, value);
    } else {
      await _ss.write(key, value);
    }
  }
}
