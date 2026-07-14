import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_kyc_repository.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/error_keys.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final IKycRepository repo;

  KycBloc({required this.repo}) : super(KycInitial()) {
    on<KycStatusRequested>(_onStatus);
    on<KycStartRequested>(_onStart);
    on<KycSdkCompleted>(_onSdkComplete);
    on<KycSdkFailed>(_onSdkFailed);
    on<KycApplicantDataRequested>(_onApplicantData);
  }

  Future<void> _onStatus(KycStatusRequested event, Emitter<KycState> emit) async {
    emit(KycLoading());
    try {
      final data = await repo.getKycStatus();
      final status = data['status'] as String;
      emit(KycStatusLoaded(
        status: status,
        rejectionReason: data['rejectionReason'] as String?,
        verifiedAt: data['verifiedAt'] as String?,
        inProgress: data['inProgress'] == true,
      ));
      // Auto-fetch applicant data when verified
      if (status == 'VERIFIED') {
        add(KycApplicantDataRequested());
      }
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError(ErrorKeys.failedToLoadKycStatus));
    }
  }

  Future<void> _onApplicantData(KycApplicantDataRequested event, Emitter<KycState> emit) async {
    final currentState = state;
    String status = 'VERIFIED';
    String? verifiedAt;
    if (currentState is KycStatusLoaded) {
      status = currentState.status;
      verifiedAt = currentState.verifiedAt;
    }
    emit(KycApplicantDataLoading(status: status, verifiedAt: verifiedAt));
    try {
      final data = await repo.getApplicantData();
      emit(KycStatusLoaded(
        status: status,
        verifiedAt: verifiedAt,
        applicantData: data,
      ));
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError(ErrorKeys.failedToLoadKycData));
    }
  }

  Future<void> _onStart(KycStartRequested event, Emitter<KycState> emit) async {
    emit(KycLoading());
    try {
      final response = await repo.startKyc();
      emit(KycSdkReady(webSdkUrl: response.webSdkUrl));
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError(ErrorKeys.failedToStartKyc));
    }
  }

  Future<void> _onSdkComplete(KycSdkCompleted event, Emitter<KycState> emit) async {
    emit(KycSdkDone());
  }

  Future<void> _onSdkFailed(KycSdkFailed event, Emitter<KycState> emit) async {
    emit(KycError('verificationError:${event.errorCode}'));
  }
}
