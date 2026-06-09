import '../../domain/entities/owner_voice_status.dart';
import '../../domain/repositories/voice_enrollment_repository.dart';
import '../datasources/voice_enrollment_remote.dart';

class VoiceEnrollmentRepositoryImpl implements VoiceEnrollmentRepository {
  final VoiceEnrollmentRemote _remote;
  VoiceEnrollmentRepositoryImpl(this._remote);

  @override
  Future<OwnerVoiceStatus> getStatus() => _remote.getStatus();

  @override
  Future<OwnerVoiceStatus> enroll(String wavPath) => _remote.enroll(wavPath);

  @override
  Future<void> deleteOwner() => _remote.deleteOwner();
}
