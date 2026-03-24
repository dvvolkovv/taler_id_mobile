import '../../domain/entities/profile_section_entity.dart';
import '../../domain/repositories/i_profile_sections_repository.dart';
import '../datasources/profile_sections_remote_datasource.dart';

class ProfileSectionsRepositoryImpl implements IProfileSectionsRepository {
  final ProfileSectionsRemoteDataSource _remote;
  ProfileSectionsRepositoryImpl(this._remote);

  @override
  Future<List<ProfileSectionEntity>> getMySections() => _remote.getMySections();

  @override
  Future<ProfileSectionEntity> upsertSection(
    SectionType type,
    SectionContent content,
    SectionVisibility visibility,
  ) => _remote.upsertSection(type: type, content: content, visibility: visibility);

  @override
  Future<void> deleteSection(SectionType type) => _remote.deleteSection(type);

  @override
  Future<void> updateVisibility(SectionType type, SectionVisibility visibility) =>
      _remote.updateVisibility(type, visibility);

  @override
  Future<List<ProfileSectionEntity>> getUserSections(String userId) =>
      _remote.getUserSections(userId);
}
