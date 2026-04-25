import 'package:equatable/equatable.dart';

abstract class TransactionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {}
