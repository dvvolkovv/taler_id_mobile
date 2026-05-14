import '../entities/presence_entity.dart';

abstract class IPresenceRepository {
  Future<void> ping();
  Future<PresenceEntity> getPresence(String userId);
  Future<PresenceEntity> getMyPresence();
  Future<void> updatePrivacy(String privacy); // 'EVERYONE' | 'CONTACTS' | 'NOBODY'
}
