import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/repositories/i_mail_repository.dart';
import 'mail_event.dart';
import 'mail_state.dart';

class MailBloc extends Bloc<MailEvent, MailState> {
  final IMailRepository _repo;

  MailBloc({required IMailRepository repo})
      : _repo = repo,
        super(const MailState()) {
    on<MailInboxRequested>(_onInboxRequested);
    on<MailLoadMoreRequested>(_onLoadMore);
    on<MailMarkSeenRequested>(_onMarkSeen);
    on<MailDeleteRequested>(_onDelete);
  }

  Future<void> _onInboxRequested(
      MailInboxRequested event, Emitter<MailState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true, noAccount: false));
    try {
      final account = await _repo.getAccount();
      final page = await _repo.getMessages(beforeUid: null);
      emit(state.copyWith(
        account: account,
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isLoading: false,
      ));
    } on ApiException catch (e) {
      // 404 / mail_account_not_found = ящика нет (старый юзер, ещё не выбрал адрес)
      final serverCode = e.data?['code'] as String?;
      if (e.isNotFound || serverCode == 'mail_account_not_found') {
        emit(state.copyWith(noAccount: true, isLoading: false));
      } else {
        emit(state.copyWith(error: e.message, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onLoadMore(
      MailLoadMoreRequested event, Emitter<MailState> emit) async {
    if (state.isLoading) return;
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repo.getMessages(beforeUid: cursor);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoadingMore: false));
    }
  }

  Future<void> _onMarkSeen(
      MailMarkSeenRequested event, Emitter<MailState> emit) async {
    emit(state.copyWith(
      items: state.items
          .map((m) => m.uid == event.uid ? m.copyWith(seen: event.seen) : m)
          .toList(),
    ));
    try {
      await _repo.setSeen(event.uid, event.seen);
    } catch (_) {
      // тихий откат не делаем — при следующем refresh придёт серверное состояние
    }
  }

  Future<void> _onDelete(
      MailDeleteRequested event, Emitter<MailState> emit) async {
    final items = state.items;
    final idx = items.indexWhere((m) => m.uid == event.uid);
    if (idx == -1) return;
    final removed = items[idx];
    emit(state.copyWith(
      items: [...items.sublist(0, idx), ...items.sublist(idx + 1)],
    ));
    try {
      await _repo.deleteMessage(event.uid);
    } catch (e) {
      // Rollback: вставляем удалённый элемент обратно на прежнее место
      final current = state.items;
      final restoredIdx = idx.clamp(0, current.length);
      emit(state.copyWith(
        items: [
          ...current.sublist(0, restoredIdx),
          removed,
          ...current.sublist(restoredIdx),
        ],
        error: e.toString(),
      ));
    }
  }
}
