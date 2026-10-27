package tirol.taler.taler_id_mobile.installer

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import tirol.taler.taler_id_mobile.MainActivity

/**
 * Declared in the manifest, so it fires even when the app is not running.
 *
 * A finished download: on screen the app polls the status and offers the
 * install itself; off screen it can't open the installer (Android 10+ blocks
 * activity starts from the background), so it gets a "downloaded — tap to
 * install" notification. Asking for the status also restarts a download that
 * DownloadManager could not resume.
 *
 * The app was updated: the downloaded APK, its record and the notification
 * are no longer needed, nor is the old banner's copy in the cache.
 */
class UpdateDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // A crash here would kill a process the user isn't even looking at.
        try {
            when (intent.action) {
                DownloadManager.ACTION_DOWNLOAD_COMPLETE -> {
                    val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
                    if (!UpdateDownloader.isOurDownload(context, id)) return
                    if (MainActivity.isInForeground) return
                    if (UpdateDownloader.status(context)["state"] == "ready") {
                        UpdateDownloader.showReadyNotification(context)
                    }
                }
                Intent.ACTION_MY_PACKAGE_REPLACED -> {
                    // Clears the file, the record and the notification once the
                    // installed build has caught up with the downloaded one.
                    UpdateDownloader.status(context)
                    UpdateDownloader.cleanupLegacy(context)
                }
            }
        } catch (e: Exception) {
            Log.e("UpdateDownloadReceiver", "${intent.action} handling failed", e)
        }
    }
}
