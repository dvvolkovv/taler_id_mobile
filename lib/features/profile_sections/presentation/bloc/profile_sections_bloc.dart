import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_profile_sections_repository.dart';
import 'profile_sections_event.dart';
import 'profile_sections_state.dart';

class ProfileSectionsBloc extends Bloc<ProfileSectionsEvent, ProfileSectionsState> {
  final IProfileSectionsRepository _repo;

  ProfileSectionsBloc(this._repo) : super(ProfileSectionsInitial()) {
    on<LoadMySections>(_onLoad);
    on<UpsertSection>(_onUpsert);
    on<DeleteSection>(_onDelete);
    on<UpdateSectionVisibility>(_onUpdateVisibility);
    on<LoadUserSections>(_onLoadUser);
  }

  Future<void> _onLoad(LoadMySections event, Emitter<ProfileSectionsState> emit) async {
    emit(ProfileSectionsLoading());
    try {
      final sections = await _repo.getMySections();
      emit(ProfileSectionsLoaded(sections));
    } catch (e) {
      emit(ProfileSectionsError(e.toString()));
    }
  }

  Future<void> _onUpsert(UpsertSection event, Emitter<ProfileSectionsState> emit) async {
    try {
      await _repo.upsertSection(event.type, event.content, event.visibility);
      add(LoadMySections());
    } catch (e) {
      emit(ProfileSectionsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteSection event, Emitter<ProfileSectionsState> emit) async {
    try {
      await _repo.deleteSection(event.type);
      add(LoadMySections());
    } catch (e) {
      emit(ProfileSectionsError(e.toString()));
    }
  }

  Future<void> _onUpdateVisibility(UpdateSectionVisibility event, Emitter<ProfileSectionsState> emit) async {
    try {
      await _repo.updateVisibility(event.type, event.visibility);
      add(LoadMySections());
    } catch (e) {
      emit(ProfileSectionsError(e.toString()));
    }
  }

  Future<void> _onLoadUser(LoadUserSections event, Emitter<ProfileSectionsState> emit) async {
    emit(ProfileSectionsLoading());
    try {
      final sections = await _repo.getUserSections(event.userId);
      emit(ProfileSectionsLoaded(sections));
    } catch (e) {
      emit(ProfileSectionsError(e.toString()));
    }
  }
}
