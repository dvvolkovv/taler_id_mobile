import 'package:equatable/equatable.dart';
import '../../domain/entities/feature_toggle_entity.dart';

abstract class TogglesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TogglesInitial extends TogglesState {}

class TogglesLoading extends TogglesState {}

class TogglesLoaded extends TogglesState {
  final List<FeatureToggleEntity> toggles;
  TogglesLoaded(this.toggles);
  @override
  List<Object?> get props => [toggles];
}

class TogglesError extends TogglesState {
  final String message;
  TogglesError(this.message);
  @override
  List<Object?> get props => [message];
}
