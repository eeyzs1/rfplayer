import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/models/app_settings.dart';
import 'package:rfplayer/data/models/play_history.dart';
import 'package:rfplayer/data/repositories/history_repository.dart';
import 'package:rfplayer/domain/services/playback_history_service.dart';
import 'package:rfplayer/domain/services/thumbnail_service.dart';

class _FakeThumbnailService extends ThumbnailService {
  int generateCallCount = 0;
  String? lastPath;

  @override
  Future<String?> generateThumbnail(String filePath, {MediaType? type}) async {
    generateCallCount++;
    lastPath = filePath;
    return null;
  }
}

void main() {
  late AppDatabase db;
  late PlaybackHistoryService service;
  late _FakeThumbnailService thumbnailService;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    thumbnailService = _FakeThumbnailService();
    service = PlaybackHistoryService(
      repository: HistoryRepository(db.historyDao),
      thumbnailService: thumbnailService,
      historySaveMode: HistorySaveMode.realPath,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('PlaybackHistoryService', () {
    test('getOrCreateHistory creates new history for new path', () async {
      final history = await service.getOrCreateHistory('/test/video.mp4');

      expect(history, isNotNull);
      expect(history!.path, '/test/video.mp4');
      expect(history.displayName, 'video.mp4');
      expect(history.extension, 'mp4');
      expect(history.type, MediaType.video);
      expect(history.playCount, 1);
    });

    test('getOrCreateHistory returns null when HistorySaveMode is none', () async {
      final noSaveService = PlaybackHistoryService(
        repository: HistoryRepository(db.historyDao),
        thumbnailService: thumbnailService,
        historySaveMode: HistorySaveMode.none,
      );

      final history = await noSaveService.getOrCreateHistory('/test/video.mp4');
      expect(history, isNull);

      noSaveService.dispose();
    });

    test('getOrCreateHistory increments playCount for existing path', () async {
      await service.getOrCreateHistory('/test/video.mp4');
      final history = await service.getOrCreateHistory('/test/video.mp4');

      expect(history!.playCount, 2);
    });

    test('getOrCreateHistory detects media type correctly', () async {
      final videoHistory = await service.getOrCreateHistory('/test/video.mkv');
      expect(videoHistory!.type, MediaType.video);

      final audioHistory = await service.getOrCreateHistory('/test/song.mp3');
      expect(audioHistory!.type, MediaType.audio);

      final imageHistory = await service.getOrCreateHistory('/test/photo.jpg');
      expect(imageHistory!.type, MediaType.image);
    });

    test('getOrCreateHistory uses fileName parameter for display name', () async {
      final history = await service.getOrCreateHistory(
        'content://media/123',
        fileName: 'My Video.mp4',
      );

      expect(history!.displayName, 'My Video.mp4');
    });

    test('updatePosition updates position in repository', () async {
      await service.getOrCreateHistory('/test/video.mp4');
      await service.updatePosition('/test/video.mp4', const Duration(minutes: 5));

      final repo = HistoryRepository(db.historyDao);
      final history = await repo.getByPath('/test/video.mp4');
      expect(history!.lastPosition, const Duration(minutes: 5));
    });

    test('updateDuration updates duration', () async {
      await service.getOrCreateHistory('/test/video.mp4');
      await service.updateDuration('/test/video.mp4', const Duration(hours: 1, minutes: 30));

      final repo = HistoryRepository(db.historyDao);
      final history = await repo.getByPath('/test/video.mp4');
      expect(history!.totalDuration, const Duration(hours: 1, minutes: 30));
    });

    test('updatePositionDebounced does not update immediately', () async {
      await service.getOrCreateHistory('/test/video.mp4');

      service.updatePositionDebounced('/test/video.mp4', const Duration(minutes: 5));

      final repo = HistoryRepository(db.historyDao);
      final history = await repo.getByPath('/test/video.mp4');
      expect(history!.lastPosition, isNot(equals(const Duration(minutes: 5))));
    });

    test('dispose cancels debounce timer and prevents further operations', () async {
      await service.getOrCreateHistory('/test/video.mp4');
      service.dispose();

      final history = await service.getOrCreateHistory('/test/video2.mp4');
      expect(history, isNull);
    });

    test('triggers thumbnail generation for video files', () async {
      await service.getOrCreateHistory('/test/video.mp4');

      expect(thumbnailService.generateCallCount, greaterThan(0));
      expect(thumbnailService.lastPath, '/test/video.mp4');
    });

    test('does not trigger thumbnail for audio files', () async {
      await service.getOrCreateHistory('/test/song.mp3');

      expect(thumbnailService.generateCallCount, 0);
    });
  });
}
