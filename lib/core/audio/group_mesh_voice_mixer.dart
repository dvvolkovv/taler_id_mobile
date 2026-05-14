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

    // Count non-null sources once. Pure sum + hard clip was producing audible
    // distortion in 2- and 3-peer calls because simultaneous speech crossed
    // the int16 ceiling on loud frames. Normalising by the non-null peer
    // count avoids the saturating-clip "buzz" reported as "прерывание
    // голоса" during the hardware smoke. Single-source (1-on-1 mesh, or
    // group call where only one peer is speaking) is unchanged because the
    // divide-by-1 is a no-op.
    var activeCount = 0;
    for (final src in sources) {
      if (src != null) activeCount++;
    }
    if (activeCount == 0) return out;

    for (var i = 0; i < frameSamples; i++) {
      var sum = 0;
      for (final src in sources) {
        if (src == null) continue;
        if (i >= src.length) continue;
        sum += src[i];
      }
      final mixed = activeCount > 1 ? sum ~/ activeCount : sum;
      if (mixed > 32767) {
        out[i] = 32767;
      } else if (mixed < -32768) {
        out[i] = -32768;
      } else {
        out[i] = mixed;
      }
    }
    return out;
  }
}
