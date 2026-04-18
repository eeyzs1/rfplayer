import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/core/extensions/duration_extensions.dart';

void main() {
  group('DurationExtensions.toHHMMSS', () {
    test('formats duration with hours', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 45);
      expect(duration.toHHMMSS(), '01:30:45');
    });

    test('formats duration without hours', () {
      final duration = Duration(minutes: 5, seconds: 30);
      expect(duration.toHHMMSS(), '05:30');
    });

    test('formats zero duration', () {
      expect(Duration.zero.toHHMMSS(), '00:00');
    });

    test('pads single digit minutes and seconds', () {
      final duration = Duration(minutes: 3, seconds: 7);
      expect(duration.toHHMMSS(), '03:07');
    });
  });

  group('DurationExtensions.toProgressString', () {
    test('formats progress string', () {
      final current = Duration(minutes: 1, seconds: 30);
      final total = Duration(minutes: 5, seconds: 0);
      expect(current.toProgressString(total), '01:30 / 05:00');
    });

    test('formats progress with hours', () {
      final current = Duration(hours: 0, minutes: 30, seconds: 0);
      final total = Duration(hours: 1, minutes: 30, seconds: 0);
      expect(current.toProgressString(total), '30:00 / 01:30:00');
    });
  });
}
