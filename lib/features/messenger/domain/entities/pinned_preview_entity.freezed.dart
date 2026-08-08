// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pinned_preview_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PinnedPreviewEntity _$PinnedPreviewEntityFromJson(Map<String, dynamic> json) {
  return _PinnedPreviewEntity.fromJson(json);
}

/// @nodoc
mixin _$PinnedPreviewEntity {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  DateTime? get sentAt => throw _privateConstructorUsedError;
  DateTime? get pinnedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PinnedPreviewEntityCopyWith<PinnedPreviewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinnedPreviewEntityCopyWith<$Res> {
  factory $PinnedPreviewEntityCopyWith(
          PinnedPreviewEntity value, $Res Function(PinnedPreviewEntity) then) =
      _$PinnedPreviewEntityCopyWithImpl<$Res, PinnedPreviewEntity>;
  @useResult
  $Res call(
      {String id,
      String content,
      String? senderName,
      DateTime? sentAt,
      DateTime? pinnedAt});
}

/// @nodoc
class _$PinnedPreviewEntityCopyWithImpl<$Res, $Val extends PinnedPreviewEntity>
    implements $PinnedPreviewEntityCopyWith<$Res> {
  _$PinnedPreviewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? senderName = freezed,
    Object? sentAt = freezed,
    Object? pinnedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      sentAt: freezed == sentAt
          ? _value.sentAt
          : sentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pinnedAt: freezed == pinnedAt
          ? _value.pinnedAt
          : pinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PinnedPreviewEntityImplCopyWith<$Res>
    implements $PinnedPreviewEntityCopyWith<$Res> {
  factory _$$PinnedPreviewEntityImplCopyWith(_$PinnedPreviewEntityImpl value,
          $Res Function(_$PinnedPreviewEntityImpl) then) =
      __$$PinnedPreviewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String content,
      String? senderName,
      DateTime? sentAt,
      DateTime? pinnedAt});
}

/// @nodoc
class __$$PinnedPreviewEntityImplCopyWithImpl<$Res>
    extends _$PinnedPreviewEntityCopyWithImpl<$Res, _$PinnedPreviewEntityImpl>
    implements _$$PinnedPreviewEntityImplCopyWith<$Res> {
  __$$PinnedPreviewEntityImplCopyWithImpl(_$PinnedPreviewEntityImpl _value,
      $Res Function(_$PinnedPreviewEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? senderName = freezed,
    Object? sentAt = freezed,
    Object? pinnedAt = freezed,
  }) {
    return _then(_$PinnedPreviewEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      sentAt: freezed == sentAt
          ? _value.sentAt
          : sentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pinnedAt: freezed == pinnedAt
          ? _value.pinnedAt
          : pinnedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PinnedPreviewEntityImpl implements _PinnedPreviewEntity {
  const _$PinnedPreviewEntityImpl(
      {required this.id,
      this.content = '',
      this.senderName,
      this.sentAt,
      this.pinnedAt});

  factory _$PinnedPreviewEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PinnedPreviewEntityImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String content;
  @override
  final String? senderName;
  @override
  final DateTime? sentAt;
  @override
  final DateTime? pinnedAt;

  @override
  String toString() {
    return 'PinnedPreviewEntity(id: $id, content: $content, senderName: $senderName, sentAt: $sentAt, pinnedAt: $pinnedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PinnedPreviewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.pinnedAt, pinnedAt) ||
                other.pinnedAt == pinnedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, content, senderName, sentAt, pinnedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PinnedPreviewEntityImplCopyWith<_$PinnedPreviewEntityImpl> get copyWith =>
      __$$PinnedPreviewEntityImplCopyWithImpl<_$PinnedPreviewEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PinnedPreviewEntityImplToJson(
      this,
    );
  }
}

abstract class _PinnedPreviewEntity implements PinnedPreviewEntity {
  const factory _PinnedPreviewEntity(
      {required final String id,
      final String content,
      final String? senderName,
      final DateTime? sentAt,
      final DateTime? pinnedAt}) = _$PinnedPreviewEntityImpl;

  factory _PinnedPreviewEntity.fromJson(Map<String, dynamic> json) =
      _$PinnedPreviewEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  String? get senderName;
  @override
  DateTime? get sentAt;
  @override
  DateTime? get pinnedAt;
  @override
  @JsonKey(ignore: true)
  _$$PinnedPreviewEntityImplCopyWith<_$PinnedPreviewEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
