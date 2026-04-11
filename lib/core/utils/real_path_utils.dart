import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RealPathUtils {
  static const MethodChannel _channel = MethodChannel('com.rfplayer.app/real_path');

  static bool isContentUri(String path) {
    return path.startsWith('content://');
  }

  static Future<String?> getRealPath(String path) async {
    if (!isContentUri(path)) {
      debugPrint('[RealPathUtils] 不是 content URI，直接返回: $path');
      return path;
    }

    if (!Platform.isAndroid) {
      debugPrint('[RealPathUtils] 非 Android 平台，无法处理 content URI: $path');
      return null;
    }

    debugPrint('[RealPathUtils] 尝试将 content URI 转换为真实路径: $path');
    
    try {
      final String? result = await _channel.invokeMethod(
        'getRealPath',
        {'uri': path},
      );
      
      debugPrint('[RealPathUtils] 原生通道返回真实路径: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[RealPathUtils] 原生通道错误: ${e.code}, ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[RealPathUtils] 其他错误: $e');
      return null;
    }
  }

  static Future<String?> getSafePath(String path) async {
    if (!isContentUri(path)) {
      debugPrint('[RealPathUtils] 路径已经是安全路径: $path');
      return path;
    }

    debugPrint('[RealPathUtils] 检测到 content URI，尝试转换: $path');
    final realPath = await getRealPath(path);
    
    if (realPath == null) {
      debugPrint('[RealPathUtils] 无法将 content URI 转换为真实路径');
      return null;
    }

    final file = File(realPath);
    if (await file.exists()) {
      debugPrint('[RealPathUtils] 成功转换为安全路径: $realPath');
      return realPath;
    } else {
      debugPrint('[RealPathUtils] 转换后的路径不存在: $realPath');
      return null;
    }
  }

  static Future<bool> takePersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) {
      debugPrint('[RealPathUtils] 不是 content URI，无需持久化: $uri');
      return true;
    }

    if (!Platform.isAndroid) {
      debugPrint('[RealPathUtils] 非 Android 平台，不支持持久化 content URI');
      return false;
    }

    debugPrint('[RealPathUtils] 尝试持久化 content URI 权限: $uri');

    try {
      final bool? result = await _channel.invokeMethod(
        'takePersistableUriPermission',
        {'uri': uri},
      );
      debugPrint('[RealPathUtils] 持久化结果: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[RealPathUtils] 持久化失败: ${e.code}, ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[RealPathUtils] 持久化异常: $e');
      return false;
    }
  }

  static Future<bool> releasePersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) {
      return true;
    }

    if (!Platform.isAndroid) {
      return false;
    }

    debugPrint('[RealPathUtils] 尝试释放 content URI 持久化权限: $uri');

    try {
      final bool? result = await _channel.invokeMethod(
        'releasePersistableUriPermission',
        {'uri': uri},
      );
      debugPrint('[RealPathUtils] 释放结果: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[RealPathUtils] 释放失败: ${e.code}, ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[RealPathUtils] 释放异常: $e');
      return false;
    }
  }

  static Future<bool> hasPersistableUriPermission(String uri) async {
    if (!isContentUri(uri)) {
      return true;
    }

    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? result = await _channel.invokeMethod(
        'hasPersistableUriPermission',
        {'uri': uri},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[RealPathUtils] 检查权限失败: ${e.code}, ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[RealPathUtils] 检查权限异常: $e');
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
