import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taler_id_mobile/core/platform/platform_utils.dart';

/// Desktop OS toast notifications for new messages and incoming calls.
///
/// Supports macOS (DarwinNotificationDetails) and Linux
/// (LinuxNotificationDetails). Windows is not yet supported by the
/// flutter_local_notifications package (v18.x) — wiring is a no-op on Windows.
///
/// Lifecycle: call [initialize] once from main() after the tray service.
/// Then call [showMessage] / [showCallInvite] from any socket event handler.
class DesktopNotificationsService {
  static final DesktopNotificationsService instance =
      DesktopNotificationsService._();
  DesktopNotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String routePayload)? _onTap;

  Future<void> initialize({void Function(String routePayload)? onTap}) async {
    if (!PlatformUtils.instance.isDesktop) return;
    if (_initialized) return;
    _onTap = onTap;

    const macInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxInit =
        LinuxInitializationSettings(defaultActionName: 'Open Taler ID');

    await _plugin.initialize(
      const InitializationSettings(macOS: macInit, linux: linuxInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && _onTap != null) _onTap!(payload);
      },
    );
    _initialized = true;
  }

  Future<void> showMessage({
    required String title,
    required String body,
    required String routePayload,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _hashId(routePayload),
      title,
      body,
      const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      payload: routePayload,
    );
  }

  Future<void> showCallInvite({
    required String callerName,
    required String routePayload,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      _hashId(routePayload),
      'Входящий звонок',
      callerName,
      const NotificationDetails(
        macOS: DarwinNotificationDetails(
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.critical,
        ),
      ),
      payload: routePayload,
    );
  }

  int _hashId(String s) => s.hashCode & 0x7fffffff;
}
