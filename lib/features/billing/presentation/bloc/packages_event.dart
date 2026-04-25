import 'package:equatable/equatable.dart';

abstract class PackagesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPackages extends PackagesEvent {}

class PurchasePackage extends PackagesEvent {
  final String packageId;
  PurchasePackage(this.packageId);
  @override
  List<Object?> get props => [packageId];
}
