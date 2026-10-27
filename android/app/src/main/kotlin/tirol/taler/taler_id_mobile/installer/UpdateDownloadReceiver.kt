package tirol.taler.taler_id_mobile.installer

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import tirol.taler.taler_id_mobile.MainActivity

/**
 * Declared in the manifest, so it fires even when the app is not running.
 * On screen the app polls the status and offers the install itself; off
 * screen it can't open the installer (Android 10+ blocks activity starts from
 * the background), so it gets a "downloaded — tap to install" notification.
 */
class UpdateDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        // A crash here would kill a process the user isn't even looking at.
        try {
            val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
            if (!UpdateDownloader.isOurDownload(context, id)) return
            if (MainActivity.isInForeground) return
            if (UpdateDownloader.status(context)["state"] == "ready") {
                UpdateDownloader.showReadyNotification(context)
            }
        } catch (e: Exception) {
            Log.e("UpdateDownloadReceiver", "download complete handling failed", e)
        }
    }
}
