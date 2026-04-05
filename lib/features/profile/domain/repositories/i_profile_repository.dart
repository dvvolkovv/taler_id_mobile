import '../entities/user_entity.dart';

abstract class IProfileRepository {
  Future<UserEntity> getProfile();
  UserEntity? getCachedProfile();
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
}
