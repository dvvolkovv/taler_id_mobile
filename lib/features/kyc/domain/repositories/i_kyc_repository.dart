import '../entities/sumsub_applicant_entity.dart';
import '../../data/datasources/kyc_remote_datasource.dart' show KycStartResponse;

abstract class IKycRepository {
  Future<KycStartResponse> startKyc();
  Future<Map<String, dynamic>> getKycStatus();
  Future<SumsubApplicantEntity> getApplicantData();
}
