// lib/core/platform/call_kit.dart
import 'package:flutter/foundation.dart';
import 'platform_utils.dart';
import 'call_kit_mobile.dart';
import 'call_kit_desktop.dart';

/// Wrapper around a raw CallKit / flutter_callkit_incoming event.
///
/// [type] is one of the [CallKitEvent.type*] string constants.
/// [uuid] is the call UUID from the event body.
/// [data] is the full event body map (contains 'extra', 'nameCaller', etc.).
class CallKitEvent {
  // Event type string constants (values emitted by flutter_callkit_incoming)
  static const typeAccept =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT';
  static const typeDecline =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE';
  static const typeEnded =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_ENDED';
  static const typeTimeout =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TIMEOUT';
  static const typeConnected =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_CONNECTED';
  static const typeIncoming =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING';
  static const typeStart =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_START';
  static const typeCallback =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_CALLBACK';
  static const typePushTokenVoip =
      'com.hiennv.flutter_callkit_incoming.DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP';

  final String type;
  final String uuid;
  final Map<String, dynamic>? data;

  const CallKitEvent({
    required this.type,
    required this.uuid,
    this.data,
  });
}

/// Platform-agnostic interface for native incoming-call UI (CallKit / android
/// full-screen notification).
///
/// Dispatch is done once at first access: mobile platforms get [CallKitMobile]
/// (which delegates to `flutter_callkit_incoming`); desktop platforms get
/// [CallKitDesktop] (all no-ops).
///
/// Use [debugResetForTest] in unit tests to force re-initialisation.
abstract class CallKitPlatform {
  static CallKitPlatform? _instance;

  static CallKitPlatform get instance =>
      _instance ??=
          PlatformUtils.instance.isMobile ? CallKitMobile() : CallKitDesktop();

  /// Show the native incoming-call UI.
  Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String roomName,
    String? handle,
    String? avatar,
    bool isVideo = false,
    Map<String, dynamic>? extra,
    String? textAccept,
    String? textDecline,
    int? durationMs,
    String? androidIncomingChannelName,
    String? androidMissedChannelName,
  });

  /// End the call identified by [uuid].
  Future<void> endCall(String uuid);

  /// End all active calls.
  Future<void> endAllCalls();

  /// Return the list of currently active calls (raw plugin format).
  Future<List<dynamic>> activeCalls();

  /// Return the VoIP push token (iOS only; null on all other platforms).
  Future<String?> getDevicePushTokenVoIP();

  /// Stream of CallKit events re-broadcast from the single native subscription.
  Stream<CallKitEvent> get events;

  @visibleForTesting
  static void debugResetForTest() => _instance = null;
}
