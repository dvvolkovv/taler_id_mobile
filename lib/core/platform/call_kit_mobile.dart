// lib/core/platform/call_kit_mobile.dart
import 'dart:async';

import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

import 'call_kit.dart';

/// [CallKitPlatform] implementation for iOS and Android.
///
/// Delegates every method to [flutter_callkit_incoming]. Subscribes to
/// [FlutterCallkitIncoming.onEvent] exactly once in the constructor and
/// re-broadcasts events as [CallKitEvent]s so that no other code path needs
/// to access [onEvent] directly (each access to [onEvent] replaces the
/// underlying EventChannel handler, which would silently kill the singleton
/// subscription).
class CallKitMobile implements CallKitPlatform {
  final _controller = StreamController<CallKitEvent>.broadcast();

  CallKitMobile() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      _controller.add(CallKitEvent(
        type: event.event.name,
        uuid: (event.body['id'] ?? '').toString(),
        data: Map<String, dynamic>.from(event.body as Map),
      ));
    });
  }

  @override
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
  }) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Taler ID',
      handle: handle ?? roomName,
      type: isVideo ? 1 : 0,
      avatar: avatar,
      extra: extra,
      textAccept: textAccept,
      textDecline: textDecline,
      duration: durationMs ?? 60000,
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        isShowFullLockedScreen: true,
        ringtonePath: 'bumer_ringtone',
        backgroundColor: '#0A1628',
        actionColor: '#167EF2',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: androidIncomingChannelName,
        missedCallNotificationChannelName: androidMissedChannelName,
        isShowCallID: false,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        supportsVideo: false,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'bumer_ringtone.caf',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  @override
  Future<void> endCall(String uuid) => FlutterCallkitIncoming.endCall(uuid);

  @override
  Future<void> endAllCalls() => FlutterCallkitIncoming.endAllCalls();

  @override
  Future<List<dynamic>> activeCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    if (result is List) return result;
    return [];
  }

  @override
  Future<String?> getDevicePushTokenVoIP() async {
    final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    return token?.toString();
  }

  @override
  Stream<CallKitEvent> get events => _controller.stream;
}
