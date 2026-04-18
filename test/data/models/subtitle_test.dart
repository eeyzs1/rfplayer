import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/subtitle.dart';

void main() {
  group('SubtitleItem', () {
    test('creates item with all properties', () {
      final item = SubtitleItem(
        index: 1,
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 4),
        content: 'Hello, World!',
      );

      expect(item.index, 1);
      expect(item.startTime, const Duration(seconds: 1));
      expect(item.endTime, const Duration(seconds: 4));
      expect(item.content, 'Hello, World!');
    });

    group('isActive', () {
      final item = SubtitleItem(
        index: 1,
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 4),
        content: 'Test',
      );

      test('returns true when position is within range', () {
        expect(item.isActive(const Duration(seconds: 2)), isTrue);
      });

      test('returns true when position equals startTime', () {
        expect(item.isActive(const Duration(seconds: 1)), isTrue);
      });

      test('returns true when position equals endTime', () {
        expect(item.isActive(const Duration(seconds: 4)), isTrue);
      });

      test('returns false when position is before startTime', () {
        expect(item.isActive(const Duration(milliseconds: 999)), isFalse);
      });

      test('returns false when position is after endTime', () {
        expect(item.isActive(const Duration(seconds: 5)), isFalse);
      });

      test('returns false for zero position when start is non-zero', () {
        expect(item.isActive(Duration.zero), isFalse);
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final item = SubtitleItem(
          index: 1,
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 4),
          content: 'Test',
        );

        final str = item.toString();
        expect(str, contains('SubtitleItem'));
        expect(str, contains('1'));
        expect(str, contains('Test'));
      });
    });
  });
}
