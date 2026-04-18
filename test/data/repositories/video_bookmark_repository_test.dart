import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/video_bookmark_repository.dart';
import 'package:rfplayer/data/models/video_bookmark.dart';

void main() {
  late AppDatabase db;
  late VideoBookmarkRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = VideoBookmarkRepository(db.videoBookmarkDao);
  });

  tearDown(() async {
    await db.close();
  });

  VideoBookmark createBookmark({
    String id = 'test-id',
    String videoPath = '/test/video.mp4',
    String videoName = 'video.mp4',
    Duration position = Duration.zero,
    String? note,
    BookmarkType type = BookmarkType.video,
  }) {
    return VideoBookmark(
      id: id,
      videoPath: videoPath,
      videoName: videoName,
      position: position,
      note: note,
      createdAt: DateTime(2024, 1, 1),
      type: type,
    );
  }

  group('VideoBookmarkRepository', () {
    test('getAll returns empty list initially', () async {
      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('addBookmark and getAll', () async {
      final bookmark = createBookmark(note: 'Test note');
      await repository.addBookmark(bookmark);

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all[0].note, 'Test note');
    });

    test('getByVideoPath returns bookmarks for specific video', () async {
      await repository.addBookmark(createBookmark(id: 'id-1', videoPath: '/video1.mp4', videoName: 'video1.mp4'));
      await repository.addBookmark(createBookmark(id: 'id-2', videoPath: '/video2.mp4', videoName: 'video2.mp4'));

      final result = await repository.getByVideoPath('/video1.mp4');
      expect(result.length, 1);
      expect(result[0].videoPath, '/video1.mp4');
    });

    test('deleteBookmark removes bookmark by id', () async {
      await repository.addBookmark(createBookmark(id: 'to-delete'));
      await repository.deleteBookmark('to-delete');

      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('deleteAllBookmarksForVideo removes all bookmarks for video', () async {
      await repository.addBookmark(createBookmark(id: 'id-1', videoPath: '/video1.mp4', videoName: 'video1.mp4'));
      await repository.addBookmark(createBookmark(id: 'id-2', videoPath: '/video1.mp4', videoName: 'video1.mp4', position: const Duration(minutes: 5)));
      await repository.addBookmark(createBookmark(id: 'id-3', videoPath: '/video2.mp4', videoName: 'video2.mp4'));

      await repository.deleteAllBookmarksForVideo('/video1.mp4');

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all[0].videoPath, '/video2.mp4');
    });
  });
}
