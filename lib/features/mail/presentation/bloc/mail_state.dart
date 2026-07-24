import 'package:equatable/equatable.dart';

import '../../domain/entities/mail_entities.dart';

class MailState extends Equatable {
  final MailAccountEntity? account;
  final List<MailListItemEntity> items;
  final int? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool noAccount;
  final String? error;

  const MailState({
    this.account,
    this.items = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.noAccount = false,
    this.error,
  });

  MailState copyWith({
    MailAccountEntity? account,
    List<MailListItemEntity>? items,
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
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        noAccount: noAccount ?? this.noAccount,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [account, items, nextCursor, isLoading, isLoadingMore, noAccount, error];
}
