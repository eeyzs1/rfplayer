import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/subtitle_track.dart';

void main() {
  group('SubtitleTrack', () {
    test('creates embedded track', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        language: 'en',
        type: SubtitleTrackType.embedded,
        streamIndex: 0,
      );

      expect(track.id, 0);
      expect(track.name, 'English');
      expect(track.language, 'en');
      expect(track.type, SubtitleTrackType.embedded);
      expect(track.path, isNull);
      expect(track.streamIndex, 0);
    });

    test('creates external track', () {
      final track = SubtitleTrack(
        id: 1000,
        name: 'External [SRT]',
        type: SubtitleTrackType.external,
        path: '/path/to/subtitle.srt',
      );

      expect(track.id, 1000);
      expect(track.name, 'External [SRT]');
      expect(track.language, isNull);
      expect(track.type, SubtitleTrackType.external);
      expect(track.path, '/path/to/subtitle.srt');
      expect(track.streamIndex, isNull);
    });

    test('SubtitleTrackType has all values', () {
      expect(SubtitleTrackType.values.length, 2);
      expect(SubtitleTrackType.values, contains(SubtitleTrackType.embedded));
      expect(SubtitleTrackType.values, contains(SubtitleTrackType.external));
    });

    test('toString returns readable representation', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final str = track.toString();
      expect(str, contains('SubtitleTrack'));
      expect(str, contains('English'));
      expect(str, contains('embedded'));
    });
  });
}
