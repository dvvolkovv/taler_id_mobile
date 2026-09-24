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

  /// On iOS: sent when the system holds or resumes the call ("Hold &
  /// Accept" from the call UI) and as the echo of our own
  /// [CallKitPlatform.setHeld]; the id is upper-case (Swift `uuidString`)
  /// — compare lower-cased. On Android: only that echo, with the id as
  /// passed.
  static const typeToggleHold =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_HOLD';

  /// On iOS: sent when the user taps mute in the call UI (lock screen /
  /// Dynamic Island) and as the echo of our own [CallKitPlatform.setMuted];
  /// the id is upper-case (Swift `uuidString`) — compare lower-cased. On
  /// Android: only that echo, with the id as passed.
  static const typeToggleMute =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_MUTE';

  /// iOS only. Carries no call id — the event body is only
  /// `{isActivate: bool}`, so [CallKitEvent.uuid] is '' for this event.
  static const typeToggleAudioSession =
      'com.hiennv.flutter_callkit_incoming.ACTION_CALL_TOGGLE_AUDIO_SESSION';

  final String type;
  final String uuid;
  final Map<String, dynamic>? data;

  const CallKitEvent({
    required this.type,
    required this.uuid,
    this.data,
  });
}

/// Platform-agnostic interface to the native call UI (CallKit / android
/// full-screen notification): incoming and outgoing calls, plus in-call
/// controls (connect, hold, mute).
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

  /// Put a conversation that did not ring through CallKit (an outgoing call,
  /// a meeting joined by link) into the OS call system.
  ///
  /// iOS only — don't call this (or [setCallConnected], [setHeld],
  /// [setMuted]) on Android, where they are not no-ops: this starts the
  /// plugin's phone-call foreground service with an ongoing-call
  /// notification, emits [CallKitEvent.typeStart] and records an *accepted*
  /// call in [activeCalls] — while one is there, `call_cancelled` no longer
  /// dismisses a ringing call.
  ///
  /// [uuid] must be a valid UUID: the iOS plugin force-unwraps it
  /// (`CallManager.swift`), so anything else crashes the app. The returned
  /// future only means the request reached the plugin; iOS confirms with a
  /// [CallKitEvent.typeStart] event carrying the same [uuid], and sends
  /// nothing if it refuses the call. [extra] must be JSON-encodable — the
  /// plugin embeds it in the call's handle, which iOS keeps in Recents.
  Future<void> startCall({
    required String uuid,
    required String callerName,
    required String handle,
    Map<String, dynamic>? extra,
  });

  /// Outgoing call: report it connected. Ringing incoming call: answer it,
  /// exactly as the Accept button of the CallKit UI would.
  ///
  /// iOS only — see [startCall]. On Android this posts the ongoing-call
  /// notification and emits [CallKitEvent.typeConnected].
  Future<void> setCallConnected(String uuid);

  /// Put [uuid] on hold, or take it off hold.
  ///
  /// iOS only — see [startCall]. On Android this only echoes
  /// [CallKitEvent.typeToggleHold] back into [events].
  Future<void> setHeld(String uuid, bool onHold);

  /// Mirror our mute state in the system call UI.
  ///
  /// iOS only — see [startCall]. On Android this only echoes
  /// [CallKitEvent.typeToggleMute] back into [events].
  Future<void> setMuted(String uuid, bool muted);

  /// Return the list of currently active calls (raw plugin format).
  Future<List<dynamic>> activeCalls();

  /// Return the VoIP push token (iOS only; null on all other platforms).
  Future<String?> getDevicePushTokenVoIP();

  /// Stream of CallKit events re-broadcast from the single native subscription.
  Stream<CallKitEvent> get events;

  @visibleForTesting
  static void debugResetForTest() => _instance = null;

  @visibleForTesting
  static set debugInstance(CallKitPlatform instance) {
    _instance = instance;
  }
}
