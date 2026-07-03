import '../entities/owner_voice_status.dart';

abstract class VoiceEnrollmentRepository {
  Future<OwnerVoiceStatus> getStatus();
  Future<OwnerVoiceStatus> enroll(String wavPath);
  Future<void> deleteOwner();
}
