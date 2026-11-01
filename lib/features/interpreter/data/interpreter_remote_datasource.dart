import 'package:dio/dio.dart';

import '../../../core/api/api_error_handler.dart';
import '../../../core/api/dio_client.dart';
import '../domain/interpreter_error.dart';
import '../domain/interpreter_models.dart';

/// REST calls under `src/interpreter/*`. Every method rethrows as
/// [InterpreterException] so the repository and bloc never see a bare
/// [ApiException]/[DioException].
class InterpreterRemoteDataSource {
  final DioClient client;

  InterpreterRemoteDataSource(this.client);

  Future<InterpreterCatalog> catalog() async {
    try {
      return await client.get<InterpreterCatalog>(
        '/interpreter/languages',
        fromJson: (d) => InterpreterCatalog.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }

  Future<HostedSession> create(String lang) async {
    try {
      return await client.post<HostedSession>(
        '/interpreter/sessions',
        data: {'lang': lang},
        // A retry/failover on a receiveTimeout would risk a second QR
        // session opening for the same host if the first create() actually
        // reached the server.
        options: Options(extra: {kNoResendAfterTimeout: true}),
        fromJson: (d) => HostedSession.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }

  Future<NewCode> newCode(String sessionId) async {
    try {
      return await client.post<NewCode>(
        '/interpreter/sessions/$sessionId/code',
        fromJson: (d) => NewCode.fromJson(Map<String, dynamic>.from(d as Map)),
      );
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }

  /// Goes through `client.dio` directly (not `DioClient.post`) because the
  /// backend waits for the agent to start up to 35s before answering — the
  /// shared client's 30s default `receiveTimeout` would time this call out
  /// on its own before the server gets a chance to.
  Future<JoinedSession> join(String code, String lang) async {
    try {
      final response = await client.dio.post(
        '/interpreter/sessions/join',
        data: {'code': code, 'lang': lang},
        // The single-use code may already be consumed and the host's
        // billing session already opened by the time a receiveTimeout
        // fires — a retry/failover would risk the server seeing this twice.
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          extra: {kNoResendAfterTimeout: true},
        ),
      );
      return JoinedSession.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw InterpreterException.from(ApiErrorHandler.handle(e));
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }

  Future<SessionView> get(String sessionId) async {
    try {
      return await client.get<SessionView>(
        '/interpreter/sessions/$sessionId',
        fromJson: (d) => SessionView.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }

  Future<void> end(String sessionId) async {
    try {
      await client.post<dynamic>('/interpreter/sessions/$sessionId/end');
    } catch (e) {
      throw InterpreterException.from(e);
    }
  }
}
