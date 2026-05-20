package tirol.taler.taler_id_mobile.notifications

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput

/**
 * Immutable snapshot of an Android notification that arrived from another app.
 *
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 *
 * Held purely in RAM by [NotificationStoreNative]. The replyAction / remoteInput / pendingIntent
 * fields are required to fire an inline reply via [android.app.RemoteInput.addResultsToIntent].
 * They are nullable because not every notification carries a reply action (Gmail "open compose",
 * group notifications without inline reply, E2EE notifications with empty body, etc.).
 */
data class CapturedNotification(
    val packageName: String,
    val key: String,
    val postTimeMs: Long,
    val title: String,
    val body: String,
    val conversationTitle: String?,
    val canReply: Boolean,
    // Reply machinery — only meaningful while the originating notification is still cached.
    // We keep references to the live Notification.Action / RemoteInput / PendingIntent so
    // tryReply can build the result bundle and fire the intent.
    val replyAction: Notification.Action? = null,
    val remoteInput: RemoteInput? = null,
    val pendingIntent: PendingIntent? = null,
) {
    /**
     * Serialise to a Map suitable for crossing the [io.flutter.plugin.common.MethodChannel] /
     * [io.flutter.plugin.common.EventChannel] boundary. Action/intent fields are intentionally
     * dropped — Dart side never needs them; replies go via [NotificationBridge].
     */
    fun toMap(): Map<String, Any?> = mapOf(
        "packageName" to packageName,
        "key" to key,
        "postTimeMs" to postTimeMs,
        "title" to title,
        "body" to body,
        "conversationTitle" to conversationTitle,
        "canReply" to canReply,
    )
}

/** Result of a [TalerNotificationListenerService.tryReply] attempt. */
sealed class ReplyOutcome {
    /** Inline reply intent fired successfully (no delivery guarantee — see Risk 3 in plan). */
    object Sent : ReplyOutcome()

    /** The notification_key is no longer in the in-memory store. */
    object NoSuchKey : ReplyOutcome()

    /** Notification exists but exposes no Action with a RemoteInput we can fill. */
    object NoReplyAction : ReplyOutcome()

    /** PendingIntent.send threw — typically CanceledException when the source app cleared it. */
    data class IntentFailure(val message: String) : ReplyOutcome()
}
