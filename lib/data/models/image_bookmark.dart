import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_bookmark.freezed.dart';
part 'image_bookmark.g.dart';

@freezed
class ImageBookmark with _$ImageBookmark {
  const factory ImageBookmark({
    required String id,
    required String imagePath,
    required String imageName,
    required DateTime createdAt,
  }) = _ImageBookmark;

  factory ImageBookmark.fromJson(Map<String, dynamic> json) =>
      _$ImageBookmarkFromJson(json);
}
