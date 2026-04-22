import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../constants/supported_formats.dart';
import 'real_path_utils.dart';

class IntentUtils {
  static const MethodChannel _intentChannel =
      MethodChannel('com.rfplayer.app/intent');
  static const MethodChannel _argsChannel =
      MethodChannel('com.rfplayer.app/args');

  static Future<String?> getInitialFileUri() async {
    if (Platform.isAndroid) {
      return _getAndroidInitialUri();
    } else if (Platform.isWindows) {
      return _getWindowsCommandLineFile();
    }
    return null;
  }

  static Future<String?> _getAndroidInitialUri() async {
    try {
      final uri = await _intentChannel.invokeMethod<String>('getInitialIntentUri');
      if (uri == null) return null;
      return uri;
    } on PlatformException {
      return null;
    }
  }

  static Future<String?> _getWindowsCommandLineFile() async {
    try {
      final result = await _argsChannel.invokeMethod<List<Object?>>('getCommandLineArgs');
      if (result != null && result.isNotEmpty) {
        for (final arg in result) {
          final filePath = arg as String;
          if (FileSystemEntity.isFileSync(filePath)) {
            return filePath;
          }
        }
      }
    } on PlatformException {
      return null;
    }

    try {
      final args = Platform.executableArguments;
      if (args.isNotEmpty) {
        for (final filePath in args) {
          if (FileSystemEntity.isFileSync(filePath)) {
            return filePath;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static void setupIntentListener(Function(String uri) onFileReceived) {
    if (!Platform.isAndroid) return;

    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntent') {
        final uri = call.arguments as String?;
        if (uri != null) {
          onFileReceived(uri);
        }
      }
    });
  }

  static Future<ResolvedMediaPath> resolveToFilePath(String uri) async {
    if (Platform.isWindows) {
      if (FileSystemEntity.isFileSync(uri)) {
        return ResolvedMediaPath(
          path: uri,
          source: PathSource.realPath,
          canStoreInHistory: true,
        );
      }
      return ResolvedMediaPath(path: uri, source: PathSource.failed);
    }

    if (Platform.isAndroid) {
      if (RealPathUtils.isContentUri(uri)) {
        return RealPathUtils.resolveContentUri(uri);
      } else if (uri.startsWith('file://')) {
        final filePath = Uri.parse(uri).toFilePath();
        if (FileSystemEntity.isFileSync(filePath)) {
          return ResolvedMediaPath(
            path: filePath,
            source: PathSource.realPath,
            canStoreInHistory: true,
          );
        }
      } else if (FileSystemEntity.isFileSync(uri)) {
        return ResolvedMediaPath(
          path: uri,
          source: PathSource.realPath,
          canStoreInHistory: true,
        );
      }
    }

    return ResolvedMediaPath(path: uri, source: PathSource.failed);
  }

  static String? getFileNameFromUri(String uri) {
    if (Platform.isWindows || uri.startsWith('file://')) {
      final path = uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
      return p.basename(path);
    }
    if (uri.startsWith('content://')) {
      final decoded = Uri.decodeFull(uri);
      return decoded.split('/').last;
    }
    return p.basename(uri);
  }

  static bool isMediaFile(String path) {
    return isVideoFile(path) || isAudioFile(path) || isImageFile(path);
  }

  static MediaType getMediaType(String path) {
    return RealPathUtils.getMediaType(path);
  }
}
