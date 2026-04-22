import 'dart:io';
import '../../core/extensions/duration_extensions.dart';
import '../../core/utils/real_path_utils.dart' show MediaType;
export '../../core/utils/real_path_utils.dart' show MediaType;

class PlayHistory {
  final String id;
  final String path;
  final String displayName;
  final String extension;
  final MediaType type;
  final String? thumbnailPath;
  final Duration? lastPosition;
  final Duration? totalDuration;
  final DateTime lastPlayedAt;
  final int playCount;

  PlayHistory({
    required this.id,
    required this.path,
    required this.displayName,
    required this.extension,
    required this.type,
    this.thumbnailPath,
    this.lastPosition,
    this.totalDuration,
    required this.lastPlayedAt,
    required this.playCount,
  });

  factory PlayHistory.fromDb(dynamic row) {
    return PlayHistory(
      id: row.id,
      path: row.path,
      displayName: row.displayName,
      extension: row.extension,
      type: MediaType.values[row.type],
      thumbnailPath: row.thumbnailPath,
      lastPosition: row.lastPositionMs != null ? Duration(milliseconds: row.lastPositionMs!) : null,
      totalDuration: row.totalDurationMs != null ? Duration(milliseconds: row.totalDurationMs!) : null,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(row.lastPlayedAt),
      playCount: row.playCount,
    );
  }

  double get progress {
    if (lastPosition == null || totalDuration == null) return 0.0;
    if (totalDuration!.inMilliseconds == 0) return 0.0;
    return (lastPosition!.inMilliseconds / totalDuration!.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get isCompleted => progress > 0.95;

  String get progressString {
    if (lastPosition == null || totalDuration == null) {
      return '';
    }
    // 确保总时长不为零
    if (totalDuration!.inMilliseconds == 0) {
      return '${lastPosition!.toHHMMSS()} / --:--';
    }
    return lastPosition!.toProgressString(totalDuration!);
  }

  Future<bool> get fileExists async {
    if (path.startsWith('content://')) return true;
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }
}