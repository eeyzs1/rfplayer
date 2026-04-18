import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/bookmark_repository.dart';
import 'package:rfplayer/data/models/bookmark.dart';

void main() {
  late AppDatabase db;
  late BookmarkRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = BookmarkRepository(db.bookmarkDao);
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

  group('BookmarkRepository', () {
    test('getAll returns empty list initially', () async {
      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('insert and getAll', () async {
      await repository.insert(createBookmark());

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all[0].path, '/test/folder');
    });

    test('insert deduplicates by path', () async {
      await repository.insert(createBookmark(id: 'id-1'));
      await repository.insert(createBookmark(id: 'id-2'));

      final all = await repository.getAll();
      expect(all.length, 1);
    });

    test('deleteById removes bookmark', () async {
      await repository.insert(createBookmark(id: 'to-delete'));
      await repository.deleteById('to-delete');

      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('reorder updates sort orders', () async {
      await repository.insert(createBookmark(id: 'id-1', path: '/f1', displayName: 'F1', sortOrder: 0));
      await repository.insert(createBookmark(id: 'id-2', path: '/f2', displayName: 'F2', sortOrder: 1));

      await repository.reorder(['id-2', 'id-1']);

      final all = await repository.getAll();
      expect(all[0].displayName, 'F2');
      expect(all[1].displayName, 'F1');
    });

    test('watchAll returns stream of bookmarks', () async {
      final stream = repository.watchAll();

      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);

      await repository.insert(createBookmark());

      final secondEmission = await stream.first;
      expect(secondEmission.length, 1);
    });
  });
}
