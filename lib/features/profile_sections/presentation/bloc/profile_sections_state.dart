import '../../domain/entities/profile_section_entity.dart';

abstract class ProfileSectionsState {}

class ProfileSectionsInitial extends ProfileSectionsState {}

class ProfileSectionsLoading extends ProfileSectionsState {}

class ProfileSectionsLoaded extends ProfileSectionsState {
  final List<ProfileSectionEntity> sections;
  ProfileSectionsLoaded(this.sections);
}

class ProfileSectionsError extends ProfileSectionsState {
  final String message;
  ProfileSectionsError(this.message);
}
