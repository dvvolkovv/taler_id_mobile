import 'package:hive/hive.dart';

/// Tiny persistent prefs for mesh-related UI state. Currently only the
/// iOS onboarding-tooltip flag, but kept as a separate service so future
/// flags (e.g. user-preferred transport) have a clear home.
///
/// Hive box: 'mesh_prefs'. Single key 'onboarding_shown_v1'.
class MeshPrefsService {
  static const _boxName = 'mesh_prefs';
  static const _onboardingKey = 'onboarding_shown_v1';

  Box? _box;

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox(_boxName);
    }
  }

  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }

  Future<bool> isOnboardingShown() async {
    return (_box?.get(_onboardingKey) as bool?) ?? false;
  }

  Future<void> markOnboardingShown() async {
    await _box?.put(_onboardingKey, true);
  }
}
