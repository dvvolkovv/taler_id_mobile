import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_balance_entity.dart';

abstract class BalanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BalanceInitial extends BalanceState {}

class BalanceLoading extends BalanceState {}

class BalanceLoaded extends BalanceState {
  final WalletBalanceEntity balance;
  BalanceLoaded(this.balance);
  @override
  List<Object?> get props => [balance];
}

class BalanceError extends BalanceState {
  final String message;
  BalanceError(this.message);
  @override
  List<Object?> get props => [message];
}
