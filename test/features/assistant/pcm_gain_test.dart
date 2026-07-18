import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/audio/pcm_gain.dart';

Uint8List pcmFromSamples(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

List<int> samplesFromPcm(Uint8List pcm) {
  final data = ByteData.sublistView(pcm);
  return [
    for (var i = 0; i < pcm.length; i += 2) data.getInt16(i, Endian.little),
  ];
}

void main() {
  test('amplifies samples by gain', () {
    final out = amplifyPcm16(pcmFromSamples([1000, -2000, 0]), 2.0);
    expect(samplesFromPcm(out), [2000, -4000, 0]);
  });

  test('clips at int16 bounds instead of overflowing', () {
    final out = amplifyPcm16(pcmFromSamples([30000, -30000]), 2.0);
    expect(samplesFromPcm(out), [32767, -32768]);
  });

  test('gain 1.0 is identity', () {
    final input = pcmFromSamples([123, -456, 32767, -32768]);
    expect(samplesFromPcm(amplifyPcm16(input, 1.0)),
        [123, -456, 32767, -32768]);
  });

  test('odd trailing byte is preserved untouched', () {
    final input = Uint8List.fromList([...pcmFromSamples([1000]), 0x7f]);
    final out = amplifyPcm16(input, 2.0);
    expect(out.length, input.length);
    expect(out.last, 0x7f);
  });
}
