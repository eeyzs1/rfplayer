import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/database/daos/image_bookmark_dao.dart';
import 'package:rfplayer/data/models/image_bookmark.dart';

void main() {
  late AppDatabase db;
  late ImageBookmarkDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dao = db.imageBookmarkDao;
  });

  tearDown(() async {
    await db.close();
  });

  ImageBookmark createBookmark({
    String id = 'test-id',
    String imagePath = '/test/photo.jpg',
    String imageName = 'photo.jpg',
  }) {
    return ImageBookmark(
      id: id,
      imagePath: imagePath,
      imageName: imageName,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  group('ImageBookmarkDao', () {
    test('insert and getAll', () async {
      final bookmark = createBookmark();
      await dao.insert(bookmark);

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].imagePath, '/test/photo.jpg');
      expect(all[0].imageName, 'photo.jpg');
    });

    test('getByImagePath returns bookmark for specific image', () async {
      await dao.insert(createBookmark(id: 'id-1', imagePath: '/photo1.jpg', imageName: 'photo1.jpg'));
      await dao.insert(createBookmark(id: 'id-2', imagePath: '/photo2.jpg', imageName: 'photo2.jpg'));

      final result = await dao.getByImagePath('/photo1.jpg');
      expect(result, isNotNull);
      expect(result!.imagePath, '/photo1.jpg');
    });

    test('getByImagePath returns null for non-existent path', () async {
      final result = await dao.getByImagePath('/nonexistent.jpg');
      expect(result, isNull);
    });

    test('deleteById removes bookmark', () async {
      await dao.insert(createBookmark(id: 'to-delete'));
      await dao.deleteById('to-delete');

      final all = await dao.getAll();
      expect(all, isEmpty);
    });

    test('deleteByImagePath removes bookmark', () async {
      await dao.insert(createBookmark(id: 'id-1', imagePath: '/photo1.jpg', imageName: 'photo1.jpg'));
      await dao.insert(createBookmark(id: 'id-2', imagePath: '/photo2.jpg', imageName: 'photo2.jpg'));

      await dao.deleteByImagePath('/photo1.jpg');

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].imagePath, '/photo2.jpg');
    });

    test('insert multiple bookmarks for different images', () async {
      for (int i = 0; i < 5; i++) {
        await dao.insert(createBookmark(
          id: 'id-$i',
          imagePath: '/photo$i.jpg',
          imageName: 'photo$i.jpg',
        ));
      }

      final all = await dao.getAll();
      expect(all.length, 5);
    });
  });
}
