import 'dart:async';

import 'package:flutter/services.dart';

import 'models/captured_notification.dart';
import 'notification_filter.dart';

/// Thin abstraction over the `taler_id/notifications/{cmd,stream}` channels.
///
/// Production code wires [MethodChannelNotificationPlatform]. Tests substitute
/// a plain in-memory fake — no Mocktail. The interface is intentionally tiny
/// so the fake stays trivial.
abstract class NotificationPlatform {
  /// `true` if the user has granted `BIND_NOTIFICATION_LISTENER_SERVICE`.
  Future<bool> isNotificationAccessGranted();

  /// Open the system Settings screen where the access toggle lives.
  /// Returns when the activity has been launched (not when the user returns).
  Future<void> openNotificationAccessSettings();

  /// Query the native ring buffer. Returns already-decoded
  /// [CapturedNotification]s — the filter is sent across the wire so the
  /// native side does the matching (it owns the full 200-entry buffer).
  Future<List<CapturedNotification>> getRecent(NotificationFilter filter);

  /// Fire an inline reply on the notification identified by [key].
  /// Returns the raw `{ok, error?, message?}` map from the native side so the
  /// caller can decide how to react (the store throws on `ok: false`).
  Future<Map<String, dynamic>> reply({required String key, required String text});

  /// Live stream of admitted notifications. One event per incoming push that
  /// passed echo suppression on the native side.
  Stream<CapturedNotification> get notificationStream;
}

/// Production implementation backed by Flutter platform channels.
class MethodChannelNotificationPlatform implements NotificationPlatform {
  static const _methodChannelName = 'taler_id/notifications/cmd';
  static const _eventChannelName = 'taler_id/notifications/stream';

  final MethodChannel _method;
  final EventChannel _events;
  Stream<CapturedNotification>? _decodedStream;

  MethodChannelNotificationPlatform({
    MethodChannel? method,
    EventChannel? events,
  })  : _method = method ?? const MethodChannel(_methodChannelName),
        _events = events ?? const EventChannel(_eventChannelName);

  @override
  Future<bool> isNotificationAccessGranted() async {
    final res = await _method.invokeMethod<bool>('isNotificationAccessGranted');
    return res ?? false;
  }

  @override
  Future<void> openNotificationAccessSettings() async {
    await _method.invokeMethod<void>('openNotificationAccessSettings');
  }

  @override
  Future<List<CapturedNotification>> getRecent(NotificationFilter filter) async {
    final raw = await _method.invokeMethod<List<dynamic>>(
      'getRecent',
      filter.toMethodArgs(),
    );
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((m) => CapturedNotification.fromMap(m))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> reply({
    required String key,
    required String text,
  }) async {
    final raw = await _method.invokeMethod<Map<dynamic, dynamic>>(
      'reply',
      <String, dynamic>{'key': key, 'text': text},
    );
    if (raw == null) {
      return {'ok': false, 'error': 'null_response'};
    }
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }

  @override
  Stream<CapturedNotification> get notificationStream {
    return _decodedStream ??= _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => CapturedNotification.fromMap(event as Map))
        .asBroadcastStream();
  }
}
