package tirol.taler.taler_id_mobile.notifications

import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentLinkedDeque

/**
 * Singleton in-memory store of recent notifications captured by
 * [TalerNotificationListenerService], plus echo-suppression bookkeeping.
 *
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 *
 * Threading: callbacks may arrive on the listener's binder thread; reads come from the Flutter
 * main thread via [NotificationBridge]. Backing structure is a [ConcurrentLinkedDeque] capped at
 * [MAX_ENTRIES]; mutating operations that read-then-write are wrapped in `synchronized(lock)`.
 *
 * Design choices (per plan):
 *   * No Kotlin coroutines — plain blocking + concurrent primitives.
 *   * Ring buffer: newest at the head; on overflow the oldest tail entry is evicted.
 *   * Echo suppression: when [markSelfSent] records a body, subsequent [addPosted] calls within
 *     [ECHO_TTL_MS] for the same package + (conversationTitle ?: title) whose body fuzzy-matches
 *     the recorded body (Levenshtein <= [ECHO_LEVENSHTEIN_THRESHOLD], case-insensitive, trimmed)
 *     are dropped and never reach the ring buffer or the EventSink.
 *   * 30 s window for suppression check; 60 s TTL before the echo entry is dropped.
 */
class NotificationStoreNative private constructor() {

    companion object {
        const val MAX_ENTRIES = 200
        const val ECHO_TTL_MS: Long = 60_000L
        const val ECHO_SUPPRESSION_WINDOW_MS: Long = 30_000L
        const val ECHO_LEVENSHTEIN_THRESHOLD: Int = 3

        @JvmStatic
        val singleton: NotificationStoreNative by lazy { NotificationStoreNative() }
    }

    private val lock = Any()
    private val buffer = ConcurrentLinkedDeque<CapturedNotification>()

    /** Echo suppression entries: pkg + conversationOrTitle -> recorded reply body + timestamp. */
    private data class EchoEntry(val body: String, val sentAtMs: Long)

    private val echoMap = HashMap<String, EchoEntry>()

    /**
     * The EventSink, if a Flutter listener is currently attached via
     * [io.flutter.plugin.common.EventChannel]. Updated from the Flutter main thread under [lock];
     * reads are best-effort.
     */
    @Volatile
    var eventSink: EventChannel.EventSink? = null

    // --- Public API -----------------------------------------------------------------------

    /**
     * Try to admit a freshly-posted notification.
     *
     * Returns true if it was admitted (added to the ring buffer + forwarded to the EventSink),
     * false if it was suppressed as an echo of our own outgoing reply.
     *
     * @param now caller-supplied current time in millis (injectable for tests).
     */
    fun addPosted(n: CapturedNotification, now: Long = System.currentTimeMillis()): Boolean {
        synchronized(lock) {
            pruneEchoMapLocked(now)
            if (isEchoLocked(n, now)) {
                return false
            }
            // Drop any stale entry with the same key (shouldn't normally happen — but defensive).
            removeByKeyLocked(n.key)
            buffer.addFirst(n)
            while (buffer.size > MAX_ENTRIES) {
                buffer.pollLast()
            }
        }
        // Forward outside the lock to avoid holding it across Flutter binder calls.
        try {
            eventSink?.success(n.toMap())
        } catch (_: Throwable) {
            // EventSink may be torn down concurrently; swallow.
        }
        return true
    }

    /**
     * Return matching notifications, newest first. All filter fields are optional.
     *
     * @param pkgSubstring case-insensitive substring of [CapturedNotification.packageName].
     * @param senderSubstring case-insensitive substring of [CapturedNotification.conversationTitle]
     *   (falling back to [CapturedNotification.title]).
     * @param sinceMs only entries with `postTimeMs >= sinceMs`.
     * @param limit positive max count; null means unlimited (up to [MAX_ENTRIES]).
     */
    fun recent(
        pkgSubstring: String? = null,
        senderSubstring: String? = null,
        sinceMs: Long? = null,
        limit: Int? = null,
    ): List<CapturedNotification> {
        val pkgLc = pkgSubstring?.lowercase()
        val senderLc = senderSubstring?.lowercase()
        // Snapshot under lock to avoid ConcurrentModification surprises on iteration.
        val snapshot = synchronized(lock) { buffer.toList() }
        val filtered = snapshot.asSequence()
            .filter { n ->
                if (pkgLc != null && !n.packageName.lowercase().contains(pkgLc)) return@filter false
                if (senderLc != null) {
                    val haystack = (n.conversationTitle ?: n.title).lowercase()
                    if (!haystack.contains(senderLc)) return@filter false
                }
                if (sinceMs != null && n.postTimeMs < sinceMs) return@filter false
                true
            }
        return if (limit != null && limit > 0) filtered.take(limit).toList() else filtered.toList()
    }

    /** Lookup a notification by its [CapturedNotification.key] (StatusBarNotification.key). */
    fun findByKey(key: String): CapturedNotification? {
        synchronized(lock) {
            return buffer.firstOrNull { it.key == key }
        }
    }

    /**
     * Record that we (the agent) just fired an inline reply. Subsequent inbound notifications
     * matching this body within [ECHO_SUPPRESSION_WINDOW_MS] for the same conversation are
     * dropped silently. Entry expires after [ECHO_TTL_MS].
     */
    fun markSelfSent(
        packageName: String,
        conversationOrTitle: String,
        body: String,
        atMs: Long = System.currentTimeMillis(),
    ) {
        synchronized(lock) {
            echoMap[echoKey(packageName, conversationOrTitle)] = EchoEntry(body.trim(), atMs)
            pruneEchoMapLocked(atMs)
        }
    }

    /** Drop everything. Test-only. */
    fun clearForTest() {
        synchronized(lock) {
            buffer.clear()
            echoMap.clear()
        }
        eventSink = null
    }

    // --- Private --------------------------------------------------------------------------

    private fun removeByKeyLocked(key: String) {
        val it = buffer.iterator()
        while (it.hasNext()) {
            if (it.next().key == key) {
                it.remove()
                return
            }
        }
    }

    private fun pruneEchoMapLocked(now: Long) {
        val it = echoMap.entries.iterator()
        while (it.hasNext()) {
            val e = it.next()
            if (now - e.value.sentAtMs > ECHO_TTL_MS) {
                it.remove()
            }
        }
    }

    private fun isEchoLocked(n: CapturedNotification, now: Long): Boolean {
        val key = echoKey(n.packageName, n.conversationTitle ?: n.title)
        val entry = echoMap[key] ?: return false
        if (now - entry.sentAtMs > ECHO_SUPPRESSION_WINDOW_MS) return false
        val incoming = n.body.trim()
        // Strip a leading "You: " or similar self-prefix that some messengers add to their
        // own confirmation notifications.
        val incomingStripped = stripSelfPrefix(incoming)
        val distance = levenshtein(incomingStripped.lowercase(), entry.body.lowercase())
        return distance <= ECHO_LEVENSHTEIN_THRESHOLD
    }

    private fun echoKey(pkg: String, conv: String): String = "$pkg::$conv"

    private fun stripSelfPrefix(text: String): String {
        // Common self-echo prefixes used by WhatsApp/Telegram/SMS. Case-insensitive.
        val prefixes = listOf("you: ", "ты: ", "вы: ")
        val lower = text.lowercase()
        for (p in prefixes) {
            if (lower.startsWith(p)) return text.substring(p.length).trim()
        }
        return text
    }

    /** Iterative Levenshtein distance. Returns Int.MAX_VALUE / 2 sentinel for null safety. */
    internal fun levenshtein(a: String, b: String): Int {
        if (a == b) return 0
        if (a.isEmpty()) return b.length
        if (b.isEmpty()) return a.length
        val n = a.length
        val m = b.length
        var prev = IntArray(m + 1) { it }
        var curr = IntArray(m + 1)
        for (i in 1..n) {
            curr[0] = i
            for (j in 1..m) {
                val cost = if (a[i - 1] == b[j - 1]) 0 else 1
                curr[j] = minOf(
                    prev[j] + 1,        // deletion
                    curr[j - 1] + 1,    // insertion
                    prev[j - 1] + cost, // substitution
                )
            }
            val tmp = prev
            prev = curr
            curr = tmp
        }
        return prev[m]
    }
}
