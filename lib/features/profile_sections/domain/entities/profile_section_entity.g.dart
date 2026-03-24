// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_section_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SectionContentImpl _$$SectionContentImplFromJson(Map<String, dynamic> json) =>
    _$SectionContentImpl(
      items:
          (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      freeText: json['freeText'] as String?,
    );

Map<String, dynamic> _$$SectionContentImplToJson(
        _$SectionContentImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'freeText': instance.freeText,
    };

_$ProfileSectionEntityImpl _$$ProfileSectionEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ProfileSectionEntityImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$SectionTypeEnumMap, json['type']),
      content: SectionContent.fromJson(json['content'] as Map<String, dynamic>),
      visibility: $enumDecode(_$SectionVisibilityEnumMap, json['visibility']),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProfileSectionEntityImplToJson(
        _$ProfileSectionEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$SectionTypeEnumMap[instance.type]!,
      'content': instance.content,
      'visibility': _$SectionVisibilityEnumMap[instance.visibility]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SectionTypeEnumMap = {
  SectionType.coreValues: 'VALUES',
  SectionType.worldview: 'WORLDVIEW',
  SectionType.skills: 'SKILLS',
  SectionType.interests: 'INTERESTS',
  SectionType.desires: 'DESIRES',
  SectionType.background: 'BACKGROUND',
  SectionType.likes: 'LIKES',
  SectionType.dislikes: 'DISLIKES',
};

const _$SectionVisibilityEnumMap = {
  SectionVisibility.public_: 'PUBLIC',
  SectionVisibility.contacts: 'CONTACTS',
  SectionVisibility.private_: 'PRIVATE',
};
