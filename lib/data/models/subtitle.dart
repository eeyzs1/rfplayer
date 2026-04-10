class SubtitleItem {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String content;

  SubtitleItem({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.content,
  });

  bool isActive(Duration position) {
    return position >= startTime && position <= endTime;
  }

  @override
  String toString() {
    return 'SubtitleItem(index: $index, startTime: $startTime, endTime: $endTime, content: $content)';
  }
}
