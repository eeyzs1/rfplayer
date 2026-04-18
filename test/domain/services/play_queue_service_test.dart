import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/play_queue_repository.dart';
import 'package:rfplayer/domain/services/play_queue_service.dart';

void main() {
  late AppDatabase db;
  late PlayQueueService service;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    service = PlayQueueService(PlayQueueRepository(db.playQueueDao));
  });

  tearDown(() async {
    await db.close();
  });

  group('PlayQueueService', () {
    test('getQueue returns empty list initially', () async {
      final queue = await service.getQueue();
      expect(queue, isEmpty);
    });

    test('addToQueue adds item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      expect(queue.length, 1);
      expect(queue[0].path, 'content://media/v1');
    });

    test('addToQueue deduplicates', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      expect(queue.length, 1);
    });

    test('removeFromQueue removes item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      await service.removeFromQueue(queue[0].id);

      final remaining = await service.getQueue();
      expect(remaining, isEmpty);
    });

    test('playItem sets current playing', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[1].id);

      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v2');
    });

    test('playNext moves to next item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);
      await service.playNext();

      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v2');
    });

    test('playNext wraps around to first item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[1].id);
      await service.playNext();

      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v1');
    });

    test('playPrevious moves to previous item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[1].id);
      await service.playPrevious();

      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v1');
    });

    test('playPrevious wraps around to last item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);
      await service.playPrevious();

      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v2');
    });

    test('removeFromQueueWithHandling returns true when only item removed', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);
      final shouldGoHome = await service.removeFromQueueWithHandling(queue[0].id);

      expect(shouldGoHome, isTrue);
      final remaining = await service.getQueue();
      expect(remaining, isEmpty);
    });

    test('removeFromQueueWithHandling returns false when non-current item removed', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      final nonCurrentId = queue[1].id;
      await service.playItem(queue[0].id);

      final shouldGoHome = await service.removeFromQueueWithHandling(nonCurrentId);

      expect(shouldGoHome, isFalse);
    });

    test('removeFromQueueWithHandling switches to next when current removed', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);

      final shouldGoHome = await service.removeFromQueueWithHandling(queue[0].id);

      expect(shouldGoHome, isFalse);
      final current = await service.getCurrentPlaying();
      expect(current, isNotNull);
      expect(current!.path, 'content://media/v2');
    });

    test('clearQueue keeps current playing item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);

      await service.clearQueue();

      final remaining = await service.getQueue();
      expect(remaining.length, 1);
      expect(remaining[0].path, 'content://media/v1');
    });

    test('reorderQueue reorders items', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');
      await service.addToQueue('content://media/v3', 'v3.mp4');

      await service.reorderQueue(2, 0);

      final queue = await service.getQueue();
      expect(queue[0].path, 'content://media/v3');
    });

    test('markAsPlayed marks item as played', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      await service.markAsPlayed(queue[0].id);

      final updated = await service.getQueue();
      expect(updated[0].hasPlayed, isTrue);
    });

    test('updatePlayProgress updates progress', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');

      final queue = await service.getQueue();
      await service.updatePlayProgress(queue[0].id, 0.75);

      final updated = await service.getQueue();
      expect(updated[0].playProgress, 0.75);
    });

    test('getNextItem returns next item', () async {
      await service.addToQueue('content://media/v1', 'v1.mp4');
      await service.addToQueue('content://media/v2', 'v2.mp4');

      final queue = await service.getQueue();
      await service.playItem(queue[0].id);

      final next = await service.getNextItem();
      expect(next, isNotNull);
      expect(next!.path, 'content://media/v2');
    });
  });
}
