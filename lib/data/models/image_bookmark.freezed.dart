// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_bookmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ImageBookmark _$ImageBookmarkFromJson(Map<String, dynamic> json) {
  return _ImageBookmark.fromJson(json);
}

/// @nodoc
mixin _$ImageBookmark {
  String get id => throw _privateConstructorUsedError;
  String get imagePath => throw _privateConstructorUsedError;
  String get imageName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ImageBookmark to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImageBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImageBookmarkCopyWith<ImageBookmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageBookmarkCopyWith<$Res> {
  factory $ImageBookmarkCopyWith(
    ImageBookmark value,
    $Res Function(ImageBookmark) then,
  ) = _$ImageBookmarkCopyWithImpl<$Res, ImageBookmark>;
  @useResult
  $Res call({
    String id,
    String imagePath,
    String imageName,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ImageBookmarkCopyWithImpl<$Res, $Val extends ImageBookmark>
    implements $ImageBookmarkCopyWith<$Res> {
  _$ImageBookmarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImageBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imagePath = null,
    Object? imageName = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            imagePath: null == imagePath
                ? _value.imagePath
                : imagePath // ignore: cast_nullable_to_non_nullable
                      as String,
            imageName: null == imageName
                ? _value.imageName
                : imageName // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ImageBookmarkImplCopyWith<$Res>
    implements $ImageBookmarkCopyWith<$Res> {
  factory _$$ImageBookmarkImplCopyWith(
    _$ImageBookmarkImpl value,
    $Res Function(_$ImageBookmarkImpl) then,
  ) = __$$ImageBookmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String imagePath,
    String imageName,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ImageBookmarkImplCopyWithImpl<$Res>
    extends _$ImageBookmarkCopyWithImpl<$Res, _$ImageBookmarkImpl>
    implements _$$ImageBookmarkImplCopyWith<$Res> {
  __$$ImageBookmarkImplCopyWithImpl(
    _$ImageBookmarkImpl _value,
    $Res Function(_$ImageBookmarkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ImageBookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imagePath = null,
    Object? imageName = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ImageBookmarkImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        imagePath: null == imagePath
            ? _value.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String,
        imageName: null == imageName
            ? _value.imageName
            : imageName // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageBookmarkImpl implements _ImageBookmark {
  const _$ImageBookmarkImpl({
    required this.id,
    required this.imagePath,
    required this.imageName,
    required this.createdAt,
  });

  factory _$ImageBookmarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageBookmarkImplFromJson(json);

  @override
  final String id;
  @override
  final String imagePath;
  @override
  final String imageName;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ImageBookmark(id: $id, imagePath: $imagePath, imageName: $imageName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageBookmarkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.imageName, imageName) ||
                other.imageName == imageName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, imagePath, imageName, createdAt);

  /// Create a copy of ImageBookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageBookmarkImplCopyWith<_$ImageBookmarkImpl> get copyWith =>
      __$$ImageBookmarkImplCopyWithImpl<_$ImageBookmarkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageBookmarkImplToJson(this);
  }
}

abstract class _ImageBookmark implements ImageBookmark {
  const factory _ImageBookmark({
    required final String id,
    required final String imagePath,
    required final String imageName,
    required final DateTime createdAt,
  }) = _$ImageBookmarkImpl;

  factory _ImageBookmark.fromJson(Map<String, dynamic> json) =
      _$ImageBookmarkImpl.fromJson;

  @override
  String get id;
  @override
  String get imagePath;
  @override
  String get imageName;
  @override
  DateTime get createdAt;

  /// Create a copy of ImageBookmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageBookmarkImplCopyWith<_$ImageBookmarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
