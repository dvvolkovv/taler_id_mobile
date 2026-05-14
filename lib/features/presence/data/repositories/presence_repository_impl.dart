import '../../domain/entities/presence_entity.dart';
import '../../domain/repositories/i_presence_repository.dart';
import '../datasources/presence_remote_datasource.dart';

class PresenceRepositoryImpl implements IPresenceRepository {
  final PresenceRemoteDataSource _ds;
  PresenceRepositoryImpl(this._ds);

  @override
  Future<void> ping() => _ds.ping();

  @override
  Future<PresenceEntity> getPresence(String userId) => _ds.getPresence(userId);

  @override
  Future<PresenceEntity> getMyPresence() => _ds.getMyPresence();

  @override
  Future<void> updatePrivacy(String privacy) => _ds.updatePrivacy(privacy);
}
