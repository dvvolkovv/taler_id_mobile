import '../../../../core/api/dio_client.dart';
import '../../domain/entities/profile_section_entity.dart';

class ProfileSectionsRemoteDataSource {
  final DioClient _client;
  ProfileSectionsRemoteDataSource(this._client);

  Future<List<ProfileSectionEntity>> getMySections() async {
    final result = await _client.get<List<dynamic>>(
      '/profile-sections',
      fromJson: (d) => d as List<dynamic>,
    );
    return result
        .map((e) => ProfileSectionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProfileSectionEntity> upsertSection({
    required SectionType type,
    required SectionContent content,
    required SectionVisibility visibility,
  }) async {
    final result = await _client.put<Map<String, dynamic>>(
      '/profile-sections',
      data: {
        'type': _sectionTypeToString(type),
        'content': content.toJson(),
        'visibility': _visibilityToString(visibility),
      },
      fromJson: (d) => d as Map<String, dynamic>,
    );
    return ProfileSectionEntity.fromJson(result);
  }

  Future<void> deleteSection(SectionType type) async {
    await _client.delete('/profile-sections/${_sectionTypeToString(type)}');
  }

  Future<void> updateVisibility(
    SectionType type,
    SectionVisibility visibility,
  ) async {
    await _client.patch<Map<String, dynamic>>(
      '/profile-sections/${_sectionTypeToString(type)}/visibility',
      data: {'visibility': _visibilityToString(visibility)},
    );
  }

  Future<List<ProfileSectionEntity>> getUserSections(String userId) async {
    final result = await _client.get<List<dynamic>>(
      '/profile-sections/user/$userId',
      fromJson: (d) => d as List<dynamic>,
    );
    return result
        .map((e) => ProfileSectionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _sectionTypeToString(SectionType type) {
    switch (type) {
      case SectionType.coreValues: return 'VALUES';
      case SectionType.worldview: return 'WORLDVIEW';
      case SectionType.skills: return 'SKILLS';
      case SectionType.interests: return 'INTERESTS';
      case SectionType.desires: return 'DESIRES';
      case SectionType.background: return 'BACKGROUND';
      case SectionType.likes: return 'LIKES';
      case SectionType.dislikes: return 'DISLIKES';
    }
  }

  String _visibilityToString(SectionVisibility v) {
    switch (v) {
      case SectionVisibility.public_: return 'PUBLIC';
      case SectionVisibility.contacts: return 'CONTACTS';
      case SectionVisibility.private_: return 'PRIVATE';
    }
  }
}
