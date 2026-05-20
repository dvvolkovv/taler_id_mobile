import 'dart:async';

import 'notification_platform.dart';

/// Tracks whether the user has granted `BIND_NOTIFICATION_LISTENER_SERVICE`.
///
/// Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
///
/// The OS does not push a "permission changed" event, so this service is
/// poll-based: callers (the onboarding banner) hit [refresh] whenever they
/// have a reason to suspect the state may have changed — typically on
/// `AppLifecycleState.resumed` after the user returned from the Settings
/// activity.
class NotificationPermissionService {
  final NotificationPlatform _platform;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool? _last;

  NotificationPermissionService(this._platform);

  /// One-shot read. Updates [current] and may emit on [watch] if the value
  /// changed.
  Future<bool> isGranted() async {
    final value = await _platform.isNotificationAccessGranted();
    _publish(value);
    return value;
  }

  /// Launch the system Settings activity where the access toggle lives.
  Future<void> openSettings() => _platform.openNotificationAccessSettings();

  /// Re-poll the OS and broadcast the new value (de-duplicated).
  /// Call from `AppLifecycleState.resumed`.
  Future<void> refresh() async {
    await isGranted();
  }

  /// Last observed value, or `null` if we've never polled.
  bool? get current => _last;

  /// Broadcast stream — emits when [refresh] / [isGranted] observe a value
  /// different from the previous one. New subscribers do NOT receive a
  /// replay; pair with [current] for initial state.
  Stream<bool> watch() => _controller.stream;

  Future<void> dispose() => _controller.close();

  void _publish(bool value) {
    if (_last == value) return;
    _last = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }
}
