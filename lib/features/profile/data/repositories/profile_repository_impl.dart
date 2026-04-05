import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../../../../core/storage/cache_service.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource remote;
  final CacheService cache;

  ProfileRepositoryImpl({required this.remote, required this.cache});

  @override
  Future<UserEntity> getProfile() async {
    try {
      final data = await remote.getProfile();
      await cache.saveProfile(data);
      return UserEntity.fromJson(data);
    } catch (_) {
      final cached = cache.getProfile();
      if (cached != null) return UserEntity.fromJson(cached);
      rethrow;
    }
  }

  @override
  UserEntity? getCachedProfile() {
    final cached = cache.getProfile();
    if (cached == null) return null;
    try { return UserEntity.fromJson(cached); } catch (_) { return null; }
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> data) async {
    await remote.updateProfile(data);
    // Reload full profile (updateProfile returns Profile, not User)
    final full = await remote.getProfile();
    await cache.saveProfile(full);
    return UserEntity.fromJson(full);
  }
}
