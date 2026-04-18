import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/core/utils/format_utils.dart';

void main() {
  group('FormatUtils.formatDuration', () {
    test('formats duration with hours', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 45);
      expect(FormatUtils.formatDuration(duration), '01:30:45');
    });

    test('formats duration without hours', () {
      final duration = Duration(minutes: 5, seconds: 30);
      expect(FormatUtils.formatDuration(duration), '05:30');
    });

    test('formats zero duration', () {
      expect(FormatUtils.formatDuration(Duration.zero), '00:00');
    });

    test('formats duration with only seconds', () {
      expect(FormatUtils.formatDuration(const Duration(seconds: 45)), '00:45');
    });

    test('pads single digit values', () {
      final duration = Duration(hours: 0, minutes: 3, seconds: 7);
      expect(FormatUtils.formatDuration(duration), '03:07');
    });

    test('formats large hour values', () {
      final duration = Duration(hours: 12, minutes: 0, seconds: 0);
      expect(FormatUtils.formatDuration(duration), '12:00:00');
    });
  });

  group('FormatUtils.formatFileSize', () {
    test('formats zero bytes', () {
      expect(FormatUtils.formatFileSize(0), '0 B');
    });

    test('formats negative bytes', () {
      expect(FormatUtils.formatFileSize(-1), '0 B');
    });

    test('formats bytes', () {
      expect(FormatUtils.formatFileSize(500), '500 B');
    });

    test('formats kilobytes', () {
      expect(FormatUtils.formatFileSize(1024), '1.00 KB');
    });

    test('formats megabytes', () {
      expect(FormatUtils.formatFileSize(1048576), '1.00 MB');
    });

    test('formats gigabytes', () {
      expect(FormatUtils.formatFileSize(1073741824), '1.00 GB');
    });

    test('formats terabytes', () {
      expect(FormatUtils.formatFileSize(1099511627776), '1.00 TB');
    });

    test('formats large KB with one decimal', () {
      expect(FormatUtils.formatFileSize(15360), '15.0 KB');
    });

    test('formats large MB with no decimal', () {
      expect(FormatUtils.formatFileSize(104857600), '100 MB');
    });

    test('formats 1.5 MB', () {
      expect(FormatUtils.formatFileSize(1572864), '1.50 MB');
    });
  });

  group('FormatUtils.formatDateTime', () {
    test('formats today time as HH:MM', () {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, 14, 30);
      final result = FormatUtils.formatDateTime(dateTime);
      expect(result, '14:30');
    });

    test('formats yesterday as HH:MM', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = FormatUtils.formatDateTime(yesterday);
      expect(result, contains(':'));
    });

    test('formats date within a week with days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final result = FormatUtils.formatDateTime(threeDaysAgo);
      expect(result, contains('d ago'));
    });

    test('formats older dates with month/day', () {
      final older = DateTime.now().subtract(const Duration(days: 30));
      final result = FormatUtils.formatDateTime(older);
      expect(result, contains('/'));
    });
  });
}
