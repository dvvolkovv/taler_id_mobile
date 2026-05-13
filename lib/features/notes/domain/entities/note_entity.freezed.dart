// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NoteEntity _$NoteEntityFromJson(Map<String, dynamic> json) {
  return _NoteEntity.fromJson(json);
}

/// @nodoc
mixin _$NoteEntity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  NoteSource get source => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get localPending => throw _privateConstructorUsedError;
  Map<String, dynamic>? get conflictedWith =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NoteEntityCopyWith<NoteEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteEntityCopyWith<$Res> {
  factory $NoteEntityCopyWith(
          NoteEntity value, $Res Function(NoteEntity) then) =
      _$NoteEntityCopyWithImpl<$Res, NoteEntity>;
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      NoteSource source,
      DateTime createdAt,
      DateTime updatedAt,
      bool localPending,
      Map<String, dynamic>? conflictedWith});
}

/// @nodoc
class _$NoteEntityCopyWithImpl<$Res, $Val extends NoteEntity>
    implements $NoteEntityCopyWith<$Res> {
  _$NoteEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? source = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? localPending = null,
    Object? conflictedWith = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as NoteSource,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
      conflictedWith: freezed == conflictedWith
          ? _value.conflictedWith
          : conflictedWith // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NoteEntityImplCopyWith<$Res>
    implements $NoteEntityCopyWith<$Res> {
  factory _$$NoteEntityImplCopyWith(
          _$NoteEntityImpl value, $Res Function(_$NoteEntityImpl) then) =
      __$$NoteEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      NoteSource source,
      DateTime createdAt,
      DateTime updatedAt,
      bool localPending,
      Map<String, dynamic>? conflictedWith});
}

/// @nodoc
class __$$NoteEntityImplCopyWithImpl<$Res>
    extends _$NoteEntityCopyWithImpl<$Res, _$NoteEntityImpl>
    implements _$$NoteEntityImplCopyWith<$Res> {
  __$$NoteEntityImplCopyWithImpl(
      _$NoteEntityImpl _value, $Res Function(_$NoteEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? source = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? localPending = null,
    Object? conflictedWith = freezed,
  }) {
    return _then(_$NoteEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as NoteSource,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      localPending: null == localPending
          ? _value.localPending
          : localPending // ignore: cast_nullable_to_non_nullable
              as bool,
      conflictedWith: freezed == conflictedWith
          ? _value._conflictedWith
          : conflictedWith // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteEntityImpl implements _NoteEntity {
  const _$NoteEntityImpl(
      {required this.id,
      required this.title,
      required this.content,
      this.source = NoteSource.manual,
      required this.createdAt,
      required this.updatedAt,
      this.localPending = false,
      final Map<String, dynamic>? conflictedWith})
      : _conflictedWith = conflictedWith;

  factory _$NoteEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  @JsonKey()
  final NoteSource source;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool localPending;
  final Map<String, dynamic>? _conflictedWith;
  @override
  Map<String, dynamic>? get conflictedWith {
    final value = _conflictedWith;
    if (value == null) return null;
    if (_conflictedWith is EqualUnmodifiableMapView) return _conflictedWith;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'NoteEntity(id: $id, title: $title, content: $content, source: $source, createdAt: $createdAt, updatedAt: $updatedAt, localPending: $localPending, conflictedWith: $conflictedWith)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.localPending, localPending) ||
                other.localPending == localPending) &&
            const DeepCollectionEquality()
                .equals(other._conflictedWith, _conflictedWith));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      content,
      source,
      createdAt,
      updatedAt,
      localPending,
      const DeepCollectionEquality().hash(_conflictedWith));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteEntityImplCopyWith<_$NoteEntityImpl> get copyWith =>
      __$$NoteEntityImplCopyWithImpl<_$NoteEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteEntityImplToJson(
      this,
    );
  }
}

abstract class _NoteEntity implements NoteEntity {
  const factory _NoteEntity(
      {required final String id,
      required final String title,
      required final String content,
      final NoteSource source,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool localPending,
      final Map<String, dynamic>? conflictedWith}) = _$NoteEntityImpl;

  factory _NoteEntity.fromJson(Map<String, dynamic> json) =
      _$NoteEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  NoteSource get source;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get localPending;
  @override
  Map<String, dynamic>? get conflictedWith;
  @override
  @JsonKey(ignore: true)
  _$$NoteEntityImplCopyWith<_$NoteEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
