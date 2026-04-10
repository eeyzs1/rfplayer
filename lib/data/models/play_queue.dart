import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class PlayQueueItem {
  final String id;
  final String path;
  final String displayName;
  final int sortOrder;
  final DateTime addedAt;
  final bool isCurrentPlaying;
  final bool hasPlayed;
  final double playProgress;
  final bool isInvalid;

  PlayQueueItem({
    required this.id,
    required this.path,
    required this.displayName,
    required this.sortOrder,
    required this.addedAt,
    required this.isCurrentPlaying,
    required this.hasPlayed,
    required this.playProgress,
    this.isInvalid = false,
  });

  factory PlayQueueItem.fromPath(String path, int sortOrder) {
    return PlayQueueItem(
      id: const Uuid().v4(),
      path: path,
      displayName: p.basename(path),
      sortOrder: sortOrder,
      addedAt: DateTime.now(),
      isCurrentPlaying: false,
      hasPlayed: false,
      playProgress: 0.0,
      isInvalid: false,
    );
  }

  static Future<PlayQueueItem> fromPathAsync(String path, int sortOrder) async {
    bool isInvalid = false;
    if (!path.startsWith('content://')) {
      try {
        isInvalid = !await File(path).exists();
      } catch (_) {
        isInvalid = true;
      }
    }
    return PlayQueueItem(
      id: const Uuid().v4(),
      path: path,
      displayName: p.basename(path),
      sortOrder: sortOrder,
      addedAt: DateTime.now(),
      isCurrentPlaying: false,
      hasPlayed: false,
      playProgress: 0.0,
      isInvalid: isInvalid,
    );
  }

  String get resourceType => 'video';
}