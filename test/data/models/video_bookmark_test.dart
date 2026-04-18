import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/video_bookmark.dart';

void main() {
  group('VideoBookmark', () {
    final now = DateTime(2024, 6, 15, 10, 30);

    test('creates video bookmark with all properties', () {
      final bookmark = VideoBookmark(
        id: 'test-id',
        videoPath: '/test/video.mp4',
        videoName: 'video.mp4',
        position: const Duration(minutes: 5, seconds: 30),
        note: 'Interesting part',
        createdAt: now,
        type: BookmarkType.video,
      );

      expect(bookmark.id, 'test-id');
      expect(bookmark.videoPath, '/test/video.mp4');
      expect(bookmark.videoName, 'video.mp4');
      expect(bookmark.position, const Duration(minutes: 5, seconds: 30));
      expect(bookmark.note, 'Interesting part');
      expect(bookmark.createdAt, now);
      expect(bookmark.type, BookmarkType.video);
    });

    test('defaults type to BookmarkType.video', () {
      final bookmark = VideoBookmark(
        id: 'test-id',
        videoPath: '/test/video.mp4',
        videoName: 'video.mp4',
        position: Duration.zero,
        createdAt: now,
      );

      expect(bookmark.type, BookmarkType.video);
    });

    test('supports copyWith', () {
      final bookmark = VideoBookmark(
        id: 'test-id',
        videoPath: '/test/video.mp4',
        videoName: 'video.mp4',
        position: const Duration(minutes: 5),
        note: 'Original note',
        createdAt: now,
      );

      final copied = bookmark.copyWith(
        note: 'Updated note',
        position: const Duration(minutes: 10),
      );

      expect(copied.id, bookmark.id);
      expect(copied.videoPath, bookmark.videoPath);
      expect(copied.note, 'Updated note');
      expect(copied.position, const Duration(minutes: 10));
    });

    test('supports equality', () {
      final bookmark1 = VideoBookmark(
        id: 'test-id',
        videoPath: '/test/video.mp4',
        videoName: 'video.mp4',
        position: const Duration(minutes: 5),
        createdAt: now,
      );

      final bookmark2 = VideoBookmark(
        id: 'test-id',
        videoPath: '/test/video.mp4',
        videoName: 'video.mp4',
        position: const Duration(minutes: 5),
        createdAt: now,
      );

      expect(bookmark1, equals(bookmark2));
    });

    test('BookmarkType has all values', () {
      expect(BookmarkType.values.length, 2);
      expect(BookmarkType.values, contains(BookmarkType.video));
      expect(BookmarkType.values, contains(BookmarkType.image));
    });
  });
}
