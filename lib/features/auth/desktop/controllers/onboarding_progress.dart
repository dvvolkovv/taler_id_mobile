import 'package:taler_id_mobile/core/platform/secure_storage.dart';

/// Persists the per-user desktop onboarding interaction step under
/// `onboarding_step_desktop` in [SecureStorage].
///
/// Values:
///   - 0 — nothing handled yet (default)
///   - 1 — one permission row has been interacted with (granted or denied)
///   - 2 — both rows have been interacted with — "Продолжить" enables
///
/// Cleared on `_finish()` (whether the user pressed "Пропустить" or
/// "Продолжить"). The persisted value does NOT capture grant/deny outcomes —
/// only that the user has interacted. Re-rendering after a tray-close +
/// reopen treats interacted rows as neutral `handled` (no green/red dot).
class OnboardingProgress {
  OnboardingProgress._();

  static const _key = 'onboarding_step_desktop';

  static Future<int> getStep() async {
    final raw = await SecureStorage.instance.read(_key);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  static Future<void> saveStep(int step) async {
    await SecureStorage.instance.write(_key, step.toString());
  }

  static Future<void> clear() async {
    await SecureStorage.instance.delete(_key);
  }
}
