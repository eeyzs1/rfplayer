import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/database/app_database.dart';
import 'package:rfplayer/data/repositories/image_bookmark_repository.dart';

void main() {
  late AppDatabase db;
  late ImageBookmarkRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = ImageBookmarkRepository(db.imageBookmarkDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ImageBookmarkRepository', () {
    test('getAll returns empty list initially', () async {
      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('addBookmark and getAll', () async {
      await repository.addBookmark('/test/photo.jpg', 'photo.jpg');

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all[0].imagePath, '/test/photo.jpg');
      expect(all[0].imageName, 'photo.jpg');
    });

    test('addBookmark deduplicates by imagePath', () async {
      await repository.addBookmark('/test/photo.jpg', 'photo.jpg');
      await repository.addBookmark('/test/photo.jpg', 'photo.jpg');

      final all = await repository.getAll();
      expect(all.length, 1);
    });

    test('getByImagePath returns bookmark for specific image', () async {
      await repository.addBookmark('/photo1.jpg', 'photo1.jpg');
      await Future.delayed(const Duration(milliseconds: 10));
      await repository.addBookmark('/photo2.jpg', 'photo2.jpg');

      final result = await repository.getByImagePath('/photo1.jpg');
      expect(result, isNotNull);
      expect(result!.imagePath, '/photo1.jpg');
    });

    test('getByImagePath returns null for non-existent path', () async {
      final result = await repository.getByImagePath('/nonexistent.jpg');
      expect(result, isNull);
    });

    test('deleteBookmark removes bookmark by id', () async {
      await repository.addBookmark('/test/photo.jpg', 'photo.jpg');

      final all = await repository.getAll();
      await repository.deleteBookmark(all[0].id);

      final remaining = await repository.getAll();
      expect(remaining, isEmpty);
    });

    test('deleteByImagePath removes bookmark', () async {
      await repository.addBookmark('/photo1.jpg', 'photo1.jpg');
      await Future.delayed(const Duration(milliseconds: 10));
      await repository.addBookmark('/photo2.jpg', 'photo2.jpg');

      await repository.deleteByImagePath('/photo1.jpg');

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(all[0].imagePath, '/photo2.jpg');
    });
  });
}
