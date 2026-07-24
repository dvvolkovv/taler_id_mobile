import 'package:equatable/equatable.dart';

import '../../domain/entities/mail_entities.dart';
import '../../domain/entities/mail_folder_entity.dart';

class MailState extends Equatable {
  final MailAccountEntity? account;
  final List<MailListItemEntity> items;
  final List<MailFolderEntity> folders;
  final String currentFolder;
  final int unread;
  final int? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool noAccount;
  final String? error;

  const MailState({
    this.account,
    this.items = const [],
    this.folders = const [],
    this.currentFolder = 'INBOX',
    this.unread = 0,
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.noAccount = false,
    this.error,
  });

  MailState copyWith({
    MailAccountEntity? account,
    List<MailListItemEntity>? items,
    List<MailFolderEntity>? folders,
    String? currentFolder,
    int? unread,
    int? nextCursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? noAccount,
    String? error,
    bool clearError = false,
  }) =>
      MailState(
        account: account ?? this.account,
        items: items ?? this.items,
        folders: folders ?? this.folders,
        currentFolder: currentFolder ?? this.currentFolder,
        unread: unread ?? this.unread,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        noAccount: noAccount ?? this.noAccount,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        account,
        items,
        folders,
        currentFolder,
        unread,
        nextCursor,
        isLoading,
        isLoadingMore,
        noAccount,
        error,
      ];
}
