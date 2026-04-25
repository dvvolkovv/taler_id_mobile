import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import 'billing_event_bus.dart';

/// Result of [VoiceBillingBridge.start]: the backend-minted ephemeral
/// OpenAI Realtime client secret and the matching billing session id we
/// must reference in heartbeats and on close.
///
/// `clientSecret` is nullable to stay compatible with the current mobile
/// flow, which connects to the backend's WebSocket proxy using a JWT
/// instead of the raw OpenAI Realtime endpoint. When used with the proxy,
/// callers simply ignore the client secret and keep the session id for
/// billing bookkeeping.
@immutable
class VoiceSessionHandle {
  final String billingSessionId;
  final String? clientSecret;
  const VoiceSessionHandle({
    required this.billingSessionId,
    this.clientSecret,
  });
}

/// Thin wrapper that owns the billing side of a voice_assistant session:
///
///  1. [start] → POST /voice/session → captures `billingSessionId`, kicks
///     off a 10-second heartbeat loop and exposes [onTerminated] filtered
///     to the current session.
///  2. [stop] → POST /voice/session/:id/close with the caller-measured
///     duration, then cancels the heartbeat. Safe to call multiple times.
///
/// The bridge is intentionally decoupled from the WebRTC/WebSocket
/// transport: callers own the audio channel, the bridge only coordinates
/// metering with the backend. Heartbeats and the close call are
/// fire-and-forget in the sense that failures do not throw back into the
/// UI — they are logged at debug level. The backend's cron-based
/// metering + inactivity sweep is the source of truth.
class VoiceBillingBridge {
  final DioClient _dio;
  final BillingEventBus _eventBus;
  final Duration _heartbeatInterval;

  VoiceBillingBridge({
    required DioClient dio,
    required BillingEventBus eventBus,
    Duration heartbeatInterval = const Duration(seconds: 10),
  })  : _dio = dio,
        _eventBus = eventBus,
        _heartbeatInterval = heartbeatInterval;

  Timer? _heartbeat;
  String? _sessionId;
  DateTime? _startedAt;
  StreamSubscription<AiSessionTerminatedEvent>? _terminatedSub;
  StreamController<AiSessionTerminatedEvent>? _terminatedCtrl;
  bool _closing = false;

  /// ID of the active billing session, or `null` if no session is live.
  String? get sessionId => _sessionId;

  /// Broadcast stream of `ai_session_terminated` events for the *current*
  /// session only. Emits nothing until [start] has resolved. Consumers
  /// should subscribe after `await start()` returns.
  Stream<AiSessionTerminatedEvent> get onTerminated {
    _terminatedCtrl ??= StreamController<AiSessionTerminatedEvent>.broadcast();
    return _terminatedCtrl!.stream;
  }

  /// Opens a billing session and returns the handle. Throws on failure —
  /// the caller typically surfaces insufficient-funds (402) via the global
  /// Dio error interceptor, so nothing special is needed here.
  ///
  /// Re-entrant: if a previous session is still live, it is silently closed
  /// (with duration 0) before the new one starts.
  Future<VoiceSessionHandle> start() async {
    if (_sessionId != null) {
      // Defensive: a previous session wasn't properly torn down. Close it
      // with 0 seconds so the backend can finalize before we create a new one.
      await stop(durationSec: 0);
    }

    final data = await _dio.post<Map<String, dynamic>>(
      '/voice/session',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );

    final billingSessionId = data['billingSessionId'] as String?;
    final clientSecret = data['clientSecret'] as String?;
    if (billingSessionId == null || billingSessionId.isEmpty) {
      // Backend older than Task 10 of Plan 1 — session was opened OpenAI-side
      // but we have no billing handle. Still return something usable so the
      // assistant can talk; metering will remain on the cron estimate.
      debugPrint(
        '[VoiceBillingBridge] POST /voice/session returned no billingSessionId',
      );
      return VoiceSessionHandle(
        billingSessionId: '',
        clientSecret: clientSecret,
      );
    }

    _sessionId = billingSessionId;
    _startedAt = DateTime.now();
    _closing = false;
    _terminatedCtrl ??= StreamController<AiSessionTerminatedEvent>.broadcast();

    // Fan `ai_session_terminated` events for *this* session into our own
    // controller. The global bus multiplexes all users' sessions, the
    // bridge narrows it to the one we own.
    _terminatedSub = _eventBus.onSessionTerminated.listen((e) {
      if (e.sessionId == _sessionId) {
        _terminatedCtrl?.add(e);
      }
    });

    _startHeartbeat();
    return VoiceSessionHandle(
      billingSessionId: billingSessionId,
      clientSecret: clientSecret,
    );
  }

  /// Tears down the billing session. Calls `POST /voice/session/:id/close`
  /// with the caller-measured duration (falls back to our own stopwatch if
  /// [durationSec] is omitted) and cancels the heartbeat timer.
  ///
  /// Safe to call multiple times — subsequent invocations are no-ops.
  Future<void> stop({int? durationSec}) async {
    if (_closing) return;
    _closing = true;

    final id = _sessionId;
    _heartbeat?.cancel();
    _heartbeat = null;
    await _terminatedSub?.cancel();
    _terminatedSub = null;

    if (id == null || id.isEmpty) {
      _sessionId = null;
      _startedAt = null;
      return;
    }

    final secs = durationSec ??
        (_startedAt == null
            ? 0
            : DateTime.now().difference(_startedAt!).inSeconds);

    try {
      await _dio.post<dynamic>(
        '/voice/session/$id/close',
        data: {'durationSec': secs < 0 ? 0 : secs},
      );
    } catch (e) {
      // Close is best-effort: the cron inactivity sweep will eventually
      // finalize the session even if this fails.
      debugPrint('[VoiceBillingBridge] close failed for $id: $e');
    } finally {
      _sessionId = null;
      _startedAt = null;
    }
  }

  /// Call when the owning widget is disposed. Guarantees no further
  /// heartbeats fire and closes the terminated-events stream.
  Future<void> dispose() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _terminatedSub?.cancel();
    _terminatedSub = null;
    await _terminatedCtrl?.close();
    _terminatedCtrl = null;
    _sessionId = null;
    _startedAt = null;
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _tick());
  }

  Future<void> _tick() async {
    final id = _sessionId;
    if (id == null || id.isEmpty) return;
    try {
      await _dio.post<dynamic>(
        '/metering/heartbeat',
        data: {'sessionId': id},
      );
    } on ApiException catch (e) {
      // 404: session already gone. 410: session was terminated server-side.
      // Either way, stop beating and let the terminated-event handler (or
      // the next user action) drive teardown.
      if (e.statusCode == 404 || e.statusCode == 410) {
        debugPrint(
          '[VoiceBillingBridge] heartbeat ${e.statusCode} for $id — stopping timer',
        );
        _heartbeat?.cancel();
        _heartbeat = null;
      } else {
        debugPrint('[VoiceBillingBridge] heartbeat error: $e');
      }
    } catch (e) {
      // Network blips: keep trying on the next tick.
      debugPrint('[VoiceBillingBridge] heartbeat transient error: $e');
    }
  }
}
