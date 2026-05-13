import 'dart:typed_data';

abstract final class GroupMeshVoiceMixer {
  /// Mix N PCM sources element-wise into one frame of `frameSamples` int16 samples.
  ///
  /// Each source may be null (treated as silence) or shorter than [frameSamples]
  /// (treated as zero for missing trailing samples). Sums are hard-clipped to the
  /// int16 range [-32768, 32767].
  ///
  /// If [sources] is empty, returns a zero-filled Int16List of [frameSamples].
  static Int16List mix(List<Int16List?> sources, int frameSamples) {
    final out = Int16List(frameSamples);
    if (sources.isEmpty) return out;

    for (var i = 0; i < frameSamples; i++) {
      var sum = 0;
      for (final src in sources) {
        if (src == null) continue;
        if (i >= src.length) continue;
        sum += src[i];
      }
      if (sum > 32767) {
        out[i] = 32767;
      } else if (sum < -32768) {
        out[i] = -32768;
      } else {
        out[i] = sum;
      }
    }
    return out;
  }
}
