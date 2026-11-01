import 'interpreter_models.dart';

/// Gateway to `src/interpreter/*` on the backend. Every method throws
/// [InterpreterException] (never the underlying [DioException]/[ApiException])
/// so bloc code only ever catches one exception type.
abstract class InterpreterRepository {
  /// `GET /interpreter/languages`.
  Future<InterpreterCatalog> catalog();

  /// `POST /interpreter/sessions` — host (A) starts a new session.
  Future<HostedSession> create(String lang);

  /// `POST /interpreter/sessions/:id/code` — host asks for a fresh QR code
  /// on a session that is still waiting.
  Future<NewCode> newCode(String sessionId);

  /// `POST /interpreter/sessions/join` — guest (B) joins by scanned code.
  Future<JoinedSession> join(String code, String lang);

  /// `GET /interpreter/sessions/:id` — status poll, used by both sides.
  Future<SessionView> get(String sessionId);

  /// `POST /interpreter/sessions/:id/end` — idempotent; either side may end.
  Future<void> end(String sessionId);
}
