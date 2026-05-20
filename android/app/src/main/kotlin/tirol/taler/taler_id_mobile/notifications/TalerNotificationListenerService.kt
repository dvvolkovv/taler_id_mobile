package tirol.taler.taler_id_mobile.notifications

import android.app.Notification
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.lang.ref.WeakReference

/**
 * Android NotificationListenerService implementation.
 *
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 *
 * Single-process per Risk 6 — bound by system_server but lives in the same process as Flutter,
 * so [NotificationStoreNative.singleton] is directly readable from the bridge.
 *
 * Skipped notifications:
 *   * Anything from our own package (own foreground services, FCM, etc.).
 *   * Ongoing or foreground-service notifications (FLAG_ONGOING_EVENT, FLAG_FOREGROUND_SERVICE).
 *   * Echoes of our own outgoing reply within the suppression window (handled in
 *     [NotificationStoreNative.addPosted]).
 */
class TalerNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "TalerNotifListener"

        /**
         * Weak reference to the latest bound instance — used by static [tryReply] so the
         * Flutter bridge can call without having to bind to the service explicitly.
         * Cleared in [onListenerDisconnected].
         */
        private var instanceRef: WeakReference<TalerNotificationListenerService> = WeakReference(null)

        /**
         * Fire an inline reply for [key] with [text]. Looks up the cached
         * [CapturedNotification] from [NotificationStoreNative], builds the RemoteInput
         * bundle, and sends the PendingIntent.
         */
        @JvmStatic
        fun tryReply(key: String, text: String): ReplyOutcome {
            val cached = NotificationStoreNative.singleton.findByKey(key)
                ?: return ReplyOutcome.NoSuchKey
            val action = cached.replyAction
            val remoteInput = cached.remoteInput
            val pi = cached.pendingIntent
            if (action == null || remoteInput == null || pi == null) {
                return ReplyOutcome.NoReplyAction
            }
            return try {
                val context = instanceRef.get()?.applicationContext
                val fillIn = Intent()
                val bundle = Bundle().apply { putCharSequence(remoteInput.resultKey, text) }
                RemoteInput.addResultsToIntent(arrayOf(remoteInput), fillIn, bundle)
                pi.send(context, 0, fillIn)
                // Record self-sent for echo suppression.
                NotificationStoreNative.singleton.markSelfSent(
                    packageName = cached.packageName,
                    conversationOrTitle = cached.conversationTitle ?: cached.title,
                    body = text,
                )
                ReplyOutcome.Sent
            } catch (e: PendingIntent.CanceledException) {
                Log.w(TAG, "PendingIntent cancelled for key=$key: ${e.message}")
                ReplyOutcome.IntentFailure(e.message ?: "PendingIntent cancelled")
            } catch (e: Throwable) {
                Log.w(TAG, "Reply failed for key=$key", e)
                ReplyOutcome.IntentFailure(e.message ?: e.javaClass.simpleName)
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instanceRef = WeakReference(this)
        Log.i(TAG, "Notification listener connected")
        // Replay active notifications so the in-memory buffer is populated immediately on
        // first launch / reinstall. Without this, the buffer is empty until new notifications
        // arrive — leading to the agent saying "no new mail" even when notifications are
        // visibly sitting in the status bar.
        try {
            val active = activeNotifications ?: return
            var replayed = 0
            for (sbn in active) {
                if (sbn.packageName == applicationContext.packageName) continue
                val flags = sbn.notification?.flags ?: 0
                val ignoreMask = Notification.FLAG_FOREGROUND_SERVICE or Notification.FLAG_ONGOING_EVENT
                if (flags and ignoreMask != 0) continue
                val captured = extract(sbn) ?: continue
                if (NotificationStoreNative.singleton.addPosted(captured)) {
                    replayed++
                }
            }
            Log.i(TAG, "Replayed $replayed active notifications on connect")
        } catch (e: Throwable) {
            Log.w(TAG, "Active-notification replay failed", e)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (instanceRef.get() === this) {
            instanceRef = WeakReference(null)
        }
        Log.i(TAG, "Notification listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            if (sbn.packageName == applicationContext.packageName) return
            val flags = sbn.notification.flags
            val ignoreMask = Notification.FLAG_FOREGROUND_SERVICE or Notification.FLAG_ONGOING_EVENT
            if (flags and ignoreMask != 0) return

            val captured = extract(sbn) ?: return
            NotificationStoreNative.singleton.addPosted(captured)
        } catch (e: Throwable) {
            // Don't ever let an extraction error tear down the listener.
            Log.w(TAG, "onNotificationPosted failed", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // v1: no-op. Future work: mark cached entry as dismissed so the agent can be told.
        if (Log.isLoggable(TAG, Log.VERBOSE)) {
            Log.v(TAG, "Notification removed: ${sbn.key}")
        }
    }

    private fun extract(sbn: StatusBarNotification): CapturedNotification? {
        val n = sbn.notification ?: return null
        val extras = n.extras ?: Bundle()

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        val body = if (bigText.isNotBlank()) bigText else text
        val conversationTitle: String? =
            extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()

        // Find first action with a non-empty RemoteInput[] — that's our reply hook.
        var replyAction: Notification.Action? = null
        var remoteInput: RemoteInput? = null
        n.actions?.forEach { action ->
            if (replyAction != null) return@forEach
            val ris = action.remoteInputs
            if (ris != null && ris.isNotEmpty()) {
                // Pick the first text-capable RemoteInput.
                val textInput = ris.firstOrNull { it.allowFreeFormInput } ?: ris.first()
                replyAction = action
                remoteInput = textInput
            }
        }

        val canReply = replyAction != null && remoteInput != null

        return CapturedNotification(
            packageName = sbn.packageName ?: "",
            key = sbn.key ?: "${sbn.packageName}#${sbn.id}",
            postTimeMs = sbn.postTime,
            title = title,
            body = body,
            conversationTitle = conversationTitle,
            canReply = canReply,
            replyAction = replyAction,
            remoteInput = remoteInput,
            pendingIntent = replyAction?.actionIntent,
        )
    }
}
