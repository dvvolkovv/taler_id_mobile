import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../platform/platform_utils.dart';

/// Screen rotation on the call screen, and the user's choice to lock it.
///
/// The app is portrait-only (main.dart). A call screen lets the phone rotate —
/// unless the user pressed "Не поворачивать экран", which keeps it upright in
/// this call and the next ones. The choice lives in the `call_prefs` Hive box,
/// opened at start-up, so a call screen reads it synchronously and a locked
/// call never turns sideways even for a frame.
///
/// On iOS SystemChrome alone isn't enough: AppDelegate's
/// `supportedInterfaceOrientationsFor` answers portrait-only unless
/// `taler_id/orientation` → `setAllowAll(true)` flips it. The native flag is
/// sent only after SystemChrome has answered, so the two always arrive in
/// that order. Neither answer means the window has already turned — iOS 16+
/// sometimes misses the first request, hence [reapply].
///
/// Call screens are counted rather than flagged: re-entering a call while the
/// minimised screen is still animating out builds the new screen before the
/// old one is disposed, and the old one's [callScreenClosed] must not take
/// rotation away from the new one.
///
/// Callers fire and forget (`unawaited`), so nothing here throws: platform and
/// storage failures are logged and the app carries on.
class CallOrientationService {
  /// [openBox] is for tests; the app uses Hive.
  CallOrientationService({
    bool? isSupported,
    bool? isIOS,
    Future<Box> Function(String name)? openBox,
  })  : isSupported = isSupported ?? PlatformUtils.instance.isMobile,
        _isIOS = isIOS ?? PlatformUtils.instance.isIOS,
        _openBox = openBox ?? ((name) => Hive.openBox(name));

  static const _boxName = 'call_prefs';
  static const _lockedKey = 'rotation_locked_v1';
  static const _channel = MethodChannel('taler_id/orientation');

  /// Whether the screen rotates on this platform at all (iOS and Android).
  /// Elsewhere the button is hidden and nothing is applied.
  final bool isSupported;
  final bool _isIOS;
  final Future<Box> Function(String name) _openBox;

  final ValueNotifier<bool> _rotationLocked = ValueNotifier(false);

  /// The user's choice. The call screen's button listens to it; change it
  /// with [setRotationLocked], which also applies and stores it.
  ValueListenable<bool> get rotationLocked => _rotationLocked;

  Box? _box;
  int _openCallScreens = 0;

  /// Opens the storage and loads the choice. Never throws: without storage
  /// the choice lives in memory until the app restarts.
  Future<void> init() async {
    try {
      _box = await _openBox(_boxName);
    } catch (e) {
      debugPrint('[CallOrientation] call_prefs did not open, recreating: $e');
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _box = await _openBox(_boxName);
      } catch (e) {
        debugPrint('[CallOrientation] no storage, choice kept in memory: $e');
        _box = null;
      }
    }
    _rotationLocked.value = _box?.get(_lockedKey) == true;
  }

  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }

  /// A call screen opened: count it and apply the choice.
  Future<void> callScreenOpened() {
    _openCallScreens++;
    return _apply();
  }

  /// Applies the choice again without counting a screen. The call screen
  /// repeats it after its first frame: iOS 16+ doesn't always pick up a new
  /// set of orientations the first time.
  Future<void> reapply() =>
      _openCallScreens > 0 ? _apply() : Future<void>.value();

  /// A call screen closed — minimised or the call ended. The last one out
  /// puts the app back to portrait.
  Future<void> callScreenClosed() {
    if (_openCallScreens == 0) return Future<void>.value();
    _openCallScreens--;
    return _openCallScreens == 0
        ? _setFreeRotation(false)
        : Future<void>.value();
  }

  /// Applies the choice right away if a call screen is open — a screen lying
  /// sideways snaps back upright — then stores it.
  Future<void> setRotationLocked(bool locked) async {
    _rotationLocked.value = locked;
    if (_openCallScreens > 0) await _apply();
    try {
      await _box?.put(_lockedKey, locked);
    } catch (e) {
      debugPrint('[CallOrientation] choice not stored, kept in memory: $e');
    }
  }

  Future<void> _apply() => _setFreeRotation(!_rotationLocked.value);

  Future<void> _setFreeRotation(bool free) async {
    if (!isSupported) return;
    try {
      await SystemChrome.setPreferredOrientations(free
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp]);
    } catch (e) {
      debugPrint('[CallOrientation] setPreferredOrientations failed: $e');
    }
    if (_isIOS) {
      try {
        await _channel.invokeMethod('setAllowAll', free);
      } catch (e) {
        debugPrint('[CallOrientation] setAllowAll($free) failed: $e');
      }
    }
  }
}
