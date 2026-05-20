import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'models/captured_notification.dart';
import 'notification_filter.dart';
import 'notification_platform.dart';

/// Dart-side facade over the native `NotificationStoreNative` ring buffer.
///
/// Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
///
/// Design notes:
///  * The native side is the single source of truth (~200 entry ring buffer
///    in the listener process). [recent] just forwards to `getRecent` and lets
///    the native side apply the filter.
///  * The Dart-side cache (last ~50 events delivered via the event stream) is
///    used exclusively for the defensive key-check inside [replyOnKey]. If
///    a caller asks to reply to a key the Dart side hasn't seen we log a
///    warning but still forward the request — the native buffer may be ahead
///    of the Dart subscription.
///  * Streaming events also push into the cache so a `recent()` call made
///    before the very first `getRecent` round-trip isn't completely blind.
class NotificationStore {
  static const int _cacheLimit = 50;

  final NotificationPlatform _platform;
  final Queue<CapturedNotification> _cache = Queue<CapturedNotification>();
  late final StreamSubscription<CapturedNotification> _sub;
  final StreamController<CapturedNotification> _outbound =
      StreamController<CapturedNotification>.broadcast();

  NotificationStore(this._platform) {
    _sub = _platform.notificationStream.listen(
      _onEvent,
      onError: (Object e, StackTrace st) {
        debugPrint('NotificationStore: stream error: $e');
      },
    );
  }

  /// Public broadcast stream — multiple consumers (e.g. Task-9 feed widget
  /// + tool dispatcher) can subscribe without competing for events.
  Stream<CapturedNotification> get stream => _outbound.stream;

  /// Fetch recent notifications matching [filter] from the native store.
  Future<List<CapturedNotification>> recent(NotificationFilter filter) {
    return _platform.getRecent(filter);
  }

  /// Reply to the notification identified by [key].
  ///
  /// Throws [NotificationReplyException] if the native side returns
  /// `{ok: false}`. If [key] is not in the local cache, logs a warning via
  /// [debugPrint] but still forwards the request — the native buffer may
  /// have entries the Dart subscription has not yet seen.
  Future<void> replyOnKey(String key, String text) async {
    final knownLocally = _cache.any((n) => n.key == key);
    if (!knownLocally) {
      debugPrint(
        'NotificationStore.replyOnKey: key "$key" not in local cache '
        '(${_cache.length} entries) — forwarding to native anyway.',
      );
    }
    final result = await _platform.reply(key: key, text: text);
    final ok = result['ok'] == true;
    if (!ok) {
      final error = (result['error'] as String?) ?? 'unknown_error';
      final message = result['message'] as String?;
      throw NotificationReplyException(
        error: error,
        message: message,
      );
    }
  }

  /// Visible for testing — read-only snapshot of the in-process cache.
  @visibleForTesting
  List<CapturedNotification> get debugCache => List.unmodifiable(_cache);

  Future<void> dispose() async {
    await _sub.cancel();
    await _outbound.close();
  }

  void _onEvent(CapturedNotification n) {
    _cache.addLast(n);
    while (_cache.length > _cacheLimit) {
      _cache.removeFirst();
    }
    if (!_outbound.isClosed) {
      _outbound.add(n);
    }
  }
}

/// Thrown by [NotificationStore.replyOnKey] when the native side reports
/// `{ok: false}`. The [error] mirrors the native error code (e.g.
/// `no_such_key`, `no_reply_action`, `pending_intent_failed`).
class NotificationReplyException implements Exception {
  final String error;
  final String? message;

  const NotificationReplyException({required this.error, this.message});

  @override
  String toString() {
    if (message == null || message!.isEmpty) {
      return 'NotificationReplyException: $error';
    }
    return 'NotificationReplyException: $error ($message)';
  }
}
