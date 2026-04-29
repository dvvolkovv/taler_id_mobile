package tirol.taler.taler_id_mobile.audio

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import kotlin.concurrent.thread

class AudioCaptureChannel(engine: FlutterEngine) : EventChannel.StreamHandler {
  companion object {
    const val METHOD = "tirol.taler/mesh_audio_capture"
    const val EVENT  = "tirol.taler/mesh_audio_capture/frames"
    const val SAMPLE_RATE = 16000
    const val FRAME_SAMPLES = 320 // 20 ms at 16 kHz
  }

  private var recorder: AudioRecord? = null
  private var aec: AcousticEchoCanceler? = null
  private var ns:  NoiseSuppressor? = null
  private var sink: EventChannel.EventSink? = null
  @Volatile private var running = false
  @Volatile private var micEnabled = true
  private val mainHandler = Handler(Looper.getMainLooper())

  init {
    MethodChannel(engine.dartExecutor.binaryMessenger, METHOD).setMethodCallHandler { call, res ->
      when (call.method) {
        "start" -> { try { start(); res.success(null) } catch (e: Exception) { res.error("start_failed", e.message, null) } }
        "stop"  -> { stop();  res.success(null) }
        "setMicEnabled" -> {
          val on = call.argument<Boolean>("enabled") ?: true
          micEnabled = on; res.success(null)
        }
        else -> res.notImplemented()
      }
    }
    EventChannel(engine.dartExecutor.binaryMessenger, EVENT).setStreamHandler(this)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
  override fun onCancel(arguments: Any?) { sink = null }

  private fun start() {
    if (running) return
    val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
    val rec = AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, SAMPLE_RATE,
        AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, minBuf * 4)
    if (AcousticEchoCanceler.isAvailable()) {
      aec = AcousticEchoCanceler.create(rec.audioSessionId)?.also { it.enabled = true }
    }
    if (NoiseSuppressor.isAvailable()) {
      ns = NoiseSuppressor.create(rec.audioSessionId)?.also { it.enabled = true }
    }
    rec.startRecording()
    recorder = rec
    running = true

    thread(start = true, name = "mesh-audio-capture") {
      val buf = ShortArray(FRAME_SAMPLES)
      while (running) {
        val n = rec.read(buf, 0, FRAME_SAMPLES)
        if (n <= 0) continue
        if (!micEnabled) continue
        val out = ByteArray(n * 2)
        for (i in 0 until n) {
          out[i * 2] = (buf[i].toInt() and 0xFF).toByte()
          out[i * 2 + 1] = ((buf[i].toInt() shr 8) and 0xFF).toByte()
        }
        mainHandler.post { sink?.success(out) }
      }
    }
  }

  private fun stop() {
    running = false
    aec?.release(); aec = null
    ns?.release();  ns  = null
    val r = recorder
    recorder = null
    try { r?.stop(); r?.release() } catch (_: Throwable) {}
  }
}
