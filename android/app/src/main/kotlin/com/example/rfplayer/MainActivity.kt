package com.example.rfplayer

import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rfplayer.app/real_path"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
                "takePersistableUriPermission" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val contentResolver = contentResolver
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
                            val contentResolver = contentResolver
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
                            val contentResolver = contentResolver
                            val persistedPermissions = contentResolver.persistedUriPermissions
                            val hasPermission = persistedPermissions.any {
                                it.uri == uri && it.isReadPermission
                            }
                            Log.d("MainActivity", "hasPersistableUriPermission: $uriString -> $hasPermission")
                            result.success(hasPermission)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "hasPersistableUriPermission failed: $uriString", e)
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Uri is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
