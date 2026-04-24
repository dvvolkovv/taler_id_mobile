import 'package:equatable/equatable.dart';

abstract class BalanceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load (or refresh) the wallet balance from the backend.
class LoadBalance extends BalanceEvent {}

/// Notification from outside (e.g. Socket.IO `billing.balance_changed`) that
/// the balance changed server-side. BLoC reacts by refetching, since the
/// backend is the single source of truth and may include recent transactions
/// in the response.
class BalanceChangedExternally extends BalanceEvent {
  final String balancePlanck;
  BalanceChangedExternally(this.balancePlanck);
  @override
  List<Object?> get props => [balancePlanck];
}
