import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/database/daos/history_dao.dart';
import 'package:rfplayer/data/models/play_history.dart';

void main() {
  late AppDatabase db;
  late HistoryDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dao = db.historyDao;
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
    DateTime? lastPlayedAt,
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
      lastPlayedAt: lastPlayedAt ?? DateTime(2024, 1, 1),
      playCount: playCount,
    );
  }

  group('HistoryDao', () {
    test('upsert and getByPath', () async {
      final history = createHistory();
      await dao.upsert(history);

      final result = await dao.getByPath('/test/video.mp4');

      expect(result, isNotNull);
      expect(result!.path, '/test/video.mp4');
      expect(result.displayName, 'video.mp4');
      expect(result.type, MediaType.video);
    });

    test('getByPath returns null for non-existent path', () async {
      final result = await dao.getByPath('/nonexistent');
      expect(result, isNull);
    });

    test('upsert replaces existing entry (same path)', () async {
      final history1 = createHistory(id: 'id-1', playCount: 1);
      await dao.upsert(history1);

      final history2 = createHistory(id: 'id-2', playCount: 5);
      await dao.upsert(history2);

      final result = await dao.getByPath('/test/video.mp4');
      expect(result, isNotNull);
      expect(result!.playCount, 5);
    });

    test('getHistory returns items ordered by lastPlayedAt desc', () async {
      await dao.upsert(createHistory(
        id: 'id-1',
        path: '/video1.mp4',
        displayName: 'video1.mp4',
        lastPlayedAt: DateTime(2024, 1, 1),
      ));

      await dao.upsert(createHistory(
        id: 'id-2',
        path: '/video2.mp4',
        displayName: 'video2.mp4',
        lastPlayedAt: DateTime(2024, 1, 2),
      ));

      final history = await dao.getHistory();
      expect(history.length, 2);
      expect(history[0].path, '/video2.mp4');
      expect(history[1].path, '/video1.mp4');
    });

    test('getHistory respects limit', () async {
      for (int i = 0; i < 10; i++) {
        await dao.upsert(createHistory(
          id: 'id-$i',
          path: '/video$i.mp4',
          displayName: 'video$i.mp4',
        ));
      }

      final history = await dao.getHistory(limit: 5);
      expect(history.length, 5);
    });

    test('updatePosition updates position', () async {
      await dao.upsert(createHistory(
        lastPosition: Duration.zero,
        totalDuration: const Duration(minutes: 10),
      ));

      await dao.updatePosition('/test/video.mp4', const Duration(minutes: 5));

      final result = await dao.getByPath('/test/video.mp4');
      expect(result!.lastPosition, const Duration(minutes: 5));
    });

    test('deleteById removes entry', () async {
      await dao.upsert(createHistory(id: 'to-delete'));
      await dao.deleteById('to-delete');

      final result = await dao.getByPath('/test/video.mp4');
      expect(result, isNull);
    });

    test('deleteAll removes all entries', () async {
      await dao.upsert(createHistory(id: 'id-1', path: '/v1.mp4', displayName: 'v1'));
      await dao.upsert(createHistory(id: 'id-2', path: '/v2.mp4', displayName: 'v2'));

      await dao.deleteAll();

      final history = await dao.getHistory();
      expect(history, isEmpty);
    });

    test('deleteByPath removes entry by path', () async {
      await dao.upsert(createHistory(id: 'id-1', path: '/v1.mp4', displayName: 'v1'));
      await dao.upsert(createHistory(id: 'id-2', path: '/v2.mp4', displayName: 'v2'));

      await dao.deleteByPath('/v1.mp4');

      final history = await dao.getHistory();
      expect(history.length, 1);
      expect(history[0].path, '/v2.mp4');
    });

    test('watchHistory emits updates', () async {
      final stream = dao.watchHistory();

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);

      await dao.upsert(createHistory());

      final secondEmission = await stream.first;
      expect(secondEmission.length, 1);
    });
  });
}
