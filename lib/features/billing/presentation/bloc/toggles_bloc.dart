import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import '../../domain/entities/feature_toggle_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import 'toggles_event.dart';
import 'toggles_state.dart';

class TogglesBloc extends Bloc<TogglesEvent, TogglesState> {
  final BillingRepository repo;

  TogglesBloc({required this.repo}) : super(TogglesInitial()) {
    on<LoadToggles>(_onLoad);
    on<ToggleFeature>(_onToggle);
  }

  Future<void> _onLoad(LoadToggles event, Emitter<TogglesState> emit) async {
    emit(TogglesLoading());
    try {
      final toggles = await repo.getToggles();
      emit(TogglesLoaded(toggles));
    } on ApiException catch (e) {
      emit(TogglesError(e.message));
    } catch (_) {
      emit(TogglesError(ErrorKeys.failedToLoadToggles));
    }
  }

  /// Optimistic toggle: flip the value locally first, then call the backend.
  /// On failure, rollback to the prior list and emit an error.
  Future<void> _onToggle(
    ToggleFeature event,
    Emitter<TogglesState> emit,
  ) async {
    final current = state;
    if (current is! TogglesLoaded) return;

    final original = current.toggles;
    final optimistic = original
        .map((t) => t.featureKey == event.featureKey
            ? FeatureToggleEntity(
                featureKey: t.featureKey,
                enabled: event.enabled,
              )
            : t)
        .toList();
    emit(TogglesLoaded(optimistic));

    try {
      await repo.setToggle(event.featureKey, event.enabled);
    } on ApiException catch (e) {
      emit(TogglesLoaded(original));
      emit(TogglesError(e.message));
      emit(TogglesLoaded(original));
    } catch (_) {
      emit(TogglesLoaded(original));
      emit(TogglesError(ErrorKeys.failedToSaveToggle));
      emit(TogglesLoaded(original));
    }
  }
}
