import 'package:equatable/equatable.dart';

abstract class TogglesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadToggles extends TogglesEvent {}

class ToggleFeature extends TogglesEvent {
  final String featureKey;
  final bool enabled;
  ToggleFeature({required this.featureKey, required this.enabled});
  @override
  List<Object?> get props => [featureKey, enabled];
}
