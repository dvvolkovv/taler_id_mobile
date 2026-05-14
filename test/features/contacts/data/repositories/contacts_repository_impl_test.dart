// test/features/contacts/data/repositories/contacts_repository_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taler_id_mobile/core/storage/outbox_op.dart';
import 'package:taler_id_mobile/core/storage/outbox_queue.dart';
import 'package:taler_id_mobile/features/contacts/data/datasources/contacts_local_datasource.dart';
import 'package:taler_id_mobile/features/contacts/data/repositories/contacts_repository_impl.dart';
import 'package:taler_id_mobile/features/contacts/domain/entities/contact_item_entity.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override Future<String?> getApplicationDocumentsPath() async => dir;
  @override Future<String?> getApplicationSupportPath() async => dir;
  @override Future<String?> getTemporaryPath() async => dir;
}

void main() {
  late Directory tempDir;
  late ContactsLocalDataSource local;
  late OutboxQueue queue;
  late _MockRemote remote;
  late ContactsRepositoryImpl repo;

  setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contacts_repo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    Hive.init(tempDir.path);
    await Hive.openBox<String>(ContactsLocalDataSource.boxName);
    await Hive.openBox<String>(OutboxQueue.boxName);
    local = ContactsLocalDataSource();
    queue = OutboxQueue();
    remote = _MockRemote();
    repo = ContactsRepositoryImpl(local: local, remote: remote, outbox: queue);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('acceptContactRequest sets localPending and enqueues update op with action=accept', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.acceptContactRequest('req-1', 'u1');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].op, OutboxOpKind.update);
    expect(ops[0].entityId, 'req-1');
    expect(ops[0].feature, 'contacts');
    expect(ops[0].payload!['action'], 'accept');
    final localNow = await local.getById('u1');
    expect(localNow!.localPending, true);
    expect(localNow.status, ContactStatus.accepted);
  });

  test('rejectContactRequest removes local item and enqueues update op with action=reject', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.rejectContactRequest('req-1', 'u1');
    expect(await local.getById('u1'), isNull);
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].payload!['action'], 'reject');
  });

  test('accept then reject for same requestId — second op replaces first', () async {
    await local.upsert(ContactItemEntity(
      userId: 'u1',
      name: 'Alice',
      status: ContactStatus.incoming,
      requestId: 'req-1',
    ));
    await repo.acceptContactRequest('req-1', 'u1');
    await repo.rejectContactRequest('req-1', 'u1');
    final ops = await queue.pending();
    expect(ops.length, 1);
    expect(ops[0].payload!['action'], 'reject');
  });

  test('sendContactRequest delegates to remote and propagates exceptions', () async {
    when(() => remote.sendContactRequest('u-target'))
        .thenThrow(Exception('offline'));
    await expectLater(
      () => repo.sendContactRequest('u-target'),
      throwsA(isA<Exception>()),
    );
  });

  test('refresh merges incoming + accepted + sent lists, preserves localPending', () async {
    when(() => remote.getContactRequests()).thenAnswer((_) async => [
      {'id': 'req-A', 'senderId': 'u-A', 'senderName': 'Alice', 'status': 'PENDING'},
    ]);
    when(() => remote.getConversations()).thenAnswer((_) async => [
      const ConversationEntity(
        id: 'conv-1',
        participantIds: ['u-self', 'u-B'],
        type: 'DIRECT',
        otherUserId: 'u-B',
        otherUserName: 'Bob',
      ),
    ]);
    when(() => remote.getSentContactRequests()).thenAnswer((_) async => [
      {'id': 'req-C', 'receiverId': 'u-C', 'receiverName': 'Carol', 'status': 'PENDING'},
    ]);

    // Pre-existing local entry with localPending=true to verify preservation.
    await local.upsert(ContactItemEntity(
      userId: 'u-A',
      name: 'Alice (stale)',
      status: ContactStatus.incoming,
      requestId: 'req-A',
      localPending: true,
    ));

    await repo.refresh();

    final all = await local.getAll();
    final aliceLocal = all.firstWhere((c) => c.userId == 'u-A');
    expect(aliceLocal.localPending, true, reason: 'localPending must survive refresh');
    expect(all.any((c) => c.userId == 'u-B' && c.status == ContactStatus.accepted), true);
    expect(all.any((c) => c.userId == 'u-C' && c.status == ContactStatus.pending), true);
  });
}
