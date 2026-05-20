package tirol.taler.taler_id_mobile.notifications

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Wires the [NotificationStoreNative] to Flutter over a [MethodChannel] (commands) and an
 * [EventChannel] (live stream).
 *
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 *
 * Channels:
 *   * `taler_id/notifications/cmd` — method channel for permission checks, recent-list queries,
 *     and reply commands.
 *   * `taler_id/notifications/stream` — event channel emitting one [Map] per inbound
 *     notification as soon as it's admitted by the native store.
 */
class NotificationBridge(
    flutterEngine: FlutterEngine,
    private val context: Context,
) {

    companion object {
        const val METHOD_CHANNEL = "taler_id/notifications/cmd"
        const val EVENT_CHANNEL = "taler_id/notifications/stream"
    }

    init {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationAccessGranted" -> {
                        result.success(isNotificationAccessGranted())
                    }
                    "openNotificationAccessSettings" -> {
                        openNotificationAccessSettings()
                        result.success(null)
                    }
                    "getRecent" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        result.success(handleGetRecent(args))
                    }
                    "reply" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        result.success(handleReply(args))
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationStoreNative.singleton.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    NotificationStoreNative.singleton.eventSink = null
                }
            })

        // Ask the system to rebind our listener service if it's not currently bound.
        // After app reinstall / process restart the system binds the listener lazily —
        // sometimes only when a new notification arrives. Without this nudge, the
        // in-memory buffer stays empty until the next inbound notification, even if
        // the user has notifications already sitting in the status bar.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                NotificationListenerService.requestRebind(
                    ComponentName(context, TalerNotificationListenerService::class.java),
                )
            } catch (e: Throwable) {
                Log.w("NotificationBridge", "requestRebind failed", e)
            }
        }
    }

    // --- Permission -----------------------------------------------------------------------

    private fun isNotificationAccessGranted(): Boolean {
        val enabled = NotificationManagerCompat.getEnabledListenerPackages(context)
        return enabled.contains(context.packageName)
    }

    private fun openNotificationAccessSettings() {
        // Android 11+: jump straight to our listener's toggle. Fall back to the general
        // listener-settings screen if the direct action isn't recognised.
        val direct: Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                val component = ComponentName(
                    context,
                    TalerNotificationListenerService::class.java,
                )
                putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    component.flattenToString(),
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            null
        }
        try {
            if (direct != null && direct.resolveActivity(context.packageManager) != null) {
                context.startActivity(direct)
                return
            }
        } catch (_: Throwable) {
            // fallthrough to generic settings
        }
        val fallback = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(fallback)
    }

    // --- Recent / reply -------------------------------------------------------------------

    private fun handleGetRecent(args: Map<String, Any?>): List<Map<String, Any?>> {
        val pkg = args["app"] as? String
        val sender = args["sender"] as? String
        val sinceMinutes = (args["sinceMinutes"] as? Number)?.toInt()
        val limit = (args["limit"] as? Number)?.toInt()
        val sinceMs: Long? = if (sinceMinutes != null && sinceMinutes > 0) {
            System.currentTimeMillis() - sinceMinutes * 60_000L
        } else {
            null
        }
        return NotificationStoreNative.singleton
            .recent(pkg, sender, sinceMs, limit)
            .map { it.toMap() }
    }

    private fun handleReply(args: Map<String, Any?>): Map<String, Any?> {
        val key = args["key"] as? String ?: ""
        val text = args["text"] as? String ?: ""
        if (key.isEmpty() || text.isEmpty()) {
            return mapOf("ok" to false, "error" to "missing key or text")
        }
        return when (val outcome = TalerNotificationListenerService.tryReply(key, text)) {
            is ReplyOutcome.Sent -> mapOf("ok" to true)
            is ReplyOutcome.NoSuchKey -> mapOf("ok" to false, "error" to "no_such_key")
            is ReplyOutcome.NoReplyAction -> mapOf("ok" to false, "error" to "no_reply_action")
            is ReplyOutcome.IntentFailure ->
                mapOf("ok" to false, "error" to "pending_intent_failed", "message" to outcome.message)
        }
    }
}
