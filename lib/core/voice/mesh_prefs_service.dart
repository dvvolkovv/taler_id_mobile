import 'package:hive/hive.dart';

/// Tiny persistent prefs for mesh-related UI state. Currently holds the
/// iOS onboarding-tooltip flag and the Android battery-exemption prompt flag.
/// Kept as a separate service so future flags (e.g. user-preferred transport)
/// have a clear home.
///
/// Hive box: 'mesh_prefs'.
class MeshPrefsService {
  static const _boxName = 'mesh_prefs';
  static const _onboardingKey = 'onboarding_shown_v1';
  static const _batteryPromptKey = 'battery_prompt_shown_v1';

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

  Future<bool> isBatteryPromptShown() async {
    return (_box?.get(_batteryPromptKey) as bool?) ?? false;
  }

  Future<void> markBatteryPromptShown() async {
    await _box?.put(_batteryPromptKey, true);
  }
}
