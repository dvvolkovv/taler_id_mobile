import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/crypto/keys/contact_key_store_hive.dart';
import 'package:taler_id_mobile/core/mesh/services/envelope.dart';
import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/services/messenger_cache_service.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/conversation_entity.dart';

class _FakeRemote implements MessengerRemoteDataSource {
  final List<({String convId, String content, String? clientTempId})>
      sentCalls = [];
  bool isConnectedValue = true;

  @override
  bool get isSocketConnected => isConnectedValue;

  @override
  void sendMessage(String convId, String content,
      {String? fileUrl, String? fileName, int? fileSize, String? fileType,
      String? s3Key, String? thumbnailSmallUrl, String? thumbnailMediumUrl,
      String? thumbnailLargeUrl, String? fileRecordId, String? topicId,
      String? clientTempId}) {
    sentCalls.add((convId: convId, content: content, clientTempId: clientTempId));
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeAdapter implements MeshMessengerAdapter {
  final List<({PeerId peerDevicePk, String contactUserId, Envelope envelope})>
      perPeerCalls = [];
  final List<AdaptedOutboundMessage> outboundEvents = [];

  @override
  Future<void> sendEnvelopeToPeer({
    required PeerId peerDevicePk,
    required String contactUserId,
    required Envelope envelope,
  }) async {
    perPeerCalls.add((
      peerDevicePk: peerDevicePk,
      contactUserId: contactUserId,
      envelope: envelope,
    ));
  }

  @override
  void emitOutbound(AdaptedOutboundMessage event) =>
      outboundEvents.add(event);

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('not used: ${i.memberName}');
}

class _FakePending implements PendingMessageService {
  final List<String> removed = [];
  @override
  Future<void> remove(String tempId) async => removed.add(tempId);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeCache implements MessengerCacheService {
  final Map<String, ConversationEntity> _conversations = {};
  void seedConversation(ConversationEntity c) => _conversations[c.id] = c;
  @override
  ConversationEntity? getConversationById(String id) => _conversations[id];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeContactKeyStore implements HiveContactKeyStore {
  final Map<String, PeerId> _userIdToUserPk = {};
  final Map<String, List<PeerId>> _userPkHexToDevices = {};
  void seedContact(String userId, PeerId userPk, List<PeerId> devices) {
    _userIdToUserPk[userId] = userPk;
    _userPkHexToDevices[userPk.toHex()] = devices;
  }
  @override
  PeerId? userPkForContactUserId(String userId) => _userIdToUserPk[userId];
  @override
  List<PeerId> devicesFor(PeerId userPk) =>
      _userPkHexToDevices[userPk.toHex()] ?? const [];
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  late _FakeRemote remote;
  late _FakeAdapter adapter;
  late _FakePending pending;
  late _FakeCache cache;
  late _FakeContactKeyStore store;

  setUp(() {
    remote = _FakeRemote();
    adapter = _FakeAdapter();
    pending = _FakePending();
    cache = _FakeCache();
    store = _FakeContactKeyStore();
  });

  MessengerRepositoryImpl buildRepo({
    required Set<String> visibleUserIds,
    String? myUserId = 'me-id',
  }) {
    return MessengerRepositoryImpl(
      remote,
      meshAdapter: adapter,
      pending: pending,
      cache: cache,
      hiveContactStore: store,
      isPeerVisibleForContactUserId: visibleUserIds.contains,
      currentUserIdProvider: () => myUserId,
    );
  }

  group('Phase 2 group fanout in sendMessage', () {
    test('group with all visible+known peers — server send + N pairwise mesh',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2', 'p3'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      final p2Pk = PeerId.fromHex('2' * 64);
      final p3Pk = PeerId.fromHex('3' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      store.seedContact('p2', p2Pk, [p2Pk]);
      store.seedContact('p3', p3Pk, [p3Pk]);

      final repo = buildRepo(visibleUserIds: {'p1', 'p2', 'p3'});
      repo.sendMessage('group-conv', 'hi group', clientTempId: 'temp_X');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, hasLength(1));
      expect(remote.sentCalls.first.clientTempId, 'temp_X');
      expect(adapter.perPeerCalls, hasLength(3));
      final calledUsers =
          adapter.perPeerCalls.map((c) => c.contactUserId).toSet();
      expect(calledUsers, {'p1', 'p2', 'p3'});
      expect(adapter.outboundEvents, hasLength(1),
          reason: 'one logical send → one AdaptedOutboundMessage');
      expect(adapter.outboundEvents.first.id, 'mesh-out-X',
          reason: 'mesh-out id strips temp_ prefix so sender bubble does not show pending clock');
      expect(adapter.outboundEvents.first.clientTempId, 'temp_X',
          reason: 'clientTempId preserved for dedup against server echo');
    });

    test('group with mixed visibility — visible get mesh, server still hit',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2', 'p3'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      final p2Pk = PeerId.fromHex('2' * 64);
      final p3Pk = PeerId.fromHex('3' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      store.seedContact('p2', p2Pk, [p2Pk]);
      store.seedContact('p3', p3Pk, [p3Pk]);

      final repo = buildRepo(visibleUserIds: {'p1'});  // only p1 visible
      repo.sendMessage('group-conv', 'hi mixed', clientTempId: 'temp_Y');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, hasLength(1));
      expect(adapter.perPeerCalls.first.contactUserId, 'p1');
    });

    test('group, no visible peers — server-only', () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1', 'p2'],
      ));
      final repo = buildRepo(visibleUserIds: const {});

      repo.sendMessage('group-conv', 'no mesh', clientTempId: 'temp_Z');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, isEmpty);
    });

    test('socket offline + visible peers — mesh-only, no server send',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'group-conv',
        type: 'GROUP',
        participantIds: ['me-id', 'p1'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      remote.isConnectedValue = false;

      final repo = buildRepo(visibleUserIds: {'p1'});
      repo.sendMessage('group-conv', 'mesh only', clientTempId: 'temp_W');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, isEmpty,
          reason: 'socket offline → server send skipped');
      expect(adapter.perPeerCalls, hasLength(1));
    });

    test('1:1 with visible peer + connected — both server and mesh', () async {
      cache.seedConversation(ConversationEntity(
        id: 'direct-conv',
        type: 'DIRECT',
        participantIds: ['me-id', 'p1'],
        otherUserId: 'p1',
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);

      final repo = buildRepo(visibleUserIds: {'p1'});
      repo.sendMessage('direct-conv', 'hi 1:1', clientTempId: 'temp_D');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, hasLength(1));
    });

    test('mesh-out id strips temp_ prefix to avoid pending-clock false positive',
        () async {
      cache.seedConversation(ConversationEntity(
        id: 'conv-1',
        type: 'GROUP',
        participantIds: ['me-id', 'p1'],
      ));
      final p1Pk = PeerId.fromHex('1' * 64);
      store.seedContact('p1', p1Pk, [p1Pk]);
      final repo = buildRepo(visibleUserIds: {'p1'});

      repo.sendMessage('conv-1', 'no clock plz',
          clientTempId: 'temp_abc-123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.outboundEvents, hasLength(1));
      final id = adapter.outboundEvents.first.id;
      expect(id.startsWith('temp_'), isFalse,
          reason: 'must NOT start with temp_ — would render as pending');
      expect(id, 'mesh-out-abc-123');
    });

    test('group > 50 visible peers — mesh skipped, server-only', () async {
      final participants = ['me-id'];
      final visible = <String>{};
      for (var i = 0; i < 60; i++) {
        participants.add('p$i');
        final hexBase = i.toString().padLeft(2, '0');
        final pk = PeerId.fromHex('aa' + hexBase + '0' * 60);
        store.seedContact('p$i', pk, [pk]);
        visible.add('p$i');
      }
      cache.seedConversation(ConversationEntity(
        id: 'huge-conv',
        type: 'GROUP',
        participantIds: participants,
      ));
      final repo = buildRepo(visibleUserIds: visible);

      repo.sendMessage('huge-conv', 'big group', clientTempId: 'temp_BIG');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.perPeerCalls, isEmpty,
          reason: 'over 50 mesh-eligible peers → mesh skipped');
    });
  });
}
