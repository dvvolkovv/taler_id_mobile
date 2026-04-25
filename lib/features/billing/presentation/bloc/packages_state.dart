import 'package:equatable/equatable.dart';
import '../../domain/entities/billing_package_entity.dart';
import '../../domain/entities/wallet_balance_entity.dart';

abstract class PackagesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PackagesInitial extends PackagesState {}

class PackagesLoading extends PackagesState {}

class PackagesLoaded extends PackagesState {
  final List<BillingPackageEntity> packages;
  PackagesLoaded(this.packages);
  @override
  List<Object?> get props => [packages];
}

class PackagesError extends PackagesState {
  final String message;
  PackagesError(this.message);
  @override
  List<Object?> get props => [message];
}

class PurchaseInProgress extends PackagesState {
  final String packageId;
  PurchaseInProgress(this.packageId);
  @override
  List<Object?> get props => [packageId];
}

class PurchaseSuccess extends PackagesState {
  final WalletBalanceEntity newBalance;
  PurchaseSuccess({required this.newBalance});
  @override
  List<Object?> get props => [newBalance];
}

class PurchaseFailed extends PackagesState {
  final String message;
  PurchaseFailed(this.message);
  @override
  List<Object?> get props => [message];
}
