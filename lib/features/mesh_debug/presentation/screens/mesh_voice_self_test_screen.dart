import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/audio/mesh_voice_audio_engine.dart';
import '../../../../core/audio/default_mesh_voice_audio_engine.dart';

class MeshVoiceSelfTestScreen extends StatefulWidget {
  const MeshVoiceSelfTestScreen({super.key});
  @override
  State<MeshVoiceSelfTestScreen> createState() => _MeshVoiceSelfTestScreenState();
}

class _MeshVoiceSelfTestScreenState extends State<MeshVoiceSelfTestScreen> {
  MeshVoiceAudioEngine? _engine;
  bool _running = false;
  int _seq = 0;
  StreamSubscription<Uint8List>? _outboundSub;

  Future<void> _startLoopback() async {
    final engine = defaultMeshVoiceAudioEngine();
    _engine = engine;
    _outboundSub = engine.outbound.listen((opusBytes) {
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
