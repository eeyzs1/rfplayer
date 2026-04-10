import '../../data/models/subtitle_track.dart';

class SubtitleState {
  final List<SubtitleTrack> tracks;
  final SubtitleTrack? activeTrack;
  final bool enabled;

  const SubtitleState({
    required this.tracks,
    this.activeTrack,
    required this.enabled,
  });

  static const SubtitleState empty = SubtitleState(
    tracks: [],
    activeTrack: null,
    enabled: true,
  );

  SubtitleState copyWith({
    List<SubtitleTrack>? tracks,
    SubtitleTrack? activeTrack,
    bool? enabled,
    bool clearActiveTrack = false,
  }) {
    return SubtitleState(
      tracks: tracks ?? this.tracks,
      activeTrack: clearActiveTrack ? null : (activeTrack ?? this.activeTrack),
      enabled: enabled ?? this.enabled,
    );
  }
}
