package com.example.rfplayer

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.system.Os
import android.system.OsConstants
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.charset.Charset

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rfplayer.app/real_path"
    private val SUBTITLE_CHANNEL = "com.rfplayer.app/subtitle"
    private val INTENT_CHANNEL = "com.rfplayer.app/intent"
    private var initialIntentUri: String? = null
    private var pendingIntentUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntentUri" -> {
                    result.success(initialIntentUri)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRealPath" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val realPath = RealPathUtil.getRealPath(this, uri)
                            if (realPath != null) {
                                result.success(realPath)
                            } else {
                                result.error("PATH_NOT_FOUND", "Could not find real path", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                "getDisplayName" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val name = RealPathUtil.getDisplayName(this, uri)
                            result.success(name)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "takePersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            contentResolver.takePersistableUriPermission(
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                            Log.d("MainActivity", "takePersistableUriPermission success: $uriString")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "takePersistableUriPermission failed: $uriString", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                "releasePersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            contentResolver.releasePersistableUriPermission(
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                            Log.d("MainActivity", "releasePersistableUriPermission success: $uriString")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "releasePersistableUriPermission failed: $uriString", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                "hasPersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val persistedPermissions = contentResolver.persistedUriPermissions
                            val hasPermission = persistedPermissions.any {
                                it.uri.toString() == uri.toString() && it.isReadPermission
                            }
                            result.success(hasPermission)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "hasPersistableUriPermission failed: $uriString", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                "cacheContentUri" -> {
                    val uriString = call.argument<String>("uri")
                    val ext = call.argument<String>("ext") ?: ""
                    val cacheDir = call.argument<String>("cacheDir") ?: "subtitle_cache"
                    if (uriString != null) {
                        Thread {
                            try {
                                val uri = Uri.parse(uriString)
                                val cachedPath = cacheContentUri(uri, ext, cacheDir)
                                if (cachedPath != null) {
                                    runOnUiThread { result.success(cachedPath) }
                                } else {
                                    runOnUiThread { result.success(null) }
                                }
                            } catch (e: Exception) {
                                Log.e("MainActivity", "cacheContentUri failed", e)
                                runOnUiThread { result.success(null) }
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                "showToast" -> {
                    val message = call.argument<String>("message")
                    if (message != null) {
                        android.widget.Toast.makeText(this, message, android.widget.Toast.LENGTH_SHORT).show()
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Message is null", null)
                    }
                }
                "getSdkVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "canOpenFileNative" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val fd = Os.open(path, OsConstants.O_RDONLY, 0)
                            Os.close(fd)
                            Log.d("MainActivity", "canOpenFileNative: $path -> true")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.d("MainActivity", "canOpenFileNative: $path -> false (${e.message})")
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "hasMediaPermission" -> {
                    val mediaType = call.argument<String>("mediaType") ?: "unknown"
                    val granted = when {
                        Build.VERSION.SDK_INT >= 33 -> {
                            when (mediaType) {
                                "video" -> ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
                                "audio" -> ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED
                                "image" -> ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
                                else -> {
                                    val v = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
                                    val a = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED
                                    val i = ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
                                    v || a || i
                                }
                            }
                        }
                        else -> ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
                    }
                    Log.d("MainActivity", "hasMediaPermission: mediaType=$mediaType, sdk=${Build.VERSION.SDK_INT}, granted=$granted")
                    result.success(granted)
                }
                "readContentUriBytes" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        Thread {
                            try {
                                val uri = Uri.parse(uriString)
                                val inputStream = contentResolver.openInputStream(uri)
                                if (inputStream != null) {
                                    val bytes = inputStream.use { it.readBytes() }
                                    Log.d("MainActivity", "readContentUriBytes: read ${bytes.size} bytes from $uriString")
                                    runOnUiThread { result.success(bytes) }
                                } else {
                                    Log.e("MainActivity", "readContentUriBytes: openInputStream returned null for $uriString")
                                    runOnUiThread { result.success(null) }
                                }
                            } catch (e: Exception) {
                                Log.e("MainActivity", "readContentUriBytes failed: $uriString", e)
                                runOnUiThread { result.success(null) }
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SUBTITLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractEmbeddedSubtitles" -> {
                    val path = call.argument<String>("path")
                    val streamIndex = call.argument<Int>("streamIndex") ?: -1
                    if (path != null) {
                        Thread {
                            try {
                                val subtitleData = extractEmbeddedSubtitles(path, streamIndex)
                                if (subtitleData != null) {
                                    runOnUiThread { result.success(subtitleData) }
                                } else {
                                    runOnUiThread { result.success(null) }
                                }
                            } catch (e: Exception) {
                                Log.e("MainActivity", "Error extracting subtitles", e)
                                runOnUiThread { result.error("EXTRACT_ERROR", e.message, null) }
                            }
                        }.start()
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action != Intent.ACTION_VIEW) return

        val uri = intent.data
        if (uri != null) {
            val uriString = uri.toString()
            Log.d("MainActivity", "Received intent with URI: $uriString")
            if (initialIntentUri == null) {
                initialIntentUri = uriString
            } else {
                notifyFlutterOfNewIntent(uriString)
            }
        }
    }

    private fun notifyFlutterOfNewIntent(uriString: String) {
        try {
            val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, INTENT_CHANNEL)
            channel.invokeMethod("onNewIntent", uriString)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to notify Flutter of new intent", e)
        }
    }

    private fun cacheContentUri(uri: Uri, ext: String, cacheSubDir: String = "subtitle_cache"): String? {
        try {
            val fileName = getFileNameFromUri(uri)
            val cacheDir = File(cacheDir, cacheSubDir)
            if (!cacheDir.exists()) cacheDir.mkdirs()

            val safeExt = if (ext.isNotEmpty()) ext else {
                val dotIndex = fileName.lastIndexOf('.')
                if (dotIndex >= 0) fileName.substring(dotIndex + 1).lowercase() else "txt"
            }

            val baseName = if (fileName.contains('.')) {
                fileName.substring(0, fileName.lastIndexOf('.'))
            } else {
                fileName
            }

            val cacheFile = File(cacheDir, "$baseName.$safeExt")
            val input = contentResolver.openInputStream(uri)
            if (input != null) {
                input.use { inputStream ->
                    FileOutputStream(cacheFile).use { outputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
            } else {
                return null
            }

            Log.d("MainActivity", "Cached content URI to: ${cacheFile.absolutePath}")
            return cacheFile.absolutePath
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to cache content URI", e)
            return null
        }
    }

    private fun getFileNameFromUri(uri: Uri): String {
        var fileName = "subtitle"
        if (uri.scheme == "content") {
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        fileName = it.getString(nameIndex)
                    }
                }
            }
        }
        return fileName
    }

    private fun extractEmbeddedSubtitles(path: String, streamIndex: Int): Map<String, String>? {
        val file = File(path)
        if (!file.exists()) {
            Log.e("MainActivity", "File does not exist: $path")
            return null
        }

        val ext = path.substringAfterLast('.', "").lowercase()
        if (ext == "mkv" || ext == "webm" || ext == "mka") {
            return extractMkvSubtitles(path, streamIndex)
        }

        return extractMediaExtractorSubtitles(path, streamIndex)
    }

    private fun extractMediaExtractorSubtitles(path: String, targetSubtitleIndex: Int): Map<String, String>? {
        val extractor = android.media.MediaExtractor()
        try {
            extractor.setDataSource(path)

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(android.media.MediaFormat.KEY_MIME) ?: continue
                Log.d("MainActivity", "MediaExtractor track[$i]: mime=$mime")
            }

            var subtitleTrackIndex = -1
            var subtitleCount = 0

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(android.media.MediaFormat.KEY_MIME) ?: continue

                if (isSubtitleMime(mime)) {
                    if (subtitleCount == targetSubtitleIndex) {
                        subtitleTrackIndex = i
                        break
                    }
                    subtitleCount++
                }
            }

            if (subtitleTrackIndex == -1) {
                Log.d("MainActivity", "MediaExtractor: no subtitle track found at index $targetSubtitleIndex")
                return null
            }

            extractor.selectTrack(subtitleTrackIndex)

            val entries = mutableListOf<Pair<Long, String>>()

            while (true) {
                val si = extractor.sampleTrackIndex
                if (si < 0 || si != subtitleTrackIndex) break

                val timeUs = extractor.sampleTime
                val size = extractor.sampleSize

                if (size > 0 && size < 1024 * 1024) {
                    val buf = java.nio.ByteBuffer.allocate(size.toInt())
                    extractor.readSampleData(buf, 0)
                    buf.flip()
                    val bytes = ByteArray(buf.remaining())
                    buf.get(bytes)
                    val text = bytes.toString(Charset.forName("UTF-8")).trim()
                    if (text.isNotEmpty() && !text.startsWith("\u0000")) {
                        val clean = text.replace(Regex("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]"), "").trim()
                        if (clean.isNotEmpty()) {
                            entries.add(Pair(timeUs, clean))
                        }
                    }
                }
                if (!extractor.advance()) break
            }

            if (entries.isEmpty()) return null
            return mapOf("content" to buildSrt(entries), "format" to "srt")
        } catch (e: Exception) {
            Log.e("MainActivity", "MediaExtractor error", e)
            return null
        } finally {
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    private fun isSubtitleMime(mime: String): Boolean {
        return mime.startsWith("text/") ||
            mime == "application/x-subrip" ||
            mime == "application/x-ssa" ||
            mime == "application/ttml+xml" ||
            mime == "application/x-quicktime-tx3g"
    }

    private fun extractMkvSubtitles(path: String, targetStreamIndex: Int): Map<String, String>? {
        try {
            val raf = RandomAccessFile(path, "r")
            try {
                val parser = MkvParser(raf)
                val result = parser.extractSubtitleTrack(targetStreamIndex)
                return result
            } finally {
                try { raf.close() } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "MKV extraction error", e)
            return null
        }
    }

    private fun buildSrt(entries: List<Pair<Long, String>>): String {
        val sb = StringBuilder()
        for (i in entries.indices) {
            val (timeUs, text) = entries[i]
            val startMs = timeUs / 1000
            val endMs = if (i + 1 < entries.size) entries[i + 1].first / 1000 else startMs + 3000
            sb.appendLine(i + 1)
            sb.appendLine("${formatSrtTime(startMs)} --> ${formatSrtTime(endMs)}")
            sb.appendLine(text)
            sb.appendLine()
        }
        return sb.toString().trim()
    }

    private fun formatSrtTime(timeMs: Long): String {
        val h = timeMs / 3600000
        val m = (timeMs % 3600000) / 60000
        val s = (timeMs % 60000) / 1000
        val ms = timeMs % 1000
        return String.format("%02d:%02d:%02d,%03d", h, m, s, ms)
    }
}

internal class MkvParser(private val raf: RandomAccessFile) {

    companion object {
        private const val TAG = "MkvParser"
        private const val EBML_HEADER = 0x1A45DFA3L
        private const val SEGMENT = 0x18538067L
        private const val SEEK_HEAD = 0x114D9B74L
        private const val INFO = 0x1549A966L
        private const val TIMECODE_SCALE = 0x2AD7B1L
        private const val TRACKS = 0x1654AE6BL
        private const val TRACK_ENTRY = 0xAEL
        private const val TRACK_NUMBER = 0xD7L
        private const val TRACK_TYPE = 0x83L
        private const val CODEC_ID = 0x86L
        private const val CODEC_PRIVATE = 0x63A2L
        private const val CLUSTER = 0x1F43B675L
        private const val CLUSTER_TIMECODE = 0xE7L
        private const val SIMPLE_BLOCK = 0xA3L
        private const val BLOCK_GROUP = 0xA0L
        private const val BLOCK = 0xA1L
        private const val BLOCK_DURATION = 0x9BL
        private const val TRACK_TYPE_SUBTITLE = 0x11L
    }

    private var timecodeScale = 1000000L

    fun extractSubtitleTrack(targetStreamIndex: Int): Map<String, String>? {
        val fileLength = raf.length()
        var pos = 0L

        val ebmlId = readElementId(pos)
        if (ebmlId != EBML_HEADER) {
            Log.e(TAG, "Not a valid MKV/WebM file")
            return null
        }
        val ebmlSize = readElementSize(pos + elementIdLength(pos))
        pos += elementIdLength(pos) + sizeFieldLength(pos + elementIdLength(pos)) + ebmlSize

        if (pos >= fileLength) return null

        val segId = readElementId(pos)
        if (segId != SEGMENT) {
            Log.e(TAG, "No Segment element found")
            return null
        }
        val segSizeOffset = pos + elementIdLength(pos)
        val segSizeFieldLen = sizeFieldLength(segSizeOffset)
        val segContentSize = readElementSize(segSizeOffset)
        val segDataStart = segSizeOffset + segSizeFieldLen
        val segEnd = if (segContentSize == UNKNOWN_SIZE) fileLength else segDataStart + segContentSize

        var tracksOffset = -1L
        var tracksSize = 0L
        var clusterOffset = -1L

        var scanPos = segDataStart
        while (scanPos < segEnd - 4) {
            val id = readElementId(scanPos)
            if (id == 0L) { scanPos++; continue }
            val idLen = elementIdLength(scanPos)
            val sizeOffset = scanPos + idLen
            if (sizeOffset >= segEnd) break
            val sizeLen = sizeFieldLength(sizeOffset)
            val contentSize = readElementSize(sizeOffset)
            val dataStart = sizeOffset + sizeLen

            if (contentSize != UNKNOWN_SIZE && dataStart + contentSize > segEnd + 1024) {
                scanPos++
                continue
            }

            when (id) {
                TRACKS -> {
                    tracksOffset = dataStart
                    tracksSize = contentSize
                }
                CLUSTER -> {
                    if (clusterOffset < 0) clusterOffset = dataStart
                }
                SEEK_HEAD, INFO -> { }
            }

            if (tracksOffset >= 0 && clusterOffset >= 0) break

            if (contentSize == UNKNOWN_SIZE) {
                scanPos++
                continue
            }
            scanPos = dataStart + contentSize
        }

        if (tracksOffset < 0) {
            Log.e(TAG, "No Tracks element found")
            return null
        }

        val trackInfo = parseTracks(tracksOffset, tracksSize, targetStreamIndex)
        if (trackInfo == null) {
            Log.d(TAG, "Subtitle track $targetStreamIndex not found in Tracks")
            return null
        }

        Log.d(TAG, "Found subtitle track: trackNum=${trackInfo.trackNumber}, codecId=${trackInfo.codecId}")

        val codecPrivate = trackInfo.codecPrivate
        val isAss = trackInfo.codecId.contains("ASS", ignoreCase = true) ||
                    trackInfo.codecId.contains("SSA", ignoreCase = true)

        val entries = mutableListOf<Pair<Long, String>>()

        if (clusterOffset < 0) {
            Log.d(TAG, "No Cluster found")
            return null
        }

        scanClustersForTrack(segDataStart, segEnd, trackInfo.trackNumber, entries)

        if (entries.isEmpty()) {
            Log.d(TAG, "No subtitle entries extracted")
            return null
        }

        Log.d(TAG, "Extracted ${entries.size} subtitle entries")

        if (isAss && codecPrivate != null) {
            val assHeader = codecPrivate.toString(Charset.forName("UTF-8"))
            val content = buildAssFile(assHeader, entries)
            return mapOf("content" to content, "format" to "ass")
        } else {
            val content = buildSrtFromEntries(entries)
            return mapOf("content" to content, "format" to "srt")
        }
    }

    private data class TrackInfo(
        val trackNumber: Long,
        val codecId: String,
        val codecPrivate: ByteArray?
    )

    private fun parseTracks(offset: Long, size: Long, targetStreamIndex: Int): TrackInfo? {
        val end = offset + size
        var pos = offset
        var currentSubtitleIndex = 0

        while (pos < end - 2) {
            val id = readElementId(pos)
            if (id == 0L) { pos++; continue }
            val idLen = elementIdLength(pos)
            val sizeOffset = pos + idLen
            if (sizeOffset >= end) break
            val sizeLen = sizeFieldLength(sizeOffset)
            val contentSize = readElementSize(sizeOffset)
            val dataStart = sizeOffset + sizeLen

            if (id == TRACK_ENTRY) {
                val trackEnd = dataStart + contentSize
                var trackNum = 0L
                var trackType = 0
                var codecId = ""
                var codecPrivate: ByteArray? = null

                var tp = dataStart
                while (tp < trackEnd - 1) {
                    val tid = readElementId(tp)
                    if (tid == 0L) { tp++; continue }
                    val tidLen = elementIdLength(tp)
                    val tSizeOffset = tp + tidLen
                    if (tSizeOffset >= trackEnd) break
                    val tSizeLen = sizeFieldLength(tSizeOffset)
                    val tContentSize = readElementSize(tSizeOffset)
                    val tDataStart = tSizeOffset + tSizeLen

                    when (tid) {
                        TRACK_NUMBER -> {
                            trackNum = readUnsignedInt(tDataStart, tContentSize.toInt())
                        }
                        TRACK_TYPE -> {
                            trackType = readUnsignedInt(tDataStart, tContentSize.toInt()).toInt()
                        }
                        CODEC_ID -> {
                            codecId = readString(tDataStart, tContentSize.toInt())
                        }
                        CODEC_PRIVATE -> {
                            if (tContentSize > 0 && tContentSize < 10 * 1024 * 1024) {
                                codecPrivate = readBytes(tDataStart, tContentSize.toInt())
                            }
                        }
                    }

                    if (tContentSize == UNKNOWN_SIZE) break
                    tp = tDataStart + tContentSize
                }

                if (trackType.toLong() == TRACK_TYPE_SUBTITLE) {
                    Log.d(TAG, "Found subtitle track: trackNum=$trackNum, codecId=$codecId, index=$currentSubtitleIndex, targetStreamIndex=$targetStreamIndex")
                    if (currentSubtitleIndex == targetStreamIndex || trackNum - 1 == targetStreamIndex.toLong()) {
                        return TrackInfo(trackNum, codecId, codecPrivate)
                    }
                    currentSubtitleIndex++
                }
            }

            if (contentSize == UNKNOWN_SIZE) break
            pos = dataStart + contentSize
        }
        return null
    }

    private fun scanClustersForTrack(
        segDataStart: Long,
        segEnd: Long,
        trackNumber: Long,
        entries: MutableList<Pair<Long, String>>
    ) {
        var pos = segDataStart
        val trackNumBytes = encodeVint(trackNumber)
        val trackNumPrefix = trackNumBytes[0].toInt() and 0xFF

        while (pos < segEnd - 4) {
            val id = readElementId(pos)
            if (id == 0L) { pos++; continue }
            val idLen = elementIdLength(pos)
            val sizeOffset = pos + idLen
            if (sizeOffset >= segEnd) break
            val sizeLen = sizeFieldLength(sizeOffset)
            val contentSize = readElementSize(sizeOffset)
            val dataStart = sizeOffset + sizeLen

            if (id == CLUSTER) {
                var clusterTimecode = 0L
                var cp = dataStart
                val clusterEnd = if (contentSize == UNKNOWN_SIZE) segEnd else dataStart + contentSize

                while (cp < clusterEnd - 3) {
                    val cid = readElementId(cp)
                    if (cid == 0L) { cp++; continue }
                    val cidLen = elementIdLength(cp)
                    val cSizeOffset = cp + cidLen
                    if (cSizeOffset >= clusterEnd) break
                    val cSizeLen = sizeFieldLength(cSizeOffset)
                    val cContentSize = readElementSize(cSizeOffset)
                    val cDataStart = cSizeOffset + cSizeLen

                    if (cContentSize > 100 * 1024 * 1024) {
                        cp++
                        continue
                    }

                    when (cid) {
                        CLUSTER_TIMECODE -> {
                            clusterTimecode = readUnsignedInt(cDataStart, cContentSize.toInt())
                        }
                        SIMPLE_BLOCK -> {
                            parseSimpleBlock(cDataStart, cContentSize.toInt(), clusterTimecode, trackNumber, entries)
                        }
                        BLOCK_GROUP -> {
                            parseBlockGroup(cDataStart, cContentSize.toInt(), clusterTimecode, trackNumber, entries)
                        }
                    }

                    if (cContentSize == UNKNOWN_SIZE) break
                    cp = cDataStart + cContentSize
                }

                if (contentSize == UNKNOWN_SIZE) {
                    pos = clusterEnd
                } else {
                    pos = dataStart + contentSize
                }
            } else if (id == TRACKS || id == SEEK_HEAD || id == INFO) {
                if (contentSize == UNKNOWN_SIZE) { pos++; continue }
                pos = dataStart + contentSize
            } else {
                if (contentSize == UNKNOWN_SIZE) { pos++; continue }
                pos = dataStart + contentSize
            }
        }
    }

    private fun parseSimpleBlock(
        dataStart: Long, dataSize: Int,
        clusterTimecode: Long, trackNumber: Long,
        entries: MutableList<Pair<Long, String>>
    ) {
        if (dataSize < 4) return

        val firstByte = readByte(dataStart)
        val trackNum = decodeVintTrackNum(firstByte, dataStart)
        if (trackNum != trackNumber) return

        val trackNumLen = vintLength(firstByte)
        if (dataStart + trackNumLen + 3 > dataStart + dataSize) return

        val timecodeOffset = dataStart + trackNumLen
        val relativeTimecode = readSignedInt16(timecodeOffset)
        val flags = readByte(timecodeOffset + 2)

        val headerSize = trackNumLen + 3
        val payloadSize = dataSize - headerSize
        if (payloadSize <= 0 || payloadSize > 1024 * 1024) return

        val payloadStart = dataStart + headerSize
        val payload = readBytes(payloadStart, payloadSize)
        val text = payload.toString(Charset.forName("UTF-8")).trim()

        if (text.isNotEmpty() && !text.all { it.code < 0x20 }) {
            val cleanText = text.replace(Regex("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]"), "").trim()
            if (cleanText.isNotEmpty()) {
                val timecodeNs = (clusterTimecode + relativeTimecode) * timecodeScale
                val timeMs = timecodeNs / 1_000_000
                entries.add(Pair(timeMs, cleanText))
            }
        }
    }

    private fun parseBlockGroup(
        dataStart: Long, dataSize: Int,
        clusterTimecode: Long, trackNumber: Long,
        entries: MutableList<Pair<Long, String>>
    ) {
        var pos = dataStart
        val end = dataStart + dataSize
        var blockData: ByteArray? = null
        var blockDuration: Long? = null

        while (pos < end - 1) {
            val id = readElementId(pos)
            if (id == 0L) { pos++; continue }
            val idLen = elementIdLength(pos)
            val sizeOffset = pos + idLen
            if (sizeOffset >= end) break
            val sizeLen = sizeFieldLength(sizeOffset)
            val contentSize = readElementSize(sizeOffset)
            val cDataStart = sizeOffset + sizeLen

            when (id) {
                BLOCK -> {
                    if (contentSize in 1..(10 * 1024 * 1024)) {
                        blockData = readBytes(cDataStart, contentSize.toInt())
                    }
                }
                BLOCK_DURATION -> {
                    blockDuration = readUnsignedInt(cDataStart, contentSize.toInt())
                }
            }

            if (contentSize == UNKNOWN_SIZE) break
            pos = cDataStart + contentSize
        }

        if (blockData == null || blockData!!.size < 4) return

        val firstByte = blockData!![0].toInt() and 0xFF
        val trackNum = decodeVintTrackNumFromBuffer(firstByte, blockData!!)
        if (trackNum != trackNumber) return

        val trackNumLen = vintLength(firstByte)
        if (trackNumLen + 3 > blockData!!.size) return

        val relativeTimecode = ((blockData!![trackNumLen].toInt() and 0xFF) shl 8) or
                               (blockData!![trackNumLen + 1].toInt() and 0xFF)
        val relTimecodeSigned = if (relativeTimecode > 32767) relativeTimecode - 65536 else relativeTimecode

        val headerSize = trackNumLen + 3
        val payloadSize = blockData!!.size - headerSize
        if (payloadSize <= 0 || payloadSize > 1024 * 1024) return

        val payload = blockData!!.copyOfRange(headerSize, blockData!!.size)
        val text = payload.toString(Charset.forName("UTF-8")).trim()

        if (text.isNotEmpty() && !text.all { it.code < 0x20 }) {
            val cleanText = text.replace(Regex("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]"), "").trim()
            if (cleanText.isNotEmpty()) {
                val timecodeNs = (clusterTimecode + relTimecodeSigned) * timecodeScale
                val timeMs = timecodeNs / 1_000_000
                entries.add(Pair(timeMs, cleanText))
            }
        }
    }

    private fun buildAssFile(assHeader: String, entries: List<Pair<Long, String>>): String {
        val sb = StringBuilder()
        val headerTrimmed = assHeader.trimEnd()
        sb.append(headerTrimmed)
        if (!headerTrimmed.endsWith("\n")) sb.appendLine()
        sb.appendLine()

        if (!assHeader.contains("[Events]", ignoreCase = true)) {
            sb.appendLine("[Events]")
            sb.appendLine("Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text")
        }

        for ((timeMs, text) in entries) {
            val startTime = formatAssTime(timeMs)
            val endTime = formatAssTime(timeMs + 3000)
            val dialogueText = if (text.startsWith("Dialogue:", ignoreCase = true)) {
                text.substringAfter("Dialogue:").trimStart()
            } else {
                "0,$startTime,$endTime,Default,,0,0,0,,$text"
            }
            sb.appendLine("Dialogue: $dialogueText")
        }

        return sb.toString()
    }

    private fun formatAssTime(timeMs: Long): String {
        val h = timeMs / 3600000
        val m = (timeMs % 3600000) / 60000
        val s = (timeMs % 60000) / 1000
        val cs = (timeMs % 1000) / 10
        return String.format("%d:%02d:%02d.%02d", h, m, s, cs)
    }

    private fun buildSrtFromEntries(entries: List<Pair<Long, String>>): String {
        val sb = StringBuilder()
        for (i in entries.indices) {
            val (timeMs, text) = entries[i]
            val startMs = timeMs
            val endMs = if (i + 1 < entries.size) entries[i + 1].first else startMs + 3000
            val displayText = if (text.startsWith("Dialogue:", ignoreCase = true)) {
                extractAssText(text)
            } else {
                text
            }
            if (displayText.isNotEmpty()) {
                sb.appendLine(i + 1)
                sb.appendLine("${formatSrtTime(startMs)} --> ${formatSrtTime(endMs)}")
                sb.appendLine(displayText)
                sb.appendLine()
            }
        }
        return sb.toString().trim()
    }

    private fun extractAssText(dialogueLine: String): String {
        val afterDialogue = dialogueLine.substringAfter("Dialogue:").trimStart()
        val parts = afterDialogue.split(",", limit = 10)
        if (parts.size >= 10) {
            return parts[9].replace("\\N", "\n").replace("\\n", "\n").replace("\\h", " ")
        }
        return afterDialogue
    }

    private fun formatSrtTime(timeMs: Long): String {
        val h = timeMs / 3600000
        val m = (timeMs % 3600000) / 60000
        val s = (timeMs % 60000) / 1000
        val ms = timeMs % 1000
        return String.format("%02d:%02d:%02d,%03d", h, m, s, ms)
    }

    private val UNKNOWN_SIZE = -1L

    private fun readElementId(pos: Long): Long {
        if (pos >= raf.length() - 1) return 0
        val firstByte = raf.seek(pos); val b = raf.readByte().toInt() and 0xFF
        val len = vintLength(b)
        if (pos + len > raf.length()) return 0
        var id = 0L
        raf.seek(pos)
        for (i in 0 until len) {
            id = (id shl 8) or (raf.readByte().toInt() and 0xFF).toLong()
        }
        return id
    }

    private fun elementIdLength(pos: Long): Int {
        if (pos >= raf.length()) return 1
        raf.seek(pos)
        val b = raf.readByte().toInt() and 0xFF
        return vintLength(b)
    }

    private fun readElementSize(pos: Long): Long {
        if (pos >= raf.length()) return 0
        raf.seek(pos)
        val firstByte = raf.readByte().toInt() and 0xFF
        val len = vintLength(firstByte)
        if (pos + len > raf.length()) return 0
        var size = firstByte and vintMask(len).toInt()
        for (i in 1 until len) {
            size = (size shl 8) or (raf.readByte().toInt() and 0xFF)
        }
        if (size.toLong() == vintMask(len)) return UNKNOWN_SIZE
        return size.toLong()
    }

    private fun sizeFieldLength(pos: Long): Int {
        if (pos >= raf.length()) return 1
        raf.seek(pos)
        val b = raf.readByte().toInt() and 0xFF
        return vintLength(b)
    }

    private fun vintLength(firstByte: Int): Int {
        if (firstByte and 0x80 != 0) return 1
        if (firstByte and 0x40 != 0) return 2
        if (firstByte and 0x20 != 0) return 3
        if (firstByte and 0x10 != 0) return 4
        if (firstByte and 0x08 != 0) return 5
        if (firstByte and 0x04 != 0) return 6
        if (firstByte and 0x02 != 0) return 7
        return 8
    }

    private fun vintMask(len: Int): Long {
        return when (len) {
            1 -> 0x7FL
            2 -> 0x3FFFL
            3 -> 0x1FFFFFL
            4 -> 0x0FFFFFFFL
            5 -> 0x07FFFFFFFL
            6 -> 0x03FFFFFFFFL
            7 -> 0x01FFFFFFFFFFL
            8 -> 0x00FFFFFFFFFFFFL
            else -> 0x7FL
        }
    }

    private fun readUnsignedInt(pos: Long, size: Int): Long {
        if (size <= 0 || size > 8) return 0
        raf.seek(pos)
        var value = 0L
        for (i in 0 until size) {
            value = (value shl 8) or (raf.readByte().toInt() and 0xFF).toLong()
        }
        return value
    }

    private fun readSignedInt16(pos: Long): Int {
        raf.seek(pos)
        val hi = raf.readByte().toInt() and 0xFF
        val lo = raf.readByte().toInt() and 0xFF
        val value = (hi shl 8) or lo
        return if (value > 32767) value - 65536 else value
    }

    private fun readByte(pos: Long): Int {
        raf.seek(pos)
        return raf.readByte().toInt() and 0xFF
    }

    private fun readString(pos: Long, size: Int): String {
        val bytes = readBytes(pos, size)
        return bytes.toString(Charset.forName("UTF-8")).trimEnd('\u0000')
    }

    private fun readBytes(pos: Long, size: Int): ByteArray {
        raf.seek(pos)
        val bytes = ByteArray(size)
        raf.readFully(bytes)
        return bytes
    }

    private fun decodeVintTrackNum(firstByte: Int, dataStart: Long): Long {
        val len = vintLength(firstByte)
        var value = (firstByte and vintMask(len).toInt()).toLong()
        raf.seek(dataStart + 1)
        for (i in 1 until len) {
            value = (value shl 8) or (raf.readByte().toInt() and 0xFF).toLong()
        }
        return value
    }

    private fun decodeVintTrackNumFromBuffer(firstByte: Int, buf: ByteArray): Long {
        val len = vintLength(firstByte)
        var value = (firstByte and vintMask(len).toInt()).toLong()
        for (i in 1 until len) {
            value = (value shl 8) or (buf[i].toInt() and 0xFF).toLong()
        }
        return value
    }

    private fun encodeVint(value: Long): ByteArray {
        if (value < 0x7F) return byteArrayOf((0x80 or value.toInt()).toByte())
        if (value < 0x3FFF) return byteArrayOf(
            (0x40 or (value shr 8).toInt()).toByte(),
            (value and 0xFF).toByte()
        )
        return byteArrayOf(
            (0x20 or (value shr 16).toInt()).toByte(),
            ((value shr 8) and 0xFF).toByte(),
            (value and 0xFF).toByte()
        )
    }
}
