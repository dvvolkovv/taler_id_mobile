import 'package:flutter/material.dart';
import 'package:taler_id_mobile/core/platform/secure_storage.dart';

/// Persists the user's preferred [ThemeMode] in [SecureStorage] under the key
/// `theme_mode`. Defaults to [ThemeMode.system] when nothing has been saved yet
/// or when the stored value is unrecognised.
class ThemeModeStorage {
  static const _key = 'theme_mode';
  final SecureStorage storage;

  ThemeModeStorage({SecureStorage? storage})
      : storage = storage ?? SecureStorage.instance;

  Future<ThemeMode> load() async {
    final raw = await storage.read(_key);
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    await storage.write(_key, mode.name);
  }
}
