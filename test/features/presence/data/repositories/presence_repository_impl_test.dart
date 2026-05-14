import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/presence/data/datasources/presence_remote_datasource.dart';
import 'package:taler_id_mobile/features/presence/data/repositories/presence_repository_impl.dart';
import 'package:taler_id_mobile/features/presence/domain/entities/presence_entity.dart';

class _MockDs extends Mock implements PresenceRemoteDataSource {}

void main() {
  late _MockDs ds;
  late PresenceRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    repo = PresenceRepositoryImpl(ds);
  });

  test('getPresence forwards to datasource and returns entity', () async {
    final entity = PresenceEntity(
      isOnline: true,
      lastSeenAt: DateTime.utc(2026, 5, 14, 7),
      hidden: false,
    );
    when(() => ds.getPresence('u1')).thenAnswer((_) async => entity);
    expect(await repo.getPresence('u1'), entity);
    verify(() => ds.getPresence('u1')).called(1);
  });

  test('ping forwards to datasource', () async {
    when(() => ds.ping()).thenAnswer((_) async {});
    await repo.ping();
    verify(() => ds.ping()).called(1);
  });

  test('updatePrivacy forwards privacy string to datasource', () async {
    when(() => ds.updatePrivacy(any())).thenAnswer((_) async {});
    await repo.updatePrivacy('CONTACTS');
    verify(() => ds.updatePrivacy('CONTACTS')).called(1);
  });

  test('PresenceEntity.fromJson handles hidden + null lastSeen correctly', () {
    final e = PresenceEntity.fromJson({
      'isOnline': null,
      'lastSeenAt': null,
      'hidden': true,
    });
    expect(e.isOnline, isNull);
    expect(e.lastSeenAt, isNull);
    expect(e.hidden, isTrue);
  });
}
