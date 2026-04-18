import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/bookmark.dart';

void main() {
  group('Bookmark', () {
    test('creates bookmark with all properties', () {
      final now = DateTime(2024, 1, 15);
      final bookmark = Bookmark(
        id: 'test-id',
        path: '/test/folder',
        displayName: 'My Folder',
        createdAt: now,
        sortOrder: 0,
      );

      expect(bookmark.id, 'test-id');
      expect(bookmark.path, '/test/folder');
      expect(bookmark.displayName, 'My Folder');
      expect(bookmark.createdAt, now);
      expect(bookmark.sortOrder, 0);
    });

    group('fromDb', () {
      test('creates bookmark from database row', () {
        final row = _MockDbRow(
          id: 'db-id',
          path: '/db/folder',
          displayName: 'DB Folder',
          createdAt: 1705276800000,
          sortOrder: 2,
        );

        final bookmark = Bookmark.fromDb(row);

        expect(bookmark.id, 'db-id');
        expect(bookmark.path, '/db/folder');
        expect(bookmark.displayName, 'DB Folder');
        expect(bookmark.createdAt, DateTime.fromMillisecondsSinceEpoch(1705276800000));
        expect(bookmark.sortOrder, 2);
      });
    });
  });
}

class _MockDbRow {
  final String id;
  final String path;
  final String displayName;
  final int createdAt;
  final int sortOrder;

  _MockDbRow({
    required this.id,
    required this.path,
    required this.displayName,
    required this.createdAt,
    required this.sortOrder,
  });
}
