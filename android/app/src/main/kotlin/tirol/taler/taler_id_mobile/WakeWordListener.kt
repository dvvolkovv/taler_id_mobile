package tirol.taler.taler_id_mobile

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log

/**
 * Native wake word listener using Android SpeechRecognizer.
 * Mutes notification/music streams ONCE on first start, unmutes on stop/pause/detect.
 * Restarts silently (no mute cycling) on timeout.
 */
class WakeWordListener(
    private val context: Context,
    private val onDetected: () -> Unit
) {
    companion object {
        private const val TAG = "WakeWord"
    }

    private var recognizer: SpeechRecognizer? = null
    private var isListening = false
    private var enabled = false
    private val handler = Handler(Looper.getMainLooper())

    // Only custom phrase + its variations
    private var phrases = listOf<String>()

    fun setCustomPhrase(phrase: String?) {
        if (phrase != null && phrase.isNotBlank()) {
            val custom = phrase.lowercase().trim()
            phrases = listOf(custom)
            Log.i(TAG, "Phrase: $custom")
        }
    }

    fun start() {
        if (enabled && isListening) return
        enabled = true
        Log.i(TAG, "start")
        startListening()
    }

    fun stop() {
        enabled = false
        Log.i(TAG, "stop")
        handler.removeCallbacksAndMessages(null)
        destroyRecognizer()
    }

    fun pause() {
        Log.i(TAG, "pause")
        handler.removeCallbacksAndMessages(null)
        destroyRecognizer()
    }

    fun resume() {
        if (isListening) return
        enabled = true
        Log.i(TAG, "resume")
        startListening()
    }

    private fun startListening() {
        if (isListening || !enabled) return
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.e(TAG, "SpeechRecognizer not available")
            return
        }

        destroyRecognizer()
        recognizer = SpeechRecognizer.createSpeechRecognizer(context)
        recognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                isListening = true
                // Keep muted — unmute only on detect/pause/stop
            }

            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}

            override fun onError(error: Int) {
                isListening = false
                if (enabled) {
                    // Restart without muting (already past the beep)
                    handler.postDelayed({ if (enabled) startListening() }, 500)
                }
            }

            override fun onResults(results: Bundle?) {
                isListening = false
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null && checkPhrases(matches)) return
                // Not matched — restart silently
                if (enabled) {
                    handler.postDelayed({ if (enabled) startListening() }, 200)
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null) checkPhrases(matches)
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
        }
        recognizer?.startListening(intent)
    }

    /** Returns true if phrase detected */
    private fun checkPhrases(matches: List<String>): Boolean {
        for (match in matches) {
            val lower = match.lowercase()
            for (phrase in phrases) {
                if (lower.contains(phrase)) {
                    Log.i(TAG, "DETECTED: $lower")
                    enabled = false
                    handler.removeCallbacksAndMessages(null)
                    destroyRecognizer()
                    onDetected()
                    return true
                }
            }
        }
        return false
    }

    private fun destroyRecognizer() {
        isListening = false
        try {
            recognizer?.cancel()
            recognizer?.destroy()
        } catch (_: Exception) {}
        recognizer = null
    }
}
