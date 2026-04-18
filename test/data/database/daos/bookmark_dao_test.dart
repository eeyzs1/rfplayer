import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/database/daos/bookmark_dao.dart';
import 'package:rfplayer/data/models/bookmark.dart';

void main() {
  late AppDatabase db;
  late BookmarkDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dao = db.bookmarkDao;
  });

  tearDown(() async {
    await db.close();
  });

  Bookmark createBookmark({
    String id = 'test-id',
    String path = '/test/folder',
    String displayName = 'Test Folder',
    int sortOrder = 0,
  }) {
    return Bookmark(
      id: id,
      path: path,
      displayName: displayName,
      createdAt: DateTime(2024, 1, 1),
      sortOrder: sortOrder,
    );
  }

  group('BookmarkDao', () {
    test('insert and getAll', () async {
      final bookmark = createBookmark();
      await dao.insert(bookmark);

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].path, '/test/folder');
      expect(all[0].displayName, 'Test Folder');
    });

    test('insert deduplicates by path', () async {
      await dao.insert(createBookmark(id: 'id-1'));
      await dao.insert(createBookmark(id: 'id-2'));

      final all = await dao.getAll();
      expect(all.length, 1);
    });

    test('getAll returns items ordered by sortOrder', () async {
      await dao.insert(createBookmark(id: 'id-1', path: '/folder1', displayName: 'Folder 1', sortOrder: 2));
      await dao.insert(createBookmark(id: 'id-2', path: '/folder2', displayName: 'Folder 2', sortOrder: 0));
      await dao.insert(createBookmark(id: 'id-3', path: '/folder3', displayName: 'Folder 3', sortOrder: 1));

      final all = await dao.getAll();
      expect(all[0].displayName, 'Folder 2');
      expect(all[1].displayName, 'Folder 3');
      expect(all[2].displayName, 'Folder 1');
    });

    test('deleteById removes bookmark', () async {
      await dao.insert(createBookmark(id: 'to-delete'));
      await dao.deleteById('to-delete');

      final all = await dao.getAll();
      expect(all, isEmpty);
    });

    test('reorder updates sort orders', () async {
      await dao.insert(createBookmark(id: 'id-1', path: '/f1', displayName: 'F1', sortOrder: 0));
      await dao.insert(createBookmark(id: 'id-2', path: '/f2', displayName: 'F2', sortOrder: 1));
      await dao.insert(createBookmark(id: 'id-3', path: '/f3', displayName: 'F3', sortOrder: 2));

      await dao.reorder(['id-3', 'id-1', 'id-2']);

      final all = await dao.getAll();
      expect(all[0].displayName, 'F3');
      expect(all[1].displayName, 'F1');
      expect(all[2].displayName, 'F2');
    });

    test('watchAll emits updates', () async {
      final stream = dao.watchAll();

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);

      await dao.insert(createBookmark());

      final secondEmission = await stream.first;
      expect(secondEmission.length, 1);
    });
  });
}
