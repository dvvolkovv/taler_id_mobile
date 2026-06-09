package tirol.taler.taler_id_mobile.installer

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class ApkInstaller(private val context: Context, engine: FlutterEngine) {
    companion object {
        private const val CHANNEL = "taler_id/installer"
        private const val ACTION_INSTALL_RESULT = "tirol.taler.taler_id_mobile.INSTALL_RESULT"
        private const val TAG = "ApkInstaller"
    }

    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
    private var pendingResult: MethodChannel.Result? = null
    private var receiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "install" -> {
                    val path = call.argument<String>("path")
                    val displayName = call.argument<String>("displayName") ?: "talerid-update.apk"
                    if (path == null) {
                        result.error("invalid_args", "path required", null)
                        return@setMethodCallHandler
                    }
                    install(File(path), displayName, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun install(apk: File, displayName: String, result: MethodChannel.Result) {
        if (!apk.exists() || apk.length() == 0L) {
            result.success(mapOf("status" to "downloadFailed", "message" to "APK missing or empty"))
            return
        }

        try { copyToDownloads(apk, displayName) }
        catch (e: Exception) { Log.w(TAG, "MediaStore copy failed: ${e.message}") }

        try {
            val installer = context.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
                setAppPackageName(context.packageName)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
                }
            }
            val sessionId = installer.createSession(params)
            val session = installer.openSession(sessionId)

            FileInputStream(apk).use { input ->
                session.openWrite(displayName, 0, apk.length()).use { output ->
                    input.copyTo(output, bufferSize = 64 * 1024)
                    session.fsync(output)
                }
            }

            registerReceiver(result)

            val intent = Intent(ACTION_INSTALL_RESULT).apply { setPackage(context.packageName) }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pi = PendingIntent.getBroadcast(context, sessionId, intent, flags)
            session.commit(pi.intentSender)
            session.close()
        } catch (e: Exception) {
            Log.e(TAG, "install threw", e)
            deliver(mapOf("status" to "failureUnknown", "message" to (e.message ?: "install threw")))
        }
    }

    private fun registerReceiver(result: MethodChannel.Result) {
        pendingResult?.let { try { it.success(mapOf("status" to "aborted", "message" to "superseded")) } catch (_: Exception) {} }
        pendingResult = result
        if (receiver != null) return

        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val status = intent?.getIntExtra(PackageInstaller.EXTRA_STATUS, -999) ?: -999
                val msg = intent?.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE) ?: ""
                if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                    val confirm = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                    if (confirm != null) {
                        confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try { context.startActivity(confirm) }
                        catch (e: Exception) {
                            Log.e(TAG, "confirm activity launch failed", e)
                            deliver(mapOf("status" to "failureUnknown", "message" to (e.message ?: "")))
                        }
                    }
                    return
                }
                deliver(mapOf("status" to statusToString(status), "message" to msg))
            }
        }
        val filter = IntentFilter(ACTION_INSTALL_RESULT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    private fun statusToString(status: Int): String = when (status) {
        PackageInstaller.STATUS_SUCCESS -> "success"
        PackageInstaller.STATUS_FAILURE_CONFLICT -> "conflict"
        PackageInstaller.STATUS_FAILURE_INCOMPATIBLE -> "incompatible"
        PackageInstaller.STATUS_FAILURE_BLOCKED -> "blocked"
        PackageInstaller.STATUS_FAILURE_ABORTED -> "aborted"
        PackageInstaller.STATUS_FAILURE_STORAGE -> "storage"
        PackageInstaller.STATUS_FAILURE_INVALID -> "invalid"
        PackageInstaller.STATUS_FAILURE -> "failureUnknown"
        else -> "failureUnknown"
    }

    private fun deliver(payload: Map<String, Any?>) {
        val r = pendingResult
        pendingResult = null
        receiver?.let { try { context.unregisterReceiver(it) } catch (_: Exception) {} }
        receiver = null
        try { r?.success(payload) } catch (_: Exception) {}
    }

    private fun copyToDownloads(src: File, displayName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val resolver = context.contentResolver
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val sel = "${MediaStore.Downloads.DISPLAY_NAME}=?"
        resolver.query(collection, arrayOf(MediaStore.Downloads._ID), sel, arrayOf(displayName), null)?.use { c ->
            while (c.moveToNext()) {
                val id = c.getLong(0)
                resolver.delete(android.content.ContentUris.withAppendedId(collection, id), null, null)
            }
        }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, "application/vnd.android.package-archive")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: return
        resolver.openOutputStream(uri)?.use { out ->
            FileInputStream(src).use { it.copyTo(out, 64 * 1024) }
        }
        val finalValues = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
        resolver.update(uri, finalValues, null, null)
    }
}
