import '../../../../core/api/dio_client.dart';
import '../models/group_call_dto.dart';

/// Thin REST wrapper around the backend's `/voice/group-calls` endpoints.
/// Returns raw DTOs — domain mapping happens in the repository implementation.
class GroupCallRemoteDatasource {
  final DioClient _http;

  GroupCallRemoteDatasource(this._http);

  Future<CreateGroupCallResponseDto> create(List<String> inviteeIds) async {
    return _http.post(
      '/voice/group-calls',
      data: {'inviteeIds': inviteeIds},
      fromJson: (d) =>
          CreateGroupCallResponseDto.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  Future<List<GroupCallDto>> getActive() async {
    final response = await _http.get(
      '/voice/group-calls/active',
      fromJson: (d) =>
          ActiveGroupCallsResponseDto.fromJson(Map<String, dynamic>.from(d as Map)),
    );
    return response.calls;
  }

  Future<GroupCallDto> getCall(String id) async {
    final response = await _http.get(
      '/voice/group-calls/$id',
      fromJson: (d) =>
          GetGroupCallResponseDto.fromJson(Map<String, dynamic>.from(d as Map)),
    );
    return response.groupCall;
  }

  Future<JoinGroupCallResponseDto> join(String id) async {
    return _http.post(
      '/voice/group-calls/$id/join',
      data: const <String, dynamic>{},
      fromJson: (d) =>
          JoinGroupCallResponseDto.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  Future<void> decline(String id) async {
    await _http.post(
      '/voice/group-calls/$id/decline',
      data: const <String, dynamic>{},
      fromJson: (d) => d,
    );
  }

  Future<void> leave(String id) async {
    await _http.post(
      '/voice/group-calls/$id/leave',
      data: const <String, dynamic>{},
      fromJson: (d) => d,
    );
  }

  Future<void> inviteMore(String id, List<String> userIds) async {
    await _http.post(
      '/voice/group-calls/$id/invite',
      data: {'userIds': userIds},
      fromJson: (d) => d,
    );
  }

  Future<void> kick(String id, String userId) async {
    await _http.post(
      '/voice/group-calls/$id/kick',
      data: {'userId': userId},
      fromJson: (d) => d,
    );
  }

  Future<void> muteAll(String id) async {
    await _http.post(
      '/voice/group-calls/$id/mute-all',
      data: const <String, dynamic>{},
      fromJson: (d) => d,
    );
  }

  Future<void> end(String id) async {
    await _http.post(
      '/voice/group-calls/$id/end',
      data: const <String, dynamic>{},
      fromJson: (d) => d,
    );
  }
}
