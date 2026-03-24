import '../entities/profile_section_entity.dart';

abstract class IProfileSectionsRepository {
  Future<List<ProfileSectionEntity>> getMySections();
  Future<ProfileSectionEntity> upsertSection(
    SectionType type,
    SectionContent content,
    SectionVisibility visibility,
  );
  Future<void> deleteSection(SectionType type);
  Future<void> updateVisibility(SectionType type, SectionVisibility visibility);
  Future<List<ProfileSectionEntity>> getUserSections(String userId);
}
