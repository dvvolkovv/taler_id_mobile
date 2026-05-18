import 'package:flutter/material.dart';
import 'theme_mode_storage.dart';

/// A [ValueNotifier] that holds the current [ThemeMode] and persists changes
/// to [ThemeModeStorage].
///
/// Create via [ThemeModeNotifier.create] which reads the persisted value before
/// constructing, so the initial value is always up-to-date.
class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  final ThemeModeStorage _storage;

  ThemeModeNotifier(this._storage, ThemeMode initial) : super(initial);

  /// Loads the persisted theme mode and returns a ready-to-use notifier.
  static Future<ThemeModeNotifier> create() async {
    final storage = ThemeModeStorage();
    final initial = await storage.load();
    return ThemeModeNotifier(storage, initial);
  }

  /// Updates the current theme mode and persists it.
  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    await _storage.save(mode);
  }
}
