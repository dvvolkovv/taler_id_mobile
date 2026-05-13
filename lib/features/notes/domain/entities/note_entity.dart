import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_entity.freezed.dart';
part 'note_entity.g.dart';

enum NoteSource {
  @JsonValue('MANUAL') manual,
  @JsonValue('ASSISTANT') assistant,
}

enum ConflictResolution { keepMine, acceptServer }

@freezed
class NoteEntity with _$NoteEntity {
  const factory NoteEntity({
    required String id,
    required String title,
    required String content,
    @Default(NoteSource.manual) NoteSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool localPending,
    Map<String, dynamic>? conflictedWith,
  }) = _NoteEntity;

  factory NoteEntity.fromJson(Map<String, dynamic> json) => _$NoteEntityFromJson(json);
}
