package com.kasem.receive_sharing_intent

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Parcelable
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLConnection

private const val MESSAGES_CHANNEL = "receive_sharing_intent/messages"
private const val EVENTS_CHANNEL_MEDIA = "receive_sharing_intent/events-media"
private const val EVENTS_CHANNEL_TEXT = "receive_sharing_intent/events-text"

class ReceiveSharingIntentPlugin : FlutterPlugin, ActivityAware, MethodCallHandler,
        EventChannel.StreamHandler, NewIntentListener {

    private var initialMedia: JSONArray? = null
    private var latestMedia: JSONArray? = null

    private var eventSinkMedia: EventChannel.EventSink? = null

    private var binding: ActivityPluginBinding? = null
    private lateinit var applicationContext: Context

    private fun setupCallbackChannels(binaryMessenger: BinaryMessenger) {
        val mChannel = MethodChannel(binaryMessenger, MESSAGES_CHANNEL)
        mChannel.setMethodCallHandler(this)

        val eChannelMedia = EventChannel(binaryMessenger, EVENTS_CHANNEL_MEDIA)
        eChannelMedia.setStreamHandler(this)

        val eChannelText = EventChannel(binaryMessenger, EVENTS_CHANNEL_TEXT)
        eChannelText.setStreamHandler(this)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        setupCallbackChannels(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSinkMedia = events
    }

    override fun onCancel(arguments: Any?) {
        eventSinkMedia = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInitialMedia" -> result.success(initialMedia?.toString())
            "reset" -> {
                initialMedia = null
                latestMedia = null
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // PATCH P2 (Taler ID): a share that can't be read must not throw out of
    // onAttachedToActivity / onNewIntent. Upstream that aborted the plugin's
    // registration for the whole activity (cold start) or crashed it.
    private fun handleIntent(intent: Intent, initial: Boolean) {
        try {
            handleIntentUnsafe(intent, initial)
        } catch (e: Exception) {
            Log.e("ReceiveSharingIntent", "Failed to read shared content", e)
        }
    }

    private fun handleIntentUnsafe(intent: Intent, initial: Boolean) {
        when {
            // Sharing or opening media (image, video, text, file)
            intent.type != null && (
                    intent.action == Intent.ACTION_VIEW
                            || intent.action == Intent.ACTION_SEND
                            || intent.action == Intent.ACTION_SEND_MULTIPLE) -> {

                val value = getMediaUris(intent)
                if (initial) initialMedia = value
                latestMedia = value
                eventSinkMedia?.success(latestMedia?.toString())
            }

            // Opening URL
            intent.action == Intent.ACTION_VIEW -> {
                val value = JSONArray(
                        listOf(JSONObject()
                                .put("path", intent.dataString)
                                .put("type", MediaType.URL.value))
                )
                if (initial) initialMedia = value
                latestMedia = value
                eventSinkMedia?.success(latestMedia?.toString())
            }
        }
    }

    private fun getMediaUris(intent: Intent?): JSONArray? {
        if (intent == null) return null

        return when (intent.action) {
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                toJsonObject(uri, null, intent.type)?.let { JSONArray(listOf(it)) }
            }

            Intent.ACTION_SEND -> {
                val uri = intent.parcelable<Uri>(Intent.EXTRA_STREAM)
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                toJsonObject(uri, text, intent.type)?.let { JSONArray(listOf(it)) }
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.parcelableArrayList<Uri>(Intent.EXTRA_STREAM)
                val mimeTypes = intent.getStringArrayExtra(Intent.EXTRA_MIME_TYPES)

                uris?.mapIndexedNotNull { index, uri ->
                    // PATCH P3 (Taler ID): one unreadable item is skipped,
                    // the rest of the share still arrives.
                    try {
                        toJsonObject(uri, null, mimeTypes?.getOrNull(index))
                    } catch (e: Exception) {
                        Log.w("ReceiveSharingIntent", "Skipping unreadable $uri: $e")
                        null
                    }
                }?.let { JSONArray(it) }
            }

            else -> null
        }
    }

    // content can only be uri or string
    private fun toJsonObject(uri: Uri?, text: String?, mimeType: String?): JSONObject? {
        val path = uri?.let { FileDirectory.getAbsolutePath(applicationContext, it) }
        // PATCH P4 (Taler ID): nothing readable and no text — no item.
        // Upstream sent "path": null, which the Dart side can't parse.
        if (path == null && text == null) return null
        val mType = mimeType ?: path?.let { URLConnection.guessContentTypeFromName(path) }
        // PATCH P5 (Taler ID): a file that came as a stream stays a file even
        // when its MIME type is text/* (.txt, .csv, .vcf, .ics, .html…).
        // Upstream typed it TEXT, and the Dart side put its cache path into
        // the message field instead of attaching the file.
        val type = MediaType.fromMimeType(mType).let {
            if (it == MediaType.TEXT && path != null) MediaType.FILE else it
        }
        // PATCH P6 (Taler ID): no video thumbnail or duration — the app
        // doesn't read them, and MediaMetadataRetriever on the main thread
        // cost time and could throw, dropping the video itself.
        return JSONObject()
                .put("path", path ?: text)
                .put("type", type.value)
                .put("mimeType", mType)
    }

    enum class MediaType(val value: String) {
        IMAGE("image"), VIDEO("video"), TEXT("text"), FILE("file"), URL("url");

        companion object {
            fun fromMimeType(mimeType: String?): MediaType {
                return when {
                    mimeType?.startsWith("image") == true -> IMAGE
                    mimeType?.startsWith("video") == true -> VIDEO
                    mimeType?.startsWith("text") == true -> TEXT
                    else -> FILE
                }
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addOnNewIntentListener(this)
        handleIntent(binding.activity.intent, true)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        binding?.removeOnNewIntentListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        binding?.removeOnNewIntentListener(this)
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent, false)
        return false
    }

    inline fun <reified T : Parcelable> Intent.parcelable(key: String): T? = when {
        Build.VERSION.SDK_INT >= 33 -> getParcelableExtra(key, T::class.java)
        else -> @Suppress("DEPRECATION") getParcelableExtra(key) as? T
    }

    inline fun <reified T : Parcelable> Intent.parcelableArrayList(key: String): ArrayList<T>? = when {
        Build.VERSION.SDK_INT >= 33 -> getParcelableArrayListExtra(key, T::class.java)
        else -> @Suppress("DEPRECATION") getParcelableArrayListExtra(key)
    }
}
