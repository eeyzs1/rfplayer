enum SubtitleTrackType {
  embedded,
  external,
}

class SubtitleTrack {
  final int id;
  final String name;
  final String? language;
  final SubtitleTrackType type;
  final String? path;
  final int? streamIndex;

  SubtitleTrack({
    required this.id,
    required this.name,
    this.language,
    required this.type,
    this.path,
    this.streamIndex,
  });

  @override
  String toString() {
    return 'SubtitleTrack(id: $id, name: $name, language: $language, type: $type, streamIndex: $streamIndex)';
  }
}
