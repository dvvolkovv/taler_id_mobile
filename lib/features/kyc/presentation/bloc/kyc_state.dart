import 'package:equatable/equatable.dart';
import '../../domain/entities/sumsub_applicant_entity.dart';

abstract class KycState extends Equatable {
  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {}
class KycLoading extends KycState {}

class KycStatusLoaded extends KycState {
  final String status;
  final String? rejectionReason;
  final String? verifiedAt;
  final SumsubApplicantEntity? applicantData;
  KycStatusLoaded({
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    this.applicantData,
  });
  @override
  List<Object?> get props => [status, rejectionReason, verifiedAt, applicantData];
}

class KycApplicantDataLoading extends KycState {
  final String status;
  final String? verifiedAt;
  KycApplicantDataLoading({required this.status, this.verifiedAt});
  @override
  List<Object?> get props => [status, verifiedAt];
}

class KycSdkReady extends KycState {
  /// Mobile SDK token — non-null on mobile, null on desktop.
  final String? sdkToken;

  /// Web SDK URL — non-null on desktop, null on mobile.
  final String? webSdkUrl;

  KycSdkReady({this.sdkToken, this.webSdkUrl});

  @override
  List<Object?> get props => [sdkToken, webSdkUrl];
}

class KycSdkDone extends KycState {} // SDK finished, waiting for webhook
class KycError extends KycState {
  final String message;
  KycError(this.message);
  @override
  List<Object?> get props => [message];
}
