// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImageBookmarkImpl _$$ImageBookmarkImplFromJson(Map<String, dynamic> json) =>
    _$ImageBookmarkImpl(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      imageName: json['imageName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ImageBookmarkImplToJson(_$ImageBookmarkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'imageName': instance.imageName,
      'createdAt': instance.createdAt.toIso8601String(),
    };
