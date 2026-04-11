import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../data/models/play_history.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/history_repository.dart';
import '../../core/constants/supported_formats.dart';
import 'thumbnail_service.dart';

class PlaybackHistoryService {
  final HistoryRepository _repository;
  final ThumbnailService _thumbnailService;
  final HistorySaveMode _historySaveMode;
  Timer? _debounceTimer;
  bool _disposed = false;

  PlaybackHistoryService({
    required HistoryRepository repository,
    required ThumbnailService thumbnailService,
    HistorySaveMode historySaveMode = HistorySaveMode.realPath,
  })  : _repository = repository,
        _thumbnailService = thumbnailService,
        _historySaveMode = historySaveMode;

  Future<PlayHistory?> getOrCreateHistory(
    String path, {
    String? fileName,
    Duration? totalDuration,
  }) async {
    if (_disposed) return null;
    if (_historySaveMode == HistorySaveMode.none) return null;

    var history = await _repository.getByPath(path);

    if (_disposed) return null;

    if (history == null) {
      final currentDisplayName = p.basename(path);
      final allHistory =
          await _repository.getHistory(limit: 1000, offset: 0);
      if (_disposed) return null;
      for (final h in allHistory) {
        if (h.displayName == currentDisplayName) {
          history = h;
          break;
        }
      }
    }

    if (_disposed) return null;

    if (history == null) {
      return await _createNewHistory(path, fileName, totalDuration);
    } else {
      return await _updateExistingHistory(history, totalDuration);
    }
  }

  Future<PlayHistory> _createNewHistory(
    String path,
    String? fileName,
    Duration? totalDuration,
  ) async {
    if (_disposed) return _createFallbackHistory(path, fileName, totalDuration);

    final ext = _extractExtension(fileName ?? path);
    final displayName = fileName ?? p.basename(path);
    final mediaType = _detectMediaType(ext);

    final history = PlayHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      displayName: displayName,
      extension: ext,
      type: mediaType,
      lastPosition: Duration.zero,
      totalDuration: totalDuration,
      lastPlayedAt: DateTime.now(),
      playCount: 1,
    );

    await _repository.upsert(history);

    if (mediaType != MediaType.audio) {
      _generateThumbnailAsync(path, type: mediaType);
    }

    return history;
  }

  PlayHistory _createFallbackHistory(
    String path,
    String? fileName,
    Duration? totalDuration,
  ) {
    final ext = _extractExtension(fileName ?? path);
    final displayName = fileName ?? p.basename(path);
    final mediaType = _detectMediaType(ext);

    return PlayHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      displayName: displayName,
      extension: ext,
      type: mediaType,
      lastPosition: Duration.zero,
      totalDuration: totalDuration,
      lastPlayedAt: DateTime.now(),
      playCount: 1,
    );
  }

  Future<PlayHistory> _updateExistingHistory(
    PlayHistory history,
    Duration? totalDuration,
  ) async {
    if (_disposed) return history;

    final effectiveDuration =
        (totalDuration != null && totalDuration != Duration.zero)
            ? totalDuration
            : history.totalDuration;

    final updated = PlayHistory(
      id: history.id,
      path: history.path,
      displayName: history.displayName,
      extension: history.extension,
      type: history.type,
      lastPosition: history.lastPosition,
      totalDuration: effectiveDuration,
      lastPlayedAt: DateTime.now(),
      playCount: history.playCount + 1,
      thumbnailPath: history.thumbnailPath,
    );

    await _repository.upsert(updated);

    if (history.thumbnailPath == null) {
      _generateThumbnailAsync(history.path);
    }

    return updated;
  }

  Future<void> updatePosition(String path, Duration position) async {
    if (_disposed) return;
    try {
      await _repository.updatePosition(path, position);
    } catch (e) {
      if (!_disposed) {
        debugPrint('[PlaybackHistoryService] Error updating position: $e');
      }
    }
  }

  void updatePositionDebounced(String path, Duration position) {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!_disposed) {
        _repository.updatePosition(path, position);
      }
    });
  }

  Future<void> updateDuration(String path, Duration duration) async {
    if (_disposed) return;
    try {
      var history = await _repository.getByPath(path);
      if (_disposed) return;

      if (history != null) {
        final updatedHistory = PlayHistory(
          id: history.id,
          path: history.path,
          displayName: history.displayName,
          extension: history.extension,
          type: history.type,
          lastPosition: history.lastPosition,
          totalDuration: duration,
          lastPlayedAt: history.lastPlayedAt,
          playCount: history.playCount,
        );

        if (!_disposed) {
          await _repository.upsert(updatedHistory);
        }
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[PlaybackHistoryService] Error updating duration: $e');
      }
    }
  }

  void _generateThumbnailAsync(String path, {MediaType? type}) async {
    if (_disposed) return;
    try {
      final thumbPath = await _thumbnailService.generateThumbnail(
        path,
        type: type,
      );

      if (thumbPath != null && !_disposed) {
        var history = await _repository.getByPath(path);
        if (!_disposed && history != null) {
          final updatedHistory = PlayHistory(
            id: history.id,
            path: history.path,
            displayName: history.displayName,
            extension: history.extension,
            type: history.type,
            lastPosition: history.lastPosition,
            totalDuration: history.totalDuration,
            lastPlayedAt: history.lastPlayedAt,
            playCount: history.playCount,
            thumbnailPath: thumbPath,
          );
          await _repository.upsert(updatedHistory);
        }
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[PlaybackHistoryService] Thumbnail generation failed: $e');
      }
    }
  }

  String _extractExtension(String filename) {
    final ext = p.extension(filename).toLowerCase();
    return ext.length > 1 ? ext.substring(1) : ext;
  }

  MediaType _detectMediaType(String extension) {
    if (videoFormats.contains(extension)) {
      return MediaType.video;
    }
    if (audioFormats.contains(extension)) {
      return MediaType.audio;
    }
    if (imageFormats.contains(extension)) {
      return MediaType.image;
    }
    return MediaType.video;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounceTimer?.cancel();
  }
}
