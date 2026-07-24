import 'package:flutter_bloc/flutter_bloc.dart';

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
    } catch (e) {
      // 404 = ящика нет (старый юзер, ещё не выбрал адрес)
      final msg = e.toString();
      if (msg.contains('404') || msg.contains('mail_account_not_found')) {
        emit(state.copyWith(noAccount: true, isLoading: false));
      } else {
        emit(state.copyWith(error: msg, isLoading: false));
      }
    }
  }

  Future<void> _onLoadMore(
      MailLoadMoreRequested event, Emitter<MailState> emit) async {
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
    emit(state.copyWith(
      items: state.items.where((m) => m.uid != event.uid).toList(),
    ));
    try {
      await _repo.deleteMessage(event.uid);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
