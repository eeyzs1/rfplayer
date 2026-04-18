import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/history_repository.dart';
import 'package:rfplayer/data/models/play_history.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = HistoryRepository(db.historyDao);
  });

  tearDown(() async {
    await db.close();
  });

  PlayHistory createHistory({
    String id = 'test-id',
    String path = '/test/video.mp4',
    String displayName = 'video.mp4',
    String extension = 'mp4',
    MediaType type = MediaType.video,
    String? thumbnailPath,
    Duration? lastPosition,
    Duration? totalDuration,
    int playCount = 1,
  }) {
    return PlayHistory(
      id: id,
      path: path,
      displayName: displayName,
      extension: extension,
      type: type,
      thumbnailPath: thumbnailPath,
      lastPosition: lastPosition,
      totalDuration: totalDuration,
      lastPlayedAt: DateTime(2024, 1, 1),
      playCount: playCount,
    );
  }

  group('HistoryRepository', () {
    test('getHistory returns empty list initially', () async {
      final history = await repository.getHistory();
      expect(history, isEmpty);
    });

    test('upsert and getByPath', () async {
      final history = createHistory();
      await repository.upsert(history);

      final result = await repository.getByPath('/test/video.mp4');
      expect(result, isNotNull);
      expect(result!.path, '/test/video.mp4');
    });

    test('updatePosition updates position', () async {
      await repository.upsert(createHistory(
        lastPosition: Duration.zero,
        totalDuration: const Duration(minutes: 10),
      ));

      await repository.updatePosition('/test/video.mp4', const Duration(minutes: 5));

      final result = await repository.getByPath('/test/video.mp4');
      expect(result!.lastPosition, const Duration(minutes: 5));
    });

    test('deleteById removes entry', () async {
      await repository.upsert(createHistory(id: 'to-delete'));
      await repository.deleteById('to-delete');

      final result = await repository.getByPath('/test/video.mp4');
      expect(result, isNull);
    });

    test('deleteAll removes all entries', () async {
      await repository.upsert(createHistory(id: 'id-1', path: '/v1.mp4', displayName: 'v1'));
      await repository.upsert(createHistory(id: 'id-2', path: '/v2.mp4', displayName: 'v2'));

      await repository.deleteAll();

      final history = await repository.getHistory();
      expect(history, isEmpty);
    });

    test('deleteByPath removes entry by path', () async {
      await repository.upsert(createHistory(id: 'id-1', path: '/v1.mp4', displayName: 'v1'));
      await repository.upsert(createHistory(id: 'id-2', path: '/v2.mp4', displayName: 'v2'));

      await repository.deleteByPath('/v1.mp4');

      final history = await repository.getHistory();
      expect(history.length, 1);
      expect(history[0].path, '/v2.mp4');
    });

    test('updateThumbnail updates thumbnail path', () async {
      await repository.upsert(createHistory());

      await repository.updateThumbnail('/test/video.mp4', '/thumb/video.jpg');

      final result = await repository.getByPath('/test/video.mp4');
      expect(result!.thumbnailPath, '/thumb/video.jpg');
    });

    test('updateThumbnail does nothing for non-existent path', () async {
      await repository.updateThumbnail('/nonexistent', '/thumb.jpg');

      final result = await repository.getByPath('/nonexistent');
      expect(result, isNull);
    });

    test('getRecent returns limited results', () async {
      for (int i = 0; i < 10; i++) {
        await repository.upsert(createHistory(
          id: 'id-$i',
          path: '/v$i.mp4',
          displayName: 'v$i',
        ));
      }

      final recent = await repository.getRecent(limit: 3);
      expect(recent.length, 3);
    });

    test('watchHistory returns stream', () async {
      final stream = repository.watchHistory();

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);

      await repository.upsert(createHistory());

      final secondEmission = await stream.first;
      expect(secondEmission.length, 1);
    });
  });
}
