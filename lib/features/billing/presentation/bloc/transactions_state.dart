import 'package:equatable/equatable.dart';
import '../../domain/entities/billing_transaction_entity.dart';

abstract class TransactionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<BillingTransactionEntity> transactions;
  TransactionsLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class TransactionsError extends TransactionsState {
  final String message;
  TransactionsError(this.message);
  @override
  List<Object?> get props => [message];
}
