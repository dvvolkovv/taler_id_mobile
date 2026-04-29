import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/audio/mesh_voice_audio_engine.dart';
import '../../../../core/audio/platform/audio_capture.dart';
import '../../../../core/audio/platform/audio_playback.dart';

/// Thin adapters so the screen doesn't need to implement both interfaces
/// on a single class (which would merge their start/stop methods).
class _CaptureAdapter implements AudioCaptureSource {
  final AudioCapture _capture;
  _CaptureAdapter(this._capture);

  @override
  Stream<Int16List> get frames => _capture.frames;
  @override
  Future<void> start() => _capture.start();
  @override
  Future<void> stop() => _capture.stop();
  @override
  Future<void> setMicEnabled(bool enabled) => _capture.setMicEnabled(enabled);
}

class _PlaybackAdapter implements AudioPlaybackSink {
  final AudioPlayback _playback;
  _PlaybackAdapter(this._playback);

  @override
  Future<void> start() => _playback.start();
  @override
  Future<void> stop() => _playback.stop();
  @override
  Future<void> push(Int16List pcm) => _playback.push(pcm);
}

class MeshVoiceSelfTestScreen extends StatefulWidget {
  const MeshVoiceSelfTestScreen({super.key});
  @override
  State<MeshVoiceSelfTestScreen> createState() => _MeshVoiceSelfTestScreenState();
}

class _MeshVoiceSelfTestScreenState extends State<MeshVoiceSelfTestScreen> {
  late final _CaptureAdapter _captureAdapter;
  late final _PlaybackAdapter _playbackAdapter;
  MeshVoiceAudioEngine? _engine;
  bool _running = false;
  int _seq = 0;
  StreamSubscription<Uint8List>? _outboundSub;

  @override
  void initState() {
    super.initState();
    _captureAdapter = _CaptureAdapter(AudioCapture());
    _playbackAdapter = _PlaybackAdapter(AudioPlayback());
  }

  Future<void> _startLoopback() async {
    final engine = MeshVoiceAudioEngine(
      capture: _captureAdapter,
      playback: _playbackAdapter,
    );
    _engine = engine;
    _outboundSub = engine.outbound.listen((opusBytes) {
      // Loop back: feed the just-encoded frame as if it were inbound.
      _seq++;
      engine.inbound(seq: _seq, payload: opusBytes);
      if (mounted && _seq % 50 == 0) setState(() {});
    });
    await engine.start();
    if (mounted) setState(() => _running = true);
  }

  Future<void> _stopLoopback() async {
    await _engine?.stop();
    await _outboundSub?.cancel();
    _engine = null;
    _outboundSub = null;
    _seq = 0;
    if (mounted) setState(() => _running = false);
  }

  @override
  void dispose() {
    _engine?.stop();
    _outboundSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesh Voice Self-Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _running
                      ? '🔊 Running. Speak into mic — you should hear yourself with ~80 ms delay.'
                      : 'Press Start to begin loopback test.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(_running ? Icons.stop : Icons.mic),
              label: Text(_running ? 'Stop' : 'Start loopback'),
              onPressed: _running ? _stopLoopback : _startLoopback,
            ),
            const SizedBox(height: 12),
            Text(
              'Seq counter: $_seq',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
