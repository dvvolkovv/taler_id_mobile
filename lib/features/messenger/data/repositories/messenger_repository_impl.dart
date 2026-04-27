import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../../../../core/mesh/crypto/keys/contact_key_store_hive.dart';
import '../../../../core/mesh/services/envelope.dart';
import '../../../../core/mesh/transport/peer_id.dart';
import '../../../../core/services/messenger_cache_service.dart';
import '../../../../core/services/pending_message_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/analyst_events.dart';
import '../../domain/repositories/i_messenger_repository.dart'
    show IMessengerRepository, MeshInboundMessage, MeshOutboundMessage;
import '../datasources/messenger_remote_datasource.dart';
import '../services/mesh_messenger_adapter.dart';
import '../services/pending_mesh_send_queue.dart';

class MessengerRepositoryImpl implements IMessengerRepository {
  final MessengerRemoteDataSource _remote;
  final MeshMessengerAdapter _meshAdapter;
  final PendingMessageService _pending;
  final MessengerCacheService _cache;
  final HiveContactKeyStore _hiveContactStore;
  final bool Function(String contactUserId) _isPeerVisibleForContactUserId;
  final String? Function() _currentUserIdProvider;
  final PendingMeshSendQueue _pendingMeshQueue;

  static const int _meshGroupSizeCap = 50;

  MessengerRepositoryImpl(
    this._remote, {
    required MeshMessengerAdapter meshAdapter,
    required PendingMessageService pending,
    required MessengerCacheService cache,
    required HiveContactKeyStore hiveContactStore,
    required bool Function(String) isPeerVisibleForContactUserId,
    required String? Function() currentUserIdProvider,
    required PendingMeshSendQueue pendingMeshQueue,
  })  : _meshAdapter = meshAdapter,
        _pending = pending,
        _cache = cache,
        _hiveContactStore = hiveContactStore,
        _isPeerVisibleForContactUserId = isPeerVisibleForContactUserId,
        _currentUserIdProvider = currentUserIdProvider,
        _pendingMeshQueue = pendingMeshQueue {
    _meshAdapter.peerDiscovered.listen(_onMeshPeerDiscovered);
  }

  @override
  Future<void> connect(String accessToken) => _remote.connect(accessToken);

  @override
  Future<List<ConversationEntity>> getConversations() => _remote.getConversations();

  @override
  Future<ConversationEntity> createConversation(String participantId) =>
      _remote.createConversation(participantId);

  @override
  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor, String? topicId}) =>
      _remote.getMessages(conversationId, cursor: cursor, topicId: topicId);

  @override
  Future<List<UserSearchEntity>> searchUsers(String query) => _remote.searchUsers(query);

  @override
  void joinConversation(String id) => _remote.joinConversation(id);

  @override
  void sendMessage(
    String conversationId,
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
    // Always-on server path when socket is connected. Server fans out to all
    // members of the conversation (1:1 echo or group fanout).
    if (_remote.isSocketConnected) {
      _remote.sendMessage(
        conversationId,
        content,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        s3Key: s3Key,
        thumbnailSmallUrl: thumbnailSmallUrl,
        thumbnailMediumUrl: thumbnailMediumUrl,
        thumbnailLargeUrl: thumbnailLargeUrl,
        fileRecordId: fileRecordId,
        topicId: topicId,
        clientTempId: clientTempId,
      );
    }
    // (When socket is offline, MessengerBloc's _resendPending will retry on
    //  reconnect — Phase 1g behaviour preserved.)

    // Phase 2 mesh fanout — text-only (attachments stay server-side).
    if (fileUrl != null || s3Key != null) return;
    // ignore: unawaited_futures
    _meshFanout(
      conversationId: conversationId,
      content: content,
      clientTempId: clientTempId,
    );
  }

  Future<void> _meshFanout({
    required String conversationId,
    required String content,
    required String? clientTempId,
  }) async {
    try {
      final conv = _cache.getConversationById(conversationId);
      if (conv == null) {
        debugPrint('[mesh-fanout] no cached conversation for $conversationId, skipping mesh');
        return;
      }
      final myUserId = _currentUserIdProvider();
      final eligible = _meshEligibleParticipants(conv, myUserId);
      final now = DateTime.now().toUtc();
      if (eligible.isEmpty) {
        if (clientTempId != null) {
          _pendingMeshQueue.enqueue(
            clientId: clientTempId,
            conversationId: conversationId,
            content: content,
            sentAt: now,
          );
          debugPrint(
              '[mesh-fanout] no eligible peers — enqueued for retry (clientId=$clientTempId)');
        } else {
          debugPrint('[mesh-fanout] no eligible peers for $conversationId, server-only');
        }
        return;
      }
      if (eligible.length > _meshGroupSizeCap) {
        debugPrint('[mesh-fanout] group size ${eligible.length} > $_meshGroupSizeCap, mesh skipped (server-only)');
        return;
      }

      final clientId = clientTempId ?? const Uuid().v4();
      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: conversationId,
        clientId: clientId,
        text: content,
        sentAt: now,
      );

      // Per-peer fire-and-forget; one peer failure does not block others.
      for (final peer in eligible) {
        // ignore: unawaited_futures
        _meshAdapter.sendEnvelopeToPeer(
          peerDevicePk: peer.devicePk,
          contactUserId: peer.userId,
          envelope: envelope,
        ).catchError((Object e) {
          debugPrint('[mesh-fanout] send to ${peer.userId} failed: $e');
        });
      }

      // ONE outbound event per logical send (not per peer). Phase 1h's
      // MeshMessageSent handler in MessengerBloc replaces temp_clientId with
      // a mesh-out MessageEntity exactly once.
      if (clientTempId != null) {
        // Phase 2: mesh-out entity must NOT keep the `temp_` prefix or the
        // sender's bubble will render with a pending-clock icon (see
        // _isPending check in chat_room_screen.dart). Convert temp_<uuid>
        // → mesh-out-<uuid> so the entity reads as "sent via mesh".
        final outboundId = clientId.startsWith('temp_')
            ? 'mesh-out-${clientId.substring(5)}'
            : 'mesh-out-$clientId';
        _meshAdapter.emitOutbound(AdaptedOutboundMessage(
          id: outboundId,
          conversationId: conversationId,
          contactUserId: eligible.first.userId,  // representative; not used by bloc handler
          clientTempId: clientTempId,
          text: content,
          sentAt: now,
        ));
        // Clear pending since the message is now persisted as mesh-out.
        await _pending.remove(clientTempId);
      }
    } catch (e, st) {
      debugPrint('[mesh-fanout] unexpected error: $e\n$st');
    }
  }

  Future<void> _onMeshPeerDiscovered(AdaptedPeerDiscovered ev) async {
    final due = _pendingMeshQueue.dueFor(
      peerUserId: ev.contactUserId,
      participantsOf: (convId) =>
          _cache.getConversationById(convId)?.participantIds ?? const [],
    ).toList();
    for (final entry in due) {
      final envelope = Envelope(
        version: 1,
        type: 'text',
        convId: entry.conversationId,
        clientId: entry.clientId,
        text: entry.content,
        sentAt: entry.sentAt,
      );
      try {
        await _meshAdapter.sendEnvelopeToPeer(
          peerDevicePk: ev.devicePk,
          contactUserId: ev.contactUserId,
          envelope: envelope,
        );
        final isFirst = _pendingMeshQueue.markFannedOut(
          clientId: entry.clientId,
          peerUserId: ev.contactUserId,
        );
        if (isFirst) {
          final outboundId = entry.clientId.startsWith('temp_')
              ? 'mesh-out-${entry.clientId.substring(5)}'
              : 'mesh-out-${entry.clientId}';
          _meshAdapter.emitOutbound(AdaptedOutboundMessage(
            id: outboundId,
            conversationId: entry.conversationId,
            contactUserId: ev.contactUserId,
            clientTempId: entry.clientId,
            text: entry.content,
            sentAt: entry.sentAt,
          ));
        }
        debugPrint(
            '[mesh-retry] delivered ${entry.clientId} to ${ev.contactUserId}');
      } catch (e) {
        debugPrint(
            '[mesh-retry] send to ${ev.contactUserId} failed: $e (will retry on next discover)');
      }
    }
  }

  List<_EligiblePeer> _meshEligibleParticipants(
      ConversationEntity conv, String? myUserId) {
    final out = <_EligiblePeer>[];
    for (final p in conv.participantIds) {
      if (p == myUserId) continue;
      if (!_isPeerVisibleForContactUserId(p)) continue;
      final userPk = _hiveContactStore.userPkForContactUserId(p);
      if (userPk == null) continue;
      final devices = _hiveContactStore.devicesFor(userPk);
      if (devices.isEmpty) continue;
      out.add(_EligiblePeer(userId: p, devicePk: devices.first));
    }
    return out;
  }

  @override
  void editMessage(String conversationId, String messageId, String newContent) =>
      _remote.editMessage(conversationId, messageId, newContent);

  @override
  void deleteMessage(String conversationId, String messageId, String scope) =>
      _remote.deleteMessage(conversationId, messageId, scope);

  @override
  void sendTyping(String conversationId, bool isTyping) =>
      _remote.sendTyping(conversationId, isTyping);

  @override
  void sendCallInvite(String conversationId, String roomName) =>
      _remote.sendCallInvite(conversationId, roomName);

  @override
  Stream<MessageEntity> get messageStream => _remote.messageStream;

  @override
  Stream<Map<String, dynamic>> get callInviteStream => _remote.callInviteStream;

  @override
  Stream<Map<String, dynamic>> get messageUpdatedStream => _remote.messageUpdatedStream;

  @override
  Stream<Map<String, dynamic>> get messageDeletedStream => _remote.messageDeletedStream;

  @override
  Stream<Map<String, dynamic>> get messageAckedStream => _remote.messageAckedStream;

  @override
  Stream<Map<String, dynamic>> get messagesReadStream => _remote.messagesReadStream;

  @override
  void markRead(String conversationId) => _remote.markRead(conversationId);

  // Group methods
  @override
  Future<ConversationEntity> createGroupConversation(String name, List<String> participantIds) =>
      _remote.createGroupConversation(name, participantIds);

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String conversationId) =>
      _remote.getGroupMembers(conversationId);

  @override
  Future<void> addGroupMembers(String conversationId, List<String> userIds) =>
      _remote.addGroupMembers(conversationId, userIds);

  @override
  Future<void> removeGroupMember(String conversationId, String userId) =>
      _remote.removeGroupMember(conversationId, userId);

  @override
  Future<void> changeGroupMemberRole(String conversationId, String userId, String role) =>
      _remote.changeGroupMemberRole(conversationId, userId, role);

  @override
  Future<void> updateGroupInfo(String conversationId, {String? name, String? avatarUrl, String? description, bool? slowMode, bool? topicsEnabled, int? autoDeleteDays}) =>
      _remote.updateGroupInfo(conversationId, name: name, avatarUrl: avatarUrl, description: description, slowMode: slowMode, topicsEnabled: topicsEnabled, autoDeleteDays: autoDeleteDays);

  @override
  Future<void> leaveGroup(String conversationId) => _remote.leaveGroup(conversationId);

  @override
  Future<void> deleteGroup(String conversationId) => _remote.deleteGroup(conversationId);

  // Group streams
  @override
  Stream<Map<String, dynamic>> get groupUpdatedStream => _remote.groupUpdatedStream;
  @override
  Stream<Map<String, dynamic>> get groupMemberAddedStream => _remote.groupMemberAddedStream;
  @override
  Stream<Map<String, dynamic>> get groupMemberRemovedStream => _remote.groupMemberRemovedStream;
  @override
  Stream<Map<String, dynamic>> get groupRoleChangedStream => _remote.groupRoleChangedStream;
  @override
  Stream<Map<String, dynamic>> get groupCreatedStream => _remote.groupCreatedStream;
  @override
  Stream<Map<String, dynamic>> get groupDeletedStream => _remote.groupDeletedStream;

  // Group call streams
  @override
  Stream<Map<String, dynamic>> get groupCallStartedStream => _remote.groupCallStartedStream;
  @override
  Stream<Map<String, dynamic>> get groupCallEndedStream => _remote.groupCallEndedStream;

  // Typing stream
  @override
  Stream<Map<String, dynamic>> get typingStream => _remote.typingStream;

  // Contact requests
  @override
  Future<Map<String, dynamic>> sendContactRequest(String receiverId) => _remote.sendContactRequest(receiverId);
  @override
  Future<List<Map<String, dynamic>>> getContactRequests() => _remote.getContactRequests();
  @override
  Future<Map<String, dynamic>> acceptContactRequest(String requestId) => _remote.acceptContactRequest(requestId);
  @override
  Future<void> rejectContactRequest(String requestId) => _remote.rejectContactRequest(requestId);
  @override
  Future<List<Map<String, dynamic>>> getSentContactRequests() => _remote.getSentContactRequests();
  @override
  Stream<Map<String, dynamic>> get contactRequestStream => _remote.contactRequestStream;
  @override
  Stream<Map<String, dynamic>> get contactAcceptedStream => _remote.contactAcceptedStream;

  // Reaction methods
  @override
  void reactToMessage(String conversationId, String messageId, String emoji) =>
      _remote.reactToMessage(conversationId, messageId, emoji);
  @override
  Stream<Map<String, dynamic>> get reactionUpdatedStream => _remote.reactionUpdatedStream;
  @override
  Stream<String> get socketErrorStream => _remote.socketErrorStream;

  // Mute methods
  @override
  Future<Map<String, dynamic>> muteConversation(String conversationId, {int? durationMinutes}) =>
      _remote.muteConversation(conversationId, durationMinutes: durationMinutes);

  @override
  Future<void> unmuteConversation(String conversationId) =>
      _remote.unmuteConversation(conversationId);

  @override
  Stream<AnalystChunk> get analystChunkStream => _remote.analystChunkStream;

  @override
  Stream<AnalystSeam> get analystSeamStream => _remote.analystSeamStream;

  @override
  Future<String> getOrCreateSavedConversation() => _remote.getOrCreateSavedConversation();

  @override
  Stream<MeshInboundMessage> get meshMessageStream =>
      _meshAdapter.inbound.map(
        (msg) => MeshInboundMessage(
          contactUserId: msg.contactUserId,
          conversationId: msg.conversationId,
          text: msg.text,
          receivedAt: msg.receivedAt,
        ),
      );

  @override
  Stream<MeshOutboundMessage> get meshOutboundStream =>
      _meshAdapter.outbound.map(
        (o) => MeshOutboundMessage(
          id: o.id,
          conversationId: o.conversationId,
          contactUserId: o.contactUserId,
          clientTempId: o.clientTempId,
          text: o.text,
          sentAt: o.sentAt,
        ),
      );

  @override
  void dispose() => _remote.dispose();
}

class _EligiblePeer {
  final String userId;
  final PeerId devicePk;
  _EligiblePeer({required this.userId, required this.devicePk});
}
