import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart'
    as ck_event;
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../mesh/transport/peer_id.dart';
import '../mesh/voice/mesh_voice_state.dart';
import '../notifications/notification_service.dart';
import '../../features/call_history/data/mesh_call_history_entry.dart';
import '../../features/call_history/data/mesh_call_history_repository.dart';
import '../../features/voice/presentation/screens/mesh_voice_call_screen.dart';
import '../../features/voice/presentation/widgets/mesh_incoming_call_sheet.dart';

/// Thin abstraction over `globalNavigatorKey` so unit tests can inject a spy.
abstract class MeshNavigator {
  Future<T?> pushScreen<T>(Widget screen);
  Future<void> showSheet(Widget sheet);
  void popSheet();
  void popScreen();
  void showSnackbar(String message);
}

class MeshPeerInfo {
  final String? userId;
  final String? name;
  final String? avatarUrl;
  const MeshPeerInfo({this.userId, this.name, this.avatarUrl});
}

/// Singleton UI controller for mesh voice calls.
class MeshVoiceUiCoordinator {
  final Stream<CallState> stateStream;
  final Future<int> Function(PeerId peer) invite;
  final Future<void> Function() accept;
  final Future<void> Function() reject;
  final Future<void> Function() hangup;
  final MeshCallHistoryRepository repo;
  final MeshNavigator navigator;
  final Future<MeshPeerInfo> Function(PeerId peer) peerInfoLookup;
  final PeerId selfDevicePk;
  final String? Function(PeerId peer) transportLabelForPeer;

  StreamSubscription<CallState>? _sub;
  StreamSubscription<dynamic>? _callkitSub;
  _PendingCall? _pending;

  /// For tests: override the lifecycle state. Production reads from WidgetsBinding.
  AppLifecycleState? debugLifecycleState;

  /// For tests: override platform detection. Production uses Platform.isAndroid.
  bool? debugIsAndroid;

  MeshVoiceUiCoordinator({
    required this.stateStream,
    required this.invite,
    required this.accept,
    required this.reject,
    required this.hangup,
    required this.repo,
    required this.navigator,
    required this.peerInfoLookup,
    required this.selfDevicePk,
    required this.transportLabelForPeer,
  });

  void start() {
    _sub ??= stateStream.listen(_onState);
    try {
      // Subscribe to the broadcast stream fed by main.dart's single
      // `FlutterCallkitIncoming.onEvent` listener — accessing `.onEvent`
      // directly REPLACES the underlying EventChannel handler, which
      // silently disconnected main.dart's central router so 1-on-1 and
      // server-routed group call accepts no longer triggered any navigation.
      _callkitSub ??= NotificationService.callEvents.listen(_onCallkitEvent);
    } catch (_) {
      // EventChannel requires ServicesBinding; silently skip in unit tests.
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    try {
      await _callkitSub?.cancel();
    } catch (_) {
      // EventChannel cancel may fail in tests without a platform mock.
    }
    _sub = null;
    _callkitSub = null;
  }

  bool _isAppInForeground() {
    if (debugLifecycleState != null) {
      return debugLifecycleState == AppLifecycleState.resumed;
    }
    AppLifecycleState? state;
    try {
      state = WidgetsBinding.instance.lifecycleState;
    } catch (_) {
      // Binding not yet initialized (e.g. unit tests without ensureInitialized).
      // Default to foreground so the existing sheet path is used.
      return true;
    }
    // null means the app has not yet received a lifecycle event — treat as
    // foreground so the sheet path (the pre-existing behavior) is preserved.
    if (state == null) return true;
    return state == AppLifecycleState.resumed;
  }

  bool _isAndroid() => debugIsAndroid ?? (!kIsWeb && Platform.isAndroid);

  Future<void> _showCallkitIncoming(
      IncomingState st, MeshPeerInfo info) async {
    if (!_isAndroid()) return;
    final fallback =
        'Mesh-устройство ${st.callerDevicePk.toHex().substring(0, 8)}';
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: st.callId.toString(),
        nameCaller: info.name ?? fallback,
        handle: '📡 Mesh',
        type: 0,
        avatar: info.avatarUrl,
        extra: {'mesh_call_id': st.callId},
      ));
    } catch (_) {
      // Plugin may throw if FCM-only mode or notification permission denied.
      // Fall through silently — mesh state machine still tracks the call.
    }
  }

  void _onCallkitEvent(dynamic event) {
    if (event == null) return;
    final body = (event as ck_event.CallEvent).body;
    if (body is! Map) return;
    final extra = body['extra'];
    if (extra is! Map) return;
    if (extra['mesh_call_id'] == null) return;
    final eventType = event.event;
    if (eventType == ck_event.Event.actionCallAccept) {
      accept();
    } else if (eventType == ck_event.Event.actionCallDecline ||
        eventType == ck_event.Event.actionCallTimeout) {
      reject();
    }
  }

  /// Initiate a mesh call to [peer]. Returns the generated call id, or
  /// `null` if the call could not be started (loopback, busy, etc.).
  Future<int?> placeCall(PeerId peer) async {
    if (_bytesEqual(peer.bytes, selfDevicePk.bytes)) return null;
    try {
      return await invite(peer);
    } on StateError {
      navigator.showSnackbar('Звонок уже идёт');
      return null;
    }
  }

  void _onState(CallState st) {
    if (st is InvitingState) {
      _handleInviting(st);
    } else if (st is IncomingState) {
      _handleIncoming(st);
    } else if (st is ActiveState) {
      _handleActive(st);
    } else if (st is EndedState) {
      _handleEnded(st);
    }
  }

  Future<void> _handleInviting(InvitingState st) async {
    final info = await peerInfoLookup(st.calleeDevicePk);
    _pending = _PendingCall(
      callId: st.callId,
      peer: st.calleeDevicePk,
      peerUserId: info.userId,
      peerName: info.name,
      peerAvatarUrl: info.avatarUrl,
      isOutgoing: true,
      startedAt: st.sentAt,
      transport: transportLabelForPeer(st.calleeDevicePk),
    );
    if (_pending?.screenPushed == true) return;
    _pending?.screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(
      stateStream: stateStream,
      initialState: st,
      peer: st.calleeDevicePk,
      peerName: info.name,
      peerAvatarUrl: info.avatarUrl,
      transportName: transportLabelForPeer(st.calleeDevicePk),
      onMuteToggle: () async {},
      onHangup: hangup,
    ));
  }

  Future<void> _handleIncoming(IncomingState st) async {
    final info = await peerInfoLookup(st.callerDevicePk);
    _pending = _PendingCall(
      callId: st.callId,
      peer: st.callerDevicePk,
      peerUserId: info.userId,
      peerName: info.name,
      peerAvatarUrl: info.avatarUrl,
      isOutgoing: false,
      startedAt: st.receivedAt,
      transport: transportLabelForPeer(st.callerDevicePk),
    );
    if (_isAppInForeground()) {
      await navigator.showSheet(MeshIncomingCallSheet(
        peer: st.callerDevicePk,
        peerName: info.name,
        peerAvatarUrl: info.avatarUrl,
        onAccept: () => accept(),
        onDecline: () => reject(),
      ));
    } else {
      await _showCallkitIncoming(st, info);
    }
  }

  Future<void> _handleActive(ActiveState st) async {
    final p = _pending;
    if (p != null && p.callId == st.callId) {
      p.activatedAt = st.startedAt;
    }
    if (p?.screenPushed == true) return; // caller side already has the screen
    navigator.popSheet();
    p?.screenPushed = true;
    await navigator.pushScreen(MeshVoiceCallScreen(
      stateStream: stateStream,
      initialState: st,
      peer: st.peerDevicePk,
      peerName: p?.peerName,
      peerAvatarUrl: p?.peerAvatarUrl,
      transportName: transportLabelForPeer(st.peerDevicePk),
      onMuteToggle: () async {},
      onHangup: hangup,
    ));
  }

  Future<void> _handleEnded(EndedState st) async {
    final p = _pending;
    navigator.popSheet();
    if (p == null) return;
    if (p.callId != st.callId) return;
    // callId match confirmed — claim _pending now so concurrent EndedState
    // for a stale callId doesn't reuse it.
    _pending = null;
    final endedAt = DateTime.now().toUtc();
    final dur = p.activatedAt == null
        ? null
        : endedAt.difference(p.activatedAt!).inSeconds;
    await repo.add(MeshCallHistoryEntry(
      callId: p.callId,
      peerDevicePkBase64: base64Encode(p.peer.bytes),
      peerUserId: p.peerUserId,
      peerName: p.peerName,
      isOutgoing: p.isOutgoing,
      startedAt: p.startedAt,
      activatedAt: p.activatedAt,
      endedAt: endedAt,
      durationSec: dur,
      endReason: st.reason.name,
      transport: p.transport,
    ));
    // Dismiss any callkit overlay that was shown while the app was backgrounded.
    if (_isAndroid()) {
      unawaited(
        FlutterCallkitIncoming.endCall(p.callId.toString())
            .catchError((_) {}),
      );
    }
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _PendingCall {
  final int callId;
  final PeerId peer;
  final String? peerUserId;
  final String? peerName;
  final String? peerAvatarUrl;
  final bool isOutgoing;
  final DateTime startedAt;
  DateTime? activatedAt;
  bool screenPushed = false;
  final String? transport;

  _PendingCall({
    required this.callId,
    required this.peer,
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.isOutgoing,
    required this.startedAt,
    required this.transport,
  });
}
