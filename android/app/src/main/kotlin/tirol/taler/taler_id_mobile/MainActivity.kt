package tirol.taler.taler_id_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import tirol.taler.taler_id_mobile.audio.AudioCaptureChannel
import tirol.taler.taler_id_mobile.audio.AudioPlaybackChannel
import tirol.taler.taler_id_mobile.audio.AudioRouteController
import tirol.taler.taler_id_mobile.audio.AudioRouteDevice
import tirol.taler.taler_id_mobile.installer.ApkInstaller
import tirol.taler.taler_id_mobile.notifications.NotificationBridge
import com.cloudwebrtc.webrtc.LocalTrack
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterFragmentActivity() {
    private var audioFocusRequest: AudioFocusRequest? = null
    private var focusListener: AudioManager.OnAudioFocusChangeListener? = null
    private var audioFocusGranted = false
    private var flutterChannel: MethodChannel? = null
    private var savedNotifVolume = -1
    private var savedMusicVolume = -1
    private var videoProcessor: VideoBackgroundProcessor? = null
    private var isVideoProcessing = false
    private var wakeWordListener: WakeWordListener? = null
    private var wakeWordChannel: MethodChannel? = null
    // Capture the correct FlutterWebRTCPlugin instance right after plugin registration
    private var webrtcPlugin: FlutterWebRTCPlugin? = null
    private val audioRouteEventSink = AtomicReference<EventChannel.EventSink?>(null)
    private var audioDeviceCallback: AudioDeviceCallback? = null

    /**
     * Single owner of the in-call output route. Every path that requests audio
     * focus goes through it, because the focus request itself resets the route
     * to the earpiece — see [AudioRouteController].
     */
    private val audioRoute by lazy {
        val am = getSystemService(AUDIO_SERVICE) as AudioManager
        AudioRouteController(object : AudioRouteDevice {
            override var speakerphoneOn: Boolean
                get() = am.isSpeakerphoneOn
                set(value) { am.isSpeakerphoneOn = value }
            override var bluetoothScoOn: Boolean
                get() = am.isBluetoothScoOn
                set(value) { am.isBluetoothScoOn = value }
            override fun enterCommunicationMode() { am.mode = AudioManager.MODE_IN_COMMUNICATION }
            override fun startBluetoothSco() = am.startBluetoothSco()
            override fun stopBluetoothSco() = am.stopBluetoothSco()
        })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    override fun onDestroy() {
        unregisterAudioRouteCallback()
        super.onDestroy()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val messagesChannel = NotificationChannel(
                "messages",
                "Сообщения",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о новых сообщениях"
                enableVibration(true)
            }
            nm.createNotificationChannel(messagesChannel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture the correct FlutterWebRTCPlugin instance immediately after plugin registration.
        // sharedSingleton may be overwritten later by another instance, so grab it now.
        webrtcPlugin = FlutterWebRTCPlugin.sharedSingleton
        Log.i("VideoEffects", "[VideoEffects] Captured WebRTC plugin: ${System.identityHashCode(webrtcPlugin)}")

        // Video effects channel (ML Kit selfie segmentation)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/video_effects")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "startProcessing" -> {
                        val args = call.arguments as? Map<*, *>
                        val effectType = args?.get("effectType") as? String ?: "blur"
                        val trackId = args?.get("trackId") as? String

                        val proc = videoProcessor ?: VideoBackgroundProcessor().also { videoProcessor = it }

                        if (effectType == "blur") {
                            proc.effectType = VideoBackgroundProcessor.EffectType.BLUR
                        } else if (effectType == "background") {
                            val imageBytes = args?.get("backgroundImageData") as? ByteArray
                            if (imageBytes != null) {
                                val bmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                                if (bmp != null) {
                                    proc.backgroundBitmap = bmp
                                    proc.effectType = VideoBackgroundProcessor.EffectType.BACKGROUND
                                }
                            }
                        }

                        if (!isVideoProcessing) {
                            addProcessorToActiveTrack(proc, trackId)
                            isVideoProcessing = true
                        }
                        result.success(null)
                    }
                    "setEffect" -> {
                        val args = call.arguments as? Map<*, *>
                        val effectType = args?.get("effectType") as? String ?: "blur"
                        val proc = videoProcessor
                        if (proc != null) {
                            if (effectType == "blur") {
                                proc.effectType = VideoBackgroundProcessor.EffectType.BLUR
                            } else if (effectType == "background") {
                                val imageBytes = args?.get("backgroundImageData") as? ByteArray
                                if (imageBytes != null) {
                                    val bmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                                    if (bmp != null) {
                                        proc.backgroundBitmap = bmp
                                        proc.effectType = VideoBackgroundProcessor.EffectType.BACKGROUND
                                    }
                                }
                            }
                        }
                        result.success(null)
                    }
                    "stopProcessing" -> {
                        videoProcessor?.let { proc ->
                            removeProcessorFromAllTracks(proc)
                            proc.cleanup()
                        }
                        isVideoProcessing = false
                        result.success(null)
                    }
                    "reattach" -> {
                        if (isVideoProcessing) {
                            videoProcessor?.let { addProcessorToActiveTrack(it, null) }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/audio")
        flutterChannel = ch
        ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeaker" -> {
                        val on = call.arguments as? Boolean ?: false
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        audioRoute.setSpeakerphone(on)
                        // Always re-request focus so second toggle doesn't leave the session
                        // half-configured (previously we only did this on toggle-ON, and toggle-OFF
                        // silently killed mic input on some devices). It re-applies the route.
                        requestAudioFocus(am)
                        result.success(null)
                    }
                    "getAudioOutputs" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        val outputs = mutableListOf<Map<String, String>>()
                        outputs.add(mapOf("id" to "earpiece", "name" to "Телефон", "type" to "earpiece"))
                        outputs.add(mapOf("id" to "speaker", "name" to "Динамик", "type" to "speaker"))
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val devices = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                            val hasWired = devices.any { d ->
                                d.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                                d.type == AudioDeviceInfo.TYPE_WIRED_HEADSET
                            }
                            val btDevice = devices.firstOrNull { d ->
                                d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                                d.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                                    (d.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                                     d.type == AudioDeviceInfo.TYPE_BLE_SPEAKER))
                            }
                            if (hasWired) {
                                outputs.add(mapOf("id" to "headphones", "name" to "Наушники", "type" to "headphones"))
                            }
                            if (btDevice != null) {
                                val btName = btDevice.productName?.toString() ?: "Bluetooth"
                                outputs.add(mapOf("id" to "bluetooth", "name" to btName, "type" to "bluetooth"))
                            }
                        }
                        result.success(outputs)
                    }
                    "setAudioOutput" -> {
                        val type = call.arguments as? String ?: "earpiece"
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        Log.i("AudDbg", "setAudioOutput: type=$type modeBefore=${am.mode} speakerBefore=${am.isSpeakerphoneOn}")
                        audioRoute.select(type)
                        // requestAudioFocus re-applies the route it just set — the focus
                        // request resets the output to the earpiece on most devices.
                        requestAudioFocus(am)
                        Log.i("AudDbg", "setAudioOutput: after switch mode=${am.mode} speaker=${am.isSpeakerphoneOn}")
                        result.success(null)
                    }
                    "requestAudioFocus" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        requestAudioFocus(am)
                        result.success(null)
                    }
                    "getCurrentAudioRoute" -> {
                        // Actual hardware route right now — used on app resume to
                        // avoid re-applying a stale UI selection over headphones/BT.
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        val route = when {
                            am.isBluetoothScoOn -> "bluetooth"
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                                am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { d ->
                                    d.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                                    d.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                                    d.type == AudioDeviceInfo.TYPE_USB_HEADSET
                                } -> "headphones"
                            am.isSpeakerphoneOn -> "speaker"
                            else -> "earpiece"
                        }
                        result.success(route)
                    }
                    "abandonAudioFocus" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        abandonAudioFocus(am)
                        result.success(null)
                    }
                    "muteBeep" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        savedNotifVolume = am.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
                        savedMusicVolume = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                        am.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                        am.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
                        result.success(null)
                    }
                    "unmuteBeep" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        if (savedNotifVolume >= 0) {
                            am.setStreamVolume(AudioManager.STREAM_NOTIFICATION, savedNotifVolume, 0)
                            savedNotifVolume = -1
                        }
                        if (savedMusicVolume >= 0) {
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, savedMusicVolume, 0)
                            savedMusicVolume = -1
                        }
                        result.success(null)
                    }
                    "requestBatteryOptimizationExemption" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            val pkg = packageName
                            if (!pm.isIgnoringBatteryOptimizations(pkg)) {
                                val intent = Intent(
                                    android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                    Uri.parse("package:$pkg")
                                )
                                startActivity(intent)
                            }
                        }
                        result.success(null)
                    }
                    "enableCallAudioMix" -> {
                        enableCallAudioMix()
                        result.success(null)
                    }
                    "disableCallAudioMix" -> {
                        disableCallAudioMix()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/audio_route")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    audioRouteEventSink.set(events)
                }
                override fun onCancel(arguments: Any?) {
                    audioRouteEventSink.set(null)
                }
            })

        registerAudioRouteCallback()

        // Mesh audio capture channel (PCM-16 frames, 16 kHz, AEC + NS)
        AudioCaptureChannel(flutterEngine)

        // Mesh audio playback channel (PCM-16, 16 kHz, USAGE_VOICE_COMMUNICATION)
        AudioPlaybackChannel(flutterEngine)

        // Wake word channel (separate from audio to avoid handler conflicts)
        val wwCh = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/wake_word")
        wakeWordChannel = wwCh
        wwCh.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    if (wakeWordListener == null) {
                        wakeWordListener = WakeWordListener(this@MainActivity) {
                            runOnUiThread {
                                wakeWordChannel?.invokeMethod("onWakeWord", null)
                            }
                        }
                    }
                    val args = call.arguments as? Map<*, *>
                    wakeWordListener?.setCustomPhrase(args?.get("customPhrase") as? String)
                    wakeWordListener?.start()
                    result.success(null)
                }
                "stop" -> {
                    wakeWordListener?.stop()
                    result.success(null)
                }
                "pause" -> {
                    wakeWordListener?.pause()
                    result.success(null)
                }
                "resume" -> {
                    val args = call.arguments as? Map<*, *>
                    wakeWordListener?.setCustomPhrase(args?.get("customPhrase") as? String)
                    wakeWordListener?.resume()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Phase 1A: bridge for the on-device NotificationListenerService — exposes captured
        // notifications + inline reply over MethodChannel/EventChannel.
        NotificationBridge(flutterEngine, this)

        // In-app APK updater: native PackageInstaller session + visible MediaStore copy.
        ApkInstaller(applicationContext, flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/mesh_fg_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val peerCount = call.argument<Int>("peerCount") ?: 0
                        val intent = Intent(this, MeshForegroundService::class.java).apply {
                            putExtra(MeshForegroundService.EXTRA_PEER_COUNT, peerCount)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stop" -> {
                        val intent = Intent(this, MeshForegroundService::class.java).apply {
                            action = MeshForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestAudioFocus(am: AudioManager) {
        val modeBefore = am.mode
        Log.i("AudDbg", "requestAudioFocus: enter granted=$audioFocusGranted modeBefore=$modeBefore speakerBefore=${am.isSpeakerphoneOn}")
        // Assert the route immediately — LiveKit may default to speakerphone.
        // Defaults to the earpiece; stays on whatever the user last picked.
        audioRoute.reapply()

        // If we already hold audio focus, just enforce the mode — don't re-request.
        // Re-requesting would cause the previous listener to receive AUDIOFOCUS_LOSS_TRANSIENT
        // which triggers spurious beeps in Flutter.
        if (audioFocusGranted) {
            Log.i("AudDbg", "requestAudioFocus: SKIP (already granted), modeAfter=${am.mode}")
            return
        }

        val listener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            Log.i("AudDbg", "focusChange: $focusChange (granted=$audioFocusGranted mode=${am.mode})")
            when (focusChange) {
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                    // A real external audio source (phone call, alarm) took focus
                    audioFocusGranted = false
                    runOnUiThread { flutterChannel?.invokeMethod("audioInterrupted", null) }
                }
                AudioManager.AUDIOFOCUS_GAIN -> {
                    // Focus returned — restore communication mode and the route
                    // the call was on before the interruption.
                    audioFocusGranted = true
                    audioRoute.reapply()
                    runOnUiThread { flutterChannel?.invokeMethod("audioResumed", null) }
                }
                AudioManager.AUDIOFOCUS_LOSS -> {
                    audioFocusGranted = false
                }
                else -> {}
            }
        }
        focusListener = listener

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener(listener)
                .build()
            audioFocusRequest = req
            val result = am.requestAudioFocus(req)
            audioFocusGranted = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
            Log.i("AudDbg", "requestAudioFocus: NEW request result=$result granted=$audioFocusGranted modeAfter=${am.mode} speakerAfter=${am.isSpeakerphoneOn}")
        } else {
            @Suppress("DEPRECATION")
            val result = am.requestAudioFocus(listener, AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN)
            audioFocusGranted = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
            Log.i("AudDbg", "requestAudioFocus: NEW request (legacy) result=$result granted=$audioFocusGranted modeAfter=${am.mode}")
        }
        // Granting focus re-routes to the earpiece behind our back — put the
        // call back where the user wanted it.
        audioRoute.reapply()
    }

    private fun abandonAudioFocus(am: AudioManager) {
        audioFocusGranted = false
        // Call over — the next one starts on the earpiece, not on whatever
        // output this call ended on.
        audioRoute.reset()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(focusListener)
        }
        focusListener = null
    }

    private fun registerAudioRouteCallback() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val am = getSystemService(AUDIO_SERVICE) as AudioManager

        val cb = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                val bt = addedDevices.firstOrNull { isBluetoothHeadset(it) } ?: return
                if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
                try {
                    audioRoute.select(AudioRouteController.ROUTE_BLUETOOTH)
                    requestAudioFocus(am)
                } catch (e: Exception) {
                    Log.w("AudioRoute", "BT SCO start failed: ${e.message}")
                }
                sendRouteEvent(mapOf(
                    "event" to "bluetoothConnected",
                    "name" to (bt.productName?.toString() ?: "Bluetooth")
                ))
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                val hadBt = removedDevices.any { isBluetoothHeadset(it) }
                if (!hadBt) return
                if (am.mode != AudioManager.MODE_IN_COMMUNICATION) return
                try {
                    // Headset gone: fall back to the earpiece, but don't yank a
                    // call that was deliberately put on the loudspeaker.
                    if (audioRoute.route == AudioRouteController.ROUTE_BLUETOOTH) {
                        audioRoute.select(AudioRouteController.ROUTE_EARPIECE)
                    }
                } catch (e: Exception) {
                    Log.w("AudioRoute", "BT SCO stop failed: ${e.message}")
                }
                sendRouteEvent(mapOf("event" to "bluetoothDisconnected"))
            }

            private fun isBluetoothHeadset(d: AudioDeviceInfo): Boolean =
                d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        d.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
        }
        am.registerAudioDeviceCallback(cb, null)
        audioDeviceCallback = cb
    }

    private fun unregisterAudioRouteCallback() {
        val am = getSystemService(AUDIO_SERVICE) as AudioManager
        audioDeviceCallback?.let { am.unregisterAudioDeviceCallback(it) }
        audioDeviceCallback = null
    }

    private fun sendRouteEvent(payload: Map<String, Any?>) {
        runOnUiThread { audioRouteEventSink.get()?.success(payload) }
    }

    private var callAudioFocusRequest: AudioFocusRequest? = null

    /// Request audio focus in mix-respecting mode so external VoIP apps
    /// (WhatsApp/Telegram) can ring without preempting our LiveKit audio.
    private fun enableCallAudioMix() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        Log.i("AudDbg", "enableCallAudioMix: enter primaryGranted=$audioFocusGranted mode=${audioManager.mode} listenerAttached=${focusListener != null}")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(true)
                .setWillPauseWhenDucked(false)
                .also { b -> focusListener?.let { b.setOnAudioFocusChangeListener(it) } }
                .build()
            val outcome = audioManager.requestAudioFocus(request)
            Log.i("AudDbg", "enableCallAudioMix: outcome=$outcome primaryGrantedAfter=$audioFocusGranted mode=${audioManager.mode}")
            if (outcome == AudioManager.AUDIOFOCUS_REQUEST_GRANTED ||
                outcome == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
                callAudioFocusRequest = request
                Log.i("CallAudioMix", "enabled (gain=$outcome, may_duck=true)")
            } else {
                Log.w("CallAudioMix", "enable failed: outcome=$outcome")
            }
        } else {
            // API 24-25 fallback: deprecated API
            @Suppress("DEPRECATION")
            val outcome = audioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
            Log.i("CallAudioMix", "enabled via deprecated API (outcome=$outcome)")
        }
    }

    /// Release the call audio focus request so the app stops mixing with others.
    private fun disableCallAudioMix() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = callAudioFocusRequest
            if (req != null) {
                audioManager.abandonAudioFocusRequest(req)
                callAudioFocusRequest = null
                Log.i("CallAudioMix", "disabled")
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
            Log.i("CallAudioMix", "disabled via deprecated API")
        }
    }

    // Track the LocalVideoTrack wrapper we created (for removal later)
    private var activeLocalVideoTrack: LocalVideoTrack? = null

    private fun addProcessorToActiveTrack(processor: VideoBackgroundProcessor, trackId: String?) {
        Log.i("VideoEffects", "[VideoEffects] addProcessorToActiveTrack trackId=$trackId")

        // Strategy 1: Use track ID with both captured and current singleton
        val candidates = listOfNotNull(webrtcPlugin, FlutterWebRTCPlugin.sharedSingleton).distinct()
        Log.i("VideoEffects", "[VideoEffects] Plugin candidates: ${candidates.size}, captured=${System.identityHashCode(webrtcPlugin)}, singleton=${System.identityHashCode(FlutterWebRTCPlugin.sharedSingleton)}")

        for (plugin in candidates) {
            try {
                // Strategy 1a: Direct getLocalTrack by ID (same approach LiveKit uses)
                if (trackId != null) {
                    val localTrack = plugin.getLocalTrack(trackId)
                    if (localTrack is LocalVideoTrack) {
                        Log.i("VideoEffects", "[VideoEffects] Found LocalVideoTrack via getLocalTrack($trackId) on plugin ${System.identityHashCode(plugin)}")
                        localTrack.addProcessor(processor)
                        activeLocalVideoTrack = localTrack
                        return
                    }
                    Log.i("VideoEffects", "[VideoEffects] getLocalTrack($trackId) returned ${localTrack?.javaClass?.name ?: "null"} on plugin ${System.identityHashCode(plugin)}")
                }

                // Strategy 1b: Iterate all localTracks looking for any video track
                val handlerField = plugin.javaClass.getDeclaredField("methodCallHandler")
                handlerField.isAccessible = true
                val handler = handlerField.get(plugin) ?: continue

                val tracksField = handler.javaClass.getDeclaredField("localTracks")
                tracksField.isAccessible = true
                @Suppress("UNCHECKED_CAST")
                val tracks = tracksField.get(handler) as? Map<String, LocalTrack> ?: emptyMap()
                Log.i("VideoEffects", "[VideoEffects] Plugin ${System.identityHashCode(plugin)}: localTracks=${tracks.size}, keys=${tracks.keys}")

                for ((tid, track) in tracks) {
                    if (track is LocalVideoTrack) {
                        Log.i("VideoEffects", "[VideoEffects] Adding processor to localTrack: $tid")
                        track.addProcessor(processor)
                        activeLocalVideoTrack = track
                        return
                    }
                }

                // Check handler initialization state for diagnostics
                val gumField = handler.javaClass.getDeclaredField("getUserMediaImpl")
                gumField.isAccessible = true
                val gum = gumField.get(handler)
                val pcObsField = handler.javaClass.getDeclaredField("mPeerConnectionObservers")
                pcObsField.isAccessible = true
                val pcObs = pcObsField.get(handler) as? Map<*, *>
                Log.i("VideoEffects", "[VideoEffects] Plugin ${System.identityHashCode(plugin)}: getUserMediaImpl=${gum != null}, PCs=${pcObs?.size ?: 0}")

            } catch (e: Exception) {
                Log.i("VideoEffects", "[VideoEffects] Error with plugin ${System.identityHashCode(plugin)}: ${e.message}")
            }
        }

        Log.i("VideoEffects", "[VideoEffects] No LocalVideoTrack found via any plugin. Will try again on next frame.")
    }

    private fun removeProcessorFromAllTracks(processor: VideoBackgroundProcessor) {
        activeLocalVideoTrack?.removeProcessor(processor)
        activeLocalVideoTrack = null
    }
}
