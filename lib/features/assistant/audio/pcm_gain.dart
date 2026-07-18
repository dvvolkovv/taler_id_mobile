import 'dart:typed_data';

/// Amplifies little-endian PCM16 audio by [gain] with hard clipping at the
/// int16 range. OpenAI Realtime output is noticeably quiet on the in-call
/// audio session, so the assistant boosts it before playback (same approach
/// as the backend's TRANSLATOR_GAIN for translator TTS).
Uint8List amplifyPcm16(Uint8List pcm, double gain) {
  if (gain == 1.0) return pcm;
  final out = Uint8List.fromList(pcm);
  final data = ByteData.sublistView(out);
  final evenLength = pcm.length - (pcm.length % 2);
  for (var i = 0; i < evenLength; i += 2) {
    final sample = (data.getInt16(i, Endian.little) * gain).round();
    data.setInt16(i, sample.clamp(-32768, 32767), Endian.little);
  }
  return out;
}
