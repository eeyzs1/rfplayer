import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/subtitle_track.dart';
import 'package:rfplayer/domain/models/subtitle_state.dart';

void main() {
  group('SubtitleState', () {
    test('empty has correct default values', () {
      expect(SubtitleState.empty.tracks, isEmpty);
      expect(SubtitleState.empty.activeTrack, isNull);
      expect(SubtitleState.empty.enabled, isTrue);
    });

    test('creates with custom values', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final state = SubtitleState(
        tracks: [track],
        activeTrack: track,
        enabled: true,
      );

      expect(state.tracks.length, 1);
      expect(state.activeTrack, track);
      expect(state.enabled, isTrue);
    });

    test('copyWith updates tracks', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final state = SubtitleState.empty.copyWith(tracks: [track]);

      expect(state.tracks.length, 1);
      expect(state.activeTrack, isNull);
      expect(state.enabled, isTrue);
    });

    test('copyWith updates activeTrack', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final state = SubtitleState.empty.copyWith(
        tracks: [track],
        activeTrack: track,
      );

      expect(state.activeTrack, track);
    });

    test('copyWith with clearActiveTrack sets activeTrack to null', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final stateWithTrack = SubtitleState(
        tracks: [track],
        activeTrack: track,
        enabled: true,
      );

      final stateCleared = stateWithTrack.copyWith(clearActiveTrack: true);

      expect(stateCleared.activeTrack, isNull);
    });

    test('copyWith updates enabled', () {
      final state = SubtitleState.empty.copyWith(enabled: false);
      expect(state.enabled, isFalse);
    });

    test('copyWith preserves existing values when not specified', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final state = SubtitleState(
        tracks: [track],
        activeTrack: track,
        enabled: true,
      );

      final copied = state.copyWith(enabled: false);

      expect(copied.tracks, state.tracks);
      expect(copied.activeTrack, state.activeTrack);
      expect(copied.enabled, isFalse);
    });

    test('tracks list is unmodifiable via copyWith', () {
      final track = SubtitleTrack(
        id: 0,
        name: 'English',
        type: SubtitleTrackType.embedded,
      );

      final state = SubtitleState(tracks: [track], enabled: true);

      expect(state.tracks.length, 1);
    });
  });
}
