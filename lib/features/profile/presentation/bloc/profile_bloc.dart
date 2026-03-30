import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IProfileRepository repo;

  ProfileBloc({required this.repo}) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateSubmitted>(_onUpdate);
  }

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await repo.getProfile();
      emit(ProfileLoaded(user));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      emit(ProfileError(message: ErrorKeys.failedToLoadProfile));
    }
  }

  Future<void> _onUpdate(ProfileUpdateSubmitted event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await repo.updateProfile(event.data);
      emit(ProfileLoaded(user));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      // ignore: avoid_print
      print('[ProfileBloc] Update error: $e');
      emit(ProfileError(message: ErrorKeys.failedToUpdateProfile));
    }
  }
}
