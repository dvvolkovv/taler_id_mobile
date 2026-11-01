import '../domain/interpreter_models.dart';
import '../domain/interpreter_repository.dart';
import 'interpreter_remote_datasource.dart';

class InterpreterRepositoryImpl implements InterpreterRepository {
  final InterpreterRemoteDataSource remote;

  InterpreterRepositoryImpl(this.remote);

  @override
  Future<InterpreterCatalog> catalog() => remote.catalog();

  @override
  Future<HostedSession> create(String lang) => remote.create(lang);

  @override
  Future<NewCode> newCode(String sessionId) => remote.newCode(sessionId);

  @override
  Future<JoinedSession> join(String code, String lang) =>
      remote.join(code, lang);

  @override
  Future<SessionView> get(String sessionId) => remote.get(sessionId);

  @override
  Future<void> end(String sessionId) => remote.end(sessionId);
}
