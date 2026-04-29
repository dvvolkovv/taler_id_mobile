import 'dart:typed_data';
import 'package:flutter/services.dart';

class AudioPlayback {
  static const _method = MethodChannel('tirol.taler/mesh_audio_playback');

  Future<void> start() async => await _method.invokeMethod('start');
  Future<void> stop() async => await _method.invokeMethod('stop');

  /// Push a PCM frame for playback. Frames are queued internally on the
  /// native side and pulled by the audio render callback.
  Future<void> push(Int16List pcm) async {
    final bytes = pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes);
    await _method.invokeMethod('push', bytes);
  }
}
