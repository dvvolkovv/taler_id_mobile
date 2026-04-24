import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/mesh/transport/peer_id.dart';
import 'package:taler_id_mobile/core/services/pending_message_service.dart';
import 'package:taler_id_mobile/features/messenger/data/datasources/messenger_remote_datasource.dart';
import 'package:taler_id_mobile/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:taler_id_mobile/features/messenger/data/services/mesh_messenger_adapter.dart';
import 'package:taler_id_mobile/features/messenger/data/services/transport_selector.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Stub that records sendMessage calls without requiring a live DioClient.
class _FakeRemote implements MessengerRemoteDataSource {
  final sentCalls = <Map<String, dynamic>>[];

  @override
  void sendMessage(
    String convId,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? s3Key,
    String? thumbnailSmallUrl,
    String? thumbnailMediumUrl,
    String? thumbnailLargeUrl,
    String? fileRecordId,
    String? topicId,
    String? clientTempId,
  }) {
    sentCalls.add({
      'convId': convId,
      'content': content,
      'clientTempId': clientTempId,
    });
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeMeshAdapter extends MeshMessengerAdapter {
  bool fail = false;
  final outboundCalls = <Map<String, dynamic>>[];

  _FakeMeshAdapter()
      : super(
          meshSendText: ({required PeerId toUserPk, required String text}) async {},
          meshInbound: const Stream.empty(),
          lookupUserByDevice: (_) => null,
          contactUserIdForUserPk: (_) => null,
          resolveConversationId: (id) => 'conv-$id',
          currentUserIdProvider: () => 'me',
          persistLocal: (_) {},
        );

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required PeerId contactDevicePk,
    required String contactUserId,
  }) async {
    outboundCalls.add({
      'conversationId': conversationId,
      'text': text,
    });
    if (fail) throw StateError('mesh send boom');
  }
}

class _FakePending extends PendingMessageService {
  final removed = <String>[];

  @override
  Future<void> remove(String tempId) async {
    removed.add(tempId);
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

({String userId, PeerId devicePk})? _resolveToContact(String convId) =>
    (userId: 'contact-1', devicePk: PeerId.fromHex('a' * 64));

({String userId, PeerId devicePk})? _resolveNull(String convId) => null;

TransportSelector _meshSelector() => TransportSelector(
      isSocketConnected: () => false,
      isPeerVisibleFor: (_) => true,
      offlineFallbackEnabled: () => true,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeRemote remote;
  late _FakeMeshAdapter adapter;
  late _FakePending pending;

  setUp(() {
    remote = _FakeRemote();
    adapter = _FakeMeshAdapter();
    pending = _FakePending();
  });

  group('MessengerRepositoryImpl mesh send (Phase 1g)', () {
    test('successful mesh send clears pending + does NOT hit server', () async {
      final repo = MessengerRepositoryImpl(
        remote,
        selector: _meshSelector(),
        meshAdapter: adapter,
        resolveContact: _resolveToContact,
        pending: pending,
      );

      repo.sendMessage('conv-1', 'hello via mesh', clientTempId: 'temp_42');
      // Give the async helper a chance to complete.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.outboundCalls, hasLength(1));
      expect(remote.sentCalls, isEmpty,
          reason: 'server must not be hit on successful mesh send');
      expect(pending.removed, ['temp_42'],
          reason: 'pending must be cleared so reconnect does not duplicate');
    });

    test('mesh send failure falls back to server, preserves pending', () async {
      adapter.fail = true;
      final repo = MessengerRepositoryImpl(
        remote,
        selector: _meshSelector(),
        meshAdapter: adapter,
        resolveContact: _resolveToContact,
        pending: pending,
      );

      repo.sendMessage('conv-1', 'hello via mesh', clientTempId: 'temp_42');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.outboundCalls, hasLength(1));
      expect(remote.sentCalls, hasLength(1),
          reason: 'server must be hit on mesh failure');
      expect(remote.sentCalls.first['clientTempId'], 'temp_42',
          reason: 'the same tempId propagates so server echo can dedupe');
      expect(pending.removed, isEmpty,
          reason: 'pending kept so the fallback send can be cleared by echo');
    });

    test('no-contact case stays on server path unchanged', () async {
      final repo = MessengerRepositoryImpl(
        remote,
        selector: _meshSelector(),
        meshAdapter: adapter,
        resolveContact: _resolveNull,
        pending: pending,
      );

      repo.sendMessage('conv-1', 'hi', clientTempId: 'temp_43');
      // Server is called synchronously for non-mesh paths, but give a tick
      // for completeness.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(remote.sentCalls, hasLength(1));
      expect(adapter.outboundCalls, isEmpty);
    });
  });
}
