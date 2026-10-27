package tirol.taler.taler_id_mobile.installer

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.NotificationCompat
import tirol.taler.taler_id_mobile.MainActivity
import tirol.taler.taler_id_mobile.R
import java.io.File
import java.util.Locale

/**
 * Downloads an update APK with the system DownloadManager, so it survives the
 * app going to the background or being killed, and resumes after the network
 * drops. One download at a time; its id, url, version and build live in
 * SharedPreferences, so a restarted app picks it up instead of starting over.
 */
object UpdateDownloader {
    private const val TAG = "UpdateDownloader"
    private const val PREFS = "taler_update_download"
    private const val K_ID = "id"
    private const val K_URL = "url"
    private const val K_VERSION = "version"
    private const val K_BUILD = "build"
    private const val K_FILE = "file"
    /** Why the finished file was rejected; the record stays so the next start knows. */
    private const val K_FAILED = "failed"
    /** The download was already started over once after DownloadManager couldn't resume it. */
    private const val K_RESTARTED = "restarted"
    /**
     * A URL that served another app's APK (TEST is sent to PROD). Not part of
     * the per-download record: [clear] keeps it, so every new build from the
     * same link goes straight to the browser instead of costing a download.
     */
    private const val K_FOREIGN_URL = "foreign_url"
    private const val CHANNEL_ID = "app_updates"
    private const val NOTIFICATION_ID = 7301
    const val EXTRA_INSTALL_UPDATE = "install_update"
    private const val UNAVAILABLE = "download_manager_unavailable"
    /** Same string as UpdateDownloadStatus.channelError: state unknown, Dart keeps what it knew. */
    private const val CHANNEL_ERROR = "channel_error"
    private const val WRONG_PACKAGE = "wrong_package"
    /** The old in-app banner downloaded here (getTemporaryDirectory) and never cleaned up. */
    private const val LEGACY_CACHE_APK = "taler_id_update.apk"

    /** Set when the "downloaded" notification opened the app; Dart consumes it. */
    @Volatile
    var installRequested = false

    fun start(context: Context, url: String, version: String, build: Int): Map<String, Any?> {
        val prefs = prefs(context)
        // This link served another app's APK before: any build from it would
        // too, so Dart sends the user to the browser. A new link gets a download.
        if (url == prefs.getString(K_FOREIGN_URL, null)) return failed(WRONG_PACKAGE)
        if (prefs.getLong(K_ID, -1L) != -1L && prefs.getInt(K_BUILD, -1) == build) {
            val current = status(context)
            if (current["state"] in setOf("running", "paused", "ready")) return current
            // We only failed to ask about it: the download itself may be fine.
            if (current["reason"] == CHANNEL_ERROR) return current
        }
        // Another version, a failed attempt or a rejected file (Retry, the
        // server may have fixed it): start over.
        return enqueue(context, url, version, build, restarted = false)
    }

    fun status(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id == -1L) return mapOf("state" to "none")
        val url = prefs.getString(K_URL, null)
        val version = prefs.getString(K_VERSION, null)
        val build = prefs.getInt(K_BUILD, -1)
        val file = prefs.getString(K_FILE, null)
        // The app already runs this build or a newer one: the file did its job.
        if (build.toLong() <= installedBuild(context)) {
            clear(context)
            return mapOf("state" to "none")
        }
        val base = mapOf("version" to version, "build" to build, "file" to file)
        prefs.getString(K_FAILED, null)?.let { return base + failed(it) }
        val dm = downloadManager(context) ?: return channelError()
        var restart = false
        try {
            val c = dm.query(DownloadManager.Query().setFilterById(id)) ?: return channelError()
            c.use { _ ->
                if (!c.moveToFirst()) { // cancelled from the notification shade
                    clear(context)
                    return mapOf("state" to "none")
                }
                val st = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                val done = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                val total = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                val reason = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                val progress = if (total > 0) done.toDouble() / total else 0.0
                when (st) {
                    DownloadManager.STATUS_SUCCESSFUL -> {
                        // DownloadManager renames on a name clash (talerid-X-N-1.apk):
                        // the file it actually wrote is the one to check and install.
                        val local = c.getString(c.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                            ?.let { Uri.parse(it) }
                            ?.takeIf { it.scheme == "file" }
                            ?.path
                        val path = local ?: file
                        if (path != file) prefs.edit().putString(K_FILE, path).apply()
                        val bad = verify(context, path, build)
                        if (bad == null) {
                            // The link serves our package again.
                            if (url != null && url == prefs.getString(K_FOREIGN_URL, null)) {
                                prefs.edit().remove(K_FOREIGN_URL).apply()
                            }
                            return base + mapOf("file" to path, "state" to "ready")
                        }
                        reject(context, id, path, bad)
                        return base + mapOf("file" to path) + failed(bad)
                    }
                    DownloadManager.STATUS_FAILED -> {
                        // 412 on resume (the file changed under the URL) and the
                        // like: DownloadManager gives up. Once, start from scratch.
                        if (reason == DownloadManager.ERROR_CANNOT_RESUME &&
                            url != null && version != null && !prefs.getBoolean(K_RESTARTED, false)
                        ) {
                            restart = true
                        } else {
                            return base + failed("error_$reason")
                        }
                    }
                    DownloadManager.STATUS_PAUSED -> return base + mapOf("state" to "paused", "progress" to progress)
                    else -> return base + mapOf("state" to "running", "progress" to progress)
                }
            }
        } catch (e: Exception) { // the download provider is disabled or gone
            Log.e(TAG, "query failed", e)
            return channelError()
        }
        if (restart && url != null && version != null) {
            Log.i(TAG, "download $id cannot resume, starting $version ($build) over")
            return enqueue(context, url, version, build, restarted = true)
        }
        return channelError()
    }

    fun isOurDownload(context: Context, id: Long): Boolean =
        id != -1L && prefs(context).getLong(K_ID, -1L) == id

    /** Forgets the download: removes it from DownloadManager (with its file) and our notification. */
    fun clear(context: Context) {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id != -1L) remove(context, id)
        prefs.getString(K_FILE, null)?.let { File(it).delete() }
        val foreign = prefs.getString(K_FOREIGN_URL, null)
        // An editor applies clear() before its puts: only the record goes.
        val editor = prefs.edit().clear()
        if (foreign != null) editor.putString(K_FOREIGN_URL, foreign)
        editor.apply()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)?.cancel(NOTIFICATION_ID)
    }

    /**
     * The downloaded file failed a later check (the installer's signature
     * check): it goes, the record stays with [reason], so the card shows the
     * failure with Retry instead of quietly going back to Update.
     */
    fun reject(context: Context, reason: String) {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id == -1L) return
        reject(context, id, prefs.getString(K_FILE, null), reason)
    }

    /**
     * Deletes the copies the old in-app banner put into the public Downloads
     * as talerid-<version>.apk on every update and never removed: gigabytes on
     * a long-time Android 10+ user. Only rows this app owns, and only on
     * Android 11+, where OWNER_PACKAGE_NAME is a reliable filter; on 10 a
     * query can also see what the user downloaded with the browser (the
     * TEST → PROD talerid.apk), and that is never ours to delete.
     */
    fun cleanupLegacyDownloads(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        try {
            val where = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? AND " +
                "${MediaStore.MediaColumns.OWNER_PACKAGE_NAME} = ?"
            val removed = context.contentResolver.delete(
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                where,
                arrayOf("talerid-%.apk", context.packageName),
            )
            if (removed > 0) Log.i(TAG, "removed $removed old update copies from Downloads")
        } catch (e: Exception) {
            Log.w(TAG, "Downloads cleanup failed: ${e.message}")
        }
    }

    /** Deletes what the old in-app banner left in the cache: up to a whole APK per device. */
    fun cleanupLegacy(context: Context) {
        try {
            File(context.cacheDir, LEGACY_CACHE_APK).delete()
        } catch (e: Exception) {
            Log.w(TAG, "legacy cleanup failed: ${e.message}")
        }
    }

    fun showReadyNotification(context: Context) {
        val version = prefs(context).getString(K_VERSION, "") ?: ""
        val ru = Locale.getDefault().language == "ru"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    if (ru) "Обновления" else "Updates",
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
            )
        }
        val open = Intent(context, MainActivity::class.java).apply {
            putExtra(EXTRA_INSTALL_UPDATE, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pi = PendingIntent.getActivity(
            context, NOTIFICATION_ID, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(if (ru) "Обновление $version скачано" else "Update $version downloaded")
            .setContentText(if (ru) "Нажмите, чтобы установить" else "Tap to install")
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()
        try {
            nm.notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) { // POST_NOTIFICATIONS refused on Android 13+
            Log.w(TAG, "notification not allowed: ${e.message}")
        }
    }

    /** Enqueues a fresh download of [build], forgetting whatever was there before. */
    private fun enqueue(
        context: Context,
        url: String,
        version: String,
        build: Int,
        restarted: Boolean,
    ): Map<String, Any?> {
        clear(context)
        cleanupLegacy(context)
        val dm = downloadManager(context) ?: return failed(UNAVAILABLE)
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: return failed("no_storage")
        // Only our downloads live here: anything left is an earlier attempt.
        dir.listFiles()
            ?.filter { it.name.startsWith("talerid-") && it.name.endsWith(".apk") }
            ?.forEach { it.delete() }
        val name = "talerid-$version-$build.apk"
        return try {
            val request = DownloadManager.Request(Uri.parse(url))
                .setTitle("Taler ID $version")
                .setMimeType("application/vnd.android.package-archive")
                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                .setAllowedOverMetered(true)
                .setAllowedOverRoaming(true)
                .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, name)
            val id = dm.enqueue(request)
            prefs(context).edit()
                .putLong(K_ID, id)
                .putString(K_URL, url)
                .putString(K_VERSION, version)
                .putInt(K_BUILD, build)
                .putString(K_FILE, File(dir, name).absolutePath)
                .putBoolean(K_RESTARTED, restarted)
                .apply()
            status(context)
        } catch (e: Exception) { // DownloadManager disabled on the device, or a bad URL
            Log.e(TAG, "enqueue failed", e)
            failed(UNAVAILABLE)
        }
    }

    /**
     * The finished file is not the build we want: drop it, but remember why,
     * so the next start doesn't spend another download on the same answer.
     */
    private fun reject(context: Context, id: Long, path: String?, reason: String) {
        Log.w(TAG, "downloaded file rejected: $reason")
        remove(context, id)
        path?.let { File(it).delete() }
        val prefs = prefs(context)
        val url = prefs.getString(K_URL, null)
        val editor = prefs.edit().putString(K_FAILED, reason)
        if (reason == WRONG_PACKAGE && url != null) editor.putString(K_FOREIGN_URL, url)
        editor.apply()
    }

    /** null when [path] is our package at [build]; otherwise what is wrong with it. */
    private fun verify(context: Context, path: String?, build: Int): String? {
        if (path == null) return "unparseable"
        return try {
            val f = File(path)
            if (!f.exists() || f.length() == 0L) return "unparseable"
            val info = context.packageManager.getPackageArchiveInfo(path, 0) ?: return "unparseable"
            val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
            else @Suppress("DEPRECATION") info.versionCode.toLong()
            when {
                info.packageName != context.packageName -> WRONG_PACKAGE
                code != build.toLong() -> "wrong_build"
                else -> null
            }
        } catch (e: Exception) {
            Log.w(TAG, "verify failed: ${e.message}")
            "unparseable"
        }
    }

    private fun remove(context: Context, id: Long) {
        try {
            downloadManager(context)?.remove(id)
        } catch (e: Exception) {
            Log.w(TAG, "remove failed: ${e.message}")
        }
    }

    private fun installedBuild(context: Context): Long {
        val pi = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pi.longVersionCode
        else @Suppress("DEPRECATION") pi.versionCode.toLong()
    }

    private fun downloadManager(context: Context): DownloadManager? =
        context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager

    private fun failed(reason: String): Map<String, Any?> = mapOf("state" to "failed", "reason" to reason)

    private fun channelError(): Map<String, Any?> = failed(CHANNEL_ERROR)

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
