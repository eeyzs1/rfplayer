enum SubtitleTrackType {
  embedded, // 内置字幕轨道
  external, // 外部字幕文件
}

class SubtitleTrack {
  final int id;
  final String name;
  final String? language;
  final SubtitleTrackType type;
  final String? path; // 仅外部字幕文件使用

  SubtitleTrack({
    required this.id,
    required this.name,
    this.language,
    required this.type,
    this.path,
  });

  @override
  String toString() {
    return 'SubtitleTrack(id: $id, name: $name, language: $language, type: $type, path: $path)';
  }
}
