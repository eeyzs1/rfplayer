// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoBookmarkImpl _$$VideoBookmarkImplFromJson(Map<String, dynamic> json) =>
    _$VideoBookmarkImpl(
      id: json['id'] as String,
      videoPath: json['videoPath'] as String,
      videoName: json['videoName'] as String,
      position: Duration(microseconds: (json['position'] as num).toInt()),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type:
          $enumDecodeNullable(_$BookmarkTypeEnumMap, json['type']) ??
          BookmarkType.video,
    );

Map<String, dynamic> _$$VideoBookmarkImplToJson(_$VideoBookmarkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'videoPath': instance.videoPath,
      'videoName': instance.videoName,
      'position': instance.position.inMicroseconds,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': _$BookmarkTypeEnumMap[instance.type]!,
    };

const _$BookmarkTypeEnumMap = {
  BookmarkType.video: 'video',
  BookmarkType.image: 'image',
};
