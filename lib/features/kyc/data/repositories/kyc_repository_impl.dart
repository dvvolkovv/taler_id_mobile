import '../../domain/entities/sumsub_applicant_entity.dart';
import '../../domain/repositories/i_kyc_repository.dart';
import '../datasources/kyc_remote_datasource.dart';
import '../../../../core/storage/cache_service.dart';

class KycRepositoryImpl implements IKycRepository {
  final KycRemoteDataSource remote;
  final CacheService cache;

  KycRepositoryImpl({required this.remote, required this.cache});

  @override
  Future<KycStartResponse> startKyc() => remote.startKyc();

  @override
  Future<Map<String, dynamic>> getKycStatus() async {
    try {
      final data = await remote.getKycStatus();
      await cache.saveKycStatus(data);
      return data;
    } catch (_) {
      final cached = cache.getKycStatus();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<SumsubApplicantEntity> getApplicantData() async {
    try {
      final data = await remote.getApplicantData();
      await cache.saveSumsubData(data);
      return SumsubApplicantEntity.fromJson(data);
    } catch (_) {
      final cached = cache.getSumsubData();
      if (cached != null) return SumsubApplicantEntity.fromJson(cached);
      rethrow;
    }
  }
}
