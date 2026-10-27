package tirol.taler.taler_id_mobile.installer

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class ApkInstaller(private val context: Context, engine: FlutterEngine) {
    companion object {
        private const val CHANNEL = "taler_id/installer"
        private const val ACTION_INSTALL_RESULT = "tirol.taler.taler_id_mobile.INSTALL_RESULT"
        private const val TAG = "ApkInstaller"
        private const val UNTRUSTED = "untrusted_signature"

        // Certificates our APKs are signed with: aeza builds (dev + TEST flavors,
        // debug keystore on the aeza build host) and PROD (talerid upload key).
        private val OUR_SIGNERS = setOf(
            "550899753325b9d61b7170fd770a13b582d6ee413c6f25c0c8d9af879e0c4499",
            "12d7ab5036595e5109ef432773ff23c63f620d234e5695c67a742f2e1f4c9b8d",
        )
    }

    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

    /**
     * Writes the session, checks signatures, copies to Downloads: each one
     * reads the whole APK, and the main thread here is also Flutter's UI thread.
     */
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    // The install in flight and its result receiver. Main thread only.
    private var pendingResult: MethodChannel.Result? = null
    private var pendingApk: File? = null
    private var pendingName: String? = null
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
                "startDownload" -> {
                    val url = call.argument<String>("url")
                    val version = call.argument<String>("version")
                    val build = call.argument<Int>("build")
                    if (url == null || version == null || build == null) {
                        result.error("invalid_args", "url, version and build required", null)
                        return@setMethodCallHandler
                    }
                    result.success(UpdateDownloader.start(context, url, version, build))
                }
                "downloadStatus" -> result.success(UpdateDownloader.status(context))
                "cancelDownload" -> {
                    UpdateDownloader.clear(context)
                    result.success(null)
                }
                "consumeInstallRequest" -> {
                    val requested = UpdateDownloader.installRequested
                    UpdateDownloader.installRequested = false
                    result.success(requested)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Main thread. Fills the installer session off it and commits back on it. */
    private fun install(apk: File, displayName: String, result: MethodChannel.Result) {
        if (!apk.exists() || apk.length() == 0L) {
            result.success(payload("downloadFailed", "APK missing or empty"))
            return
        }
        // Takes the result over before any work, so a failure while writing
        // answers this call rather than an earlier one.
        registerReceiver(result, apk, displayName)
        io.execute {
            var session: PackageInstaller.Session? = null
            try {
                val installer = context.packageManager.packageInstaller
                val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
                    setAppPackageName(context.packageName)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
                    }
                }
                val sessionId = installer.createSession(params)
                val opened = installer.openSession(sessionId)
                session = opened

                FileInputStream(apk).use { input ->
                    opened.openWrite(displayName, 0, apk.length()).use { output ->
                        input.copyTo(output, bufferSize = 64 * 1024)
                        opened.fsync(output)
                    }
                }
                main.post { commit(result, opened, sessionId) }
            } catch (e: Exception) {
                Log.e(TAG, "install threw", e)
                session?.let { abandon(it) }
                main.post { finish(result, payload("failureUnknown", e.message ?: "install threw")) }
            }
        }
    }

    /** Main thread. Hands the written session to the system installer. */
    private fun commit(result: MethodChannel.Result, session: PackageInstaller.Session, sessionId: Int) {
        if (pendingResult !== result) { // another install took over meanwhile
            abandon(session)
            return
        }
        try {
            val intent = Intent(ACTION_INSTALL_RESULT).apply { setPackage(context.packageName) }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pi = PendingIntent.getBroadcast(context, sessionId, intent, flags)
            session.commit(pi.intentSender)
        } catch (e: Exception) {
            Log.e(TAG, "commit threw", e)
            abandon(session)
            finish(result, payload("failureUnknown", e.message ?: "commit threw"))
            return
        }
        try { session.close() } catch (_: Exception) {}
    }

    /** Main thread. */
    private fun registerReceiver(result: MethodChannel.Result, apk: File, displayName: String) {
        pendingResult?.let { try { it.success(payload("aborted", "superseded")) } catch (_: Exception) {} }
        pendingResult = result
        pendingApk = apk
        pendingName = displayName
        if (receiver != null) return

        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val status = intent?.getIntExtra(PackageInstaller.EXTRA_STATUS, -999) ?: -999
                val msg = intent?.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE) ?: ""
                if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                    val confirm = intent?.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                    if (confirm != null) {
                        confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try { context.startActivity(confirm) }
                        catch (e: Exception) {
                            Log.e(TAG, "confirm activity launch failed", e)
                            deliver(payload("failureUnknown", e.message ?: ""))
                        }
                    }
                    return
                }
                onFinalStatus(statusToString(status), msg)
            }
        }
        val filter = IntentFilter(ACTION_INSTALL_RESULT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    /**
     * Main thread. A failed install leaves a copy in Downloads for installing
     * by hand, but only of an APK we signed: on Android 7–10 any app with the
     * storage permission can replace the file in our external files dir, and
     * the conflict dialog tells the user to uninstall Taler ID and install
     * that copy. The check hashes the whole APK, so it runs off this thread.
     */
    private fun onFinalStatus(status: String, message: String) {
        val result = pendingResult
        val apk = pendingApk
        val name = pendingName
        if (status == "success" || status == "aborted" || result == null || apk == null || name == null) {
            deliver(payload(status, message))
            return
        }
        io.execute {
            val ours = signedByUs(apk)
            val saved = ours && try {
                copyToDownloads(apk, name)
            } catch (e: Exception) {
                Log.w(TAG, "MediaStore copy failed: ${e.message}")
                false
            }
            main.post {
                if (pendingResult !== result) return@post // answered as superseded already
                if (ours) {
                    deliver(payload(status, message, savedToDownloads = saved))
                } else {
                    Log.w(TAG, "downloaded APK is not signed by us, deleting it")
                    UpdateDownloader.clear(context)
                    apk.delete()
                    deliver(payload("invalid", UNTRUSTED))
                }
            }
        }
    }

    /** Whether every certificate [apk] is signed with is one of ours; false when unreadable. */
    private fun signedByUs(apk: File): Boolean = try {
        val digests = signerDigests(apk.path)
        digests.isNotEmpty() && digests.all { it in OUR_SIGNERS }
    } catch (e: Exception) {
        Log.w(TAG, "signature check failed: ${e.message}")
        false
    }

    /** SHA-256 (hex) of each signing certificate of the archive at [path]. */
    private fun signerDigests(path: String): List<String> {
        val pm = context.packageManager
        val signers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // API 28 collects an archive's certificates only for GET_SIGNATURES,
            // so signingInfo comes back null there.
            pm.getPackageArchiveInfo(path, PackageManager.GET_SIGNING_CERTIFICATES)
                ?.signingInfo?.apkContentsSigners
                ?: legacySigners(pm, path)
        } else {
            legacySigners(pm, path)
        }
        val sha = MessageDigest.getInstance("SHA-256")
        return signers.orEmpty().map { sig ->
            sha.digest(sig.toByteArray()).joinToString("") { "%02x".format(it.toInt() and 0xff) }
        }
    }

    @Suppress("DEPRECATION")
    private fun legacySigners(pm: PackageManager, path: String): Array<Signature>? =
        pm.getPackageArchiveInfo(path, PackageManager.GET_SIGNATURES)?.signatures

    private fun abandon(session: PackageInstaller.Session) {
        try { session.abandon() } catch (_: Exception) {}
    }

    private fun payload(status: String, message: String, savedToDownloads: Boolean = false): Map<String, Any?> =
        mapOf("status" to status, "message" to message, "savedToDownloads" to savedToDownloads)

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

    /** Answers [result] if it is still the install in flight; a superseded one was answered already. */
    private fun finish(result: MethodChannel.Result, payload: Map<String, Any?>) {
        if (pendingResult === result) deliver(payload)
    }

    /** Main thread. */
    private fun deliver(payload: Map<String, Any?>) {
        val r = pendingResult
        pendingResult = null
        pendingApk = null
        pendingName = null
        receiver?.let { try { context.unregisterReceiver(it) } catch (_: Exception) {} }
        receiver = null
        try { r?.success(payload) } catch (_: Exception) {}
    }

    /** A copy in the public Downloads; false when none was written (below Android 10, or no stream). */
    private fun copyToDownloads(src: File, displayName: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
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
        val uri = resolver.insert(collection, values) ?: return false
        try {
            val written = resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(src).use { it.copyTo(out, 64 * 1024) }
                true
            } ?: false
            if (!written) {
                resolver.delete(uri, null, null)
                return false
            }
        } catch (e: Exception) { // no half-written file left in Downloads
            try { resolver.delete(uri, null, null) } catch (_: Exception) {}
            throw e
        }
        val finalValues = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
        resolver.update(uri, finalValues, null, null)
        return true
    }
}
