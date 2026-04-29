import 'dart:typed_data';
import 'package:flutter/services.dart';

class AudioCapture {
  static const _method = MethodChannel('tirol.taler/mesh_audio_capture');
  static const _events = EventChannel('tirol.taler/mesh_audio_capture/frames');

  Stream<Int16List>? _stream;

  Future<void> start() async => await _method.invokeMethod('start');
  Future<void> stop() async => await _method.invokeMethod('stop');
  Future<void> setMicEnabled(bool enabled) async =>
      await _method.invokeMethod('setMicEnabled', {'enabled': enabled});

  Stream<Int16List> get frames {
    return _stream ??= _events.receiveBroadcastStream().map((event) {
      final bytes = event as Uint8List;
      // Reinterpret the bytes as Int16 samples (little-endian on iOS+Android).
      return Int16List.view(bytes.buffer, bytes.offsetInBytes, bytes.length ~/ 2);
    });
  }
}
