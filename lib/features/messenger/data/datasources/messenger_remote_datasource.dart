import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/api/dio_client.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/user_search_entity.dart';
import '../../domain/entities/group_member_entity.dart';

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
  final _messageDeletedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _contactRequestCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _contactAcceptedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _reconnectCtrl = StreamController<void>.broadcast();
  final _socketErrorCtrl = StreamController<String>.broadcast();

  MessengerRemoteDataSource(this._http);

  Future<void> connect(String accessToken) async {
    _socket?.dispose();
    _socket = io.io(
      '${AppConfig.baseUrl}/messenger',
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
    _socket!.on('call_answered', (d) {
      try {
        final data = Map<String, dynamic>.from(d as Map);
        _callAnsweredCtrl.add(data['roomName'] as String? ?? '');
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
      try { _groupCallEndedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('message_deleted', (d) {
      try { _messageDeletedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('typing', (d) {
      try { _typingCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('message_reaction_updated', (d) {
      try { _reactionUpdatedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('contact_request', (d) {
      try { _contactRequestCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    _socket!.on('contact_request_accepted', (d) {
      try { _contactAcceptedCtrl.add(Map<String, dynamic>.from(d as Map)); } catch (_) {}
    });
    // Re-join all conversation rooms after reconnect
    _socket!.on('error', (d) {
      final msg = (d is Map) ? (d['message'] ?? 'Ошибка') : d.toString();
      _socketErrorCtrl.add(msg.toString());
    });
    _socket!.on('connect', (_) {
      _reconnectCtrl.add(null);
      for (final id in _joinedConversations) {
        _socket?.emit('join', {'conversationId': id});
      }
    });
    _socket!.on('disconnect', (reason) {
      _disconnectCtrl.add(reason?.toString() ?? 'disconnected');
    });
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
  Stream<Map<String, dynamic>> get messageDeletedStream => _messageDeletedCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get contactRequestStream => _contactRequestCtrl.stream;
  Stream<Map<String, dynamic>> get contactAcceptedStream => _contactAcceptedCtrl.stream;
  Stream<Map<String, dynamic>> get reactionUpdatedStream => _reactionUpdatedCtrl.stream;
  bool get isSocketConnected => _socket?.connected ?? false;

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
  }) {
    final payload = <String, dynamic>{'conversationId': id, 'content': content};
    if (clientTempId != null) payload['clientTempId'] = clientTempId;
    if (topicId != null) payload['topicId'] = topicId;
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

  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor}) async {
    final url = cursor != null
        ? '/messenger/conversations/$conversationId/messages?cursor=$cursor'
        : '/messenger/conversations/$conversationId/messages';
    return _http.get(url, fromJson: (d) => Map<String, dynamic>.from(d as Map));
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

  void dispose() {
    _socket?.dispose();
    _messageCtrl.close();
    _callInviteCtrl.close();
    _callEndedCtrl.close();
    _disconnectCtrl.close();
    _messageUpdatedCtrl.close();
    _messagesReadCtrl.close();
    _groupUpdatedCtrl.close();
    _groupMemberAddedCtrl.close();
    _groupMemberRemovedCtrl.close();
    _groupRoleChangedCtrl.close();
    _groupCreatedCtrl.close();
    _groupDeletedCtrl.close();
    _groupCallStartedCtrl.close();
    _groupCallEndedCtrl.close();
    _messageDeletedCtrl.close();
    _typingCtrl.close();
    _contactRequestCtrl.close();
    _contactAcceptedCtrl.close();
    _reactionUpdatedCtrl.close();
  }
}
