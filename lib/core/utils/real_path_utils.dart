import 'dart:io';
import 'package:flutter/services.dart';

class RealPathUtils {
  static const MethodChannel _channel = MethodChannel('com.rfplayer.app/real_path');

  static bool isContentUri(String path) {
    return path.startsWith('content://');
  }

  static Future<String?> getRealPath(String path) async {
    if (!isContentUri(path)) return path;
    if (!Platform.isAndroid) return null;

    try {
      return await _channel.invokeMethod('getRealPath', {'uri': path});
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getSafePath(String path) async {
    if (!isContentUri(path)) return path;

    final realPath = await getRealPath(path);
    if (realPath == null) return null;

    final file = File(realPath);
    if (await file.exists()) return realPath;
    return null;
  }

  static Future<bool> takePersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) return true;
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod('takePersistableUriPermission', {'uri': uri}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> releasePersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) return true;
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod('releasePersistableUriPermission', {'uri': uri}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) return true;
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod('hasPersistableUriPermission', {'uri': uri}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static String getFileName(String path) {
    if (isContentUri(path)) {
      final segments = path.split('/');
      return segments.isNotEmpty ? segments.last : path;
    } else {
      return path.split(RegExp(r'[/\\]')).last;
    }
  }
}
