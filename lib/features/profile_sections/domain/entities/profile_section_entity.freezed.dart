// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_section_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SectionContent _$SectionContentFromJson(Map<String, dynamic> json) {
  return _SectionContent.fromJson(json);
}

/// @nodoc
mixin _$SectionContent {
  List<String> get items => throw _privateConstructorUsedError;
  String? get freeText => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SectionContentCopyWith<SectionContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SectionContentCopyWith<$Res> {
  factory $SectionContentCopyWith(
          SectionContent value, $Res Function(SectionContent) then) =
      _$SectionContentCopyWithImpl<$Res, SectionContent>;
  @useResult
  $Res call({List<String> items, String? freeText});
}

/// @nodoc
class _$SectionContentCopyWithImpl<$Res, $Val extends SectionContent>
    implements $SectionContentCopyWith<$Res> {
  _$SectionContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? freeText = freezed,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<String>,
      freeText: freezed == freeText
          ? _value.freeText
          : freeText // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SectionContentImplCopyWith<$Res>
    implements $SectionContentCopyWith<$Res> {
  factory _$$SectionContentImplCopyWith(_$SectionContentImpl value,
          $Res Function(_$SectionContentImpl) then) =
      __$$SectionContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> items, String? freeText});
}

/// @nodoc
class __$$SectionContentImplCopyWithImpl<$Res>
    extends _$SectionContentCopyWithImpl<$Res, _$SectionContentImpl>
    implements _$$SectionContentImplCopyWith<$Res> {
  __$$SectionContentImplCopyWithImpl(
      _$SectionContentImpl _value, $Res Function(_$SectionContentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? freeText = freezed,
  }) {
    return _then(_$SectionContentImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<String>,
      freeText: freezed == freeText
          ? _value.freeText
          : freeText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SectionContentImpl implements _SectionContent {
  const _$SectionContentImpl(
      {final List<String> items = const [], this.freeText})
      : _items = items;

  factory _$SectionContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SectionContentImplFromJson(json);

  final List<String> _items;
  @override
  @JsonKey()
  List<String> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? freeText;

  @override
  String toString() {
    return 'SectionContent(items: $items, freeText: $freeText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SectionContentImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.freeText, freeText) ||
                other.freeText == freeText));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), freeText);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SectionContentImplCopyWith<_$SectionContentImpl> get copyWith =>
      __$$SectionContentImplCopyWithImpl<_$SectionContentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SectionContentImplToJson(
      this,
    );
  }
}

abstract class _SectionContent implements SectionContent {
  const factory _SectionContent(
      {final List<String> items,
      final String? freeText}) = _$SectionContentImpl;

  factory _SectionContent.fromJson(Map<String, dynamic> json) =
      _$SectionContentImpl.fromJson;

  @override
  List<String> get items;
  @override
  String? get freeText;
  @override
  @JsonKey(ignore: true)
  _$$SectionContentImplCopyWith<_$SectionContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProfileSectionEntity _$ProfileSectionEntityFromJson(Map<String, dynamic> json) {
  return _ProfileSectionEntity.fromJson(json);
}

/// @nodoc
mixin _$ProfileSectionEntity {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  SectionType get type => throw _privateConstructorUsedError;
  SectionContent get content => throw _privateConstructorUsedError;
  SectionVisibility get visibility => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProfileSectionEntityCopyWith<ProfileSectionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileSectionEntityCopyWith<$Res> {
  factory $ProfileSectionEntityCopyWith(ProfileSectionEntity value,
          $Res Function(ProfileSectionEntity) then) =
      _$ProfileSectionEntityCopyWithImpl<$Res, ProfileSectionEntity>;
  @useResult
  $Res call(
      {String id,
      String userId,
      SectionType type,
      SectionContent content,
      SectionVisibility visibility,
      DateTime updatedAt});

  $SectionContentCopyWith<$Res> get content;
}

/// @nodoc
class _$ProfileSectionEntityCopyWithImpl<$Res,
        $Val extends ProfileSectionEntity>
    implements $ProfileSectionEntityCopyWith<$Res> {
  _$ProfileSectionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? content = null,
    Object? visibility = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SectionType,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as SectionContent,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as SectionVisibility,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SectionContentCopyWith<$Res> get content {
    return $SectionContentCopyWith<$Res>(_value.content, (value) {
      return _then(_value.copyWith(content: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProfileSectionEntityImplCopyWith<$Res>
    implements $ProfileSectionEntityCopyWith<$Res> {
  factory _$$ProfileSectionEntityImplCopyWith(_$ProfileSectionEntityImpl value,
          $Res Function(_$ProfileSectionEntityImpl) then) =
      __$$ProfileSectionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      SectionType type,
      SectionContent content,
      SectionVisibility visibility,
      DateTime updatedAt});

  @override
  $SectionContentCopyWith<$Res> get content;
}

/// @nodoc
class __$$ProfileSectionEntityImplCopyWithImpl<$Res>
    extends _$ProfileSectionEntityCopyWithImpl<$Res, _$ProfileSectionEntityImpl>
    implements _$$ProfileSectionEntityImplCopyWith<$Res> {
  __$$ProfileSectionEntityImplCopyWithImpl(_$ProfileSectionEntityImpl _value,
      $Res Function(_$ProfileSectionEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? content = null,
    Object? visibility = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProfileSectionEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SectionType,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as SectionContent,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as SectionVisibility,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileSectionEntityImpl implements _ProfileSectionEntity {
  const _$ProfileSectionEntityImpl(
      {required this.id,
      required this.userId,
      required this.type,
      required this.content,
      required this.visibility,
      required this.updatedAt});

  factory _$ProfileSectionEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileSectionEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final SectionType type;
  @override
  final SectionContent content;
  @override
  final SectionVisibility visibility;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ProfileSectionEntity(id: $id, userId: $userId, type: $type, content: $content, visibility: $visibility, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileSectionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, userId, type, content, visibility, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileSectionEntityImplCopyWith<_$ProfileSectionEntityImpl>
      get copyWith =>
          __$$ProfileSectionEntityImplCopyWithImpl<_$ProfileSectionEntityImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileSectionEntityImplToJson(
      this,
    );
  }
}

abstract class _ProfileSectionEntity implements ProfileSectionEntity {
  const factory _ProfileSectionEntity(
      {required final String id,
      required final String userId,
      required final SectionType type,
      required final SectionContent content,
      required final SectionVisibility visibility,
      required final DateTime updatedAt}) = _$ProfileSectionEntityImpl;

  factory _ProfileSectionEntity.fromJson(Map<String, dynamic> json) =
      _$ProfileSectionEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  SectionType get type;
  @override
  SectionContent get content;
  @override
  SectionVisibility get visibility;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ProfileSectionEntityImplCopyWith<_$ProfileSectionEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}
