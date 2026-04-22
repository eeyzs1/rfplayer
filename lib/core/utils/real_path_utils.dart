import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../constants/supported_formats.dart';

enum MediaType { video, audio, image, unknown }

enum PathSource { realPath, contentUri, failed }

class ResolvedMediaPath {
  final String path;
  final PathSource source;
  final String? originalContentUri;
  final bool canStoreInHistory;
  final String? displayName;
  final bool needsPersistRequest;

  const ResolvedMediaPath({
    required this.path,
    required this.source,
    this.originalContentUri,
    this.canStoreInHistory = false,
    this.displayName,
    this.needsPersistRequest = false,
  });

  bool get isPlayable => source != PathSource.failed;
  bool get isFromContentUri => source == PathSource.contentUri;
}

class RealPathUtils {
  static const MethodChannel _channel = MethodChannel('com.rfplayer.app/real_path');

  static bool isContentUri(String path) {
    return path.startsWith('content://');
  }

  static Future<int?> getSdkVersion() async {
    if (!Platform.isAndroid) return null;

    try {
      return await _channel.invokeMethod('getSdkVersion');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> canOpenFileNative(String path) async {
    if (!Platform.isAndroid) return File(path).existsSync();

    try {
      return await _channel.invokeMethod('canOpenFileNative', {'path': path}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasMediaPermission(String mediaType) async {
    if (!Platform.isAndroid) return true;

    try {
      return await _channel.invokeMethod('hasMediaPermission', {'mediaType': mediaType}) ?? false;
    } catch (_) {
      return false;
    }
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

  static Future<String?> getDisplayName(String uri) async {
    if (!isContentUri(uri)) return null;
    if (!Platform.isAndroid) return null;

    try {
      return await _channel.invokeMethod('getDisplayName', {'uri': uri});
    } catch (_) {
      return null;
    }
  }

  static Future<ResolvedMediaPath> resolveContentUri(String contentUri) async {
    if (!isContentUri(contentUri)) {
      return ResolvedMediaPath(path: contentUri, source: PathSource.realPath, canStoreInHistory: true);
    }
    if (!Platform.isAndroid) {
      return ResolvedMediaPath(path: contentUri, source: PathSource.failed);
    }

    final displayName = await getDisplayName(contentUri);

    final nameForType = displayName ?? '';
    final mediaType = _getMediaType(nameForType);
    final hasPermission = await hasMediaPermission(_mediaTypeToString(mediaType));

    if (hasPermission) {
      try {
        final realPath = await getRealPath(contentUri);
        if (realPath != null) {
          final canOpen = await canOpenFileNative(realPath);
          if (canOpen) {
            return ResolvedMediaPath(
              path: realPath,
              source: PathSource.realPath,
              originalContentUri: contentUri,
              canStoreInHistory: true,
              displayName: displayName ?? p.basename(realPath),
            );
          }
        }
      } catch (_) {}
    }

    return ResolvedMediaPath(
      path: contentUri,
      source: PathSource.contentUri,
      originalContentUri: contentUri,
      canStoreInHistory: false,
      displayName: displayName,
      needsPersistRequest: true,
    );
  }

  static Future<String?> getSafePath(String path) async {
    if (!isContentUri(path)) return path;

    final resolved = await resolveContentUri(path);
    if (resolved.isPlayable) return resolved.path;
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

  static Future<String?> cacheContentUri(String uri, [String ext = '', String cacheDir = 'subtitle_cache']) async {
    if (!isContentUri(uri)) return null;
    if (!Platform.isAndroid) return null;

    try {
      return await _channel.invokeMethod('cacheContentUri', {'uri': uri, 'ext': ext, 'cacheDir': cacheDir});
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> readContentUriBytes(String uri) async {
    if (!isContentUri(uri)) return null;
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<Uint8List>('readContentUriBytes', {'uri': uri});
      return result;
    } catch (_) {
      return null;
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

  static MediaType _getMediaType(String path) {
    if (isVideoFile(path)) return MediaType.video;
    if (isAudioFile(path)) return MediaType.audio;
    if (isImageFile(path)) return MediaType.image;
    return MediaType.unknown;
  }

  static String _mediaTypeToString(MediaType type) {
    return switch (type) {
      MediaType.video => 'video',
      MediaType.audio => 'audio',
      MediaType.image => 'image',
      MediaType.unknown => 'unknown',
    };
  }

  static bool isMediaFile(String path) {
    return isVideoFile(path) || isAudioFile(path) || isImageFile(path);
  }

  static MediaType getMediaType(String path) => _getMediaType(path);
}
