import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_section_entity.freezed.dart';
part 'profile_section_entity.g.dart';

enum SectionType {
  @JsonValue('VALUES') coreValues,
  @JsonValue('WORLDVIEW') worldview,
  @JsonValue('SKILLS') skills,
  @JsonValue('INTERESTS') interests,
  @JsonValue('DESIRES') desires,
  @JsonValue('BACKGROUND') background,
  @JsonValue('LIKES') likes,
  @JsonValue('DISLIKES') dislikes,
}

enum SectionVisibility {
  @JsonValue('PUBLIC') public_,
  @JsonValue('CONTACTS') contacts,
  @JsonValue('PRIVATE') private_,
}

@freezed
class SectionContent with _$SectionContent {
  const factory SectionContent({
    @Default([]) List<String> items,
    String? freeText,
  }) = _SectionContent;

  factory SectionContent.fromJson(Map<String, dynamic> json) =>
      _$SectionContentFromJson(json);
}

@freezed
class ProfileSectionEntity with _$ProfileSectionEntity {
  const factory ProfileSectionEntity({
    required String id,
    required String userId,
    required SectionType type,
    required SectionContent content,
    required SectionVisibility visibility,
    required DateTime updatedAt,
  }) = _ProfileSectionEntity;

  factory ProfileSectionEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileSectionEntityFromJson(json);
}
