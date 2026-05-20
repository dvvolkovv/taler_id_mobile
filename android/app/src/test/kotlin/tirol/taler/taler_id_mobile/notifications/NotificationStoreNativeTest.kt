package tirol.taler.taler_id_mobile.notifications

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Pure-JVM unit tests for [NotificationStoreNative] — no Android dependencies are touched.
 * Phase 1A — see docs/superpowers/plans/2026-05-20-agent-shell-phase-1a-notification-listener.md
 */
class NotificationStoreNativeTest {

    private val store = NotificationStoreNative.singleton

    @Before
    fun setUp() {
        store.clearForTest()
    }

    @After
    fun tearDown() {
        store.clearForTest()
    }

    private fun makeNotification(
        key: String,
        pkg: String = "com.whatsapp",
        title: String = "Маша",
        body: String = "Привет",
        conversationTitle: String? = null,
        postTimeMs: Long = 1_000L,
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
    fun `addPosted evicts oldest entry when buffer exceeds MAX_ENTRIES`() {
        // Insert MAX_ENTRIES + 5 distinct notifications.
        val overflow = 5
        for (i in 0 until NotificationStoreNative.MAX_ENTRIES + overflow) {
            store.addPosted(makeNotification(key = "k$i", postTimeMs = i.toLong()))
        }
        val all = store.recent()
        assertEquals(NotificationStoreNative.MAX_ENTRIES, all.size)
        // The oldest `overflow` entries should be gone (keys k0..k(overflow-1)).
        assertNull(store.findByKey("k0"))
        assertNull(store.findByKey("k${overflow - 1}"))
        // The newest entry should still be there at the head.
        assertEquals("k${NotificationStoreNative.MAX_ENTRIES + overflow - 1}", all.first().key)
    }

    @Test
    fun `recent filters by package substring case-insensitively`() {
        store.addPosted(makeNotification(key = "w1", pkg = "com.whatsapp"))
        store.addPosted(makeNotification(key = "t1", pkg = "org.telegram.messenger"))
        store.addPosted(makeNotification(key = "s1", pkg = "com.google.android.apps.messaging"))

        val whatsapp = store.recent(pkgSubstring = "WhatsApp")
        assertEquals(1, whatsapp.size)
        assertEquals("w1", whatsapp.first().key)

        val telegram = store.recent(pkgSubstring = "telegram")
        assertEquals(1, telegram.size)
        assertEquals("t1", telegram.first().key)
    }

    @Test
    fun `recent excludes entries older than sinceMs`() {
        val tenMinAgo = 1_000_000L
        val now = tenMinAgo + 10 * 60_000L
        store.addPosted(makeNotification(key = "old", postTimeMs = tenMinAgo))
        store.addPosted(makeNotification(key = "fresh", postTimeMs = now))

        val fiveMinAgoCutoff = now - 5 * 60_000L
        val recent = store.recent(sinceMs = fiveMinAgoCutoff)
        assertEquals(1, recent.size)
        assertEquals("fresh", recent.first().key)
    }

    @Test
    fun `recent matches sender substring against conversationTitle then title`() {
        store.addPosted(
            makeNotification(key = "k1", title = "WhatsApp", conversationTitle = "Маша Петрова"),
        )
        store.addPosted(
            makeNotification(key = "k2", title = "Олег Сидоров", conversationTitle = null),
        )
        store.addPosted(
            makeNotification(key = "k3", title = "Random", conversationTitle = "Group chat"),
        )

        val masha = store.recent(senderSubstring = "Маша")
        assertEquals(1, masha.size)
        assertEquals("k1", masha.first().key)

        val oleg = store.recent(senderSubstring = "Олег")
        assertEquals(1, oleg.size)
        assertEquals("k2", oleg.first().key)
    }

    @Test
    fun `recent respects positive limit`() {
        for (i in 0 until 10) {
            store.addPosted(makeNotification(key = "k$i", postTimeMs = i.toLong()))
        }
        val three = store.recent(limit = 3)
        assertEquals(3, three.size)
        // Newest first: k9, k8, k7.
        assertEquals(listOf("k9", "k8", "k7"), three.map { it.key })
    }

    @Test
    fun `findByKey returns the correct notification or null`() {
        store.addPosted(makeNotification(key = "findme"))
        assertNotNull(store.findByKey("findme"))
        assertNull(store.findByKey("missing"))
    }

    @Test
    fun `levenshtein distance is correct for sample strings`() {
        assertEquals(0, store.levenshtein("hello", "hello"))
        assertEquals(1, store.levenshtein("hello", "hallo"))
        assertEquals(3, store.levenshtein("kitten", "sitting"))
        assertEquals(5, store.levenshtein("", "hello"))
    }
}
