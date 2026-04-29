package tirol.taler.taler_id_mobile.audio

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AudioPlaybackChannel(engine: FlutterEngine) {
  companion object {
    const val METHOD = "tirol.taler/mesh_audio_playback"
    const val SAMPLE_RATE = 16000
  }

  private var track: AudioTrack? = null

  init {
    MethodChannel(engine.dartExecutor.binaryMessenger, METHOD).setMethodCallHandler { call, res ->
      when (call.method) {
        "start" -> { try { start(); res.success(null) } catch (e: Exception) { res.error("start_failed", e.message, null) } }
        "stop"  -> { stop();  res.success(null) }
        "push" -> {
          val bytes = call.arguments as? ByteArray
          if (bytes != null) {
            track?.write(bytes, 0, bytes.size, AudioTrack.WRITE_BLOCKING)
            res.success(null)
          } else {
            res.error("bad_args", "expected ByteArray", null)
          }
        }
        else -> res.notImplemented()
      }
    }
  }

  private fun start() {
    if (track != null) return
    val attr = AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
      .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
      .build()
    val format = AudioFormat.Builder()
      .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
      .setSampleRate(SAMPLE_RATE)
      .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
      .build()
    val bufBytes = AudioTrack.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT) * 2
    val t = AudioTrack(attr, format, bufBytes, AudioTrack.MODE_STREAM, AudioManager.AUDIO_SESSION_ID_GENERATE)
    t.play()
    track = t
  }

  private fun stop() {
    val t = track
    track = null
    try { t?.stop(); t?.release() } catch (_: Throwable) {}
  }
}
