import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/database/daos/play_queue_dao.dart';

void main() {
  late AppDatabase db;
  late PlayQueueDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dao = db.playQueueDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('PlayQueueDao', () {
    test('insert and getAll', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-1'),
        path: Value('/video1.mp4'),
        displayName: Value('video1.mp4'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      final items = await dao.getAll();
      expect(items.length, 1);
      expect(items[0].path, '/video1.mp4');
      expect(items[0].displayName, 'video1.mp4');
    });

    test('getAll returns items ordered by sortOrder', () async {
      for (int i = 0; i < 3; i++) {
        await dao.insert(PlayQueueTableCompanion(
          id: Value('id-$i'),
          path: Value('/video$i.mp4'),
          displayName: Value('video$i.mp4'),
          sortOrder: Value(2 - i),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isCurrentPlaying: Value(0),
          hasPlayed: Value(0),
          playProgress: Value(0.0),
          isInvalid: Value(false),
        ));
      }

      final items = await dao.getAll();
      expect(items[0].displayName, 'video2.mp4');
      expect(items[1].displayName, 'video1.mp4');
      expect(items[2].displayName, 'video0.mp4');
    });

    test('deleteById removes item', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('to-delete'),
        path: Value('/video.mp4'),
        displayName: Value('video.mp4'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.deleteById('to-delete');

      final items = await dao.getAll();
      expect(items, isEmpty);
    });

    test('deleteAll removes all items', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-1'),
        path: Value('/v1.mp4'),
        displayName: Value('v1'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-2'),
        path: Value('/v2.mp4'),
        displayName: Value('v2'),
        sortOrder: Value(1),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.deleteAll();

      final items = await dao.getAll();
      expect(items, isEmpty);
    });

    test('deleteAllExceptCurrentPlaying keeps current item', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('current'),
        path: Value('/current.mp4'),
        displayName: Value('current'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(1),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));
      await dao.insert(PlayQueueTableCompanion(
        id: Value('other'),
        path: Value('/other.mp4'),
        displayName: Value('other'),
        sortOrder: Value(1),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.deleteAllExceptCurrentPlaying();

      final items = await dao.getAll();
      expect(items.length, 1);
      expect(items[0].id, 'current');
      expect(items[0].sortOrder, 0);
    });

    test('setCurrentPlaying sets only one item as current', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-1'),
        path: Value('/v1.mp4'),
        displayName: Value('v1'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(1),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-2'),
        path: Value('/v2.mp4'),
        displayName: Value('v2'),
        sortOrder: Value(1),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.setCurrentPlaying('id-2');

      final items = await dao.getAll();
      expect(items.where((i) => i.isCurrentPlaying).length, 1);
      expect(items.firstWhere((i) => i.isCurrentPlaying).id, 'id-2');
    });

    test('markAsPlayed marks item as played and not current', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-1'),
        path: Value('/v1.mp4'),
        displayName: Value('v1'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(1),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.markAsPlayed('id-1');

      final items = await dao.getAll();
      expect(items[0].hasPlayed, isTrue);
      expect(items[0].isCurrentPlaying, isFalse);
    });

    test('updatePlayProgress updates progress', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-1'),
        path: Value('/v1.mp4'),
        displayName: Value('v1'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      await dao.updatePlayProgress('id-1', 0.5);

      final items = await dao.getAll();
      expect(items[0].playProgress, 0.5);
    });

    test('reorder updates sort orders', () async {
      for (int i = 0; i < 3; i++) {
        await dao.insert(PlayQueueTableCompanion(
          id: Value('id-$i'),
          path: Value('/v$i.mp4'),
          displayName: Value('v$i'),
          sortOrder: Value(i),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isCurrentPlaying: Value(0),
          hasPlayed: Value(0),
          playProgress: Value(0.0),
          isInvalid: Value(false),
        ));
      }

      await dao.reorder(['id-2', 'id-0', 'id-1']);

      final items = await dao.getAll();
      expect(items[0].id, 'id-2');
      expect(items[1].id, 'id-0');
      expect(items[2].id, 'id-1');
    });

    test('getCurrentPlaying returns current item', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('current'),
        path: Value('/current.mp4'),
        displayName: Value('current'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(1),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      final current = await dao.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.id, 'current');
    });

    test('getCurrentPlaying returns null when no current item', () async {
      final current = await dao.getCurrentPlaying();
      expect(current, isNull);
    });

    test('getNextItem returns next item by sortOrder', () async {
      for (int i = 0; i < 3; i++) {
        await dao.insert(PlayQueueTableCompanion(
          id: Value('id-$i'),
          path: Value('/v$i.mp4'),
          displayName: Value('v$i'),
          sortOrder: Value(i),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isCurrentPlaying: Value(i == 0 ? 1 : 0),
          hasPlayed: Value(0),
          playProgress: Value(0.0),
          isInvalid: Value(false),
        ));
      }

      final next = await dao.getNextItem(0);
      expect(next, isNotNull);
      expect(next!.id, 'id-1');
    });

    test('getNextItem returns null when no next item', () async {
      await dao.insert(PlayQueueTableCompanion(
        id: Value('id-0'),
        path: Value('/v0.mp4'),
        displayName: Value('v0'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(1),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      final next = await dao.getNextItem(0);
      expect(next, isNull);
    });
  });
}
