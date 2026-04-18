import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/play_queue_repository.dart';

void main() {
  late AppDatabase db;
  late PlayQueueRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = PlayQueueRepository(db.playQueueDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlayQueueRepository', () {
    test('getAll returns empty list initially', () async {
      final items = await repository.getAll();
      expect(items, isEmpty);
    });

    test('add and getAll with content URI', () async {
      await repository.add('content://media/video1', 'video1.mp4');

      final items = await repository.getAll();
      expect(items.length, 1);
      expect(items[0].path, 'content://media/video1');
    });

    test('add deduplicates by displayName for content URIs', () async {
      await repository.add('content://media/video1', 'video1.mp4');
      await repository.add('content://media/video1', 'video1.mp4');

      final items = await repository.getAll();
      expect(items.length, 1);
    });

    test('remove deletes item by id', () async {
      await repository.add('content://media/video1', 'video1.mp4');

      final items = await repository.getAll();
      await repository.remove(items[0].id);

      final remaining = await repository.getAll();
      expect(remaining, isEmpty);
    });

    test('clear removes all items', () async {
      await repository.add('content://media/v1', 'v1.mp4');
      await repository.add('content://media/v2', 'v2.mp4');

      await repository.clear();

      final items = await repository.getAll();
      expect(items, isEmpty);
    });

    test('setCurrentPlaying sets current item', () async {
      await repository.add('content://media/v1', 'v1.mp4');
      await repository.add('content://media/v2', 'v2.mp4');

      final items = await repository.getAll();
      await repository.setCurrentPlaying(items[1].id);

      final current = await repository.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v2');
    });

    test('markAsPlayed marks item as played', () async {
      await repository.add('content://media/v1', 'v1.mp4');

      final items = await repository.getAll();
      await repository.setCurrentPlaying(items[0].id);
      await repository.markAsPlayed(items[0].id);

      final updated = await repository.getAll();
      expect(updated[0].hasPlayed, isTrue);
    });

    test('updatePlayProgress updates progress', () async {
      await repository.add('content://media/v1', 'v1.mp4');

      final items = await repository.getAll();
      await repository.updatePlayProgress(items[0].id, 0.5);

      final updated = await repository.getAll();
      expect(updated[0].playProgress, 0.5);
    });

    test('reorder updates sort orders', () async {
      await repository.add('content://media/v1', 'v1.mp4');
      await repository.add('content://media/v2', 'v2.mp4');
      await repository.add('content://media/v3', 'v3.mp4');

      final items = await repository.getAll();
      final ids = items.map((i) => i.id).toList();
      final reversed = ids.reversed.toList();

      await repository.reorder(reversed);

      final reordered = await repository.getAll();
      expect(reordered[0].path, 'content://media/v3');
      expect(reordered[1].path, 'content://media/v2');
      expect(reordered[2].path, 'content://media/v1');
    });

    test('getCurrentPlaying returns null initially', () async {
      final current = await repository.getCurrentPlaying();
      expect(current, isNull);
    });

    test('clearExceptCurrentPlaying keeps current item', () async {
      await repository.add('content://media/v1', 'v1.mp4');
      await repository.add('content://media/v2', 'v2.mp4');

      final items = await repository.getAll();
      await repository.setCurrentPlaying(items[0].id);

      await repository.clearExceptCurrentPlaying();

      final remaining = await repository.getAll();
      expect(remaining.length, 1);
      expect(remaining[0].path, 'content://media/v1');
    });

    test('getNextItem returns next item', () async {
      await repository.add('content://media/v1', 'v1.mp4');
      await repository.add('content://media/v2', 'v2.mp4');

      final items = await repository.getAll();
      await repository.setCurrentPlaying(items[0].id);

      final next = await repository.getNextItem(items[0].sortOrder);
      expect(next, isNotNull);
      expect(next!.path, 'content://media/v2');
    });

    test('getNextItem returns null when no next item', () async {
      await repository.add('content://media/v1', 'v1.mp4');

      final items = await repository.getAll();
      final next = await repository.getNextItem(items[0].sortOrder);
      expect(next, isNull);
    });

    test('getAll marks non-existent files as invalid', () async {
      await db.playQueueDao.insert(PlayQueueTableCompanion(
        id: Value('test-id'),
        path: Value('/nonexistent/file.mp4'),
        displayName: Value('file.mp4'),
        sortOrder: Value(0),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isCurrentPlaying: Value(0),
        hasPlayed: Value(0),
        playProgress: Value(0.0),
        isInvalid: Value(false),
      ));

      final items = await repository.getAll();
      expect(items[0].isInvalid, isTrue);
    });

    test('add throws for non-existent file path', () async {
      expect(
        () => repository.add('/nonexistent/file.mp4', 'file.mp4'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
