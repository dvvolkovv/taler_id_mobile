// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteEntityImpl _$$NoteEntityImplFromJson(Map<String, dynamic> json) =>
    _$NoteEntityImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      source: $enumDecodeNullable(_$NoteSourceEnumMap, json['source']) ??
          NoteSource.manual,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      localPending: json['localPending'] as bool? ?? false,
      conflictedWith: json['conflictedWith'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$NoteEntityImplToJson(_$NoteEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'source': _$NoteSourceEnumMap[instance.source]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'localPending': instance.localPending,
      'conflictedWith': instance.conflictedWith,
    };

const _$NoteSourceEnumMap = {
  NoteSource.manual: 'MANUAL',
  NoteSource.assistant: 'ASSISTANT',
};
