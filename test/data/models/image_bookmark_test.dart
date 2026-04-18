import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/image_bookmark.dart';

void main() {
  group('ImageBookmark', () {
    final now = DateTime(2024, 6, 15, 10, 30);

    test('creates image bookmark with all properties', () {
      final bookmark = ImageBookmark(
        id: 'test-id',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      expect(bookmark.id, 'test-id');
      expect(bookmark.imagePath, '/test/photo.jpg');
      expect(bookmark.imageName, 'photo.jpg');
      expect(bookmark.createdAt, now);
    });

    test('supports copyWith', () {
      final bookmark = ImageBookmark(
        id: 'test-id',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      final copied = bookmark.copyWith(imageName: 'renamed.jpg');

      expect(copied.id, bookmark.id);
      expect(copied.imagePath, bookmark.imagePath);
      expect(copied.imageName, 'renamed.jpg');
      expect(copied.createdAt, bookmark.createdAt);
    });

    test('supports equality', () {
      final bookmark1 = ImageBookmark(
        id: 'test-id',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      final bookmark2 = ImageBookmark(
        id: 'test-id',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      expect(bookmark1, equals(bookmark2));
    });

    test('different IDs are not equal', () {
      final bookmark1 = ImageBookmark(
        id: 'id-1',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      final bookmark2 = ImageBookmark(
        id: 'id-2',
        imagePath: '/test/photo.jpg',
        imageName: 'photo.jpg',
        createdAt: now,
      );

      expect(bookmark1, isNot(equals(bookmark2)));
    });
  });
}
