import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_bookmark.freezed.dart';
part 'video_bookmark.g.dart';

enum BookmarkType { video, image }

@freezed
class VideoBookmark with _$VideoBookmark {
  const factory VideoBookmark({
    required String id,
    required String videoPath,
    required String videoName,
    required Duration position,
    String? note,
    required DateTime createdAt,
    @Default(BookmarkType.video) BookmarkType type,
  }) = _VideoBookmark;

  factory VideoBookmark.fromJson(Map<String, dynamic> json) =>
      _$VideoBookmarkFromJson(json);
}