import 'dart:async';

import 'package:flutter/services.dart';

/// Dart side of `ios/Runner/CallKitAudioBridge.swift`.
abstract class SystemCallBridge {
  /// Which CallKit calls are our conversations. Non-empty: CallKit owns the
  /// audio session and WebRTC follows it; empty: WebRTC manages it as before.
  Future<void> setManagedCalls(List<String> uuids);

  /// Set the call's audio category before CallKit activates the session.
  Future<void> prepareCallAudio();

  /// No call other than our conversations remains — call waiting is over.
  Stream<void> get otherCallsEnded;
}

class MethodChannelSystemCallBridge implements SystemCallBridge {
  MethodChannelSystemCallBridge() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'otherCallsEnded') _otherCallsEnded.add(null);
      return null;
    });
  }

  // A channel of its own: `taler_id/audio` belongs to the call screen, which
  // drops its handler when it closes, and the bridge must keep working while
  // the call runs behind the banner.
  static const _channel = MethodChannel('taler_id/callkit_audio');
  final _otherCallsEnded = StreamController<void>.broadcast();

  @override
  Future<void> setManagedCalls(List<String> uuids) =>
      _channel.invokeMethod('setManagedCalls', uuids);

  @override
  Future<void> prepareCallAudio() => _channel.invokeMethod('prepareCallAudio');

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}
