import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/endpoint_service.dart';
import '../../../billing/data/services/billing_socket_listener.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/channel_summary.dart';
import '../../domain/entities/channel_details.dart';
import '../../domain/entities/analyst_events.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/entities/conversation_read_state.dart';

class MessengerRemoteDataSource {
  final DioClient _http;
  io.Socket? _socket;
  final _messageCtrl = StreamController<MessageEntity>.broadcast();
  final _callInviteCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedCtrl = StreamController<String>.broadcast();
  final _callAnsweredCtrl = StreamController<String>.broadcast();
  final _joinedConversations = <String>{};
  final _disconnectCtrl = StreamController<String>.broadcast();
  final _messageUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationReadCtrl = StreamController<Map<String, dynamic>>.broadcast();
  // Group events
  final _groupUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupMemberAddedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupMemberRemovedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupRoleChangedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupCreatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupDeletedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  // Group call events
  final _groupCallStartedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _groupCallEndedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  // Phase 1 GroupCall events (new, separate from legacy group_call_started/ended).
  // The 'group_call_ended' wire-event is shared with the legacy flow; we
  // discriminate by payload-field presence ('groupCallId' vs 'conversationId').
  final _gcInviteCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcStatusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcJoinedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcLeftCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcKickedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcMuteRequestCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcHostChangedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _gcEndedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  // Pin events
  final _messagePinnedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messageUnpinnedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _pinsClearedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messageAckedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _contactRequestCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _contactAcceptedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectCtrl = StreamController<void>.broadcast();
  final _socketErrorCtrl = StreamController<String>.broadcast();
  // AI twin fallback
  final _callAiTwinOfferCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _callAiTwinJoinedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _callAiTwinLeftCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _topicUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _outboundListenCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _analystChunkCtrl = StreamController<AnalystChunk>.broadcast();
  final _analystSeamCtrl  = StreamController<AnalystSeam>.broadcast();

  final EndpointService _endpoints;
  String? _accessToken;
  int _connectErrorStreak = 0;

  MessengerRemoteDataSource(this._http, this._endpoints) {
    // When HTTP failover moves the active endpoint to an RU edge, reconnect the
    // socket to the same endpoint so realtime messaging follows the REST layer.
    _endpoints.activeUrl.addListener(_onEndpointChanged);
  }

  void _onEndpointChanged() {
    final token = _accessToken;
    if (token == null) return; // not connected yet; connect() will use new base
    connect(token); // rebuild the socket against the new base URL
  }

  Future<void> connect(String accessToken) async {
    _accessToken = accessToken;
    debugPrint('[Socket] connect(): rebuilding socket (old connected=${_socket?.connected})');
    _socket?.dispose();
    _socket = io.io(
      '${_endpoints.baseUrl}/messenger',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setTimeout(10000)
          .build(),
    );
    _socket!.on('new_message', (d) {
      try {
        _messageCtrl.add(MessageEntity.fromJson(Map<String, dynamic>.from(d as Map)));
      } catch (e) {
        debugPrint('[Socket] new_message parse error: $e');
      }
    });
    _socket!.on('call_invite', (d) {
      try {
        _callInviteCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('call_ended', (d) {
      try {
        final data = Map<String, dynamic>.from(d as Map);
        final roomName = data['roomName'] as String? ?? '';
        debugPrint('[Socket] call_ended received: roomName=$roomName');
        _callEndedCtrl.add(roomName);
      } catch (e) {
        debugPrint('[Socket] call_ended parse error: $e');
      }
    });
    _socket!.on('message_updated', (d) {
      try {
        _messageUpdatedCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('messages_read', (d) {
      try {
        _messagesReadCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('conversation_read', (d) {
      try {
        _conversationReadCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('call_answered', (d) {
      try {
        final data = Map<String, dynamic>.from(d as Map);
        _callAnsweredCtrl.add(data['roomName'] as String? ?? '');
      } catch (_) {}
    });
    _socket!.on('call_ai_twin_offer', (d) {
      try {
        _callAiTwinOfferCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (e) {
        debugPrint('[Socket] call_ai_twin_offer parse error: $e');
      }
    });
    _socket!.on('call_ai_twin_joined', (d) {
      try {
        _callAiTwinJoinedCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    _socket!.on('call_ai_twin_left', (d) {
      try {
        _callAiTwinLeftCtrl.add(Map<String, dynamic>.from(d as Map));
      } catch (_) {}
    });
    // Group socket events
    _socket!.on('group_updated', (d) {
      try { _groupUpdatedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_member_added', (d) {
      try { _groupMemberAddedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_member_removed', (d) {
      try { _groupMemberRemovedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_role_changed', (d) {
      try { _groupRoleChangedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_created', (d) {
      try { _groupCreatedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_deleted', (d) {
      try { _groupDeletedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_started', (d) {
      try { _groupCallStartedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_ended', (d) {
      try {
        final payload = Map<String, dynamic>.from(d as Map);
        // Phase 1 group-call ended payload: {groupCallId, reason}.
        // Legacy ended payload: {conversationId, roomName}. Disambiguate by
        // presence of 'groupCallId' so the two flows don't crosstalk.
        if (payload.containsKey('groupCallId')) {
          _gcEndedCtrl.add(payload);
        } else {
          _groupCallEndedCtrl.add(payload);
        }
      } catch (_) {}
    });
    // Phase 1 GroupCall socket events (no collision with legacy events)
    _socket!.on('group_call_invite', (d) {
      try { _gcInviteCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_status', (d) {
      try { _gcStatusCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_joined', (d) {
      try { _gcJoinedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_left', (d) {
      try { _gcLeftCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_kicked', (d) {
      try { _gcKickedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_mute_request', (d) {
      try { _gcMuteRequestCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('group_call_host_changed', (d) {
      try { _gcHostChangedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    // Pin events
    _socket!.on('message_pinned', (d) {
      try { _messagePinnedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('message_unpinned', (d) {
      try { _messageUnpinnedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('pins_cleared', (d) {
      try { _pinsClearedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('message_deleted', (d) {
      try { _messageDeletedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('message_acked', (d) {
      try { _messageAckedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('typing', (d) {
      try { _typingCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('analyst_chunk', (data) {
      try {
        _analystChunkCtrl.add(AnalystChunk.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (_) {}
    });
    _socket!.on('analyst_seam', (data) {
      try {
        _analystSeamCtrl.add(AnalystSeam.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (_) {}
    });
    _socket!.on('message_reaction_updated', (d) {
      try { _reactionUpdatedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('topic_updated', (d) {
      try { _topicUpdatedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('contact_request', (d) {
      try { _contactRequestCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('contact_request_accepted', (d) {
      try { _contactAcceptedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('outbound_listen', (d) {
      try { _outboundListenCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    // Re-join all conversation rooms after reconnect
    _socket!.on('error', (d) {
      final msg = (d is Map) ? (d['message'] ?? 'Ошибка') : d.toString();
      _socketErrorCtrl.add(msg.toString());
    });
    _socket!.on('connect', (_) {
      _connectErrorStreak = 0; // healthy on this endpoint
      _endpoints.reportSuccess(); // pin this edge good; clear its failover cooldown
      _reconnectCtrl.add(null);
      for (final id in _joinedConversations) {
        _socket?.emit('join', {'conversationId': id});
      }
    });
    // If the socket can't reach the current endpoint repeatedly (e.g. DPI block
    // and HTTP hasn't run lately), fail over to the next edge. Switching the
    // active endpoint fires _onEndpointChanged -> reconnect on the new base.
    _socket!.onConnectError((_) {
      _connectErrorStreak++;
      if (_connectErrorStreak >= 3 && _endpoints.hasFallback) {
        _connectErrorStreak = 0;
        _endpoints.reportFailureAndFallback();
      }
    });
    _socket!.on('disconnect', (reason) {
      debugPrint('[Socket] disconnect event, reason=$reason');
      _disconnectCtrl.add(reason?.toString() ?? 'disconnected');
    });

    // Billing real-time events (balance changed, ai_session_*, low_balance_warning).
    // The listener registers handlers on the same socket and fans them out
    // via the BillingEventBus singleton. Safe to skip if DI not wired (e.g.
    // isolated unit tests of this datasource).
    try {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<BillingSocketListener>()) {
        getIt<BillingSocketListener>().attach((event, handler) {
          _socket!.on(event, handler);
        });
      }
    } catch (e) {
      debugPrint('[Socket] billing listener attach skipped: $e');
    }

    _socket!.connect();
  }

  Stream<MessageEntity> get messageStream => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get callInviteStream => _callInviteCtrl.stream;
  Stream<String> get callEndedStream => _callEndedCtrl.stream;
  Stream<String> get callAnsweredStream => _callAnsweredCtrl.stream;
  Stream<String> get disconnectStream => _disconnectCtrl.stream;
  Stream<void> get reconnectStream => _reconnectCtrl.stream;
  Stream<String> get socketErrorStream => _socketErrorCtrl.stream;
  Stream<Map<String, dynamic>> get messageUpdatedStream => _messageUpdatedCtrl.stream;
  Stream<Map<String, dynamic>> get messagesReadStream => _messagesReadCtrl.stream;
  Stream<Map<String, dynamic>> get conversationReadStream => _conversationReadCtrl.stream;
  // Group streams
  Stream<Map<String, dynamic>> get groupUpdatedStream => _groupUpdatedCtrl.stream;
  Stream<Map<String, dynamic>> get groupMemberAddedStream => _groupMemberAddedCtrl.stream;
  Stream<Map<String, dynamic>> get groupMemberRemovedStream => _groupMemberRemovedCtrl.stream;
  Stream<Map<String, dynamic>> get groupRoleChangedStream => _groupRoleChangedCtrl.stream;
  Stream<Map<String, dynamic>> get groupCreatedStream => _groupCreatedCtrl.stream;
  Stream<Map<String, dynamic>> get groupDeletedStream => _groupDeletedCtrl.stream;
  // Group call streams
  Stream<Map<String, dynamic>> get groupCallStartedStream => _groupCallStartedCtrl.stream;
  Stream<Map<String, dynamic>> get groupCallEndedStream => _groupCallEndedCtrl.stream;
  // Phase 1 GroupCall streams
  Stream<Map<String, dynamic>> get gcInviteStream => _gcInviteCtrl.stream;
  Stream<Map<String, dynamic>> get gcStatusStream => _gcStatusCtrl.stream;
  Stream<Map<String, dynamic>> get gcJoinedStream => _gcJoinedCtrl.stream;
  Stream<Map<String, dynamic>> get gcLeftStream => _gcLeftCtrl.stream;
  Stream<Map<String, dynamic>> get gcKickedStream => _gcKickedCtrl.stream;
  Stream<Map<String, dynamic>> get gcMuteRequestStream => _gcMuteRequestCtrl.stream;
  Stream<Map<String, dynamic>> get gcHostChangedStream => _gcHostChangedCtrl.stream;
  Stream<Map<String, dynamic>> get gcEndedStream => _gcEndedCtrl.stream;
  // Pin streams
  Stream<Map<String, dynamic>> get messagePinnedStream => _messagePinnedCtrl.stream;
  Stream<Map<String, dynamic>> get messageUnpinnedStream => _messageUnpinnedCtrl.stream;
  Stream<Map<String, dynamic>> get pinsClearedStream => _pinsClearedCtrl.stream;
  Stream<Map<String, dynamic>> get messageDeletedStream => _messageDeletedCtrl.stream;
  Stream<Map<String, dynamic>> get messageAckedStream => _messageAckedCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get contactRequestStream => _contactRequestCtrl.stream;
  Stream<Map<String, dynamic>> get contactAcceptedStream => _contactAcceptedCtrl.stream;
  Stream<Map<String, dynamic>> get reactionUpdatedStream => _reactionUpdatedCtrl.stream;
  Stream<Map<String, dynamic>> get callAiTwinOfferStream => _callAiTwinOfferCtrl.stream;
  Stream<Map<String, dynamic>> get callAiTwinJoinedStream => _callAiTwinJoinedCtrl.stream;
  Stream<Map<String, dynamic>> get callAiTwinLeftStream => _callAiTwinLeftCtrl.stream;
  Stream<Map<String, dynamic>> get topicUpdatedStream => _topicUpdatedCtrl.stream;
  Stream<Map<String, dynamic>> get outboundListenStream => _outboundListenCtrl.stream;
  Stream<AnalystChunk> get analystChunkStream => _analystChunkCtrl.stream;
  Stream<AnalystSeam>  get analystSeamStream  => _analystSeamCtrl.stream;
  bool get isSocketConnected => _socket?.connected ?? false;

  void acceptAiTwinOffer(String roomName) {
    _socket?.emit('call_ai_twin_accepted', {'roomName': roomName});
  }

  void declineAiTwinOffer(String roomName) {
    _socket?.emit('call_ai_twin_declined', {'roomName': roomName});
  }

  void joinConversation(String id) {
    _joinedConversations.add(id);
    _socket?.emit('join', {'conversationId': id});
  }

  void sendMessage(
    String id,
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
    String? origin,
    String? replyToId,
  }) {
    final payload = <String, dynamic>{'conversationId': id, 'content': content};
    if (clientTempId != null) payload['clientTempId'] = clientTempId;
    if (topicId != null) payload['topicId'] = topicId;
    if (origin != null) payload['origin'] = origin;
    if (replyToId != null) payload['replyToId'] = replyToId;
    if (fileUrl != null) {
      payload['fileUrl'] = fileUrl;
      payload['fileName'] = fileName;
      payload['fileSize'] = fileSize;
      payload['fileType'] = fileType;
      if (s3Key != null) payload['s3Key'] = s3Key;
      if (thumbnailSmallUrl != null) payload['thumbnailSmallUrl'] = thumbnailSmallUrl;
      if (thumbnailMediumUrl != null) payload['thumbnailMediumUrl'] = thumbnailMediumUrl;
      if (thumbnailLargeUrl != null) payload['thumbnailLargeUrl'] = thumbnailLargeUrl;
      if (fileRecordId != null) payload['fileRecordId'] = fileRecordId;
    }
    debugPrint('[Socket] sendMessage tempId=$clientTempId connected=${_socket?.connected}');
    _socket?.emit('message', payload);
  }

  void editMessage(String conversationId, String messageId, String newContent) {
    _socket?.emit('edit_message', {
      'conversationId': conversationId,
      'messageId': messageId,
      'content': newContent,
    });
  }

  void deleteMessage(String conversationId, String messageId, String scope) {
    _socket?.emit('delete_message', {
      'conversationId': conversationId,
      'messageId': messageId,
      'scope': scope,
    });
  }

  void sendTyping(String id, bool isTyping) =>
      _socket?.emit('typing', {'conversationId': id, 'isTyping': isTyping});

  void sendCallInvite(String conversationId, String roomName, {String? inviteeId, String? e2eeKey}) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[Socket] sendCallInvite: socket disconnected, reconnecting...');
      // Try to reconnect
      if (_socket != null) {
        _socket!.connect();
        Future.delayed(const Duration(milliseconds: 500), () {
          _socket?.emit('call_invite', {
            'conversationId': conversationId,
            'roomName': roomName,
            if (inviteeId != null) 'inviteeId': inviteeId,
            if (e2eeKey != null) 'e2eeKey': e2eeKey,
          });
          debugPrint('[Socket] sendCallInvite: sent after reconnect');
        });
      }
      return;
    }
    debugPrint('[Socket] sendCallInvite: sending via connected socket');
    _socket!.emit('call_invite', {
      'conversationId': conversationId,
      'roomName': roomName,
      if (inviteeId != null) 'inviteeId': inviteeId,
      if (e2eeKey != null) 'e2eeKey': e2eeKey,
    });
  }

  void sendCallEnded(String conversationId, String roomName) =>
      _socket?.emit('call_ended', {'conversationId': conversationId, 'roomName': roomName});

  void sendCallAnswered(String conversationId, String roomName) =>
      _socket?.emit('call_answered', {'conversationId': conversationId, 'roomName': roomName});

  void markRead(String conversationId) =>
      _socket?.emit('mark_read', {'conversationId': conversationId});

  /// Read-state horizon variant of markRead: reports the last message the
  /// user has actually scrolled past (sentAt + id), not just "read up to now".
  void emitMarkRead(String conversationId, DateTime upToSentAt, String upToMessageId) =>
      _socket?.emit('mark_read', {
        'conversationId': conversationId,
        'upToSentAt': upToSentAt.toUtc().toIso8601String(),
        'upToMessageId': upToMessageId,
      });

  void reactToMessage(String conversationId, String messageId, String emoji) =>
      _socket?.emit('react_message', {
        'conversationId': conversationId,
        'messageId': messageId,
        'emoji': emoji,
      });

  // ─── REST: Direct ───

  Future<List<ConversationEntity>> getConversations() async {
    final data = await _http.get('/messenger/conversations', fromJson: (d) => d as List);
    return data
        .map((e) => ConversationEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ConversationEntity> createConversation(String participantId) async {
    final data = await _http.post(
      '/messenger/conversations',
      data: {'participantId': participantId},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ConversationEntity.fromJson(data);
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor, String? topicId}) async {
    final params = <String>[];
    if (cursor != null) params.add('cursor=$cursor');
    if (topicId != null) params.add('topicId=$topicId');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '/messenger/conversations/$conversationId/messages$qs';
    return _http.get(url, fromJson: (d) => Map<String, dynamic>.from(d as Map));
  }

  Future<List<ConversationReadState>> fetchReadState() async {
    final data = await _http.get('/messenger/read-state', fromJson: (d) => Map<String, dynamic>.from(d as Map));
    final list = data['conversations'] as List? ?? const [];
    return list
        .map((e) => ConversationReadState.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchConversationReadState(String id) async {
    final data = await _http.get(
      '/messenger/conversations/$id/read-state',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    final list = data['participants'] as List? ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<UserSearchEntity>> searchUsers(String query) async {
    final data = await _http.get(
      '/messenger/users/search?q=${Uri.encodeComponent(query)}',
      fromJson: (d) => d as List,
    );
    return data
        .map((e) => UserSearchEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ─── REST: Groups ───

  Future<ConversationEntity> createGroupConversation(String name, List<String> participantIds) async {
    final data = await _http.post(
      '/messenger/conversations/group',
      data: {'name': name, 'participantIds': participantIds},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ConversationEntity.fromJson(data);
  }

  Future<List<GroupMemberEntity>> getGroupMembers(String conversationId) async {
    final data = await _http.get(
      '/messenger/conversations/$conversationId/members',
      fromJson: (d) => d as List,
    );
    return data
        .map((e) => GroupMemberEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addGroupMembers(String conversationId, List<String> userIds) async {
    await _http.post(
      '/messenger/conversations/$conversationId/members',
      data: {'userIds': userIds},
      fromJson: (d) => d,
    );
  }

  Future<void> removeGroupMember(String conversationId, String userId) async {
    await _http.delete('/messenger/conversations/$conversationId/members/$userId');
  }

  Future<void> changeGroupMemberRole(String conversationId, String userId, String role) async {
    await _http.patch(
      '/messenger/conversations/$conversationId/members/$userId/role',
      data: {'role': role},
    );
  }

  Future<void> updateGroupInfo(String conversationId, {String? name, String? avatarUrl, String? description, bool? slowMode, bool? topicsEnabled, int? autoDeleteDays}) async {
    await _http.patch(
      '/messenger/conversations/$conversationId',
      data: {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (description != null) 'description': description,
        if (slowMode != null) 'slowMode': slowMode,
        if (topicsEnabled != null) 'topicsEnabled': topicsEnabled,
        if (autoDeleteDays != null) 'autoDeleteDays': autoDeleteDays,
      },
    );
  }

  Future<void> leaveGroup(String conversationId) async {
    await _http.post(
      '/messenger/conversations/$conversationId/leave',
      data: {},
      fromJson: (d) => d,
    );
  }

  Future<void> deleteGroup(String conversationId) async {
    await _http.delete('/messenger/conversations/$conversationId');
  }

  // ─── REST: Contact Requests ───

  Future<Map<String, dynamic>> sendContactRequest(String receiverId) async {
    return _http.post(
      '/messenger/contacts/request',
      data: {'receiverId': receiverId},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<List<Map<String, dynamic>>> getContactRequests() async {
    final data = await _http.get(
      '/messenger/contacts/requests',
      fromJson: (d) => d as List,
    );
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> acceptContactRequest(String requestId) async {
    return _http.patch(
      '/messenger/contacts/requests/$requestId/accept',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> rejectContactRequest(String requestId) async {
    await _http.patch(
      '/messenger/contacts/requests/$requestId/reject',
      data: {},
      fromJson: (d) => d,
    );
  }

  Future<List<Map<String, dynamic>>> getSentContactRequests() async {
    final data = await _http.get(
      '/messenger/contacts/requests/sent',
      fromJson: (d) => d as List,
    );
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ─── REST: Mute ───

  Future<Map<String, dynamic>> muteConversation(String conversationId, {int? durationMinutes}) async {
    return _http.post(
      '/messenger/conversations/$conversationId/mute',
      data: {if (durationMinutes != null) 'duration': durationMinutes},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> unmuteConversation(String conversationId) async {
    await _http.post(
      '/messenger/conversations/$conversationId/unmute',
      data: {},
      fromJson: (d) => d,
    );
  }

  // ─── REST: Pins ───

  Future<Map<String, dynamic>> pinMessage(String conversationId, String messageId) async {
    return _http.post(
      '/messenger/conversations/$conversationId/messages/$messageId/pin',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// Пересылка пачки сообщений в беседу [targetConversationId].
  ///
  /// Тело копирует сервер из оригиналов — клиент передаёт только id, поэтому
  /// подделать «Переслано от X» с произвольным текстом нельзя. Сервер же
  /// рассылает новые сообщения по сокету, так что отдельно вставлять их в ленту
  /// не нужно.
  Future<List<MessageEntity>> forwardMessages(
    String targetConversationId,
    List<String> messageIds,
  ) async {
    final data = await _http.post(
      '/messenger/conversations/$targetConversationId/forward',
      data: {'messageIds': messageIds},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    final list = (data['messages'] as List?) ?? const [];
    return list
        .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> unpinMessage(String conversationId, String messageId) async {
    return _http.deleteWithResponse(
      '/messenger/conversations/$conversationId/messages/$messageId/pin',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<List<MessageEntity>> getPinnedMessages(String conversationId) async {
    final data = await _http.get(
      '/messenger/conversations/$conversationId/pinned',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    final list = (data['messages'] as List?) ?? const [];
    return list
        .map((e) => MessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> unpinAll(String conversationId) async {
    return _http.deleteWithResponse(
      '/messenger/conversations/$conversationId/pinned',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// [upTo] is the pinnedAt of the top pin the user actually saw. Without it
  /// the backend falls back to the conversation's newest pinnedAt, silently
  /// hiding a pin that arrived while the request was in flight.
  Future<Map<String, dynamic>> dismissPins(String conversationId, {DateTime? upTo}) async {
    return _http.post(
      '/messenger/conversations/$conversationId/pinned/dismiss',
      data: {if (upTo != null) 'upTo': upTo.toUtc().toIso8601String()},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  // ─── Channels ───────────────────────────────────────────────

  Future<List<ChannelSummary>> listChannels({String? q, int limit = 20, int offset = 0}) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (q != null && q.isNotEmpty) params['q'] = q;
    final list = await _http.get(
      '/messenger/channels',
      queryParameters: params,
      fromJson: (d) => d as List,
    );
    return list
        .map((e) => ChannelSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChannelDetails> getChannelDetails(String id) async {
    final data = await _http.get(
      '/messenger/channels/$id',
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ChannelDetails.fromJson(data);
  }

  Future<String> createChannel({required String name, String? description, String? avatarUrl}) async {
    final data = await _http.post(
      '/messenger/channels',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return data['id'] as String;
  }

  Future<ChannelDetails> updateChannel(String id, {String? name, String? description, String? avatarUrl}) async {
    final data = await _http.patch(
      '/messenger/channels/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return ChannelDetails.fromJson(data);
  }

  Future<void> deleteChannel(String id) async {
    await _http.delete('/messenger/channels/$id');
  }

  Future<Map<String, dynamic>> subscribeToChannel(String id) async {
    return _http.post(
      '/messenger/channels/$id/subscribe',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> unsubscribeFromChannel(String id) async {
    return _http.deleteWithResponse(
      '/messenger/channels/$id/subscribe',
      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
    );
  }

  Future<String> getOrCreateSavedConversation() async {
    final data = await _http.post(
      '/messenger/saved',
      data: {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    final id = data['conversationId'];
    if (id is! String) {
      throw const FormatException('SAVED conversation: missing conversationId in response');
    }
    return id;
  }

  Future<SyncResult> sync({String? cursor, int limit = 200}) async {
    final qp = <String, dynamic>{'limit': limit};
    if (cursor != null) qp['cursor'] = cursor;
    final res = await _http.dio.get<Map<String, dynamic>>(
      '/messenger/sync',
      queryParameters: qp,
    );
    return SyncResult.fromJson(res.data ?? const {});
  }

  /// Tear down the active socket so the next `connect(token)` starts fresh.
  /// Called from logout to prevent the previous user's JWT from staying
  /// attached on subsequent re-login as a different account.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _socket?.dispose();
    _messageCtrl.close();
    _callInviteCtrl.close();
    _callEndedCtrl.close();
    _disconnectCtrl.close();
    _messageUpdatedCtrl.close();
    _messagesReadCtrl.close();
    _conversationReadCtrl.close();
    _groupUpdatedCtrl.close();
    _groupMemberAddedCtrl.close();
    _groupMemberRemovedCtrl.close();
    _groupRoleChangedCtrl.close();
    _groupCreatedCtrl.close();
    _groupDeletedCtrl.close();
    _groupCallStartedCtrl.close();
    _groupCallEndedCtrl.close();
    _gcInviteCtrl.close();
    _gcStatusCtrl.close();
    _gcJoinedCtrl.close();
    _gcLeftCtrl.close();
    _gcKickedCtrl.close();
    _gcMuteRequestCtrl.close();
    _gcHostChangedCtrl.close();
    _gcEndedCtrl.close();
    _messageDeletedCtrl.close();
    _typingCtrl.close();
    _contactRequestCtrl.close();
    _contactAcceptedCtrl.close();
    _reactionUpdatedCtrl.close();
    _topicUpdatedCtrl.close();
    _analystChunkCtrl.close();
    _analystSeamCtrl.close();
    _messagePinnedCtrl.close();
    _messageUnpinnedCtrl.close();
    _pinsClearedCtrl.close();
  }
}
