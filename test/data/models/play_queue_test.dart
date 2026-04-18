import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/play_queue.dart';

void main() {
  group('PlayQueueItem', () {
    group('fromPath', () {
      test('creates item with correct properties', () {
        final item = PlayQueueItem.fromPath('/test/video.mp4', 0);

        expect(item.path, '/test/video.mp4');
        expect(item.displayName, 'video.mp4');
        expect(item.sortOrder, 0);
        expect(item.isCurrentPlaying, isFalse);
        expect(item.hasPlayed, isFalse);
        expect(item.playProgress, 0.0);
        expect(item.isInvalid, isFalse);
        expect(item.id, isNotEmpty);
      });

      test('creates item with different sort orders', () {
        final item1 = PlayQueueItem.fromPath('/test/a.mp4', 0);
        final item2 = PlayQueueItem.fromPath('/test/b.mp4', 1);

        expect(item1.sortOrder, 0);
        expect(item2.sortOrder, 1);
      });

      test('generates unique IDs', () {
        final item1 = PlayQueueItem.fromPath('/test/a.mp4', 0);
        final item2 = PlayQueueItem.fromPath('/test/b.mp4', 1);

        expect(item1.id, isNot(equals(item2.id)));
      });
    });

    group('resourceType', () {
      test('returns video', () {
        final item = PlayQueueItem.fromPath('/test/video.mp4', 0);
        expect(item.resourceType, 'video');
      });
    });

    group('constructor', () {
      test('creates item with all properties', () {
        final now = DateTime.now();
        final item = PlayQueueItem(
          id: 'test-id',
          path: '/test/video.mp4',
          displayName: 'video.mp4',
          sortOrder: 1,
          addedAt: now,
          isCurrentPlaying: true,
          hasPlayed: false,
          playProgress: 0.5,
          isInvalid: false,
        );

        expect(item.id, 'test-id');
        expect(item.path, '/test/video.mp4');
        expect(item.displayName, 'video.mp4');
        expect(item.sortOrder, 1);
        expect(item.addedAt, now);
        expect(item.isCurrentPlaying, isTrue);
        expect(item.hasPlayed, isFalse);
        expect(item.playProgress, 0.5);
        expect(item.isInvalid, isFalse);
      });

      test('defaults isInvalid to false', () {
        final item = PlayQueueItem(
          id: 'test-id',
          path: '/test/video.mp4',
          displayName: 'video.mp4',
          sortOrder: 0,
          addedAt: DateTime.now(),
          isCurrentPlaying: false,
          hasPlayed: false,
          playProgress: 0.0,
        );

        expect(item.isInvalid, isFalse);
      });
    });
  });
}
