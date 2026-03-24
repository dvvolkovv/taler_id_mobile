import '../../domain/entities/profile_section_entity.dart';

abstract class ProfileSectionsEvent {}

class LoadMySections extends ProfileSectionsEvent {}

class UpsertSection extends ProfileSectionsEvent {
  final SectionType type;
  final SectionContent content;
  final SectionVisibility visibility;
  UpsertSection({required this.type, required this.content, required this.visibility});
}

class DeleteSection extends ProfileSectionsEvent {
  final SectionType type;
  DeleteSection(this.type);
}

class UpdateSectionVisibility extends ProfileSectionsEvent {
  final SectionType type;
  final SectionVisibility visibility;
  UpdateSectionVisibility({required this.type, required this.visibility});
}

class LoadUserSections extends ProfileSectionsEvent {
  final String userId;
  LoadUserSections(this.userId);
}
