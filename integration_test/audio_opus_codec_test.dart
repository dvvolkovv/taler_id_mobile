import 'dart:typed_data';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taler_id_mobile/core/audio/opus/opus_encoder.dart';
import 'package:taler_id_mobile/core/audio/opus/opus_decoder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Opus encode → decode roundtrip with production config (VOIP/24kbps)', (_) async {
    final encoder = OpusEncoder(sampleRate: 16000, channels: 1, bitrate: 24000);
    final decoder = OpusDecoder(sampleRate: 16000, channels: 1);

    // Generate 20 ms of 1 kHz sine at 16 kHz mono = 320 samples.
    final pcm = Int16List(320);
    for (var i = 0; i < pcm.length; i++) {
      pcm[i] = (sin(2 * pi * 1000 * i / 16000) * 16384).toInt();
    }

    final encoded = encoder.encode(pcm);
    expect(encoded.length, greaterThan(0),
        reason: 'encoded frame must be non-empty');
    expect(encoded.length, lessThan(200),
        reason: 'a 20 ms VoIP frame at 24 kbps should not exceed ~200 bytes');

    final decoded = decoder.decode(encoded, frameSize: 320);
    expect(decoded.length, 320,
        reason: 'decoded PCM frame must have exact sample count');

    // A broken codec returns silence (all zeros) or garbage. A working codec
    // preserves the dominant signal envelope — peak amplitude stays well above
    // any reasonable noise floor for a clear sine input.
    var peak = 0;
    for (final s in decoded) {
      final abs = s < 0 ? -s : s;
      if (abs > peak) peak = abs;
    }
    expect(peak, greaterThan(1000),
        reason: 'decoded frame must preserve the input signal envelope (peak > 1000)');

    encoder.dispose();
    decoder.dispose();
  });
}
