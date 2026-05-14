import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/presence/domain/repositories/i_presence_repository.dart';
import 'package:taler_id_mobile/features/presence/presentation/services/presence_heartbeat_service.dart';

class _MockRepo extends Mock implements IPresenceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late PresenceHeartbeatService svc;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.ping()).thenAnswer((_) async {});
    svc = PresenceHeartbeatService(repo);
  });

  tearDown(() => svc.dispose());

  test('start() pings immediately when logged in and resumed', () async {
    svc.setLoggedIn(true);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => repo.ping()).called(1);
  });

  test('does not ping when logged out', () async {
    svc.setLoggedIn(false);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNever(() => repo.ping());
  });

  test('stop() cancels the timer', () async {
    svc.setLoggedIn(true);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    svc.stop();
    clearInteractions(repo);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNever(() => repo.ping());
  });
}
