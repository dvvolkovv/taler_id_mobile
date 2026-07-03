import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/entities/owner_voice_status.dart';

class VoiceEnrollmentRemote {
  final DioClient _dio;

  VoiceEnrollmentRemote(this._dio);

  Future<OwnerVoiceStatus> getStatus() async {
    final resp = await _dio.dio.get('/voice-gate/owner-status');
    return OwnerVoiceStatus.fromJson(Map<String, dynamic>.from(resp.data));
  }

  Future<OwnerVoiceStatus> enroll(String wavPath) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(wavPath, filename: 'enroll.wav'),
    });
    final resp = await _dio.dio.post('/voice-gate/enroll', data: form);
    // Backend returns { ok, speakerId, embeddingDim, audioSec } on 200; map to Status
    final data = Map<String, dynamic>.from(resp.data);
    return OwnerVoiceStatus(
      enrolled: data['ok'] == true,
      speakerId: data['speakerId'] as String?,
      enrolledAt: DateTime.now().toUtc(),
    );
  }

  Future<void> deleteOwner() async {
    await _dio.dio.delete('/voice-gate/owner');
  }
}
