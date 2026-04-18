import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/play_history.dart';

void main() {
  group('PlayHistory', () {
    PlayHistory createHistory({
      Duration? lastPosition,
      Duration? totalDuration,
      int playCount = 1,
    }) {
      return PlayHistory(
        id: 'test-id',
        path: '/test/video.mp4',
        displayName: 'video.mp4',
        extension: 'mp4',
        type: MediaType.video,
        lastPosition: lastPosition,
        totalDuration: totalDuration,
        lastPlayedAt: DateTime(2024, 1, 1),
        playCount: playCount,
      );
    }

    group('progress', () {
      test('returns 0.0 when lastPosition is null', () {
        final history = createHistory(lastPosition: null, totalDuration: Duration.zero);
        expect(history.progress, 0.0);
      });

      test('returns 0.0 when totalDuration is null', () {
        final history = createHistory(lastPosition: Duration.zero, totalDuration: null);
        expect(history.progress, 0.0);
      });

      test('returns 0.0 when totalDuration is zero', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: 10),
          totalDuration: Duration.zero,
        );
        expect(history.progress, 0.0);
      });

      test('calculates progress correctly', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: 30),
          totalDuration: const Duration(minutes: 1),
        );
        expect(history.progress, 0.5);
      });

      test('clamps progress to 1.0', () {
        final history = createHistory(
          lastPosition: const Duration(minutes: 2),
          totalDuration: const Duration(minutes: 1),
        );
        expect(history.progress, 1.0);
      });

      test('clamps progress to 0.0 for negative', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: -5),
          totalDuration: const Duration(minutes: 1),
        );
        expect(history.progress, 0.0);
      });
    });

    group('isCompleted', () {
      test('returns true when progress > 0.95', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: 96),
          totalDuration: const Duration(seconds: 100),
        );
        expect(history.isCompleted, isTrue);
      });

      test('returns false when progress <= 0.95', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: 95),
          totalDuration: const Duration(seconds: 100),
        );
        expect(history.isCompleted, isFalse);
      });

      test('returns false when progress is 0', () {
        final history = createHistory(
          lastPosition: null,
          totalDuration: null,
        );
        expect(history.isCompleted, isFalse);
      });

      test('returns true at exactly 0.96', () {
        final history = createHistory(
          lastPosition: const Duration(milliseconds: 960),
          totalDuration: const Duration(seconds: 1),
        );
        expect(history.isCompleted, isTrue);
      });
    });

    group('progressString', () {
      test('returns empty string when lastPosition is null', () {
        final history = createHistory(lastPosition: null, totalDuration: null);
        expect(history.progressString, '');
      });

      test('returns empty string when totalDuration is null', () {
        final history = createHistory(lastPosition: Duration.zero, totalDuration: null);
        expect(history.progressString, '');
      });

      test('returns fallback format when totalDuration is zero', () {
        final history = createHistory(
          lastPosition: const Duration(seconds: 30),
          totalDuration: Duration.zero,
        );
        expect(history.progressString, '00:30 / --:--');
      });

      test('returns formatted progress string', () {
        final history = createHistory(
          lastPosition: const Duration(minutes: 1, seconds: 30),
          totalDuration: const Duration(minutes: 5),
        );
        expect(history.progressString, '01:30 / 05:00');
      });
    });

    group('MediaType', () {
      test('MediaType.values contains all types', () {
        expect(MediaType.values.length, 3);
        expect(MediaType.values, contains(MediaType.video));
        expect(MediaType.values, contains(MediaType.image));
        expect(MediaType.values, contains(MediaType.audio));
      });
    });
  });
}
