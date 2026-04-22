package com.example.rfplayer

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log

object RealPathUtil {
    private const val TAG = "RealPathUtil"

    @SuppressLint("NewApi")
    fun getRealPath(context: Context, uri: Uri): String? {
        Log.d(TAG, "getRealPath: uri=$uri")

        if (DocumentsContract.isDocumentUri(context, uri)) {
            Log.d(TAG, "It's a DocumentProvider URI")

            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                if ("primary".equals(type, ignoreCase = true)) {
                    val path = Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                    Log.d(TAG, "ExternalStorage primary path: $path")
                    return path
                }
            } else if (isDownloadsDocument(uri)) {
                Log.d(TAG, "It's a DownloadsDocument URI")
                val docId = DocumentsContract.getDocumentId(uri)
                Log.d(TAG, "Downloads docId: $docId")

                if (docId.startsWith("raw:")) {
                    val path = docId.substringAfter("raw:")
                    Log.d(TAG, "Raw path: $path")
                    return path
                }

                if (docId.startsWith("msf:")) {
                    val id = docId.substringAfter("msf:")
                    Log.d(TAG, "Extracted msf id: $id")

                    val path = queryMediaStoreById(context, id)
                    if (path != null) {
                        Log.d(TAG, "Found via msf id in MediaStore: $path")
                        return path
                    }

                    Log.d(TAG, "msf id not found in MediaStore")
                    return null
                }

                try {
                    val id = docId.toLong()
                    val contentUri = ContentUris.withAppendedId(
                        Uri.parse("content://downloads/public_downloads"),
                        id
                    )
                    Log.d(TAG, "Downloads contentUri: $contentUri")
                    val path = getDataColumn(context, contentUri, null, null)
                    if (path != null) {
                        return path
                    }
                } catch (e: NumberFormatException) {
                    Log.e(TAG, "Failed to parse docId as number: $docId", e)
                }
            } else if (isMediaDocument(uri)) {
                Log.d(TAG, "It's a MediaDocument URI")
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                var contentUri: Uri? = null
                when (type) {
                    "image" -> contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])

                Log.d(TAG, "Media contentUri: $contentUri, id: ${split[1]}")
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            Log.d(TAG, "It's a content URI")
            return if (isGooglePhotosUri(uri)) uri.lastPathSegment else getDataColumn(context, uri, null, null)
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            Log.d(TAG, "It's a file URI")
            return uri.path
        }

        Log.d(TAG, "Could not resolve real path")
        return null
    }

    fun getDisplayName(context: Context, uri: Uri): String? {
        if (uri.scheme != "content") return null
        try {
            val cursor = context.contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        return it.getString(nameIndex)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "getDisplayName error", e)
        }
        return null
    }

    private fun queryMediaStoreById(context: Context, id: String): String? {
        val uris = listOf(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        )
        for (uri in uris) {
            val path = getDataColumn(context, uri, "_id=?", arrayOf(id))
            if (path != null) return path
        }
        return null
    }

    private fun getDataColumn(
        context: Context,
        uri: Uri?,
        selection: String?,
        selectionArgs: Array<String>?
    ): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)

        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndexOrThrow(column)
                val path = cursor.getString(index)
                Log.d(TAG, "getDataColumn found path: $path")
                return path
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in getDataColumn", e)
        } finally {
            cursor?.close()
        }
        return null
    }

    private fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    private fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    private fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }

    private fun isGooglePhotosUri(uri: Uri): Boolean {
        return "com.google.android.apps.photos.content" == uri.authority
    }
}
