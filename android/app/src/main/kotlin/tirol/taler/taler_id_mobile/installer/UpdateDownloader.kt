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
import android.util.Log
import androidx.core.app.NotificationCompat
import tirol.taler.taler_id_mobile.MainActivity
import tirol.taler.taler_id_mobile.R
import java.io.File
import java.util.Locale

/**
 * Downloads an update APK with the system DownloadManager, so it survives the
 * app going to the background or being killed, and resumes after the network
 * drops. One download at a time; its id, version and build live in
 * SharedPreferences, so a restarted app picks it up instead of starting over.
 */
object UpdateDownloader {
    private const val TAG = "UpdateDownloader"
    private const val PREFS = "taler_update_download"
    private const val K_ID = "id"
    private const val K_VERSION = "version"
    private const val K_BUILD = "build"
    private const val K_FILE = "file"
    private const val CHANNEL_ID = "app_updates"
    private const val NOTIFICATION_ID = 7301
    const val EXTRA_INSTALL_UPDATE = "install_update"
    private const val UNAVAILABLE = "download_manager_unavailable"

    /** Set when the "downloaded" notification opened the app; Dart consumes it. */
    @Volatile
    var installRequested = false

    fun start(context: Context, url: String, version: String, build: Int): Map<String, Any?> {
        val prefs = prefs(context)
        if (prefs.getLong(K_ID, -1L) != -1L && prefs.getInt(K_BUILD, -1) == build) {
            val current = status(context)
            if (current["state"] in setOf("running", "paused", "ready")) return current
        }
        clear(context) // another version, or a failed attempt: start over
        val dm = downloadManager(context) ?: return failed(UNAVAILABLE)
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: return failed("no_storage")
        val name = "talerid-$version-$build.apk"
        File(dir, name).delete()
        return try {
            val request = DownloadManager.Request(Uri.parse(url))
                .setTitle("Taler ID $version")
                .setMimeType("application/vnd.android.package-archive")
                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                .setAllowedOverMetered(true)
                .setAllowedOverRoaming(true)
                .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, name)
            val id = dm.enqueue(request)
            prefs.edit()
                .putLong(K_ID, id)
                .putString(K_VERSION, version)
                .putInt(K_BUILD, build)
                .putString(K_FILE, File(dir, name).absolutePath)
                .apply()
            status(context)
        } catch (e: Exception) { // DownloadManager disabled on the device, or a bad URL
            Log.e(TAG, "enqueue failed", e)
            failed(UNAVAILABLE)
        }
    }

    fun status(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id == -1L) return mapOf("state" to "none")
        val version = prefs.getString(K_VERSION, null)
        val build = prefs.getInt(K_BUILD, -1)
        val file = prefs.getString(K_FILE, null)
        // The app already runs this build or a newer one: the file did its job.
        if (build.toLong() <= installedBuild(context)) {
            clear(context)
            return mapOf("state" to "none")
        }
        val base = mapOf("version" to version, "build" to build, "file" to file)
        val dm = downloadManager(context) ?: return base + failed(UNAVAILABLE)
        try {
            dm.query(DownloadManager.Query().setFilterById(id))?.use { c ->
                if (!c.moveToFirst()) { // cancelled from the notification shade
                    clear(context)
                    return mapOf("state" to "none")
                }
                val st = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                val done = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                val total = c.getLong(c.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                val reason = c.getInt(c.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                val progress = if (total > 0) done.toDouble() / total else 0.0
                return when (st) {
                    DownloadManager.STATUS_SUCCESSFUL ->
                        if (verify(context, file, build)) base + ("state" to "ready")
                        else {
                            clear(context)
                            mapOf("state" to "failed", "reason" to "bad_apk")
                        }
                    DownloadManager.STATUS_FAILED -> base + mapOf("state" to "failed", "reason" to "error_$reason")
                    DownloadManager.STATUS_PAUSED -> base + mapOf("state" to "paused", "progress" to progress)
                    else -> base + mapOf("state" to "running", "progress" to progress)
                }
            }
        } catch (e: Exception) { // the download provider is disabled or gone
            Log.e(TAG, "query failed", e)
            return base + failed(UNAVAILABLE)
        }
        return mapOf("state" to "none")
    }

    fun isOurDownload(context: Context, id: Long): Boolean =
        id != -1L && prefs(context).getLong(K_ID, -1L) == id

    /** Forgets the download: removes it from DownloadManager (with its file) and our notification. */
    fun clear(context: Context) {
        val prefs = prefs(context)
        val id = prefs.getLong(K_ID, -1L)
        if (id != -1L) {
            try {
                downloadManager(context)?.remove(id)
            } catch (e: Exception) {
                Log.w(TAG, "remove failed: ${e.message}")
            }
        }
        prefs.getString(K_FILE, null)?.let { File(it).delete() }
        prefs.edit().clear().apply()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)?.cancel(NOTIFICATION_ID)
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
            .build()
        try {
            nm.notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) { // POST_NOTIFICATIONS refused on Android 13+
            Log.w(TAG, "notification not allowed: ${e.message}")
        }
    }

    private fun verify(context: Context, path: String?, build: Int): Boolean {
        if (path == null) return false
        val f = File(path)
        if (!f.exists() || f.length() == 0L) return false
        val info = context.packageManager.getPackageArchiveInfo(path, 0) ?: return false
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
        else @Suppress("DEPRECATION") info.versionCode.toLong()
        return info.packageName == context.packageName && code == build.toLong()
    }

    private fun installedBuild(context: Context): Long {
        val pi = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pi.longVersionCode
        else @Suppress("DEPRECATION") pi.versionCode.toLong()
    }

    private fun downloadManager(context: Context): DownloadManager? =
        context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager

    private fun failed(reason: String): Map<String, Any?> = mapOf("state" to "failed", "reason" to reason)

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
