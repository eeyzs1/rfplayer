// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_bookmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VideoBookmark _$VideoBookmarkFromJson(Map<String, dynamic> json) {
  return _VideoBookmark.fromJson(json);
}

/// @nodoc
mixin _$VideoBookmark {
  String get id => throw _privateConstructorUsedError;
  String get videoPath => throw _privateConstructorUsedError;
  String get videoName => throw _privateConstructorUsedError;
  Duration get position => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  BookmarkType get type => throw _privateConstructorUsedError;

  /// Serializes this VideoBookmark to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoBookmarkCopyWith<VideoBookmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoBookmarkCopyWith<$Res> {
  factory $VideoBookmarkCopyWith(
    VideoBookmark value,
    $Res Function(VideoBookmark) then,
  ) = _$VideoBookmarkCopyWithImpl<$Res, VideoBookmark>;
  @useResult
  $Res call({
    String id,
    String videoPath,
    String videoName,
    Duration position,
    String? note,
    DateTime createdAt,
    BookmarkType type,
  });
}

/// @nodoc
class _$VideoBookmarkCopyWithImpl<$Res, $Val extends VideoBookmark>
    implements $VideoBookmarkCopyWith<$Res> {
  _$VideoBookmarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoPath = null,
    Object? videoName = null,
    Object? position = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            videoPath: null == videoPath
                ? _value.videoPath
                : videoPath // ignore: cast_nullable_to_non_nullable
                      as String,
            videoName: null == videoName
                ? _value.videoName
                : videoName // ignore: cast_nullable_to_non_nullable
                      as String,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Duration,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as BookmarkType,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VideoBookmarkImplCopyWith<$Res>
    implements $VideoBookmarkCopyWith<$Res> {
  factory _$$VideoBookmarkImplCopyWith(
    _$VideoBookmarkImpl value,
    $Res Function(_$VideoBookmarkImpl) then,
  ) = __$$VideoBookmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String videoPath,
    String videoName,
    Duration position,
    String? note,
    DateTime createdAt,
    BookmarkType type,
  });
}

/// @nodoc
class __$$VideoBookmarkImplCopyWithImpl<$Res>
    extends _$VideoBookmarkCopyWithImpl<$Res, _$VideoBookmarkImpl>
    implements _$$VideoBookmarkImplCopyWith<$Res> {
  __$$VideoBookmarkImplCopyWithImpl(
    _$VideoBookmarkImpl _value,
    $Res Function(_$VideoBookmarkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VideoBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoPath = null,
    Object? videoName = null,
    Object? position = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? type = null,
  }) {
    return _then(
      _$VideoBookmarkImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        videoPath: null == videoPath
            ? _value.videoPath
            : videoPath // ignore: cast_nullable_to_non_nullable
                  as String,
        videoName: null == videoName
            ? _value.videoName
            : videoName // ignore: cast_nullable_to_non_nullable
                  as String,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as BookmarkType,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoBookmarkImpl implements _VideoBookmark {
  const _$VideoBookmarkImpl({
    required this.id,
    required this.videoPath,
    required this.videoName,
    required this.position,
    this.note,
    required this.createdAt,
    this.type = BookmarkType.video,
  });

  factory _$VideoBookmarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoBookmarkImplFromJson(json);

  @override
  final String id;
  @override
  final String videoPath;
  @override
  final String videoName;
  @override
  final Duration position;
  @override
  final String? note;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final BookmarkType type;

  @override
  String toString() {
    return 'VideoBookmark(id: $id, videoPath: $videoPath, videoName: $videoName, position: $position, note: $note, createdAt: $createdAt, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoBookmarkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.videoPath, videoPath) ||
                other.videoPath == videoPath) &&
            (identical(other.videoName, videoName) ||
                other.videoName == videoName) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    videoPath,
    videoName,
    position,
    note,
    createdAt,
    type,
  );

  /// Create a copy of VideoBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoBookmarkImplCopyWith<_$VideoBookmarkImpl> get copyWith =>
      __$$VideoBookmarkImplCopyWithImpl<_$VideoBookmarkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoBookmarkImplToJson(this);
  }
}

abstract class _VideoBookmark implements VideoBookmark {
  const factory _VideoBookmark({
    required final String id,
    required final String videoPath,
    required final String videoName,
    required final Duration position,
    final String? note,
    required final DateTime createdAt,
    final BookmarkType type,
  }) = _$VideoBookmarkImpl;

  factory _VideoBookmark.fromJson(Map<String, dynamic> json) =
      _$VideoBookmarkImpl.fromJson;

  @override
  String get id;
  @override
  String get videoPath;
  @override
  String get videoName;
  @override
  Duration get position;
  @override
  String? get note;
  @override
  DateTime get createdAt;
  @override
  BookmarkType get type;

  /// Create a copy of VideoBookmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoBookmarkImplCopyWith<_$VideoBookmarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
