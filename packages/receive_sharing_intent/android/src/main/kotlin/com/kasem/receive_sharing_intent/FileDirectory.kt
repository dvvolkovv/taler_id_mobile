package com.kasem.receive_sharing_intent

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileOutputStream
import java.util.Date

object FileDirectory {

    /**
     * PATCH P1 (Taler ID): a path the app can read for a shared [uri].
     *
     * Content URIs are always copied into the cache through the URI itself:
     * the sender granted read access to exactly that URI. Upstream rewrote
     * media documents into a MediaStore collection query and then opened the
     * whole collection ("Multiple items at content://media/external/images/
     * media" for every photo shared from the system Files app), returned null
     * for the "document" media type (files from its Documents category were
     * lost), and handed out raw storage paths the app can't read under
     * scoped storage.
     *
     * Each copy goes into its own folder under cache/shared/, and over-long
     * names are shortened to fit the file system.
     */
    fun getAbsolutePath(context: Context, uri: Uri): String? {
        if (!"content".equals(uri.scheme, ignoreCase = true)) return uri.path
        val name = fitName(displayName(context, uri) ?: generatedName(context, uri))
        // Each copy in its own folder: two items with the same name in one
        // share (or a new share while the previous file is still uploading)
        // must not overwrite each other.
        val dir = File(context.cacheDir, "shared/${System.nanoTime()}")
        if (!dir.mkdirs() && !dir.isDirectory) return null
        val target = File(dir, name)
        val input = context.contentResolver.openInputStream(uri) ?: return null
        input.use { stream -> FileOutputStream(target).use { stream.copyTo(it) } }
        return target.path
    }

    /**
     * The sender's file name, reduced to its last segment: it ends up in a
     * path under the cache, and "../" from a sender must not leave it.
     */
    private fun displayName(context: Context, uri: Uri): String? =
        try {
            context.contentResolver
                .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
                ?.substringAfterLast('/')
                ?.takeIf { it.isNotBlank() && it != "." && it != ".." }
        } catch (e: Exception) {
            Log.w("FileDirectory", "No display name for $uri: $e")
            null
        }

    /**
     * File names are limited to 255 bytes; a long Cyrillic name (2 bytes a
     * letter) can exceed that and the copy would fail. Keep the extension.
     */
    private fun fitName(name: String): String {
        if (name.toByteArray().size <= MAX_NAME_BYTES) return name
        val dot = name.lastIndexOf('.')
        val ext = if (dot > 0 && name.length - dot <= 10) name.substring(dot) else ""
        var base = name.substring(0, name.length - ext.length)
        while (base.isNotEmpty() && (base + ext).toByteArray().size > MAX_NAME_BYTES) {
            base = base.dropLast(1)
        }
        return base + ext
    }

    private const val MAX_NAME_BYTES = 200

    private fun generatedName(context: Context, uri: Uri): String {
        val mimeType = context.contentResolver.getType(uri)
        val prefix = when {
            mimeType == null -> "FILE"
            mimeType.startsWith("image") -> "IMG"
            mimeType.startsWith("video") -> "VID"
            else -> "FILE"
        }
        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
        return if (ext != null) "${prefix}_${Date().time}.$ext" else "${prefix}_${Date().time}"
    }
}
