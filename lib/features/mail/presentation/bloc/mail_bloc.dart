import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_exception.dart';
import '../../domain/entities/mail_folder_entity.dart';
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
    on<MailFolderSelected>(_onFolderSelected);
    on<MailMessageMoved>(_onMessageMoved);
    on<MailFolderCreated>(_onFolderCreated);
    on<MailFolderDeleted>(_onFolderDeleted);
  }

  static int _inboxUnseen(List<MailFolderEntity> folders) {
    final inbox = folders.where((f) => f.role == 'inbox');
    return inbox.isEmpty ? 0 : inbox.first.unseen;
  }

  Future<void> _onInboxRequested(
      MailInboxRequested event, Emitter<MailState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true, noAccount: false));
    try {
      final account = await _repo.getAccount();
      final page =
          await _repo.getMessages(beforeUid: null, folder: state.currentFolder);
      // Папки — не критично: при ошибке остаёмся со старым списком
      var folders = state.folders;
      var unread = state.unread;
      try {
        folders = await _repo.getFolders();
        unread = _inboxUnseen(folders);
      } catch (_) {}
      emit(state.copyWith(
        account: account,
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        folders: folders,
        unread: unread,
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
      final page = await _repo.getMessages(
          beforeUid: cursor, folder: state.currentFolder);
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
      await _repo.setSeen(event.uid, event.seen, folder: state.currentFolder);
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
      await _repo.deleteMessage(event.uid, folder: state.currentFolder);
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

  Future<void> _onFolderSelected(
      MailFolderSelected event, Emitter<MailState> emit) async {
    emit(state.copyWith(
      currentFolder: event.path,
      items: const [],
      clearCursor: true,
      isLoading: true,
      clearError: true,
    ));
    try {
      final page = await _repo.getMessages(beforeUid: null, folder: event.path);
      emit(state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onMessageMoved(
      MailMessageMoved event, Emitter<MailState> emit) async {
    final items = state.items;
    final idx = items.indexWhere((m) => m.uid == event.uid);
    if (idx == -1) return;
    final removed = items[idx];
    emit(state.copyWith(
      items: [...items.sublist(0, idx), ...items.sublist(idx + 1)],
    ));
    try {
      await _repo.moveMessage(event.uid,
          fromFolder: state.currentFolder, toFolder: event.toFolder);
    } catch (e) {
      // Rollback: возвращаем письмо на прежнее место
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

  Future<void> _onFolderCreated(
      MailFolderCreated event, Emitter<MailState> emit) async {
    try {
      await _repo.createFolder(event.name);
      final folders = await _repo.getFolders();
      emit(state.copyWith(folders: folders, unread: _inboxUnseen(folders)));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFolderDeleted(
      MailFolderDeleted event, Emitter<MailState> emit) async {
    try {
      await _repo.deleteFolder(event.path);
      final folders = await _repo.getFolders();
      emit(state.copyWith(folders: folders, unread: _inboxUnseen(folders)));
      if (state.currentFolder == event.path) {
        // Текущая папка удалена — возвращаемся в INBOX
        add(const MailFolderSelected('INBOX'));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
