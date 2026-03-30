import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/i_session_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final ISessionRepository repo;

  SessionsBloc({required this.repo}) : super(SessionsInitial()) {
    on<SessionsLoadRequested>(_onLoad);
    on<SessionDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(SessionsLoadRequested event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final sessions = await repo.getSessions();
      emit(SessionsLoaded(sessions));
    } on ApiException catch (e) {
      emit(SessionsError(e.message));
    } catch (_) {
      emit(SessionsError(ErrorKeys.failedToLoadSessions));
    }
  }

  Future<void> _onDelete(SessionDeleteRequested event, Emitter<SessionsState> emit) async {
    final current = state is SessionsLoaded ? (state as SessionsLoaded).sessions : <SessionEntity>[];
    try {
      await repo.deleteSession(event.sessionId);
      final updated = current.where((s) => s.id != event.sessionId).toList();
      emit(SessionsLoaded(updated));
    } on ApiException catch (e) {
      emit(SessionsError(e.message));
    } catch (_) {
      emit(SessionsError(ErrorKeys.failedToDeleteSession));
    }
  }
}
