// lib/core/platform/system_call_bridge.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of `ios/Runner/CallKitAudioBridge.swift`. On platforms without
/// the native bridge these methods throw [MissingPluginException]; callers
/// catch it.
abstract class SystemCallBridge {
  /// Which CallKit calls are our conversations, as lowercase CallKit uuid
  /// strings. Each call sends the complete set, replacing the previous one.
  /// Non-empty: CallKit owns the audio session and WebRTC follows it; empty:
  /// WebRTC manages it as before.
  Future<void> setManagedCalls(List<String> uuids);

  /// Set the call's audio category before CallKit activates the session.
  Future<void> prepareCallAudio();

  /// No call other than our conversations remains — call waiting is over.
  Stream<void> get otherCallsEnded;
}

class MethodChannelSystemCallBridge implements SystemCallBridge {
  MethodChannelSystemCallBridge() {
    // A channel has one Dart handler per engine: installing the same static
    // one again is harmless, and every instance shares the stream.
    _channel.setMethodCallHandler(_onNativeCall);
  }

  // A channel of its own: `taler_id/audio` belongs to the call screen, which
  // drops its handler when it closes, and the bridge must keep working while
  // the call runs behind the banner.
  static const _channel = MethodChannel('taler_id/callkit_audio');
  static final _otherCallsEnded = StreamController<void>.broadcast();

  static Future<void> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'otherCallsEnded':
        _otherCallsEnded.add(null);
      default:
        debugPrint('[CallKitAudio] unhandled native call: ${call.method}');
        throw MissingPluginException(); // native side gets FlutterMethodNotImplemented
    }
  }

  @override
  Future<void> setManagedCalls(List<String> uuids) =>
      _channel.invokeMethod<void>('setManagedCalls', uuids);

  @override
  Future<void> prepareCallAudio() => _channel.invokeMethod<void>('prepareCallAudio');

  @override
  Stream<void> get otherCallsEnded => _otherCallsEnded.stream;
}
