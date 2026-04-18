import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/database/daos/video_bookmark_dao.dart';
import 'package:rfplayer/data/models/video_bookmark.dart';

void main() {
  late AppDatabase db;
  late VideoBookmarkDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dao = db.videoBookmarkDao;
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

  group('VideoBookmarkDao', () {
    test('insert and getAll', () async {
      final bookmark = createBookmark(note: 'Test note');
      await dao.insert(bookmark);

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].videoPath, '/test/video.mp4');
      expect(all[0].note, 'Test note');
    });

    test('getByVideoPath returns bookmarks for specific video', () async {
      await dao.insert(createBookmark(id: 'id-1', videoPath: '/video1.mp4', videoName: 'video1.mp4'));
      await dao.insert(createBookmark(id: 'id-2', videoPath: '/video2.mp4', videoName: 'video2.mp4'));
      await dao.insert(createBookmark(id: 'id-3', videoPath: '/video1.mp4', videoName: 'video1.mp4', position: const Duration(minutes: 5)));

      final result = await dao.getByVideoPath('/video1.mp4');
      expect(result.length, 2);
    });

    test('getByVideoPath returns empty list for non-existent path', () async {
      final result = await dao.getByVideoPath('/nonexistent.mp4');
      expect(result, isEmpty);
    });

    test('deleteById removes bookmark', () async {
      await dao.insert(createBookmark(id: 'to-delete'));
      await dao.deleteById('to-delete');

      final all = await dao.getAll();
      expect(all, isEmpty);
    });

    test('deleteByVideoPath removes all bookmarks for video', () async {
      await dao.insert(createBookmark(id: 'id-1', videoPath: '/video1.mp4', videoName: 'video1.mp4'));
      await dao.insert(createBookmark(id: 'id-2', videoPath: '/video1.mp4', videoName: 'video1.mp4', position: const Duration(minutes: 5)));
      await dao.insert(createBookmark(id: 'id-3', videoPath: '/video2.mp4', videoName: 'video2.mp4'));

      await dao.deleteByVideoPath('/video1.mp4');

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].videoPath, '/video2.mp4');
    });

    test('preserves BookmarkType correctly', () async {
      await dao.insert(createBookmark(type: BookmarkType.image));

      final all = await dao.getAll();
      expect(all[0].type, BookmarkType.image);
    });
  });
}
