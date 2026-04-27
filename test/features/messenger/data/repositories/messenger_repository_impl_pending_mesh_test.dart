import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';
import 'package:taler_id_mobile/features/messenger/data/services/pending_mesh_send_queue.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _MockRemote extends Mock implements MessengerRemoteDataSource {}

class _MockAdapter extends Mock implements MeshMessengerAdapter {}

class _MockPending extends Mock implements PendingMessageService {}

class _MockCache extends Mock implements MessengerCacheService {}

class _MockHiveStore extends Mock implements HiveContactKeyStore {}

ConversationEntity _conv({
  required String id,
  required List<String> participantIds,
}) {
  return ConversationEntity(
    id: id,
    participantIds: participantIds,
    type: 'DIRECT',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(PeerId.fromHex('0' * 64));
    registerFallbackValue(Envelope(
      version: 1,
      type: 'text',
      convId: '_',
      clientId: '_',
      text: '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    ));
    registerFallbackValue(AdaptedOutboundMessage(
      id: '_',
      conversationId: '_',
      contactUserId: '_',
      clientTempId: null,
      text: '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
    ));
  });

  group('MessengerRepositoryImpl pending mesh enqueue', () {
    late _MockRemote remote;
    late _MockAdapter adapter;
    late _MockPending pending;
    late _MockCache cache;
    late _MockHiveStore hive;
    late PendingMeshSendQueue queue;
    late MessengerRepositoryImpl repo;
    late StreamController<AdaptedPeerDiscovered> peerCtrl;

    setUp(() {
      remote = _MockRemote();
      adapter = _MockAdapter();
      pending = _MockPending();
      cache = _MockCache();
      hive = _MockHiveStore();
      queue = PendingMeshSendQueue();
      peerCtrl = StreamController<AdaptedPeerDiscovered>.broadcast();

      when(() => remote.isSocketConnected).thenReturn(true);
      when(() => adapter.peerDiscovered).thenAnswer((_) => peerCtrl.stream);
      when(() => cache.getConversationById(any())).thenReturn(
        _conv(id: 'conv-1', participantIds: ['me', 'user-bob']),
      );
      when(() => hive.userPkForContactUserId(any())).thenReturn(null);
      when(() => hive.devicesFor(any())).thenReturn(const []);

      repo = MessengerRepositoryImpl(
        remote,
        meshAdapter: adapter,
        pending: pending,
        cache: cache,
        hiveContactStore: hive,
        isPeerVisibleForContactUserId: (_) => false, // no peer visible → no eligible
        currentUserIdProvider: () => 'me',
        pendingMeshQueue: queue,
      );
    });

    tearDown(() async {
      await peerCtrl.close();
    });

    test('text send with no eligible peers enqueues into pendingMeshQueue', () async {
      repo.sendMessage(
        'conv-1',
        'hi',
        clientTempId: 'temp_xyz',
      );
      // _meshFanout is fire-and-forget; let microtasks run.
      await Future<void>.delayed(Duration.zero);

      expect(queue.pendingCount, 1);
    });

    test('attachment send is NOT enqueued', () async {
      repo.sendMessage(
        'conv-1',
        'photo',
        fileUrl: 'https://example.com/x.png',
        clientTempId: 'temp_file',
      );
      await Future<void>.delayed(Duration.zero);
      expect(queue.pendingCount, 0);
    });

    test('send without clientTempId is NOT enqueued', () async {
      repo.sendMessage('conv-1', 'hi');
      await Future<void>.delayed(Duration.zero);
      expect(queue.pendingCount, 0);
    });
  });

  group('MessengerRepositoryImpl mesh retry on peerDiscovered', () {
    late _MockRemote remote;
    late _MockAdapter adapter;
    late _MockPending pending;
    late _MockCache cache;
    late _MockHiveStore hive;
    late PendingMeshSendQueue queue;
    late MessengerRepositoryImpl repo;
    late StreamController<AdaptedPeerDiscovered> peerCtrl;

    setUp(() {
      remote = _MockRemote();
      adapter = _MockAdapter();
      pending = _MockPending();
      cache = _MockCache();
      hive = _MockHiveStore();
      queue = PendingMeshSendQueue();
      peerCtrl = StreamController<AdaptedPeerDiscovered>.broadcast();

      when(() => remote.isSocketConnected).thenReturn(false); // mesh-only path easier
      when(() => adapter.peerDiscovered).thenAnswer((_) => peerCtrl.stream);
      when(() => cache.getConversationById('conv-1')).thenReturn(
        _conv(id: 'conv-1', participantIds: ['me', 'user-bob', 'user-charlie']),
      );
      when(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          )).thenAnswer((_) async {});

      repo = MessengerRepositoryImpl(
        remote,
        meshAdapter: adapter,
        pending: pending,
        cache: cache,
        hiveContactStore: hive,
        isPeerVisibleForContactUserId: (_) => false,
        currentUserIdProvider: () => 'me',
        pendingMeshQueue: queue,
      );
    });

    tearDown(() async {
      await peerCtrl.close();
    });

    test('peerDiscovered triggers sendEnvelopeToPeer for matching pending entry', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final bobDevicePk = PeerId.fromHex(
          'b' + '0' * 63); // any 32-byte hex; content not validated by mocks

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: bobDevicePk,
        contactUserId: 'user-bob',
      ));
      await Future<void>.delayed(Duration.zero);

      verify(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: bobDevicePk,
            contactUserId: 'user-bob',
            envelope: any(named: 'envelope'),
          )).called(1);
    });

    test('first successful retry emits one outbound; second retry to another peer does not re-emit', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final bobDevicePk = PeerId.fromHex('b' + '0' * 63);
      final charlieDevicePk = PeerId.fromHex('c' + '0' * 63);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: bobDevicePk,
        contactUserId: 'user-bob',
      ));
      await Future<void>.delayed(Duration.zero);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: charlieDevicePk,
        contactUserId: 'user-charlie',
      ));
      await Future<void>.delayed(Duration.zero);

      verify(() => adapter.emitOutbound(any())).called(1);
      verify(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          )).called(2);
    });

    test('peerDiscovered for peer not in any participants does nothing', () async {
      queue.enqueue(
        clientId: 'temp_abc',
        conversationId: 'conv-1',
        content: 'hello',
        sentAt: DateTime.now().toUtc(),
      );
      final strangerPk = PeerId.fromHex('d' + '0' * 63);

      peerCtrl.add(AdaptedPeerDiscovered(
        devicePk: strangerPk,
        contactUserId: 'user-stranger',
      ));
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => adapter.sendEnvelopeToPeer(
            peerDevicePk: any(named: 'peerDevicePk'),
            contactUserId: any(named: 'contactUserId'),
            envelope: any(named: 'envelope'),
          ));
    });
  });
}
