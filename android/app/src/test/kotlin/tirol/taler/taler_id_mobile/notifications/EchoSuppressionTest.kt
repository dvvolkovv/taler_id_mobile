package tirol.taler.taler_id_mobile.notifications

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Echo suppression behaviour for [NotificationStoreNative].
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 */
class EchoSuppressionTest {

    private val store = NotificationStoreNative.singleton

    @Before
    fun setUp() {
        store.clearForTest()
    }

    @After
    fun tearDown() {
        store.clearForTest()
    }

    private fun captured(
        key: String,
        pkg: String = "com.whatsapp",
        title: String = "Маша",
        body: String = "buy milk",
        conversationTitle: String? = "Маша",
        postTimeMs: Long = 10_000L,
    ): CapturedNotification = CapturedNotification(
        packageName = pkg,
        key = key,
        postTimeMs = postTimeMs,
        title = title,
        body = body,
        conversationTitle = conversationTitle,
        canReply = false,
    )

    @Test
    fun `addPosted within suppression window with matching body is dropped`() {
        val sentAt = 1_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        // 10 seconds later, the messenger echoes our outgoing message.
        val echo = captured(key = "echo1", body = "buy milk", postTimeMs = sentAt + 10_000L)
        val admitted = store.addPosted(echo, now = sentAt + 10_000L)
        assertFalse("Echo should have been suppressed", admitted)
        assertNull(store.findByKey("echo1"))
        // recent() must NOT include it.
        assertTrue(store.recent().none { it.key == "echo1" })
    }

    @Test
    fun `addPosted with fuzzy-matching body within Levenshtein threshold is dropped`() {
        val sentAt = 5_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        // Messenger prefixes with "You: " — handled by stripSelfPrefix; remaining text matches exactly.
        val withPrefix = captured(
            key = "prefix",
            body = "You: buy milk",
            postTimeMs = sentAt + 5_000L,
        )
        assertFalse(store.addPosted(withPrefix, now = sentAt + 5_000L))

        // One-character typo (distance 1) — still within threshold.
        val typo = captured(
            key = "typo",
            body = "buy milks",
            postTimeMs = sentAt + 6_000L,
        )
        assertFalse(store.addPosted(typo, now = sentAt + 6_000L))
    }

    @Test
    fun `addPosted after suppression window expires admits the notification`() {
        val sentAt = 1_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        // 31 seconds later — outside the 30 s suppression window. The body matches exactly,
        // but suppression no longer applies.
        val late = captured(
            key = "late",
            body = "buy milk",
            postTimeMs = sentAt + 31_000L,
        )
        val admitted = store.addPosted(late, now = sentAt + 31_000L)
        assertTrue("Late notification must be admitted", admitted)
        assertEquals(late.key, store.findByKey("late")?.key)
    }

    @Test
    fun `addPosted with non-matching body within window is admitted`() {
        val sentAt = 1_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        // Within window, but completely different text — distance > threshold.
        val different = captured(
            key = "diff",
            body = "what time?",
            postTimeMs = sentAt + 5_000L,
        )
        assertTrue(store.addPosted(different, now = sentAt + 5_000L))
    }

    @Test
    fun `suppression is keyed on package and conversation, not global`() {
        val sentAt = 1_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        // Same body, but different conversation — must NOT be suppressed.
        val otherConvo = captured(
            key = "other",
            conversationTitle = "Олег",
            body = "buy milk",
            postTimeMs = sentAt + 5_000L,
        )
        assertTrue(store.addPosted(otherConvo, now = sentAt + 5_000L))

        // Same body, different package — must NOT be suppressed.
        val otherPkg = captured(
            key = "other2",
            pkg = "org.telegram.messenger",
            conversationTitle = "Маша",
            body = "buy milk",
            postTimeMs = sentAt + 6_000L,
        )
        assertTrue(store.addPosted(otherPkg, now = sentAt + 6_000L))
    }

    @Test
    fun `recent does not include suppressed entries`() {
        val sentAt = 1_000L
        store.markSelfSent(
            packageName = "com.whatsapp",
            conversationOrTitle = "Маша",
            body = "buy milk",
            atMs = sentAt,
        )
        store.addPosted(
            captured(key = "echo", body = "buy milk", postTimeMs = sentAt + 5_000L),
            now = sentAt + 5_000L,
        )
        store.addPosted(
            captured(key = "real", body = "ok thanks", postTimeMs = sentAt + 6_000L),
            now = sentAt + 6_000L,
        )
        val items = store.recent()
        assertEquals(1, items.size)
        assertEquals("real", items.first().key)
    }
}
